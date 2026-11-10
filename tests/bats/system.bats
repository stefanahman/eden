#!/usr/bin/env bats
# graft-system installs a branch's .eden-system/ files as root: copied,
# never linked, shown and asked for first, and never with --force. The
# tests install into a scratch directory instead of /, without sudo, and
# answer the prompt through a pseudo-terminal.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"

    SYS="$BATS_TEST_TMPDIR/sys"
    mkdir -p "$SYS/etc"
    export EDEN_SYSTEM_DIR="$SYS" EDEN_SYSTEM_SUDO=""

    A="$BATS_TEST_TMPDIR/a"
    B="$BATS_TEST_TMPDIR/b"
    mkdir -p "$A/.eden-system/etc/app.d" "$B"
    printf '{"x": 1}\n' > "$A/.eden-system/etc/app.d/50-a.json"
    printf '%s\n' "$A" "$B" > "$XDG_CONFIG_HOME/eden/branches"

    GRAFTER="$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-system"
    TTY="$BATS_TEST_DIRNAME/with-tty"
    TARGET="$SYS/etc/app.d/50-a.json"
}

mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

@test "graft-system: yes on a terminal copies a new file in, with mode 644" {
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "+ /etc/app.d/50-a.json (a)" ]]
    [ -f "$TARGET" ] && [ ! -L "$TARGET" ]
    cmp -s "$TARGET" "$A/.eden-system/etc/app.d/50-a.json"
    [ "$(mode_of "$TARGET")" = 644 ]
}

@test "graft-system: an executable source is installed with mode 755" {
    printf '#!/bin/sh\n' > "$A/.eden-system/etc/app.d/hook"
    chmod +x "$A/.eden-system/etc/app.d/hook"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [ "$(mode_of "$SYS/etc/app.d/hook")" = 755 ]
}

@test "graft-system: no on a terminal writes nothing" {
    run "$TTY" n "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Left as they were" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: without a terminal it writes nothing and names what is pending" {
    run "$GRAFTER" < /dev/null
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1 system file(s) pending" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: --force never writes as root" {
    EDEN_GRAFT_FORCE=true run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "--force never writes as root" ]]
    [[ ! "$output" =~ "[y/N]" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: nothing changed, nothing asked" {
    "$TTY" y "$GRAFTER"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1 system file(s) up to date" ]]
    [[ ! "$output" =~ "[y/N]" ]]
}

@test "graft-system: a changed source is shown as a diff and installed on yes" {
    "$TTY" y "$GRAFTER"
    printf '{"x": 2}\n' > "$A/.eden-system/etc/app.d/50-a.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "~ /etc/app.d/50-a.json (a)" ]]
    [[ "$output" =~ '-{"x": 1}' ]]
    [[ "$output" =~ '+{"x": 2}' ]]
    [ "$(cat "$TARGET")" = '{"x": 2}' ]
}

@test "graft-system: a file Eden did not install is left alone" {
    mkdir -p "$SYS/etc/app.d"
    printf 'theirs\n' > "$TARGET"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/etc/app.d/50-a.json: there already, and Eden did not install it" ]]
    [ "$(cat "$TARGET")" = theirs ]
}

@test "graft-system: a file changed since Eden installed it is left alone" {
    "$TTY" y "$GRAFTER"
    printf 'edited\n' > "$TARGET"
    printf '{"x": 2}\n' > "$A/.eden-system/etc/app.d/50-a.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "changed since Eden installed it" ]]
    [ "$(cat "$TARGET")" = edited ]
}

@test "graft-system: anything but a regular file at the target is left alone, never written through" {
    mkdir -p "$SYS/etc/app.d"
    printf 'outside\n' > "$BATS_TEST_TMPDIR/outside"
    ln -s "$BATS_TEST_TMPDIR/outside" "$TARGET"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/etc/app.d/50-a.json: not a regular file" ]]
    [ -L "$TARGET" ]
    [ "$(cat "$BATS_TEST_TMPDIR/outside")" = outside ]
}

@test "graft-system: a file a branch dropped is offered for removal, and removed on yes" {
    "$TTY" y "$GRAFTER"
    rm "$A/.eden-system/etc/app.d/50-a.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "- /etc/app.d/50-a.json (no branch has it any more)" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: a dropped file changed since Eden installed it stays" {
    "$TTY" y "$GRAFTER"
    printf 'edited\n' > "$TARGET"
    rm "$A/.eden-system/etc/app.d/50-a.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "no branch has it any more, and it changed since Eden installed it" ]]
    [ "$(cat "$TARGET")" = edited ]
}

@test "graft-system: a removal that failed is offered again" {
    "$TTY" y "$GRAFTER"
    rm "$A/.eden-system/etc/app.d/50-a.json"
    chmod 555 "$SYS/etc/app.d"
    run "$TTY" y "$GRAFTER"
    chmod 755 "$SYS/etc/app.d"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Could not remove /etc/app.d/50-a.json" ]]
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "- /etc/app.d/50-a.json (no branch has it any more)" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: a new file root can see is there already is left alone" {
    # A directory the user cannot search hides its files; root sees them.
    # The stand-in sudo answers test -e for root.
    printf '#!/bin/sh\n[ "$1" = test ] && exit 0\nexec "$@"\n' > "$BATS_TEST_TMPDIR/sudo"
    chmod +x "$BATS_TEST_TMPDIR/sudo"
    EDEN_SYSTEM_SUDO="$BATS_TEST_TMPDIR/sudo" run "$TTY" y "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "/etc/app.d/50-a.json is there already (seen as root)" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: one file in two branches writes nothing" {
    mkdir -p "$B/.eden-system/etc/app.d"
    printf '{"x": 3}\n' > "$B/.eden-system/etc/app.d/50-a.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "/etc/app.d/50-a.json (a, b)" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: JSON that does not parse writes nothing" {
    command -v jq >/dev/null || skip "jq not installed"
    printf '{"x": \n' > "$A/.eden-system/etc/app.d/60-broken.json"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "/etc/app.d/60-broken.json is not valid JSON" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: a link in a branch's .eden-system writes nothing" {
    ln -s "$BATS_TEST_TMPDIR/outside" "$A/.eden-system/etc/app.d/70-link"
    run "$TTY" y "$GRAFTER"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "/etc/app.d/70-link is a link" ]]
    [ ! -e "$TARGET" ]
}

@test "graft-system: a platform folder's files are installed on that platform only" {
    mkdir -p "$A/platforms/arch/.eden-system/etc"
    printf 'arch\n' > "$A/platforms/arch/.eden-system/etc/arch.conf"
    EDEN_PLATFORM=mac run "$TTY" y "$GRAFTER"
    [ ! -e "$SYS/etc/arch.conf" ]
    EDEN_PLATFORM=arch run "$TTY" y "$GRAFTER"
    [[ "$output" =~ "+ /etc/arch.conf (a (arch))" ]]
    [ "$(cat "$SYS/etc/arch.conf")" = arch ]
}

@test "graft-system --pending lists what differs, one line each, for eden doctor" {
    run "$GRAFTER" --pending
    [ "$status" -eq 0 ]
    [ "$output" = $'install\t/etc/app.d/50-a.json\ta' ]
}
