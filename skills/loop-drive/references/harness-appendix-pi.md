# Harness appendix: pi

The portable core of this skill names no harness primitive; this appendix names pi's, as `references/harness-appendix-claude-code.md` names Claude Code's.
Read it when this session runs in pi and at least one unit takes the background-agent transport, or the compile dispatch is about to fire.
The verdicts below were read on 2026-10-18 from pi 1.3.0 with the `pi-durable-subagents` 1.0.45 package, whose README is the source of record.

## The subagent tool

pi ships no subagent tool of its own; the `pi-durable-subagents` package adds one tool, `subagents`.
Without the package, Step 0's subagent probe is absent, and the core's Absent rule applies.
Every `subagents` run is asynchronous: the call returns a workflow id (`wid`) at once, and the work continues in separate pi processes.

## Dispatch and steering

A wave's background-agent units dispatch as one parallel run: `subagents({ tasks: [{ agent: "worker", task: "<worker brief>", model: "<provider/id>", cwd: "<the unit's worktree>" }, ...] })`.
Validators dispatch the same way with `agent: "reviewer"`; list the available agents with `subagents({ action: "agents" })`.
The core's "ONE fresh-context dispatch" for Steps 1-4 and Step 6 is one `subagents({ agent: "worker", task: "<compile brief>", model: "<drive-compile pin model>" })` call.
The core's "one repair pass routed to the same implementer" is one `subagents({ action: "send", to: "<wid>/<key>", kind: "follow-up", message: "<itemized validator verdict>" })`, which continues the finished implementer in its own session, then a revalidation; a steer is refused once a call has finished.

## Waiting

Stay in the turn until the run finishes: poll `subagents({ action: "status", wid: "<wid>" })` with one `sleep 60` shell call between checks, and gate the wave once `active` is false.
Ending the turn to wait for the completion notice works in interactive pi, but under `pi -p` the print run exits when the turn ends and the subagents' results never reach this session (observed 2026-10-17).
For a per-unit receipt line, `subagents({ action: "status", wid: "<wid>", grep: "AGENT STATUS" })` returns only the matching lines of each call's output.

## Models

Background-agent workers run on the models pi's configured providers serve; list them with `pi --list-models`.
The core roster's Anthropic names apply only where pi has an Anthropic provider; otherwise each unit takes the listed model nearest its routed tier, tagged `pin:harness` in the routing table.

## Worktrees

Two calls that can write in the same git worktree run one at a time, because each holds that worktree's writer lock, so parallel implementers each need their own worktree passed as `cwd`.
The implementer creates its worktree itself with explicit `git -C <repo> worktree add ...` commands, as the core's nested-repo hazard says; leave `isolation` at its default, `"none"`, which never creates or deletes a directory.

## Bookkeeping for the repair pass

Track, per unit, the implementer's `<wid>/<key>` address session-locally; the `AGENT STATUS` receipt does not carry it.
Unlike Claude Code's background agents, durable subagents outlive this session: a pi that is quit pauses them, and the next pi resumes them, so a fresh session can still route the repair pass when it reads the address back from `subagents({ action: "status" })`.
The receipt format, its claim/gate cadence, and the git-over-receipt relaunch procedure live in the SKILL's Step 5; do not restate them here.

## Watching parallel workers

The `/subagents` view in pi lists every subagent with its model and what it is doing; Enter watches one, `s` steers it.
The core's watch points (per-unit logs, `AGENT STATUS` receipts) are the portable fallback.
