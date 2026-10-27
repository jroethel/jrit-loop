#!/usr/bin/env bash
# tests/plan-review-wiring.sh - static proof that the optional plan review pause
# is wired: a Step 3 in loop-plan gated by the plan-review pointer key, the
# section contract and the plain template beside it, the key in loop-setup's
# pointer template, and every outside reference to loop-plan's renumbered steps.
# The behavioural half is the plan-review-on-stops eval case.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"

P=skills/loop-plan/SKILL.md
grep -qxF '## Step 4 - The plan review (optional)`[gate:ASK]`' "$P" || fail "$P lacks the Step 4 plan review heading with its ASK gate tag"
for s in 'Read `plan-review` from `docs/loop/pointer.md` (default `ask` when the key is absent).' \
         'references/plan-review.md' 'references/plan-review-template.html' \
         '**Plan review:** path of the plan review record' \
         'and the plan review record when one exists'; do
  grep -qF -- "$s" "$P" || fail "$P lacks: $s"
done
for n in 4 5 6 7 8 9; do grep -qE "^## Step $n - " "$P" || fail "$P has no Step $n heading after the renumbering"; done
[ "$(grep -c '^## Step ' "$P")" = 9 ] || fail "$P should carry exactly nine Step headings"
grep -qF 'Decline means proceed to Step 5' "$P" || fail "$P: the plan review decline must route to Step 5"
grep -qF 'Decline means proceed to Step 3' "$P" || fail "$P: the Rubix decline must route to Step 3"
grep -qF 'Want the Rubix review?' "$P" || fail "$P lost the pinned Rubix offer sentence that evals/rubix-present-offer/graders/one-rubix-offer.md counts"
grep -qF 'offer the review once, as its own message, after the skeleton is written, in exactly these words:' "$P" || fail "$P lost the word-for-word pin on the Rubix offer"

for f in skills/loop-plan/references/plan-review.md skills/loop-plan/references/plan-review-template.html; do
  [ -f "$f" ] || fail "$f is missing"
done
R=skills/loop-plan/references/plan-review.md
for h in 'Where the changes land' 'Decision log' 'Open decisions' 'What the shape assumes' 'The parking lot' 'Question-round timeline' 'What happens next' 'Review rounds'; do
  grep -qF -- "$h" "$R" || fail "$R does not name the section: $h"
done
grep -qF 'verdict: approved | changes' "$R" || fail "$R lacks the answers block verdict line"
T=skills/loop-plan/references/plan-review-template.html
grep -qF 'id="copy"' "$T" || fail "$T lacks the copy-answers button"
grep -qF 'name="verdict"' "$T" || fail "$T lacks the verdict control"
grep -qE '<(script|link)[^>]+(src|href)="https?://' "$T" && fail "$T fetches something from the network; the page must be self-contained"
grep -qF 'prefers-color-scheme: dark' "$T" || fail "$T has no dark scheme"

grep -qxF 'plan-review: <ask|off|on>' skills/loop-setup/references/pointer-templates.md || fail "pointer template lacks the plan-review key"
grep -qF 'plan-review-brand: <slug>' skills/loop-setup/references/pointer-templates.md || fail "pointer template does not document plan-review-brand"
grep -qxF 'plan-review: ask' docs/loop/pointer.md || fail "this repo's pointer lacks plan-review: ask"

grep -qF 'loop-plan Step 2:' skills/loop-brainstorm/SKILL.md || fail "loop-brainstorm still points at the old Rubix step number"
grep -qF 'loop-plan, Steps 5-6' skills/loop-drive/references/model-benchmarks.md || fail "model-benchmarks still pins plan-draft to the old step numbers"
grep -qF 'Step 2 takes its present branch' evals/rubix-present-offer/prompt.md || fail "rubix-present-offer still names the old Rubix step number"
for c in rubix-present-offer rubix-absent-callout; do
  grep -qF 'plan-review: off' "evals/$c/prompt.md" || fail "evals/$c does not turn the plan review off, so its Rubix offer is no longer the only offer"
done
grep -qxF '## Expected behavior' evals/plan-review-on-stops/prompt.md || fail "evals/plan-review-on-stops/prompt.md lacks its ## Expected behavior section"
echo "PASS: plan review wired in loop-plan, loop-setup, and the evals"
