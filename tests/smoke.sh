#!/bin/sh
# Smoke tests for the gecko CLI. POSIX sh + git only.
#   sh tests/smoke.sh
set -eu

GECKO="$(cd "$(dirname "$0")/.." && pwd)/skills/gecko/scripts/gecko"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT INT TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$*"; }

cd "$work"
git init -q
git config user.email test@example.com
git config user.name test
printf 'a\n' > keep.txt
printf 'b\n' > gone.txt
git add -A
git commit -q -m init
"$GECKO" baseline >/dev/null

# 1. review flags a pure addition and lists untracked files
printf 'a\nb\nc\n' > keep.txt    # tracked, added lines, none removed
printf 'x\ny\n' > new.txt        # untracked
review="$("$GECKO" review)"
printf '%s\n' "$review" | grep -q 'keep.txt' || fail "review missed the candidate keep.txt"
printf '%s\n' "$review" | grep -q 'new.txt'  || fail "review missed untracked new.txt"
pass "review lists candidates and untracked"

# 1b. GREW (existed, only grew) is separated from NEW FILES (brand new)
printf 'x\ny\n' > staged-new.txt
git add staged-new.txt
review="$("$GECKO" review)"
printf '%s\n' "$review" | grep -q '^GREW'      || fail "review missing the GREW section"
printf '%s\n' "$review" | grep -q '^NEW FILES' || fail "review missing the NEW FILES section"
printf '%s\n' "$review" | awk '/^GREW/{g=1} /^NEW FILES/{g=0} g' | grep -q 'keep.txt' \
  || fail "an existing file that only grew should be under GREW"
printf '%s\n' "$review" | awk '/^NEW FILES/{n=1} /^untracked|^TOUCHED/{n=0} n' | grep -q 'staged-new.txt' \
  || fail "a brand-new staged file should be under NEW FILES"
pass "review separates GREW from NEW FILES"

# 2. review --json is valid-ish and mentions the candidate
"$GECKO" review --json | grep -q '"path":"keep.txt"' || fail "review --json missed the candidate"
pass "review --json emits the candidate"

# 3. ratchet passes at a clean baseline
"$GECKO" check >/dev/null || fail "check should pass at baseline"
pass "check passes at baseline"

# 4. ratchet fails on a new finding
printf 'code\n# gecko: temp - remove when X\n' > marked.txt
git add marked.txt
if "$GECKO" check >/dev/null 2>&1; then fail "check should fail on a new finding"; fi
pass "check fails on a new finding"

# 5. baseline freezes it; check passes again
"$GECKO" baseline >/dev/null
"$GECKO" check >/dev/null || fail "check should pass after baseline"
pass "baseline freezes findings"

# 6. version
"$GECKO" version | grep -q '^gecko [0-9]' || fail "version output unexpected"
pass "version prints"

# 7. hook install/uninstall
"$GECKO" hook install >/dev/null
[ -x .git/hooks/pre-commit ] || fail "hook was not installed"
"$GECKO" hook uninstall >/dev/null
if [ -e .git/hooks/pre-commit ]; then fail "hook was not removed"; fi
pass "hook install/uninstall"

printf '\nall smoke tests passed\n'
