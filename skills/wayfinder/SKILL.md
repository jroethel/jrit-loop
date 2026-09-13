---
name: wayfinder
description: Plan a huge chunk of work - more than one agent session can hold - as a shared map of decision tickets on your issue tracker, and resolve them one at a time until the way to the destination is clear.
disable-model-invocation: true
---

**Pre-plugin repo check.** Before anything else, look for `config/repo-state.md` in this repo.
If it exists and `docs/loop/pointer.md` does not, stop.
Say plainly that this repo is still on the pre-plugin loop-stack layout, name the file you found, and offer to run the loop-setup skill's migration before continuing.
Never proceed silently on a pre-plugin repo.

A loose idea has arrived - too big for one agent session, and wrapped in fog: the way to the **destination** isn't visible yet.
Wayfinding finds that way rather than charging at the destination: this skill charts it as a **shared map** on the repo's issue tracker, then works its **decision tickets** - questions whose resolution is a decision, not slices of a build - one at a time until the route is clear.

This skill is user-invoked only: `disable-model-invocation` is set, so it never auto-selects itself and runs only when the human calls it.

Naming the destination is the first act of charting - it shapes every ticket and fixes the scope.
It might be a spec to hand off, a decision to lock before planning, or a change made in place (a data-structure migration); the map is domain-agnostic.

Wayfinder requires a remote tracker (`github` or `gitlab`): its map and tickets are tracker issues end to end, no local-tracker variant.
The `wayfinder:map` label needs no renaming on GitLab (a single colon is ordinary; only `::` marks a scoped label).

## Plan, don't do

Wayfinder is **planning** by default: each ticket resolves a decision, and the map is done when the way is clear - nothing left to decide before someone goes and does the thing.
The pull to just do the work is usually the signal you've reached the edge of the map and it's time to hand off: when the way is clear, hand the destination to `/loop-plan`.
An effort can override this in its **Notes** - carrying execution into the map - but absent that, produce decisions, not deliverables.

## Refer by name

Every map and ticket is a tracker issue, so it has a **name** - its title.
In everything the human reads (narration, the map's Decisions-so-far), refer to it by that name, never a bare id, number, or slug - a wall of `#42, #43, #44` is illegible.
The id and URL ride *inside* the name (a name wraps its link), never stand in for it.

## The Map

The map is a single tracker issue on this repo, labelled `wayfinder:map` - the canonical artifact; its tickets are the issues attached to it, by the mechanism each backend actually supports (see [Tickets](#tickets)).
It is an **index**, not a store: a decision lives in exactly one place - its ticket - so the map never restates it, only gists it and links.

### The map body

The whole map at low resolution, loaded once per session.
Open tickets are **not** listed - they are open ticket issues, found by query.

```markdown
## Destination

<what reaching the end of this map looks like - the spec, decision, or change this effort is finding its way to. One or two lines; every session orients to it before choosing a ticket.>

## Notes

<domain; skills every session should consult; standing preferences for this effort>

## Decisions so far

<!-- the index - one line per closed ticket: enough to judge relevance, then zoom the link for the detail the ticket holds -->

- [<closed ticket title>](link) - <one-line gist of the answer>

## Not yet specified

<!-- see "Fog of war": in-scope fog you can't ticket yet; graduates as the frontier advances -->

## Out of scope

<!-- see "Out of scope": work ruled beyond the destination; closed, never graduates -->
```

### Tickets

Each ticket is an issue on the same tracker as the map (the issue number is its identity); its body is the question, sized to one 100K-token agent session:

```markdown
## Question

<the decision or investigation this ticket resolves>
```

Each ticket carries one of these labels: `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`, or `wayfinder:task` (see [Ticket Types](#ticket-types)).

A session **claims** a ticket by assigning it to the dev driving the map, **first**, before any work - that assignee _is_ the claim; an open, unassigned ticket is unclaimed.
Attachment and blocking differ by backend, and this prose claims only what the CLIs actually support: `gh issue create` carries a native `--parent` flag (filing the new issue as a sub-issue of the map) plus native `--blocked-by` and `--blocking` flags, while `glab` has no sub-issue or parent flag at all, so on GitLab the ticket labels are what attach a ticket to its map.
The portable mechanism on every backend is the issue-body convention: a blocked ticket writes `Blocked by: #N` for each ticket that must close first, and that convention is exactly what the receipt helper's `next-eligible` resolves, so any edge a later session must resolve mechanically is written this way regardless of backend.
A ticket is **unblocked** when every blocker is closed; the **frontier** is the open, unblocked, unclaimed tickets - the edge of the known.

Per-ticket model choice follows the routing chain, which is owned by the loop-drive skill; do not restate it here.
The answer isn't part of the body - it's recorded on resolution (see [Work through the map](#work-through-the-map)); assets created while resolving are linked from the issue, not pasted in.

## Ticket Types

Every ticket is either **HITL** - human in the loop, worked *with* a human who speaks for themselves - or **AFK**, driven by the agent alone.
A HITL ticket only resolves through that live exchange; the agent never stands in for the human's side (a grilling that answers its own questions has broken this).

- **Research** (AFK): reading docs, third-party APIs, or local resources to surface a fact a decision waits on. Resolved by a fresh-context research subagent (clean context so prior decisions don't anchor it). Use when knowledge outside the working directory is required.
- **Prototype** (HITL): a cheap, rough, throwaway artifact to react to - an outline, a stub, UI/logic code - linked as an asset; must not depend on any uninstalled skill. Use when "how should it look/behave" is the key question.
- **Grilling** (HITL): conversation via `/loop-brainstorm`, one question at a time; `/loop-brainstorm` owns domain modeling. The default case.
- **Task** (HITL or AFK): manual work that must happen before a *decision* can be made (sign up for a service so its API can be judged, provision access, move data so its shape can be seen) - the one type that *does* rather than decides, in scope only by unblocking a decision, not delivering the destination. Agent drives it alone where it can (AFK), else hands the human a precise checklist (HITL). Resolved when done; the answer records what was done and any facts (credentials location, URLs, row counts) later tickets depend on.

## Fog of war

The map is _deliberately_ incomplete: don't chart what you can't yet see.
Beyond the live tickets lies the **fog of war** - decisions and investigations you can tell are coming but can't pin down, because they hang on questions still open.
Resolving a ticket clears the fog ahead of it, graduating whatever's now specifiable into fresh tickets - one at a time, until the way is clear and no tickets remain.

The map's **Not yet specified** section holds that dim view: the suspected question, the area to revisit.
Everything here is in scope, just not sharp enough to ticket; write as loosely as the view allows - it doubles as a signpost for where the effort is headed.

**Fog or ticket?** The test is whether you can state the question precisely now - _not_ whether you can answer it now.

- **Ticket when** the question is already sharp - even if blocked and you can't act on it yet.
- **Not yet specified when** you can't yet phrase it that sharply. Don't pre-slice the fog: it's coarser than a ticket, and one patch may graduate into several tickets, or none.

**Not yet specified** excludes what's already decided (Decisions so far), already a live ticket, or out of scope.

## Out of scope

Fog only ever gathers _toward_ the destination; work beyond it is **out of scope** - not fog, and not for **Not yet specified**.
It gets its own **Out of scope** section: work consciously ruled out of _this_ effort (scope, not sharpness, lands it here).
Out-of-scope work never graduates - the frontier stops at the destination - so it returns only if the destination is redrawn, as a fresh effort.

When an existing ticket turns out to sit past the destination (mis-scoped while charting, or exposed by a resolution), **close it** (unambiguously off the frontier) and leave one line in **Out of scope**: the gist, why it's out, linking the closed ticket.
It stays out of **Decisions so far**, which records the route actually walked - a scope boundary isn't a step on it.

## Invocation

Two modes. Either way, **never resolve more than one ticket per session** - except research tickets.

### Chart the map

User invokes with a loose idea.

1. **Name the destination.** A `/loop-brainstorm` session pins down what the map is finding its way to (spec, decision, or change); it fixes the scope, so it's settled first.
2. **Map the frontier.** Brainstorm again, **breadth-first**: fan out across the whole space, surfacing the open decisions and the first steps takeable now. **If this surfaces no fog** (the way is already clear, small enough for one session), you don't need a map - stop and ask how the user wants to proceed.
3. **Create the map** (label `wayfinder:map`): Destination and Notes filled in, Decisions-so-far empty, fog sketched into **Not yet specified**.
4. **Create the tickets you can specify now**, attached to the map per your backend, then wire `Blocked by: #N` edges in a **second pass** (issues need numbers first). Wiring sorts them into frontier vs blocked; the rest stays in **Not yet specified**.
5. **Fire the research subagents.** For each `research` ticket, spin up a fresh-context research subagent in parallel, capturing findings on a throwaway `research/<name>` branch with a context pointer from the ticket.
6. Stop - charting is one session's work; it hand-resolves nothing.

### Work through the map

User invokes with a map (URL or number). A ticket is **optional** - without one, you pick the next decision, not the user.

1. Load the **map** - the low-res view, not every ticket body.
2. Choose the ticket: the user's if named, else the first frontier ticket in order. **Claim it** - assign to yourself before any work.
3. Resolve it, **zooming as needed**: fetch the full body of any related/closed ticket on demand, invoke the skills the `## Notes` block names; if in doubt, use `/loop-brainstorm`.
4. Record the resolution: post the answer as a **resolution comment**, **close** the issue, **append a context pointer** to Decisions-so-far.
5. Add newly-surfaced tickets (create-then-wire); graduate any now-specifiable fog, clearing each graduated patch from **Not yet specified**. If the answer reveals a ticket sits beyond the destination, **rule it out of scope** rather than resolving it; if it invalidates other tickets, update or delete them.
6. When the frontier is empty and the way is clear, hand the destination to `/loop-plan`.

The user may run unblocked tickets in parallel, so expect concurrent tracker edits.
