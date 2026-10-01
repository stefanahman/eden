#!/usr/bin/env bats
# graft-mise installs the tools a mise config declares, and eden doctor
# names the ones still missing.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    mkdir -p "$XDG_CONFIG_HOME/eden" "$HOME/.eden"
    GRAFTER="$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-mise"

    # A stand-in for mise: `ls --missing` prints what is in $MISSING, as mise
    # does, and `install` logs where it ran and empties the list.
    export MISSING="$BATS_TEST_TMPDIR/missing" CALLS="$BATS_TEST_TMPDIR/calls"
    : > "$MISSING"
    cat > "$BATS_TEST_TMPDIR/mise" <<'EOF'
#!/bin/bash
case "$*" in
    "ls --missing") cat "$MISSING" ;;
    install)
        echo "install in $PWD" >> "$CALLS"
        [[ -n "${MISE_FAIL:-}" ]] && exit 1
        : > "$MISSING" ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "$BATS_TEST_TMPDIR/mise"
    export EDEN_MISE="$BATS_TEST_TMPDIR/mise"
}

@test "graft-mise installs what mise reports missing, from the home folder" {
    echo 'go  1.25 (missing)  ~/.config/mise/conf.d/eden.toml  1.25' > "$MISSING"
    cd "$BATS_TEST_TMPDIR"
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Installing mise tools: go@1.25"* ]] || false
    [ "$(cat "$CALLS")" = "install in $HOME" ]
}

@test "graft-mise does nothing when every tool is installed" {
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mise tools all installed"* ]] || false
    [ ! -e "$CALLS" ]
}

@test "graft-mise skips a machine without mise" {
    EDEN_MISE=no-such-mise run "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" == *"mise not installed"* ]] || false
}

@test "graft-mise reports a failed install" {
    echo 'go  1.25 (missing)  ~/.config/mise/conf.d/eden.toml  1.25' > "$MISSING"
    MISE_FAIL=1 run "$GRAFTER"
    [ "$status" -eq 1 ]
    [[ "$output" == *"mise install failed"* ]] || false
}

@test "doctor names the mise tools that are declared but missing" {
    echo 'typst  0.15 (missing)  ~/.config/mise/conf.d/eden.toml  0.15' > "$MISSING"
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" == *"warn|mise tools declared but not installed: typst@0.15"* ]] || false
    : > "$MISSING"
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" == *"ok|mise tools installed"* ]] || false
}
