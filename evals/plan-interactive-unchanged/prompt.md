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
git add -A && git commit -qm "initial"
```

Now, working inside `repo`, write the implementation plan for the brief at `docs/briefs/2026-10-01.greeting-brief.md`.

## Expected behavior

1. The reply carries no `question channel:` line, because the interactive path prints nothing about the test.
2. The open planning question is put to the user through the interactive question tool.
