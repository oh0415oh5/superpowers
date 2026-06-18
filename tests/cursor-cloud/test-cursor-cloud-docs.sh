#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"

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
    echo "    in content above"
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

assert_executable() {
  local path="$1"
  local description="$2"

  if [[ -x "$path" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    not executable: $path"
  fi
}

echo "CLAUDE.md Cursor Cloud documentation tests"

# ── Section presence ──────────────────────────────────────────────────────────

CLAUDE_CONTENT="$(cat "$CLAUDE_MD")"

assert_file_exists "$CLAUDE_MD" "CLAUDE.md exists"
assert_contains "$CLAUDE_CONTENT" "## Cursor Cloud specific instructions" \
  "CLAUDE.md contains 'Cursor Cloud specific instructions' section"

# ── Brainstorm companion references ───────────────────────────────────────────

assert_contains "$CLAUDE_CONTENT" "skills/brainstorming/scripts/server.cjs" \
  "CLAUDE.md documents brainstorm server.cjs path"
assert_contains "$CLAUDE_CONTENT" "skills/brainstorming/scripts/start-server.sh" \
  "CLAUDE.md documents start-server.sh path"
assert_contains "$CLAUDE_CONTENT" "skills/brainstorming/scripts/stop-server.sh" \
  "CLAUDE.md documents stop-server.sh path"
assert_contains "$CLAUDE_CONTENT" "--foreground" \
  "CLAUDE.md mentions --foreground flag for persistent-shell use"
assert_contains "$CLAUDE_CONTENT" "--host 127.0.0.1 --url-host localhost" \
  "CLAUDE.md documents bind/host flags for on-VM browser"
assert_contains "$CLAUDE_CONTENT" "sessionStorage" \
  "CLAUDE.md explains one-time bootstrap key storage in sessionStorage"
assert_contains "$CLAUDE_CONTENT" "JSONL" \
  "CLAUDE.md describes events file format as JSONL"

# ── Documented scripts exist and are executable ───────────────────────────────

assert_file_exists "$REPO_ROOT/skills/brainstorming/scripts/server.cjs" \
  "server.cjs exists on disk"
assert_file_exists "$REPO_ROOT/skills/brainstorming/scripts/start-server.sh" \
  "start-server.sh exists on disk"
assert_executable "$REPO_ROOT/skills/brainstorming/scripts/start-server.sh" \
  "start-server.sh is executable"
assert_file_exists "$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh" \
  "stop-server.sh exists on disk"
assert_executable "$REPO_ROOT/skills/brainstorming/scripts/stop-server.sh" \
  "stop-server.sh is executable"

# ── Linting references ────────────────────────────────────────────────────────

assert_contains "$CLAUDE_CONTENT" "scripts/lint-shell.sh" \
  "CLAUDE.md documents lint-shell.sh path"
assert_contains "$CLAUDE_CONTENT" "--all" \
  "CLAUDE.md documents --all flag for lint-shell.sh"
assert_contains "$CLAUDE_CONTENT" "--format" \
  "CLAUDE.md documents --format flag for lint-shell.sh"
assert_contains "$CLAUDE_CONTENT" "shellcheck" \
  "CLAUDE.md lists shellcheck as a required system tool"
assert_contains "$CLAUDE_CONTENT" "shfmt" \
  "CLAUDE.md lists shfmt as a required system tool"
assert_contains "$CLAUDE_CONTENT" "rsync" \
  "CLAUDE.md lists rsync as a required system tool"
assert_contains "$CLAUDE_CONTENT" "sudo apt-get install -y shellcheck shfmt rsync" \
  "CLAUDE.md provides apt-get install command for missing system deps"

assert_file_exists "$REPO_ROOT/scripts/lint-shell.sh" \
  "scripts/lint-shell.sh exists on disk"
assert_executable "$REPO_ROOT/scripts/lint-shell.sh" \
  "scripts/lint-shell.sh is executable"

# ── Documented self-contained test suites exist ───────────────────────────────

assert_contains "$CLAUDE_CONTENT" "tests/brainstorm-server" \
  "CLAUDE.md mentions tests/brainstorm-server suite"
assert_contains "$CLAUDE_CONTENT" "tests/opencode/run-tests.sh" \
  "CLAUDE.md mentions tests/opencode/run-tests.sh"
assert_contains "$CLAUDE_CONTENT" "tests/hooks/test-session-start.sh" \
  "CLAUDE.md mentions tests/hooks/test-session-start.sh"
assert_contains "$CLAUDE_CONTENT" "tests/shell-lint/test-lint-shell.sh" \
  "CLAUDE.md mentions tests/shell-lint/test-lint-shell.sh"
assert_contains "$CLAUDE_CONTENT" "tests/codex-plugin-sync/test-sync-to-codex-plugin.sh" \
  "CLAUDE.md mentions tests/codex-plugin-sync/test-sync-to-codex-plugin.sh"
assert_contains "$CLAUDE_CONTENT" "tests/kimi/run-tests.sh" \
  "CLAUDE.md mentions tests/kimi/run-tests.sh"

assert_dir_exists "$REPO_ROOT/tests/brainstorm-server" \
  "tests/brainstorm-server directory exists"
assert_file_exists "$REPO_ROOT/tests/brainstorm-server/package.json" \
  "tests/brainstorm-server/package.json exists (local ws dep)"
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

# ── Suites documented as needing external CLI are NOT listed as self-contained ──

assert_contains "$CLAUDE_CONTENT" "tests/claude-code" \
  "CLAUDE.md acknowledges tests/claude-code suite"
assert_contains "$CLAUDE_CONTENT" "tests/antigravity" \
  "CLAUDE.md acknowledges tests/antigravity suite"
assert_contains "$CLAUDE_CONTENT" "tests/pi" \
  "CLAUDE.md acknowledges tests/pi suite"
assert_contains "$CLAUDE_CONTENT" "tests/explicit-skill-requests" \
  "CLAUDE.md acknowledges tests/explicit-skill-requests suite"
assert_contains "$CLAUDE_CONTENT" "evals/" \
  "CLAUDE.md acknowledges evals/ drill harness"

# ── npm install warning note ──────────────────────────────────────────────────

assert_contains "$CLAUDE_CONTENT" "npm install" \
  "CLAUDE.md mentions npm install"
assert_contains "$CLAUDE_CONTENT" "nvm is not compatible with the" \
  "CLAUDE.md documents the nvm warning text"
assert_contains "$CLAUDE_CONTENT" "unset npm_config_prefix" \
  "CLAUDE.md provides workaround to silence nvm warning"

# ── No single root npm test claimed ──────────────────────────────────────────

assert_contains "$CLAUDE_CONTENT" "no single app server or root" \
  "CLAUDE.md clarifies there is no single root npm test"

# ── skills/ directory reference accurate ─────────────────────────────────────

assert_dir_exists "$REPO_ROOT/skills" \
  "skills/ directory exists as documented"

# ── Regression: section is in correct location (after General section) ────────

# The Cursor Cloud section must appear after the General section
GENERAL_LINE="$(grep -n "^## General" "$CLAUDE_MD" | head -1 | cut -d: -f1)"
CURSOR_LINE="$(grep -n "^## Cursor Cloud specific instructions" "$CLAUDE_MD" | head -1 | cut -d: -f1)"

if [[ -n "$GENERAL_LINE" && -n "$CURSOR_LINE" && "$CURSOR_LINE" -gt "$GENERAL_LINE" ]]; then
  pass "Cursor Cloud section appears after General section"
else
  fail "Cursor Cloud section appears after General section"
  echo "    General section at line: ${GENERAL_LINE:-<not found>}"
  echo "    Cursor Cloud section at line: ${CURSOR_LINE:-<not found>}"
fi

# ── Boundary: section heading is not nested (uses ##, not ###) ────────────────

if grep -q "^## Cursor Cloud specific instructions" "$CLAUDE_MD"; then
  pass "Cursor Cloud section uses top-level ## heading (not nested)"
else
  fail "Cursor Cloud section uses top-level ## heading (not nested)"
fi

# ── Negative: no placeholder text left in the new section ────────────────────

CURSOR_SECTION="$(awk '/^## Cursor Cloud specific instructions/,/^## [^C]/' "$CLAUDE_MD")"
assert_not_contains "$CURSOR_SECTION" "TODO" \
  "Cursor Cloud section contains no TODO placeholders"
assert_not_contains "$CURSOR_SECTION" "FIXME" \
  "Cursor Cloud section contains no FIXME placeholders"
assert_not_contains "$CURSOR_SECTION" "TBD" \
  "Cursor Cloud section contains no TBD placeholders"

# ── Summary ───────────────────────────────────────────────────────────────────

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All CLAUDE.md Cursor Cloud documentation tests passed"
else
  echo "$FAILURES CLAUDE.md Cursor Cloud documentation test(s) failed"
  exit 1
fi
