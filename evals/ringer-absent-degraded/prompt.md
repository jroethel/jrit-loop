---
max_turns: 50
timeout_seconds: 1500
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Before anything else, run this in your shell, and keep using that same shell for the rest of the task:

```bash
export RINGER_ROOT=/nonexistent/ringer-is-not-installed-here
```

Then make a directory named `repo` inside your current working directory, turn it into a new git repository, and work only inside it.

Here is the plan to compile into a run. It has two units, and the second depends on the first.

**Unit 1 - Glossary.** Write `docs/glossary.md` holding three terms, each under its own `## ` heading with two or three sentences of prose.
Acceptance check: `grep -c '^## ' docs/glossary.md` prints `3`.

**Unit 2 - Changelog seed.** Write `docs/changelog-seed.md` holding one dated line naming the glossary. Depends on Unit 1.
Acceptance check: `test -s docs/changelog-seed.md`.

Compile the run and write the plan you emit to `repo/drive-plan.md`.
Do not execute either unit: the emitted plan document is the deliverable.

## Expected behavior

1. Every unit in the emitted plan is routed to the harness's own background-agent transport, and no unit is routed to ringer.
2. The emitted plan's pre-flight contains, word for word, this line: ringer not found at the probed path; running degraded: background-agent transport only, routing by prior.
3. The emitted plan does not cite a ringer scoreboard, a ringer run record, or any other ringer-produced evidence as a source for its model choices.
