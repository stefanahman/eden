#!/usr/bin/env bats
# `eden graft` reports failure and passes --force to grafters.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    : > "$XDG_CONFIG_HOME/eden/branches"

    # The runner looks in ~/.eden/libexec/grafters first.
    GRAFTERS="$HOME/.eden/libexec/grafters"
    mkdir -p "$GRAFTERS"
    MARKS="$BATS_TEST_TMPDIR/marks"
    mkdir -p "$MARKS"
    export MARKS
}

# fake_grafter <name> <exit status>
fake_grafter() {
    cat > "$GRAFTERS/graft-$1" <<EOF
#!/bin/bash
[[ "\${1:-}" == "--api-version" ]] && { echo 1; exit 0; }
echo "force=\${EDEN_GRAFT_FORCE:-}" > "\$MARKS/$1"
exit $2
EOF
    chmod +x "$GRAFTERS/graft-$1"
}

@test "a failing grafter fails the run, names it, and the rest still run" {
    fake_grafter a 0
    fake_grafter b 3
    fake_grafter c 0
    run "$EDEN_ROOT/bin/eden-graft"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed: graft-b" ]]
    [ -f "$MARKS/a" ] && [ -f "$MARKS/c" ]
}

@test "a run where every grafter succeeds exits 0" {
    fake_grafter a 0
    fake_grafter c 0
    run "$EDEN_ROOT/bin/eden-graft"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Graft complete" ]]
}

@test "--force reaches every grafter" {
    fake_grafter a 0
    fake_grafter c 0
    run "$EDEN_ROOT/bin/eden-graft" --force
    [ "$status" -eq 0 ]
    [ "$(cat "$MARKS/a")" = "force=true" ]
    [ "$(cat "$MARKS/c")" = "force=true" ]
}

@test "--force works with a single grafter, before or after its name" {
    fake_grafter a 0
    run "$EDEN_ROOT/bin/eden-graft" a --force
    [ "$status" -eq 0 ]
    [ "$(cat "$MARKS/a")" = "force=true" ]
    rm "$MARKS/a"
    run "$EDEN_ROOT/bin/eden-graft" --force a
    [ "$status" -eq 0 ]
    [ "$(cat "$MARKS/a")" = "force=true" ]
}

@test "without --force grafters see no force" {
    fake_grafter a 0
    run "$EDEN_ROOT/bin/eden-graft"
    [ "$status" -eq 0 ]
    [ "$(cat "$MARKS/a")" = "force=" ]
}

@test "unknown flags are still rejected" {
    fake_grafter a 0
    run "$EDEN_ROOT/bin/eden-graft" --bogus
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown flag" ]]
}
