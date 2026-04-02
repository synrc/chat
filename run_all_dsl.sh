#!/usr/bin/env bash

set -euo pipefail

DIR="${1:-docs}"
RUNNER="tools/dsl_runner.py"

if [[ ! -d "$DIR" ]]; then
  echo "Directory not found: $DIR"
  exit 1
fi

TOTAL=0
PASSED=0
FAILED=0

echo "Running DSL in: $DIR"
echo

for file in $(find "$DIR" -type f -name "*.md" | sort); do
  base="$(basename "$file")"

  if [[ "$base" == "DSL-CORE.md" ]]; then
    continue
  fi

  # перевірка чи є хоч один scenario
  if ! grep -q "^scenario " "$file"; then
    continue
  fi

  TOTAL=$((TOTAL + 1))

  echo "==> $file"

  if python "$RUNNER" "$file"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi

  echo
done

echo "==== GLOBAL SUMMARY ===="
echo "files:   $TOTAL"
echo "passed:  $PASSED"
echo "failed:  $FAILED"

if [[ $FAILED -ne 0 ]]; then
  exit 1
fi