#!/usr/bin/env bats
# Branches' env files are POSIX sh, grafted into ~/.config/eden/env.d/ and
# loaded by bash and zsh alike.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    WORK="$BATS_TEST_TMPDIR/work"
    SHARED="$BATS_TEST_TMPDIR/shared"
    mkdir -p "$WORK/.config/eden/env.d" "$SHARED/.config/eden/env.d"
    echo 'export EDITOR=nvim' > "$SHARED/.config/eden/env.d/tools.sh"
    echo 'export DO_NOT_TRACK=1' > "$WORK/.config/eden/env.d/privacy.sh"
    printf '%s\n' "$SHARED" "$WORK" > "$XDG_CONFIG_HOME/eden/branches"
    GRAFTER="$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-env"
    LOADER="$EDEN_ROOT/packages/common/.config/bash/env"
}

@test "graft-env links every branch's env files into ~/.config/eden/env.d" {
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [ "$(readlink "$XDG_CONFIG_HOME/eden/env.d/tools.sh")" = "$SHARED/.config/eden/env.d/tools.sh" ]
    [ "$(readlink "$XDG_CONFIG_HOME/eden/env.d/privacy.sh")" = "$WORK/.config/eden/env.d/privacy.sh" ]
}

@test "graft-env: one env file name in two branches writes nothing" {
    echo 'export EDITOR=vim' > "$WORK/.config/eden/env.d/tools.sh"
    run "$GRAFTER"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.config/eden/env.d/tools.sh (shared, work)" ]]
    [ ! -e "$XDG_CONFIG_HOME/eden/env.d/privacy.sh" ]
}

@test "bash loads the env files through ~/.config/bash/env" {
    "$GRAFTER"
    run env -u EDITOR -u DO_NOT_TRACK bash --norc --noprofile -c '. "$1"; echo "$EDITOR $DO_NOT_TRACK"' _ "$LOADER"
    [ "$output" = "nvim 1" ]
}

@test "the bash loader is quiet with no env files" {
    run bash --norc --noprofile -c '. "$1"; echo done' _ "$LOADER"
    [ "$output" = "done" ]
}

@test "zsh loads the env files through .zshenv" {
    command -v zsh >/dev/null || skip "zsh not installed"
    "$GRAFTER"
    run env -u EDITOR -u DO_NOT_TRACK zsh -f -c 'source "$1"; echo "$EDITOR $DO_NOT_TRACK"' _ "$EDEN_ROOT/packages/common/.config/zsh/.zshenv"
    [ "$output" = "nvim 1" ]
}

@test "doctor asks for the ~/.bashrc line where bash is the login shell" {
    echo '# nothing of Eden here' > "$HOME/.bashrc"
    SHELL=/bin/bash run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ "warn|~/.bashrc does not load Eden's env files; add: . ~/.config/bash/env" ]]
    echo '. ~/.config/bash/env' >> "$HOME/.bashrc"
    SHELL=/bin/bash run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ ! "$output" =~ "does not load Eden's env files" ]]
    [[ "$output" =~ "ok|~/.bashrc loads Eden's env files" ]]
}

@test "doctor does not ask where zsh is the login shell" {
    echo '# nothing of Eden here' > "$HOME/.bashrc"
    SHELL=/bin/zsh run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ ! "$output" =~ "bashrc" ]]
}
