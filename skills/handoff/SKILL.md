---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

This skill is user-invoked only: `disable-model-invocation` is set, so it never auto-selects itself and runs only when the human calls it.
Its `argument-hint` asks "What will the next session be used for?", and that answer shapes the handoff's emphasis.

Decide where it lands based on the repo the session is working in.
If `docs/loop/pointer.md` exists at the repo root, this is a conforming repo: read its `handoffs-home:` key (default `docs/handoffs/`) and write the handoff to `<handoffs-home>/YYYY-MM-DD.<tokens>.<slug>.md`.
Otherwise this is a non-conforming repo: create `docs/handoffs/` inside the project on demand and write the handoff to `docs/handoffs/YYYY-MM-DD.<tokens>.<slug>.md` there, never outside the project.
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.
Include a "## Next actions" section listing one next action per "- " line; that list is what handoff consumption dispositions index into.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.
