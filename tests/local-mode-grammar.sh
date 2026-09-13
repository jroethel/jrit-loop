#!/usr/bin/env bash
# tests/local-mode-grammar.sh - the D4 local-issues grammar round-trip.
# Pure-file test: everything happens inside one scratch directory this script
# creates and removes; no network and no tracker of any kind is consulted.
# Spec of record: plan 2026-09-13 B32, Task 8 step 12.
#
# Round-trip, not just render: build a docs/issues.md per the D4 grammar,
# simulate a create (append a new section AND bump the next-number marker in
# the same write), simulate a receipt (append one receipt line to a body),
# then parse the result back and assert all four grammar rules:
#   rule 1 - section numbers ascend;
#   rule 2 - state: then labels: are the first two lines after each heading;
#   rule 3 - state: is open or closed;
#   rule 4 - the marker equals the max section number plus one.
set -uo pipefail

fail() { echo "FAIL: $1" >&2; exit 1; }

TMP=$(mktemp -d) || fail "cannot create scratch directory"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/docs" || fail "cannot create scratch docs directory"
ISSUES="$TMP/docs/issues.md"

# ---------------------------------------------------------------------------
# Render the initial file per the D4 grammar: two sections, marker at 3.
# ---------------------------------------------------------------------------
cat > "$ISSUES" <<'EOF'
# Issues

<!-- next-number: 3 -->

## #1 Fix the export job
state: open
labels: idea, agent:todo

Body prose for issue 1.

## #2 Glossary move
state: closed
labels: agent:done

Body prose for issue 2.
EOF

# ---------------------------------------------------------------------------
# Simulate a create: section #3 is appended and the marker is bumped 3 -> 4
# in the SAME write (one read, one transformed write, never two edits).
# ---------------------------------------------------------------------------
content=$(cat "$ISSUES") || fail "cannot read $ISSUES"
bumped=${content//<!-- next-number: 3 -->/<!-- next-number: 4 -->}
[ "$bumped" != "$content" ] || fail "create simulation: the marker rewrite matched nothing, so the bump did not happen"
new_section='## #3 Retry on 504
state: open
labels: agent:todo

Body prose for issue 3.'
printf '%s\n\n%s\n' "$bumped" "$new_section" > "$ISSUES" || fail "cannot write $ISSUES back after the create"

# ---------------------------------------------------------------------------
# Simulate a receipt: append one receipt line to the body of the last section.
# ---------------------------------------------------------------------------
ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ') || fail "cannot produce a UTC ISO-8601 timestamp"
printf '> receipt %s: AGENT STATUS unit=test verdict=pass repairs=0\n' "$ts" >> "$ISSUES" \
  || fail "cannot append the receipt line to the body"

# ---------------------------------------------------------------------------
# Parse the result back and assert the four grammar rules.
# ---------------------------------------------------------------------------

# Rule 1: sections appear in ascending number order.
prev=0
while IFS= read -r n; do
  [ -n "$n" ] || continue
  [ "$n" -gt "$prev" ] || fail "rule 1 (ascending sections): section #$n follows #$prev, so numbers do not ascend"
  prev=$n
done < <(grep -oE '^## #[0-9]+' "$ISSUES" | grep -oE '[0-9]+$')
[ "$prev" -ge 1 ] || fail "rule 1 (ascending sections): no '## #<n>' headings parsed back from the file"
max=$prev

# Rule 2: state: and labels: are the first two lines after each heading, in that order.
r2=$(awk '/^## #/ { s = ""; l = ""
  if ((getline s) <= 0 || (getline l) <= 0 || s !~ /^state: / || l !~ /^labels: /)
    printf "after heading '%s' the first two lines are '%s' and '%s'\n", $0, s, l
}' "$ISSUES")
[ -z "$r2" ] || fail "rule 2 (state then labels as the first two lines after each heading): $r2"

# Rule 3: state: is open or closed.
r3=$(grep -n '^state: ' "$ISSUES" | grep -v -E '^[0-9]+:state: (open|closed)$')
if [ -n "$r3" ]; then
  fail "rule 3 (state is open or closed): offending state line(s):
$r3"
fi

# Rule 4: the marker equals the max section number plus one.
marker_count=$(sed -n 's/^<!-- next-number: [0-9][0-9]* -->$/x/p' "$ISSUES" | wc -l)
[ "$marker_count" -eq 1 ] || fail "rule 4 (marker = max + 1): expected exactly one next-number marker line, found $marker_count"
marker=$(sed -n 's/^<!-- next-number: \([0-9][0-9]*\) -->$/\1/p' "$ISSUES")
[ "$marker" -eq $((max + 1)) ] \
  || fail "rule 4 (marker = max + 1): marker is $marker, but the max section number is $max, so the marker should be $((max + 1))"

# Round-trip evidence: the create landed as a third section, and the receipt
# line sits in a body in the mandated shape.
sections=$(grep -c '^## #' "$ISSUES")
[ "$sections" -eq 3 ] || fail "create round-trip: expected 3 sections after the simulated create, found $sections"
grep -qE '^> receipt [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z: ' "$ISSUES" \
  || fail "receipt round-trip: no '> receipt <UTC ISO-8601>: <text>' line found in a body after the append"

echo "PASS: local-mode grammar round-trip"
