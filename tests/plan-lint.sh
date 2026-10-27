#!/usr/bin/env bash
# tests/plan-lint.sh - plan_lint.py accepts the good fixture and names the defect in each bad one; units, tests, run-table are deterministic (Refs jroethel/jrit-core#94).
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
L=skills/loop-plan/scripts/plan_lint.py
FX=tests/fixtures/plan-lint
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
[ -f "$L" ] || fail "$L is missing"
[ ! -x "$L" ] || fail "$L carries the execute bit"
python3 "$L" lint "$FX/good-plan.md" > "$TMP/good.out" || fail "good plan rejected: $(cat "$TMP/good.out")"
grep -qx 'ok: 4 tasks, 3 waves, 3 test blocks' "$TMP/good.out" || fail "good summary wrong: $(cat "$TMP/good.out")"
expect() { # <fixture> <rule> <detail substring>
  out="$(python3 "$L" lint "$FX/$1" 2>&1)"; rc=$?
  [ "$rc" -eq 1 ] || fail "$1: exit $rc, expected 1: $out"
  echo "$out" | grep -q "^lint: $2: .*$3" || echo "$out" | grep -q "^plan gate: .*$3" || fail "$1: no line for rule $2 with '$3': $out"
}
expect bad-no-depends.md depends 'Task 2: no Depends on line'
expect bad-overlap.md overlap 'Task 1 and Task 2 both own src/a.py'
expect bad-no-check.md check 'Task 2: acceptance check is not marked'
expect bad-placeholder.md placeholder 'TBD'
expect bad-no-shape.md shape 'Task 1: no Shape line'
expect bad-test-block.md test-block 'tests/test_two.py has 0 path= blocks'
python3 "$L" units "$FX/good-plan.md" --json > "$TMP/units.json" || fail "units failed"
jq -e 'length == 4 and .[0].id == "1" and .[0].wave == 1 and .[3].wave == 3 and (.[1].files.test | length) == 1 and .[1].type == "code-feature" and .[2].model == "opus" and .[3].shape == "human"' "$TMP/units.json" >/dev/null \
  || fail "units shape wrong: $(cat "$TMP/units.json")"
python3 "$L" tests "$FX/good-plan.md" --out "$TMP/t" > "$TMP/tests.out" || fail "tests extraction failed"
[ "$(wc -l < "$TMP/tests.out")" -eq 3 ] || fail "expected 3 wrote lines: $(cat "$TMP/tests.out")"
[ -f "$TMP/t/tests/test_one.py" ] && [ -f "$TMP/t/tests/shared/test_style.sh" ] || fail "extracted files missing"
grep -qx 'assert one == 1' "$TMP/t/tests/test_one.py" || fail "test body not verbatim"
out="$(python3 "$L" tests "$FX/bad-test-block.md" --out "$TMP/t2" 2>&1)"; [ $? -eq 1 ] && echo "$out" | grep -q '^FAIL path \.\./escape\.py' || fail "an escaping path was not refused"
printf 'old\n' > "$TMP/t/tests/test_one.py"
out="$(python3 "$L" tests "$FX/good-plan.md" --out "$TMP/t" 2>&1)"; [ $? -eq 1 ] && echo "$out" | grep -q '^FAIL path tests/test_one.py exists' || fail "an existing file was overwritten without mode=replace"
sed 's|path=tests/test_one.py|path=tests/test_one.py mode=append|' "$FX/good-plan.md" > "$TMP/append.md"
mkdir -p "$TMP/t3/tests" && printf 'old\n' > "$TMP/t3/tests/test_one.py"
python3 "$L" tests "$TMP/append.md" --out "$TMP/t3" | grep -q '^appended tests/test_one.py' || fail "mode=append did not append"
[ "$(sed -n 1p "$TMP/t3/tests/test_one.py")" = old ] || fail "append lost the existing content"
python3 "$L" run-table "$FX/good-plan.md" > "$TMP/table.md" || fail "run-table failed"
head -n 1 "$TMP/table.md" | grep -q '^| Wave | Task *| Shape | Type *| Model | Why *|$' || fail "table header wrong: $(head -n 1 "$TMP/table.md")"
[ "$(awk '{ print length($0) }' "$TMP/table.md" | sort -u | wc -l)" -eq 1 ] || fail "table rows are not aligned to one width"
diff <(sed -n '/^## Run shape/,/^## /p' "$FX/good-plan.md" | grep '^|') "$TMP/table.md" >/dev/null || fail "run-table differs from the good plan's table"
[ "$(python3 "$L" human-tasks "$FX/good-plan.md")" = 4 ] || fail "human-tasks wrong"
# skill-local test folders: skills/<name>/tests/ is a test root, nothing else under skills/ is
sed 's|tests/test_one.py|skills/craft-review/tests/test_x.py|g' "$FX/good-plan.md" > "$TMP/skill.md"
python3 "$L" lint "$TMP/skill.md" > "$TMP/skill.out" 2>&1 || fail "a skills/<name>/tests/ block was refused by lint: $(cat "$TMP/skill.out")"
python3 "$L" tests "$TMP/skill.md" --out "$TMP/sk-ok" > /dev/null || fail "a skills/<name>/tests/ block was not written"
[ -f "$TMP/sk-ok/skills/craft-review/tests/test_x.py" ] || fail "skills/craft-review/tests/test_x.py missing after extraction"
for bp in skills/craft-review/src/x.py skills/a/b/tests/x.py skills/tests/x.py; do
  sed "s|tests/test_one.py|$bp|g" "$FX/good-plan.md" > "$TMP/skill-bad.md"
  out="$(python3 "$L" tests "$TMP/skill-bad.md" --out "$TMP/sk-bad-$(echo "$bp" | tr / _)" 2>&1)"; rc=$?
  [ "$rc" -eq 1 ] && echo "$out" | grep -q "^FAIL path $bp " || fail "$bp was not refused: rc=$rc $out"
done
echo "PASS: plan lint"
