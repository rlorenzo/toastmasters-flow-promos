#!/usr/bin/env bash
# One entry point for every check in this repo. Run it locally the same way CI
# does: scripts/lint.sh, or scripts/lint.sh --fast for the pre-commit subset.
#
# Optional tools are skipped with a note rather than failing, so a fresh clone
# can lint whatever it has. CI installs all of them, so nothing is skipped there.
set -uo pipefail
# No `set -e`: this script deliberately runs every check and reports all of them,
# so a failing linter must not abort the run. That makes the cd guard load-bearing.
cd "$(dirname "$0")/.." || exit 1

FAST=0
[[ "${1:-}" == "--fast" ]] && FAST=1

rc=0
run() { # run <label> <cmd...>
  local label="$1"; shift
  printf '\n\033[1m%s\033[0m\n' "$label"
  if "$@"; then
    printf '  ok\n'
  else
    printf '  FAILED\n'
    rc=1
  fi
}
skip() { printf '\n\033[1m%s\033[0m\n  skipped (%s)\n' "$1" "$2"; } # skip <label> <reason>

# run_on_tracked <label> <glob> <cmd...>
# Runs <cmd> over every tracked file matching <glob>, skipping with a note if the
# tool is absent. Asking git rather than globbing is what keeps the file lists
# honest: git already knows what ships (so .claude/skills/*.md gets linted, which
# a bare '**/*.md' misses) from what is local scratch or build output (so
# agent-code-review.md and templates/*.rendered.html never reach a linter). It
# also means adding a card or a script puts it under the linter automatically,
# instead of depending on someone remembering to extend a list here.
run_on_tracked() {
  local label="$1" glob="$2"; shift 2
  local files=() f
  while IFS= read -r f; do files+=("$f"); done < <(git ls-files "$glob" 2>/dev/null)
  if ! command -v "$1" >/dev/null 2>&1; then
    skip "$label" "$1 not installed"
  elif [[ ${#files[@]} == 0 ]]; then
    skip "$label" "no tracked $glob files; not a git work tree?"
  else
    run "$label" "$@" "${files[@]}"
  fi
}

# --- Repo invariants: the rules from AGENTS.md and DESIGN.md ----------------
run "repo invariants" python3 scripts/repo_checks.py

# A check that cannot fail reads as coverage without being any. This proves each
# one still trips on a deliberate break. Full runs only: it is the checks
# themselves it re-verifies, and those change far less often than the tree does.
if [[ $FAST == 0 ]]; then
  run "repo invariants self-test" python3 scripts/test_repo_checks.py
else
  skip "repo invariants self-test" "--fast; runs in CI"
fi

# --- Shell ------------------------------------------------------------------
run_on_tracked "shellcheck" '*.sh' shellcheck --severity=warning

# --- Markdown ---------------------------------------------------------------
run_on_tracked "markdownlint" '*.md' markdownlint

# --- HTML (slower: pulls a validator) ---------------------------------------
# templates/*.rendered.html is build output and untracked, so it stays out of
# this on its own; the per-directory templates/.htmlvalidate.json handles the
# one rule the cards legitimately break.
if [[ $FAST == 0 ]]; then
  run_on_tracked "html-validate" '*.html' npx --yes html-validate
else
  skip "html-validate" "--fast; runs in CI"
fi

printf '\n'
if [[ $rc == 0 ]]; then
  printf '\033[32mAll checks passed.\033[0m\n'
else
  printf '\033[31mSome checks failed.\033[0m\n'
fi
exit $rc
