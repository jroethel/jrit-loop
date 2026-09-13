# The queue-runner prompt

A standalone, pasteable prose prompt for processing the work queue.
A human pastes it into any capable agent session, or a scheduler runs it verbatim; it carries no harness-specific fields.
The receipt helper ships inside the loop-drive skill: run every `bash scripts/receipt.sh` step below resolved relative to that skill's own directory, never against the repository under work.

## The prompt

Copy everything between the two markers.

---8<---

You are processing this repo's work queue.
Work exactly one ticket this run, then stop.

Boundaries first - they outrank everything below.

- Never **publish** without issue-level approval.
- Never **deploy** without issue-level approval.
- Never **delete** without issue-level approval.
- Never **email** without issue-level approval.
- Never change **billing/credentials** without issue-level approval.

This is a `[gate:STOP]`-class rule per loop-auto's gate classes: an outward-facing unit halts and states what it needs, and you never auto-resolve it.

Then proceed in order.

1. Derive your session id.
   Use the session id supplied to you; if none was supplied, use `${USER:-agent}-$$`.

2. Read the status ledger.
   List the open tickets per the tracker mode declared in `docs/loop/pointer.md`: `gh issue list --state open --limit 1000 --json number,title,labels` in github mode, `glab issue list --all --output json` in gitlab mode.
   Note each open ticket's `agent:*` label (todo, working, needs-input, review).

3. Select a ticket.
   Run `bash scripts/receipt.sh next-eligible <session-id>`.
   It prefers a stale-working relaunch over a fresh todo, so a killed wave is resumed automatically.
   If it prints `NONE ELIGIBLE`, there is nothing actionable for you; stop here.

4. Claim it.
   On a stale-working selection, run `bash scripts/receipt.sh claim <num> <session-id> --reclaim`.
   On a fresh todo, run `bash scripts/receipt.sh claim <num> <session-id>`.
   Exit 4 means a lost claim race: another session owns the ticket; stop, do not force it.

5. Confirm ownership.
   The claim must print your own session id; re-read the ticket's receipts and confirm you are the owner before doing any work.

6. Do the scoped work the ticket describes.
   Stay inside its stated file ownership.
   A half-done unit left by a dead session is relaunched from tracker plus git, never resumed mid-flight.

7. Leave a receipt.
   Prefer `bash scripts/receipt.sh done <num> --receipt '<what was done>' --ran '<the check command>'`; the `--ran` command is re-executed and its real exit code is captured, so never paste a claimed result in its place.
   Exit 5 means the receipt cited no executed-check evidence: run the check and retry with `--ran`.
   Exit 7 means the cited check actually failed and the ticket is now `agent:review`: the unit is not done, and the failure is the finding.
   When the check cannot be re-run, use `--receipt '<passing evidence>'` citing an executed passing run (exit 0, N passed, 0 failed, or an artifact link); a bare assertion of success is rejected.
   When human judgment is required instead, run `bash scripts/receipt.sh status <num> review` or `bash scripts/receipt.sh status <num> needs-input`.

8. STOP.
   At most one eligible ticket per run.
   A scheduler wanting more throughput runs this prompt again as a fresh run.

---8<---

## Canonical cycle, copy-paste

The operator never hand-assembles a receipt; this exact cycle is the template.

```bash
# 1. session id (skip when your scheduler supplies one)
SID="${USER:-agent}-$$"

# 2. read the status ledger (github mode; gitlab mode: glab issue list --all --output json)
gh issue list --state open --limit 1000 --json number,title,labels

# 3. select at most one ticket (stale-working relaunch beats fresh todo)
bash scripts/receipt.sh next-eligible "$SID"
# -> SELECTED #7: agent:todo, unblocked
# -> SELECTED #7: stale working, relaunch   (use --reclaim in step 4)
# -> NONE ELIGIBLE: ...                     (stop; nothing actionable)

# 4. claim, matching the selection reason
bash scripts/receipt.sh claim 7 "$SID"              # fresh todo
bash scripts/receipt.sh claim 7 "$SID" --reclaim    # stale-working relaunch
# -> prints your session id when you own it; exit 4 = lost race, stop

# 5. do the scoped work for #7, then complete with re-executed evidence
bash scripts/receipt.sh done 7 --receipt 'fixed login redirect, gate green' --ran 'bash tests/gates/auth.sh'
# a failing --ran exit routes #7 to review instead of done (exit 7)
# a done without --ran must cite a passing run, or it is rejected (exit 5)

# 6. judgment needed instead of a check
bash scripts/receipt.sh status 7 review
bash scripts/receipt.sh status 7 needs-input
```

After step 5 or 6, the run is over.
One ticket, one receipt, one run.
