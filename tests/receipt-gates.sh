#!/usr/bin/env bash
# tests/receipt-gates.sh - Gate 0 plus the six behaviour gates over the receipt
# helper, run against a real throwaway private scratch repo under jroethel
# (explicit consent; delete_repo scope verified on the token).
# Spec of record: plan 2026-09-13 B32, Task 4 step 9.
# Every helper invocation uses the D8-fixed 'bash scripts/receipt.sh ...' form,
# so the test never depends on the execute bit.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- DNS pin: the suite re-execs one mount namespace deep -----------------------
# This host's WSL resolver stalls ~10s on every AAAA query while A-only lookups
# answer in milliseconds, and gh (a static Go binary, so GODEBUG/RES_OPTIONS
# cannot steer it) resolves A+AAAA in parallel: every gh process paid the stall,
# ~25 min for a full run. Scoped to this run only: resolve both GitHub hostnames
# A-only, pin them in a namespace-private /etc/hosts, re-exec the suite inside.
# No system file is touched, addresses are re-resolved every run, and a host
# without unprivileged namespaces runs unpinned (same assertions, just slower).
if [ -z "${GATES_DNS_PINNED:-}" ] && command -v unshare >/dev/null 2>&1; then
  pin=""
  for h in api.github.com github.com; do
    a="$(getent ahostsv4 "$h" 2>/dev/null | awk '{print $1; exit}')"
    [ -n "$a" ] && pin="${pin}${a} ${h}\n"
  done
  if [ -n "$pin" ] && unshare -rm true 2>/dev/null; then
    GATES_HOSTS="$(mktemp)"
    { cat /etc/hosts; printf '%b' "$pin"; } > "$GATES_HOSTS"
    unshare -rm env GATES_DNS_PINNED=1 GATES_HOSTS="$GATES_HOSTS" \
      GATES_SCRIPT="$REPO_ROOT/tests/receipt-gates.sh" \
      bash -c 'mount --bind "$GATES_HOSTS" /etc/hosts && rm -f "$GATES_HOSTS" \
               && exec bash "$GATES_SCRIPT" "$@"' x "$@"
    exit $?
  fi
  echo "note: no namespace DNS pin (unshare or A lookup unavailable); each gh call may stall ~10s" >&2
fi

SCRATCH_NAME=""
CLONE=""
GL_CLONE=""

cleanup() {
  rc=$?
  if [ -n "$SCRATCH_NAME" ]; then
    if ! gh repo delete "jroethel/$SCRATCH_NAME" --yes >/dev/null 2>&1; then
      cat >&2 <<EOF

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! WARNING: scratch repo delete FAILED, manual cleanup is required  !!
!! Run exactly this command:                                        !!
!!   gh repo delete jroethel/$SCRATCH_NAME --yes                    !!
!! A private test repo nobody remembers must not be left behind.    !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOF
    fi
  fi
  [ -n "$CLONE" ] && rm -rf "$CLONE"
  [ -n "$GL_CLONE" ] && rm -rf "$GL_CLONE"
  exit "$rc"
}
trap cleanup EXIT

# --- setup, part 1: sweep stale scratch repos left by earlier failed runs ------
# First action, before creating anything: a run that crashed yesterday must not
# accumulate repos forever. Delete targets are only jrit-loop-scratch-* under
# jroethel, never anything else.
gh repo list jroethel --limit 200 --json name -q '.[].name' 2>/dev/null \
  | grep '^jrit-loop-scratch-' | while read -r stale; do
    echo "sweep: deleting stale scratch repo jroethel/$stale left by an earlier run"
    gh repo delete "jroethel/$stale" --yes || true
  done

# --- setup, part 2: the throwaway repo this run owns ---------------------------
# Name uses date +%s and $RANDOM, never $$: a PID collides across hosts and
# across a reboot, and a collision would make the trap delete a repo this run
# did not create.
SCRATCH_NAME="jrit-loop-scratch-$(date +%s)-$RANDOM"
gh repo create "jroethel/$SCRATCH_NAME" --private >/dev/null \
  || fail "could not create scratch repo jroethel/$SCRATCH_NAME"
CLONE="$(mktemp -d)"
gh repo clone "jroethel/$SCRATCH_NAME" "$CLONE" 2>/dev/null \
  || fail "could not clone jroethel/$SCRATCH_NAME into $CLONE"
mkdir -p "$CLONE/docs/loop" "$CLONE/scripts"
printf '# Loop pointer\n\ntracker: github\n' > "$CLONE/docs/loop/pointer.md"
# The helper is copied into the clone so the D8-fixed 'bash scripts/receipt.sh'
# form resolves from the scratch repo cwd, exactly as loop-drive's prose resolves
# it relative to the skill's own directory. Same bytes, no execute bit involved.
cp "$REPO_ROOT/skills/loop-drive/scripts/receipt.sh" "$CLONE/scripts/receipt.sh"
cd "$CLONE" || fail "could not enter the clone at $CLONE"

mkissue() {                   # args: title body -> prints the new issue number
  local url
  url="$(gh issue create --title "$1" --body "$2")" || fail "gh issue create failed for '$1'"
  printf '%s' "${url##*/}"
}
gh_labels() {                 # arg: num -> comma-joined label names
  gh issue view "$1" --json labels -q '[.labels[].name] | join(",")'
}
gh_state() {                  # arg: num -> OPEN or CLOSED
  gh issue view "$1" --json state -q .state
}

# --- Gate 0, an unprovisioned repo names its provisioner -----------------------
# No agent: labels exist yet: nothing in the helper creates them, and a repo that
# has never been through loop-setup has none of them.
echo "== Gate 0: an unprovisioned repo names its provisioner"
N0="$(mkissue 'gate 0 unprovisioned probe' 'no labels exist yet')"
out="$(bash scripts/receipt.sh status "$N0" working 2>&1)"; rc=$?
[ "$rc" -ne 0 ] || fail "Gate 0: status on an unprovisioned repo exited 0, expected failure (got: $out)"
case "$out" in
  *"loop-setup skill provisions"*) ;;
  *) fail "Gate 0: failure message does not name the loop-setup skill as the provisioner: $out" ;;
esac
# Simulates loop-setup rather than substituting for it: this is the exact
# label-provisioning command block loop-setup's setup prose prescribes. If the
# skill's prose and this block ever diverge, one of them is wrong and the
# divergence is the finding.
gh label create idea --description "Backlog lane candidate" || true
gh label create agent:todo --description "Open, unclaimed work" || true
gh label create agent:working --description "Actively claimed by a session" || true
gh label create agent:needs-input --description "Waiting on a human decision" || true
gh label create agent:review --description "Work done, awaiting review" || true
gh label create agent:done --description "Completed through the receipt helper's done verb" || true
gh label create wayfinder:map --description "Wayfinder map issue" || true
bash scripts/receipt.sh status "$N0" working || fail "Gate 0: status working still fails after loop-setup's label block ran"

# --- Gate 1, failing `done --ran` routes to review -----------------------------
echo "== Gate 1: failing done --ran routes to review"
N1="$(mkissue 'gate 1 failing ran' 'the cited command fails')"
bash scripts/receipt.sh status "$N1" working || fail "Gate 1: status working failed"
out="$(bash scripts/receipt.sh done "$N1" --receipt 'work claimed done' --ran 'exit 3' 2>&1)"; rc=$?
[ "$rc" -eq 7 ] || fail "Gate 1: done --ran with a failing command exited $rc, expected 7 (got: $out)"
[ "$(gh_state "$N1")" = "OPEN" ] || fail "Gate 1: issue #$N1 must stay open on a failed --ran, state is $(gh_state "$N1")"
labels="$(gh_labels "$N1")"
case ",$labels," in *,agent:review,*) ;; *) fail "Gate 1: labels '$labels' lack agent:review" ;; esac
case ",$labels," in *,agent:done,*) fail "Gate 1: labels '$labels' must not carry agent:done on a failed --ran" ;; esac
body="$(gh issue view "$N1" --json comments -q '.comments[].body')"
printf '%s\n' "$body" | grep -qF -- '--ran exit 3 exit 3' || fail "Gate 1: no receipt comment carrying the --ran exit tail"
printf '%s\n' "$body" | grep -q 'exit 3' || fail "Gate 1: no receipt comment naming exit 3"

# --- Gate 2, contested claim is refused -----------------------------------------
echo "== Gate 2: contested claim is refused"
N2="$(mkissue 'gate 2 contested claim' 'two sessions claim the same ticket')"
out="$(bash scripts/receipt.sh claim "$N2" session-aaa)"; rc=$?
[ "$rc" -eq 0 ] || fail "Gate 2: first claim exited $rc, expected 0"
[ "$out" = "session-aaa" ] || fail "Gate 2: first claim printed '$out', expected session-aaa"
sleep 1
err="$(bash scripts/receipt.sh claim "$N2" session-bbb 2>&1 1>/dev/null)"; rc=$?
[ "$rc" -eq 4 ] || fail "Gate 2: second claim exited $rc, expected 4"
case "$err" in
  *RACE:*) ;;
  *) fail "Gate 2: second claim stderr lacks RACE: ($err)" ;;
esac
case "$err" in
  *session-aaa*) ;;
  *) fail "Gate 2: reported owner is not session-aaa ($err)" ;;
esac

# --- Gate 3, `--reclaim` overrides ----------------------------------------------
echo "== Gate 3: --reclaim overrides"
out="$(bash scripts/receipt.sh claim "$N2" session-bbb --reclaim)"; rc=$?
[ "$rc" -eq 0 ] || fail "Gate 3: reclaim exited $rc, expected 0"
[ "$out" = "session-bbb" ] || fail "Gate 3: reclaim printed '$out', expected session-bbb"

# --- Gate 4, exactly one status ---------------------------------------------------
echo "== Gate 4: exactly one status"
bash scripts/receipt.sh status "$N2" todo || fail "Gate 4: status todo failed"
bash scripts/receipt.sh status "$N2" review || fail "Gate 4: status review failed"
labels="$(gh_labels "$N2")"
n="$(printf '%s\n' "$labels" | tr ',' '\n' | grep -c '^agent:')"
[ "$n" -eq 1 ] || fail "Gate 4: expected exactly one agent: label on #$N2, found $n ('$labels')"
[ "$labels" = "agent:review" ] || fail "Gate 4: the one agent: label is '$labels', expected agent:review"

# --- Gate 5, done without evidence is refused -------------------------------------
echo "== Gate 5: done without evidence is refused"
out="$(bash scripts/receipt.sh done "$N2" --receipt 'looks good to me' 2>&1)"; rc=$?
[ "$rc" -eq 5 ] || fail "Gate 5: done without executed-check evidence exited $rc, expected 5 (got: $out)"
[ "$(gh_state "$N2")" = "OPEN" ] || fail "Gate 5: issue #$N2 must stay open without evidence, state is $(gh_state "$N2")"

# --- Gate 6, `next-eligible` respects blocking ------------------------------------
echo "== Gate 6: next-eligible respects blocking"
NB="$(mkissue 'gate 6 blocker' 'still open, blocks A')"
NA="$(mkissue 'gate 6 A' "Blocked by: #$NB")"
gh issue edit "$NA" --add-label agent:todo || fail "Gate 6: could not label #$NA agent:todo"
NC="$(mkissue 'gate 6 C' 'no blockers, higher number than A')"
gh issue edit "$NC" --add-label agent:todo || fail "Gate 6: could not label #$NC agent:todo"
[ "$NC" -gt "$NA" ] || fail "Gate 6: setup ordering is wrong, C ($NC) must number higher than A ($NA)"
out="$(bash scripts/receipt.sh next-eligible)"
case "$out" in
  *"SELECTED #$NC:"*) ;;
  *) fail "Gate 6: expected SELECTED #$NC with #$NB open, got: $out" ;;
esac
gh issue close "$NB" || fail "Gate 6: could not close blocker #$NB"
out="$(bash scripts/receipt.sh next-eligible)"
case "$out" in
  *"SELECTED #$NA:"*) ;;
  *) fail "Gate 6: expected SELECTED #$NA after closing #$NB, got: $out" ;;
esac

# --- Gate 7, successful `done` closes and labels ----------------------------------
# Added at the wave-3 gate 2026-09-13: gates 1 and 5 exercised exit 7 and exit 5
# but never the success path, and a defect there shipped invisibly.
echo "== Gate 7: successful done closes and labels"
N7="$(mkissue 'gate 7 successful done' 'the cited command passes')"
bash scripts/receipt.sh claim "$N7" session-gate7 || fail "Gate 7: claim failed"
bash scripts/receipt.sh status "$N7" working || fail "Gate 7: status working failed"
out="$(bash scripts/receipt.sh done "$N7" --receipt 'suite green' --ran 'true' 2>&1)"; rc=$?
[ "$rc" -eq 0 ] || fail "Gate 7: successful done exited $rc, expected 0 (got: $out)"
[ "$(gh_state "$N7")" = "CLOSED" ] || fail "Gate 7: issue #$N7 must be CLOSED after done, state is $(gh_state "$N7")"
labels="$(gh_labels "$N7")"
case ",$labels," in *,agent:done,*) ;; *) fail "Gate 7: labels '$labels' lack agent:done" ;; esac
n="$(printf '%s\n' "$labels" | tr ',' '\n' | grep -c '^agent:')"
[ "$n" -eq 1 ] || fail "Gate 7: expected only agent:done on #$N7, found $n agent: labels ('$labels')"
body="$(gh issue view "$N7" --json comments -q '.comments[].body')"
printf '%s\n' "$body" | grep -qF -- 'suite green --ran true exit 0' || fail "Gate 7: no receipt comment carrying the done receipt line"

# --- GitLab coverage, conditional -------------------------------------------------
# The helper dispatches to two backends and the gates above exercise one of them,
# so a glab regression would ship unnoticed. Set GITLAB_TEST_PROJECT to a
# group/project path to run Gates 1 and 2 against the gitlab backend too.
if [ -n "${GITLAB_TEST_PROJECT:-}" ]; then
  echo "== GitLab gates 1-2 against $GITLAB_TEST_PROJECT"
  GL_CLONE="$(mktemp -d)"
  glab repo clone "$GITLAB_TEST_PROJECT" "$GL_CLONE" 2>/dev/null \
    || fail "gitlab gates: could not clone $GITLAB_TEST_PROJECT"
  mkdir -p "$GL_CLONE/docs/loop" "$GL_CLONE/scripts"
  printf '# Loop pointer\n\ntracker: gitlab\n' > "$GL_CLONE/docs/loop/pointer.md"
  cp "$REPO_ROOT/skills/loop-drive/scripts/receipt.sh" "$GL_CLONE/scripts/receipt.sh"
  HERE="$PWD"
  cd "$GL_CLONE" || fail "gitlab gates: could not enter the clone"
  for l in idea agent:todo agent:working agent:needs-input agent:review agent:done wayfinder:map; do
    glab label create --name "$l" 2>/dev/null || true
  done
  gl_issue() {               # args: title body -> prints the new issue iid
    local gout
    gout="$(glab issue create --yes --no-editor -t "$1" -d "$2")" || fail "glab issue create failed for '$1'"
    printf '%s' "$gout" | grep -oE '/issues/[0-9]+' | tail -1 | sed 's#.*/##'
  }
  G1="$(gl_issue 'gl gate 1 failing ran' 'the cited command fails')"
  bash scripts/receipt.sh status "$G1" working || fail "gitlab gate 1: status working failed"
  out="$(bash scripts/receipt.sh done "$G1" --receipt 'work claimed done' --ran 'exit 3' 2>&1)"; rc=$?
  [ "$rc" -eq 7 ] || fail "gitlab gate 1: done --ran exited $rc, expected 7 (got: $out)"
  glab issue view "$G1" --comments | grep -qF -- '--ran exit 3 exit 3' \
    || fail "gitlab gate 1: no receipt comment carrying the --ran exit tail"
  G2="$(gl_issue 'gl gate 2 contested claim' 'two sessions claim the same ticket')"
  out="$(bash scripts/receipt.sh claim "$G2" session-gla)"; rc=$?
  [ "$rc" -eq 0 ] || fail "gitlab gate 2: first claim exited $rc, expected 0"
  sleep 1
  err="$(bash scripts/receipt.sh claim "$G2" session-glb 2>&1 1>/dev/null)"; rc=$?
  [ "$rc" -eq 4 ] || fail "gitlab gate 2: second claim exited $rc, expected 4"
  case "$err" in
    *RACE:*) ;;
    *) fail "gitlab gate 2: second claim stderr lacks RACE: ($err)" ;;
  esac
  glab issue close "$G1" 2>/dev/null || true
  glab issue close "$G2" 2>/dev/null || true
  cd "$HERE" || fail "gitlab gates: could not return to $HERE"
  echo "PASS: gitlab gates 1-2 against $GITLAB_TEST_PROJECT"
else
  echo "skip: gitlab gates (GITLAB_TEST_PROJECT unset)"
fi

echo "PASS: receipt gates 0-7"
