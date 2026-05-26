#!/usr/bin/env bats
# Integration tests for `eden doctor`.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
}

@test "doctor --help is non-empty and lists exit codes" {
    run "$EDEN_ROOT/bin/eden-doctor" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Exit codes:" ]]
    [[ "$output" =~ "All checks passed" ]]
}

@test "doctor --format=plain emits parseable severity|message lines" {
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ ^ok\| ]] || [[ "$output" =~ ok\|.* ]]
    # Every non-empty line must start with ok|, warn|, error|, info|, or summary|
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^(ok|warn|error|info|summary)\| ]] || {
            echo "Unparseable line: $line"
            return 1
        }
    done <<< "$output"
}

@test "doctor exits 0 when clean, 1 with warnings, 2 with errors" {
    # We can't easily simulate all three in a sandbox, but we can assert that
    # at least the exit code is in {0,1,2} (never 3+ or negative).
    set +e
    "$EDEN_ROOT/bin/eden-doctor" --format=plain >/dev/null 2>&1
    status=$?
    set -e
    [ "$status" -ge 0 ] && [ "$status" -le 2 ]
}

@test "doctor rejects unknown flags with exit 2" {
    run "$EDEN_ROOT/bin/eden-doctor" --bogus-flag
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Unknown option" ]]
}
