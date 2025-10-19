#!/bin/bash
# Eden doctor - Health check and validation
set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
}

section() {
    echo ""
    echo "$1"
}

# Get Eden directory
EDEN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

section "Eden Health Check"
section "=================="

# Check dependencies
section "Dependencies:"

if command -v git >/dev/null 2>&1; then
    GIT_VER=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    check_pass "git installed ($GIT_VER)"
else
    check_fail "git not found"
fi

if command -v stow >/dev/null 2>&1; then
    STOW_VER=$(stow --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    if awk -v ver="$STOW_VER" 'BEGIN { exit (ver < 2.3) }'; then
        check_pass "stow installed ($STOW_VER)"
    else
        check_warn "stow $STOW_VER (recommend >= 2.3.0)"
    fi
else
    check_fail "stow not found"
fi

# Check repository
section "Repository:"

cd "$EDEN_DIR" || check_fail "Cannot access Eden directory"

if [ -d "$EDEN_DIR/.git" ]; then
    check_pass "Eden git repository exists"
    
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        check_pass "Repository is clean (no uncommitted changes)"
    else
        check_warn "Repository has uncommitted changes"
    fi
else
    check_fail "Not a git repository"
fi

# Check Eden directories
section "Structure:"

if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/eden/local" ]; then
    check_pass "Local config directory exists"
else
    check_fail "Local config directory missing: ${XDG_CONFIG_HOME:-$HOME/.config}/eden/local"
fi

if [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/eden/templates" ]; then
    check_pass "Templates directory deployed"
else
    check_warn "Templates not deployed (run ./install.sh)"
fi

# Check symlinks
section "Symlinks:"

BROKEN=0
if command -v find >/dev/null 2>&1; then
    # Check for broken symlinks in common Eden locations
    for dir in "$HOME/.config" "$HOME/.local/bin"; do
        if [ -d "$dir" ]; then
            while IFS= read -r -d '' link; do
                if [ ! -e "$link" ]; then
                    check_warn "Broken symlink: $link"
                    ((BROKEN++))
                fi
            done < <(find "$dir" -maxdepth 2 -type l -print0 2>/dev/null)
        fi
    done
    
    if [ $BROKEN -eq 0 ]; then
        check_pass "No broken symlinks found"
    fi
else
    check_warn "find command not available, skipping symlink check"
fi

# Check package counts
section "Package Statistics:"

COMMON_COUNT=$(find "$EDEN_DIR/packages/common" -type f 2>/dev/null | wc -l)
ARCH_COUNT=$(find "$EDEN_DIR/packages/arch" -type f 2>/dev/null | wc -l)
MAC_COUNT=$(find "$EDEN_DIR/packages/mac" -type f 2>/dev/null | wc -l)

echo "  Files: $COMMON_COUNT in common, $ARCH_COUNT in arch, $MAC_COUNT in mac"

# Platform parity check
section "Platform Parity:"

# Check for duplicate paths between common and platform packages
OS=""
case "$(uname -s)" in
    Linux*) OS="arch" ;;
    Darwin*) OS="mac" ;;
esac

if [ -n "$OS" ]; then
    DUPLICATES=0
    while IFS= read -r file; do
        REL_PATH="${file#$EDEN_DIR/packages/common/}"
        if [ -f "$EDEN_DIR/packages/$OS/$REL_PATH" ]; then
            check_warn "Duplicate: $REL_PATH (in both common and $OS)"
            ((DUPLICATES++))
        fi
    done < <(find "$EDEN_DIR/packages/common" -type f 2>/dev/null)
    
    if [ $DUPLICATES -eq 0 ]; then
        check_pass "No duplicate files between common and $OS packages"
    fi
fi

# Final result
section ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Eden is healthy!${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $ERRORS issue(s)${NC}"
    exit 1
fi

