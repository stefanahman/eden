#!/usr/bin/env bats
# `eden secrets` reads each secret from the account it names.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden/local"
    cat > "$XDG_CONFIG_HOME/eden/local/secrets-all" <<'EOF'
[secret]
name=Work token
path=op://Employee/work-token/credential
description=A secret in the work account
op_account=example-corp.1password.com

[secret]
name=Home token
path=op://Private/home-token/credential
description=A secret in the default account
EOF
    CALLS="$BATS_TEST_TMPDIR/calls"
    export CALLS
    STUBS="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$STUBS"
}

@test "validate passes op_account to op read as --account" {
    cat > "$STUBS/op" <<'EOF'
#!/bin/bash
echo "$*" >> "$CALLS"
EOF
    chmod +x "$STUBS/op"
    PATH="$STUBS:$PATH" run "$EDEN_ROOT/bin/eden-secrets" validate
    [ "$status" -eq 0 ]
    grep -qx 'read --account example-corp.1password.com op://Employee/work-token/credential' "$CALLS"
    grep -qx 'read op://Private/home-token/credential' "$CALLS"
}

@test "another provider gets the account as EDEN_SECRET_ACCOUNT" {
    cat > "$STUBS/fetch" <<'EOF'
#!/bin/bash
echo "${EDEN_SECRET_ACCOUNT:-none} $*" >> "$CALLS"
EOF
    chmod +x "$STUBS/fetch"
    EDEN_SECRET_GET="$STUBS/fetch" run "$EDEN_ROOT/bin/eden-secrets" validate
    [ "$status" -eq 0 ]
    grep -qx 'example-corp.1password.com op://Employee/work-token/credential' "$CALLS"
    grep -qx 'none op://Private/home-token/credential' "$CALLS"
}

@test "list shows the account a secret names" {
    run "$EDEN_ROOT/bin/eden-secrets" list
    [ "$status" -eq 0 ]
    [[ "$output" =~ "1Password Account:"[^$'\n']*"example-corp.1password.com" ]]
}
