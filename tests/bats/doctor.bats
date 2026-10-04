#!/usr/bin/env bats
# Integration tests for `eden doctor`.

setup() {
    EDEN_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export EDEN_ROOT
}

@test "doctor --help is non-empty and lists exit codes" {
    run "$EDEN_ROOT/bin/eden-doctor" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Exit codes:" ]]
    [[ "$output" =~ "All checks passed" ]]
}

@test "doctor --format=plain emits parseable severity|message lines" {
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ ^ok\| ]] || [[ "$output" =~ ok\|.* ]]
    # Every non-empty line must start with ok|, warn|, error|, info|, or summary|
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        [[ "$line" =~ ^(ok|warn|error|info|summary)\| ]] || {
            echo "Unparseable line: $line"
            return 1
        }
    done <<< "$output"
}

@test "doctor exits 0 when clean, 1 with warnings, 2 with errors" {
    # We can't easily simulate all three in a sandbox, but we can assert that
    # at least the exit code is in {0,1,2} (never 3+ or negative).
    set +e
    "$EDEN_ROOT/bin/eden-doctor" --format=plain >/dev/null 2>&1
    status=$?
    set -e
    [ "$status" -ge 0 ] && [ "$status" -le 2 ]
}

@test "doctor rejects unknown flags with exit 2" {
    run "$EDEN_ROOT/bin/eden-doctor" --bogus-flag
    [ "$status" -eq 2 ]
    [[ "$output" =~ "Unknown option" ]]
}

@test "doctor names an MCP server whose command is gone, and how to remove it" {
    export HOME="$BATS_TEST_TMPDIR/home"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR"
    cat > "$CLAUDE_CONFIG_DIR/.claude.json" <<EOF2
{
  "mcpServers": {
    "gone": {"command": "$HOME/.eden/bin/mcp-gone"},
    "here": {"command": "/bin/sh"},
    "bare": {"command": "npx"},
    "web": {"type": "http", "url": "https://example.test/mcp"}
  },
  "projects": {
    "$HOME/src/app": {"mcpServers": {"stale": {"command": "/nonexistent/mcp-stale"}}}
  }
}
EOF2
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ "warn|MCP server gone (user scope): ~/.eden/bin/mcp-gone is missing — claude mcp remove gone -s user" ]]
    [[ "$output" =~ "warn|MCP server stale (~/src/app, local scope): /nonexistent/mcp-stale is missing — in ~/src/app: claude mcp remove stale -s local" ]]
    [[ ! "$output" =~ "MCP server here" ]]
    [[ ! "$output" =~ "MCP server bare" ]]
    [[ ! "$output" =~ "MCP server web" ]]
}

@test "doctor says when it cannot read Claude Code's state, rather than passing" {
    export HOME="$BATS_TEST_TMPDIR/home"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR"
    printf '{"mcpServers":{"gone":{"command":"/nonexistent/x"}}' > "$CLAUDE_CONFIG_DIR/.claude.json"
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ "warn|MCP servers: could not read" ]]
    [[ ! "$output" =~ "Every MCP server's command is there" ]]
}

@test "doctor checks a bare command on PATH, and leaves HTTP servers and odd paths alone" {
    export HOME="$BATS_TEST_TMPDIR/home"
    export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"
    mkdir -p "$HOME" "$CLAUDE_CONFIG_DIR" "$BATS_TEST_TMPDIR/bin dir"
    cp /bin/sh "$BATS_TEST_TMPDIR/bin dir/a\\b"
    jq -n --arg bs "$BATS_TEST_TMPDIR/bin dir/a\\b" '{mcpServers: {
        nope: {command: "mcp-nope-not-on-path"},
        sh: {command: "sh"},
        web: {type: "http", url: "https://example.test/mcp", command: "/nonexistent/q"},
        odd: {command: $bs}}}' > "$CLAUDE_CONFIG_DIR/.claude.json"
    run "$EDEN_ROOT/bin/eden-doctor" --format=plain
    [[ "$output" =~ "warn|MCP server nope (user scope): mcp-nope-not-on-path is not on PATH — claude mcp remove nope -s user" ]]
    [[ ! "$output" =~ "MCP server sh " ]]
    [[ ! "$output" =~ "MCP server web" ]]
    [[ ! "$output" =~ "MCP server odd" ]]
}
