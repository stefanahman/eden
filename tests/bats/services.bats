#!/usr/bin/env bats
# Whether Karabiner-Elements runs is one check, its core service.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    stubs="$BATS_TEST_TMPDIR/stubs"
    mkdir -p "$stubs"
    # The process list pgrep -f matches against, one command line each.
    export PROCS="$BATS_TEST_TMPDIR/procs"
    : > "$PROCS"
    cat > "$stubs/pgrep" <<'EOF'
#!/bin/bash
[[ "$1" == -f ]] || exit 3
grep -Eq -- "$2" "$PROCS"
EOF
    chmod +x "$stubs/pgrep"
    export PATH="$stubs:$PATH"
}

# Karabiner-Elements 16's processes, from a running Mac.
DRIVER='/Library/SystemExtensions/37889146-640F-48F1-8139-21D4AA8E3036/org.pqrs.Karabiner-DriverKit-VirtualHIDDevice.dext/org.pqrs.Karabiner-DriverKit-VirtualHIDDevice'
HID_DAEMON='/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'
CORE='/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Core-Service.app/Contents/MacOS/Karabiner-Core-Service'
USER_SERVER='/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Console-User-Server.app/Contents/MacOS/Karabiner-Console-User-Server'
SETTINGS='/Applications/Karabiner-Elements.app/Contents/MacOS/Karabiner-Elements'
# Karabiner-Elements 15's, which does the remapping.
GRABBER='/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_grabber'

@test "Karabiner runs when its core service does, under its 16 name or its 15 one" {
    source "$EDEN_ROOT/lib/services.sh"
    printf '%s\n' "$DRIVER" "$HID_DAEMON" "$CORE" "$USER_SERVER" > "$PROCS"
    eden_karabiner_running
    printf '%s\n' "$GRABBER" > "$PROCS"
    eden_karabiner_running
}

@test "Karabiner's driver, its user server or its Settings app alone is not Karabiner running" {
    # The driver stays loaded whenever Karabiner is installed, and the
    # Settings app runs only while its window is open.
    source "$EDEN_ROOT/lib/services.sh"
    printf '%s\n' "$DRIVER" "$HID_DAEMON" "$USER_SERVER" "$SETTINGS" \
        '/usr/bin/vim /Users/me/.config/karabiner/karabiner.json' > "$PROCS"
    run eden_karabiner_running
    [ "$status" -eq 1 ]
}
