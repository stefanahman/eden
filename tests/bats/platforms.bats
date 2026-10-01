#!/usr/bin/env bats
# A branch's platforms/<platform>/ folder is grafted after the branch, on
# that platform only.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir -p "$WORK/platforms/mac/.config/wm" "$WORK/platforms/arch/.config/bar"
    touch "$WORK/.eden-graft" "$WORK/platforms/mac/.config/wm/rc" "$WORK/platforms/arch/.config/bar/rc"
    echo .config/wm/rc > "$WORK/platforms/mac/.eden-graft"
    echo .config/bar/rc > "$WORK/platforms/arch/.eden-graft"
    echo "$WORK" > "$XDG_CONFIG_HOME/eden/branches"
    GRAFTERS="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"
}

@test "the platform is mac on macOS and arch on Linux, unless EDEN_PLATFORM says" {
    source "$EDEN_ROOT/lib/branches.sh"
    case "$(uname -s)" in
        Darwin) [ "$(eden_platform)" = mac ] ;;
        Linux) [ "$(eden_platform)" = arch ] ;;
    esac
    [ "$(EDEN_PLATFORM=mac eden_platform)" = mac ]
}

@test "graft roots are each branch, then its folder for this platform" {
    source "$EDEN_ROOT/lib/branches.sh"
    run env EDEN_PLATFORM=mac bash -c 'source "$EDEN_ROOT/lib/branches.sh"; eden_graft_roots'
    [ "$output" = "$WORK
$WORK/platforms/mac" ]
    [ "$(eden_branch_name "$WORK/platforms/mac")" = "work (mac)" ]
    [ "$(eden_branch_name "$WORK")" = "work" ]
}

@test "graft-configs links the mac folder's entries on mac, not the arch folder's" {
    EDEN_PLATFORM=mac run "$GRAFTERS/graft-configs"
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.config/wm/rc")" = "$WORK/platforms/mac/.config/wm/rc" ]
    [ ! -e "$HOME/.config/bar/rc" ]
}

@test "graft-configs links the arch folder's entries on arch, not the mac folder's" {
    EDEN_PLATFORM=arch run "$GRAFTERS/graft-configs"
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.config/bar/rc")" = "$WORK/platforms/arch/.config/bar/rc" ]
    [ ! -e "$HOME/.config/wm/rc" ]
}

@test "graft-bin links a platform folder's scripts on that platform only" {
    mkdir -p "$WORK/platforms/mac/.local/bin"
    echo '#!/bin/sh' > "$WORK/platforms/mac/.local/bin/open-browser"
    EDEN_PLATFORM=arch run "$GRAFTERS/graft-bin"
    [ ! -e "$HOME/.eden/bin/open-browser" ]
    EDEN_PLATFORM=mac run "$GRAFTERS/graft-bin"
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.eden/bin/open-browser")" = "$WORK/platforms/mac/.local/bin/open-browser" ]
}

@test "a branch and its platform folder writing one target collide" {
    mkdir -p "$WORK/.local/bin" "$WORK/platforms/mac/.local/bin"
    echo '#!/bin/sh' > "$WORK/.local/bin/tool"
    echo '#!/bin/sh' > "$WORK/platforms/mac/.local/bin/tool"
    EDEN_PLATFORM=mac run "$GRAFTERS/graft-bin"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.eden/bin/tool (work, work (mac))" ]]
}

@test "doctor checks a platform folder as a root, and not as an ungrafted item" {
    mkdir -p "$WORK/platforms/mac/.config/other"
    touch "$WORK/platforms/mac/.config/other/settings"
    EDEN_PLATFORM=mac run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ ! "$output" =~ "  platforms (not in .eden-graft" ]]
    [[ "$output" =~ "work (mac): ungrafted configs found" ]]
    [[ "$output" =~ ".config/other/settings (not in .eden-graft" ]]
}

@test "doctor does not call a link into this platform's folder a leftover" {
    mkdir -p "$HOME/.config/wm"
    ln -s "$WORK/platforms/mac/.config/wm/rc" "$HOME/.config/wm/rc"
    EDEN_PLATFORM=mac run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ ! "$output" =~ "Link into an unregistered branch" ]]
}

@test "eden branch list names the platform folders and the one grafted here" {
    EDEN_PLATFORM=mac run "$EDEN_ROOT/bin/eden-branch" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Platforms: arch, mac (grafted here)" ]]
}
