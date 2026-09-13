#!/usr/bin/env bash
# ci/structure-check.sh - the eight structural checks over the shipped tree.
# Spec of record: plan 2026-09-13 B32, Task 3 step 1, checks A through H, in order.
# Each check prints its own ok: line; the script prints PASS: structure at the end.
#
# Neither the banned-token list (Check A) nor the skip list (Check B) is hard-coded
# here. Both live in committed data files read at run time: ci/banned-tokens.txt and
# ci/reference-allowlist.txt. The reason is deadlock: a port task that discovers a
# legitimate new reference would otherwise have to edit a check script owned by a
# finished task, so the list is data with append-only access and this script is code
# with one owner.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "STRUCTURE FAIL: $1" >&2; exit 1; }
ok() { printf 'ok: %s\n' "$1"; }

# ---------------------------------------------------------------------------
# Check A: banned tokens in shipped files.
# Every fixed string in ci/banned-tokens.txt must appear nowhere under skills/.
#
# One exclusion, never a glob: the docs/chain-state.md ban does not apply to
# skills/loop-setup/SKILL.md, because loop-setup's migration section must name
# docs/chain-state.md in order to delete it, and a skill that cannot name the file
# it deletes cannot document the deletion. Every other skill must still not
# mention it.
# ---------------------------------------------------------------------------
check_a() {
  local token hits
  while IFS= read -r token; do
    [ -n "$token" ] || continue
    if [ "$token" = "docs/chain-state.md" ]; then
      hits=$(grep -rInF "$token" skills/ 2>/dev/null | grep -v '^skills/loop-setup/SKILL\.md:' || true)
    else
      hits=$(grep -rInF "$token" skills/ 2>/dev/null || true)
    fi
    [ -z "$hits" ] || fail "check A: banned token '$token' appears in shipped files (allowed only in skills/loop-setup/SKILL.md for the docs/chain-state.md deletion naming):
$hits"
  done < <(sed 's/#.*$//' ci/banned-tokens.txt | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$')
  ok "A - no banned tokens under skills/"
}

# ---------------------------------------------------------------------------
# Check B: reference resolution.
# Every backticked token shaped like a relative file path in every skills/**/*.md
# must resolve at skills/<owning-skill>/<token>, unless it starts with docs/ or is
# allow-listed in ci/reference-allowlist.txt.
# ---------------------------------------------------------------------------
load_allowlist() {
  local line tok
  while IFS= read -r line; do
    tok=${line%%#*}
    tok=${tok//[[:space:]]/}
    [ -n "$tok" ] && ALLOWED[$tok]=1
  done < ci/reference-allowlist.txt
}

extract_backtick_tokens() {
  # prints "<file><TAB><line><TAB><token>" for every backticked span in every
  # skills/**/*.md that is shaped like a relative file path.
  local f span ln tok
  find skills -name '*.md' -type f | sort | while IFS= read -r f; do
    grep -noE '`[^`]+`' "$f" 2>/dev/null | while IFS=: read -r ln span; do
      tok=${span//\`/}
      if [[ $tok =~ ^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*\.(md|sh|yaml|yml|json|toml)$ ]]; then
        printf '%s\t%s\t%s\n' "$f" "$ln" "$tok"
      fi
    done
  done
}

check_b() {
  local f ln tok skill b_fail=""
  while IFS=$'\t' read -r f ln tok; do
    [ -n "$f" ] || continue
    case $tok in docs/*) continue ;; esac
    [ -n "${ALLOWED[$tok]:-}" ] && continue
    skill=${f#skills/}
    skill=${skill%%/*}
    if [ ! -e "skills/$skill/$tok" ]; then
      b_fail="$b_fail
  $f:$ln: backticked token '$tok' does not resolve at skills/$skill/$tok"
    fi
  done < <(extract_backtick_tokens)
  [ -z "$b_fail" ] || fail "check B: backticked references that do not resolve inside their owning skill (fix the reference, or append the token with a '# why' to ci/reference-allowlist.txt if it legitimately names something outside the skill):$b_fail"
  ok "B - every backticked file reference resolves inside its owning skill"
}

# ---------------------------------------------------------------------------
# Check C: byte equality of the five duplicated reference pairs.
# A pair whose files do not both exist yet is skipped, so the check is meaningful
# the moment a pair lands and vacuous before.
# ---------------------------------------------------------------------------
check_c() {
  local pair_ok=""
  pair() {
    local a="skills/$1" b="skills/$2"
    if [ ! -f "$a" ] || [ ! -f "$b" ]; then
      printf 'skip: byte-equality pair not yet landed (%s vs %s)\n' "$1" "$2"
      return 0
    fi
    cmp -s "$a" "$b" || fail "check C: $1 and $2 are not byte-identical; edit the canonical copy and re-copy, never hand-edit a duplicate"
    pair_ok="$pair_ok $1=$2"
  }
  pair loop-review/references/reviewer-conduct-contract.md loop-drive/references/reviewer-conduct-contract.md
  pair loop-brainstorm/references/brief-pipeline.md loop-improve/references/brief-pipeline.md
  pair loop-brainstorm/references/brief-pipeline.md loop-molt/references/brief-pipeline.md
  pair loop-brainstorm/references/tracker-scan.md loop-improve/references/tracker-scan.md
  pair loop-brainstorm/references/one-minute-test.md loop-drive/references/one-minute-test.md
  ok "C - duplicated references byte-identical:$pair_ok"
}

# ---------------------------------------------------------------------------
# Check D: the pre-plugin detection sentence, in the eight skills that need it.
# ---------------------------------------------------------------------------
check_d() {
  local name f
  for name in loop-auto loop-brainstorm loop-drive loop-improve loop-plan loop-track handoff wayfinder; do
    f="skills/$name/SKILL.md"
    [ -f "$f" ] || continue
    grep -qF '**Pre-plugin repo check.**' "$f" \
      || fail "check D: $f lacks the literal '**Pre-plugin repo check.**' detection sentence"
    grep -qF 'docs/loop/pointer.md' "$f" \
      || fail "check D: $f names no docs/loop/pointer.md; the detection sentence must point there"
  done
  ok "D - pre-plugin detection sentence present where required"
}

# ---------------------------------------------------------------------------
# Check E: the four stub wording markers in the three stub-carrying skills.
# ---------------------------------------------------------------------------
check_e() {
  local name f marker
  for name in loop-drive loop-plan loop-brainstorm; do
    f="skills/$name/SKILL.md"
    [ -f "$f" ] || continue
    for marker in '**Probe.**' '**Present:**' '**Absent:**' '**Disclose:**'; do
      grep -qF "$marker" "$f" \
        || fail "check E: $f lacks the stub marker '$marker'; all four Probe/Present/Absent/Disclose markers are required"
    done
  done
  ok "E - stub wording markers present where required"
}

# ---------------------------------------------------------------------------
# Check F: frontmatter shape of every skills/*/SKILL.md.
# ---------------------------------------------------------------------------
check_f() {
  local f first line n key seen_name seen_desc closed
  shopt -s nullglob
  for f in skills/*/SKILL.md; do
    IFS= read -r first < "$f" || first=""
    [ "$first" = "---" ] || fail "check F: $f does not open with a '---' frontmatter fence"
    seen_name=0
    seen_desc=0
    closed=0
    n=0
    while IFS= read -r line; do
      n=$((n + 1))
      [ "$n" -eq 1 ] && continue
      if [ "$line" = "---" ]; then
        closed=1
        break
      fi
      if [[ $line =~ ^([A-Za-z0-9-]+): ]]; then
        key=${BASH_REMATCH[1]}
        case $key in
          name) seen_name=1 ;;
          description) seen_desc=1 ;;
          argument-hint | disable-model-invocation) ;;
          *) fail "check F: $f line $n: frontmatter key '$key' is not one of name, description, argument-hint, disable-model-invocation" ;;
        esac
      fi
    done < "$f"
    [ "$closed" -eq 1 ] || fail "check F: $f frontmatter block is never closed by a second '---'"
    [ "$seen_name" -eq 1 ] || fail "check F: $f frontmatter carries no name: line"
    [ "$seen_desc" -eq 1 ] || fail "check F: $f frontmatter carries no description: line"
    if grep -qE '^fork:' "$f"; then
      fail "check F: $f contains a '^fork:' line; a bare fork key does not exist (the real key is context: fork, and jrit-loop never uses it)"
    fi
  done
  shopt -u nullglob
  ok "F - SKILL.md frontmatter keys are all recognized"
}

# ---------------------------------------------------------------------------
# Check G: no symlinks, no em dash in shipped markdown.
# ---------------------------------------------------------------------------
check_g() {
  local f em hit
  local symlinks
  symlinks=$(find skills -type l -print 2>/dev/null)
  [ -z "$symlinks" ] || fail "check G: symlinks under skills/ are forbidden (nothing in jrit-loop is symlinked):
$symlinks"
  em=$(printf '\xe2\x80\x94')
  # The sweep is all shipped markdown and only that: skills/**/*.md,
  # README.md, and docs/**/*.md. Nothing outside those roots (e.g. NOTES) is
  # house-style surface.
  while IFS= read -r f; do
    if hit=$(grep -nF "$em" "$f"); then
      fail "check G: $f contains the em dash character U+2014; house style is plain '-' only:
$hit"
    fi
  done < <(find skills docs README.md -name '*.md' -type f 2>/dev/null | sort)
  ok "G - no symlinks and no em dashes in shipped markdown"
}

# ---------------------------------------------------------------------------
# Check H: loop-drive's portable core names no harness primitive.
# Scans skills/loop-drive/SKILL.md and skills/loop-drive/references/* except
# harness-appendix-claude-code.md, and fails on the literal SendMessage, the
# backticked `Agent`, and the slash commands /goal and /loop.
#
# The slash patterns carry BOTH boundaries: a trailing class, ($|[^a-z-]), and
# a leading class, (^|[^A-Za-z0-9./]). Without the trailing class /loop-drive
# and /loop-plan would false-positive on every skill-name mention; without the
# leading boundary the path docs/loop/pointer.md that Check D itself requires
# would false-positive (leading boundary added 2026-09-13, resolving the proven
# Check D conflict at the wave-2 gate). The ban is on slash-command
# invocations, not on skill names or paths that share the substring.
#
# Exactly one sanctioned pointer sentence may name the appendix, so the core can
# say where the harness detail went without restating it; more than one such
# sentence fails, naming both.
# ---------------------------------------------------------------------------
slash_command_hit() {
  # slash_command_hit <line> <command>: true when <line> contains <command>
  # bounded on BOTH sides - the character before the slash, when one exists,
  # is not a letter, digit, '.', or '/', and the command sits at end-of-line
  # or is followed by a character outside [a-z-].
  printf '%s\n' "$1" | grep -qE '(^|[^A-Za-z0-9./])'"$2"'($|[^a-z-])'
}

check_h() {
  local f line ln_no ptr_count c pointers
  local h_files=()
  shopt -s nullglob
  [ -f skills/loop-drive/SKILL.md ] && h_files+=(skills/loop-drive/SKILL.md)
  local rf
  for rf in skills/loop-drive/references/*; do
    [ -f "$rf" ] || continue
    [ "$(basename "$rf")" = "harness-appendix-claude-code.md" ] && continue
    h_files+=("$rf")
  done
  if [ ${#h_files[@]} -gt 0 ]; then
    for f in "${h_files[@]}"; do
      ln_no=0
      while IFS= read -r line || [ -n "$line" ]; do
        ln_no=$((ln_no + 1))
        if [[ $line == *SendMessage* ]]; then
          fail "check H: $f:$ln_no names SendMessage; harness primitives live only in references/harness-appendix-claude-code.md"
        fi
        if [[ $line == *'`Agent`'* ]]; then
          fail "check H: $f:$ln_no names the backticked '\`Agent\`' tool; harness primitives live only in references/harness-appendix-claude-code.md"
        fi
        if slash_command_hit "$line" "/goal"; then
          fail "check H: $f:$ln_no invokes the /goal slash command; user-invoked slash commands cannot be invoked from skill prose (see the appendix instead)"
        fi
        if slash_command_hit "$line" "/loop"; then
          fail "check H: $f:$ln_no invokes the /loop slash command; user-invoked slash commands cannot be invoked from skill prose (see the appendix instead)"
        fi
      done < "$f"
    done
    ptr_count=0
    pointers=""
    for f in "${h_files[@]}"; do
      c=$(grep -cF 'harness-appendix-claude-code.md' "$f" || true)
      ptr_count=$((ptr_count + c))
      pointers="$pointers$(grep -nF 'harness-appendix-claude-code.md' "$f" 2>/dev/null | sed "s|^|$f:|")"
    done
    if [ "$ptr_count" -gt 1 ]; then
      fail "check H: the portable core names the appendix $ptr_count times; exactly one sanctioned pointer sentence is allowed:
$pointers"
    fi
    if [ -f skills/loop-drive/SKILL.md ] && [ "$ptr_count" -eq 0 ]; then
      fail "check H: skills/loop-drive/SKILL.md exists but its core never points to references/harness-appendix-claude-code.md; the split's contract is that the core says where the harness detail went"
    fi
  fi
  shopt -u nullglob
  ok "H - loop-drive portable core names no harness primitive, with at most one appendix pointer"
}

declare -A ALLOWED=()
load_allowlist
check_a
check_b
check_c
check_d
check_e
check_f
check_g
check_h
echo "PASS: structure"
