#!/usr/bin/env bash
# ci/consumer-sweep.sh - no session-history or consumer-generated artifacts ship
# in jrit-loop (criterion 11; run at Task 13 before the public flip).
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "CONSUMER-SWEEP FAIL: $1" >&2; exit 1; }

# docs/handoffs/ and docs/reviews/ are not swept: this repo dogfoods the loop, and docs/loop/pointer.md declares them as pointer-declared homes (owner ruling 2026-09-25).
strays=$(find . -path ./.git -prune -o \( -name conversation-archive.md -o -name learning_guide.html -o -name molt-ledger.md -o -path './docs/sessions/*' -o -path './logs/*' -o -path './.scratch/*' \) -print)
[ -z "$strays" ] || fail "consumer-generated session-history artifacts must not ship:
$strays"

echo "PASS: consumer-sweep"
