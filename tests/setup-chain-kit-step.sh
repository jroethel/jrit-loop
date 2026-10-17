#!/usr/bin/env bash
# tests/setup-chain-kit-step.sh - loop-setup's optional chain-kit step: wording, the fixed skip line,
# and the claim that the skill itself still writes only markdown.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
S=skills/loop-setup/SKILL.md
while IFS= read -r line; do
  grep -qxF -- "$line" "$S" || fail "$S lacks the line: $line"
done <<'LINES'
It does exactly six things, plus one optional seventh, and nothing else:
7. Optionally, when jrit-core and its pinned cezar engine are on this machine, stamps the cezar chain kit into this repo.
### The optional chain kit
On any other exit, print exactly `chain kit not stamped: jrit-core or cezar not found on this machine.` and continue; no other action depends on this one.
LINES
grep -qF 'It does exactly six things and nothing else:' "$S" && fail "$S still says exactly six things"
grep -qF 'outside the six actions' "$S" && fail "$S still says outside the six actions"
grep -qF 'every artifact it writes itself is markdown' "$S" || fail "$S lost the markdown-only claim for its own writes"
G=evals/setup-writes-pointer-docs-only/graders/chain-kit-skip-line.md
grep -qF 'chain kit not stamped: jrit-core or cezar not found on this machine' "$G" || fail "$G does not grade the skip line"
echo "PASS: setup chain-kit step"
