#!/usr/bin/env bash
# tests/dispatched-channel.sh - static proof that the dispatched-session question
# channel has one home in loop-auto and a byte-identical pointer in the five
# skills that ask. The behavioural half is the two plan-* eval cases.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"

# T is the detection test; loop-auto holds the copy of record and every pointer
# carries it byte for byte, so an interactive run never has to read loop-auto.
T=$(cat <<'TEST'
m="$(git rev-parse --path-format=absolute --git-path jrit-loop-dispatched 2>/dev/null)" && test -f "$m" && b="$(git branch --show-current)" && test -n "$b" && test "$(cat "$m")" = "$b"
TEST
)

A=skills/loop-auto/SKILL.md
grep -qxF '### Dispatched sessions' "$A" || fail "$A lacks the '### Dispatched sessions' heading"
grep -qxF -- "$T" "$A" || fail "$A lacks the detection test as its own line"
while IFS= read -r s; do
  grep -qF -- "$s" "$A" || fail "$A lacks: $s"
done <<'LINES'
The host writes the name of the session's current branch into the marker, and a marker whose content differs from the current branch counts as absent.
When the test exits nonzero, the skill asks exactly as it always has and prints nothing about the test.
When it exits 0, print exactly `question channel: dispatched (marker present)` once, in the same reply as the first round.
With the marker absent, every skill behaves exactly as it does without this section.
Dispatched changes the channel, never the class: an ASK still blocks until it is answered, and a STOP still halts and states what it needs.
LINES
grep -qiF 'presence-only' "$A" && fail "$A still calls the marker presence-only"
grep -qF 'question channel: interactive' "$A" && fail "$A still prints a channel line on the interactive path"
n=$(cat skills/*/SKILL.md | grep -cxF '### Dispatched sessions')
[ "$n" = 1 ] || fail "the Dispatched sessions section must have exactly one home (found $n)"

# The section names no host and emits no host grammar.
sect=$(awk '/^### Dispatched sessions$/ { on = 1; next } on && /^##/ { exit } on' "$A")
for t in firstmate 'first mate' needs-decision 'status file'; do
  printf '%s\n' "$sect" | grep -qiF -- "$t" && fail "the Dispatched sessions section names host grammar: $t"
done

P1='**Dispatched sessions.** Before the first ask or wait for a human in this skill, run `'"$T"'`.'
P2='On any nonzero exit, ask exactly as this skill says and print nothing about the test.'
P3='On exit 0, follow the loop-auto skill'"'"'s "Dispatched sessions" section for every ask in this run.'
for name in loop-brainstorm loop-plan loop-improve loop-review loop-drive; do
  f="skills/$name/SKILL.md"
  for p in "$P1" "$P2" "$P3"; do
    [ "$(grep -cxF -- "$p" "$f")" = 1 ] || fail "$f does not carry this dispatched-sessions pointer line exactly once: $p"
  done
  [ "$(grep -A2 -xF -- "$P1" "$f" | tail -n 2)" = "$(printf '%s\n%s' "$P2" "$P3")" ] || fail "$f does not keep the three pointer lines together and in order"
done
grep -qF AskUserQuestion skills/loop-drive/SKILL.md && fail "skills/loop-drive/SKILL.md names AskUserQuestion; the core stays host-neutral"

for c in plan-dispatched-no-modal plan-interactive-unchanged; do
  grep -qxF '## Expected behavior' "evals/$c/prompt.md" || fail "evals/$c/prompt.md lacks its ## Expected behavior section"
  grep -qF AskUserQuestion "evals/$c/prompt.md" || fail "evals/$c/prompt.md does not allow AskUserQuestion"
done
grep -qF 'git branch --show-current > "$(git rev-parse --path-format=absolute --git-path jrit-loop-dispatched)"' evals/plan-dispatched-no-modal/prompt.md || fail "the dispatched fixture does not write the branch into the marker"
echo "PASS: dispatched channel wired in loop-auto and 5 skills"
