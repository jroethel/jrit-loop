---
max_turns: 25
timeout_seconds: 900
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Run this command first, exactly as written, to create the repository you will be working in.

```bash
mkdir -p repo/config && cd repo && git init -q . && cat > README.md <<'EOF'
This directory is a fixture representing a repo still on the pre-plugin layout, and it must never gain a `docs/loop/pointer.md`.
EOF
cat > config/repo-state.md <<'EOF'
# Repo State Map

template-version: 7
rubix-autorun: ask
tracker: github

## Lanes

| Lane    | Home       | Status      |
| ---     | ---        | ---         |
| Issues  | ISSUES.md  | mirror kept |
| Backlog | BACKLOG.md | mirror kept |
EOF
git add -A && git commit -qm "initial"
```

Now, working inside `repo`, I want to brainstorm a new idea with you: a weekly digest that summarises the repository's open issues and mails it to the team every Monday.
Take it from here.

## Expected behavior

1. No brief is drafted and no brief file is written.
2. The reply names the file `config/repo-state.md` explicitly, by that path.
3. The reply says plainly that this repository is still on the older, pre-plugin loop-stack layout.
4. The reply offers to run the loop-setup skill's migration before any other work continues.
5. Quietly carrying on with the brainstorm anyway is wrong, however good the resulting brief would be.
