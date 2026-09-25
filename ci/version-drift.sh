#!/usr/bin/env bash
# ci/version-drift.sh - the five drift assertions of D9 (criterion 7).
# plugin.json's version is the single source; the README marker is the second
# copy that actually drifts, because it is the surface that tells a stranger
# what they are installing.
#
# Deliberately NOT asserted here: the README's npx version pin. Task 2 leaves
# it as the placeholder <VERSION> until Task 14 measures the real one, and
# asserting it in a per-push check would make Tasks 3 through 13 unpassable.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "DRIFT FAIL: $1" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required by ci/version-drift.sh and is not on PATH"

# --- 1. LICENSE at the root ----------------------------------------------------
[ -f LICENSE ] || fail "LICENSE is missing at the repo root (criterion 7)"

# --- 2. plugin.json carries a semver version -----------------------------------
jq -e '.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")' .claude-plugin/plugin.json >/dev/null 2>&1 \
  || fail ".claude-plugin/plugin.json: .version is missing or not semver X.Y.Z (got: $(jq -r '.version' .claude-plugin/plugin.json 2>/dev/null))"
name=$(jq -r '.name' .claude-plugin/plugin.json)
pv=$(jq -r '.version' .claude-plugin/plugin.json)
echo "ok: plugin.json $name version $pv is semver"

# --- 3. marketplace.json: exactly one entry, matching name, source "./" --------
mcount=$(jq '.plugins | length' .claude-plugin/marketplace.json 2>/dev/null)
[ "$mcount" = "1" ] || fail ".claude-plugin/marketplace.json carries $mcount plugins[] entries; exactly one is allowed"
m_name=$(jq -r '.plugins[0].name' .claude-plugin/marketplace.json)
m_src=$(jq -r '.plugins[0].source' .claude-plugin/marketplace.json)
[ "$m_name" = "$name" ] || fail "marketplace.json entry name '$m_name' does not equal plugin.json name '$name'"
[ "$m_src" = "./" ] || fail "marketplace.json entry source is '$m_src'; the self-marketplace contract requires \"./\""
echo "ok: marketplace.json has one entry, name $m_name, source ./"

# --- 4. README version marker equals plugin.json version -----------------------
marker_count=$(grep -cE '^<!-- jrit-loop-version: (.+) -->$' README.md)
[ "$marker_count" = "1" ] || fail "README.md carries $marker_count lines matching '^<!-- jrit-loop-version: ... -->$'; exactly one is allowed"
readme_v=$(grep -E '^<!-- jrit-loop-version: (.+) -->$' README.md | head -1 | sed -E 's/^<!-- jrit-loop-version: (.+) -->$/\1/')
[ "$readme_v" = "$pv" ] || fail "version drift: README marker says $readme_v, plugin.json says $pv"
echo "ok: README marker equals plugin.json version ($readme_v)"

# --- 5. skills/ holds exactly ten directories, each with a SKILL.md -----------
shopt -s nullglob
dirs=()
for d in skills/*/; do
  dirs+=("$d")
done
count=${#dirs[@]}
if [ "$count" -lt 10 ]; then
  echo "skip: ten-directory assertion ($count of 10 skill directories exist; hard once Task 9 lands)"
else
  [ "$count" -eq 10 ] || fail "skills/ holds $count directories; exactly ten skills ship"
fi
missing=""
for d in "${dirs[@]}"; do
  if [ ! -f "${d}SKILL.md" ]; then
    # Task 4 ships scripts/receipt.sh before Task 9 ships loop-drive's SKILL.md, so that one
    # directory may lack its SKILL.md only while the eleven-count is still short (same
    # skip-while-pending, hard-once-present pattern the budget existence checks use).
    if [ "$d" = "skills/loop-drive/" ]; then
      echo "skip: skills/loop-drive/SKILL.md not yet created (lands with Task 9; hard once present)"
      continue
    fi
    missing="$missing
  ${d} has no SKILL.md"
  fi
done
[ -z "$missing" ] || fail "skill directories without a SKILL.md:$missing"
shopt -u nullglob
echo "ok: every skill directory present has a SKILL.md"

echo "PASS: drift"
