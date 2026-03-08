#!/bin/bash
# commens-hooks.sh — Shared library for Commens hook scripts (Claude Code).
#
# Provides common functions for parsing hook input, resolving the commens
# binary, and formatting output.
#
# Usage: source this file at the top of each hook script.
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib/commens-hooks.sh"

# --- Input Parsing ---

# commens_read_input reads JSON from stdin and exports common fields.
commens_read_input() {
  HOOK_INPUT=$(cat)
  HOOK_SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // empty')
  HOOK_TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')
  HOOK_SOURCE=$(echo "$HOOK_INPUT" | jq -r '.source // empty')
  HOOK_REASON=$(echo "$HOOK_INPUT" | jq -r '.reason // empty')
  HOOK_MODEL=$(echo "$HOOK_INPUT" | jq -r '.model // empty')
  export HOOK_INPUT HOOK_SESSION_ID HOOK_TRANSCRIPT_PATH HOOK_SOURCE HOOK_REASON HOOK_MODEL
}

# --- Binary Resolution ---

# commens_resolve_binary locates the commens binary.
# Checks: COMMENS_BIN env → plugin root bin/ → PATH → common install locations.
commens_resolve_binary() {
  local plugin_root="${1:-}"

  if [ -n "${COMMENS_BIN:-}" ] && [ -x "${COMMENS_BIN}" ]; then
    COMMENS="${COMMENS_BIN}"
    return 0
  fi

  if [ -n "$plugin_root" ] && [ -x "${plugin_root}/bin/commens" ]; then
    COMMENS="${plugin_root}/bin/commens"
    return 0
  fi

  if command -v commens >/dev/null 2>&1; then
    COMMENS="commens"
    return 0
  fi

  for candidate in /usr/local/bin/commens "${HOME}/.local/bin/commens"; do
    if [ -x "$candidate" ]; then
      COMMENS="$candidate"
      return 0
    fi
  done

  COMMENS="commens"
  return 1
}

# --- Validation ---

commens_require_session_id() {
  if [ -z "$HOOK_SESSION_ID" ]; then
    commens_log "No session_id in hook input; skipping."
    exit 0
  fi
}

# --- Logging ---

commens_log() {
  echo "[commens-hook] $*" >&2
}

# --- Output Helpers ---

commens_output_context() {
  local context="$1"
  local event="${2:-SessionStart}"
  jq -n --arg ctx "$context" --arg evt "$event" '{
    "hookSpecificOutput": {
      "hookEventName": $evt,
      "additionalContext": $ctx
    }
  }'
}

commens_output_system_message() {
  local msg="$1"
  jq -n --arg msg "$msg" '{
    "systemMessage": $msg
  }'
}

commens_output_empty() {
  echo '{}'
}
