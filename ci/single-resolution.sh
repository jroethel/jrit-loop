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
  if [ -e "$HOME/.claude/skills/$n" ]; then
    count=$((count + 1))
    locs="$locs $HOME/.claude/skills/$n"
  fi
  if [ -e "$HOME/.agents/skills/$n" ]; then
    count=$((count + 1))
    locs="$locs $HOME/.agents/skills/$n"
  fi
  canon_found=0
  canon_locs=""
  if [ -f "$RECORD" ]; then
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if [ -e "$p" ]; then
        canon_found=1
        canon_locs="$canon_locs $p"
      fi
    done < <(jq -r --arg n "$n" \
      '(.plugins // {}) | to_entries | map(.value | map(.installPath // empty)) | flatten | map(. + "/skills/" + $n) | .[]' \
      "$RECORD" 2>/dev/null)
  fi
  if [ "$canon_found" -eq 1 ]; then
    count=$((count + 1))
    locs="$locs$canon_locs"
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
