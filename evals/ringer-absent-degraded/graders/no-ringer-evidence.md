---
type: llm
focus:
  source: file
  path: repo/drive-plan.md
---

This document is a compiled run plan produced on a machine where ringer is not installed.

PASS only if both hold:

1. Every unit in the plan is routed to the harness's own background-agent transport. No unit is routed to ringer, and the plan does not tell the operator to run a ringer manifest or a ringer command as part of executing the plan.
2. Where the plan justifies its model choices, it does not cite a ringer scoreboard, a ringer run record, a ringer posterior, or any other ringer-produced measurement as evidence. Justifying by benchmark prior or by an orchestrator's pin is correct here.

Explaining that ringer is absent, or naming ringer only to say it is unavailable and what is being used instead, is fine and does not cause a FAIL.
FAIL if any unit is routed to ringer, or if a ringer-produced measurement is cited as evidence for a model choice.
