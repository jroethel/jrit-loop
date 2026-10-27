#!/usr/bin/env bash
# tests/cezar-transport-pointer.sh - loop-drive's cezar reference is the one home of cezar names, and inside a cezar task the skill stops instead of driving (Refs jroethel/jrit-core#94).
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
S=skills/loop-drive/SKILL.md
R=skills/loop-drive/references/cezar-transport.md
[ -f "$R" ] || fail "$R is missing"
while IFS= read -r line; do grep -qxF -- "$line" "$S" || fail "$S lacks the line: $line"; done <<'LINES'
- `references/cezar-transport.md`: read when the environment variable `CEZ_TASK_ID` is set, before Step 0's probes; it holds the cezar probe and what this skill does inside a cezar task.
**Probe.** When `CEZ_TASK_ID` is set, run the cezar probe in `references/cezar-transport.md`.
**Present:** every unit of this run is owned by the chain's compile step; print the line the reference gives and stop.
**Absent:** routing is unchanged.
Each unit's task_type is the plan's Type: line; a Model: line on the task is a pin that wins over the routing chain; on ringer the type is the manifest's task_type.
A finding that names a global constraint becomes a shared test: append a path= block under the plan's ## Shared tests section, commit it with the gate's commit, and every later unit's custody check includes it.
LINES
for w in CEZ_BIN 'task create' '/continue' 'parentRunId' 'batches of at most 4' 'CEZ:MONITORING' '10 minutes' 'merge each finished child'; do
  grep -qF -- "$w" "$S" && fail "$S names '$w'"
  grep -qF -- "$w" "$R" && fail "$R still names '$w'; the transport is gone"
done
for h in '## Probe' '## Inside a cezar task'; do grep -qxF -- "$h" "$R" || fail "$R lacks the heading '$h'"; done
grep -qF 'running inside a cezar task; the chain'"'"'s compile step owns the drive stage; stopping' "$R" || fail "$R lacks the stop line"
[ "$(grep -c '^## ' "$R")" = 2 ] || fail "$R should carry exactly two sections"
echo "PASS: cezar transport pointer"
