#!/usr/bin/env bash
# Chain ending scripts: local CI, the merge card, squash-merge and push, GitHub CI watch,
# and the landing run's branch cleanup.
# Run as `bash .ai/jrit/stage-end.sh <subcommand>` with cwd = the run worktree.
# Reads the preflight state files from the git dir (jrit-chain-base|brief|issue)
# and .ai/jrit/kit.conf; depends on bash, git, jq, python3, and gh.
set -uo pipefail

SUB="${1:-}"
case "$SUB" in
  local-ci|merge-card|merge-push|ci-watch|branch-cleanup) ;;
  *) echo "stage-end: usage: stage-end.sh local-ci|merge-card|merge-push|ci-watch|branch-cleanup"; exit 1 ;;
esac

[ -f .ai/jrit/kit.conf ] && . ./.ai/jrit/kit.conf
. ./.ai/jrit/kit-lib.sh || { echo "$SUB: cannot load .ai/jrit/kit-lib.sh; restamp the chain kit"; exit 1; }
GH=${GH_COMMAND:-gh}

state() {
  local f
  f=$(git rev-parse --git-path "$1")
  [ -f "$f" ] || return 1
  cat "$f"
}

need_state() {
  local v
  v=$(state "$1") || { echo "$SUB: $1 missing in the git dir; run the preflight first"; exit 1; }
  printf '%s\n' "$v"
}

clean_tree() {
  local out
  out=$(git status --porcelain --untracked-files=no)
  if [ -n "$out" ]; then
    echo "$SUB: uncommitted changes in the run worktree:"
    printf '%s\n' "$out"
    exit 1
  fi
}

kit_same() {
  local base=$1 B=$2 bad
  bad=$(kit_diff "$base")
  if [ -n "$bad" ]; then
    echo "$SUB: the chain kit on this branch differs from $B:"
    printf '%s\n' "$bad"
    exit 1
  fi
}

reviews_home() {
  local v="" line
  if [ -f docs/loop/pointer.md ]; then
    while IFS= read -r line; do
      case "$line" in reviews-home:*) v=${line#reviews-home:}; break ;; esac
    done < docs/loop/pointer.md
  fi
  v=${v#"${v%%[![:space:]]*}"}
  [ -n "$v" ] || v=docs/reviews/
  echo "${v%%[[:space:]]*}"
}

local_ci() {
  local log rc
  if [ -z "${CI_COMMAND:-}" ]; then
    echo "local CI: CI_COMMAND is empty in .ai/jrit/kit.conf; set the repo's CI command"
    exit 1
  fi
  log=$(mktemp)
  bash -c "$CI_COMMAND" >"$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    rm -f "$log"
    echo "local CI: green ($CI_COMMAND)"
  else
    tail -n 150 "$log"
    rm -f "$log"
    echo "local CI: red, exit $rc ($CI_COMMAND)"
    exit 1
  fi
}

merge_card() {
  local base B RB brief N plan ids id mb rv p blocks found moved sha changed n line rest count
  clean_tree
  base=$(need_state jrit-chain-base); B=${base#origin/}
  RB=$(git branch --show-current)
  brief=$(need_state jrit-chain-brief)
  N=$(need_state jrit-chain-issue)
  kit_same "$base" "$B"

  echo "Squash-merge $RB into $B and push origin $B?"
  echo "Brief: $brief (Refs #$N)"
  echo "Kit verified: .ai/jrit and the graph match $B."
  echo "Diff since $B:"
  git diff --stat "$base...HEAD"

  echo "Acceptance checks not run by the drive gate (human-shaped tasks, confirm them yourself):"
  ids=""
  if plan=$(python3 .ai/jrit/plan_tool.py find-plan 2>/dev/null) && [ -f "$plan" ]; then
    ids=$(python3 .ai/jrit/plan_tool.py human-tasks "$plan" 2>/dev/null)
  fi
  if [ -n "$ids" ]; then
    while IFS= read -r id; do echo "- Task $id"; done <<<"$ids"
  else
    echo "none"
  fi

  echo "Acceptance checks a later task moved (they pass at their own commit; confirm the move was intended):"
  moved=$(state jrit-chain-moved 2>/dev/null) || moved=""
  if [ -n "$moved" ]; then
    while read -r id sha; do echo "- Task $id (passes at its own commit $sha)"; done <<<"$moved"
  else
    echo "none"
  fi

  echo "Auto-taken decisions (batch-review journal):"
  rv=$(reviews_home)
  mb=$(git merge-base "$base" HEAD)
  found=""
  while IFS= read -r p; do
    case "$p" in *-batch-review.md) ;; *) continue ;; esac
    found=1
    blocks=$(awk -v RS= -v ORS='\n\n' '/BATCH|DEFAULT/' "$p")
    printf '%s\n' "$p"
    if [ "$(printf '%s\n' "$blocks" | wc -c)" -gt 3000 ]; then
      printf '%s\n' "$blocks" | head -c 3000
      echo
      echo "(cut; read $p)"
    else
      printf '%s\n' "$blocks"
    fi
  done < <(git diff --name-only --diff-filter=A "$mb" HEAD -- "$rv")
  [ -n "$found" ] || echo "none recorded"

  echo "Defaults taken on this branch (confirm once by approving):"
  changed=()
  while IFS= read -r p; do changed+=("$p"); done < <(git -c core.quotePath=false diff --name-only "$mb" HEAD)
  count=0
  if [ "${#changed[@]}" -gt 0 ]; then
    while IFS= read -r -d '' rest && IFS= read -r -d '' n && IFS= read -r line; do
      count=$((count + 1))
      [ "$count" -le 40 ] || continue
      echo "- ${rest#HEAD:}:$n: $(printf '%s' "$line" | python3 -I -c 'import sys; sys.stdout.buffer.write(sys.stdin.buffer.read().decode("utf-8", "replace")[:160].encode("utf-8"))')"
    done < <(git -c core.quotePath=false grep -nIz 'NEEDS HUMAN CONFIRMATION' HEAD -- "${changed[@]/#/:(literal)}" ':!.ai' ':!docs/loop' 2>/dev/null)
  fi
  if [ "$count" -eq 0 ]; then echo "none"; elif [ "$count" -gt 40 ]; then echo "($((count - 40)) more; read the plan)"; fi

  echo "Approve squash-merges and pushes. Reject ends the run failed and keeps branch $RB."
}

# RB is deliberately not local: the EXIT trap runs after this function
# returns, and the restore handler still needs the branch name.
merge_push() {
  local base B N brief title sha ci_out out f files root del tip ref
  [ -n "${CEZ_RUN_ID:-}" ] || { echo "merge-push: CEZ_RUN_ID is not set; run this as a cezar check node"; exit 1; }
  clean_tree
  base=$(need_state jrit-chain-base); B=${base#origin/}
  RB=$(git branch --show-current)
  N=$(need_state jrit-chain-issue)
  brief=$(need_state jrit-chain-brief)
  kit_same "$base" "$B"
  title=$(awk '/^# /{sub(/^# /,""); sub(/^Brief: /,""); print; exit}' "$brief")
  [ -n "$title" ] || { echo "merge-push: no '# ' title heading in $brief"; exit 1; }

  restore() {
    git reset -q --hard >/dev/null 2>&1 || :
    git checkout -q "$RB" >/dev/null 2>&1 || :
  }
  trap restore EXIT

  rm -f "$(git rev-parse --git-path jrit-chain-green)"
  tip=$(git rev-parse "$RB")
  ref=$(landed_ref "$N")
  git fetch origin "$B" || { echo "merge-push: cannot fetch origin $B"; exit 1; }
  git checkout -q --detach "origin/$B" || { echo "merge-push: cannot detach at origin/$B"; exit 1; }
  if ! git merge --squash "$RB"; then
    files=""
    while IFS= read -r f; do [ -n "$f" ] && files="$files, $f"; done < <(git diff --name-only --diff-filter=U)
    echo "merge-push: $RB conflicts with origin/$B in: ${files#, }; branch kept"
    exit 1
  fi
  git -c commit.gpgsign=false commit -m "$title (Refs #$N)" -m "Squashed from $RB by chain run $CEZ_RUN_ID; the step-by-step history is kept at $ref (tip $tip)." \
    || { echo "merge-push: the squash commit failed"; exit 1; }
  if ! git merge-base --is-ancestor "origin/$B" "$RB"; then
    if ! ci_out=$(bash -c "${CI_COMMAND:-}" 2>&1); then
      printf '%s\n' "$ci_out" | tail -n 150
      echo "merge-push: local CI is red on the merge with the newer origin/$B; nothing pushed"
      exit 1
    fi
  fi
  if ! out=$(git push origin "HEAD:$B" 2>&1); then
    echo "merge-push: push to origin $B refused:"
    printf '%s\n' "$out"
    exit 1
  fi
  sha=$(git rev-parse HEAD)
  printf '%s\n' "$sha" > "$(git rev-parse --git-path jrit-chain-pushed)"
  printf '%s\n' "$tip" > "$(git rev-parse --git-path jrit-chain-squashed)"
  if ! del=$(git update-ref "$ref" "$tip" 2>&1); then
    echo "merge-push: pushed, but could not write $ref: $(printf '%s\n' "$del" | head -n 1)"
  fi
  if ! del=$(git branch -D "jrit/chain-I$N" 2>&1); then
    echo "merge-push: pushed, but could not delete jrit/chain-I$N: $(printf '%s\n' "$del" | head -n 1)"
  fi
  root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
  echo "local $B is behind origin; to update it run: git -C $root merge --ff-only origin/$B"
  echo "pushed ${sha:0:12} to origin $B"
}

ci_watch() {
  local base B slug url sha sha12 poll start_to run_to runs verdict names id name root
  if [ "${WATCH_GITHUB_CI:-}" != yes ]; then
    echo "GitHub CI watch off for this repo (WATCH_GITHUB_CI=${WATCH_GITHUB_CI:-})"
    exit 0
  fi
  sha=$(state jrit-chain-pushed) || { echo "ci-watch: jrit-chain-pushed missing in the git dir; run merge-push first"; exit 1; }
  slug=${GITHUB_REPO:-}
  if [ -z "$slug" ]; then
    url=$(git remote get-url origin 2>/dev/null) || url=""
    case "$url" in
      git@github.com:*) slug=${url#git@github.com:} ;;
      *://github.com/*) slug=${url#*://github.com/} ;;
    esac
    slug=${slug%.git}
    case "$slug" in
      */*) ;;
      *) echo "ci-watch: cannot tell the GitHub repo; set GITHUB_REPO in .ai/jrit/kit.conf"; exit 1 ;;
    esac
  fi
  poll=${JRIT_CI_POLL_S:-30}
  start_to=${JRIT_CI_START_TIMEOUT_S:-600}
  run_to=${JRIT_CI_RUN_TIMEOUT_S:-3600}
  sha12=${sha:0:12}
  SECONDS=0
  while :; do
    runs=$($GH run list --repo "$slug" --commit "$sha" --json databaseId,name,status,conclusion 2>/dev/null)
    verdict=$(printf '%s' "$runs" | jq -r '
      if (length == 0) then "none"
      elif all(.[]; .status == "completed" and (.conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral")) then "green"
      elif all(.[]; .status == "completed") then "red"
      else "running" end' 2>/dev/null)
    if [ -z "$verdict" ]; then
      echo "ci-watch: cannot read the GitHub run list"
      exit 1
    fi
    case "$verdict" in
      green)
        names=$(printf '%s' "$runs" | jq -r '[.[].name] | join(", ")')
        echo "GitHub CI green on $sha12: $names"
        if printf '%s' "$runs" | jq -e 'any(.[]; .conclusion == "success")' >/dev/null; then
          printf '%s\n' "$sha" > "$(git rev-parse --git-path jrit-chain-green)"
        fi
        exit 0
        ;;
      red)
        echo "GitHub CI is red on $sha12 after the push:"
        printf '%s' "$runs" | jq -r '.[] | select(.status == "completed" and ((.conclusion == "success" or .conclusion == "skipped" or .conclusion == "neutral") | not)) | "\(.databaseId) \(.name)"' |
        while read -r id name; do
          $GH run view "$id" --repo "$slug" --json jobs |
          jq -r --arg w "$name" '.jobs[] | select(.conclusion == "failure" or .conclusion == "timed_out" or .conclusion == "cancelled") | "- \($w): \(.name)"'
        done
        base=$(need_state jrit-chain-base); B=${base#origin/}
        root=$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")
        echo "To undo the push, first bring local $B level with origin: git -C $root merge --ff-only origin/$B"
        echo "then: git -C $root revert --no-edit $sha"
        echo "then: git -C $root push origin $B"
        echo "Or write a fix brief for the failing checks and start a new chain on it."
        exit 1
        ;;
      none)
        if [ "$SECONDS" -ge "$start_to" ]; then
          echo "no GitHub Actions run started for $sha12 within $start_to seconds"
          echo "Nothing is known to be broken: check the Actions tab, and undo only if it turns red."
          exit 1
        fi
        ;;
      running)
        if [ "$SECONDS" -ge "$run_to" ]; then
          names=$(printf '%s' "$runs" | jq -r '[.[] | select(.status != "completed") | .name] | join(", ")')
          echo "GitHub CI still running on $sha12 after $run_to seconds: $names"
          echo "Nothing is known to be broken: check the Actions tab, and undo only if it turns red."
          exit 1
        fi
        ;;
    esac
    sleep "$poll"
  done
}

landed_ref() { echo "refs/jrit/I$1/landed/${CEZ_RUN_ID:0:8}"; }

# Deletes only this run's own branch, and only on full landed evidence (Refs #85).
# One output line; exit 0 for a delete or the designed keep (no green verdict), 1 for every other keep.
branch_cleanup() {
  local b green pushed squashed tip n ref out
  keep() { echo "branch-cleanup: kept ${b:-HEAD}: $1"; exit "${2:-1}"; }
  b=$(git branch --show-current)
  [ -n "$b" ] || keep "no branch checked out"
  [ -n "${CEZ_BRANCH:-}" ] && [ "$CEZ_BRANCH" = "$b" ] || keep "not this run's branch (CEZ_BRANCH=${CEZ_BRANCH:-})"
  [ -n "${CEZ_RUN_ID:-}" ] || keep "CEZ_RUN_ID is not set"
  green=$(state jrit-chain-green) || keep "no green CI verdict (watch off, no run, or not green)" 0
  pushed=$(state jrit-chain-pushed) || keep "no pushed marker"
  [ "$green" = "$pushed" ] || keep "the green verdict is not for the pushed commit"
  squashed=$(state jrit-chain-squashed) || keep "no squashed tip recorded"
  tip=$(git rev-parse "refs/heads/$b")
  [ "$tip" = "$squashed" ] || keep "the branch moved since the squash (${squashed:0:12} squashed, now ${tip:0:12})"
  n=$(state jrit-chain-issue) || keep "no issue number recorded"
  ref=$(landed_ref "$n")
  [ "$(git rev-parse -q --verify "$ref" 2>/dev/null)" = "$squashed" ] || keep "archive ref $ref is missing or not at the squashed tip"
  [ -z "$(git status --porcelain)" ] || keep "uncommitted or untracked files in the run worktree"
  out=$(git checkout -q --detach 2>&1) || keep "cannot detach the worktree: $(printf '%s\n' "$out" | head -n 1)"
  if ! out=$(git branch -D "$b" 2>&1); then
    git checkout -q "$b" >/dev/null 2>&1 || :
    keep "git branch -D failed: $(printf '%s\n' "$out" | head -n 1)"
  fi
  echo "branch-cleanup: deleted $b at ${tip:0:12}; history at $ref; restore: git branch $b $ref"
}

case "$SUB" in
  local-ci) local_ci ;;
  merge-card) merge_card ;;
  merge-push) merge_push ;;
  ci-watch) ci_watch ;;
  branch-cleanup) branch_cleanup ;;
esac
