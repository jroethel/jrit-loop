---
max_turns: 30
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion]
---

Run this command first, exactly as written, to create the repository you will be working in.

```bash
mkdir -p repo/docs/loop repo/docs/briefs && cd repo && git init -q . && cat > docs/loop/pointer.md <<'EOF'
# Loop pointer

pointer-version: 1
tracker: github
autonomy-default: pause
rubix-autorun: off
plans-home: docs/plans/
EOF
cat > docs/briefs/2026-10-01.greeting-brief.md <<'EOF'
# Brief: greeting script

## Outcome

The repository gains `hello.sh`, a script that prints one greeting line and exits 0.

## Success criteria

1. `[executed-check]` `bash hello.sh` exits 0 and prints exactly one line.

## Open questions for planning

- Should `hello.sh` print an English greeting only, or take a language argument that also allows Spanish?
EOF
git add -A && git commit -qm "initial" && git branch --show-current > "$(git rev-parse --path-format=absolute --git-path jrit-loop-dispatched)"
```

Now, working inside `repo`, write the implementation plan for the brief at `docs/briefs/2026-10-01.greeting-brief.md`.

## Expected behavior

1. The reply carries the line `question channel: dispatched (marker present)`.
2. The open planning question reaches the user as a plain-text round in the reply: numbered, with 2-4 options, the recommended option listed first and marked `(recommended)`.
3. The interactive question tool is never opened.
4. The reply ends after the round and waits for the answer, so no plan file is written in this run.
