# The shared brief pipeline (convergence half)

This reference holds the convergence half shared by loop-brainstorm and loop-improve.
The calling skill carries its own divergence half - explore, scope probes, and clarifying questions, or audit-and-select - and points here once a single idea or finding is chosen to converge.
Read it in full and follow it before proceeding - do not summarize it from memory.
It runs from approaches through the user review gate and the commit offer, and holds the shared graduation contract.
The shared graduation contract lives here (single home); each calling skill keeps only its own terminal step and any skill-specific close (loop-improve's supersede-close is improve-only and stays in loop-improve).

## Approaches

Architecture thinking and outward research are required inputs to this step; the purity rules below govern what lands in the brief, never what you investigate.
Before proposing, name each candidate's enabling assumptions about the outside world - ecosystem, tooling, platform capabilities - and buy a fresh observation for any that is decision-bearing and possibly stale.
A negative about the external ecosystem ("no plugin exists", "X isn't supported") cannot kill or park a candidate until checked against the current ecosystem this session, dated; local absence is never evidence of world absence.
Score research inputs by transferable mechanism, not topic overlap.

Propose 2-3 genuinely different approaches with trade-offs, lead with your recommendation, and say why.
The chosen approach, the alternatives, the rationale, and the dated ecosystem facts it rests on all go in the brief; decisions without recorded rationale get relitigated.

## The brief

Present it section by section, scaled to complexity, checking in after each chunk.
Then write it to `docs/briefs/YYYY-MM-DD.<tokens>.<topic>-brief.md` (one sentence per line, plain dashes, aligned table pipes).
When the work belongs to a logged tracker item, include its token segment(s) (e.g. .I6 for issue 6, .B4 for backlog item 4, .R1 for roadmap item 1, .W3 for wayfinder ticket 3); when the item is not yet logged, omit the token segments entirely and insert them when the item is created.

The sections below are the brief's default shape.
Scale each to the idea - one sentence is fine for a simple one - and use your judgment to drop a section that genuinely does not apply, saying in the brief what you dropped and why.

| Section                    | Contents                                                                    |
|----------------------------|-----------------------------------------------------------------------------|
| Outcome                    | The need restated as outcome, not the action named; presupposition verdict  |
| End artifact               | The concrete thing this unblocks; for infra, the first real deliverable     |
| Done looks like            | What the user can do when finished, including the exact run/usage commands  |
| Assets and options         | Every asset mentioned, mapped to its implied option, chosen or declined     |
| Approach                   | The chosen one, the 2-3 considered, and the rationale at decision time      |
| Success criteria           | Each tagged `[executed-check]` or `[judgment]` (see tagging rule below)     |
| Seams                      | Independently checkable pieces in blast-radius order, or "atomic" stated    |
| Known vs guessed           | Three bins: verified / believed-unchecked / guessed, with what breaks if a  |
|                            | guess is wrong                                                              |
| Parking lot                | Every parked thread, verbatim enough to restart later                       |
| Out of scope               | What this deliberately is not                                               |
| Open questions for planning| Implementation questions that surfaced, one line each, unanswered           |

**Checkability tagging rule.**
Tag a criterion `[executed-check]` only if you can name the command shape that would verify it (exit 0, a rendered file, a fetched citation).
For a `[judgment]` criterion, attempt one reformulation toward checkable - "feels fast" becomes "the digest renders in under 2 seconds on the sample vault" - and keep the judgment tag only if the reformulation genuinely loses the intent.
Downstream, /loop-plan routes every `[judgment]` tag to a human checkpoint (never a worker task), and the One-Minute Test front-door checkability question and /loop-drive's step 1 halt condition consume the tags directly (P6: work enters a swarm only when checking is cheaper than producing).

**What the brief is not.**
Outside the Approach and Known vs guessed sections, the brief contains no components, no data flow, no schedulers, no file formats, no library names, no phased build roadmap.
If any of those appears elsewhere in your draft, move it to Open questions for planning as a single line and delete the prose.
Approach and Known vs guessed may name plugins, platforms, and mechanisms when decision-bearing - that is which-shape-and-why, the grain those sections exist to record.
What stays banned even there: speccing the innards of the chosen shape.
The test for every other section: every sentence should survive the implementation being swapped out entirely.

## Self-review

Look at the written brief with fresh eyes and fix inline:

1. **Placeholder scan** - any TBD, vague requirement, or empty REQUIRED section.
2. **Internal consistency** - do sections contradict each other?
3. **Architecture scan** - run the "survives an implementation swap" test on every sentence outside Approach and Known vs guessed; inside them, check the grain instead (which-shape-and-why stays, innards-spec moves to Open questions for planning).
4. **Ambiguity check** - could any criterion be read two ways? Pick one, make it explicit.
5. **Tag audit** - is every success criterion tagged, and every `[judgment]` tag the survivor of an attempted reformulation?

## User review gate and commit offer

Tell the user where the brief was written, invite review and changes before it goes to planning, and offer the commit; the phrasing is yours.
Wait for the response.
Changes requested means edit and re-run the self-review.
Offer the commit; never commit without the offer being accepted.

## Graduation (shared contract)

On an accepted commit, graduate the brief's Parking lot into backlog issues.
This contract is shared by loop-brainstorm and loop-improve and lives only here; each caller invokes it from its own terminal step.

- **Preview first.** Announce the parked-item count and each item's derived title, and ask for assent before creating anything.
- **Invoke on assent.** Parse the brief's `## Parking lot` section and open one `idea`-labeled issue per parked item with `gh issue create --label idea --title <first sentence, period-free> --body <the bullet plus its restart context and a link to the brief>`, the body following the graduated-item template in `config/conventions.md`.
- **Parking-lot bullet shape.** Each parked item is one bullet whose first sentence is the derived issue title and MUST be period-free and filename-free: the title is truncated at the first dot, so a leading filename self-truncates. A `Restart context:` continuation line carries what a later session needs to pick the item back up.
- **Verbose announce.** Each created issue is announced with its number and title.
- **Reverse.** Undo a graduated issue with `gh issue close <num>` or `glab issue close <num>` per the declared tracker mode.
- **Autonomy.** An autonomous run auto-takes graduation once the review-gate commit is accepted, but journals every created issue number for the end-of-chain review rather than firing silently.

The terminal state (naming the next stage) is the calling skill's own step - return to the calling SKILL.md after graduation resolves.
