#!/bin/bash
# session-start.sh — Claude Code SessionStart hook (matcher: startup)
#
# Registers a new active session on the Commens governance ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

bw_read_input
bw_require_session_id
bw_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

# Persist session ID for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export COMMENS_SESSION_ID=\"$BW_SESSION_ID\"" >> "$CLAUDE_ENV_FILE"
fi

RESULT=$("$BW_BIN" session register \
  --session-id "$BW_SESSION_ID" \
  --model "${BW_MODEL:-}" \
  --source "${BW_HOOK_SOURCE:-startup}" \
  --agent "claude-code" \
  --json 2>/dev/null) || true

if [ -n "$RESULT" ]; then
  bw_output_context "Session $BW_SESSION_ID registered on Commens governance ledger."
fi

exit 0
