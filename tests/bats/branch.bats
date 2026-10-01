#!/usr/bin/env bats
# `eden branch add` and `remove` compare whole entries.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden" "$HOME/b/a" "$HOME/b/a-b"
    BRANCHES="$XDG_CONFIG_HOME/eden/branches"
    BRANCH="$EDEN_ROOT/bin/eden-branch"
}

@test "remove finds an entry written as ~/..." {
    printf '%s\n' '~/b/a' '~/b/a-b' > "$BRANCHES"
    run "$BRANCH" remove '~/b/a'
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = '~/b/a-b' ]
}

@test "remove of /x/a keeps /x/a-b" {
    printf '%s\n' "$HOME/b/a" "$HOME/b/a-b" "$HOME/other" > "$BRANCHES"
    run "$BRANCH" remove "$HOME/b/a"
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = "$HOME/b/a-b
$HOME/other" ]
}

@test "remove works when every line contains the path" {
    printf '%s\n' "$HOME/b/a" "$HOME/b/a-b" > "$BRANCHES"
    run "$BRANCH" remove "$HOME/b/a"
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = "$HOME/b/a-b" ]
}

@test "remove keeps comments and blank lines" {
    printf '%s\n' '# work' "$HOME/b/a" '' '# personal' "$HOME/b/a-b" > "$BRANCHES"
    run "$BRANCH" remove "$HOME/b/a"
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = "# work

# personal
$HOME/b/a-b" ]
}

@test "remove of an unregistered path fails and changes nothing" {
    printf '%s\n' "$HOME/b/a-b" > "$BRANCHES"
    run "$BRANCH" remove "$HOME/b/a"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not found" ]]
    [ "$(cat "$BRANCHES")" = "$HOME/b/a-b" ]
}

@test "add of /x/a is not blocked by /x/a-b" {
    printf '%s\n' "$HOME/b/a-b" > "$BRANCHES"
    run "$BRANCH" add "$HOME/b/a"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Branch registered" ]]
    grep -qx "$HOME/b/a" "$BRANCHES"
}

@test "add recognises an entry written as ~/..." {
    printf '%s\n' '~/b/a' > "$BRANCHES"
    run "$BRANCH" add "$HOME/b/a"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "already registered" ]]
    [ "$(wc -l < "$BRANCHES")" -eq 1 ]
}

@test "add starts a new line when the last one has no newline" {
    printf '%s' "$HOME/b/a-b" > "$BRANCHES"
    run "$BRANCH" add "$HOME/b/a"
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = "$HOME/b/a-b
$HOME/b/a" ]
}

@test "list counts a branch's secrets once, also when there are none" {
    mkdir -p "$HOME/b/none" "$HOME/b/two"
    echo '# no secrets yet' > "$HOME/b/none/.eden-secrets"
    printf '[secret]\nname=a\n[secret]\nname=b\n' > "$HOME/b/two/.eden-secrets"
    printf '%s\n' "$HOME/b/none" "$HOME/b/two" > "$BRANCHES"
    run "$BRANCH" list
    [ "$status" -eq 0 ]
    [ "$(grep -c 'Secrets:' <<< "$output")" -eq 2 ]
    [[ "$output" =~ "Secrets: 0 defined" ]]
    [[ "$output" =~ "Secrets: 2 defined" ]]
    [[ ! "$output" =~ $'Secrets: 0\n' ]]
}

@test "a relative path is relative to where eden was run, not to the trunk" {
    mkdir -p "$HOME/work/mine"
    cd "$HOME/work"
    run "$EDEN_ROOT/bin/eden" branch add mine
    [ "$status" -eq 0 ]
    [ "$(cat "$BRANCHES")" = "$HOME/work/mine" ]
}

@test "new creates a relative path where eden was run" {
    cd "$HOME"
    run "$EDEN_ROOT/bin/eden" branch new fresh
    [ "$status" -eq 0 ]
    [ -d "$HOME/fresh/.local/bin" ]
    [ "$(cat "$BRANCHES")" = "$HOME/fresh" ]
}
