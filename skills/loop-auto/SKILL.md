---
name: loop-auto
description: Set or check the chain autonomy knob (/loop-auto), and the home of the four gate classes (ASK, STOP, BATCH, DEFAULT) and the batch-review journal format. Turns a run from human-gated (pause) to autonomous (auto); the repo default is the autonomy-default key in docs/loop/pointer.md, and a session may override it in conversation. Triggers on 'run the rest', 'take it from here', 'go autonomous', 'auto mode', 'full auto'.
---

# loop-auto

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

The autonomy knob for the chain.
Two modes: `pause` (the unset default - every gate fires live, the human is asked at each ASK) and `auto` (after the last ASK gate passes, the session runs the rest of the chain without further prompts).

## What it does

The mode has one durable home: the `autonomy-default:` key in the target repo's `docs/loop/pointer.md` (`pause` or `auto`; `pause` when the key is absent).
Checking the knob is reading that key; setting it for this run is a session override held in conversation only, never written to any file.
Changing the repo default itself is an edit to the `autonomy-default:` key in `docs/loop/pointer.md`, staged and committed like any tracked change.
Setting the mode always ends with a one-line confirmation of the new mode; it is never silent.

## Consumption is live

Consumption is live: the knob now governs gate behavior per the four gate classes below.
Setting the mode acts on this run, not on a future build wave.
This skill is the single home of the autonomy protocol; the managed CLAUDE.md block only points here.

### Knob off or unset

Fully human-gated: every gate fires live, nothing auto-taken - every ASK, STOP, BATCH, and DEFAULT surfaces to the human.

### When autonomy takes effect

Only after the last ASK gate passes. Up to and including that gate the human is in the loop; after it, the active session orchestrates the rest of the chain under the rules below.

A mode change never retroactively answers a question already asked.
When the knob flips to `auto` mid-session, any offer or choice already on the table - an unaccepted commit offer, a pending route choice - stays the human's to resolve; setting the mode does not convert it into a DEFAULT take.
On `set auto` the session first presents one consolidated ASK - `outstanding before autonomy commences: X, Y, Z - take all / pick / none` - resolves it, and only then does autonomy govern the rest of the chain.

### The four gate classes under autonomy

- ASK always blocks.
  It asks the human and waits; autonomy does not auto-answer an ASK.
  Offers and questions already pending at the moment `auto` is set are ASK-class too: setting the mode never converts them to DEFAULT takes (see "When autonomy takes effect").
- STOP always halts and states what it needs.
  A STOP names the missing input or the failing invariant (dirty tree, exceeded effort cap, outward-facing unit) and waits; autonomy never auto-resolves a STOP.
- BATCH auto-takes the named lean, proceeds, and collects the decision for the end review.
  The lean was already named in the gate's prose; autonomy takes it, records it, and moves on.
- DEFAULT auto-takes the default and logs verbosely.
  The default was already declared at the gate; autonomy takes it, logs the decision in full, and moves on.

Scope narrowing is ASK-class by definition: a decision that narrows the requested scope is never a BATCH lean or a DEFAULT take, wherever inside a step it arises.
Narrowing is sometimes right, but it is never silent and never auto-taken - it surfaces as its own explicit question.

### Batch-review list format

The batch-review list is the run's gate journal: it is created the moment autonomy takes effect and appended at every gate as it fires, in chronological order, so a run that dies mid-chain still leaves the record of every decision taken so far.
This journal is a protocol-authored file, so it is committed by the pre-flight journal-commit step before the rest of pre-flight runs, using the commit-message grammar `Journal #N: <imperative>` (for example `Journal #19: open the gate journal before pre-flight`) and dropping the `#N` segment when the tracker item is unlogged.
Its later per-gate appends are committed with each gate's own commit, so the run's own journal is never the uncommitted dirt the dirty-tree STOP would otherwise trip on.
The list home is `<reviews-home>/YYYY-MM-DD.<tokens>.<slug>-batch-review.md`, where `reviews-home:` is read from `docs/loop/pointer.md` (default `docs/reviews/`).
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.
All four gate classes are logged, but they carry two different obligations.
ASK and STOP entries are record-only: the human was present for them, so they preserve the chronology and the context around neighboring decisions but need no review.
BATCH and DEFAULT entries are the review obligation: each is a decision auto-taken for the human, to accept or reverse at the end-of-chain checkpoint.
Each entry has three fields: the decision (for record-only entries, what was asked or halted and how the human resolved it), the rationale, and a reversal path (record-only entries mark it `n/a - resolved live`).
The reversal is named honestly by gate type: a DEFAULT or commit reversal is cheap (`git revert`, or undoing the default next pass); a BATCH taste reversal (topology, triage) is a scoped re-run with the alternate lean, since the lean was a judgment, not a fact.
An entry with no honest reversal path should have been a STOP, not auto-taken.

### Continuation rule

The session active when autonomy takes effect orchestrates the rest of the chain.
Delegation only goes down-tier - the orchestrator hands work to sonnet, opus, or haiku workers, or to ringer-transported GLM/codex.
Nobody ever spawns Fable.
Fable is orchestrator-tier only and never a worker, so the autonomy continuation never delegates to it, not even under full auto.

## Per-repo default

The committed per-repo default is the line-anchored `autonomy-default:` key in `docs/loop/pointer.md`.
The effective mode is the session override when one is active, else that key, else `pause`.
Report the effective mode with its source, for example `mode: auto (repo default)` or `mode: pause (session override)`.

## Recognized phrases

Any of these phrases sets the knob to `auto` with a one-line confirmation:

- "run the rest"
- "run the rest from here"
- "take it from here"
- "go autonomous"
- "auto mode"
- "full auto"

Recognizing a phrase does not skip the confirmation.
The human always sees the new mode in the same turn.

## Where it lives

The durable mode is the `autonomy-default:` key in `docs/loop/pointer.md`; a session override lives in conversation only.
Do not shadow either in a plan artifact or anywhere else a later session would mistake for the source of truth.
