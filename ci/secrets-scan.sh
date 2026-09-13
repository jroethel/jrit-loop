#!/usr/bin/env bash
# ci/secrets-scan.sh - secret scan over the working tree, and over full history
# when --full-history is passed as the first argument (criterion 9; Task 13 runs
# the full-history pass before the public flip).
#
# Engine: gitleaks when it is on PATH, else a fixed-pattern grep fallback. Which
# engine ran is always printed, so a fallback run is never mistaken for a
# gitleaks run.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "FAIL: cannot reach the repo root" >&2; exit 1; }

fail() { echo "SECRETS FAIL: $1" >&2; exit 1; }

PATTERNS=(
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'glpat-[A-Za-z0-9_-]{20,}'
  'sk-[A-Za-z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
)

pattern_args=()
for p in "${PATTERNS[@]}"; do pattern_args+=(-e "$p"); done

if command -v gitleaks >/dev/null 2>&1; then
  echo "engine: gitleaks"
  gitleaks detect --source . --redact --exit-code 1 \
    || fail "gitleaks found secrets in the working tree (see the report above)"
  if [ "${1:-}" = "--full-history" ]; then
    gitleaks detect --source . --redact --log-opts="--all" --exit-code 1 \
      || fail "gitleaks found secrets in the full history (see the report above)"
  fi
else
  echo "engine: grep fallback (gitleaks not on PATH)"
  hits=$(grep -rInE --exclude-dir=.git "${pattern_args[@]}" . || true)
  [ -z "$hits" ] || fail "secret-shaped hits in the working tree:
$hits"
  if [ "${1:-}" = "--full-history" ]; then
    hh=$(git log -p --all | grep -nE "${pattern_args[@]}" || true)
    [ -z "$hh" ] || fail "secret-shaped hits in the full history:
$hh"
  fi
fi

echo "PASS: secrets"
