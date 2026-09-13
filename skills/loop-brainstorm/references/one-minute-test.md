# The One-Minute Test

Source: Nate B. Jones (Unlock AI), https://unlock-ai.natebjones.com/guides/the-one-minute-test

Most AI mistakes are routing mistakes.
Sort the task before starting, and pick the lightest tool that can do the work while leaving a result you can inspect.
The test routes a job to one of four verdicts. It is a fast check on the shape of the work, not a magic classifier.

## Four routes

- **CHAT** - narrow answer work: the source fits in the prompt, the task is answer-only, and you can review the result directly. The clean option when the job is small enough for one exchange.
- **ONE AGENT** - one clear goal that needs a tool/folder/app action and can still be checked by one person. One goal, one loop, a visible result.
- **AGENT TEAM** - work too large for one pass that splits cleanly across sources or roles, where outputs check against citations, tests, or acceptance rules.
- **DON'T BOTHER** - AI could technically help, but setup is not earned, the final judgment is not cheap to check, or the work is too sensitive for casual automation. A legitimate, frequent verdict, not a failure.

## Seven questions

1. **Size** - how much source material has to stay in view? If it fits in one prompt, start with chat; many documents or threads make a team more plausible.
2. **Independence** - can useful parts proceed in parallel? Reading a pile of documents splits well; most coding changes do not (each depends on the current repo state). If every worker needs the same full context and constant sync, one agent is better.
3. **Separation** - does any step need a fresh mind? A draft benefits from a critic who did not write it. Separation is not parallelism, but it can justify a team when the check is explicit.
4. **Checkability** - is checking cheaper than producing? A citation, test suite, acceptance rule, or calendar-conflict check makes AI work safer. Taste-only work fails this test.
5. **Judgment** - how much is judgment doing? Low-judgment work (collect forms, find renewal dates, summarize notes) routes to agents; high-judgment work stays with a person or is narrowed until the AI part is support work.
6. **Access & consequence** - what access does it need and what does a mistake cost? A pasted note differs from private files; a calendar action differs from money risk. Tool access earns its keep only when the done state is clear.
7. **Payoff vs setup** - does frequency and value earn the setup cost? Daily/weekly jobs get more room; rare low-value chores usually do not.

Score the plan as a whole - most plans lean clearly toward one route even when a sub-task doesn't fit. Note any part that obviously needs a different route rather than forcing everything into one bucket.

## Worked examples (the verdicts that keep it honest)

These look agent-shaped but aren't agent-worth - the reason each routes to DON'T BOTHER is the useful part:

- **Tax-folder organization** has files, missing-item checks, and obvious busywork, but the task is rare, sensitive, and still needs careful human review - not enough repeated payoff to justify a casual automation path through tax documents.
- **Product naming** makes generation cheap, not judgment cheap: more agents create a larger pile of fluent options but do not make the final call cheaper. Judging the winner is the actual work.
- **New-dishwasher research** looks splittable across reviews, prices, models, and delivery windows, but for a rare, low-value purchase with weak checkability and mixed judgment, a swarm adds coordination cost before it adds leverage. Use search, ask chat for a comparison, then choose.

## What happens next (verdict -> artifact)

The verdict matters only if it changes what you do next:

- **CHAT** -> a narrow, pasteable prompt: task + source material together, ask for one output plus assumptions and anything to verify. Review the answer before it goes anywhere.
- **ONE AGENT** -> a run card: goal (one sentence), done state (the inspectable artifact), tools (only what the run needs), cap (one pass / time limit / stop condition), check (source, rule, test, or human review).
- **AGENT TEAM** -> a small named team: roles (e.g. reader that cites, synth that combines, reviewer that checks gaps) plus a human gate before anything ships or changes.
- **DON'T BOTHER** -> a short manual checklist, plus a trigger for when to revisit (e.g. "rerun this if it becomes a weekly job").

Pick the lightest tool that leaves an inspectable result.
