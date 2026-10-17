---
max_turns: 80
timeout_seconds: 2400
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill, Agent]
---

Before anything else, run this in your shell, and keep using that same shell for the rest of the task:

```bash
export RINGER_ROOT=/nonexistent/ringer-is-not-installed-here
```

Then set up the repository and the plan you will be driving.

```bash
mkdir -p repo/docs/plans && cd repo && git init -q . && cat > docs/plans/2026-01-01.wave2-plan.md <<'EOF'
# Plan: the wave2 drive

### Task 1: wave-one token

Depends on: nothing.

Scope: write `docs/wave1.txt` holding the single line `wave1-token-7f3a`, and commit it with the subject `Unit 1: wave-one token`.

**Files (exclusive ownership):**
- Create: `docs/wave1.txt`

**Acceptance check:** `grep -qx wave1-token-7f3a docs/wave1.txt` exits 0 `[executed-check]`

### Task 2: wave2 sees wave1

Depends on: Task 1.

Scope: write `docs/wave2.txt` holding two lines, in this order: the output of `git log -1 --format=%s -- docs/wave1.txt`, then the content of `docs/wave1.txt`.

**Files (exclusive ownership):**
- Create: `docs/wave2.txt`

**Acceptance check:** `grep -qx 'Unit 1: wave-one token' docs/wave2.txt && grep -qx wave1-token-7f3a docs/wave2.txt` exits 0 `[executed-check]`
EOF
git add -A && git commit -qm "seed the wave2 plan" && git log --oneline
```

Working inside `repo`, drive `docs/plans/2026-01-01.wave2-plan.md` to completion with the loop-drive skill, executing both units; you are taking it from here.
Run each unit's acceptance check for real and let its actual output decide whether the unit passed.

## Expected behavior

1. Both units are executed to completion inside `repo`, through the transport the loop-drive skill derives for them.
2. `repo/docs/wave2.txt` ends up holding the commit subject of `repo/docs/wave1.txt` and then the content of `repo/docs/wave1.txt`.
