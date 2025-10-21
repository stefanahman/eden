#!/bin/bash
# Eden test runner - convenience wrapper
# Runs all validation tests from tests/ directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run all test scripts in tests/
echo "Running Eden validation tests..."
echo ""

"$SCRIPT_DIR/tests/validate-setup.sh"

# Optional: Check 1Password secrets (informational, doesn't fail)
if [[ "${SKIP_SECRETS:-}" != "1" ]]; then
    echo ""
    "$SCRIPT_DIR/tests/validate-secrets.sh"
fi

exit $?

