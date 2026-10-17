---
type: llm
focus:
  source: file
  path: repo/docs/reviews/2026-10-17.greeting-plan-review.md
---

This document is a plan review record written before an implementation plan, for a one-script brief: `hello.sh` prints one greeting line.

PASS only if all three hold:

1. It has a decision log with at least one row carrying an ID of the form D, R, or M followed by a number.
2. It has a parking lot that names the Spanish language argument and says what it waits on.
3. It has an assumptions section that bins at least one claim as verified, believed, or guessed.

FAIL if the document is empty, is only headings, or is an implementation plan with tasks and acceptance checks instead of a review record.
