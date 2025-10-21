#!/bin/bash
# Eden Secrets Validation
# Optional test - checks if 1Password secrets are configured
# Note: This test is informational; missing secrets don't fail the build

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Eden Secrets Check (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to repo root
cd "$(dirname "$0")/.." || exit 1

# Check if op CLI is available
if ! command -v op >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} 1Password CLI not installed (optional)"
    echo ""
    echo "Secrets validation skipped."
    echo "To enable: Install 1Password CLI from https://developer.1password.com/docs/cli/"
    echo ""
    exit 0
fi

# Check if authenticated
if ! op account list >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠${NC} 1Password CLI not authenticated (optional)"
    echo ""
    echo "Secrets validation skipped."
    echo "To enable: Run 'op signin'"
    echo ""
    exit 0
fi

# Run validation
echo -e "${BLUE}ℹ${NC} Running secrets validation..."
echo ""

if packages/common/.local/bin/eden-secrets validate; then
    echo -e "${GREEN}✓${NC} All secrets configured"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠${NC} Some secrets are not configured (this is optional)"
    echo ""
    echo "To set up secrets:"
    echo "  eden-mcp-setup    # For GitHub MCP integration"
    echo ""
    exit 0  # Don't fail - secrets are optional for development
fi

