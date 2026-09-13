#!/usr/bin/env bash
# tests/pre-plugin-detection.sh - static proof that the pre-plugin detection
# paragraph is wired into the eight consumer skills, byte-for-byte per D3.
# This script proves the wiring only; the behavioural half of criterion 6 is
# Task 10's pre-plugin-repo-refusal eval case, which runs a real model against
# this same fixture.
# Spec of record: plan 2026-09-13 B32, Task 12 step 2.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# The D3 paragraph, held byte-for-byte in this file so the comparison needs no
# external source of record. It is four physical lines, one sentence per line,
# because the byte comparison and the house-style check must agree.
# A quoted literal inside [[ == ]] matches the newlines exactly, so the four
# lines must appear consecutively; any one line alone never satisfies it.
d3_paragraph="$(cat <<'D3_PARAGRAPH'
**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.
D3_PARAGRAPH
)"

contains_paragraph() { [[ "$(cat "$1")" == *"$d3_paragraph"* ]]; }

# The eight skills D3 says carry the paragraph.
for name in loop-auto loop-brainstorm loop-drive loop-improve loop-plan loop-track handoff wayfinder; do
  file="skills/$name/SKILL.md"
  [ -f "$file" ] || fail "$file does not exist"
  contains_paragraph "$file" \
    || fail "skills/$name/SKILL.md does not contain the D3 detection paragraph byte-for-byte"
done

# loop-review and loop-molt are exempt by D3: loop-review works on any repo
# with zero setup, and loop-molt audits prose artifacts rather than repo state.
for name in loop-review loop-molt; do
  file="skills/$name/SKILL.md"
  [ -f "$file" ] || fail "$file does not exist"
  ! contains_paragraph "$file" \
    || fail "skills/$name/SKILL.md carries the paragraph but D3 exempts it"
done

# loop-setup owns the migration, so it carries the migration heading instead.
grep -q '^## Migrating a pre-plugin repo$' skills/loop-setup/SKILL.md \
  || fail "skills/loop-setup/SKILL.md lacks the '## Migrating a pre-plugin repo' heading"

# The fixture the refusal is expected against: pre-plugin state present,
# pointer absent.
[ -f tests/fixtures/pre-plugin-repo/config/repo-state.md ] \
  || fail "fixture tests/fixtures/pre-plugin-repo/config/repo-state.md is missing"
[ ! -e tests/fixtures/pre-plugin-repo/docs/loop/pointer.md ] \
  || fail "fixture must not carry docs/loop/pointer.md; a present pointer would make it a post-plugin repo"

echo "PASS: pre-plugin detection wired in 8 skills"
