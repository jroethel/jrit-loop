---
name: loop-plan
description: >
  Use when a brief, spec, or requirements exist for multi-step work and the next artifact is an
  implementation plan - after /loop-brainstorm (or any spec), before any code. Triggers on
  "write the plan", "implementation plan", "break this into tasks", "PRD", or a brief handed off
  for planning. Emits an executor-agnostic plan consumable by /loop-drive or any capable agent
  with no special skills installed.
---

# loop-plan: brief to loop-ready plan

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

You write the implementation plan for an executor with zero context for the codebase and questionable taste.
That executor may be a human, a lone agent, or a wave of parallel workers under /loop-drive; the plan must serve all three without knowing which.
The plan stands alone: no skill invocations, no tool-specific instructions, nothing the executor must have installed beyond the repo itself.

```
/loop-brainstorm ──> brief ──> /loop-plan: skeleton (+ optional Rubix review) ──> one question round ──> (optional plan review page) ──> plan ──> exit by loop-auto ──> /loop-drive
```

Loop work downstream consumes what is set here: explicit depends-on relations become waves, exclusive file ownership makes parallelism safe, and executed acceptance checks are /loop-drive's hard gate (P6: a unit belongs on a worker only if checking is cheaper than producing).

<HARD-GATE>
Do not write implementation code, scaffold anything, or invoke any implementation skill.
The only files you create are the plan, the plan review page and its record, and their revisions.
Test code embedded in the plan document is plan content, not implementation.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order:

1. **Ingest** - read the brief and everything it points to; explore the codebase
2. **Skeleton and the Rubix pass** - the shape of every task, then the optional Rubix review of that shape
3. **The one question round** - every open decision in one round; nothing is asked after it
4. **Optional plan review** - one page of the shape, approved before any task body is written
5. **Write the task bodies and tests** - steps and verbatim test code for every task in the skeleton
6. **Self-review and lint** - including the loop-drive contract check, fixed inline, then the lint
7. **Run shape** - the table the lint's run-table verb prints, pasted verbatim
8. **User reviews the plan** - and gets offered the commit
9. **Exit by loop-auto** - hand off, or commit and start the chain, by the effective autonomy mode

## Step 1 - Ingest

The normal input is a loop-brainstorm brief (`docs/briefs/`): outcome, success criteria with `[executed-check]`/`[judgment]` tags, seams, assets, known-vs-guessed, open questions for planning, and a `Resolved assumptions` section.
Without a brief, accept any spec or requirements, but first run a condensed intake (outcome, what done looks like, checkable criteria) - do not plan against a vibe.
When the work is named by a tracker issue number and no committed brief exists for that issue, do not plan and do not ask brief-level questions: end at once with Step 9's no-brief line.
Explore the codebase the plan will land in; follow its existing patterns rather than restructuring around them.

## Step 2 - Skeleton and the Rubix pass

Write the skeleton first, then review it, so findings land before any task body is spent.

**The plan file.**
Save to `<plans-home>/YYYY-MM-DD.<tokens>.<topic>-plan.md`, where `<plans-home>` is the `plans-home:` key from `docs/loop/pointer.md`, defaulting to `docs/plans/` when the key is absent.
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.

**The skeleton.**
The skeleton is the plan file with its header (Step 5), its decision log so far, its global constraints, the file map, and for every task its heading, `Depends on`, `Shape`, `Type`, optional `Model`, `Decisions`, Files, Interfaces, Edge inputs, and the acceptance command.
It has no step bodies and no test code; those are Step 5's work.

**File structure first.**
Map which files will be created or modified and what each is responsible for; this is where decomposition gets locked in.
Prefer small files with one clear responsibility; in existing codebases, follow the established pattern.

**Task right-sizing.**
A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate.
Fold setup, config, and docs into the task whose deliverable needs them; split only where a reviewer could reject one task while approving its neighbor.
The brief's seams are candidate task boundaries; deviations from them get a recorded reason.
The brief's invariants (its North star and invariants section) are non-negotiable constraints on seam 1: each becomes a Global constraints line verbatim, and a plan that cannot honor one stops and asks rather than trading it away.

**Prefactor rule.**
Restructuring that must precede a change is called out as its own earlier task or step, so it never rides inside a feature task.
For a wide refactor, expand-contract is the reference pattern: land the new structure, migrate callers, then remove the old.

**Loop-aware structure (the delta from a human-paced plan):**

- Every task declares `Depends on:` explicitly, even "none".
  Waves are derived from these; a missing edge is a race condition.
- Every task's file list is exclusive ownership.
  Two tasks touching one file must be dependent, never parallel; a shared file is a boundary error, redraw it.
- Every task ends in an acceptance check: one command, its expected pass condition, tagged `[executed-check]`.
  A task whose acceptance is `[judgment]` is not a task; its criterion routes to a human checkpoint.
- Every task characterizes itself for the executor: `Shape:` (auto, or human with its reason), `Type:` (one of code-feature, code-fix, code-review, test-hardening, docs, research, probe, data-pipeline, format-conversion), an optional `Model:` pin of one token, and `Decisions:` naming the decision log IDs it implements, or none.
  The executor maps the type to a model; a `Model:` pin overrides that mapping and is for a task whose type does not say enough.
- Every task lists its **Edge inputs:** the empty, malformed, and boundary inputs its tests must feed, as bullets, or `none (<reason>)` on the header line.

**The Rubix pass.**
Named for a Rubik's cube: the same object re-oriented shows faces the builder stopped seeing.
The review lives in its own skill; this step decides whether to call it on the skeleton, then triages what it returns for the round.

Read `rubix-autorun` from `docs/loop/pointer.md` (default `ask` when the key is absent).

**Probe.** Check whether a skill named `rubix-review` is available in this session.
**Present:** offer the optional two-lens Rubix review of the skeleton, gated by the `rubix-autorun:` key in `docs/loop/pointer.md` (`ask` when the key is absent).
**Absent:** continue without it.
**Disclose:** say in one line "the optional Rubix review skill is not installed in this session; continuing without it."

**If the rubix-review skill is available:**

- `ask` - offer the review once, as its own message, after the skeleton is written, in exactly these words:
  > "Skeleton written. Want the Rubix review? The rubix-review skill sends fresh-context reviewers - one reads it as a professional downstream of the artifact, one gives it a cold best-practice read. Findings with rationale, you pick what gets in."
  Decline means proceed to Step 3; do not offer again.
- `on` - invoke rubix-review on the skeleton without asking.
- `off` - skip silently; proceed to Step 3, where the round still happens.

On acceptance (or auto), invoke the rubix-review skill on the plan file holding the skeleton, then triage its findings as below.

**If the rubix-review skill is not available:** the optional Rubix review skill is not installed in this session; continuing without it.
Warn once per context, never per plan, and fall back to Step 3 directly - never a hard failure.
This is the soft, optional review being skipped, unlike the reviewer-conduct contract, which is a required co-install that fails closed.

**Triage.** Record your own verdict - revise or no - with a one-line reason for every finding; none applied silently or dismissed without a written reason.
Build one table: finding, lens, severity, reviewer rationale (condensed), your verdict.
The table is kept for the round: the user picks which findings get incorporated there, in one question, and you revise the skeleton with the picks.

## Step 3 - The one question round`[gate:ASK]`

The round is the plan stage's one card, at its front.
Facts are your job (explore, don't ask); only decisions go to the user.

**What goes on it, in one round only:**

- every open question of the brief that its `Resolved assumptions` section does not answer (a brief with no such section puts every open question here);
- the Rubix findings as one multiSelect pick, when the pass ran;
- every planner decision that is not a routine default.

The round fits one card: at most 4 questions, the Rubix pick counting as one.
Rank the candidates by how much of the plan a wrong answer would undo, ask the top ones, and take everything beyond the fourth as a marked default.
A round with nothing on it is not asked.

**Dispatched sessions.** Before the first ask or wait for a human in this skill, run `m="$(git rev-parse --path-format=absolute --git-path jrit-loop-dispatched 2>/dev/null)" && test -f "$m" && b="$(git branch --show-current)" && test -n "$b" && test "$(cat "$m")" = "$b"`.
On any nonzero exit, ask exactly as this skill says and print nothing about the test.
On exit 0, follow the loop-auto skill's "Dispatched sessions" section for every ask in this run.

Present the round through one AskUserQuestion call (or as one plain-text round under the dispatched marker), 2-4 concrete options each, your recommendation first.
One decision per question: a scope narrowing (or any second decision) never rides inside an option's description - it gets its own question, and under autonomy scope narrowing is ASK-class, never auto-taken.
None may be silently carried into the plan; an unanswered question in a task is a placeholder.

After this round the plan asks nothing more: every later choice is taken as a default and written as NEEDS HUMAN CONFIRMATION in the decision log.
Every answer and every default gets an ID in the plan's decision log, with its source (human or default); each task's `Decisions:` line cites those IDs.

## Step 4 - The plan review (optional)`[gate:ASK]`

A pause between the settled round and the task bodies: one page shows the shape of the work, and the human approves it before any task body is written.
The page asks no new question: its open decisions are the defaults already marked NEEDS HUMAN CONFIRMATION, and its verdict approves the shape or sends notes.
The page is for the reviewer; its record is for the plan writer.
The section contract for both, the answer block, and the renderer choice live in `references/plan-review.md`; read it in full when this step runs and follow it rather than summarizing it from memory.

Read `plan-review` from `docs/loop/pointer.md` (default `ask` when the key is absent).

- `ask` - after the question round, offer the review once, as its own message:
  > "Questions settled. Want the plan review page before the plan draft? One page: where the changes land, the flow with one figure per load-bearing decision, the open decisions, what the shape assumes, the parking lot, and what happens next. You approve the shape, then the plan gets written."
  Decline means proceed to Step 5; do not offer again.
- `on` - build the page without asking.
- `off` - skip silently; proceed to Step 5.

**Build.**
Write the record first, then the page from it, both at `<reviews-home>/YYYY-MM-DD.<tokens>.<topic>-plan-review.md` and `.html`, where `reviews-home:` is read from `docs/loop/pointer.md` (default `docs/reviews/`) and the token rule is the one in Step 2.
Every decision taken so far, by the human in the round or by you as a default, carries its decision log ID in the record; a default is marked reversible.
Every load-bearing claim is binned verified, believed, or guessed, with its source.

**Render.**
**Probe.** Check whether a skill named `lavish` is available in this session.
**Present:** render the page through lavish, hand it the brand pack and doctype when either was named, and collect the answers through lavish's own feedback channel.
**Absent:** write the page from `references/plan-review-template.html`, tell the human the path to open in a browser, and collect the answers from the page's copy-answers block pasted into the conversation.
**Disclose:** say in one line "the optional lavish renderer is not installed in this session; the plan review page is plain HTML at <path>."
The brand pack and doctype come from `brand=<slug>` and `doctype=<slug>` named when loop-plan is invoked, else from the optional pointer keys `plan-review-brand:` and `plan-review-doctype:`, else none; the plain page has neither and says so in one line when either was named.

**Review.**
Stop and wait for the verdict; this is an ASK gate, so autonomy never takes it, and under `auto` it is the last ASK before autonomy takes effect.
"Changes needed" means fold the notes into the record and the skeleton, rebuild the page, and ask again; a second round catches what only shows in the full picture.
"Approved" means append the answers and the verdict to the record and proceed to Step 5.
In a dispatched session, write both files, print the page path and the open decisions as the plain-text round, and end the turn.

## Step 5 - Write the task bodies and tests

**Dispatch.**
A fresh-context dispatch at the plan-draft role pin bundles the task bodies, the tests, and the self-review (Steps 5-6); that writer holds only the brief, the codebase, the skeleton, and the plan review record when one exists, never this conversation.
The driving session then reviews the dependency graph against the conversation for depends-on edges a fresh writer could not infer.
The plan-draft role pin's model lives in the Role pins table of loop-drive's routing reference (the loop-drive skill's references/model-benchmarks.md), its single home; cite it by role name everywhere else.

Follow the user's global markdown style instructions already loaded in this session's context, when any exist.
When a global constraint is a style rule (sentence-per-line, dash, or table style), scope it to human-read deliverables and name the exemption in the constraint line: machine-read run artifacts - resume pointers, worker result files, structured logs - are exempt.

**Header, in order:**

```markdown
# <Topic> Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes.
> No specific tooling, harness, or skills are assumed.

**Goal:** one sentence.
**Approach:** 2-3 sentences, from the brief's chosen approach and rationale.
**Tech stack:** key technologies.
**Source brief:** path, if one exists.
**Plan review:** path of the plan review record, if one exists; the plan's decisions cite its IDs.

## Decision log
A table: ID | Decision | Source, one row per answer from the round and per default, every default marked NEEDS HUMAN CONFIRMATION.

## Global constraints
The project-wide requirements, one line each, exact values verbatim.

## Dependency graph
Text sketch of task-level depends-on relations (which tasks can run in parallel, which gate).

## Human checkpoints
Where the executor stops and asks a human.
Every [judgment] criterion from the brief lands here, never on a task.

## Run shape
The table Step 7 pastes, never hand-written.

## How to run
The build/test/setup commands the whole plan assumes, exact and paste-able.

## Tasks
One section per task, in the template below.

## Shared tests
One "### Shared test: <path>" entry per checkable global constraint, each with its one path= block.
```

**Task template:**

~~~~markdown
### Task N: <component>

Depends on: Task 2, Task 3 (or: none)
Shape: auto (or: human, <why>)
Type: code-feature
Model: opus (optional pin; omitted means the executor's routing)
Decisions: D1, D4 (or: none)

**Files (exclusive ownership):**
- Create: `exact/path`
- Modify: `exact/path:123-145`
- Test: `tests/exact/path`

**Interfaces:** ...

**Edge inputs:**
- <an input the tests must feed: empty, malformed, boundary>

**Acceptance check:** `<command>` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test

```bash path=tests/exact/path
...
```
~~~~

After Step 1, every task carries the same remaining steps: run the test with the exact command and the expected FAIL, implement against the contract in Interfaces, run the acceptance check with the expected PASS, and commit with exact `git add`/`git commit` lines.

**Test blocks.**
A test block opens its fence with `path=<repo-relative path>` in the info string, plus an optional `mode=append` or `mode=replace`.
The path sits under `tests/`, `test/`, or `spec/`; a block without a mode writes a new file, `mode=append` adds a fragment to an existing one, and only `mode=replace` may replace a tracked file.
Every `Test:` bullet and every `## Shared tests` entry has exactly one tagged block.

**Code policy.**
Test code appears verbatim, always; the tests are the spec's teeth.
Implementation code appears only when the exact code IS the decision (a subtle algorithm, a tricky migration); otherwise the contract - signatures, behavior notes, edge cases - is the spec.
A capable implementer writes better code at execution time than a plan can pre-write; embedded implementations bloat the plan and pre-decide what the worker should own.

**No placeholders.**
These are plan failures, never written:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "handle edge cases" (name the errors and edges, or cut the line)
- "Write tests for the above" without the actual test code
- "Similar to Task N" (repeat it; tasks are read out of order)
- References to types or functions no task defines
- A skill, plugin, or harness-specific instruction the executor may not have

## Step 6 - Self-review and lint

Look at the written plan with fresh eyes and fix inline:

1. **Brief coverage** - every success criterion maps to a task's acceptance check or a human checkpoint; list gaps and fix them.
2. **Placeholder scan** - the list above, plus empty sections.
3. **Type consistency** - names and signatures in later tasks match what earlier tasks defined.
4. **Loop-drive contract check** - per task: scope stated, acceptance check executed not judged, ownership exclusive, depends-on complete, readable in isolation.
   Parallel-eligible tasks (no path between them) touch disjoint files.
5. **Agnosticism scan** - the plan survives an executor who has never heard of this toolchain; no skill names, no harness features.
6. **Decision coverage** - every choice made after the round is a decision log row marked NEEDS HUMAN CONFIRMATION, and every `Decisions:` ID is a row of the log.

Then run the lint: `python3 scripts/plan_lint.py lint <plan>`, with the script path resolved relative to this skill's directory, not the repo.
It checks every task field, the decision IDs, the edge inputs, placeholders, depends-on cycles, ownership overlap between parallel tasks, the test blocks, and the Run shape table.
The lint compares the Run shape section with the run-table output, so paste that table as Step 7 says before the lint's first run.
A plan the lint rejects is not written yet.
Fix every problem it prints and re-run it until it exits 0.

## Step 7 - Run shape

Run `python3 scripts/plan_lint.py run-table <plan>`, resolved the same way, and paste its output verbatim under `## Run shape`.
Wave comes from `Depends on:`: a task with none is wave 1, any other is one past the highest wave among its dependencies.
Shape is auto (executed acceptance check, files disjoint from its wave-mates) or human (irreversible or outward-facing: a push, deploy, publish, send, or delete of something a person owns), and a human shape carries its reason on the task's `Shape:` line.
Never edit the table by hand: change the task's line, re-run the command, re-paste, and re-run the lint.

## Step 8 - User review gate`[gate:DEFAULT]`

Print the plan's Run shape table first, so the auto/human split is reviewed while the plan is fresh; the user may flip any task's shape, and each flip is written into that task's `Shape:` line with its reason and the table re-run, so it is not re-litigated downstream.
Under autonomy the derived shapes stand and are journaled.
Tell the user where the plan was written, invite review and revisions, and offer the commit (phrasing yours); wait for the response.
Changes requested means edit and re-run the self-review and the lint.
Under pause, never commit without the offer being accepted; under autonomy the accepted offer is the declared default, and Step 9 commits.

## Step 9 - Exit by loop-auto (pinned)`[gate:DEFAULT]`

Read the effective autonomy mode as loop-auto defines it.

**No brief.** When the work is named by tracker issue `#<n>` and no committed brief exists for it, the exit says `no brief for #<n>; run loop-brainstorm first` and ends; nothing is planned.

**The chain launcher.** The start command is `bash "${JRIT_CORE_ROOT:-$HOME/repos/jrit/jrit-core}/scripts/chain-start.sh" <repo> <issue> --from drive --branch <branch>`, where `<repo>` is this repo's root, `<issue>` the tracker issue the plan belongs to, and `<branch>` the branch the plan is committed on.
Check whether that `chain-start.sh` exists at that path; when it does not, or the plan belongs to no tracker issue, every exit below takes the plain hand-off instead of the command.

**Dispatched.** Run the dispatched-sessions test from Step 3.
A dispatched session commits the plan and ends; it never starts a chain.
The host that dispatched it starts the next stage.

**Pause.** Name the approved plan's path and print the start command, without running it.
Without the launcher, close with the plain hand-off: name the routes onward, **/loop-drive** - its front-door triage answers the run-shape verdict ("is this worth automating / how should I run this plan", the One-Minute Test for a plan in hand) and then drives it - execution by hand or with any agent, or stopping here - the plan stands alone either way.
The user chooses the route; under pause loop-plan never invokes the next skill unprompted and never begins execution.

**Auto, in an interactive session.** Commit the plan, push its branch, run the start command, and print the run id it returns.
Without the launcher, commit the plan and close with the plain hand-off.

The only files loop-plan creates are the plan, the plan review page and its record, and their revisions.
