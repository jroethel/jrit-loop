# The ringer transport

How the orchestrator drives a wave's packed manifest.
Ringer owns isolation, checks, retries, and logging; the orchestrator owns the specs, the checks' substance, model routing, and the gate.
This is the transport for units routed to ringer by Step 2's unified chain - commonly non-Anthropic or flat-rate engines (GLM via z.ai, anything via OpenRouter), or any unit where you want an executed check and a scoreboard row.

## Tier mapping

- **Orchestrator** = this session. Writes the manifest, runs it, reads results, gates. Never a worker.
- **Implementer** = a manifest task (one `tasks[]` entry), run on an engine (`claude`/haiku, `claude-zai`/GLM, `opencode`/OpenRouter).
- **Validation** = the task's executed `check` (the primary, non-negotiable gate), plus an optional separate review task for judgment ringer's check cannot express.

## Manifest conventions, per unit

One task per unit. Each task carries:

- `key`: unit id (unique; becomes the task dir and worktree name).
- `engine` + `model`: the routing decision from Step 2 (`model` fills the engine's `{model}` placeholder; omit to take the engine default).
- `task_type`: from the canonical vocabulary (code-feature, code-fix, code-review, research, persona-review, site-build, image-gen, docs, probe, bakeoff, ...). Untyped tasks teach the scoreboard nothing and draw a lint nudge.
- `spec`: self-contained. Everything the worker needs, no pointer specs, an ownership list of every file it may touch, an embedded how-to-run, and the exact output contract.
- `expect_files`: the deliverables, so the results page shows the right work.
- `check`: prints WHY it fails, verifies substance not just presence, strict on substance and tolerant on format (P14).
- `verified`: one plain-English line stating what the check proves.
- Optional: `max_attempts` (default 2 = one try + one retry; set `1` for a hard no-retry lane) and `redact_spec` (scrubs the spec from run state, logged command line, and eval row - but NOT from `worker.log` if the worker echoes it, so it is not a secrecy guarantee).

Run-level: `run_name` (the SAME across every wave of the build), `workdir`, `worktrees: true`, and `max_parallel`.

## Isolation and the patch-export pattern

Run-level `"worktrees": true` gives each task an isolated git worktree, so you do not re-specify per-task isolation.
But a passing task's worktree is DELETED, and worker commits die with it. Mitigations the plan must carry:

- **Deliverables outside the worktree**, or the check exports them first: `git add -A && git diff --cached > <path-outside-worktree>.patch`; you apply and commit on your branch after review.
- **Gitignored outputs** (`dist/`, build dirs) are not staged by `git add -A`; the check must `cp` them to a path outside the worktree explicitly. Verify the patch AND the copies.
- **Logs survive** in `<workdir>/logs/`, so post-mortems work even on deleted worktrees.
- **Stagger opencode spawns**: concurrent OpenCode workers contend on its shared sqlite state store (WAL); stagger launches or cap parallelism to avoid lock errors.

## The wave gate = ringer's post-run review ritual

At each gate, consume ringer's outputs (do not trust the summary line alone):

1. Read the run JSON in `~/.ringer/runs/` (statuses, retries, durations).
2. For every retried or failed task, read the raw worker log in `<workdir>/logs/` before deciding anything; a retry that passed on attempt 2 often flags a spec ambiguity worth fixing.
3. Spot-check at least one PASSING task's artifact.
4. A failure with a useless error message means the CHECK needs work, not (only) the worker.
5. Apply reviewed patches to the integration branch, run the full suite there, and advance only when green.

Ringer's built-in single retry IS the repair pass; do not add another (per-task `max_attempts` tunes it: `1` disables the retry). A task that fails at its attempt limit is a stopped unit for the gate to resolve.

## The ask lane

`./ringer.py ask "question" --source <path>` (repeatable `--source`, `--dry-run` to preview the packet) is a one-shot, read-only, no-manifest question over named sources.
Use it instead of reading files into your own context when the answer is all you need; it is not a unit and produces no scoreboard row.

## Model routing

Per-unit model choice follows the routing chain (`references/model-benchmarks.md`); this file does not restate it (the promotion ladder and prior tier live in that single home).
One ringer-specific mechanic stays here:

- **MODEL-NOTES receipts.** After a run, add a dated line to `<ringer-repo>/docs/MODEL-NOTES.md` when it taught you something about a model, supported only by the executed checks and raw logs.

## W-scaling: fewer, fatter waves (P13)

Marginal overhead per unit is flat; the binding constraint is your gate bandwidth (how many verdicts and diffs you can actually read and reason about at a gate).
So do not shard a build into more waves than the dependency graph forces.
Prefer fewer, fatter waves: put every currently-unblocked unit in the same wave, and let ringer's `max_parallel` and the stagger handle the width.
A plan with W=50 tiny waves is usually a mis-compiled W=8; collapse independent units into the same wave rather than serializing them for tidiness.
