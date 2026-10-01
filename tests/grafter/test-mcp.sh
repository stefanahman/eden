#!/bin/bash
# Integration tests for graft-mcp
# Runs in a temp directory sandbox — safe against real $HOME

# Capture real repo root before sandbox overrides EDEN_ROOT
REAL_EDEN_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GRAFTER="$REAL_EDEN_ROOT/packages/eden/.eden/libexec/grafters/graft-mcp"

source "$(dirname "$0")/../helpers.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  graft-mcp tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Skip if jq not available (graft-mcp requires it)
if ! command -v jq >/dev/null 2>&1; then
    echo "  jq not installed — skipping graft-mcp tests"
    exit 0
fi


# claude_stub: a stand-in for the claude CLI that records each call as
# "<directory> <arguments>" in $SANDBOX/claude-calls.
claude_stub() {
    mkdir -p "$SANDBOX/bin"
    printf '#!/bin/bash\necho "$PWD $*" >> "%s/claude-calls"\n' "$SANDBOX" > "$SANDBOX/bin/claude"
    chmod +x "$SANDBOX/bin/claude"
    export EDEN_CLAUDE_CLI="$SANDBOX/bin/claude"
}

# =============================================================================
# Test 1: No branches file
# =============================================================================
sandbox_setup
rm -f "$XDG_CONFIG_HOME/eden/branches"

describe "no branches file still writes empty global config"
output=$("$GRAFTER" 2>&1)
assert_file_exists "$HOME/.config/mcp/servers.json"

sandbox_teardown

# =============================================================================
# Test 2: Global merge from branch
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.config/mcp"
cat > "$branch/.config/mcp/servers.json" <<'JSON'
{
    "mcpServers": {
        "test-server": {
            "command": "/usr/bin/test-server",
            "args": []
        }
    }
}
JSON
register_branch "$branch"

describe "global merge creates servers.json with branch servers"
output=$("$GRAFTER" 2>&1)
count=$(jq '.mcpServers | length' "$HOME/.config/mcp/servers.json")
if [[ "$count" == "1" ]]; then pass; else fail "expected 1 server, got $count"; fi

sandbox_teardown

# =============================================================================
# Test 3: Multi-branch global merge
# =============================================================================
sandbox_setup

branch1=$(create_test_branch "branch-a")
mkdir -p "$branch1/.config/mcp"
cat > "$branch1/.config/mcp/servers.json" <<'JSON'
{"mcpServers": {"server-a": {"command": "/usr/bin/a", "args": []}}}
JSON

branch2=$(create_test_branch "branch-b")
mkdir -p "$branch2/.config/mcp"
cat > "$branch2/.config/mcp/servers.json" <<'JSON'
{"mcpServers": {"server-b": {"command": "/usr/bin/b", "args": []}}}
JSON

register_branch "$branch1"
register_branch "$branch2"

describe "multi-branch merge combines servers"
output=$("$GRAFTER" 2>&1)
count=$(jq '.mcpServers | length' "$HOME/.config/mcp/servers.json")
if [[ "$count" == "2" ]]; then pass; else fail "expected 2 servers, got $count"; fi

sandbox_teardown

# =============================================================================
# Test 4: Project scope — Claude Code's local scope, not a .mcp.json
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
# The path as $PWD spells it after a cd: no doubled slash (macOS TMPDIR
# ends in one), so it matches what the stub logs.
project_target="$(cd "$SANDBOX" && pwd)/project-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/myapp/.mcp"
cat > "$branch/projects/myapp/.mcp/servers.json" <<'JSON'
{"mcpServers": {"project-server": {"command": "/usr/bin/proj", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"
claude_stub

describe "project scope writes no .mcp.json in the target"
output=$("$GRAFTER" 2>&1)
assert_not_exists "$project_target/.mcp.json"

describe "project servers go to Claude Code's local scope, run in the target"
if grep -qF "$project_target mcp add-json -s local project-server" "$SANDBOX/claude-calls"; then pass; else fail "no add-json for project-server in $project_target"; fi

unset EDEN_CLAUDE_CLI
sandbox_teardown

# =============================================================================
# Test 5: Project scope — nested directory
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
# The path as $PWD spells it after a cd: no doubled slash (macOS TMPDIR
# ends in one), so it matches what the stub logs.
project_target="$(cd "$SANDBOX" && pwd)/nested-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/games/mygame/.mcp"
cat > "$branch/projects/games/mygame/.mcp/servers.json" <<'JSON'
{"mcpServers": {"game-server": {"command": "/usr/bin/game", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/games/mygame/.eden-target"
register_branch "$branch"
claude_stub

describe "nested project scope reaches the target's local scope"
output=$("$GRAFTER" 2>&1)
if grep -qF "$project_target mcp add-json -s local game-server" "$SANDBOX/claude-calls"; then pass; else fail "no add-json for game-server in $project_target"; fi

describe "reports nested project name"
assert_output_contains "$output" "games/mygame"

unset EDEN_CLAUDE_CLI
sandbox_teardown

# =============================================================================
# Test 6: Project without .mcp/servers.json is skipped
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/no-mcp-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/nomcp"
echo "$project_target" > "$branch/projects/nomcp/.eden-target"
register_branch "$branch"

describe "project without .mcp/servers.json skips quietly"
output=$("$GRAFTER" 2>&1)
assert_not_exists "$project_target/.mcp.json"

sandbox_teardown

# =============================================================================
# Test 7: Project servers don't leak into global config
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/project-target"
mkdir -p "$project_target"

# Global server
mkdir -p "$branch/.config/mcp"
cat > "$branch/.config/mcp/servers.json" <<'JSON'
{"mcpServers": {"global-srv": {"command": "/usr/bin/global", "args": []}}}
JSON

# Project server
mkdir -p "$branch/projects/myapp/.mcp"
cat > "$branch/projects/myapp/.mcp/servers.json" <<'JSON'
{"mcpServers": {"project-srv": {"command": "/usr/bin/proj", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"
claude_stub

output=$("$GRAFTER" 2>&1)

describe "global config has only global server"
global_has_proj=$(jq '.mcpServers | has("project-srv")' "$HOME/.config/mcp/servers.json")
if [[ "$global_has_proj" == "false" ]]; then pass; else fail "project server leaked into global"; fi

describe "the project's local scope has only the project server"
if grep -qF "add-json -s local project-srv" "$SANDBOX/claude-calls" && ! grep -qF "global-srv" "$SANDBOX/claude-calls"; then pass; else fail "global server leaked into project"; fi

unset EDEN_CLAUDE_CLI
sandbox_teardown

# =============================================================================
# Test 10: Claude Desktop config is never modified
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.config/mcp"
cat > "$branch/.config/mcp/servers.json" <<'JSON'
{"mcpServers": {"srv": {"command": "/usr/bin/srv", "args": []}}}
JSON
register_branch "$branch"

# Create Claude Desktop config dir with existing config
mkdir -p "$HOME/Library/Application Support/Claude"
cat > "$HOME/Library/Application Support/Claude/claude_desktop_config.json" <<'JSON'
{"mcpServers": {}, "preferences": {"sidebarMode": "chat"}}
JSON

describe "Claude Desktop config is not modified by graft"
output=$("$GRAFTER" 2>&1)
servers=$(jq '.mcpServers | length' "$HOME/Library/Application Support/Claude/claude_desktop_config.json")
if [[ "$servers" == "0" ]]; then pass; else fail "expected 0 servers in Desktop, got $servers"; fi

describe "Claude Desktop preferences are preserved"
mode=$(jq -r '.preferences.sidebarMode' "$HOME/Library/Application Support/Claude/claude_desktop_config.json")
if [[ "$mode" == "chat" ]]; then pass; else fail "preferences lost"; fi

sandbox_teardown

# =============================================================================
# Test 11: Remote (non-stdio) servers are included in global config
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
mkdir -p "$branch/.config/mcp"
cat > "$branch/.config/mcp/servers.json" <<'JSON'
{
    "mcpServers": {
        "local-srv": {"command": "/usr/bin/local", "args": []},
        "remote-srv": {"type": "http", "url": "https://example.com/mcp"}
    }
}
JSON
register_branch "$branch"

describe "global config includes remote servers"
output=$("$GRAFTER" 2>&1)
count=$(jq '.mcpServers | length' "$HOME/.config/mcp/servers.json")
if [[ "$count" == "2" ]]; then pass; else fail "expected 2 servers, got $count"; fi

sandbox_teardown

# =============================================================================
# Results
# =============================================================================

report
