# Fixture Plan

> A small plan in the format plan_lint.py checks.

**Goal:** Exercise every lint rule on four tasks.

## Decision log

| ID  | Decision                      | Source  |
| --- | ----------------------------- | ------- |
| D1  | The module lives in src/a.py. | human   |
| D2  | Docs ship beside the code.    | default |

## Run shape

| Wave | Task                      | Shape | Type         | Model | Why                            |
| ---- | ------------------------- | ----- | ------------ | ----- | ------------------------------ |
| 1    | Task 1 the module         | auto  | code-feature | -     | executed check, disjoint files |
| 2    | Task 2 the module's edits | auto  | code-feature | -     | executed check, disjoint files |
| 2    | Task 3 the docs page      | auto  | docs         | opus  | executed check, disjoint files |
| 3    | Task 4 the push           | human | probe        | -     | pushes to origin               |

## Tasks

### Task 1: the module

Depends on: none
Shape: auto
Type: code-feature
Decisions: D1

**Files (exclusive ownership):**
- Create: `src/a.py`
- Test: `tests/test_one.py`

**Edge inputs:**
- An empty input.

**Acceptance check:** `python3 tests/test_one.py` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test

```python path=tests/test_one.py
from src.a import one
assert one == 1
```

- [ ] Step 2: Write `src/a.py`.

### Task 2: the module's edits

Depends on: Task 1
Shape: auto
Type: code-feature
Decisions: D1

**Files (exclusive ownership):**
- Modify: `src/a.py:1-5`
- Test: `tests/test_two.py`

**Edge inputs:**
- A negative input.

**Acceptance check:** `python3 tests/test_two.py` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test

```python path=tests/test_two.py
from src.a import two
assert two == 2
```

- [ ] Step 2: Edit `src/a.py`.

### Task 3: the docs page

Depends on: Task 1
Shape: auto
Type: docs
Model: opus
Decisions: D2

**Files (exclusive ownership):**
- Create: `docs/x.md`

**Edge inputs:** none (prose only)

**Acceptance check:** `bash tests/shared/test_style.sh` exits 0 `[executed-check]`

- [ ] Step 1: Write `docs/x.md`.

### Task 4: the push

Depends on: Task 2, Task 3
Shape: human, pushes to origin
Type: probe
Decisions: none

**Files (exclusive ownership):**
- Modify: `README.md`

**Edge inputs:**
- A rejected push.

**Acceptance check:** `git ls-remote --exit-code origin main` exits 0 `[executed-check]`

- [ ] Step 1: Push `main` to origin.

## Shared tests

### Shared test: tests/shared/test_style.sh

```bash path=tests/shared/test_style.sh
#!/usr/bin/env bash
! grep -rn 'TODO' docs
```
