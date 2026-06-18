#!/usr/bin/env bash
# Tests for the "Cursor Cloud specific instructions" section added to CLAUDE.md.
# Validates that:
#   1. The documented section and cross-references exist in CLAUDE.md.
#   2. Every file/directory path mentioned in the section actually exists.
#   3. Documented CLI flags are implemented by the referenced scripts.
#   4. server.cjs relies only on Node.js built-in modules.
#   5. Non-runnable test suites listed as requiring external tools exist on disk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
START_SERVER="$REPO_ROOT/skills/brainstorming/scripts/start-server.sh"
STOP_SERVER="$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh"
SERVER_CJS="$REPO_ROOT/skills/brainstorming/scripts/server.cjs"
LINT_SHELL="$REPO_ROOT/scripts/lint-shell.sh"

FAILURES=0

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    pass "$description"
  else
    fail "$description"
    echo "    expected to find: $needle"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "$description"
    echo "    did not expect to find: $needle"
  else
    pass "$description"
  fi
}

assert_file_exists() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    missing file: $path"
  fi
}

assert_file_executable() {
  local path="$1"
  local description="$2"

  if [[ -x "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    not executable: $path"
  fi
}

assert_dir_exists() {
  local path="$1"
  local description="$2"

  if [[ -d "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    missing directory: $path"
  fi
}

# ---------------------------------------------------------------------------
echo "CLAUDE.md Cursor Cloud section — documentation accuracy tests"
# ---------------------------------------------------------------------------

# --- Section 1: The new section and its cross-references exist in CLAUDE.md ---

echo ""
echo "  Section header and cross-references"

claude_md_content="$(cat "$CLAUDE_MD")"

assert_contains "$claude_md_content" \
  "## Cursor Cloud specific instructions" \
  "CLAUDE.md contains the Cursor Cloud specific instructions section header"

assert_contains "$claude_md_content" \
  "skills/brainstorming/scripts/server.cjs" \
  "CLAUDE.md references server.cjs path"

assert_contains "$claude_md_content" \
  "skills/brainstorming/scripts/start-server.sh" \
  "CLAUDE.md references start-server.sh path"

assert_contains "$claude_md_content" \
  "skills/brainstorming/scripts/stop-server.sh" \
  "CLAUDE.md references stop-server.sh path"

assert_contains "$claude_md_content" \
  "scripts/lint-shell.sh" \
  "CLAUDE.md references lint-shell.sh path"

assert_contains "$claude_md_content" \
  "--foreground" \
  "CLAUDE.md documents the --foreground flag for start-server.sh"

assert_contains "$claude_md_content" \
  "--host 127.0.0.1 --url-host localhost" \
  "CLAUDE.md documents the --host and --url-host flag combination"

assert_contains "$claude_md_content" \
  "tests/brainstorm-server" \
  "CLAUDE.md references tests/brainstorm-server test suite"

assert_contains "$claude_md_content" \
  "tests/opencode/run-tests.sh" \
  "CLAUDE.md references tests/opencode/run-tests.sh"

assert_contains "$claude_md_content" \
  "tests/hooks/test-session-start.sh" \
  "CLAUDE.md references tests/hooks/test-session-start.sh"

assert_contains "$claude_md_content" \
  "tests/shell-lint/test-lint-shell.sh" \
  "CLAUDE.md references tests/shell-lint/test-lint-shell.sh"

assert_contains "$claude_md_content" \
  "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" \
  "CLAUDE.md references tests/codex-plugin-sync/test-sync-to-codex-plugin.sh"

assert_contains "$claude_md_content" \
  "tests/kimi/run-tests.sh" \
  "CLAUDE.md references tests/kimi/run-tests.sh"

assert_contains "$claude_md_content" \
  "npm_config_prefix" \
  "CLAUDE.md documents the nvm/npm_config_prefix warning"

assert_contains "$claude_md_content" \
  "shellcheck" \
  "CLAUDE.md documents shellcheck as a system dependency"

assert_contains "$claude_md_content" \
  "shfmt" \
  "CLAUDE.md documents shfmt as a system dependency"

assert_contains "$claude_md_content" \
  "stop-server.sh <session_dir>" \
  "CLAUDE.md documents stop-server.sh usage with <session_dir> argument"

# --- Section 2: Every referenced file/directory actually exists on disk ---

echo ""
echo "  Referenced files and directories exist on disk"

assert_file_exists "$SERVER_CJS" \
  "skills/brainstorming/scripts/server.cjs exists"

assert_file_exists "$START_SERVER" \
  "skills/brainstorming/scripts/start-server.sh exists"

assert_file_executable "$START_SERVER" \
  "skills/brainstorming/scripts/start-server.sh is executable"

assert_file_exists "$STOP_SERVER" \
  "skills/brainstorming/scripts/stop-server.sh exists"

assert_file_executable "$STOP_SERVER" \
  "skills/brainstorming/scripts/stop-server.sh is executable"

assert_file_exists "$LINT_SHELL" \
  "scripts/lint-shell.sh exists"

assert_file_executable "$LINT_SHELL" \
  "scripts/lint-shell.sh is executable"

assert_dir_exists "$REPO_ROOT/tests/brainstorm-server" \
  "tests/brainstorm-server/ directory exists"

assert_file_exists "$REPO_ROOT/tests/brainstorm-server/package.json" \
  "tests/brainstorm-server/package.json exists"

assert_file_exists "$REPO_ROOT/tests/opencode/run-tests.sh" \
  "tests/opencode/run-tests.sh exists"

assert_file_exists "$REPO_ROOT/tests/hooks/test-session-start.sh" \
  "tests/hooks/test-session-start.sh exists"

assert_file_exists "$REPO_ROOT/tests/shell-lint/test-lint-shell.sh" \
  "tests/shell-lint/test-lint-shell.sh exists"

assert_file_exists "$REPO_ROOT/tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" \
  "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh exists"

assert_file_exists "$REPO_ROOT/tests/kimi/run-tests.sh" \
  "tests/kimi/run-tests.sh exists"

# --- Section 3: tests/brainstorm-server package.json has an npm "test" script ---

echo ""
echo "  tests/brainstorm-server npm test script"

brainstorm_pkg="$(cat "$REPO_ROOT/tests/brainstorm-server/package.json")"

assert_contains "$brainstorm_pkg" \
  '"test"' \
  "tests/brainstorm-server/package.json declares a test script"

# --- Section 4: Documented flags are implemented in start-server.sh ---

echo ""
echo "  start-server.sh CLI flags match CLAUDE.md documentation"

start_server_content="$(cat "$START_SERVER")"

assert_contains "$start_server_content" \
  "--foreground" \
  "start-server.sh implements the --foreground flag"

assert_contains "$start_server_content" \
  "--host)" \
  "start-server.sh implements the --host flag"

assert_contains "$start_server_content" \
  "--url-host)" \
  "start-server.sh implements the --url-host flag"

assert_contains "$start_server_content" \
  '127.0.0.1' \
  "start-server.sh uses 127.0.0.1 as default bind host"

# --- Section 5: stop-server.sh positional argument handling ---

echo ""
echo "  stop-server.sh session_dir argument handling"

stop_server_content="$(cat "$STOP_SERVER")"

assert_contains "$stop_server_content" \
  'SESSION_DIR="$1"' \
  "stop-server.sh reads SESSION_DIR from positional argument \$1"

assert_contains "$stop_server_content" \
  'stop-server.sh <session_dir>' \
  "stop-server.sh usage error mentions <session_dir>"

# Invoke stop-server.sh without arguments; it must exit non-zero and print an error.
stop_output="$(bash "$STOP_SERVER" 2>&1 || true)"
stop_exit_code=0
bash "$STOP_SERVER" >/dev/null 2>&1 || stop_exit_code=$?

if [[ "$stop_exit_code" -ne 0 ]]; then
  pass "stop-server.sh exits non-zero when called without arguments"
else
  fail "stop-server.sh exits non-zero when called without arguments"
fi

assert_contains "$stop_output" \
  "session_dir" \
  "stop-server.sh outputs usage hint when called without arguments"

# --- Section 6: server.cjs uses only Node.js built-in modules ---

echo ""
echo "  server.cjs relies only on Node.js built-in modules"

# Extract every require('...') or require("...") call from server.cjs.
# The regex matches the module name inside the quotes.
node_builtins="assert|buffer|child_process|cluster|console|constants|crypto|dgram|dns|domain|events|fs|http|http2|https|inspector|module|net|os|path|perf_hooks|process|punycode|querystring|readline|repl|stream|string_decoder|timers|tls|trace_events|tty|url|util|v8|vm|worker_threads|zlib"

# Collect module names: strip the require( ... ) wrapper, then strip surrounding quotes.
required_modules="$(grep -o "require('[^']*')" "$SERVER_CJS" || true)"
required_modules+="$(grep -o 'require("[^"]*")' "$SERVER_CJS" || true)"

if [[ -z "$required_modules" ]]; then
  pass "server.cjs has no require() calls (no external dependencies)"
else
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Extract module name: strip require( and closing ) then strip quotes
    mod="${line#require(}"
    mod="${mod%)}"
    mod="${mod//\'/}"
    mod="${mod//\"/}"
    if printf '%s' "$mod" | grep -qE "^($node_builtins)$"; then
      pass "server.cjs require('$mod') is a Node.js built-in"
    else
      fail "server.cjs require('$mod') is NOT a Node.js built-in — introduces an external dependency"
    fi
  done <<< "$required_modules"
fi

# --- Section 7: Non-runnable test suite directories exist ---

echo ""
echo "  Non-runnable test suite directories exist on disk"

assert_dir_exists "$REPO_ROOT/tests/claude-code" \
  "tests/claude-code/ directory exists (needs 'claude' CLI, not runnable here)"

assert_dir_exists "$REPO_ROOT/tests/antigravity" \
  "tests/antigravity/ directory exists (not runnable here)"

assert_dir_exists "$REPO_ROOT/tests/pi" \
  "tests/pi/ directory exists (not runnable here)"

assert_dir_exists "$REPO_ROOT/tests/explicit-skill-requests" \
  "tests/explicit-skill-requests/ directory exists (not runnable here)"

# --- Section 8: Regression and boundary checks ---

echo ""
echo "  Regression and boundary checks"

# start-server.sh must reject unknown flags with a non-zero exit and JSON error
unknown_flag_output="$(bash "$START_SERVER" --unknown-flag-xyz 2>&1 || true)"
unknown_flag_exit=0
bash "$START_SERVER" --unknown-flag-xyz >/dev/null 2>&1 || unknown_flag_exit=$?

if [[ "$unknown_flag_exit" -ne 0 ]]; then
  pass "start-server.sh exits non-zero for unknown flags"
else
  fail "start-server.sh exits non-zero for unknown flags"
fi

assert_contains "$unknown_flag_output" \
  "Unknown argument" \
  "start-server.sh reports unknown flag in error output"

# CLAUDE.md must mention that server uses only Node built-ins (no npm install needed)
assert_contains "$claude_md_content" \
  "no \`npm install\` needed" \
  "CLAUDE.md states no npm install needed to run the server"

# CLAUDE.md must mention the events JSONL file behaviour
assert_contains "$claude_md_content" \
  "events" \
  "CLAUDE.md mentions the events file for browser interactions"

# Confirm section appears after the General section (ordering sanity check)
general_pos="$(grep -n "^## General" "$CLAUDE_MD" | head -1 | cut -d: -f1)"
cursor_pos="$(grep -n "^## Cursor Cloud specific instructions" "$CLAUDE_MD" | head -1 | cut -d: -f1)"

if [[ -n "$general_pos" && -n "$cursor_pos" && "$cursor_pos" -gt "$general_pos" ]]; then
  pass "Cursor Cloud section appears after the General section in CLAUDE.md"
else
  fail "Cursor Cloud section appears after the General section in CLAUDE.md"
fi

# ---------------------------------------------------------------------------
echo ""
if [[ "$FAILURES" -eq 0 ]]; then
  echo "All CLAUDE.md Cursor Cloud documentation tests passed"
else
  echo "$FAILURES CLAUDE.md Cursor Cloud documentation test(s) failed"
  exit 1
fi
