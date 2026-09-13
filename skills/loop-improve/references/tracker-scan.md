# Tracker scan

Shared step for loop-brainstorm and loop-improve: check the thing in hand (a fresh idea, an audit
finding) against what is already tracked before spending further effort shaping it.

Read the tracker mode from `docs/loop/pointer.md`, then list open issues with `gh issue list --state open --limit 1000 --json number,title,labels` (github) or `glab issue list --all --output json` (gitlab) for the open Issues and Backlog lanes; in `local` mode read the file named by the `local-issues-file:` key.

Match by judgment; when a title is ambiguous, read the body (`gh issue view N` in github mode, `glab issue view N` in gitlab mode, the `local-issues-file:` file in local mode) before deciding.

A match is either the same work (covered) or the same area with a different ask (related, not a
duplicate). No match: proceed as new. How each skill renders and acts on a match is its own step
- this reference owns only the scan mechanism.
