# Pointer templates

This reference carries the two templates loop-setup renders into a target repo and the grammar its local issues file follows.
Everything verbatim here is the spec of record: render it with the angle-bracket slots filled, never paraphrased.

## The docs/loop/pointer.md template

```markdown
# Loop pointer

This file is the machine surface: the line-anchored keys below are what the loop skills read.
Prose conventions live in the sibling `docs/loop/conventions.md`.

pointer-version: 1
tracker: <github|gitlab|local>
autonomy-default: <pause|auto>
rubix-autorun: <ask|off|on>
handoffs-home: docs/handoffs/
briefs-home: docs/briefs/
plans-home: docs/plans/
reviews-home: docs/reviews/
archive-home: docs/archive/
local-issues-file: docs/issues.md
tracker-remote-ack: <github|gitlab>

## Lanes

| Lane      | Home                               | How                                             |
| ---       | ---                                | ---                                             |
| Issues    | the tracker, open, no `idea`       | Read with `gh` or `glab` directly; no mirror.   |
| Backlog   | the tracker, label `idea`          | Read with `gh` or `glab` directly; no mirror.   |
| Wayfinder | the tracker, label `wayfinder:map` | Read with `gh` or `glab` directly; no mirror.   |
| Handoffs  | `docs/handoffs/`                   | Per unit and per session.                       |
| Briefs    | `docs/briefs/`                     | One file per brief.                             |
| Plans     | `docs/plans/`                      | One file per plan.                              |
| Reviews   | `docs/reviews/`                    | One file per review run.                        |
| Archive   | `docs/archive/`                    | Moved work lands here.                          |

Files in the doc-tree homes above share one filename grammar: `YYYY-MM-DD.<descriptor>.md`, date first, dot-separated, the descriptor a short slug with optional tracker-token segments (e.g. `.I6` for issue 6).
The loop-drive resume pointer (`YYYY-MM-DD.<unit-slug>.resume.md`) and the loop-auto batch-review journal (`YYYY-MM-DD.<tokens>.<slug>-batch-review.md`) are the two fixed instances of that grammar.

The tracker is the single source of truth; no generated mirror files exist.
Claim, done, status, and next-eligible run through the receipt helper shipped inside the loop-drive skill.
In `local` mode the receipt helper does not run: claim ordering and evidence-gated done are unenforced, and this repo is single-machine only.
```

Rendering rules for the conditional keys:

`local-issues-file:` is written only when `tracker:` is `local`.
`tracker-remote-ack:` is written only when `tracker:` is `local` and the repo has a github or gitlab remote; it is a hand-written line, never something loop-setup writes itself.
`rubix-autorun:` is the successor of the old `config/repo-state.md` key of the same name, same values (`ask` default, `off`, `on`).

## What docs/loop/conventions.md must contain

`docs/loop/conventions.md` is the prose surface.
It carries, ported from `config/conventions.md`: the `agent:` label vocabulary and its fixed semantics, the filename grammar, the archive and graduation rules, and the verbose-announce convention.
The `agent:` family semantics are unchanged: `agent:todo`, `agent:working`, `agent:needs-input`, `agent:review`, `agent:done`, exactly one active at a time, `agent:done` reachable only through the receipt helper's `done` verb.

## The local-issues grammar (docs/issues.md)

One file, at the path `local-issues-file:` declares (default `docs/issues.md`).

```markdown
# Issues

<!-- next-number: 4 -->

## #1 Short title, no trailing period
state: open
labels: idea, agent:todo

Body prose for issue 1.

> receipt 2026-09-13T14:02:11Z: AGENT STATUS branch=x worktree=y verdict=pass repairs=0

## #2 Another title
state: closed
labels: agent:done

Body prose for issue 2.
```

Rules, exactly:
Sections appear in ascending number order.
`state:` and `labels:` are the first two lines after the heading, in that order, each on its own line.
`state:` is `open` or `closed`.
`labels:` is a comma-plus-space list, possibly empty, and `agent:` states are ordinary members of it.
Issue numbers are monotonically increasing and assigned at create from the `<!-- next-number: N -->` marker, which is bumped in the same write.
Comments and receipts append to the body as `> receipt <UTC ISO-8601>: <text>` lines.
The receipt helper does not run in local mode; the pointer doc discloses that claim and done enforcement are absent there.
