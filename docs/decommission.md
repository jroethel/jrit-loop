# Decommissioning the symlink farm

Staged by Task 12 of the B32 plugin port, 2026-09-13.
Nothing on this page has been run; every command block is Jeremy's to fire at human checkpoint C3, which itself fires only after checkpoint C4 has flipped the repo public.

## 1. Why the farm has to go

Eleven skill names currently resolve through a two-hop symlink farm, verified on this host 2026-09-13.
The outer hop is `$HOME/.claude/skills/<n>` pointing at `$HOME/.agents/skills/<n>`.
The inner hop is `$HOME/.agents/skills/<n>` pointing at `~/repos/loop-stack-session/skills/<n>` in the loop-stack-session checkout.
The eleven names are handoff, loop-auto, loop-brainstorm, loop-drive, loop-improve, loop-molt, loop-plan, loop-review, loop-setup, loop-track, and wayfinder.
Once the plugin is installed, each of those names also resolves from the plugin's own skills directory, so every name would resolve from two places at once.
Two resolutions per name is not a stable end state: session startup picks one by a precedence you do not control, and the losing copy silently drifts.
The farm therefore comes down after the install is verified, in the order Section 2 stages.

## 2. The staged cutover commands

These are Jeremy's to fire at C3, in this order, verbatim.
Between step 1 and step 4 each of the eleven names resolves twice, which is expected and transient.
Removing first would leave Jeremy with zero working skills if the install fails, which is the one outcome the ordering must not allow; a transient double resolution is recoverable, an empty toolkit mid-session is not.
The `jroethel/jrit-loop` marketplace form works because C3 fires after C4 has flipped the repo public, so the repo is public by then; this is also exactly the install path a stranger takes, so the decommission dogfoods it.

```bash
# 1. Install the plugin from the public self-marketplace.
claude plugin marketplace add jroethel/jrit-loop
claude plugin install jrit-loop@jrit-loop

# 2. Verify the plugin lists its skills before anything is removed.
claude plugin list

# 3. Remove the outer hop.
rm -f $HOME/.claude/skills/{handoff,loop-auto,loop-brainstorm,loop-drive,loop-improve,loop-molt,loop-plan,loop-review,loop-setup,loop-track,wayfinder}

# 4. Remove the inner hop.
rm -f $HOME/.agents/skills/{handoff,loop-auto,loop-brainstorm,loop-drive,loop-improve,loop-molt,loop-plan,loop-review,loop-setup,loop-track,wayfinder}

# 5. Verify exactly one resolution per name.
bash ~/repos/jrit/jrit-loop/ci/single-resolution.sh
```

Stop after step 2 if the plugin does not list its skills; nothing has been removed at that point, so the farm is untouched and the failed install costs nothing.

## 3. Rollback

A failed cutover is one command from reverted: recreate both hops of the farm in the shape verified on this host.

```bash
for n in handoff loop-auto loop-brainstorm loop-drive loop-improve loop-molt loop-plan loop-review loop-setup loop-track wayfinder; do
  ln -sfn ~/repos/loop-stack-session/skills/$n ~/.agents/skills/$n
  ln -sfn ~/.agents/skills/$n ~/.claude/skills/$n
done
```

The inner hop points each name back at `~/repos/loop-stack-session/skills/<n>`, and the outer hop points back at the inner, restoring the two-hop farm rather than substituting a flat one-hop layout.
The `-fn` flags make the loop idempotent, so it also repairs a half-removed farm where some names still have a link in place.
If the plugin install itself succeeded and the farm is being restored anyway, the plugin must also be removed for a full reversion; until then each name resolves twice, the same transient state the cutover itself passes through.

## 4. The orphaned global managed block

`$HOME/.claude/CLAUDE.md` carries a loop-stack block delimited by these two marker lines, found at lines 101 and 110 on this host:

```
# --- loop-stack (managed) ---
# --- end loop-stack (managed) ---
```

Nothing in the plugin model writes or reads that block, so once the farm is gone it is orphaned instruction text that still loads into every session.
Stage its removal: delete everything from the opening marker through the closing marker inclusive, touching no other line of the file.
A backup first, then a line-anchored delete, does exactly that:

```bash
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.pre-c3.bak
sed -i '/^# --- loop-stack (managed) ---$/,/^# --- end loop-stack (managed) ---$/d' ~/.claude/CLAUDE.md
```

Its content is Fable-era routing and safeguard policy, and its disposition is Jeremy's call at C3.
Option A: the parts he still wants move into his own hand-maintained CLAUDE.md as ordinary hand-edited text.
Option B: the block is dropped entirely, and nothing replaces it.
Answer at C3: pending; this line is where the answer gets recorded when he gives it.
The parked Fable-retirement idea, migrated as old #61, is the follow-up home for the broader question; this step only removes the orphan.

## 5. Per-repo mirror deletion

C3 and criterion 12 are per-host, not per-plan: they run once on every host that carries the symlink farm, and the host list is confirmed with Jeremy at the C3 handoff rather than assumed from this one.
For each rolled repo, the migration that loop-setup performs deletes `ISSUES.md`, `BACKLOG.md`, `WAYFINDER.md`, and `docs/chain-state.md` rather than freezing them.
It leaves `config/repo-state.md` and `config/conventions.md` in place for the human to remove.

The repo list is resolved with this command, not with a one-level glob:

```bash
find $HOME/repos -maxdepth 3 -path '*/config/repo-state.md' | while read -r f; do grep -q '^tracker:' "$f" && echo "$f"; done
```

The glob form `grep -rl '^tracker:' $HOME/repos/*/config/repo-state.md` only matches a repo sitting exactly one level under `$HOME/repos`, and this plan's own target lives at `~/repos/jrit/jrit-loop`, two levels down, so the shallow form is demonstrably wrong on this very host.
The unanchored grep would also match a `tracker:` appearing mid-line in prose.

Resolved on this host, 2026-09-13, with the line-anchored filter:

- `~/repos/rubix-review/config/repo-state.md`
- `~/repos/vaultwise/config/repo-state.md`
- `~/repos/loop-stack-session/config/repo-state.md`

Resolved count: 3.
The brief claimed eight rolled repos; the mismatch was reconciled with Jeremy at the C3 handoff on 2026-09-13.
A widened sweep (depth 5 across ~/repos, ~/claude, ~/projects, and ~/.claude, at Jeremy's direction) found the same three repos and nothing more, so the brief's eight was stale and the three-repo list above is the confirmed migration surface.
One property of the prescribed command belongs in that reconciliation: `-maxdepth 3` reaches `config/repo-state.md` only for a repo sitting exactly one level under `$HOME/repos`, because the file adds two more levels of its own; a repo nested two levels down places the file at depth four, outside the sweep.
So if any of the missing five repos are nested two levels deep, this command cannot see them however many there are, and the C3 handoff should decide whether to re-resolve with a deeper `-maxdepth` or a different scope.
loop-stack-session itself appearing in the resolved list is a membership question for the same reconciliation: it is the source checkout the farm points at, not obviously a repo to migrate.
