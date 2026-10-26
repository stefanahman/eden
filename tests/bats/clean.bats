#!/usr/bin/env bats
# A graft takes out the broken links it finds in the folders it fills
# when they point into a branch grafted here: what a branch left behind
# when one of its files went. Nothing else is touched.
#
# Every [[ ]] and ! line ends in "|| false": bash 3.2 does not stop on a
# failing [[ ]], and no bash stops on a failing !, so without it such a
# line asserts nothing.

setup() {
    # graft-bin reads either; a caller's must not decide a test.
    unset FORCE EDEN_GRAFT_FORCE
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    GRAFTERS="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"
    BRANCH="$BATS_TEST_TMPDIR/work"
    mkdir -p "$BRANCH"
    touch "$BRANCH/.eden-graft"
    echo "$BRANCH" > "$XDG_CONFIG_HOME/eden/branches"
}

# Stdin is empty: graft-bin asks on a terminal, and a test must not wait
# for an answer, or take one.
graft() {
    run bash "$GRAFTERS/graft-$1" < /dev/null
}

@test "a skill retired from its branch: the next graft takes its broken link out, and says so" {
    mkdir -p "$BRANCH/.claude/skills/old" "$BRANCH/.claude/skills/kept"
    touch "$BRANCH/.claude/skills/old/SKILL.md" "$BRANCH/.claude/skills/kept/SKILL.md"
    graft claude
    [ -L "$HOME/.claude/skills/old" ]

    mv "$BRANCH/.claude/skills/old" "$BATS_TEST_TMPDIR/retired"
    graft claude
    [ "$status" -eq 0 ]
    [[ "$output" =~ "× ~/.claude/skills/old [removed: broken link into work]" ]] || false
    [ ! -L "$HOME/.claude/skills/old" ]
    [ -L "$HOME/.claude/skills/kept" ]
    [ -f "$BATS_TEST_TMPDIR/retired/SKILL.md" ]
}

@test "a broken link left before this change is taken out the same way: nothing needs a record" {
    # As an earlier eden left it on a machine: linked, then the skill went.
    mkdir -p "$HOME/.claude/skills"
    ln -s "$BRANCH/.claude/skills/stacked-prs" "$HOME/.claude/skills/stacked-prs"
    graft claude
    [ "$status" -eq 0 ]
    [[ "$output" =~ "× ~/.claude/skills/stacked-prs [removed: broken link into work]" ]] || false
    [ ! -L "$HOME/.claude/skills/stacked-prs" ]
}

@test "a broken top-level file link and a project's broken skill link are taken out" {
    repo="$HOME/Development/app"
    mkdir -p "$repo/.claude/skills" "$HOME/.claude" "$BRANCH/projects/app/.claude/skills/s"
    echo "$repo" > "$BRANCH/projects/app/.eden-target"
    touch "$BRANCH/projects/app/.claude/skills/s/SKILL.md"
    ln -s "$BRANCH/projects/app/.claude/skills/gone" "$repo/.claude/skills/gone"
    ln -s "$BRANCH/.claude/statusline.sh" "$HOME/.claude/statusline.sh"
    graft claude
    [ "$status" -eq 0 ]
    [ ! -L "$repo/.claude/skills/gone" ]
    [ ! -L "$HOME/.claude/statusline.sh" ]
    [ -L "$repo/.claude/skills/s" ]
}

@test "a project whose .claude left its branch while the project stays: its broken links are taken out" {
    repo="$HOME/Development/app"
    mkdir -p "$repo" "$BRANCH/projects/app/.claude/skills/s"
    echo "$repo" > "$BRANCH/projects/app/.eden-target"
    touch "$BRANCH/projects/app/.claude/skills/s/SKILL.md"
    graft claude
    [ -L "$repo/.claude/skills/s" ]
    mv "$BRANCH/projects/app/.claude" "$BATS_TEST_TMPDIR/app-claude"
    graft claude
    [ "$status" -eq 0 ]
    [ ! -L "$repo/.claude/skills/s" ]
}

@test "a script deleted from a branch: graft-bin takes its broken link out without asking" {
    mkdir -p "$BRANCH/.local/bin"
    touch "$BRANCH/.local/bin/tool" "$BRANCH/.local/bin/kept"
    graft bin
    mv "$BRANCH/.local/bin/tool" "$BATS_TEST_TMPDIR/tool"
    graft bin
    [ "$status" -eq 0 ]
    [[ "$output" =~ "× ~/.eden/bin/tool [removed: broken link into work]" ]] || false
    [[ ! "$output" =~ "tool is a broken link" ]] || false
    [ ! -L "$HOME/.eden/bin/tool" ]
    [ -L "$HOME/.eden/bin/kept" ]
}

@test "graft-bin still asks about a broken link that points anywhere else, and removes it with --force" {
    mkdir -p "$HOME/.eden/bin"
    ln -s "$BATS_TEST_TMPDIR/elsewhere/tool" "$HOME/.eden/bin/stray"
    graft bin
    [[ "$output" =~ "stray is a broken link (run interactively to resolve)" ]] || false
    [ -L "$HOME/.eden/bin/stray" ]
    EDEN_GRAFT_FORCE=true run bash "$GRAFTERS/graft-bin" < /dev/null
    [[ "$output" =~ "stray [removing broken link]" ]] || false
    [ ! -L "$HOME/.eden/bin/stray" ]
}

@test "env.d, zshenv.d and git identities lose their broken links into a branch" {
    mkdir -p "$XDG_CONFIG_HOME/eden/env.d" "$XDG_CONFIG_HOME/zsh/zshenv.d" "$HOME/.config/git/identities"
    ln -s "$BRANCH/.config/eden/env.d/gone.sh" "$XDG_CONFIG_HOME/eden/env.d/gone.sh"
    ln -s "$BRANCH/.config/zsh/zshenv.d/gone.zsh" "$XDG_CONFIG_HOME/zsh/zshenv.d/gone.zsh"
    ln -s "$BRANCH/.config/git/identities/gone" "$HOME/.config/git/identities/gone"
    graft env
    [ "$status" -eq 0 ]
    [ ! -L "$XDG_CONFIG_HOME/eden/env.d/gone.sh" ]
    graft zsh
    [ "$status" -eq 0 ]
    [ ! -L "$XDG_CONFIG_HOME/zsh/zshenv.d/gone.zsh" ]
    graft git
    [ "$status" -eq 0 ]
    [ ! -L "$HOME/.config/git/identities/gone" ]
}

@test "graft-configs takes out a broken link beside its entries, its own and one an entry no longer names" {
    mkdir -p "$BRANCH/.config/app" "$BRANCH/.config/other"
    touch "$BRANCH/.config/app/a.conf" "$BRANCH/.config/app/b.conf" "$BRANCH/.config/other/c.conf" "$BRANCH/.dotrc"
    printf '%s\n' .config/app/a.conf .config/app/b.conf .config/other/c.conf .dotrc > "$BRANCH/.eden-graft"
    graft configs
    [ -L "$HOME/.config/app/a.conf" ]
    [ -L "$HOME/.dotrc" ]

    # a.conf leaves the branch but keeps its entry; b.conf leaves both, and
    # its folder is still named by nothing but where a.conf was; .dotrc
    # leaves the branch, from $HOME itself.
    mv "$BRANCH/.config/app/a.conf" "$BRANCH/.config/app/b.conf" "$BRANCH/.dotrc" "$BATS_TEST_TMPDIR/"
    printf '%s\n' .config/app/a.conf .config/other/c.conf .dotrc > "$BRANCH/.eden-graft"
    graft configs
    [ "$status" -eq 0 ]
    [ ! -L "$HOME/.config/app/a.conf" ]
    [ ! -L "$HOME/.config/app/b.conf" ]
    [ ! -L "$HOME/.dotrc" ]
    [ -L "$HOME/.config/other/c.conf" ]
}

@test "a link into a branch whose folder is not here is left: the branch may come back" {
    # Registered spelled resolved, so macOS's /var, a link to /private/var,
    # cannot be what keeps the link.
    BRANCH="$(cd -P "$BRANCH" && pwd -P)"
    echo "$BRANCH" > "$XDG_CONFIG_HOME/eden/branches"
    mkdir -p "$BRANCH/.local/bin"
    touch "$BRANCH/.local/bin/tool"
    graft bin
    mv "$BRANCH" "$BATS_TEST_TMPDIR/moved"
    EDEN_GRAFT_FORCE= run bash "$GRAFTERS/graft-bin" < /dev/null
    [ -L "$HOME/.eden/bin/tool" ]
    [[ ! "$output" =~ "removed: broken link" ]] || false
}

@test "a broken link written relative counts by where it points" {
    mkdir -p "$HOME/.claude/skills"
    ln -s "../../../work/.claude/skills/gone" "$HOME/.claude/skills/gone"
    [ "$(cd "$HOME/.claude/skills" && cd ../../.. && pwd)/work" = "$BRANCH" ]
    graft claude
    [ ! -L "$HOME/.claude/skills/gone" ]
}

@test "a link to a branch entry that is itself a link, broken further on, is not broken: it is left" {
    # The branch tracks a link to a checkout this machine does not have,
    # as macos's tmux/plugins/claude-status does.
    mkdir -p "$BRANCH/.claude/skills" "$HOME/.claude/skills"
    ln -s "$BATS_TEST_TMPDIR/not-cloned/skill" "$BRANCH/.claude/skills/ext"
    ln -s "$BRANCH/.claude/skills/ext" "$HOME/.claude/skills/ext"
    ln -s "$BRANCH/.claude/skills/ext/" "$HOME/.claude/skills/ext-slash"
    graft claude
    [ "$status" -eq 0 ]
    [ -L "$HOME/.claude/skills/ext" ]
    [ -L "$HOME/.claude/skills/ext-slash" ]
    [[ ! "$output" =~ "removed" ]] || false
}

@test "a broken link whose text starts in a branch but climbs out of it is left" {
    mkdir -p "$BRANCH/sub" "$HOME/.claude/skills"
    ln -s "$BRANCH/sub/../../out/gone" "$HOME/.claude/skills/escape"
    ln -s "$BRANCH/nowhere/../../out/gone" "$HOME/.claude/skills/escape2"
    graft claude
    [ -L "$HOME/.claude/skills/escape" ]
    [ -L "$HOME/.claude/skills/escape2" ]
}

@test "a broken link whose text ends in .. through what does not exist is left" {
    mkdir -p "$HOME/.claude/skills"
    ln -s "$BRANCH/nowhere/.." "$HOME/.claude/skills/up"
    ln -s "$BRANCH/nowhere/." "$HOME/.claude/skills/here"
    graft claude
    [ -L "$HOME/.claude/skills/up" ]
    [ -L "$HOME/.claude/skills/here" ]
}

@test "a relative link under a linked folder counts by where the system resolves it" {
    # ~/.claude is a link elsewhere: ../../work from inside it is not the
    # branch at ~/work, whatever the path reads like. $HOME is spelled
    # resolved here, so only how .. is taken decides (macOS's /var is a
    # link to /private/var, which would otherwise decide it).
    export HOME="$(cd -P "$HOME" && pwd -P)"
    export XDG_CONFIG_HOME="$HOME/.config" XDG_STATE_HOME="$HOME/.local/state"
    branch2="$HOME/work"
    mkdir -p "$branch2/.claude/skills" "$BATS_TEST_TMPDIR/elsewhere/claude/skills"
    touch "$branch2/.eden-graft"
    echo "$branch2" > "$XDG_CONFIG_HOME/eden/branches"
    ln -s "$BATS_TEST_TMPDIR/elsewhere/claude" "$HOME/.claude"
    ln -s "../../work/.claude/skills/gone" "$HOME/.claude/skills/gone"
    graft claude
    [ -L "$HOME/.claude/skills/gone" ]
}

@test "a blank or unreadable .eden-graft line never has the folder above \$HOME cleaned" {
    ln -s "$BRANCH/gone" "$BATS_TEST_TMPDIR/outside-home"
    printf '   \n' > "$BRANCH/.eden-graft"
    graft configs
    [ -L "$BATS_TEST_TMPDIR/outside-home" ]
    printf '%s\n' "it's" > "$BRANCH/.eden-graft"
    graft configs
    [ "$status" -ne 0 ]
    [ -L "$BATS_TEST_TMPDIR/outside-home" ]
}

@test "graft-bin stopped by a collision cleans nothing, even with --force" {
    other="$BATS_TEST_TMPDIR/other"
    mkdir -p "$BRANCH/.local/bin" "$other/.local/bin" "$HOME/.eden/bin"
    touch "$BRANCH/.local/bin/x" "$other/.eden-graft" "$other/.local/bin/x"
    echo "$other" >> "$XDG_CONFIG_HOME/eden/branches"
    ln -s "$BRANCH/.local/bin/gone" "$HOME/.eden/bin/gone"
    EDEN_GRAFT_FORCE=true run bash "$GRAFTERS/graft-bin" < /dev/null
    [ "$status" -eq 1 ]
    [ -L "$HOME/.eden/bin/gone" ]
}

@test "a link into a branch's platform folder is named by it" {
    mkdir -p "$BRANCH/platforms/mac/.local/bin" "$HOME/.eden/bin"
    ln -s "$BRANCH/platforms/mac/.local/bin/tool" "$HOME/.eden/bin/tool"
    EDEN_PLATFORM=mac run bash "$GRAFTERS/graft-bin" < /dev/null
    [[ "$output" =~ "× ~/.eden/bin/tool [removed: broken link into work (mac)]" ]] || false
}

@test "a link through a branch folder that links to a checkout not here is left" {
    # The branch's .claude/rules is a link to an external checkout, as
    # macos's tmux/plugins/claude-status is; the checkout is not here.
    mkdir -p "$BRANCH/.claude" "$HOME/.claude/rules"
    ln -s "$BATS_TEST_TMPDIR/not-here/rules" "$BRANCH/.claude/rules"
    ln -s "$BRANCH/.claude/rules/x.md" "$HOME/.claude/rules/x.md"
    graft claude
    [ "$status" -eq 0 ]
    [ -L "$HOME/.claude/rules/x.md" ]
    [[ ! "$output" =~ "removed" ]] || false
}

@test "a link whose text ends in a slash is judged as without it" {
    mkdir -p "$BRANCH" "$HOME/.claude/skills"
    ln -s "$BATS_TEST_TMPDIR/outside/dangle" "$BRANCH/dangle"
    ln -s "$BRANCH/dangle/../" "$HOME/.claude/skills/ts"
    ln -s "$BRANCH/dangle/.." "$HOME/.claude/skills/nots"
    # Into the branch, broken, written with a slash: taken out as without.
    ln -s "$BRANCH/.claude/skills/gone/" "$HOME/.claude/skills/slashed"
    graft claude
    [ -L "$HOME/.claude/skills/ts" ]
    [ -L "$HOME/.claude/skills/nots" ]
    [ ! -L "$HOME/.claude/skills/slashed" ]
}

@test "an .eden-graft entry of slashes, or one that climbs out, never has the folder above \$HOME cleaned" {
    ln -s "$BRANCH/gone" "$BATS_TEST_TMPDIR/outside-home"
    for entry in / // '"/"' ../x; do
        printf '%s\n' "$entry" > "$BRANCH/.eden-graft"
        graft configs
        [ -L "$BATS_TEST_TMPDIR/outside-home" ]
    done
}

@test "a branch registered through a link is named as registered" {
    ln -s "$BRANCH" "$BATS_TEST_TMPDIR/alias"
    echo "$BATS_TEST_TMPDIR/alias" > "$XDG_CONFIG_HOME/eden/branches"
    mkdir -p "$HOME/.eden/bin"
    ln -s "$BATS_TEST_TMPDIR/alias/.local/bin/tool" "$HOME/.eden/bin/tool"
    graft bin
    [[ "$output" =~ "× ~/.eden/bin/tool [removed: broken link into alias]" ]] || false
}

@test "nothing else is touched: a working link, a real file, a broken link elsewhere or into an unregistered branch, one a folder below" {
    old="$BATS_TEST_TMPDIR/old"
    mkdir -p "$old" "$BRANCH/.claude/skills/live" "$HOME/.claude/skills/deeper"
    touch "$old/.eden-graft" "$BRANCH/.claude/skills/live/SKILL.md"
    ln -s "$BRANCH/.claude/skills/live" "$HOME/.claude/skills/mine-live"
    echo keep > "$HOME/.claude/skills/real.md"
    ln -s "$BATS_TEST_TMPDIR/elsewhere/gone" "$HOME/.claude/skills/elsewhere"
    ln -s "$old/.claude/skills/gone" "$HOME/.claude/skills/old-branch"
    ln -s "$BRANCH/.claude/skills/gone" "$HOME/.claude/skills/deeper/gone"
    graft claude
    [ "$status" -eq 0 ]
    [ -L "$HOME/.claude/skills/mine-live" ]
    [ "$(cat "$HOME/.claude/skills/real.md")" = keep ]
    [ -L "$HOME/.claude/skills/elsewhere" ]
    [ -L "$HOME/.claude/skills/old-branch" ]
    [ -L "$HOME/.claude/skills/deeper/gone" ]
    [[ ! "$output" =~ "removed" ]] || false
}

@test "each grafter stopped by a collision takes nothing out" {
    # A second branch with the same file as this one, for every grafter;
    # beside each, a broken link into this branch that a graft would take.
    other="$BATS_TEST_TMPDIR/other"
    echo "$other" >> "$XDG_CONFIG_HOME/eden/branches"
    for f in .claude/skills/x/SKILL.md .config/app/a.conf .config/eden/env.d/x.sh \
             .config/git/identities/x .config/zsh/zshenv.d/x.zsh; do
        mkdir -p "$BRANCH/${f%/*}" "$other/${f%/*}"
        touch "$BRANCH/$f" "$other/$f"
    done
    echo .config/app/a.conf > "$BRANCH/.eden-graft"
    echo .config/app/a.conf > "$other/.eden-graft"
    folders=".claude/skills .config/app .config/eden/env.d .config/git/identities .config/zsh/zshenv.d"
    for d in $folders; do
        mkdir -p "$HOME/$d"
        ln -s "$BRANCH/$d/gone" "$HOME/$d/gone"
    done
    for g in claude configs env git zsh; do
        graft "$g"
        [ "$status" -eq 1 ] || { echo "graft-$g: status $status, not 1"; false; }
    done
    for d in $folders; do
        [ -L "$HOME/$d/gone" ] || { echo "~/$d/gone was taken out"; false; }
    done
}

@test "a folder that is a branch's own, linked whole, is left: nothing inside a branch is taken out" {
    # ~/.claude/skills is the branch's folder itself, as .eden-graft would
    # link it; a broken link inside is the branch's file, not a leftover.
    mkdir -p "$BRANCH/.claude/skills" "$HOME/.claude"
    ln -s "$BRANCH/.claude/skills/nothing" "$BRANCH/.claude/skills/dangling"
    ln -s "$BRANCH/.claude/skills" "$HOME/.claude/skills"
    graft claude
    [ "$status" -eq 0 ]
    [ -L "$BRANCH/.claude/skills/dangling" ]
    # A branch registered without an .eden-graft (eden branch add only
    # warns, outside gardens) is still a branch here.
    rm "$BRANCH/.eden-graft"
    graft claude
    [ "$status" -eq 0 ]
    [ -L "$BRANCH/.claude/skills/dangling" ]
}

@test "a folder that resolves into a branch not grafted here is left: its links are that branch's" {
    # As branches/personal on a machine that grows only bardo: on disk,
    # with an .eden-graft, not grafted. ~/.config/app is a leftover link
    # into it, and it tracks a link into the grafted branch.
    other="$BATS_TEST_TMPDIR/other"
    mkdir -p "$other/.config/app" "$BRANCH/.config/app" "$HOME/.config"
    touch "$other/.eden-graft" "$BRANCH/.config/app/a.conf"
    echo .config/app/a.conf > "$BRANCH/.eden-graft"
    ln -s "$BRANCH/.config/app/gone" "$other/.config/app/tracked-link"
    ln -s "$other/.config/app" "$HOME/.config/app"
    graft configs
    [ -L "$other/.config/app/tracked-link" ]
    [[ ! "$output" =~ "removed" ]] || false
}
