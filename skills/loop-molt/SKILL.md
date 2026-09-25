---
name: loop-molt
description: >
  Audit any instruction-prose artifact - a SKILL.md, a CLAUDE.md block, an operating manual, a
  run-book - against a dated snapshot of what the harness now does natively, so plumbing gets
  deleted and policy survives. Classifies each block into four bins - plumbing, policy, premise,
  choreography - emits deletions plus a drift ledger line, and converges structural findings into a brief.
  Triggers on "molt", "harness drift", "audit this skill against the harness", "re-evaluate this
  prose against what the harness now does", and /loop-molt.
---

# loop-molt: audit instruction prose against the live harness

Skills, manuals, and CLAUDE.md blocks rot silently: nothing fails when the harness absorbs a
mechanic, so the prose that describes it just becomes dead weight. Molt is the audit that catches
that drift - the third in the family next to /loop-improve (audits the product) and P10's evolve
move (audits the run logs). This skill runs on any prose-shaped artifact; loop-stack self-audit is
just the dogfood case.

The reference doc is `references/protocol.md` (vendored, canonical). Read it in full before
auditing - this SKILL.md is the thin wrapper, the protocol is the method.

## The one-line test

Per block of prose: **"would the harness or the target model do this unprompted, today?"**
Not "is this correct?" - correct-but-native is still deletable. Prose describing HOW to do
mechanics is suspect; prose describing WHAT MUST BE TRUE is policy.

## The four bins

Every block sorts into one of four bins - **plumbing, policy, premise, choreography** - defined,
with their actions and the policy membership test, in `references/protocol.md` (step 3). This
SKILL.md never restates those definitions; the reference is their single home.

## Steps

Full procedure and rationale live in `references/protocol.md`; the pointers below are the running order, not a second copy.

0. **Refresh ground truth** - never audit against remembered capability; thin refresh (changelog + one live probe of a load-bearing claim) per artifact, deep refresh (full research pull) for a whole-stack recalibration.
   The snapshot includes the harness instruction corpus pinned to the running harness version (protocol step 0).
   The second evidence source is the target model's prompting notes, the model notes that ground choreography verdicts.
   Date-stamp the snapshot - it is the evidence base and its expiry.
1. **Constraint register FIRST**`[gate:ASK]` - before classifying anything, ask the owner which design choices are deliberate standing constraints (portability, provider mix, cost, compliance) versus historical accident. Mandatory and ASK-class: never classify a premise as expired without it (a constraint misread as stale nearly flipped three recommendations); deliberate constraints are kept AND labeled so the next audit does not re-litigate them.
   The register also names the target model, the model that will read the artifact, never assumed.
2. **Inventory**`[gate:ASK]` - break the artifact into blocks (each instruction, gate, step, or embedded claim is one unit); for a skill family, inventory duplication too (a narrative in N places counts once, then N-1 deletions), across the files when the audit covers more than one.
   A conflicting pair (two blocks that cannot both be true) is an owner question, asked once per run with the other pairs, and is never auto-resolved.
3. **Classify** - sort every block into the four bins using the reference's definitions and policy-membership test; an expired premise is rewritten in place (never a bolted-on correction), a deliberate constraint kept and labeled.
   Kept POLICY blocks are then rewritten to the wording standard defined in `references/protocol.md` step 3.
3b. **Gap scan** - check the artifact against each documented behavior change in the target model's notes; a gap becomes a proposed addition kept only through the reverse subtraction test of `references/protocol.md` step 3b (arm A: artifact as is, arm B: artifact plus the addition, three or more runs per arm).
4. **Test by subtraction** - delete the block, run the artifact's existing checks plus one real task, keep the deletion only if nothing degrades; a checkless artifact gets a check first (weaker fallback: compare one real task to a pre-deletion run).
5. **Emit the drift ledger line** - append one entry to `docs/molt-ledger.md` (`## YYYY-MM-DD - <artifact path>`: date, harness snapshot, blocks deleted by bin, blocks kept as policy, constraints re-confirmed); on a first audit of a principles-less artifact, also emit its derived invariants as a starter principles sheet.

## Workflow: inline vs. brief

- **Small findings** (block deletions, single-file rewrites) apply inline via the subtraction test
  with a `docs/molt-ledger.md` line, same session.
- **Structural findings** (skill merges, gates-to-hooks, re-homing) converge through the shared
  pipeline at `references/brief-pipeline.md` into a brief and ride
  the normal chain: /loop-plan -> /loop-drive -> /loop-review. No audit content is
  duplicated - loop-improve reaches this same audit via `--focus harness-drift`.

The artifact is harness-agnostic: this SKILL.md is the only Claude-Code-specific wrapper; the
protocol is portable prose that any agent can run.

## Host defaults (jrit)

This section holds this host's concrete paths and commands for the portable protocol; the protocol and its references name none.

- Harness version command: `claude --version`.
- Local catalog checkout: `~/repos/claude-code-system-prompts`.
- Pinned read: `git -C ~/repos/claude-code-system-prompts grep -n -i '<phrase>' v<version> -- system-prompts`, and for the index date `git -C ~/repos/claude-code-system-prompts log -1 --format=%cs v<version>`.
- Optional semantic index: the qmd collection `piebald-ai`, which indexes the catalog head, so confirm every hit in the pinned tag.
- Model-notes folder: `~/.config/jrit/molt/model-notes/<model>.md`, one downloaded prompting page per model.
- Model-notes download: `curl -sfL https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-<model>.md -o ~/.config/jrit/molt/model-notes/<model>.md`.
- Non-Anthropic model log: `~/repos/ringer/docs/MODEL-NOTES.md`.
