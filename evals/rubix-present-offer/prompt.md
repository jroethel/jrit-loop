---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

This case runs in a session where the `rubix-review` skill IS available, so `/loop-plan` Step 2 takes its present branch and offers the Rubix review on the skeleton, before any task body is written.

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

1. An implementation plan is produced and saved inside the repository at `docs/plan.md`, starting as the skeleton.
2. The reply offers the optional two-lens Rubix review of the skeleton exactly once, as soon as the skeleton is written, and waits for the answer rather than running the review unasked.
3. The reply never says the optional Rubix review skill is not installed in this session, because it is installed.
4. The skeleton is written before the offer; the offer is an offer, and declining it never blocks the plan.
