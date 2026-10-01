#!/usr/bin/env bats
# The branch list: one reader (lib/branches.sh) for every consumer.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    BRANCHES="$XDG_CONFIG_HOME/eden/branches"
    GRAFTERS="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"
}

@test "reader skips blanks and comments and expands ~, \$EDEN_ROOT and \$HOME" {
    printf '%s\n' '# comment' '' '   ' '  # indented' '~/one' \
        '  $EDEN_ROOT/branches/example  ' '${HOME}/two/' '/abs/three' > "$BRANCHES"
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branches'
    [ "$status" -eq 0 ]
    [ "$output" = "$HOME/one
$EDEN_ROOT/branches/example
$HOME/two
/abs/three" ]
}

@test "reader returns nothing when the list does not exist" {
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branches'
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "a grafter reads a last line that has no newline" {
    branch="$BATS_TEST_TMPDIR/branch-a"
    mkdir -p "$branch/.config/zsh/zshenv.d"
    echo 'export A=1' > "$branch/.config/zsh/zshenv.d/a.zsh"
    printf '%s' "$branch" > "$BRANCHES"

    run bash "$GRAFTERS/graft-zsh"
    [ "$status" -eq 0 ]
    [ -L "$XDG_CONFIG_HOME/zsh/zshenv.d/a.zsh" ]
}

@test "graft-configs does not evaluate a branch entry" {
    marker="$BATS_TEST_TMPDIR/evaluated"
    printf '%s\n' "/nonexistent/branch\$(touch $marker)" > "$BRANCHES"

    run bash "$GRAFTERS/graft-configs"
    [ ! -e "$marker" ]
}

@test "a project's target is the first listed path that exists" {
    source "$EDEN_ROOT/lib/branches.sh"
    mkdir -p "$HOME/Development/private/app"
    printf '%s\n' '# where the repo is checked out' '~/Development/app' '~/Development/private/app' > "$BATS_TEST_TMPDIR/target"
    [ "$(eden_project_target "$BATS_TEST_TMPDIR/target")" = "$HOME/Development/private/app" ]
}

@test "a project's target falls back to its first path when none exists" {
    source "$EDEN_ROOT/lib/branches.sh"
    printf '%s\n' '~/Development/app' '~/Development/private/app' > "$BATS_TEST_TMPDIR/target"
    run eden_project_target "$BATS_TEST_TMPDIR/target"
    [ "$status" -eq 1 ]
    [ "$output" = "$HOME/Development/app" ]
}
