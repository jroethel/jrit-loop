#!/usr/bin/env bash
# ci/run-all.sh - the single dev gate: the five read-only checks, then plugin
# validation when the claude binary is present (criterion 10).
#
# It does NOT run ci/clean-room-npx.sh or ci/single-resolution.sh: both are
# host-mutating (a throwaway HOME with real network installs; the host's
# installed-plugins record) and are manual, Task-14 checks by design.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "RUN-ALL FAIL: $1" >&2; exit 1; }

for s in ci/structure-check.sh ci/budget-check.sh ci/version-drift.sh ci/secrets-scan.sh ci/consumer-sweep.sh; do
  echo "== $s"
  bash "$s" || fail "$s exited non-zero"
done

if command -v claude >/dev/null 2>&1; then
  echo "== claude plugin validate --strict . (marketplace manifest)"
  claude plugin validate --strict . || fail "claude plugin validate --strict . failed"
  echo "== claude plugin validate --strict .claude-plugin/plugin.json (plugin manifest and components)"
  claude plugin validate --strict .claude-plugin/plugin.json || fail "claude plugin validate --strict .claude-plugin/plugin.json failed"
else
  echo "skip: claude plugin validate --strict . (claude binary not on PATH)"
  echo "skip: claude plugin validate --strict .claude-plugin/plugin.json (claude binary not on PATH)"
fi

echo "PASS: all"
