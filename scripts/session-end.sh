#!/bin/bash
# session-end.sh — Claude Code SessionEnd hook
#
# Archives the session to the Commens governance ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

bw_read_input
bw_require_session_id
bw_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

FINALIZE_ARGS=(
  finalize-session
  --session-id "$BW_SESSION_ID"
  --reason "${BW_HOOK_REASON:-other}"
  --agent "claude-code"
  --json
)

if [ -n "$BW_TRANSCRIPT_PATH" ] && [ -f "$BW_TRANSCRIPT_PATH" ]; then
  FINALIZE_ARGS+=(--transcript-path "$BW_TRANSCRIPT_PATH")
fi

"$BW_BIN" "${FINALIZE_ARGS[@]}" 2>/dev/null || {
  bw_log "Failed to finalize session $BW_SESSION_ID"
}

exit 0
