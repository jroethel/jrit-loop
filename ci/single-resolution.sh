#!/usr/bin/env bash
# ci/single-resolution.sh - after decommission (human checkpoint C3), each of the
# eleven skill names must resolve from EXACTLY ONE location (criterion 12).
# Run once per host that carried the symlink farm, at Task 14.
#
# Host record verified at write time, 2026-09-13, with 'ls ~/.claude/plugins/'
# and 'jq': the plugin runtime's installed-plugins record is
#   ~/.claude/plugins/installed_plugins.json
# and its shape is
#   { "version": 2,
#     "plugins": {
#       "<plugin>@<marketplace>": [
#         { "scope": "user", "installPath": "<abs path under plugins/cache>",
#           "version": "...", "installedAt": "...", "lastUpdated": "...",
#           "gitCommitSha": "..." } ] } }
# The canonical installed location for skill <n> is <installPath>/skills/<n>,
# taken from that record.
#
# This check counts COPIES, not collisions, and the distinction is the whole
# check. A globbed 'find ~/.claude/plugins/ -name <n>' counts a legitimately
# installed plugin two or three times over, because the same plugin exists under
# marketplaces/ as a cloned source tree and under cache/ as a resolved version
# tree; a correct install would report 3 and fail. The marketplaces/ and cache/
# trees are therefore excluded by construction - the installed path is read from
# the runtime's record, never globbed - while ~/.claude/skills and
# ~/.agents/skills are checked directly because that is where the symlink farm
# lived.
#
# One layout is deliberately counted as a SINGLE resolution even though it
# populates both of those directories: the skills-CLI (npx skills add) install,
# where ~/.agents/skills/<n> is a real directory and ~/.claude/skills/<n> is a
# symlink into it. That is one physical copy reached by two paths - Claude Code
# only reads ~/.claude/skills, so the symlink is mandatory. It is distinguished
# from the pre-decommission farm, whose ~/.agents/skills/<n> hop is itself a
# symlink to a repo checkout, by the real-directory test in the loop below.
set -uo pipefail

fail() { echo "SINGLE-RESOLUTION FAIL: $1" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || fail "jq is required by ci/single-resolution.sh and is not on PATH"

RECORD="$HOME/.claude/plugins/installed_plugins.json"

NAMES="handoff loop-auto loop-brainstorm loop-drive loop-improve loop-molt loop-plan loop-review loop-setup loop-track wayfinder"

if [ ! -f "$RECORD" ]; then
  echo "info: no installed-plugins record at $RECORD; the canonical installed location resolves for no name"
fi

bad=""
for n in $NAMES; do
  count=0
  locs=""
  # Skills-CLI cross-tool layout collapses to one resolution: the real copy is a
  # directory at ~/.agents/skills/<n> and ~/.claude/skills/<n> is a symlink into
  # it, so the same physical copy reached by two paths counts once. The farm is
  # NOT collapsed: there ~/.agents/skills/<n> is itself a symlink into a repo
  # checkout, so the -d/! -L test fails and both paths count, which is the
  # duplication this check exists to catch.
  claude_p="$HOME/.claude/skills/$n"
  agents_p="$HOME/.agents/skills/$n"
  collapsed=0
  if [ -d "$agents_p" ] && [ ! -L "$agents_p" ] && [ -L "$claude_p" ]; then
    cp_real="$(cd "$claude_p" 2>/dev/null && pwd -P)"
    ap_real="$(cd "$agents_p" 2>/dev/null && pwd -P)"
    if [ -n "$ap_real" ] && [ "$cp_real" = "$ap_real" ]; then
      collapsed=1
      count=$((count + 1))
      locs="$locs $agents_p (with $claude_p symlinked into it)"
    fi
  fi
  if [ "$collapsed" -eq 0 ]; then
    if [ -e "$claude_p" ]; then
      count=$((count + 1))
      locs="$locs $claude_p"
    fi
    if [ -e "$agents_p" ]; then
      count=$((count + 1))
      locs="$locs $agents_p"
    fi
  fi
  canon_paths=""
  if [ -f "$RECORD" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if [ -e "$p" ]; then
        canon_paths="${canon_paths}${p}"$'\n'
      fi
    done < <(jq -r --arg n "$n" \
      '(.plugins // {}) | to_entries | map(.value | map(.installPath // empty)) | flatten | map(. + "/skills/" + $n) | .[]' \
      "$RECORD" 2>/dev/null)
  fi
  # Count DISTINCT canonical paths: the record can name the same installPath
  # more than once (that is still one copy), but two distinct resolved paths
  # are two real installed copies, and collapsing them to one hid exactly the
  # duplication this check exists to catch.
  canon_n=0
  if [ -n "$canon_paths" ]; then
    canon_paths=$(printf '%s' "$canon_paths" | sort -u)
    canon_n=$(printf '%s\n' "$canon_paths" | grep -c '')
  fi
  if [ "$canon_n" -gt 1 ]; then
    fail "$n resolves from $canon_n distinct canonical installed locations; two real installed copies are two locations, not one:
$(printf '%s\n' "$canon_paths" | sed 's/^/  /')"
  fi
  if [ "$canon_n" -eq 1 ]; then
    count=$((count + 1))
    locs="$locs $canon_paths"
  fi
  if [ "$count" -ne 1 ]; then
    bad="$bad
  $n resolves from $count locations (expected exactly 1):$locs"
  else
    echo "ok: $n resolves from exactly 1 location"
  fi
done

[ -z "$bad" ] || fail "these skill names do not resolve from exactly one location:$bad"

echo "PASS: single-resolution"
