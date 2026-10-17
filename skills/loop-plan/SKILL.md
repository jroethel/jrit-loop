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
/loop-brainstorm ──> brief ──> /loop-plan (+ optional plan review page) ──> plan (+ optional Rubix review via the rubix-review skill) ──> /loop-drive
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
2. **Resolve open questions** - the brief's planning questions get answered here, not carried
3. **Optional plan review** - one page of the shape, approved before any task-level planning is spent
4. **Decompose** - file map, task boundaries, dependency graph, ownership
5. **Write the plan file** - `<plans-home>/YYYY-MM-DD.<tokens>.<topic>-plan.md`, where `plans-home:` is read from `docs/loop/pointer.md` (default `docs/plans/`)
6. **Self-review** - including the loop-drive contract check, fixed inline
7. **Optional Rubix review** - soft-checked call to the rubix-review skill
8. **User reviews the plan** - and gets offered the commit
9. **Hand off** - pinned options, then stop

## Step 1 - Ingest

The normal input is a loop-brainstorm brief (`docs/briefs/`): outcome, success criteria with `[executed-check]`/`[judgment]` tags, seams, assets, known-vs-guessed, and open questions for planning.
Without a brief, accept any spec or requirements, but first run a condensed intake (outcome, what done looks like, checkable criteria) - do not plan against a vibe.
Explore the codebase the plan will land in; follow its existing patterns rather than restructuring around them.

## Step 2 - Resolve the open questions`[gate:ASK]`

The brief's "Open questions for planning" section is this skill's first workload.
Each question gets answered by your codebase exploration, decided in the plan header, or asked of the user.
Ask user questions in frontier rounds, not one per message: batch every question whose prerequisites are settled into one numbered round, wait for the answers, then recompute - a question that depends on another still open this round waits for the next round.
Facts are your job (explore, don't ask); only decisions go to the user.

**Dispatched sessions.** Before the first ask or wait for a human in this skill, run `m="$(git rev-parse --path-format=absolute --git-path jrit-loop-dispatched 2>/dev/null)" && test -f "$m" && b="$(git branch --show-current)" && test -n "$b" && test "$(cat "$m")" = "$b"`.
On any nonzero exit, ask exactly as this skill says and print nothing about the test.
On exit 0, follow the loop-auto skill's "Dispatched sessions" section for every ask in this run.

Present each round through AskUserQuestion (up to 4 questions per call), 2-4 concrete options each, your recommendation first.
One decision per question: a scope narrowing (or any second decision) never rides inside an option's description - it gets its own question, and under autonomy scope narrowing is ASK-class, never auto-taken.
None may be silently carried into the plan; an unanswered question in a task is a placeholder.

## Step 3 - The plan review (optional)`[gate:ASK]`

A pause between the settled questions and the plan draft: one page shows the shape of the work, and the human approves it before any task-level planning is spent.
The page is for the reviewer; its record is for the plan writer.
The section contract for both, the answer block, and the renderer choice live in `references/plan-review.md`; read it in full when this step runs and follow it rather than summarizing it from memory.

Read `plan-review` from `docs/loop/pointer.md` (default `ask` when the key is absent).

- `ask` - after the last question round, offer the review once, as its own message:
  > "Questions settled. Want the plan review page before the plan draft? One page: where the changes land, the flow with one figure per load-bearing decision, the open decisions, what the shape assumes, the parking lot, and what happens next. You approve the shape, then the plan gets written."
  Decline means proceed to Step 4; do not offer again.
- `on` - build the page without asking.
- `off` - skip silently; proceed to Step 4.

**Build.**
Write the record first, then the page from it, both at `<reviews-home>/YYYY-MM-DD.<tokens>.<topic>-plan-review.md` and `.html`, where `reviews-home:` is read from `docs/loop/pointer.md` (default `docs/reviews/`) and the token rule is the one in Step 5.
Every decision taken so far, by the human in a round or by you as a default, gets an ID in the record's decision log; a default is marked reversible.
Every load-bearing claim is binned verified, believed, or guessed, with its source.

**Render.**
**Probe.** Check whether a skill named `lavish` is available in this session.
**Present:** render the page through lavish, hand it the brand pack and doctype when either was named, and collect the answers through lavish's own feedback channel.
**Absent:** write the page from `references/plan-review-template.html`, tell the human the path to open in a browser, and collect the answers from the page's copy-answers block pasted into the conversation.
**Disclose:** say in one line "the optional lavish renderer is not installed in this session; the plan review page is plain HTML at <path>."
The brand pack and doctype come from `brand=<slug>` and `doctype=<slug>` named when loop-plan is invoked, else from the optional pointer keys `plan-review-brand:` and `plan-review-doctype:`, else none; the plain page has neither and says so in one line when either was named.

**Review.**
Stop and wait for the verdict; this is an ASK gate, so autonomy never takes it, and under `auto` it is the last ASK before autonomy takes effect.
"Changes needed" means fold the notes into the record, rebuild the page, and ask again; a second round catches what only shows in the full picture.
"Approved" means append the answers and the verdict to the record and proceed to Step 4.
In a dispatched session, write both files, print the page path and the open decisions as the plain-text round, and end the turn.

## Step 4 - Decompose

**Dispatch.**
A fresh-context dispatch at the plan-draft role pin bundles decompose + draft + self-review (Steps 4-6); that writer holds only the brief, the codebase, and the plan review record when one exists, never this conversation.
The driving session then reviews the dependency graph against the conversation for depends-on edges a fresh writer could not infer.
The plan-draft role pin's model lives in the Role pins table of loop-drive's routing reference (the loop-drive skill's references/model-benchmarks.md), its single home; cite it by role name everywhere else.

**File structure first.**
Map which files will be created or modified and what each is responsible for; this is where decomposition gets locked in.
Prefer small files with one clear responsibility; in existing codebases, follow the established pattern.

**Task right-sizing.**
A task is the smallest unit that carries its own test cycle and is worth a fresh reviewer's gate.
Fold setup, config, and docs into the task whose deliverable needs them; split only where a reviewer could reject one task while approving its neighbor.
The brief's seams are candidate task boundaries; deviations from them get a recorded reason.

**Prefactor rule.**
Restructuring that must precede a change is called out as its own earlier task or step, so it never rides inside a feature task.
For a wide refactor, expand-contract is the reference pattern: land the new structure, migrate callers, then remove the old.

**Loop-aware structure (the delta from a human-paced plan):**

- Every task declares `Depends on:` explicitly, even "none". Waves are derived from these; a missing edge is a race condition.
- Every task's file list is exclusive ownership. Two tasks touching one file must be dependent, never parallel; a shared file is a boundary error, redraw it.
- Every task ends in an acceptance check: one command, its expected pass condition, tagged `[executed-check]`. A task whose acceptance is `[judgment]` is not a task; its criterion routes to a human checkpoint.

## Step 5 - Write the plan file

Save to `<plans-home>/YYYY-MM-DD.<tokens>.<topic>-plan.md`, where `<plans-home>` is the `plans-home:` key from `docs/loop/pointer.md`, defaulting to `docs/plans/` when the key is absent.
Follow the user's global markdown style instructions already loaded in this session's context, when any exist.
When a global constraint is a style rule (sentence-per-line, dash, or table style), scope it to human-read deliverables and name the exemption in the constraint line: machine-read run artifacts - resume pointers, worker result files, structured logs - are exempt.
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.

**Header, in order:**

```markdown
# <Topic> Implementation Plan

> For executors: tasks use checkbox syntax; execute in dependency order; a task is done when its
> acceptance check passes. No specific tooling, harness, or skills are assumed.

**Goal:** one sentence.
**Approach:** 2-3 sentences, from the brief's chosen approach and rationale.
**Tech stack:** key technologies.
**Source brief:** path, if one exists.
**Plan review:** path of the plan review record, if one exists; the plan's decisions cite its IDs.

## Global constraints
The project-wide requirements, one line each, exact values verbatim.

## Dependency graph
Text sketch of task-level depends-on relations (which tasks can run in parallel, which gate).

## Human checkpoints
Where the executor stops and asks a human.
Every [judgment] criterion from the brief lands here, never on a task.

## Run shape
A table, one row per task: Wave | Task | Shape | Why.
Wave comes from Depends-on: a task with none is wave 1, any other is one past the highest wave among its dependencies.
Shape is auto (executed acceptance check, files disjoint from its wave-mates) or human (irreversible or outward-facing: a push, deploy, publish, send, or delete of something a person owns).

## How to run
The build/test/setup commands the whole plan assumes, exact and paste-able.
```

**Task template:**

````markdown
### Task N: <component>

Depends on: Task 2, Task 3 (or: none)

**Files (exclusive ownership):**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test_file.py`

**Interfaces:**
- Consumes: exact signatures this task uses from earlier tasks
- Produces: exact names, parameters, and return types later tasks rely on
  (an executor may see only this one task; this block is how neighbors' names reach them)

**Acceptance check:** `pytest tests/exact/path/to/test_file.py -v` exits 0 `[executed-check]`

- [ ] Step 1: Write the failing test (verbatim test code block)
- [ ] Step 2: Run it - exact command, expected FAIL with <message>
- [ ] Step 3: Implement against the contract in Interfaces
- [ ] Step 4: Run it - exact command, expected PASS
- [ ] Step 5: Commit - exact `git add`/`git commit` lines
````

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

## Step 6 - Self-review

Look at the written plan with fresh eyes and fix inline:

1. **Brief coverage** - every success criterion maps to a task's acceptance check or a human checkpoint; list gaps and fix them.
2. **Placeholder scan** - the list above, plus empty sections.
3. **Type consistency** - names and signatures in later tasks match what earlier tasks defined.
4. **Loop-drive contract check** - per task: scope stated, acceptance check executed not judged, ownership exclusive, depends-on complete, readable in isolation. Parallel-eligible tasks (no path between them) touch disjoint files.
5. **Agnosticism scan** - the plan survives an executor who has never heard of this toolchain; no skill names, no harness features.
6. **Run shape** - every task appears exactly once, each wave matches the task's Depends-on edges, and every human row says why.

## Step 7 - The Rubix review (optional)`[gate:DEFAULT]`

Named for a Rubik's cube: the same object re-oriented shows faces the builder stopped seeing.
The review now lives in its own skill; this step decides whether to call it, then folds in what it returns.

Read `rubix-autorun` from `docs/loop/pointer.md` (default `ask` when the key is absent).

**Probe.** Check whether a skill named `rubix-review` is available in this session.
**Present:** offer the optional two-lens Rubix review of the drafted artifact, gated by the `rubix-autorun:` key in `docs/loop/pointer.md` (`ask` when the key is absent).
**Absent:** continue without it.
**Disclose:** say in one line "the optional Rubix review skill is not installed in this session; continuing without it."

**If the rubix-review skill is available:**

- `ask` - offer the review once, as its own message, after self-review passes:
  > "Plan written. Want the Rubix review? The rubix-review skill sends fresh-context reviewers - one reads it as a professional downstream of the artifact, one gives it a cold best-practice read. Findings with rationale, you pick what gets in."
  Decline means proceed to Step 8; do not offer again.
- `on` - invoke rubix-review on the plan file without asking.
- `off` - skip silently; proceed to Step 8.

On acceptance (or auto), invoke the rubix-review skill on the plan file, then triage its findings as below.

**If the rubix-review skill is not available:** the optional Rubix review skill is not installed in this session; continuing without it.
Warn once per context, never per plan, and fall back to Step 8 directly - never a hard failure.
This is the soft, optional review being skipped, unlike the reviewer-conduct contract, which is a required co-install that fails closed.

**Triage.** Record your own verdict - revise or no - with a one-line reason for every finding; none applied silently or dismissed without a written reason. Present one table: finding, lens, severity, reviewer rationale (condensed), your verdict. The user picks which get incorporated; revise; re-run Step 6.`[gate:BATCH]`

## Step 8 - User review gate`[gate:DEFAULT]`

Print the plan's Run shape table first, so the auto/human split is reviewed while the plan is fresh; the user may flip any task's shape, and each flip is written into the Run shape section with its reason so it is not re-litigated downstream.
Under autonomy the derived shapes stand and are journaled.
Tell the user where the plan was written, invite review and revisions, and offer the commit (phrasing yours); wait for the response.
Changes requested means edit and re-run the self-review. Never commit without the offer being accepted.

## Step 9 - Hand off (pinned)`[gate:DEFAULT]`

Close by naming the approved plan's path and the routes onward: **/loop-drive** - its front-door triage answers the run-shape verdict ("is this worth automating / how should I run this plan", the One-Minute Test for a plan in hand) and then drives it - execution by hand or with any agent, or stopping here - the plan stands alone either way.

The user chooses the route; loop-plan never invokes the next skill unprompted and never begins execution.
The only files it creates are the plan and its revisions.

