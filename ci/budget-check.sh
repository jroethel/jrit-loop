#!/usr/bin/env bash
# ci/budget-check.sh - the executable sweep and the receipt helper's SLOC budget.
# Spec of record: plan 2026-09-13 B32, Task 3 step 2 and D8.
#
# The budgeted denominator is the helper ALONE. The 200 Jeremy approved on
# 2026-09-13 was measured against skills/loop-drive/scripts/receipt.sh, and
# summing the manifests into it would add roughly 25 lines of declarative
# overhead the approved number never contemplated. The three manifests are
# asserted present and their SLOC is printed as information only; they carry
# no threshold and can never fail this check on size. A missing manifest is
# a hard fail naming its path: all three ship with the plugin.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "BUDGET FAIL: $1" >&2; exit 1; }

# --- 1. zero executables under skills/ except the receipt helper ---------------
stray=$(find skills -type f -perm -u+x ! -path 'skills/loop-drive/scripts/receipt.sh' -print)
[ -z "$stray" ] || fail "executable files under skills/ other than skills/loop-drive/scripts/receipt.sh:
$stray
Every invocation form is 'bash <script>', so nothing else may carry the execute bit."

sloc() { grep -cvE '^[[:space:]]*(#|$)' "$1"; }

# --- 2. the helper's SLOC against the amended budget --------------------------
HELPER=skills/loop-drive/scripts/receipt.sh
if [ -f "$HELPER" ]; then
  n=$(sloc "$HELPER")
  echo "helper SLOC: $n (budget 200)"
  [ "$n" -lt 200 ] || fail "helper SLOC is $n, at or over the amended budget of 200 (D8, Jeremy 2026-09-13). Do not raise the threshold: escalate to human checkpoint C5."
else
  echo "skip: helper SLOC (skills/loop-drive/scripts/receipt.sh not yet created)"
fi

# --- 3. the three manifests: present-and-informative, never thresholded -------
for p in .claude-plugin/plugin.json .claude-plugin/marketplace.json skills/handoff/agents/openai.yaml; do
  if [ -f "$p" ]; then
    echo "info: $p SLOC: $(sloc "$p")"
  else
    fail "manifest missing: $p"
  fi
done

echo "PASS: budget"
