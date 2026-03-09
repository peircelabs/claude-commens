#!/bin/bash
# launch-server.sh — Start the Commens MCP proxy (stdio transport).
# This starts the per-instance MCP proxy which connects to the shared
# service over a Unix domain socket. The shared service is auto-started
# if not already running.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/commens-hooks.sh" 2>/dev/null \
  || { echo "Failed to source commens-hooks.sh" >&2; exit 1; }

commens_resolve_binary "${CLAUDE_PLUGIN_ROOT:-}"

if [ "$COMMENS" = "commens" ] && ! command -v commens >/dev/null 2>&1; then
  commens_log "commens binary not found. Install from: https://github.com/peircelabs/commens"
  commens_log "Or set COMMENS_BIN to the absolute path of the binary."
  exit 1
fi

exec "$COMMENS" mcp serve
