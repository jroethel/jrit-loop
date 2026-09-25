# Harness-Drift Audit (the "molt" protocol)

This copy is canonical and self-contained; it has no upstream source file.

Distilled 2026-08-15 from the loop-stack-vs-research evaluation session.
Purpose: a repeatable workflow for re-evaluating any skill or prose instruction against what the harness now does natively, so plumbing gets deleted and policy survives.
Applies to: SKILL.md files, CLAUDE.md blocks, operating manuals, run-books - any instruction prose an agent consumes.
"molt" has a second sense in a sibling override-pack project: sys-prompts-cc uses "molt" for realigning an override pack to a new harness version, and this protocol stays independent of that sense.

## The one-line test

Per block of prose, ask: "would the harness or the target model do this unprompted, today?"
Not "is this correct?" - correct-but-native is still deletable.
Prose describing HOW to do mechanics is suspect; prose describing WHAT MUST BE TRUE is policy.

## When to run

- After any major harness release or model generation change.
- Before extending a skill (never add prose to un-audited prose).
- On a cadence otherwise (quarterly); the 90-day research shows the harness eats plumbing roughly monthly.

## Steps

### 0. Refresh ground truth (never audit against remembered capability)

The auditing session does its own pull, in two tiers:

- **Thin refresh (default, minutes):** changelog scan plus one live probe of any load-bearing feature claim (run the command in a scratch repo). Sufficient for a single artifact.
- **Deep refresh (occasional):** a full research pull (last30days or equivalent). Warranted for a whole-stack recalibration or a model-generation change, not per artifact.

**Harness evidence.** The plumbing bin, conflicts with the harness, and premises about the harness are judged against the harness instruction corpus, the prompt set actually running: stock prompts, or the override set if one is applied.
That corpus is the Piebald prompt catalog, `https://github.com/Piebald-AI/claude-code-system-prompts`.
Read it at the catalog tag matching the running harness version, never at its head; when that tag is missing or differs from the catalog version in use, record both versions and mark dependent verdicts unverified.
The index date is the commit date of the tag for a direct read, or the semantic index's last update for an indexed read, with the indexed catalog version recorded as a second version.
A semantic index is optional and only finds paraphrase candidates, so confirm every index hit in the pinned tag.
Re-indexing changes local state, so the audit never re-indexes; it reads whatever index already exists.
A conflict with the harness is actionable only when the harness text does not already defer to the user.
Each harness-based finding cites the harness file, its version, and its index date.
With no corpus at hand, fall back to memory and mark every dependent verdict unverified.
The corpus never ships with the skill; fetch it from the catalog named above.
Which input serves which finding class is tabulated in `references/evidence.md`.

**Model evidence.** The target model's documented behavior comes from Anthropic's per-model prompting pages, named by the upstream URL pattern `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-<model>.md`.
Each page serves Markdown when .md is appended to its URL, so the notes are read as plain prose.
A page is downloaded once per model into the model-notes folder the host names, and its fetch date is the file's modification time.
Refresh is manual: the owner re-downloads a page when it changes, and the audit only reads the copy already on disk.
Only the parts about prose responses bear on the audit; API-integration mechanics such as request parameters and tool schemas are out of scope.
Each page is a delta against its predecessor, so the download follows the chain back to the model the artifact was last molted against.
A non-Anthropic worker model takes its evidence from whatever dated model log the stack keeps for it, else from memory marked unverified.
Choreography verdicts rest on the model notes, so each choreography finding cites the page it relies on and that page's fetch date.
Offline, the last download serves; with no download at all, every dependent verdict is marked unverified.

Date-stamp the snapshot; it is the evidence base and its expiry. After the first audit, the drift ledger lets the next one diff from the last snapshot instead of re-researching from zero.

### 1. Constraint register FIRST (the C1 lesson)

Before classifying anything, ask the owner which design choices are deliberate standing constraints (portability, provider mix, cost, compliance) versus historical accident.
The register also records which model will read this artifact - the target model or models - as the owner states it, never assumed.
Never classify a premise as expired without this step; this session initially misread "/workflows off" as a stale premise when it was a live portability requirement, and the reversal changed three recommendations.

### 2. Inventory

Break the artifact into blocks: each instruction, gate, enumerated step, or embedded claim is one classifiable unit.
For a skill family, also inventory duplication (the same narrative stated in N places counts once, then N-1 deletions).
The inventory looks for contradiction as well as duplication: two blocks that cannot both be true at the same time.
When the audit covers more than one file, duplication and contradiction are inventoried across the files, not only within each.
When two blocks collide, a conflicting pair goes to the owner as a constraint-register question, an ASK-class gate: molt never picks a winner between conflicting instructions.
The pairs from one run are collected and asked together once the findings are drafted, one question set per run, not one stop per pair.

### 3. Classify every block into one of four bins

| Bin          | Definition                                          | Action                        |
|--------------|-----------------------------------------------------|-------------------------------|
| PLUMBING     | Mechanics the harness now performs unprompted       | Delete, or one pointer        |
| POLICY       | Discipline the harness will not impose on its own   | Keep; sharpen to outcomes     |
| PREMISE      | An assumption about the world or the harness        | Verify by a second route      |
| CHOREOGRAPHY | Step-by-step behavior the target model does by      | Delete via subtraction test   |
|              | judgment (probe names, question cadences)           |                               |

Premise sub-rule: expired premise gets rewritten in place (never a bolted-on correction); a deliberate constraint (from step 1) gets kept AND labeled as a constraint so the next audit does not re-litigate it.

POLICY membership test, with or without a principles sheet:
if the artifact has a principles sheet (like loop-stack's P1-P14), keep = traces to a named principle.
If it has none, derive as you go: for each block classified POLICY, write the one-line invariant it protects; a block whose broken-without-it invariant cannot be named is choreography in disguise.
The owner's constraint register seeds the invariant list; the first audit's byproduct is a starter principles sheet the next audit inherits.
A principles sheet is an accelerator, never a prerequisite.
Policy examples from the source session: checks-or-stall, validator-never-fixes contracts, per-unit cost routing tables, risk-classed gates, run-state formats, check custody.
Plumbing examples: fan-out mechanics, background execution, notifications, session resume - all prose re-describing what the harness already does.

### 3b. Gap scan against the target model's behavior changes

Subtraction (step 4) catches prose the artifact should lose; the gap scan catches the opposite drift, a documented behavior change in the target model that the artifact fails to exploit.
Check the artifact against each documented behavior change in the target model's notes (the model evidence of step 0), and where the artifact ignores a change the notes describe, record a gap.
A gap becomes a proposed addition tied to a documented behavior shift, citing the model-notes version and fetch date the shift came from.
When the constraint register names more than one target model, the scan runs once per named model, and each addition names the model it targets.

A proposed addition is kept only through a reverse subtraction test, run before the addition enters the artifact.
Arm A runs the artifact as is; arm B runs the artifact plus the addition, both arms on the same one real task.
A single run per arm cannot separate improvement from run-to-run variance and must never decide the keep, so the test uses three or more runs per arm.
Every run is scored against a binary checklist tied to the named behavior shift, with the checklist written before the runs and the keep rule fixed before the runs - a stated threshold of arm B over arm A.
The pairing is deliberate: an "improves" left undefined until after the scores exist is LLM-as-judge, and the checklist may not change after the first run - anything noticed mid-test joins the next cycle's checklist, never the current one.
The drift ledger records the run count and scores per arm, the checklist, the keep rule, and the verdict.
An addition not yet reverse-tested is reported as proposed, never as kept.

### 4. Test by subtraction

Delete the block, run the artifact's existing checks plus one real task, keep the deletion if nothing degrades.
This requires the artifact to HAVE executable checks; an artifact with no checks gets a check before it gets an audit (loop-stack's gate tests are the model here).
Fallback for a checkless artifact: delete the block, run the artifact on one real task, compare output against a pre-deletion run - weaker certainty, still workable.
Per-line tiebreaker, from the research: "would removing this cause a mistake? If not, cut it."

### 5. Emit a drift ledger line (and, first time, a principles sheet)

Append to a small ledger (per artifact or per repo): date, harness snapshot version, blocks deleted by bin, blocks kept as policy, constraints re-confirmed.
On a first audit of a principles-less artifact, also emit the derived invariants as that artifact's starter principles sheet.
The next audit diffs from this known point instead of re-deriving everything.

## Expected steady state

Each audited artifact converges toward a policy sheet: constraints, contracts, thresholds, formats - riding on native mechanics.
Policy survives harness versions; plumbing has a shelf life of about one release cycle.
Convergence is net change within a band per cycle: deletions and additions roughly balancing, every addition tied to a dated model-notes version from the gap scan (step 3b); an artifact that only ever grows has never been audited.

## Where molt sits in the chain

Molt is the third audit in the family, next to /loop-improve and P10's evolve move, each on a different object: improve audits the product, molt audits the instruction prose, evolve audits the run logs. It exists because the other two never catch harness drift - nothing fails when the harness absorbs plumbing, so the prose silently becomes dead weight.

Small findings apply inline via the subtraction test with a drift ledger line, same session; structural findings (skill merges, gates-to-hooks, re-homing) emit a brief via the shared convergence machinery (brief-pipeline.md) and ride the normal chain: /loop-plan -> /loop-drive -> /loop-review. Self-targeting loop-stack is the dogfood case; molt runs on any prose-shaped artifact (manuals, CLAUDE.md blocks, other skills).

## Wiring it into the stack

One implementation, two entry points: the standalone `/loop-molt` skill owns the audit (this protocol as its reference), invocable directly on any artifact; `/loop-improve --focus harness-drift` delegates with a one-line pointer, never a second copy. Refresh (step 0) maps to a last30days/changelog pull; subtraction (step 4) maps to the artifact's existing test harness where one exists.
