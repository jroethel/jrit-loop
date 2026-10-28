#!/usr/bin/env bash
# Unit gate: the check nodes of one unit in the generated drive graph, from
# the run worktree, with the base branch handed in as CEZ_BASE.
#   unit-gate.sh <task id>         gate unit <id>: its check, custody, ownership,
#                                  shared tests, the full suite; moves nothing
#   unit-gate.sh landed <task id>  after a passing validator: record the head
#   unit-gate.sh custody           the custody diff alone (stage-gate.sh drive)
# State lives in refs/jrit/I<n>/, shared by every worktree (D23); the plan is
# read from the tests commit, so a unit cannot change its own check (D28).
set -uo pipefail
TOOL=".ai/jrit/plan_tool.py"

fail() { echo "unit gate: $1"; exit 1; }
usage() { echo "usage: unit-gate.sh <task id> | landed <task id> | custody"; exit 2; }
case "${1:-}" in
landed) [ -n "${2:-}" ] || usage ;;
"" | -*) usage ;;
esac
. ./.ai/jrit/kit-lib.sh || fail "cannot load .ai/jrit/kit-lib.sh; restamp the chain kit"

issue="$(git rev-parse --git-path jrit-chain-issue)"
[ -f "$issue" ] || fail "no jrit-chain-issue; preflight did not run in this worktree"
n="$(cat "$issue")"
TESTS="refs/jrit/I$n/tests"
UNIT_HEAD="refs/jrit/I$n/unit-head"

if [ "$1" = landed ]; then
    git update-ref "$UNIT_HEAD" HEAD || exit 1
    git branch -f "jrit/chain-I$n" HEAD || exit 1
    echo "Landed unit $2 at $(git rev-parse HEAD | cut -c1-12)"
    exit 0
fi

git rev-parse -q --verify "$TESTS^{commit}" >/dev/null || fail "no tests commit; stage-tests.sh did not run"
if [ "$1" != custody ]; then
    dirty="$(git status --porcelain | cut -c4- | paste -s -d ' ' -)"
    [ -z "$dirty" ] || fail "uncommitted changes: $dirty"
fi
plan="$(python3 "$TOOL" find-plan ${CEZ_BASE:+--base "$CEZ_BASE"})" || fail "$plan"
copy="$(mktemp)"
trap 'rm -f "$copy"' EXIT
git show "$TESTS:$plan" >"$copy" 2>/dev/null || fail "$plan is not in the tests commit $(git rev-parse "$TESTS" | cut -c1-12)"

# q tests|shared: the plan copy's Test: and shared test paths, or only the
# shared ones; q later <id>: the Test: paths of the units after <id> in run
# order, less any of <id>, of a unit before it, or shared; q owner <id> <prev>: every path changed since <prev> that is
# outside the unit's Files bullets and the plan, review, and handoff homes.
q() {
    python3 - "$@" "$copy" <<'PY'
import sys
sys.dont_write_bytecode = True
sys.path.insert(0, ".ai/jrit")
import plan_tool as t
from plan_lint import analyze, blocks, files_of, run_order, section, SHARED_RE

what, plan = sys.argv[1], sys.argv[-1]
lines, inside, tasks = analyze(t.read_file(plan))
sec = section(lines, inside, SHARED_RE)
shared = [p for i, p, _, _ in blocks(lines, inside)
          if sec and sec[0] < i < sec[1]]
if what == "shared":
    for p in shared:
        print(p)
elif what == "tests":
    for p in dict.fromkeys([p for task in tasks
                            for p in files_of(task)["test"]] + shared):
        print(p)
elif what == "later":
    order = run_order(tasks)
    at = next((i for i, x in enumerate(order) if x["id"] == sys.argv[2]), None)
    if at is None:
        print("no Task {}".format(sys.argv[2]))
        sys.exit(2)
    keep = {p for x in order[:at + 1] for p in files_of(x)["test"]} | set(shared)
    for p in dict.fromkeys(p for x in order[at + 1:] for p in files_of(x)["test"]):
        if p not in keep:
            print(p)
else:
    tid, prev = sys.argv[2], sys.argv[3]
    task = next((x for x in tasks if x["id"] == tid), None)
    if task is None:
        print("no Task {}".format(tid))
        sys.exit(2)
    top = t.git_out(["rev-parse", "--show-toplevel"]).strip()
    entries = ["docs/plans/", t.pointer_home("reviews-home", "docs/reviews/"),
               t.pointer_home("handoffs-home", "docs/handoffs/")]
    entries += [e for b in task["bullets"] for s in t.SPAN_RE.findall(b)
                for e in [t.owned_path(s, top)] if e]
    bad = 0
    for path in t.git_out(["diff", "--name-only", prev, "HEAD"]).splitlines():
        if path.startswith((".ai/", "docs/loop/")):
            print("outside unit {}: {} {}".format(tid, path, t.NEVER_OWNED_MSG))
            bad += 1
        elif not any(t.allowed(path, e) for e in entries):
            print("outside unit {}: {}".format(tid, path))
            bad += 1
    sys.exit(1 if bad else 0)
PY
}

custody() {
    out="$(q tests)" || exit 1
    specs=(":(literal)$plan")
    while IFS= read -r p; do [ -n "$p" ] && specs+=(":(literal)$p"); done <<<"$out"
    changed="$(git -c core.quotePath=false diff --name-only "$TESTS" -- "${specs[@]}")" || exit 1
    [ -z "$changed" ] && return 0
    printf '%s\n' "$changed" | sed 's/.*/custody: & differs from the tests commit/'
    exit 1
}

if [ "$1" = custody ]; then
    custody
    echo "custody: ok"
    exit 0
fi
id="$1"

# (1) the unit's acceptance check, from the committed plan
python3 "$TOOL" run-checks "$copy" --task "$id" || exit 1
# (2) custody: no committed test and not the plan changed
custody
# (3) ownership of everything since the last landed unit
prev="$UNIT_HEAD"
git rev-parse -q --verify "$prev" >/dev/null || prev="$TESTS"
q owner "$id" "$prev" || exit 1
# (4) shared tests, run directly
out="$(q shared)" || exit 1
shared=()
while IFS= read -r p; do [ -n "$p" ] && shared+=("$p"); done <<<"$out"
for p in ${shared[@]+"${shared[@]}"}; do
    case "$p" in *.py) run=python3 ;; *) run=bash ;; esac
    out="$("$run" "$p" 2>&1)" || {
        echo "shared test failed: $p"
        printf '%s\n' "$out" | tail -n 40
        exit 1
    }
done
# (5) the full suite
CI_COMMAND=""
[ -f .ai/jrit/kit.conf ] && . ./.ai/jrit/kit.conf
if [ -z "${CI_COMMAND:-}" ]; then
    echo "note: CI_COMMAND is empty in .ai/jrit/kit.conf; no full suite run"
else
    # Later units' committed tests are red until they land: run the suite in
    # a throwaway worktree of HEAD with each one reset to the tests commit's
    # parent, or removed when it is new there.
    out="$(q later "$id")" || fail "$out"
    later=()
    while IFS= read -r p; do [ -n "$p" ] && later+=("$p"); done <<<"$out"
    run="."
    if [ "${#later[@]}" -gt 0 ]; then
        echo "full suite: holding back ${#later[@]} later test(s)"
        run="$(mktemp -d)" || exit 1
        trap 'rm -f "$copy"; git worktree remove --force "$run" >/dev/null 2>&1; rm -rf "$run"' EXIT
        trap 'exit 1' HUP INT TERM
        git worktree add -q --detach "$run" HEAD || fail "cannot add a throwaway worktree"
        for p in "${later[@]}"; do
            if git cat-file -e "$TESTS^:$p" 2>/dev/null; then
                git -C "$run" checkout -q "$TESTS^" -- ":(literal)$p"
            else
                git -C "$run" rm -q -f --ignore-unmatch -- ":(literal)$p"
            fi || fail "cannot hold back $p"
        done
        git -C "$run" -c user.name=unit-gate -c user.email=unit-gate@localhost -c commit.gpgsign=false \
            commit -q --no-verify --allow-empty -m "unit gate: held back" || fail "cannot commit the held-back tree"
    fi
    out="$(cd "$run" && bash -c "$CI_COMMAND" 2>&1)" || {
        echo "unit gate: full suite failed ($CI_COMMAND)"
        printf '%s\n' "$out" | tail -n 150
        exit 1
    }
fi
echo "Head: $(git rev-parse HEAD)"
echo "PASS unit $id"
