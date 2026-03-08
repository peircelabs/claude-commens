#!/bin/bash
# pre-compact.sh — Claude Code PreCompact hook
#
# Saves a checkpoint before context compaction.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

commens_read_input
commens_require_session_id
commens_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

"$COMMENS" session checkpoint \
  --session-id "$HOOK_SESSION_ID" \
  --checkpoint-type "pre_compact" \
  --json 2>/dev/null || {
  commens_log "Failed to checkpoint session $HOOK_SESSION_ID"
}

exit 0
