#!/usr/bin/env bash
# Tests for the "Cursor Cloud specific instructions" section added to CLAUDE.md.
# Verifies that every file, script, and flag documented there actually exists and
# behaves as described.
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

assert_file_exists() {
    local description="$1"
    local path="$2"
    if [[ -f "$path" ]]; then
        pass "$description"
    else
        fail "$description (missing: $path)"
    fi
}

assert_executable() {
    local description="$1"
    local path="$2"
    if [[ -x "$path" ]]; then
        pass "$description"
    else
        fail "$description (not executable: $path)"
    fi
}

assert_dir_exists() {
    local description="$1"
    local path="$2"
    if [[ -d "$path" ]]; then
        pass "$description"
    else
        fail "$description (missing directory: $path)"
    fi
}

assert_exit_zero() {
    local description="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description (command exited non-zero: $*)"
    fi
}

assert_exit_nonzero() {
    local description="$1"
    shift
    if ! "$@" >/dev/null 2>&1; then
        pass "$description"
    else
        fail "$description (expected non-zero exit but got zero: $*)"
    fi
}

assert_output_contains() {
    local description="$1"
    local needle="$2"
    shift 2
    local output
    output="$("$@" 2>&1 || true)"
    if [[ "$output" == *"$needle"* ]]; then
        pass "$description"
    else
        fail "$description (expected '$needle' in output, got: $output)"
    fi
}

# ---------------------------------------------------------------------------
# 1. Brainstorm companion — documented files exist and are executable
# ---------------------------------------------------------------------------

echo ""
echo "Brainstorm companion files"

BRAINSTORM_SCRIPTS="$REPO_ROOT/skills/brainstorming/scripts"

assert_file_exists \
    "server.cjs exists at skills/brainstorming/scripts/server.cjs" \
    "$BRAINSTORM_SCRIPTS/server.cjs"

assert_file_exists \
    "start-server.sh exists at skills/brainstorming/scripts/start-server.sh" \
    "$BRAINSTORM_SCRIPTS/start-server.sh"

assert_executable \
    "start-server.sh is executable" \
    "$BRAINSTORM_SCRIPTS/start-server.sh"

assert_file_exists \
    "stop-server.sh exists at skills/brainstorming/scripts/stop-server.sh" \
    "$BRAINSTORM_SCRIPTS/stop-server.sh"

assert_executable \
    "stop-server.sh is executable" \
    "$BRAINSTORM_SCRIPTS/stop-server.sh"

# Docs say Node built-ins only — no package.json should be present in scripts/
if [[ ! -f "$BRAINSTORM_SCRIPTS/package.json" ]]; then
    pass "No package.json in brainstorming scripts dir (Node built-ins only, no npm install needed)"
else
    fail "Unexpected package.json found in brainstorming scripts dir — docs say no npm install needed"
fi

# ---------------------------------------------------------------------------
# 2. start-server.sh flags documented in CLAUDE.md
# ---------------------------------------------------------------------------

echo ""
echo "start-server.sh documented flags"

# Unknown argument should output a JSON error and exit non-zero
assert_output_contains \
    "start-server.sh outputs JSON error for unknown flag" \
    '"error"' \
    bash "$BRAINSTORM_SCRIPTS/start-server.sh" --unknown-flag-xyz

assert_exit_nonzero \
    "start-server.sh exits non-zero for unknown flag" \
    bash "$BRAINSTORM_SCRIPTS/start-server.sh" --unknown-flag-xyz

# Verify --host flag is accepted (parse-only; passing a bad host that won't start a server
# is fine — we only care it doesn't reject the flag itself at parse time).
# We use --foreground with a background timeout kill to avoid actually starting the server;
# instead we check the parse path only via a dry-run-style trap.
# Simpler: check that the script does NOT print "Unknown argument: --host"
host_output="$(bash "$BRAINSTORM_SCRIPTS/start-server.sh" --host 127.0.0.1 --unknown-flag-xyz 2>&1 || true)"
if [[ "$host_output" != *"Unknown argument: --host"* ]]; then
    pass "--host flag is recognised (not rejected as unknown)"
else
    fail "--host flag was rejected as unknown"
fi

url_host_output="$(bash "$BRAINSTORM_SCRIPTS/start-server.sh" --url-host localhost --unknown-flag-xyz 2>&1 || true)"
if [[ "$url_host_output" != *"Unknown argument: --url-host"* ]]; then
    pass "--url-host flag is recognised (not rejected as unknown)"
else
    fail "--url-host flag was rejected as unknown"
fi

foreground_output="$(bash "$BRAINSTORM_SCRIPTS/start-server.sh" --foreground --unknown-flag-xyz 2>&1 || true)"
if [[ "$foreground_output" != *"Unknown argument: --foreground"* ]]; then
    pass "--foreground flag is recognised (not rejected as unknown)"
else
    fail "--foreground flag was rejected as unknown"
fi

# ---------------------------------------------------------------------------
# 3. stop-server.sh — documented contract: requires <session_dir> argument
# ---------------------------------------------------------------------------

echo ""
echo "stop-server.sh documented behaviour"

# No argument → JSON error, non-zero exit
assert_exit_nonzero \
    "stop-server.sh exits non-zero when called with no argument" \
    bash "$BRAINSTORM_SCRIPTS/stop-server.sh"

assert_output_contains \
    "stop-server.sh outputs JSON error when called with no argument" \
    '"error"' \
    bash "$BRAINSTORM_SCRIPTS/stop-server.sh"

# Non-existent session dir → JSON {status: "not_running"}, exit 0
nonexistent_dir="$(mktemp -d)"
rmdir "$nonexistent_dir"   # remove so it really doesn't exist
stop_output="$(bash "$BRAINSTORM_SCRIPTS/stop-server.sh" "$nonexistent_dir" 2>&1 || true)"
if [[ "$stop_output" == *'"not_running"'* ]]; then
    pass "stop-server.sh returns not_running for session dir with no PID file"
else
    fail "stop-server.sh unexpected output for missing session dir: $stop_output"
fi

# ---------------------------------------------------------------------------
# 4. Linting — scripts/lint-shell.sh and its documented flags
# ---------------------------------------------------------------------------

echo ""
echo "scripts/lint-shell.sh documented flags"

LINT_SCRIPT="$REPO_ROOT/scripts/lint-shell.sh"

assert_file_exists \
    "lint-shell.sh exists at scripts/lint-shell.sh" \
    "$LINT_SCRIPT"

assert_executable \
    "lint-shell.sh is executable" \
    "$LINT_SCRIPT"

# --help exits 0 (documents -h/--help support)
assert_exit_zero \
    "lint-shell.sh --help exits 0" \
    bash "$LINT_SCRIPT" --help

# Unknown flag must exit non-zero
assert_exit_nonzero \
    "lint-shell.sh exits non-zero for unknown flag" \
    bash "$LINT_SCRIPT" --unknown-flag-xyz

# Verify --all is a recognised flag (no "unknown option" error for it)
all_flag_output="$(bash "$LINT_SCRIPT" --all --unknown-flag-xyz 2>&1 || true)"
if [[ "$all_flag_output" != *"unknown option: --all"* ]]; then
    pass "--all flag is recognised by lint-shell.sh"
else
    fail "--all flag was rejected as unknown by lint-shell.sh"
fi

# Verify --format is a recognised flag
format_flag_output="$(bash "$LINT_SCRIPT" --format --unknown-flag-xyz 2>&1 || true)"
if [[ "$format_flag_output" != *"unknown option: --format"* ]]; then
    pass "--format flag is recognised by lint-shell.sh"
else
    fail "--format flag was rejected as unknown by lint-shell.sh"
fi

# ---------------------------------------------------------------------------
# 5. Self-contained test suites — directories and runner scripts exist
# ---------------------------------------------------------------------------

echo ""
echo "Self-contained test suite directories and runner scripts"

assert_dir_exists \
    "tests/brainstorm-server/ directory exists" \
    "$REPO_ROOT/tests/brainstorm-server"

assert_file_exists \
    "tests/brainstorm-server/package.json exists (npm test entry point)" \
    "$REPO_ROOT/tests/brainstorm-server/package.json"

assert_file_exists \
    "tests/opencode/run-tests.sh exists" \
    "$REPO_ROOT/tests/opencode/run-tests.sh"

# CLAUDE.md documents these as invoked with explicit 'bash <script>', so we
# check existence only — not the executable bit.
assert_file_exists \
    "tests/hooks/test-session-start.sh exists" \
    "$REPO_ROOT/tests/hooks/test-session-start.sh"

assert_file_exists \
    "tests/shell-lint/test-lint-shell.sh exists" \
    "$REPO_ROOT/tests/shell-lint/test-lint-shell.sh"

assert_file_exists \
    "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh exists" \
    "$REPO_ROOT/tests/codex-plugin-sync/test-sync-to-codex-plugin.sh"

assert_file_exists \
    "tests/kimi/run-tests.sh exists" \
    "$REPO_ROOT/tests/kimi/run-tests.sh"

# ---------------------------------------------------------------------------
# 6. External-agent test suite directories exist (but are documented as not runnable here)
# ---------------------------------------------------------------------------

echo ""
echo "External-agent test suite directories (documented as needing CLI/API key)"

assert_dir_exists \
    "tests/claude-code/ directory exists" \
    "$REPO_ROOT/tests/claude-code"

assert_dir_exists \
    "tests/antigravity/ directory exists" \
    "$REPO_ROOT/tests/antigravity"

assert_dir_exists \
    "tests/pi/ directory exists" \
    "$REPO_ROOT/tests/pi"

assert_dir_exists \
    "tests/explicit-skill-requests/ directory exists" \
    "$REPO_ROOT/tests/explicit-skill-requests"

# ---------------------------------------------------------------------------
# 7. skills/ directory exists (documented as the location of skill Markdown files)
# ---------------------------------------------------------------------------

echo ""
echo "skills/ directory"

assert_dir_exists \
    "skills/ directory exists" \
    "$REPO_ROOT/skills"

# ---------------------------------------------------------------------------
# 8. Boundary / negative cases
# ---------------------------------------------------------------------------

echo ""
echo "Boundary and negative cases"

# stop-server.sh must not accept more than zero positional args without the
# required one — passing empty string behaves like no arg logically (empty
# SESSION_DIR). The script itself checks -z "$SESSION_DIR".
empty_arg_output="$(bash "$BRAINSTORM_SCRIPTS/stop-server.sh" "" 2>&1 || true)"
if [[ "$empty_arg_output" == *'"error"'* ]]; then
    pass "stop-server.sh returns JSON error when called with empty session_dir"
else
    fail "stop-server.sh did not return JSON error for empty session_dir: $empty_arg_output"
fi

# lint-shell.sh --strict is also a supported flag (not documented in CLAUDE.md
# but must not break --all which IS documented). Regression guard: --all and
# --strict together must not emit an unknown-option error.
all_strict_output="$(bash "$LINT_SCRIPT" --all --strict --unknown-flag-xyz 2>&1 || true)"
if [[ "$all_strict_output" != *"unknown option: --all"* && "$all_strict_output" != *"unknown option: --strict"* ]]; then
    pass "--all and --strict together are both recognised by lint-shell.sh"
else
    fail "--all or --strict was rejected as unknown when used together"
fi

# start-server.sh --host and --url-host together, plus --foreground, must all be
# recognised (the exact combination documented in CLAUDE.md).
combo_output="$(bash "$BRAINSTORM_SCRIPTS/start-server.sh" \
    --host 127.0.0.1 --url-host localhost --foreground --unknown-flag-xyz 2>&1 || true)"
if [[ "$combo_output" != *"Unknown argument: --host"* && \
      "$combo_output" != *"Unknown argument: --url-host"* && \
      "$combo_output" != *"Unknown argument: --foreground"* ]]; then
    pass "Documented start-server.sh flag combination (--host --url-host --foreground) all recognised"
else
    fail "One or more of --host/--url-host/--foreground were rejected: $combo_output"
fi

# ---------------------------------------------------------------------------
# Final result
# ---------------------------------------------------------------------------

echo ""
if [[ "$FAILURES" -gt 0 ]]; then
    echo "STATUS: FAILED ($FAILURES failure(s))"
    exit 1
fi

echo "STATUS: PASSED"
