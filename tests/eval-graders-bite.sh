#!/usr/bin/env bash
# tests/eval-graders-bite.sh - static proof that every regex grader under
# evals/*/graders/ bites: it passes a committed good sample and fails a
# committed bad sample, with no model call (#36 criterion 3).
# Samples live at tests/fixtures/eval-graders/<case>/<grader>.pass.txt and
# .fail.txt; a sample with no matching regex grader is an orphan and fails.
# Runner semantics mirrored here, verified 2026-10-17 against the regex grader
# in the shipped claude 2.1.294 binary: new RegExp(pattern, flags); match
# defaults to contains; contains and not_contains use .test without g; count:N
# adds g and counts String.prototype.match results; flags must match
# ^[dgimsuvy]*$; a {source: file} target whose file is missing fails the grader.
# Pattern, flags, and match values must be bare or YAML double-quoted
# (parsed with JSON.parse); single-quoted values are rejected.
# The node block also prints one "llm: <path>" line per llm grader.
set -uo pipefail
fail() { echo "FAIL: $1" >&2; exit 1; }
cd "$(dirname "${BASH_SOURCE[0]}")/.." || fail "cannot reach the repo root"
command -v node >/dev/null 2>&1 || fail "node is not on PATH"
out="$(mktemp)" || fail "cannot create a temp file"
trap 'rm -f "$out"' EXIT

node - >"$out" <<'JS'
const fs = require('fs'), path = require('path');
const FIX = 'tests/fixtures/eval-graders';
const regexGraders = new Set();
let n = 0, bad = 0;
const err = (m) => { console.error('FAIL: ' + m); bad++; };
for (const c of fs.readdirSync('evals').sort()) {
  const gd = path.join('evals', c, 'graders');
  if (!fs.existsSync(gd)) continue;
  for (const g of fs.readdirSync(gd).filter((f) => f.endsWith('.md')).sort()) {
    const name = c + '/' + g.replace(/\.md$/, '');
    const fm = (fs.readFileSync(path.join(gd, g), 'utf8').match(/^---\n([\s\S]*?)\n---/) || [])[1] || '';
    const field = (k) => {
      const m = fm.match(new RegExp('^' + k + ':[ \\t]*(.*)$', 'm'));
      if (!m) return undefined;
      const v = m[1].trim();
      if (v.startsWith("'")) throw new Error(k + ': single-quoted values unsupported; use double quotes');
      if (!v.startsWith('"')) return v;
      try { return JSON.parse(v); } catch (e) { throw new Error('cannot parse ' + k + ': ' + e.message); }
    };
    let type, pattern, flags, match;
    try { type = field('type'); } catch (e) { err(name + ': ' + e.message); continue; }
    if (type === 'llm') { console.log('llm: ' + path.join(gd, g)); continue; }
    if (type !== 'regex') continue;
    regexGraders.add(name);
    n++;
    try { pattern = field('pattern'); flags = field('flags') || ''; match = field('match') || 'contains'; }
    catch (e) { err(name + ': ' + e.message); continue; }
    if (pattern === undefined) { err(name + ': no pattern in frontmatter'); continue; }
    if (!/^[dgimsuvy]*$/.test(flags)) { err(name + ': flags "' + flags + '" are outside [dgimsuvy]'); continue; }
    const count = /^count:(\d+)$/.exec(match);
    if (!['contains', 'not_contains'].includes(match) && !count) { err(name + ': unknown match ' + match); continue; }
    let re, reG;
    try { re = new RegExp(pattern, flags); reG = new RegExp(pattern, flags.includes('g') ? flags : flags + 'g'); }
    catch (e) { err(name + ': invalid pattern: ' + e.message); continue; }
    const passes = (text) => count ? (text.match(reG) || []).length === Number(count[1]) : re.test(text) === (match === 'contains');
    let ok = true;
    for (const kind of ['pass', 'fail']) {
      const f = path.join(FIX, c, g.replace(/\.md$/, '') + '.' + kind + '.txt');
      if (!fs.existsSync(f)) { err(name + ': missing sample ' + f); ok = false; continue; }
      if (passes(fs.readFileSync(f, 'utf8')) !== (kind === 'pass')) { err(name + ': the grader ' + (kind === 'pass' ? 'fails its pass' : 'passes its fail') + ' sample ' + f); ok = false; }
    }
    if (ok) console.log('ok: ' + name);
  }
}
if (fs.existsSync(FIX)) {
  for (const c of fs.readdirSync(FIX).sort()) {
    const cd = path.join(FIX, c);
    for (const s of fs.statSync(cd).isDirectory() ? fs.readdirSync(cd).sort() : ['']) {
      const m = /^(.+)\.(pass|fail)\.txt$/.exec(s);
      if (!m || !regexGraders.has(c + '/' + m[1])) err('orphan sample ' + path.join(cd, s) + ': no regex grader evals/' + c + '/graders/' + (m ? m[1] : s) + '.md');
    }
  }
}
if (n === 0) err('no regex graders found under evals/*/graders/');
if (bad) process.exit(1);
console.log('PASS: ' + n + ' regex graders bite');
JS
rc=$?
cat "$out"
[ "$rc" = 0 ] || exit 1

# Criterion 1 of #36: an llm grader survives only where the Kept llm graders
# table in docs/eval-fixtures-are-engine-neutral.md lists it with a reason.
# The llm grader list is the node block's "llm: <path>" lines, so one
# frontmatter parser decides every grader's type.
D=docs/eval-fixtures-are-engine-neutral.md
rows="$(sed -n '/^## Kept llm graders$/,/^## /p' "$D" | grep '^| `' || true)"
kept=0
while IFS= read -r g; do
  [ -n "$g" ] || continue
  printf '%s\n' "$rows" | grep -qF "| \`$g\` " || fail "$g is an llm grader missing from the Kept llm graders table in $D"
  kept=$((kept + 1))
done < <(sed -n 's/^llm: //p' "$out")
while IFS= read -r r; do
  [ -n "$r" ] || continue
  [ -n "$(printf '%s\n' "$r" | cut -d'|' -f3 | tr -d '[:space:]')" ] || fail "a Kept llm graders row in $D has no reason: $r"
done <<< "$rows"
echo "PASS: $kept llm graders kept, each listed with a reason"
