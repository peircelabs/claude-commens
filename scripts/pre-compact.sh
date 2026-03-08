#!/bin/bash
# pre-compact.sh — Claude Code PreCompact hook
#
# Saves a checkpoint before context compaction.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 0; }

bw_read_input
bw_require_session_id
bw_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

CHECKPOINT_ARGS=(
  session checkpoint
  --session-id "$BW_SESSION_ID"
  --checkpoint-type "pre_compact"
  --json
)

"$BW_BIN" "${CHECKPOINT_ARGS[@]}" 2>/dev/null || {
  bw_log "Failed to checkpoint session $BW_SESSION_ID"
}

exit 0
