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
/loop-brainstorm ──> brief ──> /loop-plan ──> plan (+ optional Rubix review via the rubix-review skill) ──> /loop-drive
```

Loop work downstream consumes what is set here: explicit depends-on relations become waves, exclusive file ownership makes parallelism safe, and executed acceptance checks are /loop-drive's hard gate (P6: a unit belongs on a worker only if checking is cheaper than producing).

<HARD-GATE>
Do not write implementation code, scaffold anything, or invoke any implementation skill.
The only files you create are the plan and its revisions.
Test code embedded in the plan document is plan content, not implementation.
</HARD-GATE>

## Checklist

Create a task for each item and complete them in order:

1. **Ingest** - read the brief and everything it points to; explore the codebase
2. **Resolve open questions** - the brief's planning questions get answered here, not carried
3. **Decompose** - file map, task boundaries, dependency graph, ownership
4. **Write the plan file** - `<plans-home>/YYYY-MM-DD.<tokens>.<topic>-plan.md`, where `plans-home:` is read from `docs/loop/pointer.md` (default `docs/plans/`)
5. **Self-review** - including the loop-drive contract check, fixed inline
6. **Optional Rubix review** - soft-checked call to the rubix-review skill
7. **User reviews the plan** - and gets offered the commit
8. **Hand off** - pinned options, then stop

## Step 1 - Ingest

The normal input is a loop-brainstorm brief (`docs/briefs/`): outcome, success criteria with `[executed-check]`/`[judgment]` tags, seams, assets, known-vs-guessed, and open questions for planning.
Without a brief, accept any spec or requirements, but first run a condensed intake (outcome, what done looks like, checkable criteria) - do not plan against a vibe.
Explore the codebase the plan will land in; follow its existing patterns rather than restructuring around them.

## Step 2 - Resolve the open questions`[gate:ASK]`

The brief's "Open questions for planning" section is this skill's first workload.
Each question gets answered by your codebase exploration, decided in the plan header, or asked of the user.
Ask user questions in frontier rounds, not one per message: batch every question whose prerequisites are settled into one numbered round, wait for the answers, then recompute - a question that depends on another still open this round waits for the next round.
Facts are your job (explore, don't ask); only decisions go to the user.

Present each round through AskUserQuestion (up to 4 questions per call), 2-4 concrete options each, your recommendation first.
One decision per question: a scope narrowing (or any second decision) never rides inside an option's description - it gets its own question, and under autonomy scope narrowing is ASK-class, never auto-taken.
None may be silently carried into the plan; an unanswered question in a task is a placeholder.

## Step 3 - Decompose

**Dispatch.**
A fresh-context dispatch at the plan-draft role pin bundles decompose + draft + self-review (Steps 3-5); that writer holds only the brief and the codebase, never this conversation.
The driving session then reviews the dependency graph against the conversation for depends-on edges a fresh writer could not infer.
The plan-draft role pin resolves to Opus (this line is the pin's single home); cite it by role name everywhere else.

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

## Step 4 - Write the plan file

Save to `<plans-home>/YYYY-MM-DD.<tokens>.<topic>-plan.md`, where `<plans-home>` is the `plans-home:` key from `docs/loop/pointer.md`, defaulting to `docs/plans/` when the key is absent.
Follow the user's global markdown style instructions already loaded in this session's context, when any exist.
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

## Global constraints
The project-wide requirements, one line each, exact values verbatim.

## Dependency graph
Text sketch of task-level depends-on relations (which tasks can run in parallel, which gate).

## Human checkpoints
Where the executor stops and asks a human.
Every [judgment] criterion from the brief lands here, never on a task.

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

## Step 5 - Self-review

Look at the written plan with fresh eyes and fix inline:

1. **Brief coverage** - every success criterion maps to a task's acceptance check or a human checkpoint; list gaps and fix them.
2. **Placeholder scan** - the list above, plus empty sections.
3. **Type consistency** - names and signatures in later tasks match what earlier tasks defined.
4. **Loop-drive contract check** - per task: scope stated, acceptance check executed not judged, ownership exclusive, depends-on complete, readable in isolation. Parallel-eligible tasks (no path between them) touch disjoint files.
5. **Agnosticism scan** - the plan survives an executor who has never heard of this toolchain; no skill names, no harness features.

## Step 6 - The Rubix review (optional)`[gate:DEFAULT]`

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
  Decline means proceed to Step 7; do not offer again.
- `on` - invoke rubix-review on the plan file without asking.
- `off` - skip silently; proceed to Step 7.

On acceptance (or auto), invoke the rubix-review skill on the plan file, then triage its findings as below.

**If the rubix-review skill is not available:** the optional Rubix review is unavailable (rubix-review not installed); continuing without it.
Warn once per context, never per plan, and fall back to Step 7 directly - never a hard failure.
This is the soft, optional review being skipped, unlike the reviewer-conduct contract, which is a required co-install that fails closed.

**Triage.** Record your own verdict - revise or no - with a one-line reason for every finding; none applied silently or dismissed without a written reason. Present one table: finding, lens, severity, reviewer rationale (condensed), your verdict. The user picks which get incorporated; revise; re-run Step 5.`[gate:BATCH]`

## Step 7 - User review gate`[gate:DEFAULT]`

Tell the user where the plan was written, invite review and revisions, and offer the commit (phrasing yours); wait for the response.
Changes requested means edit and re-run the self-review. Never commit without the offer being accepted.

## Step 8 - Hand off (pinned)`[gate:DEFAULT]`

Close by naming the approved plan's path and the routes onward: **/loop-drive** - its front-door triage answers the run-shape verdict ("is this worth automating / how should I run this plan", the One-Minute Test for a plan in hand) and then drives it - execution by hand or with any agent, or stopping here - the plan stands alone either way.

The user chooses the route; loop-plan never invokes the next skill unprompted and never begins execution.
The only files it creates are the plan and its revisions.

