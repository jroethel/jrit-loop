# Loop conventions

This file is the prose surface for the loop convention in this repo.
The machine-readable keys live in the sibling `docs/loop/pointer.md`.

## Tracker

This repo declares `tracker: github`.
Issues, the backlog, and the wayfinder map all live in the GitHub tracker itself; there is no generated mirror file.
List open issues with `gh issue list --state open`.

## The `agent:` label vocabulary

Exactly one of these is active on an issue at a time:

- `agent:todo` - open and unclaimed.
- `agent:working` - claimed and in progress.
- `agent:needs-input` - blocked on a human answer.
- `agent:review` - work done, awaiting review.
- `agent:done` - closed, reachable only through the receipt helper's `done` verb.

Two more labels exist outside that one-active rule:

- `idea` - a parked backlog item, not active work.
- `wayfinder:map` - a wayfinder mapping item.

## Filename grammar

Files in the doc-tree homes (`docs/handoffs/`, `docs/briefs/`, `docs/plans/`, `docs/reviews/`, `docs/archive/`) share one grammar: `YYYY-MM-DD.<descriptor>.md`, date first, dot-separated, the descriptor a short slug with optional tracker-token segments (e.g. `.I6` for issue 6).

Two fixed instances of that grammar:

- The loop-drive resume pointer: `YYYY-MM-DD.<unit-slug>.resume.md`.
- The loop-auto batch-review journal: `YYYY-MM-DD.<tokens>.<slug>-batch-review.md`.

## Archive and graduation

Completed work moves to `docs/archive/` once it graduates out of its active home (a closed-out handoff, a superseded plan, a resolved review).
Moving a file to the archive does not rename it; the filename grammar above still applies.

## Verbose-announce convention

When a loop skill claims, completes, or hands off a unit of work, it announces what it did and where in a single line the human can scan without opening the file: the action taken, the file or issue touched, and the resulting state.

## Claim, done, status, next-eligible

These four verbs run through the receipt helper shipped inside the loop-drive skill.
`agent:done` is reachable only through the helper's `done` verb; no other path closes an issue as done.
