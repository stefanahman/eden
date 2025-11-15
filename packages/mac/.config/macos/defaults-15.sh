#!/usr/bin/env bash
# macOS Defaults Configuration
# 
# Generated: Template for macOS 15 (Sequoia)
# macOS Version: 15
#
# WORKFLOW:
#   1. Browse the reference: defaults-15-dump.sh (or run: eden os dump)
#   2. Copy settings you want here
#   3. Uncomment the defaults write commands
#   4. Apply: eden os apply
#
# TIP: Ask an LLM to search defaults-15-dump.sh:
#   "Find settings related to keyboard shortcuts, animations, and trackpad"

set -euo pipefail

echo "Applying macOS defaults..."
echo ""

# ============================================================================
# Your Custom Settings
# ============================================================================

# Copy settings from defaults-15-dump.sh and uncomment them here.

# Example: Fast keyboard repeat
# defaults write NSGlobalDomain KeyRepeat -int 2 2>/dev/null || true
# defaults write NSGlobalDomain InitialKeyRepeat -int 15 2>/dev/null || true

# Example: Dock auto-hide
# defaults write com.apple.dock autohide -bool true 2>/dev/null || true

# Example: Show hidden files
# defaults write com.apple.finder AppleShowAllFiles -bool true 2>/dev/null || true


# ============================================================================
# Restart Applications
# ============================================================================

echo ""
echo "Restarting affected applications..."
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo ""
echo "✓ macOS defaults applied successfully!"
echo ""
