#!/bin/bash
# Eden installer - Bootstrap Eden on a fresh system
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verbose mode
VERBOSE=false
if [[ "$1" == "--verbose" ]] || [[ "$1" == "-v" ]]; then
    VERBOSE=true
    STOW_VERBOSE="-v"
fi

log() {
    echo -e "${GREEN}▸${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

verbose() {
    if $VERBOSE; then
        echo "  $1"
    fi
}

# Pre-flight checks
log "Running pre-flight checks..."

# Check for git
if ! command -v git >/dev/null 2>&1; then
    error "git is not installed. Please install git first."
fi
verbose "✓ git found: $(git --version | head -1)"

# Check for stow
if ! command -v stow >/dev/null 2>&1; then
    error "GNU Stow is not installed. Please install stow first."
fi

# Check stow version
STOW_VERSION=$(stow --version | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
verbose "✓ stow found: version $STOW_VERSION"

if ! awk -v ver="$STOW_VERSION" 'BEGIN { exit (ver < 2.3) }'; then
    warn "stow version $STOW_VERSION found (recommend >= 2.3.0)"
fi

# Detect OS
log "Detecting operating system..."
OS=""
case "$(uname -s)" in
    Linux*)
        OS="arch"
        verbose "✓ Detected: Linux (using arch package)"
        ;;
    Darwin*)
        OS="mac"
        verbose "✓ Detected: macOS (using mac package)"
        ;;
    *)
        error "Unsupported OS: $(uname -s). Eden supports Linux and macOS only."
        ;;
esac

# Get the Eden directory (where this script lives)
EDEN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
verbose "Eden directory: $EDEN_DIR"

cd "$EDEN_DIR" || error "Failed to cd to Eden directory"

# Stow packages
log "Deploying Eden packages..."

# Stow common package
verbose "Stowing common package..."
if stow $STOW_VERBOSE -t "$HOME" -d packages common 2>&1; then
    verbose "✓ common package deployed"
else
    error "Failed to stow common package. Check for conflicts:
    
  Conflicts detected. Existing files may be blocking Eden's symlinks.
  
  Options:
    1. Move conflicting files: mv ~/.config/git ~/.config/git.backup
    2. Use stow --adopt to keep existing files and adjust Eden
    
  Run with --verbose to see details."
fi

# Stow OS-specific package
verbose "Stowing $OS package..."
if stow $STOW_VERBOSE -t "$HOME" -d packages "$OS" 2>&1; then
    verbose "✓ $OS package deployed"
else
    error "Failed to stow $OS package"
fi

# Create local config directory
log "Setting up local config directory..."
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/eden/local"
verbose "✓ Created ${XDG_CONFIG_HOME:-$HOME/.config}/eden/local/"

# Check PATH (informational only)
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    warn "~/.local/bin is not in your PATH"
    echo "  Add this to your shell config (.zshrc or .bashrc):"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Success!
echo ""
log "Eden installed successfully! 🌳"
echo ""
echo "Next steps:"
echo "  • Run './doctor.sh' to validate installation"
echo "  • View templates: ls ~/.config/eden/templates/"
echo "  • Create a branch repo for private configs (see templates/README.md)"
echo ""

