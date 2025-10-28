#!/bin/bash
# Eden installer - Bootstrap Eden on a fresh system
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Options
VERBOSE=false
INSTALL_PACKAGES=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --verbose|-v)
            VERBOSE=true
            ;;
        --packages|-p)
            INSTALL_PACKAGES=true
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --packages, -p    Install packages from Brewfile/pacman.txt"
            echo "  --verbose, -v     Show detailed output"
            echo "  --help, -h        Show this help message"
            echo ""
            echo "Bootstrap workflow:"
            echo "  1. ./install.sh           # Install eden wrapper (no dependencies)"
            echo "  2. eden install           # Install platform packages (includes GNU Stow)"
            echo "  3. eden plant             # Plant configs (wraps stow with helpful checks)"
            exit 0
            ;;
        *)
            error "Unknown option: $arg. Use --help for usage."
            ;;
    esac
done

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

# Create Eden directory structure (not stowed, user-specific)
log "Setting up Eden directories..."

# Configs in ~/.config/eden (XDG-compliant)
EDEN_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/eden"
mkdir -p "$EDEN_CONFIG/local"
verbose "✓ Created $EDEN_CONFIG/"

# Store repo path for the wrapper to find
echo "$EDEN_DIR" > "$EDEN_CONFIG/repo"
verbose "✓ Stored repo path: $EDEN_DIR"

# Binaries in ~/.eden/bin (for branch-managed scripts via graft)
# Note: This directory is ONLY for automated branch integration, not manual use
EDEN_BIN="$HOME/.eden/bin"
mkdir -p "$EDEN_BIN"
verbose "✓ Created $EDEN_BIN/ (branch automation only)"

# Install eden wrapper permanently to ~/.local/bin/
log "Installing eden CLI wrapper..."
mkdir -p "$HOME/.local/bin"
cp -f "$EDEN_DIR/eden" "$HOME/.local/bin/eden"
chmod +x "$HOME/.local/bin/eden"
verbose "✓ eden wrapper installed to ~/.local/bin/eden"

# Create branches file with default branch
if [ ! -f "$EDEN_CONFIG/branches" ]; then
    cat > "$EDEN_CONFIG/branches" << EOF
# Eden Branch Registry
# List branch repository paths here (one per line)
# Branches extend Eden with private, context-specific configurations

# Eden's opinionated default branch (comment out to opt out)
\$EDEN_ROOT/branches/default

# Add your private branches below:
# ~/branch-work
# ~/branch-personal
EOF
    verbose "✓ Created $EDEN_CONFIG/branches with default branch"
else
    verbose "✓ $EDEN_CONFIG/branches already exists (not modified)"
fi

# Binary locations:
#   ~/.local/bin/  - Eden core (eden, eden-*) + personal scripts (standard XDG)
#   ~/.eden/bin/   - Branch scripts only (automated via 'eden graft')

# Install packages (optional)
if $INSTALL_PACKAGES; then
    log "Installing packages..."

    if [ "$OS" = "mac" ]; then
        if command -v brew >/dev/null 2>&1; then
            verbose "Running brew bundle..."
            brew bundle --file="$EDEN_DIR/Brewfile" || warn "Some packages failed to install"
        else
            error "Homebrew not found. Install from https://brew.sh/ first."
        fi
    elif [ "$OS" = "arch" ]; then
        # Check for yay (AUR helper) first, as some packages are AUR-only
        if command -v yay >/dev/null 2>&1; then
            verbose "Installing packages with yay (includes AUR)..."
            # Read packages into array, skipping comments and empty lines
            mapfile -t packages < <(grep -v '^#' "$EDEN_DIR/pacman.txt" | grep -v '^$' | tr -d ' ')
            if [ ${#packages[@]} -gt 0 ]; then
                yay -S --needed "${packages[@]}" || warn "Some packages failed to install"
            fi
        elif command -v pacman >/dev/null 2>&1; then
            verbose "Installing packages with pacman (AUR packages will be skipped)..."
            # Read packages into array, skipping comments and empty lines
            mapfile -t packages < <(grep -v '^#' "$EDEN_DIR/pacman.txt" | grep -v '^$' | tr -d ' ')
            if [ ${#packages[@]} -gt 0 ]; then
                sudo pacman -S --needed "${packages[@]}" 2>&1 || true
                warn "Some packages require AUR access. Install yay and re-run with: eden install"
                echo "  Install yay: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
            fi
        else
            error "Neither yay nor pacman found. Are you on Arch Linux?"
        fi
    fi
    verbose "✓ Package installation complete"
fi

# Check PATH (informational only)
PATH_WARNINGS=()
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    PATH_WARNINGS+=("~/.local/bin")
fi
if [[ ":$PATH:" != *":$HOME/.eden/bin:"* ]]; then
    PATH_WARNINGS+=("~/.eden/bin")
fi

if [ ${#PATH_WARNINGS[@]} -gt 0 ]; then
    warn "The following directories are not in your PATH yet:"
    for dir in "${PATH_WARNINGS[@]}"; do
        echo "    • $dir"
    done
    echo "  Eden's shell configuration will add them automatically after you restart your shell"
fi

# Success!
echo ""
log "Eden wrapper installed successfully! 🌳"
echo ""
echo "Next steps:"
echo "  1. Add ~/.local/bin to your PATH (if needed):"
echo "     export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
echo "  2. Install platform packages (includes GNU Stow):"
echo "     eden install"
echo ""
echo "  3. Plant Eden configurations (wraps stow with helpful checks):"
echo "     eden plant"
echo ""
echo "  4. Validate installation:"
echo "     eden doctor"
echo ""
echo "Additional commands:"
echo "  • eden help     - Show all available commands"
echo "  • eden graft    - Integrate branch configurations"
echo "  • eden update   - Update Eden and re-apply configs"
echo ""

