#!/usr/bin/env bash
# Tests that the Cursor Cloud specific instructions in CLAUDE.md are accurate:
# referenced scripts exist, support the documented flags, and have the
# described properties.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

FAILURES=0

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

assert_file_exists() {
  local path="$1"
  local description="$2"

  if [[ -f "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected file: $path"
  fi
}

assert_dir_exists() {
  local path="$1"
  local description="$2"

  if [[ -d "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected directory: $path"
  fi
}

assert_executable() {
  local path="$1"
  local description="$2"

  if [[ -x "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected executable: $path"
  fi
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
    echo "    in:"
    printf '%s\n' "$haystack" | sed 's/^/      /'
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  if printf '%s' "$haystack" | grep -Fq -- "$needle"; then
    fail "$description"
    echo "    did not expect to find: $needle"
    echo "    in:"
    printf '%s\n' "$haystack" | sed 's/^/      /'
  else
    pass "$description"
  fi
}

echo "Cursor Cloud instructions accuracy tests"

# ---------------------------------------------------------------------------
# 1. Referenced scripts exist and are executable
# ---------------------------------------------------------------------------

SERVER_CJS="$REPO_ROOT/skills/brainstorming/scripts/server.cjs"
START_SH="$REPO_ROOT/skills/brainstorming/scripts/start-server.sh"
STOP_SH="$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh"
LINT_SH="$REPO_ROOT/scripts/lint-shell.sh"

assert_file_exists "$SERVER_CJS" "server.cjs exists"
assert_file_exists "$START_SH" "start-server.sh exists"
assert_file_exists "$STOP_SH" "stop-server.sh exists"
assert_file_exists "$LINT_SH" "lint-shell.sh exists"

assert_executable "$START_SH" "start-server.sh is executable"
assert_executable "$STOP_SH" "stop-server.sh is executable"
assert_executable "$LINT_SH" "lint-shell.sh is executable"

# ---------------------------------------------------------------------------
# 2. Documented test suites exist
# ---------------------------------------------------------------------------

assert_dir_exists "$REPO_ROOT/tests/brainstorm-server" "tests/brainstorm-server/ exists"
assert_file_exists "$REPO_ROOT/tests/brainstorm-server/package.json" "tests/brainstorm-server/package.json exists (npm test)"
assert_file_exists "$REPO_ROOT/tests/opencode/run-tests.sh" "tests/opencode/run-tests.sh exists"
assert_file_exists "$REPO_ROOT/tests/hooks/test-session-start.sh" "tests/hooks/test-session-start.sh exists"
assert_file_exists "$REPO_ROOT/tests/shell-lint/test-lint-shell.sh" "tests/shell-lint/test-lint-shell.sh exists"
assert_file_exists "$REPO_ROOT/tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh exists"
assert_file_exists "$REPO_ROOT/tests/kimi/run-tests.sh" "tests/kimi/run-tests.sh exists"

# ---------------------------------------------------------------------------
# 3. start-server.sh supports documented flags: --host, --url-host, --foreground
# ---------------------------------------------------------------------------

start_src="$(cat "$START_SH")"

assert_contains "$start_src" "--host)" "start-server.sh handles --host flag"
assert_contains "$start_src" "--url-host)" "start-server.sh handles --url-host flag"
assert_contains "$start_src" "--foreground" "start-server.sh handles --foreground flag"
assert_contains "$start_src" "127.0.0.1" "start-server.sh defaults bind host to 127.0.0.1"

# ---------------------------------------------------------------------------
# 4. start-server.sh rejects unknown arguments (negative test)
# ---------------------------------------------------------------------------

unknown_arg_output="$(bash "$START_SH" --unknown-flag-xyz 2>&1 || true)"
assert_contains "$unknown_arg_output" "Unknown argument" "start-server.sh rejects unknown flags"

# ---------------------------------------------------------------------------
# 5. stop-server.sh requires a session_dir argument
# ---------------------------------------------------------------------------

stop_output="$(bash "$STOP_SH" 2>&1 || true)"
assert_contains "$stop_output" "Usage" "stop-server.sh exits with usage when no session_dir given"

# ---------------------------------------------------------------------------
# 6. server.cjs uses only Node built-in modules (no third-party npm deps)
# ---------------------------------------------------------------------------

server_src="$(cat "$SERVER_CJS")"

# These are the built-in Node modules — all documented as "no npm install needed"
assert_contains "$server_src" "require('http')" "server.cjs uses built-in http module"
assert_contains "$server_src" "require('fs')" "server.cjs uses built-in fs module"
assert_contains "$server_src" "require('path')" "server.cjs uses built-in path module"

# Verify no non-built-in require() calls (third-party packages use bare names
# without slashes and are not among the known Node built-ins)
builtin_modules="assert|buffer|child_process|cluster|console|constants|crypto|dgram|dns|domain|events|fs|http|http2|https|inspector|module|net|os|path|perf_hooks|process|punycode|querystring|readline|repl|stream|string_decoder|sys|timers|tls|trace_events|tty|url|util|v8|vm|wasi|worker_threads|zlib"

# Extract require() arguments that look like bare package names (no path separators,
# no leading dot), then filter out known built-ins
third_party_requires="$(
  grep -oE "require\('[^']+'\)" "$SERVER_CJS" \
    | grep -oE "'[^']+'" \
    | tr -d "'" \
    | grep -vE '^[./]' \
    | grep -vE "^($builtin_modules)$" \
    || true
)"

if [[ -z "$third_party_requires" ]]; then
  pass "server.cjs has no third-party npm require() calls"
else
  fail "server.cjs has third-party npm require() calls"
  echo "    unexpected requires:"
  printf '%s\n' "$third_party_requires" | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
# 7. lint-shell.sh supports documented flags: --all, --format
# ---------------------------------------------------------------------------

lint_src="$(cat "$LINT_SH")"

assert_contains "$lint_src" "--all)" "lint-shell.sh handles --all flag"
assert_contains "$lint_src" "--format)" "lint-shell.sh handles --format flag"

# Verify the documented default behaviour: changed files only (not --all)
assert_contains "$lint_src" "collect_changed_shell_files" "lint-shell.sh defaults to changed files"

# ---------------------------------------------------------------------------
# 8. CLAUDE.md contains the Cursor Cloud section
# ---------------------------------------------------------------------------

claude_md="$(cat "$REPO_ROOT/CLAUDE.md")"

assert_contains "$claude_md" "## Cursor Cloud specific instructions" "CLAUDE.md has Cursor Cloud section"
assert_contains "$claude_md" "skills/brainstorming/scripts/server.cjs" "CLAUDE.md references server.cjs"
assert_contains "$claude_md" "skills/brainstorming/scripts/start-server.sh" "CLAUDE.md references start-server.sh"
assert_contains "$claude_md" "skills/brainstorming/scripts/stop-server.sh" "CLAUDE.md references stop-server.sh"
assert_contains "$claude_md" "scripts/lint-shell.sh" "CLAUDE.md references lint-shell.sh"
assert_contains "$claude_md" "--host 127.0.0.1 --url-host localhost" "CLAUDE.md documents bind/host flags example"
assert_contains "$claude_md" "--foreground" "CLAUDE.md documents --foreground flag"
assert_contains "$claude_md" "--all" "CLAUDE.md documents --all flag for lint-shell.sh"
assert_contains "$claude_md" "--format" "CLAUDE.md documents --format flag for lint-shell.sh"
assert_contains "$claude_md" "no \`npm install\` needed" "CLAUDE.md states server.cjs needs no npm install"
assert_contains "$claude_md" "sessionStorage" "CLAUDE.md describes one-time bootstrap key mechanism"
assert_contains "$claude_md" "JSONL" "CLAUDE.md describes event format"

# Boundary: section must document that the events file does not exist until interaction
assert_contains "$claude_md" "events file does not exist until the first interaction" \
  "CLAUDE.md notes events file is absent before first interaction"

# Negative: section should not claim npm install is required for server
assert_not_contains "$claude_md" "npm install.*server.cjs" \
  "CLAUDE.md does not instruct running npm install for server.cjs"

# ---------------------------------------------------------------------------
# Result
# ---------------------------------------------------------------------------

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All Cursor Cloud instructions tests passed"
else
  echo "$FAILURES Cursor Cloud instructions test(s) failed"
  exit 1
fi
