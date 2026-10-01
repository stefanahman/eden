#!/usr/bin/env bats
# Two branches writing the same target stop the grafter, which then
# writes nothing and names both branches.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$XDG_CONFIG_HOME/eden"
    A="$BATS_TEST_TMPDIR/work"
    B="$BATS_TEST_TMPDIR/personal"
    mkdir -p "$A" "$B"
    printf '%s\n' "$A" "$B" > "$XDG_CONFIG_HOME/eden/branches"
    GRAFTERS="$EDEN_ROOT/packages/eden/.eden/libexec/grafters"
}

# in_both <path> <content>: the same file in both branches.
in_both() {
    local branch
    for branch in "$A" "$B"; do
        mkdir -p "$branch/$(dirname "$1")"
        printf '%s\n' "$2" > "$branch/$1"
    done
}

@test "the finder reports a shared target, and one inside another's" {
    source "$EDEN_ROOT/lib/collisions.sh"
    run eden_collisions < <(printf '%s\t%s\n' \
        '~/a' work '~/b' work '~/a' personal '~/b/c' personal '~/d' work '~/d' work '~/de' personal)
    [ "${lines[0]}" = '~/a (work, personal)' ]
    [ "${lines[1]}" = '~/b/c (personal) is inside ~/b (work)' ]
    [ "${#lines[@]}" -eq 2 ]
}

@test "graft-configs: two branches linking one path write nothing" {
    in_both .config/app/config.yaml 'x'
    echo .config/app/config.yaml > "$A/.eden-graft"
    echo .config/app/config.yaml > "$B/.eden-graft"
    run "$GRAFTERS/graft-configs"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.config/app/config.yaml (work, personal)" ]]
    [ ! -e "$HOME/.config/app/config.yaml" ]
}

@test "graft-configs: a path inside another branch's linked folder collides" {
    mkdir -p "$A/.config/app" "$B/.config/app"
    touch "$B/.config/app/extra.yaml"
    echo .config/app > "$A/.eden-graft"
    echo .config/app/extra.yaml > "$B/.eden-graft"
    run "$GRAFTERS/graft-configs"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.config/app/extra.yaml (personal) is inside ~/.config/app (work)" ]]
}

@test "graft-configs: different paths from two branches are both linked" {
    mkdir -p "$A/.config/one" "$B/.config/two"
    echo .config/one > "$A/.eden-graft"
    echo .config/two > "$B/.eden-graft"
    run "$GRAFTERS/graft-configs"
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.config/one")" = "$A/.config/one" ]
    [ "$(readlink "$HOME/.config/two")" = "$B/.config/two" ]
}

@test "graft-bin: one script name in two branches writes nothing" {
    in_both .local/bin/tool '#!/bin/sh'
    run "$GRAFTERS/graft-bin"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.eden/bin/tool (work, personal)" ]]
    [ ! -e "$HOME/.eden/bin/tool" ]
}

@test "graft-bin: a link no branch provides any more is replaced" {
    mkdir -p "$A/.local/bin" "$HOME/.eden/bin" "$BATS_TEST_TMPDIR/old"
    echo '#!/bin/sh' > "$A/.local/bin/tool"
    echo '#!/bin/sh' > "$BATS_TEST_TMPDIR/old/tool"
    ln -s "$BATS_TEST_TMPDIR/old/tool" "$HOME/.eden/bin/tool"
    run "$GRAFTERS/graft-bin"
    [ "$status" -eq 0 ]
    [ "$(readlink "$HOME/.eden/bin/tool")" = "$A/.local/bin/tool" ]
}

@test "graft-claude: one rule in two branches writes nothing" {
    in_both .claude/rules/style.md 'rule'
    run "$GRAFTERS/graft-claude"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.claude/rules/style.md (work, personal)" ]]
    [ ! -e "$HOME/.claude/rules/style.md" ]
}

@test "graft-zsh: one env file in two branches writes nothing" {
    in_both .config/zsh/zshenv.d/tools.zsh 'export A=1'
    run "$GRAFTERS/graft-zsh"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.config/zsh/zshenv.d/tools.zsh (work, personal)" ]]
    [ ! -e "$XDG_CONFIG_HOME/zsh/zshenv.d/tools.zsh" ]
}

@test "graft-git: one identity in two branches writes nothing" {
    in_both .config/git/identities/_default '[user]'
    run "$GRAFTERS/graft-git"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "~/.config/git/identities/_default (work, personal)" ]]
    [ ! -e "$HOME/.config/git/identities/_default" ]
}

@test "graft-mcp: one server name in two branches writes nothing" {
    command -v jq >/dev/null || skip "jq not installed"
    in_both .config/mcp/servers.json '{"mcpServers": {"tracker": {"command": "/bin/true"}}}'
    run "$GRAFTERS/graft-mcp"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "MCP server tracker (work, personal)" ]]
    [ ! -e "$HOME/.config/mcp/servers.json" ]
}

@test "graft-secrets: one secret id in two branches writes nothing" {
    in_both .eden-secrets $'[secret]\nid=api-token\nname=API token\npath=op://Vault/api/credential'
    run "$GRAFTERS/graft-secrets"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "secret api-token (work, personal)" ]]
    [ ! -e "$XDG_CONFIG_HOME/eden/local/secrets-all" ]
}

@test "graft-secrets: secrets without a shared id are collected" {
    printf '[secret]\nid=one\npath=op://V/one/c\n' > "$A/.eden-secrets"
    printf '[secret]\nid=two\npath=op://V/two/c\n[secret]\nname=no id\npath=op://V/x/c\n' > "$B/.eden-secrets"
    run "$GRAFTERS/graft-secrets"
    [ "$status" -eq 0 ]
    [ "$(grep -c '^\[secret\]' "$XDG_CONFIG_HOME/eden/local/secrets-all")" -eq 3 ]
}
