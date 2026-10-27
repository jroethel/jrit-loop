#!/usr/bin/env bash
# tests/plan-contract.sh - loop-plan carries the one question round, the skeleton-first Rubix pass, the lint at exit, the task fields, and the loop-auto exit (Refs jroethel/jrit-core#94).
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
P=skills/loop-plan/SKILL.md
while IFS= read -r line; do grep -qxF -- "$line" "$P" || fail "$P lacks the line: $line"; done <<'LINES'
## Step 2 - Skeleton and the Rubix pass
## Step 3 - The one question round`[gate:ASK]`
## Step 5 - Write the task bodies and tests
## Step 6 - Self-review and lint
## Step 7 - Run shape
## Step 9 - Exit by loop-auto (pinned)`[gate:DEFAULT]`
After this round the plan asks nothing more: every later choice is taken as a default and written as NEEDS HUMAN CONFIRMATION in the decision log.
A plan the lint rejects is not written yet.
Read the effective autonomy mode as loop-auto defines it.
A dispatched session commits the plan and ends; it never starts a chain.
LINES
for s in 'python3 scripts/plan_lint.py lint' 'python3 scripts/plan_lint.py run-table' 'Skeleton written. Want the Rubix review?' \
         'Shape: auto (or: human, <why>)' 'Type: code-feature' 'Decisions: D1, D4 (or: none)' '**Edge inputs:**' 'path=tests/exact/path' '## Shared tests' \
         'no brief for #<n>; run loop-brainstorm first' 'Resolved assumptions'; do
  grep -qF -- "$s" "$P" || fail "$P lacks: $s"
done
grep -qF 'Plan written. Want the Rubix review?' "$P" && fail "$P still offers Rubix on the written plan"
[ "$(grep -c '^## Step ' "$P")" = 9 ] || fail "$P should carry exactly nine Step headings"
[ "$(grep -c 'Want the Rubix review?' "$P")" = 1 ] || fail "the Rubix offer sentence must appear exactly once"
grep -q "$(printf '\xe2\x80\x94')" "$P" && fail "em dash in $P"
[ "$(jq -r .version .claude-plugin/plugin.json)" = "0.6.0" ] || fail "plugin.json is not 0.6.0"
grep -qF 'chain-start.sh # why:' ci/reference-allowlist.txt || fail "allowlist lacks chain-start.sh"
echo "PASS: plan contract"
