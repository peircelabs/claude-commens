#!/bin/bash
# test-hooks.sh — Integration tests for Commens hook scripts.
#
# Uses a temporary COMMENS_HOME with a fresh Dolt ledger to verify
# that each hook script runs successfully against the real commens CLI.
#
# Usage:
#   ./tests/test-hooks.sh
#
# Prerequisites:
#   - commens CLI installed and in PATH
#   - jq installed and in PATH
#   - dolt installed and in PATH
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="${REPO_ROOT}/scripts"

# --- Test Framework ---

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

pass() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_PASSED=$((TESTS_PASSED + 1))
  echo "  PASS: $1"
}

fail() {
  TESTS_RUN=$((TESTS_RUN + 1))
  TESTS_FAILED=$((TESTS_FAILED + 1))
  FAILURES="${FAILURES}\n  FAIL: $1"
  echo "  FAIL: $1"
}

assert_exit_zero() {
  local name="$1"
  local exit_code="$2"
  if [ "$exit_code" -eq 0 ]; then
    pass "$name"
  else
    fail "$name (exit code: $exit_code)"
  fi
}

assert_not_empty() {
  local name="$1"
  local value="$2"
  if [ -n "$value" ]; then
    pass "$name"
  else
    fail "$name (empty result)"
  fi
}

assert_contains() {
  local name="$1"
  local haystack="$2"
  local needle="$3"
  if echo "$haystack" | grep -q "$needle"; then
    pass "$name"
  else
    fail "$name (expected to contain: $needle)"
  fi
}

# --- Setup ---

setup() {
  echo "Setting up test environment..."

  # Create isolated commens home.
  TEST_COMMENS_HOME=$(mktemp -d)
  export COMMENS_HOME="$TEST_COMMENS_HOME"

  # Bootstrap config and ledger.
  commens config init --project test-project --force 2>/dev/null
  commens init --project test-project --force 2>/dev/null

  # Create a mock transcript file for record-interaction tests.
  TEST_TRANSCRIPT=$(mktemp)
  cat > "$TEST_TRANSCRIPT" << 'TRANSCRIPT'
{"role": "user", "content": "What is 2+2?"}
{"role": "assistant", "content": "2+2 equals 4."}
TRANSCRIPT

  # Session ID used across all tests.
  TEST_SESSION_ID="test-session-$(date +%s)"

  echo "  COMMENS_HOME=$TEST_COMMENS_HOME"
  echo "  TEST_SESSION_ID=$TEST_SESSION_ID"
  echo ""
}

# --- Teardown ---

teardown() {
  echo ""
  echo "Cleaning up..."
  rm -rf "$TEST_COMMENS_HOME"
  rm -f "$TEST_TRANSCRIPT"
  echo "  Removed $TEST_COMMENS_HOME"
}

# --- Tests ---

test_session_start() {
  echo "Test: session-start.sh"

  local output exit_code
  output=$(echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"$TEST_TRANSCRIPT\",
    \"cwd\": \"$REPO_ROOT\",
    \"permission_mode\": \"default\",
    \"hook_event_name\": \"SessionStart\",
    \"source\": \"startup\",
    \"model\": \"test-model\"
  }" | bash "$SCRIPTS_DIR/session-start.sh" 2>/dev/null) && exit_code=0 || exit_code=$?

  assert_exit_zero "session-start.sh exits 0" "$exit_code"
  assert_not_empty "session-start.sh produces output" "$output"

  # Verify the session was registered on the ledger.
  local sessions
  sessions=$(commens session list --json 2>/dev/null || echo "")
  assert_contains "session appears in ledger" "$sessions" "$TEST_SESSION_ID"
}

test_session_resume() {
  echo "Test: session-resume.sh"

  local exit_code
  echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"$TEST_TRANSCRIPT\",
    \"cwd\": \"$REPO_ROOT\",
    \"permission_mode\": \"default\",
    \"hook_event_name\": \"SessionStart\",
    \"source\": \"resume\",
    \"model\": \"test-model\"
  }" | bash "$SCRIPTS_DIR/session-resume.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "session-resume.sh exits 0" "$exit_code"
}

test_record_interaction() {
  echo "Test: record-interaction.sh"

  local exit_code
  echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"$TEST_TRANSCRIPT\",
    \"cwd\": \"$REPO_ROOT\",
    \"permission_mode\": \"default\",
    \"hook_event_name\": \"Stop\",
    \"stop_hook_active\": false,
    \"last_assistant_message\": \"2+2 equals 4.\"
  }" | bash "$SCRIPTS_DIR/record-interaction.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "record-interaction.sh exits 0" "$exit_code"

  # Verify interaction was recorded.
  local interactions
  interactions=$(commens session interaction list --session-id "$TEST_SESSION_ID" --json 2>/dev/null || echo "")
  assert_contains "interaction recorded in ledger" "$interactions" "$TEST_SESSION_ID"
}

test_pre_compact() {
  echo "Test: pre-compact.sh"

  local exit_code
  echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"$TEST_TRANSCRIPT\",
    \"cwd\": \"$REPO_ROOT\",
    \"permission_mode\": \"default\",
    \"hook_event_name\": \"PreCompact\",
    \"trigger\": \"manual\",
    \"custom_instructions\": \"\"
  }" | bash "$SCRIPTS_DIR/pre-compact.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "pre-compact.sh exits 0" "$exit_code"
}

test_session_end() {
  echo "Test: session-end.sh"

  local exit_code
  echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"$TEST_TRANSCRIPT\",
    \"cwd\": \"$REPO_ROOT\",
    \"permission_mode\": \"default\",
    \"hook_event_name\": \"SessionEnd\",
    \"reason\": \"other\"
  }" | bash "$SCRIPTS_DIR/session-end.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "session-end.sh exits 0" "$exit_code"
}

test_missing_session_id() {
  echo "Test: missing session_id gracefully exits 0"

  local exit_code
  echo '{"session_id": ""}' \
    | bash "$SCRIPTS_DIR/session-start.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "graceful exit on empty session_id" "$exit_code"
}

test_missing_transcript() {
  echo "Test: record-interaction.sh with missing transcript gracefully exits 0"

  local exit_code
  echo "{
    \"session_id\": \"$TEST_SESSION_ID\",
    \"transcript_path\": \"/nonexistent/path.jsonl\"
  }" | bash "$SCRIPTS_DIR/record-interaction.sh" >/dev/null 2>&1 && exit_code=0 || exit_code=$?

  assert_exit_zero "graceful exit on missing transcript" "$exit_code"
}

# --- Main ---

main() {
  echo "=== Commens Hook Integration Tests ==="
  echo ""

  # Check prerequisites.
  for cmd in commens jq dolt; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "ERROR: $cmd is required but not found in PATH"
      exit 1
    fi
  done

  setup

  # Run tests in lifecycle order.
  test_session_start
  test_session_resume
  test_record_interaction
  test_pre_compact
  test_session_end

  # Edge cases.
  test_missing_session_id
  test_missing_transcript

  teardown

  # Summary.
  echo ""
  echo "=== Results: $TESTS_PASSED/$TESTS_RUN passed ==="
  if [ "$TESTS_FAILED" -gt 0 ]; then
    echo -e "\nFailures:$FAILURES"
    exit 1
  fi
}

main "$@"
