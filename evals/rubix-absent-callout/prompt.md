---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

This case runs in a session where the `rubix-review` skill is NOT available, so `/loop-plan` Step 2 takes its absent branch at the point where it would offer the Rubix review on the skeleton.

Make a directory named `repo` inside your current working directory, turn it into a new git repository, and work only inside it.

Then run this command, exactly as written, so the repository turns the optional plan review page off and the only offer in this run is the Rubix one.

```bash
mkdir -p repo/docs/loop && printf 'pointer-version: 1\ntracker: github\nplan-review: off\n' > repo/docs/loop/pointer.md
```

Here is the brief to plan from.

> **Brief: repository glossary.** The repository needs a short glossary at `docs/glossary.md` covering the three words a newcomer trips over here: brief, plan, unit.
> One `## ` heading per word, two or three sentences each, no links and no cross-references.
> Done means the file exists, holds exactly three `## ` headings, and reads cleanly to somebody who has never seen this repository before.

Turn that brief into an implementation plan and write the plan to `repo/docs/plan.md`.

## Expected behavior

1. An implementation plan is produced and saved inside the repository at `docs/plan.md`.
2. Where the Rubix review would be offered on the skeleton, the run states exactly once, in one plain line, that the optional Rubix review skill is not installed in this session and that the work is continuing without it.
3. The work runs through to a finished plan rather than stopping, asking for the missing review skill to be installed, or treating its absence as a failure.
