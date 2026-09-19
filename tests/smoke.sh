#!/bin/sh
# Smoke tests for the gecko CLI. POSIX sh + git only.
#   sh tests/smoke.sh
set -eu

GECKO="$(cd "$(dirname "$0")/.." && pwd)/skills/gecko/scripts/gecko"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT INT TERM

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$*"; }

# keep the suite quiet; the notice is tested explicitly below
export GECKO_QUIET=1

cd "$work"
git init -q
git config user.email test@example.com
git config user.name test
printf 'a\n' > keep.txt
printf 'b\n' > gone.txt
git add -A
git commit -q -m init
"$GECKO" baseline --update >/dev/null

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

# 1c. review --json is capped by default; --all lifts it
i=1
while [ "$i" -le 20 ]; do
  printf 'x\n' > "cap-$i.ts"
  git add "cap-$i.ts"
  i=$((i + 1))
done
"$GECKO" review --json | grep -q '"truncated":true' || fail "review --json should report truncation"
"$GECKO" review --json --all | grep -q '"truncated":false' || fail "review --json --all should not truncate"
pass "review --json is capped; --all lifts it"

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

# 4b. a bare `baseline` is a dry run: it must NOT clear the new finding
"$GECKO" baseline >/dev/null
if "$GECKO" check >/dev/null 2>&1; then fail "bare baseline must not write"; fi
pass "bare baseline is a dry run"

# 4c. check --json reports a machine-readable verdict
"$GECKO" check --json 2>/dev/null | grep -q '"verdict":"findings"' \
  || fail "check --json did not report the findings verdict"
pass "check --json reports findings"

# 5. baseline freezes it; check passes again
"$GECKO" baseline --update >/dev/null
"$GECKO" check >/dev/null || fail "check should pass after baseline"
pass "baseline freezes findings"

# 5b. with no detector configured, check says so (unless GECKO_QUIET=1)
GECKO_QUIET=0 "$GECKO" check 2>&1 >/dev/null | grep -q 'no detector configured' \
  || fail "check should warn when no detector is configured"
pass "check warns when no detector is configured"

# 6. version
"$GECKO" version | grep -q '^gecko [0-9]' || fail "version output unexpected"
pass "version prints"

# 7. hook install/uninstall
"$GECKO" hook install >/dev/null
[ -x .git/hooks/pre-commit ] || fail "hook was not installed"
"$GECKO" hook uninstall >/dev/null
if [ -e .git/hooks/pre-commit ]; then fail "hook was not removed"; fi
pass "hook install/uninstall"

# 7b. foreign pre-commit: say how to append check, do not clobber
printf '#!/bin/sh\necho other\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
hook_err="$("$GECKO" hook install 2>&1)" && fail "hook install should refuse a foreign pre-commit"
printf '%s\n' "$hook_err" | grep -q 'exec ' || fail "hook refusal should print the exec line to append"
printf '%s\n' "$hook_err" | grep -qF '# gecko:ratchet' || fail "hook refusal should print the marker"
grep -q 'echo other' .git/hooks/pre-commit || fail "foreign pre-commit was overwritten"
rm -f .git/hooks/pre-commit
pass "hook install refuses foreign hooks with an append snippet"

# 8. detector failure is fail-closed: check exits 1, baseline --update does not write
mkdir -p .gecko
before_bl=$(cat .gecko/baseline)
printf 'gecko_detect() { return 1; }\n' > .gecko/config
git add .gecko/config
if "$GECKO" check >/dev/null 2>&1; then fail "check should fail when the detector fails"; fi
"$GECKO" check --json 2>/dev/null | grep -q '"verdict":"detector_failed"' \
  || fail "check --json should report detector_failed"
if "$GECKO" baseline --update >/dev/null 2>&1; then fail "baseline --update must not write on detector failure"; fi
after_bl=$(cat .gecko/baseline)
[ "$before_bl" = "$after_bl" ] || fail "baseline --update rewrote the file after a detector crash"
git rm -q -f .gecko/config
rm -f .gecko/config
pass "detector failure fails closed"

# 9. untracked .gecko/config is not sourced
printf 'gecko_detect() { printf "evil.ts\tboom\n"; }\n' > .gecko/config
if "$GECKO" check >/dev/null 2>&1; then :; else fail "untracked config must not be sourced (would add a new finding)"; fi
"$GECKO" check 2>&1 >/dev/null | grep -q 'ignoring untracked' \
  || fail "check should say it ignored untracked .gecko/config"
rm -f .gecko/config
pass "untracked config is ignored"

# 10. review --base on a missing ref dies, it does not report clean
if "$GECKO" review --base DOESNOTEXIST >/dev/null 2>&1; then fail "review should die on an unknown --base"; fi
"$GECKO" review --base DOESNOTEXIST 2>&1 | grep -q "unknown ref" \
  || fail "review should name the unknown ref"
pass "review dies on an unknown --base"

# 11. summary / --json added counts untracked lines
json_added() { sed -n 's/^{"base":"[^"]*","added":\([0-9]*\).*/\1/p'; }
added_before=$("$GECKO" review --json | json_added)
printf 'u1\nu2\nu3\n' > untracked-count.txt
added_after=$("$GECKO" review --json | json_added)
expected=$((added_before + 3))
[ "$added_after" -eq "$expected" ] || fail "review --json added should include untracked lines ($added_after != $expected)"
"$GECKO" review | grep -q 'untracked:' || fail "review summary should mention untracked"
rm -f untracked-count.txt
pass "review counts untracked lines in the summary"

# 12. annotation ratchet: comment-shaped, skip docs/md/vendor
mkdir -p docs vendor src
printf '# gecko: documented in prose\n' > docs/note.md
printf '// gecko: bundled leftover\n' > vendor/lib.js
printf 'see gecko: this is prose\n' > src/prose.ts
git add docs/note.md vendor/lib.js src/prose.ts
if "$GECKO" check >/dev/null 2>&1; then :; else fail "docs/vendor/prose must not count as annotations"; fi
printf '  // gecko: keep until pagination ships\n' > src/real.ts
git add src/real.ts
if "$GECKO" check >/dev/null 2>&1; then fail "a real comment annotation should fail check"; fi
git rm -q -f docs/note.md vendor/lib.js src/prose.ts src/real.ts
pass "annotation ratchet is comment-shaped and skips docs/vendor"

# 13. tests/, test_*, *_test.go hidden unless --tests; untracked tests too
mkdir -p tests src
printf 't\n' > tests/smoke.sh
printf 't\n' > test_foo.py
printf 't\n' > src/foo_test.go
git add tests/smoke.sh test_foo.py src/foo_test.go
hidden="$("$GECKO" review)"
printf '%s\n' "$hidden" | grep -q 'tests/smoke.sh' && fail "tests/smoke.sh should be hidden"
printf '%s\n' "$hidden" | grep -q 'test_foo.py' && fail "test_foo.py should be hidden"
printf '%s\n' "$hidden" | grep -q 'foo_test.go' && fail "foo_test.go should be hidden"
shown="$("$GECKO" review --tests)"
printf '%s\n' "$shown" | grep -q 'tests/smoke.sh' || fail "review --tests should show tests/smoke.sh"
printf '%s\n' "$shown" | grep -q 'test_foo.py' || fail "review --tests should show test_foo.py"
printf '%s\n' "$shown" | grep -q 'foo_test.go' || fail "review --tests should show foo_test.go"
printf 't\n' > src/hidden.test.ts
untracked_rev="$("$GECKO" review)"
printf '%s\n' "$untracked_rev" | grep -q 'hidden.test.ts' && fail "untracked test files should be hidden"
rm -f src/hidden.test.ts
git rm -q -f tests/smoke.sh test_foo.py src/foo_test.go
pass "test globs hide tests/, test_*, *_test.go, and untracked tests"

# 14. ORPHANS: a replacement that drops an import leaves the old module (and its private dep)
mkdir -p src/services src/screens
printf 'export const fooClient = { get: function () { return 1 } }\n' > src/services/fooClient.ts
printf 'import { fooClient } from "./fooClient"\nexport const fooService = { load: function () { return fooClient.get() } }\n' > src/services/fooService.ts
printf 'import { fooService } from "../services/fooService"\nexport const page = fooService.load()\n' > src/screens/page.ts
git add src/services/fooClient.ts src/services/fooService.ts src/screens/page.ts
git commit -q -m 'foo stack'
printf 'export const useFooQuery = function () { return 1 }\nexport const page = useFooQuery()\n' > src/screens/page.ts
orphans="$("$GECKO" review)"
printf '%s\n' "$orphans" | grep -q '^ORPHANS' || fail "review missing the ORPHANS section after a dropped import"
printf '%s\n' "$orphans" | grep -q 'fooService' || fail "dropped fooService import should list fooService as an orphan"
printf '%s\n' "$orphans" | grep -q 'fooClient' || fail "fooClient, only used by the orphan service, should be hop 1"
"$GECKO" review --json | grep -q '"path":"src/services/fooService.ts"' \
  || fail "review --json should emit the orphan path"
pass "review lists ORPHANS for a replaced import and one hop"

# 14b. another remaining caller means it is not an orphan
printf 'import { fooService } from "../services/fooService"\nexport const other = fooService.load()\n' > src/screens/other.ts
git add src/screens/other.ts
still="$("$GECKO" review)"
printf '%s\n' "$still" | grep -q 'fooService' && fail "fooService must not be an orphan while other.ts still imports it"
git rm -q -f src/screens/other.ts
pass "ORPHANS skips modules that still have a caller"

printf '\nall smoke tests passed\n'
