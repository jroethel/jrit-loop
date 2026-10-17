# The plan review

The plan review is a pause between the settled question rounds and the plan draft.
It produces two files with one stem under `reviews-home:` (default `docs/reviews/`): the record, `YYYY-MM-DD.<tokens>.<topic>-plan-review.md`, and the page, `YYYY-MM-DD.<tokens>.<topic>-plan-review.html`.
The record is the source: it is what the plan writer receives and what the plan cites.
The page is rendered from the record for the human reviewer, and nothing appears on the page that the record does not hold.
Write the record first, then the page.

## The record

The record carries these sections in this order, each as a `## ` heading, none omitted; a section with nothing to say states that in one line.

1. **Header.** The topic as the title, then one line each for the source brief's path, the date, and the number of question rounds held so far.
2. **Where the changes land.** A table, one row per place (repo, tool, host config): place, what changes, notes.
   Places that stay unchanged get a row saying so; "nothing changes here" is a finding the reviewer needs.
3. **The flow, and one figure per load-bearing decision.** First the end-to-end flow of the work as built, then one figure for every decision the shape rests on.
   In the record each figure is a text sketch (nodes and arrows, or a short table) that stands without the page.
   Each figure carries a callout beside it: what was chosen, the alternatives that lost, why, and who decided.
4. **Decision log.** A table collecting every callout and every other decision taken so far: ID, decision, chosen, alternatives that lost, why, by.
   IDs use three letters: `D` for decisions made before this run (in the brief or earlier), `R` for decisions the human made in a question round (`R1` is the first question of round 1 in asking order), `M` for defaults you took without asking.
   Every `M` row is marked reversible, with the one-line reversal.
5. **Open decisions.** Every decision still open, each with a plain-language tradeoff table (option, what it gains, what it costs) and your recommendation listed first.
   These become the page's answer controls, numbered `Q1`, `Q2`, and so on in this order.
6. **What the shape assumes.** Every load-bearing claim in one of three bins.
   Verified: checked this session against source, a probe, a command, or the human's own word, with the source named.
   Believed: read from source or memory but never run, with why you believe it and what breaks if it is wrong; the plan's first tasks probe these.
   Guessed: a number or threshold someone picked, with who picked it.
7. **The parking lot, in suggested order.** Every deferred idea from the brief's parking lot and out-of-scope list and from this session: item, what it waits on, when it comes back.
   The order is your suggestion and says so; the reviewer reorders.
8. **Question-round timeline.** One entry per round held so far, read from this session, with each question and the answer given.
9. **What happens next.** The steps from an approved shape to the committed plan, then everything that is the human's to fire (a push, a filing, a send), each on its own line.
10. **Review rounds.** Appended, never edited: one entry per review round with the notes received and what changed in the record because of them, and after the verdict, the answers block verbatim and the verdict line.

## The page

The page holds the record's sections 2 through 9 in the same order, numbered `01` through `08`, with the header as the page title block.
Each figure is an illustration, not a text sketch: nodes and arrows, with the decision callout beside it carrying chosen, lost, why, and who.
Section 05 (open decisions) renders each `Q` as a card with its tradeoff table and radio controls, recommendation first and marked, plus a free-text line for an answer the options missed.
The page ends with a verdict control (approved, or changes needed) and a notes field.
The page is self-contained: inline styles, no scripts fetched from anywhere, readable in light and dark, no horizontal scroll at phone width.

## The answers block

The page assembles one plain-text block from its controls, and the human either sends it through the renderer's own feedback channel or copies it and pastes it into the conversation.
The block's shape, which the record's final review-round entry quotes verbatim:

```
plan-review: <record path>
round: <N>
Q1: <chosen option, or the free-text answer>
Q2: <...>
verdict: approved | changes
notes: <free text, may be empty>
```

A `changes` verdict with notes means a new review round: fold the notes into the record, rebuild the page, bump `round`, and ask again.
An `approved` verdict means append the block and the verdict to the record, then continue to the decompose step; the record's path goes into the plan header's `**Plan review:**` line, and the plan's decisions cite the record's IDs.

## The renderer

Two renderers exist, and the record is the same under both.

When a skill named `lavish` is available, write the page following lavish's own plan, diagram, and input playbooks, open it with lavish, and collect the answers block through lavish's feedback channel; the copy-answers control may stay on the page but is not the primary channel.
When it is not, copy `plan-review-template.html` beside the record, fill its slots from the record, and tell the human the path to open in a browser; the page's copy-answers button is the channel, and the block arrives pasted into the conversation.

A brand pack and a doctype are vocabulary of the renderer, not of this skill.
When either was named (at invocation as `brand=<slug>` or `doctype=<slug>`, or in the pointer keys `plan-review-brand:` and `plan-review-doctype:`), pass the slugs through to a renderer that understands them, such as lavish's design-direction step or a brand build skill installed in the session, and state in one line which was applied.
The plain template applies neither; when one was named and the plain template was used, say so in one line.

## In a dispatched session

Write both files, then print the page path, the open decisions as the plain-text round (numbered `Q1` onward, options with the recommendation first and marked `(recommended)`), and the verdict as the last question.
End the turn; the next user turn carries the answers block or the round's answers.
