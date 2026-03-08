#!/bin/bash
# record-interaction.sh — Claude Code Stop hook
#
# Records the most recently completed interaction (user prompt + assistant
# response) as an INTERACTION asset on the Commens governance ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

commens_read_input
commens_require_session_id
commens_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

# Only proceed if we have a transcript file to parse.
if [ -z "$HOOK_TRANSCRIPT_PATH" ] || [ ! -f "$HOOK_TRANSCRIPT_PATH" ]; then
  commens_log "No transcript_path in hook input or file not found; skipping."
  exit 0
fi

# Per-session sequence counter.
COUNTER_DIR="${HOME}/.commens/interaction-counters"
mkdir -p "$COUNTER_DIR"
COUNTER_FILE="${COUNTER_DIR}/${HOOK_SESSION_ID}"

CURRENT_SEQ=0
if [ -f "$COUNTER_FILE" ]; then
  CURRENT_SEQ=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
fi
NEXT_SEQ=$((CURRENT_SEQ + 1))

# Extract last user prompt from JSONL transcript.
USER_PROMPT=$(jq -rs '
  [.[] | select(.role == "user" or .type == "human")] |
  last |
  if . == null then ""
  elif (.content | type) == "string" then .content
  elif (.content | type) == "array" then
    [.content[] | select(.type == "text") | .text] | join(" ")
  else ""
  end
' "$HOOK_TRANSCRIPT_PATH" 2>/dev/null || echo "")

# Extract last assistant response.
ASSISTANT_RESPONSE=$(jq -rs '
  [.[] | select(.role == "assistant" or .type == "assistant")] |
  last |
  if . == null then ""
  elif (.content | type) == "string" then .content
  elif (.content | type) == "array" then
    [.content[] | select(.type == "text") | .text] | join(" ")
  else ""
  end
' "$HOOK_TRANSCRIPT_PATH" 2>/dev/null || echo "")

# Collect tool calls from the last assistant turn.
TOOL_CALLS=$(jq -rs '
  [.[] | select(.role == "assistant" or .type == "assistant")] |
  last |
  if . == null then []
  elif (.content | type) == "array" then
    [.content[] | select(.type == "tool_use") | .name] | unique
  else []
  end
' "$HOOK_TRANSCRIPT_PATH" 2>/dev/null || echo "[]")

# Model from last assistant turn or hook input.
ASSISTANT_MODEL=$(jq -rs '
  [.[] | select(.role == "assistant" or .type == "assistant")] |
  last |
  .message.model // empty
' "$HOOK_TRANSCRIPT_PATH" 2>/dev/null || echo "")
INTERACTION_MODEL="${ASSISTANT_MODEL:-${HOOK_MODEL:-}}"

if [ -z "$USER_PROMPT" ]; then
  commens_log "No user prompt found in transcript; skipping interaction recording."
  exit 0
fi

INTERACTION_ID=$(printf "%s_%04d" "$HOOK_SESSION_ID" "$NEXT_SEQ")

"$COMMENS" session interaction record \
  --session-id    "$HOOK_SESSION_ID" \
  --interaction-id "$INTERACTION_ID" \
  --sequence-number "$NEXT_SEQ" \
  --user-prompt   "$USER_PROMPT" \
  --assistant-response "$ASSISTANT_RESPONSE" \
  --model         "$INTERACTION_MODEL" \
  --agent-name    "claude-code" \
  --tool-calls    "$(echo "$TOOL_CALLS" | jq -r '.[]' | tr '\n' ',' | sed 's/,$//')" \
  --json 2>/dev/null \
  && echo "$NEXT_SEQ" > "$COUNTER_FILE" \
  || commens_log "Failed to record interaction $INTERACTION_ID for session $HOOK_SESSION_ID"

exit 0
