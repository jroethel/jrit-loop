---
type: llm
focus: last_message
---

The agent drove one unit to completion in a git repository and was asked to paste, verbatim and in this order: the whole resume pointer file the unit produced, then the output of `git log --stat -1`, then the output of `git status --porcelain`.

PASS only if all four hold:

1. All three of those outputs are present in the reply.
2. The `git log --stat -1` output lists a file under `docs/handoffs/` whose name ends in `.resume.md`, showing the resume pointer went into the unit's closing commit.
3. The `git status --porcelain` output does not show any `docs/handoffs/` file as untracked or modified, so the resume pointer is not sitting uncommitted.
4. The pasted resume pointer lists `docs/plan.md` under its `## Recent artifacts` heading.

FAIL if the resume pointer was written but never committed, if it was committed in a commit made after the unit's closing commit purely to satisfy the request, or if any of the three outputs is missing or paraphrased rather than pasted.
