# Evidence matrices: which input answers which finding

Distilled 2026-09-25 from the molt harness-evidence brief.
Molt reads up to three inputs.
The artifact's own prose is always present.
The two evidence corpora are optional, and each answers a different question: the harness corpus says what the harness already tells the model, and the model notes say how the target model responds to prose.
Step 0 of `references/protocol.md` says how each corpus is pinned, fetched, and stamped; this file holds only the two matrices and their notes.

## The three inputs

| Input          | Presence | Source                                                                                                                                                               | Perspective           | Used for                                                              | If absent          |
|----------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------|-----------------------------------------------------------------------|--------------------|
| Artifact prose | Always   | The file or files under audit                                                                                                                                        | Its own text          | Every step; the contradiction check and the mechanical wording checks | No audit           |
| Harness corpus | Optional | The Piebald prompt catalog (`https://github.com/Piebald-AI/claude-code-system-prompts`) at the tag matching the running harness version, or a semantic index over it | What the harness says | Plumbing, harness conflicts, harness premises                         | Memory, unverified |
| Model notes    | Optional | Anthropic's per-model prompting pages (`https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-<model>.md`), downloaded once per model   | How the model reacts  | Choreography, the gap scan, the wording standard                      | Memory, unverified |

The split follows molt's bins.
Plumbing, mechanics the harness now performs unprompted, is judged against the harness corpus.
Choreography, step-by-step behavior the target model does by judgment, is judged against the model notes.
The subtraction test is the final verdict either way: it runs a real task and uses neither corpus.

## Which inputs each finding class needs

| Finding class                              | Artifact | Harness | Model notes |
|--------------------------------------------|----------|---------|-------------|
| Plumbing: the harness already does it      | yes      | yes     | -           |
| Choreography: the model does it unprompted | yes      | -       | yes         |
| Duplicates or conflicts with the harness   | yes      | yes     | -           |
| Contradiction inside the artifact          | yes      | -       | -           |
| Wording fails the standard                 | yes      | -       | yes         |
| Addition for a documented model need       | yes      | -       | yes         |
| Stale premise about the harness            | yes      | yes     | -           |

Notes:
- Contradictions inside the artifact need only the artifact, so the contradiction check is the one check that works with neither optional input.
- Wording draws on two sources: the model notes supply the dated patterns, and the owner's banned-token list enters through the constraint register (jrit-core's banned-token list can supply it as data).
- When an input is missing, molt falls back to memory, marks the verdicts that depend on it as unverified, and the ledger records which inputs were present.
