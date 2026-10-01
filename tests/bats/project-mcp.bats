#!/usr/bin/env bats
# graft-mcp puts a project's MCP servers in Claude Code's local scope for
# that repo, instead of generating a .mcp.json inside it.

setup() {
    command -v jq >/dev/null || skip "jq not installed"
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
    export HOME="$BATS_TEST_TMPDIR/home"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CONFIG_HOME="$HOME/.config"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    mkdir -p "$XDG_CONFIG_HOME/eden" "$CLAUDE_CONFIG_DIR"

    REPO="$BATS_TEST_TMPDIR/repos/app"
    git init -q "$REPO"
    REPO="$(cd "$REPO" && pwd -P)"
    WORK="$BATS_TEST_TMPDIR/work"
    mkdir -p "$WORK/projects/app/.mcp"
    echo "$REPO" > "$WORK/projects/app/.eden-target"
    server '{"type": "http", "url": "https://mcp.example.com/a"}'
    echo "$WORK" > "$XDG_CONFIG_HOME/eden/branches"

    # A stand-in for the claude CLI: local scope kept in .claude.json under
    # the repo's path, as Claude Code keeps it, and every call logged.
    STUBS="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$STUBS"
    export CALLS="$BATS_TEST_TMPDIR/calls"
    cat > "$STUBS/claude" <<'EOF'
#!/bin/bash
echo "$*" >> "$CALLS"
f="$CLAUDE_CONFIG_DIR/.claude.json"
[[ -f "$f" ]] || echo '{}' > "$f"
key="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
has() { jq -e --arg k "$key" --arg n "$1" '.projects[$k].mcpServers[$n] != null' "$f" >/dev/null; }
case "$1 $2 $3 $4" in
    "mcp add-json -s local")
        has "$5" && { echo "MCP server $5 already exists in local config"; exit 1; }
        jq --arg k "$key" --arg n "$5" --argjson s "$6" '.projects[$k].mcpServers[$n] = $s' "$f" > "$f.new" && mv "$f.new" "$f" ;;
    "mcp remove -s local")
        has "$5" || exit 1
        jq --arg k "$key" --arg n "$5" 'del(.projects[$k].mcpServers[$n])' "$f" > "$f.new" && mv "$f.new" "$f" ;;
    *) exit 2 ;;
esac
EOF
    chmod +x "$STUBS/claude"
    export PATH="$STUBS:$PATH"
    GRAFTER="$EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-mcp"
}

# server <json>: the project's only server, "tracker".
server() {
    printf '{"mcpServers": {"tracker": %s}}\n' "$1" > "$WORK/projects/app/.mcp/servers.json"
}

local_server() {
    jq -cS --arg k "$REPO" '.projects[$k].mcpServers.tracker' "$CLAUDE_CONFIG_DIR/.claude.json"
}

@test "a project's servers go to Claude's local scope for the repo, not into a .mcp.json" {
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [ "$(local_server)" = '{"type":"http","url":"https://mcp.example.com/a"}' ]
    [ ! -e "$REPO/.mcp.json" ]
}

@test "a second graft calls claude no more" {
    run "$GRAFTER"
    rm "$CALLS"
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [ ! -e "$CALLS" ]
}

@test "a changed server replaces the one in local scope" {
    run "$GRAFTER"
    server '{"type": "http", "url": "https://mcp.example.com/b"}'
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [ "$(local_server)" = '{"type":"http","url":"https://mcp.example.com/b"}' ]
}

@test "an untracked .mcp.json from an earlier graft is named, not deleted" {
    echo '{"mcpServers": {"tracker": {"type": "http", "url": "https://old"}}}' > "$REPO/.mcp.json"
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "app/.mcp.json is untracked and still has tracker" ]]
    [ -f "$REPO/.mcp.json" ]
}

@test "without the claude CLI the project is skipped with a warning" {
    EDEN_CLAUDE_CLI=no-such-claude run "$GRAFTER"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "no-such-claude not found" ]]
    [ ! -e "$REPO/.mcp.json" ]
}

@test "global servers go to the state file under CLAUDE_CONFIG_DIR, where Claude reads them" {
    echo '{}' > "$CLAUDE_CONFIG_DIR/.claude.json"
    mkdir -p "$WORK/.config/mcp"
    echo '{"mcpServers": {"docs": {"type": "http", "url": "https://docs.example.com"}}}' > "$WORK/.config/mcp/servers.json"
    run "$GRAFTER"
    [ "$status" -eq 0 ]
    [ "$(jq -r '.mcpServers.docs.url' "$CLAUDE_CONFIG_DIR/.claude.json")" = https://docs.example.com ]
}
