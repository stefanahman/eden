#!/bin/bash
# Eden test runner - convenience wrapper
# Runs all validation tests from tests/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
any_failed=0

# Run all test scripts in tests/
echo "Running Eden validation tests..."
echo ""

if ! "$SCRIPT_DIR/tests/validate-setup.sh"; then
    any_failed=1
fi

# Optional: Check 1Password secrets (informational, doesn't fail)
if [[ "${SKIP_SECRETS:-}" != "1" ]]; then
    echo ""
    "$SCRIPT_DIR/tests/validate-secrets.sh"
fi

# Run grafter integration tests (sandboxed)
for test_file in "$SCRIPT_DIR"/tests/grafter/test-*.sh; do
    [ -f "$test_file" ] || continue
    echo ""
    if ! bash "$test_file"; then
        any_failed=1
    fi
done

# Run bats integration tests if bats is installed
if command -v bats >/dev/null 2>&1 && [ -d "$SCRIPT_DIR/tests/bats" ]; then
    echo ""
    echo "Running bats tests..."
    if ! bats "$SCRIPT_DIR/tests/bats/"; then
        any_failed=1
    fi
fi

exit $any_failed
