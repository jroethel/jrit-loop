---
name: loop-setup
description: Declare a repo's tracker mode once, write the two pointer docs docs/loop/pointer.md and docs/loop/conventions.md, write the managed instructions section into AGENTS.md with its CLAUDE.md import line, and ensure the tracker label set. Run once per repo, safe to re-run, and it migrates a pre-plugin repo.
---

# loop-setup

Bootstraps the loop convention in the current repo by writing the files itself.
There is no setup script to invoke: this skill creates no executable files and no mirror files, and every artifact it writes is markdown.
It does exactly six things and nothing else:

1. Asks the tracker mode once.
2. Writes `docs/loop/pointer.md`.
3. Writes `docs/loop/conventions.md`.
4. Writes or updates the managed section in `AGENTS.md`.
5. Writes or appends the one-line `@AGENTS.md` import to `CLAUDE.md`.
6. In `github` or `gitlab` mode, ensures the label set exists.

## Tracker modes

Three tracker modes exist: `github`, `gitlab`, and `local`.
When fronting the mode question, present all three verbatim - never paraphrasing the list or silently dropping one - and state each one's viability caveat so the user can see which are usable in this environment:

- `github` - needs an authenticated `gh` CLI (`gh auth status`).
- `gitlab` - needs an origin remote to resolve the host, plus `glab` authenticated to that host (`glab auth status --hostname <host>`) and `jq` on PATH.
- `local` - no external dependency; issues live in the single file `docs/issues.md`.

There is deliberately no `none` (tracker-off) mode: `local` already runs with zero external dependency, so a repo that wants no remote tracker chooses `local`, which supersedes `none` in every case.

Remote for code, local tracking: to run a repo whose code lives on a github or gitlab remote but whose issues stay local, choose `local` and add a `tracker-remote-ack: <github|gitlab>` line to `docs/loop/pointer.md`.
That line acknowledges the deliberate mode-versus-remote split and silences the switch offer; it is the supported way to pair a remote codebase with local issue tracking, and no multi-backend "combination" mode exists or is planned.

## The mode question, idempotent

The tracker mode is declared, never inferred from `git remote`.
If `docs/loop/pointer.md` already carries a `tracker:` key, never re-ask the mode: the existing declaration stands and the run continues with the remaining actions.
When the declared mode disagrees with a github or gitlab remote, say "declared tracker: X, but the remote is Y" and offer a declinable switch to the remote's backend.
The offer is silenced by a `tracker-remote-ack:` line in the pointer doc - a hand-written acknowledgment of a deliberate mode-versus-remote disagreement that this skill never writes itself.

## What it writes

### docs/loop/pointer.md

Render the pointer template carried in `references/pointer-templates.md` with the angle-bracket slots filled from this run's answers.
On a fresh (non-migration) setup the `autonomy-default:` slot is written `pause`, matching the loop-auto skill's default when the key is absent; a migration carries the old repo's value forward.
Write `local-issues-file:` only when `tracker:` is `local`.
Omit `tracker-remote-ack:` when rendering: it appears in the file only when the repo pairs a remote codebase with local tracking, and when it appears it was written by hand; on a re-run, preserve an existing `tracker-remote-ack:` line rather than dropping it.

### docs/loop/conventions.md

Write the prose surface so it carries exactly what the conventions description in `references/pointer-templates.md` requires: the `agent:` label vocabulary and its fixed semantics, the filename grammar, the archive and graduation rules, and the verbose-announce convention.
In `local` mode it also names `docs/issues.md` and the grammar it follows there.

### The managed section in AGENTS.md

Write into `AGENTS.md` at the target repo root a block delimited by `<!-- jrit-loop:begin -->` and `<!-- jrit-loop:end -->`.
If the markers do not exist, append the block at the end of the file; if the file does not exist, create it holding the block.
On a re-run, rewrite only the content between those markers and never touch anything outside them.
The block contains, in this order:

1. The declared tracker mode and the one command that lists open issues in that mode.
2. The pointer-doc path `docs/loop/pointer.md`.
3. The `agent:` label vocabulary in one line.
4. The sentence that claim, done, status, and next-eligible run through the receipt helper shipped inside the loop-drive skill.

The list command is `gh issue list --state open` in `github` mode, `glab issue list --opened` in `gitlab` mode, and in `local` mode a pointer to the `docs/issues.md` sections whose `state:` is `open`.
Rendered shape, github mode:

```markdown
<!-- jrit-loop:begin -->
Tracker: github. Open issues: `gh issue list --state open`.
Pointer doc: `docs/loop/pointer.md`.
Labels: `agent:todo`, `agent:working`, `agent:needs-input`, `agent:review`, `agent:done` - exactly one active at a time, `agent:done` only through the receipt helper.
Claim, done, status, and next-eligible run through the receipt helper shipped inside the loop-drive skill.
<!-- jrit-loop:end -->
```

### The import line in CLAUDE.md

Verified 2026-09-13: Claude Code does not read `AGENTS.md` natively, and the documented pattern is a `CLAUDE.md` that imports it.
Write `CLAUDE.md` at the target repo root containing the single line `@AGENTS.md` when the file does not exist.
Append that line when the file exists and does not already contain it.
Never rewrite any other line of an existing `CLAUDE.md`.

## The label set

The sixth action exists because nothing else in the system creates the labels.
The `agent:` vocabulary is load-bearing in the pointer docs, the receipt helper's four verbs (claim, done, status, next-eligible) all manipulate it, and no verb provisions it; without this step every label the toolkit depends on has no creator and the first `status` call on a fresh repo fails on a missing label.
The label set is exactly `idea`, `agent:todo`, `agent:working`, `agent:needs-input`, `agent:review`, `agent:done`, `wayfinder:map`.
Provision it idempotently, one command per label, the `|| true` because an already-existing label is a success condition here and not an error.

In `github` mode run this block, which is the label-provisioning command block given in full and in this one place:

```bash
gh label create idea --description "Parked backlog item, not active work" || true
gh label create agent:todo --description "Open and unclaimed" || true
gh label create agent:working --description "Claimed and in progress" || true
gh label create agent:needs-input --description "Blocked on a human answer" || true
gh label create agent:review --description "Work done, awaiting review" || true
gh label create agent:done --description "Closed only through the receipt helper's done verb" || true
gh label create wayfinder:map --description "Wayfinder mapping item" || true
```

In `gitlab` mode run the same seven labels with the `glab` equivalent:

```bash
glab label create idea --description "Parked backlog item, not active work" || true
glab label create agent:todo --description "Open and unclaimed" || true
glab label create agent:working --description "Claimed and in progress" || true
glab label create agent:needs-input --description "Blocked on a human answer" || true
glab label create agent:review --description "Work done, awaiting review" || true
glab label create agent:done --description "Closed only through the receipt helper's done verb" || true
glab label create wayfinder:map --description "Wayfinder mapping item" || true
```

In `local` mode no labels exist to create and this step is skipped.
Say so in one line: local mode has no tracker labels, so label provisioning is skipped.

## Migrating a pre-plugin repo

Detect the pre-plugin layout: `config/repo-state.md` exists and `docs/loop/pointer.md` does not.
This skill owns the migration; the other loop skills detect the same shape and refuse to proceed silently, pointing here.
Read the old file's `tracker:`, `rubix-autorun:`, `autonomy-default:`, and Lanes table.
Render `docs/loop/pointer.md` and `docs/loop/conventions.md` from them using the templates in `references/pointer-templates.md`: `rubix-autorun:` and `autonomy-default:` keep their names and values, and each old lane becomes the tracker read named in the Lanes table, with no mirror.
Then handle the generated mirrors, preview-then-assent and never silent:

1. List the files actually found - the three mirror files `ISSUES.md`, `BACKLOG.md`, and `WAYFINDER.md`, plus the one runtime state file `docs/chain-state.md` - with a count, for example "found 2: ISSUES.md, BACKLOG.md".
2. State plainly that they are untracked and therefore unrecoverable once removed, and that they are deleted rather than frozen because the tracker's own UI is now the view.
3. Delete them only after explicit assent.
   A decline leaves every file in place and ends the migration with nothing removed.

Finally, leave `config/repo-state.md` and `config/conventions.md` in place for the human to remove.
Announce this as the one thing migration does not do for them.

After the pointer docs are rendered, the run continues with the remaining actions as normal: the `AGENTS.md` managed section, the `CLAUDE.md` import line, and, in `github` or `gitlab` mode, the label set.

## The import sweep

After the six actions, offer the import sweep: scan for pre-existing work files and file the outstanding items as tracker issues.
The recommended default is the triage workflow in `references/import-triage.md`.
The sweep runs in all three modes, loop-setup is attended-only and ignores the loop-auto autonomy knob, and there is no unattended triage mode.

## Re-running

Re-running is safe: the mode question is never re-asked, an existing `tracker-remote-ack:` line is preserved, the managed section rewrites only between its markers, and the label commands treat an existing label as success.
The skill never writes mirror files, never creates an executable, and never touches a file outside the six actions and the migration named above.
