---
type: llm
focus: last_message
---

This reply hands off an implementation plan in a session where the optional two-lens Rubix review skill IS available.

PASS only if all three hold:

1. The reply offers a Rubix review of the plan it just wrote, and the offer is made exactly once.
2. The offer is put to the reader as a choice to answer, not announced as something already run or about to be run without an answer.
3. The reply does not claim the Rubix review skill is missing, unavailable, or not installed.

FAIL if no offer is made, if the offer is made more than once, or if the reply says the review skill is unavailable.
