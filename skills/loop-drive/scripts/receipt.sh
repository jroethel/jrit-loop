#!/usr/bin/env bash
# receipt.sh - the receipt helper shipped inside the loop-drive skill.
# Reads the tracker mode from the CALLER's cwd docs/loop/pointer.md and dispatches
# four verbs (status, claim, done, next-eligible) to github (gh) or gitlab (glab).
# It operates on the caller's cwd repo, never on this script's own location, and
# the invocation form is fixed everywhere: bash scripts/receipt.sh <verb> ...
set -uo pipefail
fail() { echo "receipt: $1" >&2; exit 1; }
PTR="docs/loop/pointer.md"

mode_read() {            # prints github|gitlab; exit 3 when the key is absent, exit 2 on local
  local v="$(grep -E '^tracker:' "$PTR" 2>/dev/null | head -1 | sed -E 's/^tracker:[[:space:]]*//; s/[[:space:]]*$//')"
  case "$v" in
    github|gitlab) printf '%s\n' "$v" ;;
    local)  echo "receipt: the receipt helper does not support local mode; claim and done enforcement are absent there" >&2; exit 2 ;;
    "")    echo "receipt: no tracker: key in $PTR; the loop-setup skill writes that file" >&2; exit 3 ;;
    *)     fail "unknown tracker mode '$v' in $PTR (expected github or gitlab)" ;;
  esac
}

gh_guard() {             # fail-fast: covers gh-absent AND unauthenticated
  command -v gh >/dev/null 2>&1 || fail "github mode requires the gh CLI, which is not on PATH"
  gh auth status >/dev/null 2>&1 || fail "github mode requires an authenticated gh CLI (run: gh auth login)"
}

# --- gitlab backend helpers ---
gitlab_host() {          # prints the host of origin; nothing + non-zero when origin is absent
  local url
  url="$(git remote get-url origin 2>/dev/null)" || return 1
  [ -n "$url" ] || return 1
  printf '%s\n' "$url" | sed -E 's#^[a-z+]+://##; s#^[^@]*@##; s#[:/].*$##'
}
glab_guard() {           # fail-fast: host-scoped auth check (never bare `glab auth status`)
  local host
  command -v glab >/dev/null 2>&1 || fail "gitlab mode requires the glab CLI, which is not on PATH"
  host="$(gitlab_host)" || fail "gitlab mode requires an origin remote to resolve the GitLab host (found none)"
  glab auth status --hostname "$host" >/dev/null 2>&1 \
    || fail "gitlab mode requires glab authenticated to $host (run: glab auth login --hostname $host)"
}

# --- cross-backend dispatch helpers ---
label_missing() {        # args: name captured-stderr - a failed add that names a missing label
  if printf '%s' "$2" | grep -qiF "$1" && printf '%s' "$2" | grep -qiE 'not found|not exist|no such label'; then
    printf 'label `%s` does not exist in this repo; the loop-setup skill provisions the `agent:` label set, run it against this repo first\n' "$1" >&2
    exit 1
  fi
  fail "add label '$1' failed: $2"
}
do_label() {             # args: num name add|remove - raw op; the agent:done guard lives in the done verb
  local num="$1" name="$2" err
  if [ "$MODE" = github ]; then gh_guard
    if [ "$3" = add ]; then err="$(gh issue edit "$num" --add-label "$name" 2>&1)" || label_missing "$name" "$err"
    else gh issue edit "$num" --remove-label "$name" >/dev/null; fi
  else glab_guard
    if [ "$3" = add ]; then err="$(glab issue update "$num" --label "$name" 2>&1)" || label_missing "$name" "$err"
    else glab issue update "$num" --unlabel "$name" >/dev/null; fi
  fi
}
do_comment() {           # args: num text
  if [ "$MODE" = github ]; then gh_guard; gh issue comment "$1" --body "$2" >/dev/null
  else glab_guard; glab issue note "$1" --message "$2" >/dev/null; fi
}
do_state() {             # args: num close|reopen
  if [ "$MODE" = github ]; then gh_guard; gh issue "$2" "$1" >/dev/null
  else glab_guard; glab issue "$2" "$1" >/dev/null; fi
}
set_status() {           # args: num state - siblings removed BEFORE the add, so exactly one is active
  clear_status "$1" "$2"
  do_label "$1" "agent:$2" add
}
clear_status() {         # args: num [keep] - remove every agent: status label except `keep`
  local keep="${2:-}" s
  for s in todo working needs-input review; do
    [ "$s" = "$keep" ] && continue
    # blind remove: safe without a current-labels fetch (an absent label is the common case)
    do_label "$1" "agent:$s" remove || true
  done
}
gather_receipts() {      # arg: num - prints canonical "AGENT CLAIMED|RECLAIMED <sid> <ts>" lines,
                        # line-anchored so a receipt merely quoting the phrase is not counted
  if [ "$MODE" = github ]; then gh_guard; gh issue view "$1" --json comments -q '.comments[].body' \
      | grep -E '^AGENT (CLAIMED|RECLAIMED) [^ ]+ [^ ]+$'
  else glab_guard; glab issue view "$1" --comments 2>/dev/null \
      | grep -E '^AGENT (CLAIMED|RECLAIMED) [^ ]+ [^ ]+$'; fi
}
compute_owner() {        # stdin: canonical receipt lines -> owner sid; active window at or after
  awk '                  # the most recent RECLAIMED (else all); earliest ts, ties lex-least sid
    { sid[NR]=$3; ts[NR]=$4; if ($2 == "RECLAIMED") last = NR }
    END { if (NR == 0) exit 0
      for (i = (last ? last : 1); i <= NR; i++)
        if (bs == "" || ts[i] < bt || (ts[i] == bt && sid[i] < bs)) { bt = ts[i]; bs = sid[i] }
      print bs }'
}
fetch_body() {           # arg: num -> only that issue's body (the blocker scan is candidate-scoped)
  if [ "$MODE" = github ]; then gh_guard; gh issue view "$1" --json body -q .body
  else glab_guard; glab issue view "$1"; fi
}
do_list() {              # prints "<num><TAB><labels>" rows for open issues; ONE snapshot per run
  if [ "$MODE" = github ]; then gh_guard; gh issue list --state open --limit 1000 --json number,labels \
      -q '.[] | "\(.number)\t\([.labels[].name] | join(","))"'
  else glab_guard; glab issue list --all --output json --per-page 100 \
      | jq -r '.[] | "\(.iid)\t\([.labels[]] | join(","))"'; fi
}
next_eligible() {        # arg: optional session-id; prints one SELECTED/NONE ELIGIBLE line, always rc 0
  local sid="${1:-}" num labels rts newest owner blines blocked m cutoff rows
  local open_ids="," work_nums="" todo_nums="" total=0 nw=0 nt=0 nblk=0
  # STALE_CLAIM_SECS is a wall-clock heuristic for auto-resurfacing a dead session's
  # ticket; explicit 'claim --reclaim' is the operator's zero-wait override. Receipt
  # timestamps share the fixed %Y-%m-%dT%H:%M:%SZ shape, so a lexical compare against
  # a pre-rendered cutoff string equals the epoch compare.
  cutoff="$(date -u -r "$(( $(date +%s) - ${STALE_CLAIM_SECS:-3600} ))" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" \
    || cutoff="$(date -u -d "@$(( $(date +%s) - ${STALE_CLAIM_SECS:-3600} ))" +%Y-%m-%dT%H:%M:%SZ)"
  rows="$(do_list | sort -t$'\t' -k1,1n)"
  while IFS=$'\t' read -r num labels; do
    [ -n "$num" ] || continue
    total=$((total + 1)); open_ids="$open_ids$num,"
    case ",$labels," in *",agent:working,"*) work_nums="$work_nums$num "; nw=$((nw + 1)) ;; esac
    case ",$labels," in *",agent:todo,"*)    todo_nums="$todo_nums$num " ;; esac
  done <<< "$rows"
  # lane 1 - stale working: newest claim/reclaim receipt past the cutoff, owned by another session
  for num in $work_nums; do
    rts="$(gather_receipts "$num" 2>/dev/null || true)"
    [ -n "$rts" ] || continue    # receiptless working ticket: age unknowable, not judgeable as stale
    newest="$(printf '%s\n' "$rts" | awk '{print $4}' | sort | tail -1)"
    [ "$newest" \< "$cutoff" ] || continue
    owner="$(printf '%s\n' "$rts" | compute_owner)"
    if [ -z "$sid" ] || [ "$owner" != "$sid" ]; then printf 'SELECTED #%s: stale working, relaunch\n' "$num"; return 0; fi
  done
  # lane 2 - lowest open agent:todo, not working, blocked by no OPEN issue
  for num in $todo_nums; do
    case " $work_nums " in *" $num "*) continue ;; esac
    nt=$((nt + 1))
    blines="$(fetch_body "$num" 2>/dev/null | grep -E '^Blocked by:' || true)"   # anchored: quoted mentions cannot block
    blocked=0
    for m in $(printf '%s\n' "$blines" | grep -oE '#[0-9]+' | sed 's/#//'); do
      case "$open_ids" in *",$m,"*) blocked=1; break ;; esac     # unresolved iff still in the open set
    done
    [ "$blocked" -eq 1 ] && { nblk=$((nblk + 1)); continue; }
    printf 'SELECTED #%s: agent:todo, unblocked\n' "$num"
    return 0
  done
  printf 'NONE ELIGIBLE: %d open, %d agent:working, %d of %d agent:todo blocked\n' "$total" "$nw" "$nblk" "$nt"
  return 0
}

usage() {
  cat >&2 <<EOF
Usage: bash scripts/receipt.sh <verb> [args]   (tracker mode read from docs/loop/pointer.md)
  status <num> <todo|working|needs-input|review>  set exactly one agent: status ('done' routes through 'done')
  claim <num> <session-id> [--reclaim]            receipt-before-flip; prints owner; exit 4 on lost race
  done <num> --receipt <text> [--ran <cmd>]       exit 5 without evidence, exit 7 on failed --ran (routes to review)
  next-eligible [<session-id>]                    print the one actionable ticket (always exit 0)
EOF
}

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ $# -ge 1 ] || { usage >&2; exit 1; }
MODE="$(mode_read)" || exit $?
[ "$MODE" = gitlab ] && { command -v jq >/dev/null 2>&1 || fail "gitlab mode requires jq on PATH (issue-list parsing)"; }

sub="$1"; shift
case "$sub" in
  status)
    [ $# -ge 2 ] || fail "status: requires an issue number and a state (todo|working|needs-input|review)"
    case "$2" in todo|working|needs-input|review) ;; *) fail "status: state must be todo|working|needs-input|review (got '$2'; 'done' routes through 'receipt.sh done')" ;; esac
    set_status "$1" "$2"
    ;;
  claim)
    [ $# -ge 2 ] || fail "claim: requires an issue number and a session id"
    num="$1"; sid="$2"; shift 2; reclaim=0
    while [ $# -ge 1 ]; do case "$1" in --reclaim) reclaim=1; shift ;; *) fail "claim: unknown argument '$1'" ;; esac; done
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    verb=CLAIMED; [ "$reclaim" -eq 1 ] && verb=RECLAIMED
    # receipt BEFORE flip: a mid-claim death never leaves a receiptless working ticket
    do_comment "$num" "AGENT $verb $sid $now"
    set_status "$num" working
    owner="$(gather_receipts "$num" | compute_owner)"
    if [ -z "$owner" ] || [ "$owner" = "$sid" ] || [ "$reclaim" -eq 1 ]; then
      printf '%s\n' "$sid"
    else
      echo "RACE: #$num owned by $owner" >&2; exit 4
    fi
    ;;
  done)
    [ $# -ge 2 ] || fail "done: requires an issue number and --receipt <text>"
    num="$1"; shift; receipt=""; rancmd=""
    while [ $# -ge 2 ]; do
      case "$1" in
        --receipt) receipt="$2"; shift 2 ;;
        --ran)     rancmd="$2";  shift 2 ;;
        *) fail "done: unknown argument '$1'" ;;
      esac
    done
    [ $# -eq 0 ] || fail "done: unpaired arguments"
    [ -n "$receipt" ] || fail "done: --receipt is required"
    if [ -n "$rancmd" ]; then
      # strong path: re-execute the cited command and capture the REAL exit, not a pasted claim
      sh -c "$rancmd" >/dev/null 2>&1
      rc=$?
      receipt="$receipt --ran $rancmd exit $rc"
      if [ "$rc" -ne 0 ]; then
        do_comment "$num" "$receipt"
        set_status "$num" review
        echo "receipt: --ran command exited $rc; #$num routed to review, not done" >&2
        exit 7
      fi
    elif ! printf '%s\n' "$receipt" | grep -qE '(exit( status)? 0( |$)|[1-9][0-9]* passed|(^| )0 failed|https?://[^ ]+)'; then
      # without --ran the receipt must CITE a passing run; --ran remains the strong path
      echo "agent:done requires executed-check evidence of a PASSING run (exit 0 / N passed / 0 failed / artifact link)" >&2
      exit 5
    fi
    do_comment "$num" "$receipt"
    clear_status "$num"   # 'done' is not a status verb: clear the four siblings, then the evidence-gated add
    do_label "$num" agent:done add
    do_state "$num" close
    ;;
  next-eligible)
    next_eligible "${1:-}"
    ;;
  *) usage; exit 1 ;;
esac

# Every verb's stdout is a machine surface (owner sid, SELECTED lines) that callers
# capture, so the house-style PASS: line goes to stderr and cannot corrupt a capture.
echo "PASS: $sub" >&2
