---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Make a directory named `repo` inside your current working directory, turn it into a new git repository, and work only inside it.

Here is the brief to plan from.

> **Brief: repository glossary.** The repository needs a short glossary at `docs/glossary.md` covering the three words a newcomer trips over here: brief, plan, unit.
> One `## ` heading per word, two or three sentences each, no links and no cross-references.
> Done means the file exists, holds exactly three `## ` headings, and reads cleanly to somebody who has never seen this repository before.

Turn that brief into an implementation plan and write the plan to `repo/docs/plan.md`.

## Expected behavior

1. An implementation plan is produced and saved inside the repository at `docs/plan.md`.
2. The reply states exactly once, in one plain line, that the optional Rubix review skill is not installed in this session and that the work is continuing without it.
3. The work runs through to a finished plan rather than stopping, asking for the missing review skill to be installed, or treating its absence as a failure.
