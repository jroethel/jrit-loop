#!/usr/bin/env bash
# Stage tests: the check node run once before unit 1 of the generated drive
# graph, from the run worktree. Writes the plan's path= test blocks, commits
# them with the plan as the tests commit, and points refs/jrit/I<n>/tests at
# it (D21, D23); a rerun with unchanged blocks is a no-op, changed blocks fail.
set -uo pipefail

fail() { echo "stage-tests: $1"; exit 1; }
. ./.ai/jrit/kit-lib.sh || fail "cannot load .ai/jrit/kit-lib.sh; restamp the chain kit"

issue="$(git rev-parse --git-path jrit-chain-issue)"
[ -f "$issue" ] || fail "no jrit-chain-issue; preflight did not run in this worktree"
n="$(cat "$issue")"
ref="refs/jrit/I$n/tests"
plan="$(python3 .ai/jrit/plan_tool.py find-plan ${CEZ_BASE:+--base "$CEZ_BASE"})" || fail "$plan"

# The ref already names a commit on this branch: re-extract the blocks over
# that commit's parent and compare them with what it committed.
if old="$(git rev-parse -q --verify "$ref^{commit}")" && git merge-base --is-ancestor "$old" HEAD; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  committed="$(git diff-tree -r --root --no-commit-id --name-only "$old" -- . ":(exclude)$plan" | sort)"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    git cat-file -e "$old^:$p" 2>/dev/null || continue
    mkdir -p "$tmp/$(dirname "$p")" && git show "$old^:$p" >"$tmp/$p"
  done <<<"$committed"
  same=no
  if out="$(python3 .ai/jrit/plan_lint.py tests "$plan" --out "$tmp")"; then
    written="$(printf '%s\n' "$out" | sed 's/^[a-z]* //' | sed '/^$/d' | sort -u)"
    same=yes
    [ "$written" = "$committed" ] || same=no
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      git show "$old:$p" 2>/dev/null | cmp -s - "$tmp/$p" || same=no
    done <<<"$written"
  fi
  [ "$same" = yes ] || fail "the plan's test blocks changed since the tests commit $(echo "$old" | cut -c1-12); restart at unit=1 on a fresh branch"
  echo "Tests commit: $(echo "$old" | cut -c1-12) (already committed)"
  exit 0
fi

out="$(python3 .ai/jrit/plan_lint.py tests "$plan" --out .)" || { printf '%s\n' "$out"; fail "the plan's test blocks were not written"; }
count=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  git add -- "$p" || exit 1
  count=$((count + 1))
done < <(printf '%s\n' "$out" | sed 's/^[a-z]* //')
git add -- "$plan" || exit 1
empty=""
[ "$count" -gt 0 ] || empty="--allow-empty"
git -c commit.gpgsign=false commit -q $empty -m "Tests for $(basename "$plan") (Refs #$n)" || fail "the tests commit failed"
git update-ref "$ref" HEAD || exit 1
echo "Tests commit: $(git rev-parse HEAD | cut -c1-12) ($count files)"
