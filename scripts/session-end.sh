#!/bin/bash
# session-end.sh — Claude Code SessionEnd hook
#
# Ends the session on the Commens governance ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

commens_read_input
commens_require_session_id
commens_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

"$COMMENS" session end "$HOOK_SESSION_ID" \
  --reason "${HOOK_REASON:-other}" \
  --agent "claude-code" \
  --json 2>/dev/null || {
  commens_log "Failed to end session $HOOK_SESSION_ID"
}

exit 0
