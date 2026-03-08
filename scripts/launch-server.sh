#!/bin/bash
# launch-server.sh — Start the Commens MCP server (stdio transport).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 1; }

bw_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

if [ "$BW_BIN" = "commens" ] && ! command -v commens >/dev/null 2>&1; then
  bw_log "commens binary not found. Install from: https://github.com/peircelabs/commens"
  bw_log "Or set COMMENS_BIN to the absolute path of the binary."
  exit 1
fi

exec "$BW_BIN" serve
