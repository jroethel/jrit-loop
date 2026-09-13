---
name: loop-track
description: >
  File one tracker issue (idea, plain issue, or a wayfinder-labeled item) into a loop-setup'd
  repo from a plain natural-language ask, no mechanism knowledge required. Triggers on "add as
  an idea/issue to <repo>", "file this as an idea in <repo>", "file this as an issue in <repo>",
  "add this to wayfinder for <repo>", and loop-track. Not for thinking an idea through (that's
  loop-brainstorm) and not for capturing a memo (no such destination exists here).
---

# loop-track: file one tracker issue, no mechanism knowledge required

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

A thin skill: resolve the repo, draft one title/body from the ask in hand, file it with the
right label, report back the number. Nothing else.

<HARD-GATE>
loop-track only ever creates exactly one tracker issue per invocation.
It never writes a memo file, never builds a wayfinder map's structured body (Destination /
Notes / Decisions so far / Not yet specified / Out of scope) or its tickets - a "wayfinder"
ask here just means attaching the `wayfinder:map` label to a plain issue, the same as idea or
issue. A real wayfinder map belongs to `/wayfinder`, not here.
It never invokes loop-brainstorm, loop-plan, or loop-drive.
</HARD-GATE>

## Step 1 - Resolve the label

Read the ask for which of the three flavors is wanted - they are the same GitHub/GitLab issue
object, just different labels:

- "idea" -> `idea`
- "issue" / "bug" / unspecified -> `` (empty; a plain issue)
- "wayfinder" -> `wayfinder:map`

## Step 2 - Resolve the repo

If the ask names a path, use it as-is.
If it names cwd (or names nothing and cwd looks right), use cwd.
Otherwise search under `$HOME` yourself for a loop-setup'd repo (a directory with `docs/loop/pointer.md`) matching that name.
Zero or multiple matches is not your job to disambiguate: report the candidates (or the absence of any) back to the user and ask for an explicit path.

## Step 3 - Draft title and body

Draft a concise title and a body capturing the substance of the request or finding from the
surrounding conversation - the same judgment call `/loop-brainstorm`'s graduation step makes,
just for one item instead of a batch.
Never ask the user to write the title/body themselves; that defeats the point of a low-friction
trigger.

## Step 4 - File it

Resolve the target repo by name or path (Step 2), read `docs/loop/pointer.md` in that repo for its `tracker:` mode, then file the issue directly:

- `github` - `gh issue create --label <label> --title <title> --body <body>` (omit `--label` entirely when the label is empty).
- `gitlab` - `glab issue create --label <label> --title <title> --description <body>`.
- `local` - append a new `## #<n>` section to the file named by the repo's `local-issues-file:` key (default `docs/issues.md`): the heading, then `state: open`, then `labels:` carrying the label (or an empty list), then the body prose - taking `<n>` from the `<!-- next-number: N -->` marker and bumping that marker in the same write.

Relay the tracker's confirmation verbatim: the issue URL that `gh` or `glab` prints, or for `local` the file and the new number.
That relay is the verbose-announce convention (`docs/loop/conventions.md`) and the only report-back this skill offers.
