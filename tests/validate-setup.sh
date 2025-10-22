#!/bin/bash
# Eden Setup Validation
# Run before committing to validate Eden structure
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

# =============================================================================
# Core Binary Structure
# =============================================================================

test "Eden wrapper exists"
if [[ -f eden ]] && [[ -x eden ]]; then
    pass
else
    fail "Root eden wrapper missing or not executable"
fi

test "Eden CLI implementation exists"
if [[ -f bin/eden ]] && [[ -x bin/eden ]]; then
    pass
else
    fail "bin/eden missing or not executable"
fi

test "Core scripts exist and executable"
if [[ -x bin/eden-doctor ]] && [[ -x bin/eden-graft ]] && [[ -x bin/eden-update ]]; then
    pass
else
    fail "Missing or non-executable core scripts in bin/"
fi

test "Utility scripts exist and executable"
if [[ -x bin/eden-secrets ]] && [[ -x bin/eden-mcp-merge ]]; then
    pass
else
    fail "Missing or non-executable utility scripts in bin/"
fi

# =============================================================================
# Script Syntax Validation
# =============================================================================

test "bin/eden syntax"
if bash -n bin/eden 2>/dev/null; then
    pass
else
    fail "Syntax error in bin/eden"
fi

test "bin/eden-doctor syntax"
if bash -n bin/eden-doctor 2>/dev/null; then
    pass
else
    fail "Syntax error in bin/eden-doctor"
fi

test "bin/eden-graft syntax"
if bash -n bin/eden-graft 2>/dev/null; then
    pass
else
    fail "Syntax error in bin/eden-graft"
fi

test "bin/eden-update syntax"
if bash -n bin/eden-update 2>/dev/null; then
    pass
else
    fail "Syntax error in bin/eden-update"
fi

# =============================================================================
# Libexec Structure
# =============================================================================

test "Libexec directory exists"
if [[ -d packages/eden/.eden/libexec ]]; then
    pass
else
    fail "packages/eden/.eden/libexec directory missing"
fi

test "Libexec installers exist and executable"
libexec_ok=true
for script in packages/eden/.eden/libexec/*; do
    if [[ -f "$script" ]] && [[ ! -x "$script" ]]; then
        libexec_ok=false
        break
    fi
done
if $libexec_ok; then
    pass
else
    fail "Some libexec scripts are not executable"
fi

test "Libexec scripts syntax"
libexec_syntax_ok=true
for script in packages/eden/.eden/libexec/*; do
    if [[ -f "$script" ]]; then
        if ! bash -n "$script" 2>/dev/null; then
            libexec_syntax_ok=false
            break
        fi
    fi
done
if $libexec_syntax_ok; then
    pass
else
    fail "Syntax error in libexec script"
fi

# =============================================================================
# Security
# =============================================================================

test "No hardcoded secrets"
if ! grep -r "ghp_[a-zA-Z0-9]\|github_pat_[a-zA-Z0-9]" bin/ packages/ 2>/dev/null | grep -v "Binary\|grep -r"; then
    pass
else
    fail "Found potential hardcoded GitHub token"
fi

# =============================================================================
# Configuration Files
# =============================================================================

test "Shell config files exist"
if [[ -f packages/common/.zshenv ]] && \
   [[ -f packages/common/.config/zsh/.zshrc ]] && \
   [[ -f packages/arch/.config/zsh/platform.zsh ]] && \
   [[ -f packages/mac/.config/zsh/platform.zsh ]]; then
    pass
else
    fail "Missing shell config files"
fi

test "Git config exists"
if [[ -f packages/common/.config/git/config ]] && \
   [[ -f packages/common/.config/git/ignore ]]; then
    pass
else
    fail "Missing git config files"
fi

test "Package manager configs exist"
if [[ -f packages/common/.npmrc ]] && \
   [[ -f packages/common/.config/pnpm/rc ]]; then
    pass
else
    fail "Missing package manager configs"
fi

# =============================================================================
# JSON Validity
# =============================================================================

test "Cursor MCP config JSON validity"
if [[ -f packages/common/.config/cursor/mcp_config.json ]]; then
    if python3 -m json.tool packages/common/.config/cursor/mcp_config.json > /dev/null 2>&1; then
        pass
    else
        fail "Invalid JSON in mcp_config.json"
    fi
else
    fail "mcp_config.json missing"
fi

# =============================================================================
# Package Lists
# =============================================================================

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

test "stow in package lists"
if grep -q "stow" Brewfile && grep -q "stow" pacman.txt; then
    pass
else
    fail "stow not in both package lists"
fi

# =============================================================================
# Results
# =============================================================================

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
