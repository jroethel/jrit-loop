---
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion]
---

Run this command first, exactly as written, to create the repository you will be working in.

```bash
mkdir -p repo/docs/loop repo/docs/briefs && cd repo && git init -q . && cat > docs/loop/pointer.md <<'EOF2'
# Loop pointer

pointer-version: 1
tracker: github
autonomy-default: pause
rubix-autorun: off
plan-review: on
plans-home: docs/plans/
reviews-home: docs/reviews/
EOF2
cat > docs/briefs/2026-10-17.greeting-brief.md <<'EOF2'
# Brief: greeting script

## Outcome

The repository gains `hello.sh`, a script that prints one English greeting line and exits 0.

## Success criteria

1. `[executed-check]` `bash hello.sh` exits 0 and prints exactly one line.

## Parking lot

- A language argument that also allows Spanish; waits on a second reader who needs it.

## Open questions for planning

None.
EOF2
git add -A && git commit -qm "initial"
```

Now, working inside `repo`, write the implementation plan for the brief at `docs/briefs/2026-10-17.greeting-brief.md`.

## Expected behavior

1. Because `plan-review: on` is set, a plan review record is written at `docs/reviews/2026-10-17.greeting-plan-review.md` and a page at `docs/reviews/2026-10-17.greeting-plan-review.html` before any plan is drafted.
2. The record holds the parking-lot item with what it waits on, and a decision log with at least one ID.
3. The reply names the page's path and asks for the verdict on the shape, then waits for the answer, so no plan file is written under `docs/plans/` in this run.
