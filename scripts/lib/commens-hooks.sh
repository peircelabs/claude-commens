#!/bin/bash
# commens-hooks.sh — Shared library for Commens hook scripts (Claude Code).
#
# Tailored for the claude-commens plugin. Provides common functions for
# parsing hook input, resolving the commens binary, and formatting output.
#
# Usage: source this file at the top of each hook script.
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/commens-hooks.sh"

# Runtime identifier for this tool.
BW_RUNTIME="claude-code"

# --- Input Parsing ---

# bw_read_input reads JSON from stdin and exports common fields.
bw_read_input() {
  BW_INPUT=$(cat)
  BW_SESSION_ID=$(echo "$BW_INPUT" | jq -r '.session_id // empty')
  BW_TRANSCRIPT_PATH=$(echo "$BW_INPUT" | jq -r '.transcript_path // empty')
  BW_HOOK_SOURCE=$(echo "$BW_INPUT" | jq -r '.source // empty')
  BW_HOOK_REASON=$(echo "$BW_INPUT" | jq -r '.reason // empty')
  BW_MODEL=$(echo "$BW_INPUT" | jq -r '.model // empty')
  BW_TIMESTAMP=$(echo "$BW_INPUT" | jq -r '.timestamp // empty')
  export BW_INPUT BW_SESSION_ID BW_TRANSCRIPT_PATH BW_HOOK_SOURCE BW_HOOK_REASON BW_MODEL BW_TIMESTAMP
}

# --- Binary Resolution ---

# bw_resolve_binary locates the commens binary.
# Checks: COMMENS_BIN env → plugin root bin/ → PATH → common install locations.
bw_resolve_binary() {
  local plugin_root="${1:-}"

  if [ -n "${COMMENS_BIN:-}" ] && [ -x "${COMMENS_BIN}" ]; then
    BW_BIN="$COMMENS_BIN"
    return 0
  fi

  if [ -n "$plugin_root" ] && [ -x "${plugin_root}/bin/commens" ]; then
    BW_BIN="${plugin_root}/bin/commens"
    return 0
  fi

  if command -v commens >/dev/null 2>&1; then
    BW_BIN="commens"
    return 0
  fi

  for candidate in /usr/local/bin/commens "${HOME}/.local/bin/commens"; do
    if [ -x "$candidate" ]; then
      BW_BIN="$candidate"
      return 0
    fi
  done

  BW_BIN="commens"
  return 1
}

# --- Validation ---

bw_require_session_id() {
  if [ -z "$BW_SESSION_ID" ]; then
    bw_log "No session_id in hook input; skipping."
    exit 0
  fi
}

bw_require_project() {
  BW_PROJECT="${COMMENS_PROJECT_ID:-}"
  if [ -z "$BW_PROJECT" ]; then
    bw_log "COMMENS_PROJECT_ID not set; skipping."
    exit 0
  fi
  export BW_PROJECT
}

# --- Logging ---

bw_log() {
  echo "[commens-hook] $*" >&2
}

# --- Output Helpers ---

bw_output_context() {
  local context="$1"
  jq -n --arg ctx "$context" '{
    "hookSpecificOutput": {
      "additionalContext": $ctx
    }
  }'
}

bw_output_system_message() {
  local msg="$1"
  jq -n --arg msg "$msg" '{
    "systemMessage": $msg
  }'
}

bw_output_empty() {
  echo '{}'
}
