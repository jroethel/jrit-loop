---
name: molt-fixture-restated-harness
description: >
  Test fixture for the molt protocol (criterion 2 of the 2026-09-25 molt harness-evidence plan).
  Skill-shaped but not a skill, never installed.
---

# Commit helper (molt test fixture)

Use this when committing work in a repo that follows the tracker-token convention.

### Commit safety rules

- Leave the git configuration alone; never change user.name, user.email, or any other config value.
- Do not bypass commit hooks with flags such as --no-verify.
- When a pre-commit hook fails, fix the problem and make a fresh commit instead of amending the previous one.
- Stage files by name rather than adding everything with a blanket add.

### Tracker token in commit subjects

Every commit subject starts with the tracker token of the issue it serves, for example `#19: tighten the gate`.
The reason: the receipt helper links commits to issues by that prefix, and a commit without it is invisible to the done check.
