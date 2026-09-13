# Eval fixtures are engine-neutral

Every case under `evals/` ends its `prompt.md` body with a section headed exactly `## Expected behavior`, and that section is the fixture.
It holds numbered, plainly-worded assertions about observable outcomes: a file that exists, a line that reads a certain way, a sentence that is said once, a commit that carries a file.
It names no grader type, no runner flag, and no harness concept, because the behaviour under test is a property of the skills and not of the thing that measures them.
Anything that reads the section can check the case, and the assertions are the contract the eleven ported skills are held to.

The grader rubrics under each case's `graders/` directory are one runner over that fixture, not the fixture itself.
Each rubric wraps the same assertions in the Claude Code eval runner's own vocabulary: a `file_exists` grader per required file, a `regex` grader per line that must appear, and an `llm` grader carrying the judgement-shaped assertions as prose criteria.
When the Claude Code runner is unavailable, the named fallback is to replay the same `## Expected behavior` sections through ringer, one manifest task per case, with the case's prompt body as the task spec and its `## Expected behavior` section as the task's check.
The replay command shape is:

```bash
"${RINGER_ROOT:-$HOME/repos/ringer}/ringer.py" lint <manifest> \
  && "${RINGER_ROOT:-$HOME/repos/ringer}/ringer.py" run <manifest>
```

## Verified facts, 2026-09-13

These three were verified before any case was authored, because the case bodies assume all three and none of them had been observed when the plan was written.

| Claim | How verified | Consequence |
| --- | --- | --- |
| A case-level environment override exists as `env:` in `prompt.md` frontmatter, but its keys are restricted to names matching `EVAL_*`; any other key aborts the run. | Read the runner's own schema and its rejection message out of the shipped Claude Code 2.1.269 binary (`execution.env key "..." is not allowed - only EVAL_* keys can be set from case.yaml`), and confirmed the field list against the published `plugin-evals` documentation. | `RINGER_ROOT` cannot be set through `env:`. The `ringer-absent-degraded` case therefore carries an explicit `export RINGER_ROOT=...` as the first action in its prompt body, which is the fallback the plan named. No guessed `env:` field was written. |
| The grader types are exactly `regex`, `tool_order`, `tool_used`, `file_exists`, `llm`, and `baseline`. A `regex` grader takes `pattern`, `flags`, `target`, and `match`, where `match` is `contains`, `not_contains`, or `count:N`. A `file_exists` grader takes a glob `path` and an `exists` boolean, and it matches against the files the run created in its sandbox working directory. An `llm` grader takes `criteria` and a `focus`. Both `target` and `focus` accept `last_message`, `trace`, `files`, `mock_calls`, or a `{source: file, path: ...}` mapping. | Read the runner's grader schema and every grader implementation out of the same binary, then cross-checked against the published documentation. | The plan's guessed `match: count:1`, `file_exists`, and `regex` names all turned out to be real, and the `{source: file, path: ...}` target is what lets the ringer and rubix cases grade an emitted artifact rather than the agent's own account of it. |
| The runner isolates `HOME` unconditionally: every run gets a throwaway home, a throwaway Claude Code config directory, and a working directory beneath it, and only the plugin under test is loaded. | Ran a probe case that printed `HOME` and listed the session's skills. `HOME` was `/tmp/claude-eval-*/home`, and the session skill list held only the eleven `jrit-loop:*` skills plus Claude Code's own built-ins. None of the operator's user-level skills, `rubix-review` among them, were present. | The `rubix-absent-callout` case runs as a real eval and is not demoted. Its absent branch fires for real, so `tests/rubix-callout-wiring.sh` was not written; writing both the case and the test was never an option. |

## Three more facts the sandbox forced, same date

These were not on the plan's list, but each one would have made a case fail for a reason having nothing to do with the skill it tests.

| Claim | How verified | Consequence |
| --- | --- | --- |
| A case that asks for the `Bash` tool cannot run at all unless a sandbox backend is installed. On this host `bubblewrap` was present but `socat` was not, and the runner refused every Bash-granting run rather than running it unconfined. | The first probe run failed with `sandbox required but unavailable: ... socat not installed`, exit 1, zero turns, zero cost. | `socat` was installed into the existing user-scope linuxbrew prefix with `brew install socat`, which needs no root and is reversible with `brew uninstall socat`. Without it the acceptance check for this task cannot pass on this machine, because it grants `Bash`. |
| The run's working directory is seeded with dotfiles that are character devices rather than regular files, so `git add -A` at the top of that directory always fails with `error: .bash_profile: can only add regular files, symbolic links or git-directories` and exit 128. | A probe case ran `git init`, `git add -A`, and `git commit` at the working directory root, and then again inside a fresh subdirectory of it. The root failed at `git add`; the subdirectory committed cleanly. | Every case creates and works inside a `repo/` subdirectory of the run's working directory. The `file_exists` graders use `**/`-prefixed globs so they match whether or not that prefix is present. |
| `CLAUDE_PLUGIN_ROOT` is empty in the shell a case's Bash tool sees. | The same probe printed `PLUGINROOT=[]` and `ls: cannot access '': No such file or directory`. | The `pre-plugin-repo-refusal` case cannot copy `tests/fixtures/pre-plugin-repo/` from the plugin directory, because it has no path to it. The case reconstructs that fixture byte for byte in its own prompt instead. Task 8's fixture stays the source of record, and the two must be kept in step by hand if either changes. |

## What is deliberately not an eval case

The receipt helper's `done --ran` failure routing has no eval case, by decision.
Proving it requires mutating a real tracker, which the eval runner should not be asked to do, and it is already proven by Gate 1 of `tests/receipt-gates.sh`.
That is the whole of the coverage argument for it; nothing here duplicates that gate.

## Stability, advisory and never a gate

The acceptance check is the deterministic single run, `--runs 1`, and that is the only gating measurement.

The optional `--runs 3` stability sweep was not run.
A single pass of this suite costs about $3.74 and takes about eleven minutes, so a three-run sweep projects to roughly $11, above the `--max-cost-usd 10` ceiling the acceptance command carries.
It would therefore abort partway and report a partial spread, which is worth less than no number at all.

The flaky surface was located anyway, without paying for the sweep.
The five `regex` and `file_exists` graders are deterministic by construction; every instability seen while authoring this suite came from an `llm` grader.
One authoring pass recorded judge votes of `PASS FAIL FAIL` on a reply that satisfied the assertion, because the criteria treated an empty code block as a missing answer.
Two `llm` graders also carry the runner's own long-input warning, `no-ringer-evidence` over a 57k-character plan and `plan-still-delivered` over a 14k-character one, and long inputs are exactly where judges get noisy.
Any future flake in this suite should be looked for in an `llm` grader's criteria first.

## A property of this design worth knowing

The `## Expected behavior` section is the last thing in each `prompt.md` body, which means the agent under test reads its own assertions before it acts.
That is what makes the section portable across runners, and it is the design D11 chose, but it does soften every case: a skill that would not have produced the right behaviour unprompted can still be led to it by the assertion list.
These cases therefore prove that the skills can reach the named outcomes, not that they reach them unbidden.
The stricter reading is left to the static tests under `tests/`, which read the skill files directly and cannot be led.
