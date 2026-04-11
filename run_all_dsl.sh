#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$SCRIPT_DIR"
RUNNER="$REPO_ROOT/tools/dsl_runner.py"

DSL_DIRS=(
  "$REPO_ROOT/docs/dsl/domain"
  "$REPO_ROOT/docs/dsl/advanced"
  "$REPO_ROOT/docs/extensions/auth"
  "$REPO_ROOT/docs/extensions/abac"
  "$REPO_ROOT/docs/extensions/search"
)

if [[ ! -f "$RUNNER" ]]; then
  echo "Runner not found: $RUNNER"
  exit 1
fi

TOTAL=0
PASSED=0
FAILED=0

echo "Running DSL scenarios from configured directories..."
echo

for dir in "${DSL_DIRS[@]}"; do
  if [[ ! -d "$dir" ]]; then
    echo "Skipping missing directory: $dir"
    echo
    continue
  fi

  echo "-- Directory: $dir"

  while IFS= read -r -d '' file; do
    # пропускаємо файли без scenario
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
  done < <(find "$dir" -type f -name "*.md" -print0 | sort -z)

  echo
done

echo "==== GLOBAL SUMMARY ===="
echo "files:   $TOTAL"
echo "passed:  $PASSED"
echo "failed:  $FAILED"

if [[ $FAILED -ne 0 ]]; then
  exit 1
fi