---
type: llm
focus: trace
---

The agent was asked to plan from a brief with one open planning question, in a session with no dispatch marker.

PASS only if the trace shows the agent attempting to put that planning question to the user through the AskUserQuestion tool, whether or not the runner let the call complete.

FAIL if the agent printed the question only as plain text and never attempted the tool.
