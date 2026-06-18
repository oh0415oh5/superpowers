#!/usr/bin/env bash
# Tests that verify the claims made in the "Cursor Cloud specific instructions"
# section of CLAUDE.md are accurate and backed by real files in the repository.
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
    echo "    expected file to exist: $path"
  fi
}

assert_dir_exists() {
  local path="$1"
  local description="$2"
  if [[ -d "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected directory to exist: $path"
  fi
}

assert_executable() {
  local path="$1"
  local description="$2"
  if [[ -x "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected file to be executable: $path"
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
    echo "    in content (first 20 lines):"
    printf '%s\n' "$haystack" | head -20 | sed 's/^/      /'
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

echo "Cursor Cloud docs (CLAUDE.md) accuracy tests"

# ── Brainstorm companion ─────────────────────────────────────────────────────

assert_file_exists \
  "$REPO_ROOT/skills/brainstorming/scripts/server.cjs" \
  "brainstorm server.cjs exists"

assert_executable \
  "$REPO_ROOT/skills/brainstorming/scripts/start-server.sh" \
  "start-server.sh exists and is executable"

assert_executable \
  "$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh" \
  "stop-server.sh exists and is executable"

# CLAUDE.md claims server.cjs uses "only Node built-ins — no npm install needed
# to run it."  Verify every require() call names a built-in module by checking
# that no line matches a require of a package that is NOT a known Node built-in.
# Known built-in modules referenced in server.cjs:
KNOWN_BUILTINS="crypto|http|fs|path|os|child_process|url|events|stream|buffer|net|tls|util|assert|module|cluster|dns|domain|punycode|querystring|readline|repl|string_decoder|timers|tty|v8|vm|zlib|perf_hooks|worker_threads|async_hooks|inspector|trace_events|diagnostics_channel|wasi"
server_cjs="$REPO_ROOT/skills/brainstorming/scripts/server.cjs"
server_requires="$(grep -o "require('[^']*')" "$server_cjs" | sed "s/^require('//;s/')$//")"
non_builtin_requires=""
while IFS= read -r mod; do
  if [[ -z "$mod" ]]; then
    continue
  fi
  if ! printf '%s' "$mod" | grep -qE "^($KNOWN_BUILTINS)$"; then
    non_builtin_requires="${non_builtin_requires} ${mod}"
  fi
done <<<"$server_requires"

if [[ -z "${non_builtin_requires// /}" ]]; then
  pass "server.cjs requires only Node built-in modules (no npm install needed)"
else
  fail "server.cjs requires only Node built-in modules (no npm install needed)"
  echo "    unexpected non-builtin require(s):$non_builtin_requires"
fi

# start-server.sh must not run npm install (server needs no npm deps)
start_sh_content="$(cat "$REPO_ROOT/skills/brainstorming/scripts/start-server.sh")"
assert_not_contains \
  "$start_sh_content" \
  "npm install" \
  "start-server.sh does not call npm install (server uses only Node built-ins)"

# ── Self-contained test suites ───────────────────────────────────────────────

assert_dir_exists \
  "$REPO_ROOT/tests/brainstorm-server" \
  "tests/brainstorm-server directory exists"

assert_file_exists \
  "$REPO_ROOT/tests/brainstorm-server/package.json" \
  "tests/brainstorm-server/package.json exists"

brainstorm_pkg="$(cat "$REPO_ROOT/tests/brainstorm-server/package.json")"
assert_contains \
  "$brainstorm_pkg" \
  '"ws"' \
  "tests/brainstorm-server/package.json lists ws dependency (as documented)"

assert_file_exists \
  "$REPO_ROOT/tests/opencode/run-tests.sh" \
  "tests/opencode/run-tests.sh exists"

assert_file_exists \
  "$REPO_ROOT/tests/hooks/test-session-start.sh" \
  "tests/hooks/test-session-start.sh exists"

assert_file_exists \
  "$REPO_ROOT/tests/shell-lint/test-lint-shell.sh" \
  "tests/shell-lint/test-lint-shell.sh exists"

assert_file_exists \
  "$REPO_ROOT/tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" \
  "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh exists"

assert_file_exists \
  "$REPO_ROOT/tests/kimi/run-tests.sh" \
  "tests/kimi/run-tests.sh exists"

# ── Non-self-contained test suites exist but require external tools ───────────

assert_dir_exists \
  "$REPO_ROOT/tests/claude-code" \
  "tests/claude-code directory exists (needs external claude CLI)"

assert_dir_exists \
  "$REPO_ROOT/tests/antigravity" \
  "tests/antigravity directory exists (needs external agent CLI)"

assert_dir_exists \
  "$REPO_ROOT/tests/pi" \
  "tests/pi directory exists (needs external agent CLI)"

assert_dir_exists \
  "$REPO_ROOT/tests/explicit-skill-requests" \
  "tests/explicit-skill-requests directory exists (needs external agent CLI)"

# evals/ is an optional external clone (superpowers-evals repo) and may not be
# present; CLAUDE.md notes it is "cloned into evals/" separately, so its
# absence is expected in a fresh checkout.  Only test if it IS present.
if [[ -d "$REPO_ROOT/evals" ]]; then
  pass "evals/ directory exists (optional external clone)"
else
  pass "evals/ not present (expected: it is an optional external clone per CLAUDE.md)"
fi

# ── Linting: scripts/lint-shell.sh ───────────────────────────────────────────

assert_file_exists \
  "$REPO_ROOT/scripts/lint-shell.sh" \
  "scripts/lint-shell.sh exists"

lint_sh_content="$(cat "$REPO_ROOT/scripts/lint-shell.sh")"

assert_contains \
  "$lint_sh_content" \
  "--all" \
  "scripts/lint-shell.sh supports --all flag (as documented)"

assert_contains \
  "$lint_sh_content" \
  "--format" \
  "scripts/lint-shell.sh supports --format flag (as documented)"

# Documented system deps: shellcheck, shfmt (for linting) and rsync (for
# codex-plugin-sync test).  Verify the lint script references these tools.
assert_contains \
  "$lint_sh_content" \
  "shellcheck" \
  "scripts/lint-shell.sh invokes shellcheck (documented required system dep)"

assert_contains \
  "$lint_sh_content" \
  "shfmt" \
  "scripts/lint-shell.sh invokes shfmt (documented required system dep)"

# codex-plugin-sync test uses rsync — verify the sync test script references it
codex_sync_content="$(cat "$REPO_ROOT/tests/codex-plugin-sync/test-sync-to-codex-plugin.sh")"
assert_contains \
  "$codex_sync_content" \
  "rsync" \
  "codex-plugin-sync test uses rsync (documented as additional required dep)"

# ── Final summary ─────────────────────────────────────────────────────────────

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All Cursor Cloud docs tests passed"
else
  echo "$FAILURES Cursor Cloud docs test(s) failed"
  exit 1
fi
