---
name: loop-drive
description: Use when you have a multi-step plan, PRD, or hand-off run-book (steps or work packages, with or without copy-paste prompts) and want a single frontier-model session to orchestrate its execution instead of a human pasting prompts by hand. Also use to kick off a new project, break a big task into per-step prompts, route steps across model tiers ("which model should do this"), produce a human-paced Frontier-Sandwich run-book, or answer "is this worth automating / how should I run this plan" (the One-Minute Test front door for a plan in hand). Covers ringer-transported and background-agent-transported workers, mixed freely within a wave. Not for a one-off single-answer task.
---

# loop-drive: hand-off plan to orchestration plan

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

You are the compiler and driver that turns a plan written for a human operator (open a session, set the model, paste a prompt, review, repeat) into a plan one frontier-model session executes autonomously.
The input can be a full "Frontier Sandwich" run-book, a step-by-step plan, or a flat PRD; you derive the wave structure the plan does not spell out.
You emit the orchestration plan and, once approved, drive it.

Workers reach execution through two transports: ringer (manifest tasks; see `references/ringer-substrate.md`) and the harness's own background-agent transport (in-session workers; its harness-specific mechanics are a conditional read below).
Transport is a per-unit attribute derived in Step 2.
This file is the portable core: it names no harness primitive, and any tool that can run bash can pick up the baton from the tracker.

The principle IDs cited below (P2, P6, P7, P10, P11, P12, P14) carry short glosses inline so this skill stands alone.

## Step boundary and entry points

The driving session does not compile the plan inline.
Steps 1-4 and Step 6 - extract the skeleton, assign roles and models, neutralize the hazards, convert the prompt templates, and emit the plan - are compiled by ONE fresh-context dispatch at the drive-compile dispatch role pin; cite the role pin by that name, never a bare model id mid-prose (the pin resolves to Opus, and this line is its single home).
The driving session keeps Step 0 (route and scope), a pin review of the compiled output against this skill's rules, the Step 5 gates, and the Step 7 launch.

**Start from an existing `_loop.md`.**
When the orchestration plan already exists, skip compilation entirely and go straight to the pin review of that file, then Step 7.

## Conditional reads

Nothing under `references/` is an always-read; each file is pulled at its trigger below, and an invocation whose path never fires a trigger reads none of them (molt verdict 2026-09-13; this block is the single home of the triggers).

- `references/model-benchmarks.md`: read when a routing decision arises - Step 2 unit assignment, a runtime re-route at a gate, or human-paced per-unit model choice. Step 0 triage, a CHAT or DON'T BOTHER exit, and the pin review of an existing `_loop.md` do not read it.
- `references/ringer-substrate.md`: read when at least one unit takes the ringer transport; never read in degraded mode (ringer absent).
- `references/harness-appendix-claude-code.md`: read when at least one unit takes the background-agent transport; it is the single home of this skill's harness-specific mechanics and the only loop-drive file that names a harness primitive.
- `references/fable-guidelines.md`: read only in human-paced output mode, before drafting the run-book.
- `references/reviewer-conduct-contract.md`: read when validators are about to be dispatched (compiling Step 4 templates, or launching from an existing `_loop.md`); the fail-closed stop on a missing file is unchanged.
- `references/one-minute-test.md`: read on every fresh-plan entry at Step 0; the existing-`_loop.md` entry point skips it.

`references/queue-runner.md` is not a read for this skill at all: it is a standalone pasteable operator prompt homed here, pinned by its own gate test.

## Step 0 - Route and scope

Before compiling anything, decide whether this plan should be a loop at all, and at what size.

Run the One-Minute Test verdict (`references/one-minute-test.md`; the front-door triage - or reference the user's if they already have one):

- **CHAT** or **DON'T BOTHER**: stop. Say so plainly and name why (answer it in-session, or it is not worth automating). Do not emit a plan.
- **ONE AGENT** or **single-wave TEAM**: skip the wave machinery entirely. Apply the Step 2 chain to the single unit (no table), and emit one artifact directly, naming the unit's model, transport, and evidence tier alongside it:
  - background-agent transport: one worker brief (the subagent prompt from Step 4), and name the exact launch.
  - ringer transport: one ringer manifest, and name the exact command: `./ringer.py lint <manifest> && ./ringer.py run <manifest>`.
- **Multi-wave dependent build**: proceed through Steps 1-6; Step 7 fires at launch on every route.

Probe both optional substrates before routing.

**Probe.** Run `[ -f "${RINGER_ROOT:-$HOME/repos/ringer}/ringer.py" ]`; the `RINGER_ROOT` environment variable overrides the default location.
**Present:** ringer is available as a worker transport, and its scoreboard is the top evidence tier of the routing chain.
**Absent:** every unit takes the harness's own background-agent transport, and routing skips the top evidence tier entirely, falling back to benchmark prior then orchestrator pin.
**Disclose:** say in one line, in the emitted plan's pre-flight, "ringer not found at the probed path; running degraded: background-agent transport only, routing by prior."

**Probe.** Run `[ -n "$HERDR_ENV" ] && command -v herdr >/dev/null 2>&1`; when it succeeds, check compatibility at probe time with `herdr api schema --json` and never against a pinned version number.
**Present:** workers may be dispatched into herdr panes via `herdr api` instead of background agents.
**Absent:** workers dispatch through the harness's own background-agent transport, unchanged.
**Disclose:** say in one line "herdr not detected; dispatching workers through the harness's own background-agent transport."

Apply the checkability gate here and per unit (P6: a unit belongs on a worker only if its output can be checked more cheaply than produced); anything that fails it stays in the orchestrator's own judgment lane, never dispatched.

Every Step 0 exit must name the concrete next command or launch, so the user never has to guess which skill or command comes next.
Ship every run-something exit with a topology diagram: a fast text sketch (ASCII or fenced mermaid, never a rendered export) of orchestrator, waves, workers, and validators.
If two shapes are close (roughly 60/40 or tighter), diagram both, name your lean and why, and let the user pick.`[gate:BATCH]`

## Human-paced output mode (absorbs frontier-sandwich)

When the user wants a run-book they execute by hand across sessions (paste a prompt, review, repeat) rather than a session that orchestrates the loop, emit that instead of the wave machinery.
The invariant is the sandwich: frontier judgment before and after cheap execution, never frontier keystrokes in the middle - a Strong/Fast explore feeds a Frontier plan, then Strong/Fast execution, then a Frontier review, then a human ship.
Tier vocabulary (Frontier/Strong/Fast) and the effort defaults live in `references/fable-guidelines.md`. Per-unit model choice still follows the routing chain (`references/model-benchmarks.md`).
Output shape: a simple plan (roughly five steps or fewer) is one file, each step carrying its model tier, effort, copy-paste prompt, and verification check; a complex plan is a directory with an index Order table plus one numbered prompt file per step, so each file hands whole to a fresh session. Handoffs go through files, never conversation memory, so a quota death resumes by re-running the unfinished step.

## Step 1 - Extract the plan's skeleton

Read the source plan and everything it points to, and extract:

- **Units of work**: the steps or work packages, each with scope, acceptance criteria, and named tests if present.
- **Dependency structure**: explicit waves/ordering if given; otherwise you own deriving the wave graph from the depends-on relations, even for a flat PRD with no ordering at all.
- **Per-unit model hints**: what the human plan assigned (often "Opus for everything"); you re-derive these in Step 2, not copy them.
- **Prompt templates**: the paste-blocks; these become subagent prompts (background-agent) or manifest specs (ringer).
- **Human checkpoints**: places the plan says the human reviews or approves; these survive conversion, they do not disappear.
- **Shared state**: log files every session appends to, branches, checklists; these are the parallelism hazards.
- **Failure policy**: retry limits and escalation targets.

If a unit has no acceptance criteria you can turn into an executed check, stop and say so; orchestration without verifiable gates is just faster drift.

## Step 2 - Assign roles, models, and effort (transport-aware)

The loop is a three-tier structure regardless of transport:

| Tier | Who | Does |
|---|---|---|
| Orchestrator | the main session | The wave loop, gates, merges, spec edits, escalation. Never implements. Reads logs, verdicts, and core diffs only, to preserve context. |
| Validator | a fresh checker per unit (a subagent at the background-agent-validator role pin (resolves to Opus; this line is the pin's home), or an executed check plus optional review task) | Adversarial re-check of the implementer's claim against actual artifacts. Never fixes. |
| Implementer | a worker per unit (subagent, or manifest task) | The unit's actual work, test-first against its criteria. |

Model choice is one chain for every unit, regardless of transport, and it follows the routing chain (`references/model-benchmarks.md`) - that single home carries the three-tier evidence chain, the `./ringer.py models --task-type` posterior with its MODEL-NOTES/AMENDMENTS-PENDING integrity read, the promotion ladder, the `claude-zai` tie-break, and the roster (P7: route by evidence, not vibes). Do not restate the chain here.
Evidence cells carry the short tag only (`posterior`, `prior`, `pin:<reason-word>`); longer rationale goes in a footnote beneath the table; a pin outranks the chain when its trigger holds and the reason is never "seems hard".

Transport is derived per unit, never chosen per wave: a unit that needs in-session tools or mid-flight continuation takes the background-agent transport; otherwise it takes ringer, subject to the ringer stub's Absent rule from Step 0.
Within a wave, all ringer-transport units pack into one manifest; background-agent units launch as parallel workers; both meet at the same gate.

Roster: background-agent workers are sonnet, opus, and haiku; Fable is orchestrator-tier only and never a worker; GLM and codex run only via ringer.
Quota preference: execution typing leans to the flat-rate `claude-zai` lane when evidence ties or is thin, keeping Anthropic quota for orchestration, review gates, and judgment; this is a tie-break, not a tier.
Taste flag: units with aesthetic acceptance criteria get flagged in the routing table and offered the per-unit engine ask despite any default.

Give every unit a `task_type`; the field is free-form, and the suggested vocabulary's single home is ringer's README - never restate the list here.
The task_type drives scoreboard routing and must be set even for background-agent units so the choice is legible.
When ringer's optional Jev task_type feature is on, lint prints one `jev:` line per task comparing Jev's pick with the hand label; treat a disagreement as a re-check signal on the hand label, not an authority, and read a `keeps hand (hand-outside-vocabulary)` line as expected for a type outside Jev's narrower closed set, not actionable.

Effort: cap everything at **high**; exceeding high requires an explicit orchestrator decision recorded in the run log.`[gate:STOP]`
Use medium for units that are thin, well-referenced, or mechanical; high where numeric correctness, quirk preservation, or contract design is at stake.
Validators default to medium, high only for gate-critical units.

Runtime escalation: a unit that fails validation twice is re-routed at the gate by the same chain, usually a pin to a stronger model with the reason recorded; it is not an automatic ladder.

Produce a per-unit table with columns Unit, Wave, task_type, Model, Transport, Engine, Impl. effort, Val. effort, Evidence.
Every row needs the rationale; "seems hard" is not one.

## Step 3 - Neutralize the parallelism hazards (mark transport coverage)

Which hazards you must mitigate depends on the unit's transport.
On a mixed wave, both hazard sets are active at once.

**Check custody (both transports).**
Acceptance-check scripts live outside every worker's file ownership: no unit lists a check file among the files it may create or edit, and a worker diff that touches a check file is an automatic scope violation, not something to resolve at the gate.
The check is the attack surface - a worker that can edit its own success criterion can pass by gaming it (METR found o3 reward-hacked past a loop's criterion in 21 of 21 runs), so the check must live where no worker it judges can reach it.

**Ringer-transport units:** worktree isolation, per-task directories, and log separation are handled for you by run-level `"worktrees": true`; do not re-specify them.
Ringer's own footguns (deliverable loss on a passing worktree, gitignored outputs missing from patch exports, engine-concurrency staggering) are single-homed in `references/ringer-substrate.md`; carry them into the plan from there.

**Background-agent units:** the harness gives each background worker its own `git worktree`, merges validated branches at the gate, and never touches mainline; do not re-narrate that. Five hazards it does NOT handle are correctness policy you MUST carry (test-by-subtraction misses them - the toy chain exercises no nested repo or venv):

- **Nested repos**: if the code lives in a repo nested inside the session's outer repo, the harness's built-in worktree isolation snapshots the WRONG repo; the implementer must create the worktree itself with explicit `git -C <inner-repo> worktree add ...` commands you spell out.
- **Per-worktree environments**: in-project venvs do not travel; the template includes the install step (e.g. `poetry install`) inside the worktree.
- **Shared append-only files** (run logs, checklists): convert to one-file-per-unit (`<log>/unit-NN.md`); the orchestrator writes the combined summary at the gate. State this as an explicit, once-noted deviation from the source plan.
- **Dirty working tree**: the run's gate journal is committed first by the pre-flight journal-commit step (its creation-and-commit timing is homed in the loop-auto skill), so the journal is never the protocol dirt this STOP trips on.
  This STOP stays absolute and autonomy never auto-resolves it; worktrees branch from committed state only, and pre-flight then surfaces any remaining uncommitted changes to the human before wave 1.`[gate:STOP]`
- **Disjoint-files assumption**: within-wave units touch disjoint files by construction; a merge conflict at the gate is a scope violation, not something to quietly resolve.

## Step 4 - Convert the prompt templates (per transport)

**Background-agent units:** rewrite each paste-block as a subagent prompt.

- Delete human mechanics ("open a fresh session", "/model", "paste below", "tell me in chat").
- Keep the reading list, scope boundary, rules of engagement, and test-first order verbatim in spirit; these are the plan's real content.
- Add the workspace rules from Step 3 (worktree creation command, install step, never touch main, never push).
- Change "ask me if ambiguous" to the autonomous form: record the question in the unit log, take the most conservative reading, flag it in structured output.
- End with a structured-output contract: `{unit, branch, commit, worktree_path, tests_passed, tests_failed, deviations, open_questions, deferred_items}`.

**Ringer-transport units:** emit a manifest task per unit instead of a prompt (spec-writing rules from the ringer skill):

- **Self-contained spec.** The worker gets no conversation; put everything it needs in the spec. No pointer specs ("do what the plan says").
- **Ownership list.** Name every file the worker may create or edit, especially in multi-worker runs over one repo.
- **Embedded how-to-run.** State exactly how to build/test so the worker and the check agree.
- **Output contract.** State the exact deliverable files (and set `expect_files`).
- **Check-writing rules (P14: checks are as important as specs).** The check prints WHY it fails (a silent exit 1 starves the retry prompt and the eval log). It verifies substance, not just presence. The FULL check-writing ruleset lives in the ringer skill's "Check-writing rules" section - read it before writing any check; do not work from this summary (it summarizes, ringer governs; checks that pass this summary can still break ringer's rules - unsatisfiable under the spec's boundary, repo-wide negative greps, invariants missing their exceptions - and produce false FAILs).
  Prove non-vacuity with a committed expected-fail fixture, never a live mutate-and-restore probe: a check must never mutate the working tree to demonstrate it can fail and then restore it, because that authors dirt the protocol then trips on and can corrupt the tree if the run dies mid-probe.
  This proof is run on demand only, never a per-run obligation: it is exercised when non-vacuity is in doubt, not required of every check on every run.
  The expected-fail fixture convention - its naming, its location, and how a run references it - is governed by the ringer skill's "Check-writing rules" section, which is its single home; until that convention is authored there, skip the non-vacuity proof rather than fall back to a live probe.

**Both transports, standing house rules (MODEL-NOTES 2026-09-17 signal):**

- Forbid commit attribution explicitly: the harness's attribution reminder injects a Co-Authored-By line into worker commits unless the implementer prompt forbids it; worktree-transport workers do not commit at all, so this bites background-agent units.
- No GNU-only flags in any command, check, or embedded how-to-run; portability is a standing rule, never a per-unit hope.
- Style rules bind human-read artifacts only: classify each artifact a unit produces as human-read (a deliverable a person reads) or machine-read (the resume pointer, the structured-output result, unit logs), and compile any style constraint (sentence-per-line, dash, table style) into worker specs and validator criteria for the human-read set alone.
  A source-plan constraint phrased over every Markdown file is narrowed this way, noted once as a deviation.

**Both transports:** the validator/review stance is adversarial and evidence-first (P2: worker self-reports are worthless).
Judge the raw evidence (the diff, the executed check output, the artifact), and ignore the implementer's own narrative of what it did.

The reviewer-conduct contract is `references/reviewer-conduct-contract.md`, shipped inside this skill.
Read it and paste its contents verbatim into each subagent prompt below.
If that file is absent, this installed skill is broken: stop, do not run the subagents uncontracted, and report that the jrit-loop plugin install is incomplete and should be reinstalled. Do not run any installer from the repository under review.

Background-agent validators also get: mandatory independent test rerun, criterion-by-criterion walk with evidence, scope-boundary diff audit, read-only, and a `{verdict: pass|fail|spec-problem, criteria: [...], notes}` contract (spec-problem routes spec bugs to the orchestrator instead of a futile fix loop).
Every validator prompt (both transports) states verdict discipline explicitly: if ANY criterion fails, the overall verdict is fail - without this line, first attempts write pass while their own notes contradict it.

## Step 5 - Write the wave loop and gates

The output plan's core procedure, per wave, depends on transport for item 1 and shares the gate structure.
Gate-class semantics (ASK, STOP, BATCH, DEFAULT) and the batch-review journal format live in the loop-auto skill.

**1. Launch the wave.**

Ringer-transport units: emit one manifest for the wave and run it (`./ringer.py lint <manifest> && ./ringer.py run <manifest>`), using the SAME `run_name` across all waves; ringer's built-in single retry IS the repair pass, you do not add one.
Background-agent units: the harness runs them as parallel background workers and notifies you on each completion - on completion, launch that unit's validator; on a failed validation, one repair pass routed to the same implementer (the appendix names the steering mechanism), then revalidate; a second failure stops that unit without blocking its siblings.

**2. Gate (orchestrator).**
Read all results and verdicts from both transports.
Ringer: consume the run JSON in `~/.ringer/runs/` and the raw worker logs in `<workdir>/logs/` per ringer's post-run ritual (read every retried/failed log, spot-check at least one passing artifact).
The run JSON is truth; a detached/background shell's exit status is transport and can report failure for a run that passed.
On a FAIL, attribute before relaunching, and attribution is always a fresh re-run of the check rather than a precedent substitution.
Citing an earlier gate's verdict in place of running the check now is the banned move: a verdict from a prior run is not evidence about the current tree, so an earlier pass never stands in for the check this FAIL owes.
The already-allowed move is the re-run and its honest consequence: re-run the check's steps yourself against the tree, and if the worker's output was correct and the CHECK was wrong, fix the check, commit the audited work, and annotate the model log (MODEL-NOTES + amendment when available) instead of burning a round.
Quota exhaustion is a STOP, never a license to skip a check: when quota runs out mid-attribution the run halts and states what it needs, and the fresh check is still owed on resume.`[gate:STOP]`
Background-agent units: skim diffs of Opus-tier units and test files of Sonnet-tier units.
Merge passing branches (or apply reviewed patches) into the integration branch; run the full suite there.
Resolve stopped units: a small spec issue means edit the spec artifact and relaunch that unit; a design issue is recorded for the plan's downstream review step under the source plan's slip rules.`[gate:STOP]`
Write the wave summary; prune worker worktrees (ringer prunes its own).

**3. Distill before advancing (both transports, P10: distill or repeat forever).**
Turn any repeated failure pattern from this wave's verdicts into a fix in the spec artifact and the templates before the next wave, so the next wave does not re-earn the same failures.
Background-agent units MUST leave dated MODEL-NOTES receipts at the gate - their only durable receipt, since only ringer runs feed the scoreboard.
Batch them: one dated line per (model, task_type) per wave in `<ringer-repo>/docs/MODEL-NOTES.md`, plus a separate line only for signal events (a pin, a runtime re-route, a check-bug attribution, an off-nominal result); support them only with validator verdicts and diffs, and read them back through the same integrity discipline as any posterior.
Committing the ringer-repo receipt is part of closing the gate: commit it before advancing the wave, so the git-is-truth reconciliation covers both repos.

**4. Advance only on a green integration branch.**

Preserve the source plan's checkpoint culture: list exactly when the orchestrator stops and asks the human (P12: gates scale with risk, not size).
The minimum set: pre-flight dirty-tree decisions.
Any request to exceed the effort cap stops and asks the human`[gate:STOP]`.
A spec edit confined to a single unit or criterion, leaving unchanged what that unit is asked to produce, and touching 15 or fewer lines, auto-takes as BATCH `[gate:BATCH]`.
A larger edit, or one touching multiple units, a global constraint, or a unit's produced contract, stays a STOP and asks the human`[gate:STOP]`.
The boundary is blast radius, not raw size; 15 lines is the agreed threshold.
Any outward-facing unit (touches live consumers, publishes, or deletes things the human owns) stops and asks the human`[gate:STOP]`.

**Unit completion and the resume pointer (both transports).**
At unit completion, after the unit's acceptance check has passed and before the closing commit, the implementer writes `<handoffs-home>/YYYY-MM-DD.<unit-slug>.resume.md` in the target repo, where `handoffs-home` is read from `docs/loop/pointer.md` and defaults to `docs/handoffs/`.
The file carries four required headings, in this order and verbatim:

```markdown
# Resume pointer: <unit name>

## Unit
<unit name, the plan and task it came from, and its tracker issue number>

## State
<what is true right now, in one or two sentences, including the branch and whether the acceptance check passed>

## Next step
<the single next action, as a concrete command or a named task>

## Recent artifacts
<one bullet per artifact this unit produced or consumed: the brief, the plan, any review docs, and every doc the unit created, each as a repo-relative path>
```

`## Recent artifacts` lists the unit's brief, plan, review docs, and every doc the unit itself created, each as a repo-relative path gathered from the unit's own run rather than from memory.
The file is `git add`ed and committed in the unit's closing commit, and no human asks for it; it is machine-read, so style rules never bind it (see the standing house rules in Step 4).
Compile this deliverable into every worker prompt and manifest spec from Step 4, so the worker writes it, not the orchestrator.
For worktree-transport units, the resume pointer's path also joins the unit's ownership list, so it travels in the exported patch and lands in the unit's closing commit.

Design for interruption: the orchestrator cannot see the user's remaining quota, so the loop must die safely at any moment.
Implementers commit their results and log before returning; the plan contains a verbatim resume prompt plus a reconciliation procedure that relaunches (never resumes) half-done units.
The receipt helper ships next to this skill at `scripts/receipt.sh`; invoke it as `bash scripts/receipt.sh <verb> ...` resolved relative to this skill's own directory, never against the repository under work, and never by relying on its execute bit.
Run-state lives on the claimed ticket, not only in a session-local file (P11: git is reconciliation truth): on claiming a unit and again at every wave gate, the orchestrator posts an `AGENT STATUS` receipt - `gh issue comment <num> --body "AGENT STATUS branch=<b> worktree=<path> verdict=<v> repairs=<n>"` in github mode, or `glab issue note <num> --message "AGENT STATUS ..."` in gitlab mode, per the tracker mode declared in `docs/loop/pointer.md` - carrying the unit's branch, worktree path, validator verdict, and repair count.
A session-local run-state artifact may still be kept for the live session's own convenience, but it is a cache; the ticket receipt is the durable copy a fresh session reads.
The helper's three non-zero exits, documented at first use: exit 4 from `bash scripts/receipt.sh claim` means a lost claim race, so stop and pick a different unit; exit 5 from `bash scripts/receipt.sh done` means the receipt cited no executed-check evidence, so run the check and retry with `--ran`; exit 7 means the cited check actually failed and the issue is now `agent:review`, so the unit is not done and the failure is the finding.
The reconciliation procedure relaunches (never resumes) a half-done unit, reading three sources in order: first the unit's resume pointer (the newest file under `handoffs-home` naming the unit), then the ticket's `AGENT STATUS` receipt - a fresh session finds the killed unit via `bash scripts/receipt.sh next-eligible` (its stale-working sweep surfaces a dead session's ticket) or `bash scripts/receipt.sh claim <num> <session-id> --reclaim` - then git, and it relaunches the unit from scratch.
Git remains reconciliation truth over any receipt or pointer: when they disagree with the repository, believe the repository.
The reconciliation procedure also checks the ringer repo for an uncommitted MODEL-NOTES receipt owed by the last gate (the run drives two repos; both are checkpointed).

On the final wave only, after the integration branch is green and the run advances, run the advisory terminal artifact review: `/loop-review <pre-run-base>` from the integration branch, so the two-axis Spec and Standards report judges the whole-run diff.
This review is advisory and non-blocking - the per-unit validators already gated correctness, so it runs after advancement and does not hold it; its findings are recorded at the final human checkpoint (the ask-the-human list above), and a Spec-axis finding is slipped to the plan's downstream review step under the same slip rules used for a stopped unit's design issue.`[gate:BATCH]`

## Step 6 - Emit the plan

Write `<source-plan-name>_loop.md` next to the source plan, containing, in order:

1. What this file is, that the source plan remains the manual fallback, and that the spec artifact stays ground truth.
2. **Routing table**: the per-unit table with the columns Unit, Wave, task_type, Model, Transport, Engine, Impl. effort, Val. effort, Evidence.
3. The orchestration shape and the three validation layers (implementer self-check, per-unit validator, orchestrator gate), plus the topology diagram (updated from Step 0 if compilation changed the shape).
4. The hazard mitigations from Step 3, each marked as a deviation from the source plan where it is one.
5. Pre-flight checklist (the run's gate journal committed by the pre-flight journal-commit step as the first item; repo state, environment versions, integration branch creation, log directory; for ringer waves, the engines present; the Step 0 probe results, with each fired Disclose line quoted verbatim).
6. The wave-loop procedure and gate checklist from Step 5, including slip rules, the ask-the-human list, and the final-wave advisory terminal loop-review review.
7. A quota/resume section: durable-state rules, the reconciliation procedure, and the verbatim resume prompt.
8. The implementer/validator prompt templates (background-agent) and/or the manifest task templates (ringer) from Step 4.
9. A one-paragraph "kicking it off" section: the sentence the human says to start, where the per-wave summaries appear, the watch points from Step 7, and a pointer to the resume prompt.

Follow the user's global markdown style instructions already loaded in this session's context, when any exist.
Drafting the plan and executing it are separate approvals.
With the autonomy knob at auto, the transition into execution after the pin review passes auto-takes`[gate:DEFAULT]` - invoking /loop-drive on a finished plan under auto is the execution approval; log the launch decision in the batch-review journal.
With the knob at pause or unset, the transition is an ask`[gate:ASK]` - do not start executing until the user approves.
Either way, go through Step 7 before launching anything.

## Step 7 - Drive dashboard, then launch

When the user approves execution (including the single-artifact exits from Step 0), offer the pre-launch detail menu once per run: with the knob at pause or unset, ask in-session "See execution details before I launch?" (the appendix names this harness's question mechanism); with the knob at auto, never fire the ask - auto-take the nothing-selected default (launch immediately), print the dashboard and watch points inline, and journal the take.`[gate:DEFAULT]`

- **Dashboard**: what will run - the routing table condensed (unit, wave, model, transport, effort) plus the topology diagram.
- **Dry run**: prove the "go" before firing it - execute the pre-flight checklist for real (ringer: `./ringer.py lint <manifest>`, engines present; background-agent waves: clean tree, worktree-able state) and print the exact wave-1 launches (commands and worker briefs) without starting any worker.
- **Watch points**: where to follow the run live - background-agent waves: per-unit logs (`<log>/unit-NN.md`), the tickets' `AGENT STATUS` receipts, the harness's background-completion notifications; ringer: `tail -f <workdir>/logs/` during a wave, run JSON in `~/.ringer/runs/` at gates.

Show what they picked, fix anything the dry run flags, then launch; nothing selected means launch immediately.
Once per run, never per wave.
