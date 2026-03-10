#!/bin/bash
# session-start.sh — Claude Code SessionStart hook (matcher: startup)
#
# Starts a new active session on the Commens governance ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

commens_read_input
commens_require_session_id
commens_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

# Persist session ID for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export COMMENS_SESSION_ID=\"$HOOK_SESSION_ID\"" >> "$CLAUDE_ENV_FILE"
fi

RESULT=$("$COMMENS" session start "$HOOK_SESSION_ID" \
  --model "${HOOK_MODEL:-}" \
  --source "${HOOK_SOURCE:-startup}" \
  --agent "claude-code" \
  --json 2>/dev/null) || true

if [ -n "$RESULT" ]; then
  commens_output_context "Session $HOOK_SESSION_ID started on Commens governance ledger."
fi

exit 0
