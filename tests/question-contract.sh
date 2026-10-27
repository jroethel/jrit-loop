#!/usr/bin/env bash
# tests/question-contract.sh - the brief's Resolved assumptions section and loop-auto's marked takes are pinned word for word (Refs jroethel/jrit-core#94).
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
B=skills/loop-brainstorm/references/brief-pipeline.md
grep -qxF '## Resolved assumptions' "$B" && fail "$B carries the section as a heading of its own; it belongs in the brief section shape list"
grep -qF 'Every assumption the interview settled or the author took, one bullet each, as A<n>: <assumption> - taken as <reading>; flips if <what>; the plan stage reads this section before its one question card and never re-asks an A<n>.' "$B" \
  || fail "$B lacks the Resolved assumptions contract line"
grep -qF 'Resolved assumptions' "$B" || fail "$B does not name the section"
grep -qF 'Each answered question lands in the brief'"'"'s Resolved assumptions section as an A<n> line, so the plan stage never asks it again.' skills/loop-brainstorm/SKILL.md \
  || fail "loop-brainstorm Step 3 does not route answers into Resolved assumptions"
A=skills/loop-auto/SKILL.md
grep -qF 'Every BATCH lean and DEFAULT take is written where it applies (the plan, the handoff, or the journal) as a line carrying the literal marker NEEDS HUMAN CONFIRMATION, and the merge card lists every such line on the branch for one confirmation.' "$A" \
  || fail "$A lacks the marked-take line"
n="$(grep -c 'NEEDS HUMAN CONFIRMATION' "$A")"; [ "$n" -ge 1 ] || fail "marker absent from $A"
for f in "$B" skills/loop-brainstorm/SKILL.md "$A"; do grep -q "$(printf '\xe2\x80\x94')" "$f" && fail "em dash in $f"; done
echo "PASS: question contract"
