# Harness appendix: Claude Code

The portable core of this skill names no harness primitive; this appendix names them all, and it is the only loop-drive file that does.
Read it when at least one unit takes the background-agent transport (the Conditional reads block in the SKILL carries the trigger).
The verdicts below are the 2026-09-13 seam-0 findings, verified live against `claude` 2.1.269.

## Dispatch and steering

Background dispatch happens through the tool named `Agent`: it spawns subagents that run in the foreground or background, and the orchestrator is notified on each completion.
Steering a running worker happens through `SendMessage`: it addresses a still-running agent by its ID or name to resume it or pass it a message.
The core's "one repair pass routed to the same implementer" is concretely one `SendMessage` to that implementer's agent id, carrying the itemized validator verdict, then a revalidation.
The core's "ONE fresh-context dispatch" for Steps 1-4 and Step 6 is one background `Agent` call at the drive-compile dispatch role pin.

## Bookkeeping for the repair pass

Track, per unit, the implementer's agent id session-locally only - the one field the `AGENT STATUS` receipt does not carry, because a fresh session cannot SendMessage a dead subagent anyway; it exists only to route the single repair pass to the same implementer.
The receipt format, its claim/gate cadence, and the git-over-receipt relaunch procedure live in the SKILL's Step 5; do not restate them here.

## Live-session constraint

The orchestrator IS the loop: if this session dies (quota, crash), the loop stops - background subagents are not a durable scheduler.
When the loop must run unattended (overnight, scheduled), background-agent orchestration is the wrong tool; point to the Managed Agents API (the headless equivalent) rather than trying to keep an interactive session alive.

## User-invoked slash commands

Seam-0 verdict, recorded: `/goal` and `/loop` are user-invoked slash commands only and must never be written into this skill as steps the skill itself runs.
`/goal` sets a completion condition a small fast model re-evaluates after every turn; `/loop` re-runs a prompt on a fixed or self-paced interval for as long as the session stays open.
Both are also runnable from a shell as `claude -p "/goal ..."`, but neither is prose-callable from skill text.

## Other primitives the core defers here

- Worktree isolation: the background-dispatch tool's `isolation: worktree` option snapshots the session's outer repo, which is why the core's nested-repo hazard tells the implementer to create the worktree itself with explicit `git -C <inner-repo> worktree add ...` commands.
- The pre-launch detail ask: with the autonomy knob at pause or unset, the core's in-session question is the `AskUserQuestion` tool with multiSelect.
- Watching parallel workers: `claude agents` opens a screen listing every background session as a row you can peek at (Space), reply to, or attach into (Enter); the core's watch points (per-unit logs, `AGENT STATUS` receipts, background-completion notifications) are the portable fallback when it is absent.
