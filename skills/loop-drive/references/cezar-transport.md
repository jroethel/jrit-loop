# Cezar task transport

This is loop-drive's worker transport for a driving session that is itself running inside a cezar task: every unit dispatches as a cezar child task forked from the integration branch, the parent waits in batches, and each finished child merges at the wave gate.
Nothing here applies unless the probe below is Present; everywhere else loop-drive behaves exactly as it does without this reference.

## Probe

Run `[ -n "${CEZ_TASK_ID:-}" ] && [ -n "${CEZ_BIN:-}" ] && curl -sf "${CEZ_API_URL:-http://127.0.0.1:9}/api/v1/health" >/dev/null`; exit 0 is Present.
Present means this session is itself a cezar task and the cockpit is reachable, so Step 0 routes every unit onto this transport and no unit takes ringer or the background-agent transport.
Any other exit is Absent, and routing is unchanged.

## Dispatch

Commit the integration branch first, because a child forks from the running task's committed branch tip.
Dispatch each unit with:

```
node "$CEZ_BIN" task create "<the unit's full worker spec, its acceptance check included>" --title "<unit name>" --kind implement --success "<the acceptance check command>" --retry-limit 0
```

Always `node "$CEZ_BIN"`, never a `cez` found on PATH: the cockpit pins the engine, and a `cez` on PATH may be a different one.
Never with `--budget`: a child at its budget brake parks `waiting` and stalls the wave, and loop caps are the only ceiling (M7 as revised).
Dispatch a wave's units in batches of at most 4 unfinished children, which is cezar's in-flight limit.
Record each child id and branch from the `dispatched <id> on branch <branch>` line in the unit's `AGENT STATUS` receipt.
The child's spec never carries this parent's marker rules: a child is its own cezar task, and it ends its final turn with the single line `CEZ:DONE` once its acceptance check passes, which is how cezar settles the task; a child that reports without it parks `waiting` and shows as needing attention although nothing is owed.

## Wait

After dispatching a batch, the parent stays in its turn and waits for the batch to finish before dispatching the next.
It waits by polling, one short `sleep 60` call between checks; Human checkpoint 4 (2026-10-17) chose this after the probe saw a wake turn end without its marker on cezar 0.15.0 and cezar settle the step done early, which ends the wave short.
The design that decision replaced - end the turn with no marker and let cezar park the session without a slot until a child reports, and end the turn with the single line `CEZ:MONITORING` when nothing is left to dispatch but a child still runs - is recorded here so a future build can re-try it.
On each check, run this once per unfinished child:

```
curl -s "$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs/<id>" | jq -r '.status + " " + .createdAt + " " + (.branch // "") + " " + (.error // "")'
```

A polling parent holds a slot and slowly burns its 30-minute step limit, and `maxParallel` 6 leaves room for exactly that; if the step cuts off mid-wait, the run continues the same session and picks the children up again under Resume after a cut-off.
The parent never emits `CEZ:ASK` or `CEZ:DONE`; this rule is the parent's alone and never reaches a child's spec.

## Stuck children

A child that is `queued` more than about 10 minutes after its `createdAt` is a stop-and-surface condition: report it as a question round through this skill's ask channel - the child id, its status, and the choices to cancel it, rerun it, or take the unit back - and never poll it again.
The `waiting` leg of the rule was dropped at the same checkpoint because the probe could not reproduce a child parking `waiting` on cezar 0.15.0 (stuck=not-reproduced), and children on this transport carry no `--budget`, so a budget-brake park is not a live failure mode.

## Gate

Merge each finished child into the integration branch with `git merge --no-edit <child branch>`, then re-run the unit's acceptance check there.
A child's own report is never the verdict; the merge plus the re-run check is.
A merge conflict is a scope violation, never resolved quietly: stop and surface it through this skill's ask channel.

## Repair

A failed acceptance check at the gate earns the child exactly one repair pass, and it is the one repair the unit gets.
Send the itemized failure to the child with one continue call:

```
curl -s -X POST "$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs/<id>/continue" -H 'content-type: application/json' -d '{"text":"<itemized failure>"}'
```

Then wait again, merge again, and re-run the unit's acceptance check.
A second failure stops that unit without blocking its siblings.

## Resume after a cut-off

Children keep running when this session stops; the probe killed the parent mid-wave and every child alive at the kill finished done after it.
On resume, list this task's children and continue at Wait for each, never dispatching a unit twice:

```
curl -s "$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs" | jq -r --arg p "$CEZ_TASK_ID" '.[] | select(.dispatch.parentRunId == $p) | .id + " " + .status + " " + (.branch // "")'
```

A child missing from that list means its unit was never dispatched; a finished child goes to Gate, an unfinished one to Wait.
