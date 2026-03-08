#!/bin/bash
# session-resume.sh — Claude Code SessionStart hook (matcher: resume)
#
# Idempotently re-activates an existing session on the Commens ledger.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

bw_read_input
bw_require_session_id
bw_require_project
bw_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

# Persist session ID for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export COMMENS_SESSION_ID=\"$BW_SESSION_ID\"" >> "$CLAUDE_ENV_FILE"
fi

"$BW_BIN" register-session \
  --session-id "$BW_SESSION_ID" \
  --model "${BW_MODEL:-}" \
  --source "resume" \
  --agent "claude-code" \
  --project "$BW_PROJECT" \
  --json 2>/dev/null || true

exit 0
