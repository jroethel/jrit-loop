#!/usr/bin/env bash
# tests/cezar-transport-pointer.sh - static proof that loop-drive's cezar transport has one home
# (references/cezar-transport.md) and that the portable core only probes and points to it.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
S=skills/loop-drive/SKILL.md
R=skills/loop-drive/references/cezar-transport.md
[ -f "$R" ] || fail "$R is missing"
while IFS= read -r line; do
  grep -qxF -- "$line" "$S" || fail "$S lacks the line: $line"
done <<'LINES'
- `references/cezar-transport.md`: read when the environment variable `CEZ_TASK_ID` is set, before Step 0's probes; it holds the cezar task transport's probe, dispatch, gate, and repair mechanics.
**Probe.** When `CEZ_TASK_ID` is set, run the cezar probe in `references/cezar-transport.md`.
**Present:** every unit takes the cezar task transport, and no unit takes ringer or the background-agent transport in this run.
**Absent:** routing is unchanged.
When Step 0's cezar probe is present, every unit takes the cezar task transport instead.
Cezar-transport units: merge each finished child's branch into the integration branch and re-run the unit's acceptance check there; a child's own report is never the verdict.
LINES
for w in CEZ_BIN CEZ_API_URL 'task create' '/continue' 'parentRunId'; do
  grep -qF -- "$w" "$S" && fail "$S names '$w'; cezar mechanics belong only in $R"
  grep -qF -- "$w" "$R" || fail "$R does not cover '$w'"
done
for h in '## Probe' '## Dispatch' '## Wait' '## Stuck children' '## Gate' '## Repair' '## Resume after a cut-off'; do
  grep -qxF -- "$h" "$R" || fail "$R lacks the heading '$h'"
done
grep -qF -- 'batches of at most 4' "$R" || fail "$R does not cap a batch at 4 children"
grep -qF -- 'end the turn with no marker' "$R" || fail "$R does not tell the parent to end its turn to wait"
grep -qF -- 'CEZ:MONITORING' "$R" || fail "$R does not say how to wait with nothing left to dispatch"
grep -qF -- '10 minutes' "$R" || fail "$R has no stuck-child rule"
grep -E -- 'task create .*--budget [0-9]' "$R" && fail "$R dispatches children with a --budget (M7 as revised)"
echo "PASS: cezar transport pointer"
