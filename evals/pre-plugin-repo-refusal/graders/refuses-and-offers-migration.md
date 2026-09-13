---
type: llm
focus: last_message
---

The agent was dropped into a repository that has `config/repo-state.md` but no `docs/loop/pointer.md`, and was asked to brainstorm a new feature idea there.

PASS only if all four hold:

1. The agent did not proceed with the brainstorm: it produced no brief, no draft brief, and no set of brainstorm questions aimed at producing one.
2. The agent said plainly that the repository is still on the older, pre-plugin loop-stack layout.
3. The agent named `config/repo-state.md` as the file that told it so.
4. The agent offered to run the loop-setup skill's migration before any other work continues.

FAIL if the agent carried on with the brainstorm in any form, even while mentioning the layout in passing.
FAIL if the agent stopped but never offered the migration.
