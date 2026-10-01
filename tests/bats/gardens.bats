#!/usr/bin/env bats
# Gardens: the branch list worked out from a repo's .eden-gardens and the
# gardens this machine grows (lib/branches.sh).

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    export EDEN_PLATFORM=arch
    mkdir -p "$XDG_CONFIG_HOME/eden"
    GRAFTERS="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"

    REPO="$HOME/branches-repo"
    for b in common mac-desktop linux-desktop work personal hobby; do
        mkdir -p "$REPO/$b"
        touch "$REPO/$b/.eden-graft"
    done
    cat > "$REPO/.eden-gardens" <<'EOF'
# The gardens, and what every garden has.
[shared]
common
mac-desktop    mac
linux-desktop  arch

[work]
work

[personal]
personal
hobby
EOF
    echo '~/branches-repo' > "$XDG_CONFIG_HOME/eden/branches-repo"
}

branches() {
    bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branches'
}

@test "the shared branches for this platform come first, then each grown garden's" {
    printf '%s\n' personal work > "$XDG_CONFIG_HOME/eden/gardens"
    run branches
    [ "$status" -eq 0 ]
    [ "$output" = "$REPO/common
$REPO/linux-desktop
$REPO/work
$REPO/personal
$REPO/hobby" ]
}

@test "a garden this machine does not grow grafts nothing" {
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    run branches
    [ "$output" = "$REPO/common
$REPO/linux-desktop
$REPO/work" ]
}

@test "a branch limited to another platform is left out" {
    EDEN_PLATFORM=mac run branches
    [ "$output" = "$REPO/common
$REPO/mac-desktop" ]
}

@test "a branch listed twice is printed once" {
    printf '%s\n' '[work]' work common >> "$REPO/.eden-gardens"
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    run branches
    [ "$output" = "$REPO/common
$REPO/linux-desktop
$REPO/work" ]
}

@test "gardens replace the branches file" {
    echo "$HOME/elsewhere" > "$XDG_CONFIG_HOME/eden/branches"
    run branches
    [ "$output" = "$REPO/common
$REPO/linux-desktop" ]
}

@test "a branches repo without .eden-gardens grafts nothing, not the old branches file" {
    rm "$REPO/.eden-gardens"
    echo "$HOME/elsewhere" > "$XDG_CONFIG_HOME/eden/branches"
    run branches
    [ -z "$output" ]
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branch_list_exists'
    [ "$status" -eq 1 ]
}

@test "a long state file's first line is read without a broken pipe, also with SIGPIPE ignored" {
    mkdir -p "$XDG_STATE_HOME/eden"
    { echo work; for i in $(seq 3000); do echo "line $i"; done; } > "$XDG_STATE_HOME/eden/garden"
    run bash -c 'trap "" PIPE; source "$EDEN_ROOT/lib/branches.sh"; eden_garden_in_view 2>&1'
    [ "$output" = work ]
}

@test "a comment after a section or a branch is not part of it" {
    printf '%s\n' '[school]  # evenings' 'chess  arch  # the club' > "$REPO/.eden-gardens.add"
    cat "$REPO/.eden-gardens.add" >> "$REPO/.eden-gardens"
    mkdir -p "$REPO/chess"
    echo school > "$XDG_CONFIG_HOME/eden/gardens"
    run branches
    [ "$output" = "$REPO/common
$REPO/linux-desktop
$REPO/chess" ]
}

@test "the gardens declared, in order, without [shared]" {
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_gardens_declared'
    [ "$output" = "work
personal" ]
}

@test "a branch list exists with gardens and no branches file" {
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branch_list_exists'
    [ "$status" -eq 0 ]
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_branch_list_exists'
    [ "$status" -eq 1 ]
}

@test "a grafter grafts a grown garden's branch, platform folder included" {
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    mkdir -p "$REPO/work/.config/zsh/zshenv.d" "$REPO/work/platforms/arch/.config/zsh/zshenv.d"
    echo 'export WORK=1' > "$REPO/work/.config/zsh/zshenv.d/work.zsh"
    echo 'export WORK_ARCH=1' > "$REPO/work/platforms/arch/.config/zsh/zshenv.d/work-arch.zsh"
    mkdir -p "$REPO/hobby/.config/zsh/zshenv.d"
    echo 'export HOBBY=1' > "$REPO/hobby/.config/zsh/zshenv.d/hobby.zsh"

    run bash "$GRAFTERS/graft-zsh"
    [ "$status" -eq 0 ]
    [ -L "$XDG_CONFIG_HOME/zsh/zshenv.d/work.zsh" ]
    [ -L "$XDG_CONFIG_HOME/zsh/zshenv.d/work-arch.zsh" ]
    [ ! -e "$XDG_CONFIG_HOME/zsh/zshenv.d/hobby.zsh" ]
}

# eden garden ----------------------------------------------------------------

garden() {
    "$EDEN_ROOT/bin/eden-garden" "$@"
}

@test "garden: none in view says how to pick one" {
    run garden
    [ "$status" -eq 1 ]
    [[ "$output" == *"eden garden use"* ]]
}

@test "garden add grows a declared garden once" {
    run garden add work
    [ "$status" -eq 0 ]
    run garden add work
    [[ "$output" == *"Already growing work"* ]]
    [ "$(cat "$XDG_CONFIG_HOME/eden/gardens")" = "work" ]
}

@test "garden add refuses a garden .eden-gardens does not declare" {
    run garden add school
    [ "$status" -eq 1 ]
    [[ "$output" == *"declared: work personal"* ]]
    [ ! -e "$XDG_CONFIG_HOME/eden/gardens" ]
}

@test "garden list shows each garden's state here" {
    printf '%s\n' work retired > "$XDG_CONFIG_HOME/eden/gardens"
    mkdir -p "$XDG_STATE_HOME/eden" && echo work > "$XDG_STATE_HOME/eden/garden"
    run garden list
    [ "$status" -eq 0 ]
    [[ "$output" == *"work"*"in view"* ]]
    [[ "$output" == *"personal"*"not grown"* ]]
    [[ "$output" == *"retired"*"grown, but not declared"* ]]
}

@test "garden use refuses a garden this machine does not grow" {
    run garden use personal
    [ "$status" -eq 1 ]
    [[ "$output" == *"eden garden add personal"* ]]
    [ ! -e "$XDG_STATE_HOME/eden/garden" ]
}

@test "garden use records the garden and runs every hook, a failing one reported" {
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    hooks="$XDG_CONFIG_HOME/eden/garden.d"
    mkdir -p "$hooks"
    printf '#!/bin/sh\necho "first $1" >> "%s"\n' "$BATS_TEST_TMPDIR/ran" > "$hooks/10-first"
    printf '#!/bin/sh\nexit 3\n' > "$hooks/20-fails"
    printf '#!/bin/sh\necho "last $1" >> "%s"\n' "$BATS_TEST_TMPDIR/ran" > "$hooks/30-last"
    printf 'not a hook\n' > "$hooks/40-not-executable"
    chmod +x "$hooks/10-first" "$hooks/20-fails" "$hooks/30-last"

    run garden use work
    [ "$status" -eq 1 ]
    [[ "$output" == *"garden.d/20-fails failed"* ]]
    [ "$(cat "$XDG_STATE_HOME/eden/garden")" = "work" ]
    [ "$(cat "$BATS_TEST_TMPDIR/ran")" = "first work
last work" ]
    run garden
    [ "$output" = "work" ]
}

@test "garden remove stops growing it and takes it out of view" {
    printf '%s\n' work personal > "$XDG_CONFIG_HOME/eden/gardens"
    mkdir -p "$XDG_STATE_HOME/eden" && echo work > "$XDG_STATE_HOME/eden/garden"
    run garden remove work
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/gardens")" = "personal" ]
    [ ! -e "$XDG_STATE_HOME/eden/garden" ]
}

@test "garden new declares an empty garden and refuses a taken or reserved name" {
    run garden new school
    [ "$status" -eq 0 ]
    [ "$(tail -n 2 "$REPO/.eden-gardens")" = "
[school]" ]
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_gardens_declared'
    [ "$output" = "work
personal
school" ]
    run garden new work
    [ "$status" -eq 1 ]
    run garden new shared
    [ "$status" -eq 1 ]
    run garden new 'two words'
    [ "$status" -eq 1 ]
}

@test "garden commands need a repo with gardens" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    run garden list
    [ "$status" -eq 1 ]
    [[ "$output" == *"eden init"* ]]
}
