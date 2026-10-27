#!/usr/bin/env bash
# Stage drive: the check nodes around the generated drive graph, run from the
# run worktree (Refs #94).
#   stage-drive.sh compile     lint the plan, compile it into
#                              <root>/.ai/cezar/workflows/jrit-drive.I<n>.<id8>.yaml,
#                              and require the cockpit to parse, validate, and list it
#   stage-drive.sh start       start that workflow as its own run, once per chain run (D27)
#   stage-drive.sh card        the drive card text before unit 1 (D4, D25)
#   stage-drive.sh human <id>  the gate message of a human-shaped task (D18)
#   stage-drive.sh cleanup     delete this run's generated workflow file (D9); exits 0
# <root> is the parent of the git common dir, where cezar loads workflows (D1).
set -uo pipefail

fail() { echo "stage-drive: $1"; exit 1; }
usage() { echo "usage: stage-drive.sh compile | start | card | human <task id> | cleanup"; exit 2; }
case "${1:-}" in
compile | start | card | cleanup) ;;
human) [ -n "${2:-}" ] || usage ;;
*) usage ;;
esac
. ./.ai/jrit/kit-lib.sh || fail "cannot load .ai/jrit/kit-lib.sh; restamp the chain kit"

need_api() {
  for v in CEZ_API_URL CEZ_PROJECT_ID CEZ_RUN_ID; do
    [ -n "${!v:-}" ] || fail "$v is not set; run this as a cezar check node"
  done
  API="$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID"
}
common="$(git rev-parse --path-format=absolute --git-common-dir)" || exit 1
root="${common%/*}"

if [ "$1" = cleanup ]; then
  wf=""
  if [ -n "${CEZ_API_URL:-}" ] && [ -n "${CEZ_PROJECT_ID:-}" ] && [ -n "${CEZ_RUN_ID:-}" ]; then
    wf="$(curl -sf --max-time 15 "$CEZ_API_URL/api/v1/p/$CEZ_PROJECT_ID/runs/$CEZ_RUN_ID" | jq -r '.workflow // ""' 2>/dev/null)"
  fi
  file="$root/.ai/cezar/workflows/$wf.yaml"
  case "$wf" in
  jrit-drive.*)
    if [ -f "$file" ] && rm -f "$file"; then
      echo "cleanup: removed $file"
      exit 0
    fi
    ;;
  esac
  echo "cleanup: nothing to remove"
  exit 0
fi

issue="$(git rev-parse --git-path jrit-chain-issue)"
[ -f "$issue" ] || fail "no jrit-chain-issue; preflight did not run in this worktree"
n="$(cat "$issue")"
plan="$(python3 .ai/jrit/plan_tool.py find-plan ${CEZ_BASE:+--base "$CEZ_BASE"})" || fail "$plan"

# py <verb> [args]: card lines or a human gate message, from the plan's parse.
py() {
  python3 - "$plan" "$@" <<'PY'
import fnmatch, re, sys
sys.dont_write_bytecode = True
sys.path.insert(0, ".ai/jrit")
from plan_lint import analyze, files_of, read_file, section, units

plan, verb = sys.argv[1], sys.argv[2]
text = read_file(plan)
if verb == "human":
    t = next((u for u in units(text) if u["id"] == sys.argv[3]), None)
    if t is None or t["shape"] != "human":
        print("stage-drive: Task {} is not a human-shaped task of {}".format(sys.argv[3], plan))
        sys.exit(1)
    print("Task {} is human-shaped: {}. Do it on this branch, then approve; "
          "reject ends the run.".format(t["id"], t["shape_why"]))
    sys.exit(0)
lines, inside, tasks = analyze(text)
staged = []
span = section(lines, inside, re.compile(r"^##\s+Human checkpoints\s*$"))
if span:
    staged = [lines[j][2:].strip() for j in range(span[0] + 1, span[1])
              if not inside[j] and lines[j].startswith("- ")
              and "before unit 1" in lines[j]]
risks = []
for glob in sys.argv[3].split():
    for t in tasks:
        f = files_of(t)
        for p in dict.fromkeys(f["create"] + f["modify"] + f["test"]):
            if fnmatch.fnmatch(p, glob):
                risks.append("risk: {} matches Task {}: {}".format(glob, t["id"], p))
if not staged and not risks:
    sys.exit(3)
run = ""
span = section(lines, inside, re.compile(r"^##\s+How to run\s*$"))
if span:
    for j in range(span[0] + 1, span[1]):
        if inside[j] and lines[j].strip() and not lines[j].lstrip().startswith("#"):
            run = lines[j].strip()
            break
print("Start unit 1 of {} with these in place?".format(plan))
for x in staged + risks:
    print(x)
if run:
    print("Run: " + run)
print("Approve starts unit 1; reject ends the run.")
PY
}

case "$1" in
human)
  py human "$2"
  exit $?
  ;;
card)
  ref="refs/jrit/I$n/drive-card"
  if git rev-parse -q --verify "$ref" >/dev/null; then
    echo "No question from drive: already answered"
    exit 0
  fi
  RISK_PATHS=""
  [ -f .ai/jrit/kit.conf ] && . ./.ai/jrit/kit.conf
  out="$(py card "${RISK_PATHS:-}")"
  rc=$?
  if [ "$rc" -eq 3 ]; then
    echo "No question from drive: nothing to stage"
    exit 0
  fi
  [ "$rc" -eq 0 ] || fail "cannot build the card: $out"
  printf '%s\n' "$out"
  git update-ref "$ref" HEAD || exit 1
  exit 0
  ;;
esac

need_api
name="jrit-drive.I$n.$(printf '%s' "$CEZ_RUN_ID" | cut -c1-8)"

if [ "$1" = compile ]; then
  lint="$(python3 .ai/jrit/plan_lint.py lint "$plan")" || { printf '%s\n' "$lint"; fail "plan_lint rejects $plan"; }
  out="$root/.ai/cezar/workflows/$name.yaml"
  python3 .ai/jrit/compile_drive.py "$plan" --issue "$n" --chain "$CEZ_RUN_ID" \
    --template .ai/cezar/workflows/jrit-chain.yaml --routing .ai/jrit/routing.conf --out "$out" 2>&1 \
    || fail "the compile of $plan failed"
  tmp="$(mktemp -d)" || exit 1
  trap 'rm -rf "$tmp"' EXIT
  # Parse then validate, as tests/live/cezar-graph.sh does.
  jq -nc --rawfile y "$out" '{yaml: $y}' >"$tmp/req.json" || fail "cannot build the parse request"
  code="$(curl -s --max-time 30 -o "$tmp/parse.json" -w '%{http_code}' -X POST "$CEZ_API_URL/api/v1/workflows/parse" \
    -H 'content-type: application/json' --data-binary @"$tmp/req.json")"
  case "$code" in 2??) ;; *) fail "parse of $out returned $code: $(head -c 2000 "$tmp/parse.json")" ;; esac
  jq -c '{graph: (if has("graph") then .graph elif has("workflow") then .workflow else . end)}' "$tmp/parse.json" >"$tmp/val-req.json" \
    || fail "cannot read a graph out of the parse response"
  curl -sf --max-time 30 -X POST "$CEZ_API_URL/api/v1/workflows/validate" -H 'content-type: application/json' \
    --data-binary @"$tmp/val-req.json" >"$tmp/validate.json" || fail "POST /api/v1/workflows/validate failed"
  issues="$(jq -c '.issues // []' "$tmp/validate.json")"
  [ "$issues" = "[]" ] || fail "validate reported issues for $name: $issues"
  curl -sf --max-time 30 "$API/workflows" >"$tmp/list.json" || fail "GET $API/workflows failed"
  jq -e --arg n "$name" 'any(.workflows[]?; .name == $n)' "$tmp/list.json" >/dev/null \
    || fail "the cockpit does not list $name; it loads workflows from $root only"
  bad="$(jq -r --arg f "/$name.yaml" '.issues[]? | select(.path | endswith($f)) | .message' "$tmp/list.json")"
  [ -z "$bad" ] || fail "the cockpit reports a load issue for $name: $bad"
  echo "Workflow: $name"
  echo "Units: $(python3 .ai/jrit/plan_lint.py units "$plan" --json | jq length)"
  python3 .ai/jrit/plan_lint.py run-table "$plan"
  exit 0
fi

# start (D27): one generated run per chain run.
runs="$(curl -sf --max-time 30 "$API/runs")" || fail "GET $API/runs failed"
old="$(printf '%s' "$runs" | jq -r --arg c "--chain $CEZ_RUN_ID" \
  '[.[] | select((.task // "") | contains($c)) | select(.status == "queued" or .status == "running" or .status == "waiting") | .id][0] // ""')"
if [ -n "$old" ]; then
  echo "Started: $old (already running)"
  exit 0
fi
brief_file="$(git rev-parse --git-path jrit-chain-brief)"
[ -f "$brief_file" ] || fail "no jrit-chain-brief; preflight did not run in this worktree"
parent="$(curl -sf --max-time 30 "$API/runs/$CEZ_RUN_ID")" || fail "cannot read run $CEZ_RUN_ID"
body="$(jq -nc --arg w "$name" --arg t "$(cat "$brief_file") --from unit=1 --branch $(git branch --show-current) --chain $CEZ_RUN_ID" \
  --argjson a "$(printf '%s' "$parent" | jq '.autonomous // false')" \
  '{workflow: $w, task: $t, autonomous: $a, model: "opus"}')" || fail "cannot build the run request"
resp="$(curl -s --max-time 30 -X POST "$API/runs" -H 'content-type: application/json' --data-binary "$body")" \
  || fail "POST $API/runs failed"
id="$(printf '%s' "$resp" | jq -r '.id // empty' 2>/dev/null)"
[ -n "$id" ] || fail "the cockpit did not start $name: $resp"
echo "Started: $id"
