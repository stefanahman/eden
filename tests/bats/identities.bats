#!/usr/bin/env bats
# graft-git applies an identity to the repos whose remotes it names, and
# by directory when it names none.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export GIT_CONFIG_NOSYSTEM=1
    unset GIT_CONFIG_GLOBAL
    mkdir -p "$XDG_CONFIG_HOME/eden"
    printf '[include]\n\tpath = ~/.config/eden/local/gitconfig\n' > "$HOME/.gitconfig"

    SHARED="$BATS_TEST_TMPDIR/shared"
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir -p "$SHARED/.config/git/identities" "$WORK/.config/git/identities"
    printf '[user]\n\tname = John Doe\n\temail = john@example.com\n' \
        > "$SHARED/.config/git/identities/_default"
    printf '%s\n' "$SHARED" "$WORK" > "$XDG_CONFIG_HOME/eden/branches"
}

# repo <name> [remote url]: a repository, with an origin when given one.
repo() {
    git init -q "$BATS_TEST_TMPDIR/repos/$1"
    if [[ -n "${2:-}" ]]; then
        git -C "$BATS_TEST_TMPDIR/repos/$1" remote add origin "$2"
    fi
}

email_in() {
    git -C "$BATS_TEST_TMPDIR/repos/$1" config user.email
}

@test "an identity naming its remotes applies to repos with those remotes" {
    printf '[user]\n\temail = john@example-corp.com\n[eden]\n\tremote = git@github.com:example-corp/**\n\tremote = https://github.com/example-corp/**\n' \
        > "$WORK/.config/git/identities/example-corp"
    run "$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-git"
    [ "$status" -eq 0 ]
    repo ssh git@github.com:example-corp/app.git
    repo https https://github.com/example-corp/app
    repo other git@github.com:johndoe/dotfiles.git
    repo none
    [ "$(email_in ssh)" = john@example-corp.com ]
    [ "$(email_in https)" = john@example-corp.com ]
    [ "$(email_in other)" = john@example.com ]
    [ "$(email_in none)" = john@example.com ]
}

@test "an identity naming no remotes applies by directory, as before" {
    printf '[user]\n\temail = john@example-corp.com\n' > "$WORK/.config/git/identities/example-corp"
    run "$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-git"
    [ "$status" -eq 0 ]
    grep -qF '[includeIf "gitdir:~/Development/example-corp/"]' "$XDG_CONFIG_HOME/eden/local/gitconfig"
    ! grep -q 'hasconfig' "$XDG_CONFIG_HOME/eden/local/gitconfig"
}
