#!/bin/bash
# session-resume.sh — Claude Code SessionStart hook (matcher: resume)
#
# Idempotently re-activates an existing session on the Commens ledger.
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

"$COMMENS" session register \
  --session-id "$HOOK_SESSION_ID" \
  --model "${HOOK_MODEL:-}" \
  --source "resume" \
  --agent "claude-code" \
  --json 2>/dev/null || true

exit 0
