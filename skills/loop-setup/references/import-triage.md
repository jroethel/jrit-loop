# Import triage

## This is the default import workflow

Triage is the import workflow, not an exception to it: after loop-setup writes the pointer docs, the agent scans for pre-existing work files, classifies, verifies, and files the outstanding items.
The hard cases - a file mixing many items, work already built, reference prose that is not actionable - are handled by judgment instead of being mangled by the mechanical sweep.
The per-item offer is unchanged, still offering the two fallbacks verbatim (import this one file as one issue, or skip it); triage is what the agent does when neither fallback fits.

## The workflow

Run the steps in order; blast radius grows down the list, and each step narrows what reaches the next.

1. Scan candidates: the repo root (depth 1) and the standard roots (`docs/`, `.planning/`, `.ralph/`, `.scratch/*/issues`), skipping governed lanes and root project files.
   List one normalized path per line, no side effects.
2. Classify each discrete item in each candidate: active work is an issue with no label, and a parked backlog item takes the `idea` label.
3. Verify every item as outstanding or already-built against the codebase and git history; a dropped item, already-built or noise, carries disclosed evidence, a `file:line` or a commit.
4. Present one batch disclosure table, then offer a per-candidate walkthrough for any item the human picks.
5. On approval, file each outstanding item, archive each source doc, and write the record doc.

## The batch disclosure table

One table, shown once, holds the whole run's decisions.
Its columns are source-doc, item, classification, verdict plus evidence, and proposed-action.
Keep the raw table under 110 characters wide.
Put long evidence or prose outside the table when a cell would exceed it.

Example shape, short cells with the long evidence carried below:

| source-doc        | item           | class | verdict       | action        |
| ----------------- | -------------- | ----- | ------------- | ------------- |
| docs/notes.md     | fix export job | issue | outstanding   | file, archive |
| .planning/next.md | retry on 504   | idea  | already-built | drop (E1)     |
| docs/notes.md     | glossary move  | -     | noise         | drop (E2)     |

Dropped evidence, outside the table:

- E1: the retry shipped in `scripts/pull.sh:42`, commit a1b2c3d.
- E2: the glossary move is reference prose, not an actionable item.

## On approval

Approval is the human's explicit assent at the batch-disclosure step of this run, nothing else.
A pre-supplied classification (a `Label:` line, a `Status:` line, a human-written "proposed lane entries" section) says what an item is, not that its issue may be created - never approval to file.
Approval covers the issue bodies the agent writes, not just the classification: the human has not seen those bodies until the disclosure table, so the proposed body (or at minimum its pointer-back footer) is shown for assent before any create.

In this order:

1. File each outstanding item per the declared tracker mode: `gh issue create --label <label> --title <title> --body <body>` in github mode, `glab issue create --label <label> --title <title> --body <body>` in gitlab mode, and in local mode append a new section to `docs/issues.md` per the grammar in `references/pointer-templates.md`, numbered from the `<!-- next-number: N -->` marker and with the marker bumped in the same write.
   The remote command prints the new issue number; capture it for the record doc.
   Pass the `idea` label for a parked backlog item and no label for active work.
2. Archive each source doc to `docs/archive/`.
   Use `git mv` when the file is tracked and plain `mv` otherwise.
3. Write the D1 triage record doc described below.

## Issue body pointer-back footer

Every filed issue body ends with the graduated-item template shape from `docs/loop/conventions.md`, adapted for import.
The footer is the verbatim item prose, then a `---` rule, then three metadata lines.

```
<verbatim item prose from the source doc>
---
Source doc: docs/archive/<original-path>
Imported: YYYY-MM-DD
Restart context: <one line>
```

The verbatim prose lets the issue stand on its own after the source doc is archived.
`Source doc:` points at the archived copy, `Imported:` is today's date, and `Restart context:` is the one line a future session needs to pick the work back up.

## The triage record doc (D1)

Path: `docs/archive/YYYY-MM-DD-import-triage.md`.

Write one record doc per run that had candidates.
A run with zero candidates writes none.
The agent writes it, never bash.

The record holds a triage table with columns source-doc, item, classification (`issue`/`idea`), verdict (`outstanding`/`already-built`/`noise`), evidence, and action, followed by the filed issue numbers.
Every dropped row carries its evidence, so the record contains no drop without evidence (same shape as the batch disclosure table above, with an evidence column and the filed numbers).

## Judgment rules

These carry over unchanged in intent from the exception-only reference this file replaced.

### Split

One issue names one actionable item.
Split a candidate when it is a list, when its sections are independently actionable, or when its title needs an "and" to describe it.
A doc holding N discrete items yields N issues, never one.

### Merge

Merge when two candidates restate the same work, or when one is strictly a subset of the other.
Merge into the one with the better restart context and drop the other.

### Leave in place

Decline the file and leave it where it is when it is reference material, a log, or a completed record.
It will be offered again on the next run, and that repeat is the design speaking up about a live loose end, not a bug.

### Titling

The title is the action, in the imperative, readable without the body.

### Labelling

The `idea` label is the one load-bearing label.
Use `idea` for anything parked by decision and no label for active work.

### Disclosure

Every proposed split is shown to the human with its proposed titles before any issue is created.
This is a judgment, not a check, so it stays with the agent, never in bash.
