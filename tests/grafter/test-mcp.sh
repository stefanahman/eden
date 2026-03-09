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
# Test 4: Project scope — .mcp.json written to target
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/project-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/myapp/.mcp"
cat > "$branch/projects/myapp/.mcp/servers.json" <<'JSON'
{"mcpServers": {"project-server": {"command": "/usr/bin/proj", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"

describe "project scope writes .mcp.json in target dir"
output=$("$GRAFTER" 2>&1)
assert_file_exists "$project_target/.mcp.json"

describe "project .mcp.json contains project servers"
count=$(jq '.mcpServers | length' "$project_target/.mcp.json")
if [[ "$count" == "1" ]]; then pass; else fail "expected 1 server, got $count"; fi

sandbox_teardown

# =============================================================================
# Test 5: Project scope — nested directory
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/nested-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/games/mygame/.mcp"
cat > "$branch/projects/games/mygame/.mcp/servers.json" <<'JSON'
{"mcpServers": {"game-server": {"command": "/usr/bin/game", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/games/mygame/.eden-target"
register_branch "$branch"

describe "nested project scope writes .mcp.json"
output=$("$GRAFTER" 2>&1)
assert_file_exists "$project_target/.mcp.json"

describe "reports nested project name"
assert_output_contains "$output" "games/mygame"

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

output=$("$GRAFTER" 2>&1)

describe "global config has only global server"
global_has_proj=$(jq '.mcpServers | has("project-srv")' "$HOME/.config/mcp/servers.json")
if [[ "$global_has_proj" == "false" ]]; then pass; else fail "project server leaked into global"; fi

describe "project .mcp.json has only project server"
proj_has_global=$(jq '.mcpServers | has("global-srv")' "$project_target/.mcp.json")
if [[ "$proj_has_global" == "false" ]]; then pass; else fail "global server leaked into project"; fi

sandbox_teardown

# =============================================================================
# Test 8: Cursor sync — .cursor/mcp.json written if .cursor/ exists
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/cursor-target"
mkdir -p "$project_target/.cursor"

mkdir -p "$branch/projects/myapp/.mcp"
cat > "$branch/projects/myapp/.mcp/servers.json" <<'JSON'
{"mcpServers": {"cursor-srv": {"command": "/usr/bin/cursor", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"

describe "project with .cursor/ dir gets .cursor/mcp.json"
output=$("$GRAFTER" 2>&1)
assert_file_exists "$project_target/.cursor/mcp.json"

sandbox_teardown

# =============================================================================
# Test 9: No .cursor/ dir — .cursor/mcp.json not created
# =============================================================================
sandbox_setup

branch=$(create_test_branch "test-branch")
project_target="$SANDBOX/no-cursor-target"
mkdir -p "$project_target"

mkdir -p "$branch/projects/myapp/.mcp"
cat > "$branch/projects/myapp/.mcp/servers.json" <<'JSON'
{"mcpServers": {"srv": {"command": "/usr/bin/srv", "args": []}}}
JSON
echo "$project_target" > "$branch/projects/myapp/.eden-target"
register_branch "$branch"

describe "project without .cursor/ dir skips .cursor/mcp.json"
output=$("$GRAFTER" 2>&1)
assert_not_exists "$project_target/.cursor/mcp.json"

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
