# macOS Defaults Architecture

## Overview

Eden manages macOS system preferences as **executable bash scripts** - one per macOS major version.

## Architecture

### File Structure

```
.config/macos/
├── defaults-15.sh          # macOS 15 config (executable)
├── defaults-15-dump.sh     # Reference library (all available settings)
├── defaults-16.sh          # macOS 16 config (future)
└── README.md               # User documentation
```

### Key Principles

1. **Standalone per version** - Each file is self-contained
2. **Executable scripts** - Direct `defaults write` commands
3. **Fail gracefully** - Settings use `|| true` for forward compatibility
4. **LLM-friendly dumps** - Rich metadata for search/discovery

## Version Strategy

### One File Per macOS Version

Each macOS major version has its own config:
- `defaults-15.sh` for macOS 15 (Sequoia)
- `defaults-16.sh` for macOS 16 (future)

**No inheritance or loading chain** - each file is complete and independent.

### When Upgrading macOS

```bash
# On macOS 16 (future)
eden os dump           # Generate new reference for macOS 16
eden os edit           # Review/adjust settings
eden os apply          # Apply
```

Old version files remain for reference but aren't loaded.

## File Format

### Config Files (defaults-N.sh)

Executable bash scripts with direct `defaults write` commands:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Applying macOS defaults..."

# Keyboard
defaults write NSGlobalDomain KeyRepeat -int 2 2>/dev/null || true

# Dock
defaults write com.apple.dock autohide -bool true 2>/dev/null || true

# Cleanup
killall Dock 2>/dev/null || true
```

**Key features:**
- `2>/dev/null || true` - Fail silently if setting doesn't exist
- Direct execution - No variable interpolation needed
- Self-documenting - Comments explain each setting

### Reference Dumps (defaults-N-dump.sh)

All discoverable settings with rich metadata:

```bash
# TrackpadThreeFingerDrag
# Type: bool
# Value: 1
# Keywords: trackpad three finger drag gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerDrag" -bool true
```

**All commands commented out** - this is a reference, not a config.

## Comparison to Old Architecture

### Old System (Deprecated)

```
defaults-common.sh      # Variables: KEYBOARD_REPEAT=2
defaults-15.sh          # Overrides: KEYBOARD_REPEAT=1
macos-defaults-apply    # Reads variables, runs defaults write
```

**Problems:**
- Variables separated from commands
- Complex loading chain (common → 15 → 16)
- Deprecation tracking required
- Not directly executable

### New System

```
defaults-15.sh          # Executable script with defaults write commands
macos-defaults-apply    # Just runs the script
```

**Benefits:**
- Self-contained and executable
- No inheritance complexity
- Graceful degradation (`|| true`)
- Copy-paste friendly
- LLM-searchable dumps

## Forward Compatibility

Settings that don't exist fail silently:

```bash
# This setting might not exist on all Macs
defaults write com.apple.future NewFeature -bool true 2>/dev/null || true
# Script continues regardless
```

This means:
- ✅ Configs work across minor versions (15.0 → 15.7)
- ✅ Safe to share between similar Macs
- ✅ No explicit deprecation tracking needed

## Commands

```bash
eden os dump     # Generate reference (all settings)
eden os edit     # Edit your config
eden os apply    # Execute your config
eden os show     # View current system state
eden os diff     # Compare current vs config
```

## Workflow

### Setup New Mac

```bash
eden os dump            # Browse all options
eden os edit            # Pick what you want
eden os apply           # Apply
```

### Migrate Existing Mac

```bash
# On existing Mac - manually export settings you want
eden os show > my-current-settings.txt

# Browse dump file and recreate in config
eden os dump
eden os edit            # Add desired settings

# On new Mac
eden os apply
```

### LLM-Assisted

```bash
eden os dump

# Upload dump to LLM:
"Find keyboard, trackpad, and dock settings for a developer"

# Copy suggestions
eden os edit            # Paste
eden os apply           # Apply
```

## Evolution

As macOS evolves:

1. **New settings appear** → Show up in `eden os dump`
2. **Settings deprecated** → Fail silently with `|| true`
3. **APIs change** → Create new version file

No manual deprecation tracking needed!

## Reference: Key Domains & Discovery

### Key Preference Domains

**Core System:**
- `NSGlobalDomain` - Global system settings (keyboard, locale, etc.)
- `com.apple.finder` - Finder preferences
- `com.apple.dock` - Dock behavior and appearance
- `com.apple.screencapture` - Screenshot settings
- `com.apple.screensaver` - Screen saver and lock screen
- `com.apple.Accessibility` - Accessibility features
- `com.apple.menuextra.*` - Menu bar items

**Input Devices:**
- `com.apple.AppleMultitouchTrackpad` - Trackpad gestures
- `com.apple.driver.AppleBluetoothMultitouch*` - Bluetooth trackpad/mouse

**System Preferences:**
- `com.apple.loginwindow` - Login and lock screen
- `com.apple.systempreferences` - System Preferences app
- `com.apple.LaunchServices` - File associations
- `com.apple.TimeMachine` - Backup settings

### Discovery Commands

```bash
# List all domains
defaults domains

# Explore a domain
defaults read com.apple.finder
defaults read NSGlobalDomain | grep -i keyboard

# Search for specific settings
defaults find Dock
defaults read com.apple.dock | grep -i autohide
```

### External Resources

- [macos-defaults.com](https://macos-defaults.com) - Interactive catalog with visual examples
- [github.com/mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - Famous collection
- [defaults-write.com](https://defaults-write.com) - Community-curated database

## See Also

- `README.md` - User guide and workflows
