#!/usr/bin/env bash
# ci/clean-room-npx.sh - prove the PUBLIC npx install path in a throwaway HOME.
#
# RUN THIS ONLY AT TASK 14, AFTER HUMAN CHECKPOINT C4 (the repo going public).
# It proves the public install path and must never be run against a private
# remote: it fetches jroethel/jrit-loop anonymously from inside a throwaway HOME
# with no credentials, so a private remote returns not-found rather than a
# meaningful failure. If you are running it before C4, the red you get is this
# script running early, not a defect.
#
# Isolation pattern modelled on loop-stack's scripts/clean-room.sh: a mktemp -d
# sandbox, HOME exported into it, an rm -rf trap on exit, and the real HOME is
# never touched.
#
# Installer flags verified 2026-09-13 against 'npx skills --help' (skills 1.5.26):
#   -s, --skill <skills>   specify skill names to install
#   -y                     skip confirmation prompts (needed for non-interactive runs)
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)" || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "CLEAN-ROOM-NPX FAIL: $1" >&2; exit 1; }

NAMES="handoff loop-auto loop-brainstorm loop-drive loop-improve loop-molt loop-plan loop-review loop-setup loop-track wayfinder"

SANDBOX="$(mktemp -d)" || fail "mktemp -d failed"
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home"
mkdir -p "$HOME" || fail "could not create the sandbox HOME"

# Resolve and print the exact skills package version, on a machine-readable line,
# because Task 14 pins this value into the README's npx route.
SKILLS_VERSION="$(npx --yes skills --version 2>/dev/null)" || fail "could not resolve the skills package version"
echo "skills-package-version: $SKILLS_VERSION"

# The Check B skip list applies to installed copies exactly as it does to the
# source tree: an allow-listed token names something outside the skill by design.
declare -A ALLOWED=()
while IFS= read -r line; do
  tok=${line%%#*}
  tok=${tok//[[:space:]]/}
  [ -n "$tok" ] && ALLOWED[$tok]=1
done < "$REPO/ci/reference-allowlist.txt"

# Extractor mirroring check B in ci/structure-check.sh: every backticked span
# shaped like a relative file path, printed as "<file><TAB><line><TAB><token>".
extract_backtick_tokens() {
  local f span ln tok
  find "$1" -name '*.md' -type f | sort | while IFS= read -r f; do
    grep -noE '`[^`]+`' "$f" 2>/dev/null | while IFS=: read -r ln span; do
      tok=${span//\`/}
      if [[ $tok =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*\.(md|sh|yaml|yml|json|toml)$ ]]; then
        printf '%s\t%s\t%s\n' "$f" "$ln" "$tok"
      fi
    done
  done
}

for name in $NAMES; do
  npx --yes skills add jroethel/jrit-loop --skill "$name" -y -g \
    || fail "npx skills add jroethel/jrit-loop --skill $name did not exit 0"
  inst=""
  for cand in "$HOME/.claude/skills/$name" "$HOME/.agents/skills/$name"; do
    if [ -e "$cand" ]; then
      inst="$cand"
      break
    fi
  done
  [ -n "$inst" ] || fail "installed copy of $name not found under the sandbox HOME ($HOME/.claude/skills/$name or $HOME/.agents/skills/$name)"

  # Every backticked file token in the installed copy must resolve inside it.
  b_fail=""
  while IFS=$'\t' read -r f ln tok; do
    [ -n "$f" ] || continue
    case $tok in docs/*) continue ;; esac
    [ -n "${ALLOWED[$tok]:-}" ] && continue
    if [ ! -e "$inst/$tok" ]; then
      b_fail="$b_fail
  $f:$ln: backticked token '$tok' does not resolve inside the installed skill at $inst/$tok"
    fi
  done < <(extract_backtick_tokens "$inst")
  [ -z "$b_fail" ] || fail "installed $name has dangling reads (criterion 3):$b_fail"

  if [ "$name" = "loop-drive" ]; then
    [ -f "$inst/scripts/receipt.sh" ] || fail "installed loop-drive lacks scripts/receipt.sh; the helper did not survive the npx copy"
    out="$(bash "$inst/scripts/receipt.sh" 2>&1)"
    rc=$?
    [ "$rc" -ne 0 ] || fail "bash scripts/receipt.sh with no arguments exited 0; it must print usage and exit non-zero"
    case "$out" in
      *usage* | *Usage*) : ;;
      *) fail "bash scripts/receipt.sh with no arguments printed no usage line; output was: $out" ;;
    esac
    # Informational only, no assertion: the invocation form is 'bash scripts/receipt.sh'
    # precisely so the execute bit cannot break anything, but the answer is worth knowing.
    if [ -x "$inst/scripts/receipt.sh" ]; then
      echo "info: execute bit survived the npx copy for loop-drive/scripts/receipt.sh"
    else
      echo "info: execute bit did not survive the npx copy (harmless: the fixed invocation form is 'bash scripts/receipt.sh')"
    fi
  fi
  echo "ok: $name installed and every backticked token resolves"
done

# The placeholder is legitimate from Task 2 through Task 13 and becomes a defect
# only here, at Task 14, which is why this assertion lives in this script rather
# than in ci/version-drift.sh.
if grep -qF '<VERSION>' "$REPO/README.md"; then
  fail "README.md still contains the <VERSION> placeholder; pin the real skills package version ($SKILLS_VERSION) into the npx route"
fi

echo "PASS: clean-room"
