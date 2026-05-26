#!/usr/bin/env bats
# Integration tests for the grafter contract (EDEN_GRAFTER_API).
# Catches "you forgot to declare --api-version" before users do.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    GRAFTERS_DIR="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"
}

@test "every grafter responds to --api-version" {
    for grafter in "$GRAFTERS_DIR"/graft-*; do
        [ -x "$grafter" ] || continue
        api=$(bash "$grafter" --api-version 2>/dev/null || echo "")
        [ -n "$api" ] || {
            echo "Grafter $(basename "$grafter") did not respond to --api-version"
            return 1
        }
        [[ "$api" =~ ^[0-9]+$ ]] || {
            echo "Grafter $(basename "$grafter") returned non-numeric API: $api"
            return 1
        }
    done
}

@test "every grafter declares the current API version" {
    # Read EDEN_GRAFTER_API_CURRENT from the runner
    current=$(grep -E '^EDEN_GRAFTER_API_CURRENT=' "$EDEN_ROOT/bin/eden-graft" | head -1 | cut -d= -f2)
    [ -n "$current" ]
    for grafter in "$GRAFTERS_DIR"/graft-*; do
        [ -x "$grafter" ] || continue
        api=$(bash "$grafter" --api-version)
        [ "$api" = "$current" ] || {
            echo "Grafter $(basename "$grafter") declares v$api but runner expects v$current"
            return 1
        }
    done
}

@test "every grafter responds to --covers" {
    for grafter in "$GRAFTERS_DIR"/graft-*; do
        [ -x "$grafter" ] || continue
        run bash "$grafter" --covers
        [ "$status" -eq 0 ] || {
            echo "Grafter $(basename "$grafter") failed on --covers"
            return 1
        }
    done
}
