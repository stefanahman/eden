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

@test "a moved branches repo is named by graft, doctor and eden garden" {
    mv "$REPO" "$REPO.moved"
    run "$EDEN_ROOT/bin/eden-graft"
    [ "$status" -eq 1 ]
    [[ "$output" == *"branches-repo names $REPO, which has no .eden-gardens"*"eden init"* ]] || false
    run "$EDEN_ROOT/bin/eden-garden" list
    [ "$status" -eq 1 ]
    [[ "$output" == *"branches-repo names $REPO, which has no .eden-gardens"* ]] || false
    mkdir -p "$HOME/.eden"
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" == *"error|~/.config/eden/branches-repo names $REPO, which has no .eden-gardens"* ]] || false
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

# eden branch, with gardens ---------------------------------------------------

branch() {
    "$EDEN_ROOT/bin/eden-branch" "$@"
}

@test "branch new creates a branch in the repo and lists it in its garden" {
    cd "$REPO"
    run branch new games --garden personal
    [ "$status" -eq 0 ]
    [ -f "$REPO/games/.eden-secrets" ]
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_gardens_entries | cut -f1,2'
    [[ "$output" == *"personal	$REPO/hobby
personal	$REPO/games"* ]]
    [ ! -e "$XDG_CONFIG_HOME/eden/branches" ]
}

@test "branch new refuses a folder outside the repo before creating it" {
    cd "$HOME"
    run branch new loose --garden personal
    [ "$status" -eq 1 ]
    [[ "$output" == *"outside"* ]]
    [ ! -e "$HOME/loose" ]
}

@test "branch new and add refuse a folder name with whitespace" {
    cd "$REPO"
    run branch new "my branch" --garden personal
    [ "$status" -eq 1 ]
    [[ "$output" == *"whitespace"* ]] || false
    [ ! -e "$REPO/my branch" ]
    mkdir -p "$REPO/two words"
    run branch add "$REPO/two words" --garden personal
    [ "$status" -eq 1 ]
    run grep -q two "$REPO/.eden-gardens"
    [ "$status" -eq 1 ]
}

@test "branch add needs to be told where, and the garden must be declared" {
    mkdir -p "$REPO/extra"
    run branch add "$REPO/extra"
    [ "$status" -eq 1 ]
    [[ "$output" == *"--garden <name> or --shared"* ]]
    run branch add "$REPO/extra" --garden school
    [ "$status" -eq 1 ]
    [[ "$output" == *"eden garden new school"* ]]
}

@test "branch add --shared --platform lists it under [shared] for one platform" {
    mkdir -p "$REPO/mac-extra"
    run branch add "$REPO/mac-extra" --shared --platform mac
    [ "$status" -eq 0 ]
    [ "$(sed -n '2,6p' "$REPO/.eden-gardens")" = "[shared]
common
mac-desktop    mac
linux-desktop  arch
mac-extra  mac" ]
    run branch add "$REPO/mac-extra" --shared
    [[ "$output" == *"Already listed under [shared]"* ]]
}

@test "branch move takes a branch to another garden and keeps its platform" {
    sed 's/^hobby$/hobby  arch/' "$REPO/.eden-gardens" > "$REPO/.eden-gardens.new"
    mv "$REPO/.eden-gardens.new" "$REPO/.eden-gardens"
    run branch move hobby --garden work
    [ "$status" -eq 0 ]
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_gardens_entries'
    [[ "$output" == *"work	$REPO/hobby	arch"* ]]
    [[ "$output" != *"personal	$REPO/hobby"* ]]
}

@test "branch remove takes it out of .eden-gardens and leaves the folder" {
    run branch remove hobby
    [ "$status" -eq 0 ]
    run grep -q hobby "$REPO/.eden-gardens"
    [ "$status" -eq 1 ]
    [ -d "$REPO/hobby" ]
}

@test "branch move that cannot place a branch leaves .eden-gardens as it was" {
    mkdir -p "$HOME/outside"
    printf '%s\n' '[personal]' "$HOME/outside" >> "$REPO/.eden-gardens"
    cp "$REPO/.eden-gardens" "$BATS_TEST_TMPDIR/before"
    run branch move "$HOME/outside" --garden work
    [ "$status" -eq 1 ]
    [[ "$output" == *"outside"* ]] || false
    cmp "$REPO/.eden-gardens" "$BATS_TEST_TMPDIR/before"
    run branch remove "$HOME/outside"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Took $HOME/outside out of"* ]] || false
}

@test "branch list shows each garden's branches and what is grafted here" {
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    run branch list
    [ "$status" -eq 0 ]
    [[ "$output" == *"[shared]"*"✓ common"*"· mac-desktop (mac)"*"✓ linux-desktop (arch)"* ]]
    [[ "$output" == *"[work]  grown"*"✓ work"* ]]
    [[ "$output" == *"[personal]  not grown here"*"· personal"* ]]
}

@test "without gardens, --garden is refused" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    run branch add "$REPO/work" --garden work
    [ "$status" -eq 1 ]
    [[ "$output" == *"need gardens"* ]]
}

@test "branch remove names a branch .eden-gardens does not list" {
    run branch remove nowhere
    [ "$status" -eq 1 ]
    [[ "$output" == *"Not in $REPO/.eden-gardens: nowhere"* ]]
}

# eden init -------------------------------------------------------------------

init() {
    "$EDEN_ROOT/bin/eden-init" "$@"
}

@test "init with a repo sets up gardens, grows the named ones and puts the first in view" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    cd "$HOME"
    run init branches-repo --garden personal --garden work --no-graft
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/branches-repo")" = "$REPO" ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/gardens")" = "personal
work" ]
    [ "$(cat "$XDG_STATE_HOME/eden/garden")" = "personal" ]
    [[ "$output" == *"Next: eden graft"* ]]
}

@test "init leaves the trunk's own ~/.config/eden/repo alone" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    echo "$EDEN_ROOT" > "$XDG_CONFIG_HOME/eden/repo"
    run init "$REPO" --garden work --no-graft
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/repo")" = "$EDEN_ROOT" ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/branches-repo")" = "$REPO" ]
}

@test "init puts a garden it grows in view when the one in view is not grown" {
    mkdir -p "$XDG_STATE_HOME/eden" && echo work > "$XDG_STATE_HOME/eden/garden"
    run init "$REPO" --garden personal --no-graft
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_STATE_HOME/eden/garden")" = personal ]
}

@test "init without a tty needs the gardens named" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    run init "$REPO" --no-graft
    [ "$status" -eq 2 ]
    [[ "$output" == *"--garden <name> (declared: work personal)"* ]]
}

@test "init refuses a garden the repo does not declare" {
    run init "$REPO" --garden school --no-graft
    [ "$status" -eq 1 ]
    [[ "$output" == *"No garden school"* ]]
}

@test "init says the branches file is no longer read" {
    echo "$HOME/elsewhere" > "$XDG_CONFIG_HOME/eden/branches"
    run init "$REPO" --garden work --no-graft
    [ "$status" -eq 0 ]
    [[ "$output" == *"branches is no longer read"* ]]
}

@test "init with a path without .eden-gardens registers it as a branch" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    run init "$REPO/work" --no-graft
    [ "$status" -eq 0 ]
    [ "$(cat "$XDG_CONFIG_HOME/eden/branches")" = "$REPO/work" ]
    run init "$REPO/work" --garden work
    [ "$status" -eq 2 ]
}

@test "init grafts the gardens it grows" {
    rm "$XDG_CONFIG_HOME/eden/branches-repo"
    mkdir -p "$REPO/work/.config/zsh/zshenv.d" "$REPO/personal/.config/zsh/zshenv.d"
    echo 'export WORK=1' > "$REPO/work/.config/zsh/zshenv.d/work.zsh"
    echo 'export PERSONAL=1' > "$REPO/personal/.config/zsh/zshenv.d/personal.zsh"
    EDEN_CLAUDE_CLI=true run init "$REPO" --garden work
    [ "$status" -eq 0 ]
    [ -L "$XDG_CONFIG_HOME/zsh/zshenv.d/work.zsh" ]
    [ ! -e "$XDG_CONFIG_HOME/zsh/zshenv.d/personal.zsh" ]
    [ "$(cat "$XDG_STATE_HOME/eden/garden")" = "work" ]
}

# eden update: pulling the repo -------------------------------------------------

pull() {
    bash -c 'source "$EDEN_ROOT/lib/branches.sh"; source "$EDEN_ROOT/lib/repo.sh"; eden_branches_repo_pull'
}

clone_repo() {
    export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
    export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
    git -C "$REPO" init -q -b main
    git -C "$REPO" add -A
    git -C "$REPO" commit -q -m initial
    git clone -q --bare "$REPO" "$HOME/origin.git"
    git clone -q "$HOME/origin.git" "$HOME/clone"
    echo "$HOME/clone" > "$XDG_CONFIG_HOME/eden/branches-repo"
}

@test "pull does nothing for a repo that is not a git checkout" {
    run pull
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "pull reports a repo already up to date" {
    clone_repo
    run pull
    [ "$status" -eq 0 ]
    [ "$output" = "$HOME/clone is up to date" ]
}

@test "pull fast-forwards and says how many commits came in" {
    clone_repo
    printf '%s\n' '[school]' >> "$REPO/.eden-gardens"
    git -C "$REPO" commit -q -am 'declare school'
    git -C "$REPO" push -q "$HOME/origin.git" main
    run pull
    [ "$status" -eq 2 ]
    [ "$output" = "$HOME/clone updated: 1 new commit(s)" ]
    grep -qx '\[school\]' "$HOME/clone/.eden-gardens"
}

@test "pull leaves a diverged repo alone and says so" {
    clone_repo
    git -C "$REPO" commit -q --allow-empty -m upstream
    git -C "$REPO" push -q "$HOME/origin.git" main
    git -C "$HOME/clone" commit -q --allow-empty -m local
    run pull
    [ "$status" -eq 1 ]
    [[ "$output" == "Could not fast-forward $HOME/clone"* ]]
}

# eden doctor -------------------------------------------------------------------

gardens_report() {
    "$EDEN_ROOT/bin/eden-doctor" --format=plain 2>/dev/null | grep -E 'Gardens set up|gardens|garden |\.eden-gardens|grafts nothing|grows|in view' | sort -u
}

@test "doctor passes gardens that match the repo" {
    mkdir -p "$HOME/.eden"
    echo work > "$XDG_CONFIG_HOME/eden/gardens"
    mkdir -p "$XDG_STATE_HOME/eden" && echo work > "$XDG_STATE_HOME/eden/garden"
    run gardens_report
    [[ "$output" == *"ok|Gardens set up from $REPO"* ]]
    [[ "$output" == *"ok|work grown, work in view; .eden-gardens matches the repo"* ]]
    [[ "$output" != *"warn|"* ]]
}

@test "doctor names what .eden-gardens gets wrong" {
    mkdir -p "$REPO/stray" "$REPO/notes" "$REPO/work/platforms/mac"
    touch "$REPO/stray/.eden-graft" "$REPO/work/platforms/mac/.eden-graft"
    { echo 'orphan'; cat "$REPO/.eden-gardens"; printf '%s\n' '[work]' 'personal' 'notes' 'gone' 'common  windows'; } > "$REPO/.eden-gardens.new"
    mv "$REPO/.eden-gardens.new" "$REPO/.eden-gardens"
    printf '%s\n' work retired > "$XDG_CONFIG_HOME/eden/gardens"
    echo "$HOME/elsewhere" > "$XDG_CONFIG_HOME/eden/branches"
    run gardens_report
    [[ "$output" == *"warn|.eden-gardens: 'orphan' comes before any [section] and is not read"* ]]
    [[ "$output" == *"error|.eden-gardens lists personal more than once"* ]]
    [[ "$output" == *"warn|.eden-gardens lists notes, which is not a branch"* ]]
    [[ "$output" == *"warn|.eden-gardens lists gone under [work], which does not exist"* ]]
    [[ "$output" == *"warn|.eden-gardens: common names platform 'windows'"* ]]
    [[ "$output" == *"warn|stray is a branch that .eden-gardens does not list, so it grafts nothing"* ]]
    [[ "$output" != *"platforms/mac is a branch"* ]]
    [[ "$output" == *"warn|This machine grows retired, which .eden-gardens does not declare"* ]]
    [[ "$output" == *"warn|No garden in view"* ]]
    [[ "$output" == *"branches is not read while gardens are set up"* ]]
}

@test "doctor finds an unlisted branch when the repo is reached through a symlink" {
    mkdir -p "$REPO/stray" && touch "$REPO/stray/.eden-graft"
    ln -s "$REPO" "$HOME/repo-link"
    echo "$HOME/repo-link" > "$XDG_CONFIG_HOME/eden/branches-repo"
    run gardens_report
    [[ "$output" == *"warn|stray is a branch that .eden-gardens does not list"* ]] || false
}

@test "doctor says when no garden is grown" {
    run gardens_report
    [[ "$output" == *"warn|This machine grows no garden"* ]]
}

@test "branch move finds a branch in a subfolder by its name, unless two share it" {
    mkdir -p "$REPO/branches/chess" "$REPO/old/chess"
    printf '%s\n' '[personal]' 'branches/chess' > "$REPO/.eden-gardens.add"
    cat "$REPO/.eden-gardens.add" >> "$REPO/.eden-gardens"
    run branch move chess --garden work
    [ "$status" -eq 0 ]
    run bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_gardens_entries | cut -f1,2'
    [[ "$output" == *"work	$REPO/branches/chess"* ]]
    printf '%s\n' 'old/chess' >> "$REPO/.eden-gardens"
    run branch move chess --shared
    [ "$status" -eq 1 ]
    [[ "$output" == *"More than one branch is called chess; give its path: branches/chess old/chess"* ]]
}
