#!/bin/bash
# Eden Setup Validation
# Run before committing to validate Node.js/MCP integration setup
# Usage: tests/validate-setup.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

passed=0
failed=0

test() {
    echo -en "${BLUE}Testing:${NC} $1 ... "
}

pass() {
    echo -e "${GREEN}✓${NC}"
    ((passed++))
}

fail() {
    echo -e "${RED}✗${NC} $2"
    ((failed++))
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Eden Setup Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to repo root if running from tests/
cd "$(dirname "$0")/.." || exit 1

# Test 1: Bash script syntax
test "eden-mcp-setup syntax"
if bash -n packages/common/.local/bin/eden-mcp-setup 2>/dev/null; then
    pass
else
    fail "Syntax error in eden-mcp-setup"
fi

test "eden-node-setup syntax"
if bash -n packages/common/.local/bin/eden-node-setup 2>/dev/null; then
    pass
else
    fail "Syntax error in eden-node-setup"
fi

# Test 2: Scripts are executable
test "Scripts are executable"
if [[ -x packages/common/.local/bin/eden-mcp-setup ]] && [[ -x packages/common/.local/bin/eden-node-setup ]]; then
    pass
else
    fail "Scripts are not executable"
fi

# Test 3: JSON validity
test "MCP config JSON validity"
if python3 -m json.tool packages/common/.config/cursor/mcp_config.json > /dev/null 2>&1; then
    pass
else
    fail "Invalid JSON in mcp_config.json"
fi

# Test 4: Required files exist
test "Shell config files exist"
if [[ -f packages/common/.zshenv ]] && \
   [[ -f packages/common/.config/zsh/.zshrc ]] && \
   [[ -f packages/arch/.config/zsh/platform.zsh ]] && \
   [[ -f packages/mac/.config/zsh/platform.zsh ]]; then
    pass
else
    fail "Missing shell config files"
fi

test "Package manager configs exist"
if [[ -f packages/common/.npmrc ]] && \
   [[ -f packages/common/.config/pnpm/rc ]]; then
    pass
else
    fail "Missing package manager configs"
fi

test "Git ignore file exists"
if [[ -f packages/common/.config/git/ignore ]]; then
    pass
else
    fail "Missing git ignore file"
fi

# Test 5: Check for secrets in files (exclude validation patterns in scripts)
test "No hardcoded secrets"
if ! grep -r "ghp_[a-zA-Z0-9]\|github_pat_[a-zA-Z0-9]" packages/ 2>/dev/null | grep -v "Binary"; then
    pass
else
    fail "Found potential hardcoded GitHub token"
fi

# Test 6: XDG variables used correctly
test "XDG variables in configs"
if grep -q "XDG_CONFIG_HOME" packages/common/.config/zsh/.zshrc && \
   grep -q "XDG_DATA_HOME" packages/common/.config/zsh/.zshrc; then
    pass
else
    fail "XDG variables not used correctly"
fi

# Test 6b: Eden bin directory in PATH
test "Eden bin directory in PATH config"
if grep -q '\.eden/bin' packages/common/.config/zsh/.zshrc; then
    pass
else
    fail "~/.eden/bin not added to PATH in .zshrc"
fi

# Test 6c: Verify hybrid structure (bin separate, config in XDG)
test "Scripts reference ~/.config/eden/ for configs"
if grep -q 'XDG_CONFIG_HOME.*eden/branches' packages/common/.local/bin/eden-secrets && \
   grep -q 'XDG_CONFIG_HOME.*eden/branches' packages/common/.local/bin/eden-mcp-merge; then
    pass
else
    fail "Scripts should use ~/.config/eden/ for configs (XDG-compliant)"
fi

# Test 7: fnm integration
test "fnm integration in .zshrc"
if grep -q "fnm env --use-on-cd" packages/common/.config/zsh/.zshrc; then
    pass
else
    fail "fnm not configured for auto-switching"
fi

# Test 8: 1Password integration
test "1Password integration in MCP config"
if grep -q "op read" packages/common/.config/cursor/mcp_config.json; then
    pass
else
    fail "MCP config not using 1Password for token"
fi

# Test 9: Stow dry-run (check that new files would be symlinked)
test "Stow dry-run (new files)"
stow_output=$(stow -n -v -t "$HOME" -d packages common 2>&1 || true)
if echo "$stow_output" | grep -q "LINK.*zshenv" && echo "$stow_output" | grep -q "LINK.*cursor"; then
    pass
else
    fail "Stow would not create expected new symlinks"
fi

# Test 10: Package lists updated
test "fnm in package lists"
if grep -q "fnm" Brewfile && grep -q "fnm" pacman.txt; then
    pass
else
    fail "fnm not in both package lists"
fi

test "pnpm in package lists"
if grep -q "pnpm" Brewfile && grep -q "pnpm" pacman.txt; then
    pass
else
    fail "pnpm not in both package lists"
fi

# Test 11: MCP merge script
test "eden-mcp-merge syntax"
if bash -n packages/common/.local/bin/eden-mcp-merge 2>/dev/null; then
    pass
else
    fail "Syntax error in eden-mcp-merge"
fi

test "eden-mcp-merge is executable"
if [[ -x packages/common/.local/bin/eden-mcp-merge ]]; then
    pass
else
    fail "eden-mcp-merge is not executable"
fi

# Test 12: MCP config structure
test "MCP server naming (github-eden)"
if grep -q '"github-eden"' packages/common/.config/cursor/mcp_config.json; then
    pass
else
    fail "MCP server should be named 'github-eden'"
fi

test "MCP uses pnpm dlx"
if grep -q "pnpm dlx" packages/common/.config/cursor/mcp_config.json; then
    pass
else
    fail "MCP config should use 'pnpm dlx' for server"
fi

test "MCP config references correct 1Password item"
if grep -q "eden-github-mcp-token" packages/common/.config/cursor/mcp_config.json; then
    pass
else
    fail "MCP config should reference 'eden-github-mcp-token'"
fi

test "MCP config uses Eden bin in PATH"
if grep -q '\.eden/bin' packages/common/.config/cursor/mcp_config.json; then
    pass
else
    fail "MCP config should include ~/.eden/bin in PATH"
fi

# Test 13: MCP merge functionality (dry-run)
test "MCP merge creates correct output"
if EDEN_ROOT="$(pwd)" bash packages/common/.local/bin/eden-mcp-merge 2>&1 | grep -q "MCP config merged to.*/.cursor/mcp.json"; then
    pass
else
    fail "eden-mcp-merge doesn't output to ~/.cursor/mcp.json"
fi

test "MCP merged config is valid JSON"
if [[ -f "$HOME/.cursor/mcp.json" ]] && python3 -m json.tool "$HOME/.cursor/mcp.json" > /dev/null 2>&1; then
    pass
else
    fail "Merged MCP config is not valid JSON"
fi

test "MCP merged config contains github-eden"
if [[ -f "$HOME/.cursor/mcp.json" ]] && grep -q "github-eden" "$HOME/.cursor/mcp.json"; then
    pass
else
    fail "Merged MCP config missing github-eden server"
fi

# Test 14: Branch MCP servers are merged
test "Branch MCP servers are merged"
if [[ -f "$HOME/.cursor/mcp.json" ]]; then
    SERVER_COUNT=$(python3 -c "import json; f=open('$HOME/.cursor/mcp.json'); data=json.load(f); print(len(data.get('mcpServers', {})))")
    if [[ "$SERVER_COUNT" -gt 1 ]]; then
        pass
    else
        fail "Expected multiple MCP servers from branches (got $SERVER_COUNT)"
    fi
else
    fail "Merged MCP config not found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Results: ${GREEN}${passed} passed${NC}, ${RED}${failed} failed${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Ready to commit.${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed. Review before committing.${NC}"
    exit 1
fi

