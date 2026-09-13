---
max_turns: 70
timeout_seconds: 2400
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Run this command first, exactly as written, to create the repository and the plan you will be driving.

```bash
mkdir -p repo/docs/loop && cd repo && git init -q . && cat > docs/loop/pointer.md <<'EOF'
# Loop pointer

This file is the machine surface: the line-anchored keys below are what the loop skills read.
Prose conventions live in the sibling `docs/loop/conventions.md`.

pointer-version: 1
tracker: local
autonomy-default: auto
rubix-autorun: off
handoffs-home: docs/handoffs/
briefs-home: docs/briefs/
plans-home: docs/plans/
reviews-home: docs/reviews/
archive-home: docs/archive/
local-issues-file: docs/issues.md
EOF
cat > docs/loop/conventions.md <<'EOF'
# Loop conventions

Labels: `agent:todo`, `agent:working`, `agent:needs-input`, `agent:review`, `agent:done`, exactly one active at a time.
Filenames are `YYYY-MM-DD.<slug>.<kind>.md`.
EOF
cat > docs/plan.md <<'EOF'
# Plan: repository glossary

## Unit 1 - Glossary

Write `docs/glossary.md` holding exactly three terms - brief, plan, and unit - each under its own `## ` heading with two or three sentences of prose.

Acceptance check: `grep -c '^## ' docs/glossary.md` prints `3`.
EOF
cat > docs/issues.md <<'EOF'
# Issues

## 1 - Unit 1 - Glossary

state: open
labels: agent:todo

The glossary unit from `docs/plan.md`.
EOF
git add -A && git commit -qm "plan, pointer docs and issue" && git log --oneline
```

Working inside `repo`, drive Unit 1 of `docs/plan.md` through to completion.
Do the implementation work yourself in this session rather than dispatching a separate worker.
Run the unit's acceptance check for real and let its actual output decide whether the unit passed.

When the unit is finished, paste into your final message, in this order and verbatim: the entire contents of the resume pointer file the unit produced, then the output of `git log --stat -1`, then the output of `git status --porcelain`.

## Expected behavior

1. The repository holds a file whose path matches `docs/handoffs/*.resume.md`.
2. That file carries all four of the headings `## Unit`, `## State`, `## Next step`, and `## Recent artifacts`, in that order.
3. Its `## Recent artifacts` section lists at least the plan it came from, `docs/plan.md`, as a repository-relative path.
4. The resume pointer file is part of the unit's closing commit, not left sitting uncommitted in the working tree.
