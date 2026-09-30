#!/usr/bin/env bats
# `eden doctor` looks for broken and leftover links where grafts put them.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    BRANCHES="$XDG_CONFIG_HOME/eden/branches"
    : > "$BRANCHES"
}

doctor() {
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
}

@test "a broken link in ~/.eden/bin is reported" {
    mkdir -p "$HOME/.eden/bin"
    ln -s "$BATS_TEST_TMPDIR/gone" "$HOME/.eden/bin/tool"
    doctor
    [[ "$output" =~ "warn|Broken symlink: $HOME/.eden/bin/tool" ]]
}

@test "a broken link in zshenv.d is reported" {
    mkdir -p "$XDG_CONFIG_HOME/zsh/zshenv.d"
    ln -s "$BATS_TEST_TMPDIR/gone.zsh" "$XDG_CONFIG_HOME/zsh/zshenv.d/work.zsh"
    doctor
    [[ "$output" =~ "warn|Broken symlink: $XDG_CONFIG_HOME/zsh/zshenv.d/work.zsh" ]]
}

@test "a broken link among git identities is reported" {
    mkdir -p "$HOME/.config/git/identities"
    ln -s "$BATS_TEST_TMPDIR/gone" "$HOME/.config/git/identities/work"
    doctor
    [[ "$output" =~ "warn|Broken symlink: $HOME/.config/git/identities/work" ]]
}

@test "a working link into an unregistered branch is reported" {
    branch="$BATS_TEST_TMPDIR/old-branch"
    mkdir -p "$branch/.local/bin" "$HOME/.eden/bin"
    touch "$branch/.eden-graft" "$branch/.local/bin/tool"
    ln -s "$branch/.local/bin/tool" "$HOME/.eden/bin/tool"
    doctor
    # Doctor names the branch by its resolved path (macOS: /var -> /private/var).
    branch_real="$(cd "$branch" && pwd -P)"
    [[ "$output" =~ "warn|Link into an unregistered branch ($branch_real): $HOME/.eden/bin/tool" ]]
}

@test "a link into a registered branch is not a leftover" {
    branch="$BATS_TEST_TMPDIR/live-branch"
    mkdir -p "$branch/.local/bin" "$HOME/.eden/bin"
    touch "$branch/.eden-graft" "$branch/.local/bin/tool"
    ln -s "$branch/.local/bin/tool" "$HOME/.eden/bin/tool"
    echo "$branch" > "$BRANCHES"
    doctor
    [[ ! "$output" =~ "Link into an unregistered branch" ]]
}

@test "a link into the trunk is not a leftover" {
    mkdir -p "$HOME/.config"
    ln -s "$EDEN_ROOT/README.md" "$HOME/.config/readme"
    doctor
    [[ ! "$output" =~ "Link into an unregistered branch" ]]
}

@test "the lock links Chromium-based apps keep are not reported, other broken links are" {
    mkdir -p "$XDG_CONFIG_HOME/app"
    ln -s "host-4313" "$XDG_CONFIG_HOME/app/SingletonLock"
    ln -s "2855553049741192354" "$XDG_CONFIG_HOME/app/SingletonCookie"
    ln -s "$BATS_TEST_TMPDIR/scoped_dir/SingletonSocket" "$XDG_CONFIG_HOME/app/SingletonSocket"
    ln -s "$BATS_TEST_TMPDIR/gone" "$XDG_CONFIG_HOME/app/settings.json"
    doctor
    [[ ! "$output" =~ "Singleton" ]]
    [[ "$output" =~ "warn|Broken symlink: $XDG_CONFIG_HOME/app/settings.json" ]]
}

@test "a leftover three levels under ~/.config is reported" {
    branch="$BATS_TEST_TMPDIR/old-branch"
    mkdir -p "$branch/.config/app/app.d" "$XDG_CONFIG_HOME/app/app.d"
    touch "$branch/.eden-graft" "$branch/.config/app/app.d/work.yaml"
    ln -s "$branch/.config/app/app.d/work.yaml" "$XDG_CONFIG_HOME/app/app.d/work.yaml"
    doctor
    [[ "$output" =~ "Link into an unregistered branch" ]]
    [[ "$output" =~ "$XDG_CONFIG_HOME/app/app.d/work.yaml" ]]
}

@test "a broken link in ~/.ssh is reported" {
    mkdir -p "$HOME/.ssh"
    ln -s "$BATS_TEST_TMPDIR/gone" "$HOME/.ssh/config"
    doctor
    [[ "$output" =~ "warn|Broken symlink: $HOME/.ssh/config" ]]
}

@test "a branch's projects folder counts as grafted" {
    branch="$BATS_TEST_TMPDIR/work"
    mkdir -p "$branch/projects/app/.mcp"
    touch "$branch/.eden-graft"
    echo "$HOME/Development/app" > "$branch/projects/app/.eden-target"
    echo '{"mcpServers": {}}' > "$branch/projects/app/.mcp/servers.json"
    echo "$branch" > "$BRANCHES"
    doctor
    [[ ! "$output" =~ "projects (not in .eden-graft" ]]
    [[ "$output" =~ "work: all configs covered" ]]
}
