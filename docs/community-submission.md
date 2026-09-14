# Community marketplace submission, jrit-loop

This document holds the filled submission, ready to paste into the form at the URL below.
Jeremy fires it at human checkpoint C7; nothing here has been submitted anywhere.

Submission URL: https://platform.claude.com/plugins/submit

## Submission fields

Repository: https://github.com/jroethel/jrit-loop

Plugin name: jrit-loop

Version: 0.1.0

Description: The loop-stack toolkit: brainstorm, plan, drive, review, and track multi-step work through your repo's own issue tracker.
Its eleven skills carry an idea from first brainstorm through planning, gated or autonomous execution, two-axis review, and tracker filing, with your repo's own tracker as the single source of state.

Requirements: `gh` (authenticated) for GitHub tracker mode, or `glab` (authenticated) for GitLab tracker mode; `jq` for GitLab mode.

License: MIT

## The eleven skills

| Skill           | Line                                                                                                                                                                   |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| handoff         | Compact the current conversation into a handoff document for another agent to pick up.                                                                                 |
| loop-auto       | Set or check the chain autonomy knob and its four gate classes (ASK, STOP, BATCH, DEFAULT), turning a run from human-gated to autonomous.                              |
| loop-brainstorm | Think an idea through before any plan, PRD, or scaffolding exists, ending in a loop-ready idea brief.                                                                  |
| loop-drive      | Orchestrate the execution of a multi-step plan, PRD, or run-book in a single frontier-model session instead of a human pasting prompts by hand.                        |
| loop-improve    | Audit the repo for improvements and converge the ones worth doing into a single approved brief for planning.                                                           |
| loop-molt       | Audit an instruction-prose artifact against a dated snapshot of what the harness now does natively, so plumbing gets deleted and policy survives.                      |
| loop-plan       | Turn a brief, spec, or requirements into an executor-agnostic implementation plan consumable by loop-drive or any capable agent.                                       |
| loop-review     | Run a two-axis review (Spec and Standards) of the diff since a user-supplied fixed point, with fresh-context subagents and disclosed sources.                          |
| loop-setup      | Declare a repo's tracker mode once, write the two pointer docs, and wire the managed instructions into AGENTS.md.                                                      |
| loop-track      | File one tracker issue (idea, plain issue, or wayfinder item) from a plain natural-language ask, no mechanism knowledge required.                                      |
| wayfinder       | Plan a huge chunk of work as a shared map of decision tickets on your issue tracker, resolved one at a time until the way is clear.                                    |

## Evidence

Every quoted line below is verbatim from `docs/2026-09-13.proof-pass-receipts.md`, Part 1 (unit u13, 2026-09-13) and Part 2 (unit u14, 2026-09-14), plus the criterion-14 section recorded at checkpoint C6.

Both validate commands, Part 1:

> 1. `claude plugin validate --strict .` - exit 0 (validated the marketplace manifest, validation passed).
> 2. `claude plugin validate --strict .claude-plugin/plugin.json` - exit 0 (plugin manifest, validation passed).

`ci/run-all.sh`, Part 1:

> 3. `bash ci/run-all.sh` - exit 0 (structure, budget, drift, working-tree secrets, consumer sweep, both validates, `PASS: all`).

`ci/run-all.sh`, Part 2, records 2 and 7:

> `run-all.sh` itself passed, exit 0: `PASS: structure`, `PASS: budget` (helper SLOC 196 under the 200 budget), `PASS: drift`, `PASS: secrets` with `engine: gitleaks`, `19 commits scanned`, `no leaks found`, `PASS: consumer-sweep`, both `claude plugin validate --strict` runs passing, `PASS: all`.

> `run-all.sh` passed again, exit 0, with the same PASS lines as record 2 (`engine: gitleaks`, `19 commits scanned`, `no leaks found`, `PASS: all`).

The eval run, Part 1:

> 7. `claude plugin eval . --trust-plugin --ablation none --threshold 1.0 --runs 1 --no-publish --max-cost-usd 10 --allow-tools Bash Write Edit --json evals/results/last.json` - exit 0.
> Overall score 1.0, 5 of 5 cases passed, reported cost USD 3.5640512, duration 1953 s, results written to `evals/results/last.json`.

The clean room, Part 2: the committed script failed pre-fix (records 2, 3, and 7, each exit 1 at the installed-copy assertion), the defect is documented in the receipts doc, the one-flag fix was applied by the script's owner, and the post-fix compound is the operative record:

> Post-fix compound, executed by the orchestrator at the wave-7 gate on RIT-UADV2223 after the one-flag clean-room fix (`-g` on the skills install, so the sandbox HOME receives the copies): `bash ci/run-all.sh && bash ci/clean-room-npx.sh && bash ci/single-resolution.sh` - exit 0, `PASS: clean-room` with all eleven installed-copy checks ok, `PASS: single-resolution` 11/11.

The full-history secrets scan, Part 1:

> 9. `bash ci/secrets-scan.sh --full-history` - exit 0 (`PASS: secrets`).
> Engine: grep fallback, because gitleaks is not on PATH.
> This is the weaker engine, so this green is a fallback green, and the C4 reader must carry that fact into the flip decision.

The same scanner under the stronger engine, Part 2, inside both `run-all.sh` runs quoted above (branch history and working tree, not the `--full-history` all-refs form): `engine: gitleaks`, `19 commits scanned`, `no leaks found`.

Marketplace install proven end to end, checkpoint C6:

> Criterion 14 is therefore recorded as PASSED at checkpoint C6, the last open criterion beside the Mac's pending per-host criterion 12 run.

The eval report is left unpublished, per the plan's default for this task; nothing was run or published for it here.
