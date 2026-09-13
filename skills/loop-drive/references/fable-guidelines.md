# Model-tier and effort guidelines (human-paced mode)

Distilled from Jeremy Roethel's NotebookLM notebook "AI: Claude Fable" (July 2026).
The tier vocabulary, effort defaults, prompt patterns, and pitfalls loop-drive's human-paced output mode leans on.

## The core pattern

Use the frontier model for judgment, not keystrokes: frontier judgment before and after cheap execution, never frontier keystrokes in the middle (the sandwich invariant).

- **Explore (Strong/Fast):** map the repo, summarize architecture, identify test commands, run research, prepare a clean brief. Research does not need frontier reasoning.
- **Plan (Frontier):** feed the brief to the frontier model as architect; design the safest plan, surface hidden coupling and risks, define verification steps.
- **Execute (Strong/Fast):** hand the written plan to implementation agents for mechanical edits, CRUD, boilerplate, test updates.
- **Review (Frontier):** the frontier model reviews the diff for correctness bugs, edge cases, regression risk, missing tests; ship/no-ship.
- **Ship (Human):** final accountability.

## Task routing map (tier vocabulary)

Great Frontier tasks: architecture decisions and reviews, migration planning, large refactor plans, complex bug diagnosis, ambiguous product-to-code translation, repo-wide dependency analysis, test strategy, comparing approaches, orchestration, final PR review.

Waste of Frontier tokens (route to Strong/Fast): tiny syntax fixes, simple CRUD, renames, formatting, boilerplate, routine file search, basic test updates, mechanical implementation of an already-written plan.

Mental model: use the frontier tier where mistakes are expensive.

## Effort dial (high leverage)

Pricing context: Fable 5 is ~2x Opus 4.8 ($10/$50 vs $5/$25 per Mtok); caching gives 90% off input, batch halves it.
DeepSuite long-horizon benchmark: Fable at **low** effort ($3.76/task, 60% pass) beats Opus 4.8 at **max** ($13/task, 59%); Fable medium 65%, high 69%, xhigh 70% ($22/task). Max barely improves on xhigh.

Defaults:
- `medium`: interactive coding help, routine work.
- `high`: default for serious engineering tasks.
- `xhigh`: architecture, migrations, deep debugging, final reviews only - never for tiny edits.
- Pair higher effort with an instruction not to over-refactor beyond the requested scope.

## Prompt patterns and pitfalls

- **Tell it why.** Give the reason behind the task, who it is for, what it feeds into. Context beats micromanagement.
- **Ground claims in tool results.** On long or autonomous runs, instruct the model to audit progress claims against actual tool output (tests, diffs); this nearly eliminates fabricated status reports.
