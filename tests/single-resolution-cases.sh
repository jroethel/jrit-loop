#!/usr/bin/env bash
# tests/single-resolution-cases.sh - sandbox cases for ci/single-resolution.sh
# after the skills-CLI (.agents) collapse amendment. Each case builds a throwaway
# HOME, lays out all ten names in one shape, runs the check, and asserts the
# exit code. Nothing outside the sandbox HOME is touched.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)" || { echo "FAIL: cannot reach repo root" >&2; exit 1; }
CHECK="$REPO/ci/single-resolution.sh"
NAMES="handoff loop-auto loop-brainstorm loop-drive loop-improve loop-plan loop-review loop-setup loop-track wayfinder"

command -v jq >/dev/null 2>&1 || { echo "FAIL: jq required (ci/single-resolution.sh needs it)" >&2; exit 1; }

fails=0

empty_record() { mkdir -p "$1/.claude/plugins"; echo '{"version":2,"plugins":{}}' > "$1/.claude/plugins/installed_plugins.json"; }

# Plugin model: nothing in .claude/skills or .agents/skills; one canonical
# installPath under the plugin cache. Expect PASS.
build_plugin() {
  local h="$1" ip="$1/.claude/plugins/cache/jrit-loop/jrit-loop/0.1.0"
  mkdir -p "$h/.claude/plugins"
  printf '{"version":2,"plugins":{"jrit-loop@jrit-loop":[{"scope":"user","installPath":"%s"}]}}' "$ip" \
    > "$h/.claude/plugins/installed_plugins.json"
  for n in $NAMES; do mkdir -p "$ip/skills/$n"; done
}

# Skills-CLI layout: real copy in .agents/skills, symlink from .claude/skills.
# One physical copy, two paths. Expect PASS (the amendment's new case).
build_skills_cli() {
  local h="$1"; empty_record "$h"; mkdir -p "$h/.claude/skills" "$h/.agents/skills"
  for n in $NAMES; do
    mkdir -p "$h/.agents/skills/$n"
    ln -s "$h/.agents/skills/$n" "$h/.claude/skills/$n"
  done
}

# Pre-decommission farm: .agents/skills/<n> is a symlink into a repo checkout,
# .claude/skills/<n> symlinks to it. Two farm paths. Expect FAIL.
build_farm() {
  local h="$1"; empty_record "$h"; mkdir -p "$h/.claude/skills" "$h/.agents/skills" "$h/src/repo/skills"
  for n in $NAMES; do
    mkdir -p "$h/src/repo/skills/$n"
    ln -s "$h/src/repo/skills/$n" "$h/.agents/skills/$n"
    ln -s "$h/.agents/skills/$n" "$h/.claude/skills/$n"
  done
}

# --copy install: two real directories, no symlink. Two physical copies. Expect FAIL.
build_two_copies() {
  local h="$1"; empty_record "$h"; mkdir -p "$h/.claude/skills" "$h/.agents/skills"
  for n in $NAMES; do mkdir -p "$h/.agents/skills/$n" "$h/.claude/skills/$n"; done
}

run_case() {
  local desc="$1" want="$2" builder="$3"
  local sb; sb="$(mktemp -d)" || { echo "FAIL: mktemp -d"; fails=$((fails + 1)); return; }
  "$builder" "$sb"
  HOME="$sb" bash "$CHECK" >/dev/null 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then
    echo "ok: $desc (exit $got as expected)"
  else
    echo "FAIL: $desc (exit $got, wanted $want)"
    fails=$((fails + 1))
  fi
  rm -rf "$sb"
}

run_case "plugin model resolves once"                    0 build_plugin
run_case "skills-CLI .agents layout counts as one"       0 build_skills_cli
run_case "pre-decommission farm still fails"             1 build_farm
run_case "two real copies (--copy) still fails"          1 build_two_copies

[ "$fails" -eq 0 ] || { echo "FAIL: $fails single-resolution case(s) failed" >&2; exit 1; }
echo "PASS: single-resolution cases"
