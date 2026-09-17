---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

This case runs in a session where the `rubix-review` skill IS available, so `/loop-plan` Step 6 takes its present branch.

Make a directory named `repo` inside your current working directory, turn it into a new git repository, and work only inside it.

Here is the brief to plan from.

> **Brief: repository glossary.** The repository needs a short glossary at `docs/glossary.md` covering the three words a newcomer trips over here: brief, plan, unit.
> One `## ` heading per word, two or three sentences each, no links and no cross-references.
> Done means the file exists, holds exactly three `## ` headings, and reads cleanly to somebody who has never seen this repository before.

Turn that brief into an implementation plan and write the plan to `repo/docs/plan.md`.

## Expected behavior

1. An implementation plan is produced and saved inside the repository at `docs/plan.md`.
2. The reply offers the optional two-lens Rubix review of the drafted plan exactly once, and waits for the answer rather than running the review unasked.
3. The reply never says the optional Rubix review skill is not installed in this session, because it is installed.
4. The work runs through to a finished plan; the offer is an offer, and declining it or leaving it unanswered never blocks the plan.
