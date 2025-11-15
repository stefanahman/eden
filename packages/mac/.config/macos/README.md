# macOS System Defaults Configuration

Manage your macOS system preferences as code with Eden.

## Commands

```bash
# Generate reference library (browse all available settings)
eden os dump                 # Core system domains
eden os dump --all           # Include third-party apps

# Edit your configuration
eden os edit                 # Creates template if missing

# Apply your configuration
eden os apply                # Load and execute your config

# View current state
eden os show                 # Show current settings
eden os diff                 # Compare vs your config
```

## File Structure

```
.config/macos/
├── defaults-15.sh           # Your curated config (macOS 15)
├── defaults-15-dump.sh      # Reference library (all settings)
├── defaults-16.sh           # Future: macOS 16 config
├── ARCHITECTURE.md          # Architecture and reference
└── README.md                # This file
```

## Workflows

### Setup from Scratch

```bash
# 1. Generate comprehensive reference
eden os dump

# 2. Browse and pick settings
#    - Use grep/LLM to search defaults-15-dump.sh
#    - Ask LLM: "Find keyboard and trackpad settings"

# 3. Edit your config
eden os edit
#    - Copy desired settings from dump
#    - Uncomment the defaults write commands

# 4. Apply
eden os apply
```

### Migrate Existing Mac

```bash
# On current Mac - manually note your settings
eden os show > my-settings.txt
defaults read > my-full-prefs.txt

# Browse dump and recreate
eden os dump
eden os edit                 # Add settings from your notes

# On new Mac
eden os apply
```

### LLM-Assisted Configuration

```bash
# 1. Generate reference
eden os dump

# 2. Upload defaults-15-dump.sh to Claude/ChatGPT and ask:
"I'm a developer who likes:
- Fast keyboard navigation
- Minimal animations
- Tiling window managers
- Efficient workflows

From this macOS defaults dump, suggest 15 settings I should enable.
Show me the exact defaults write commands to copy."

# 3. Copy LLM's suggestions
eden os edit
# Paste commands

# 4. Apply
eden os apply
```

## File Format

All config files are **executable bash scripts**:

```bash
#!/usr/bin/env bash
# Your settings

# Keyboard repeat
defaults write NSGlobalDomain KeyRepeat -int 2

# Dock auto-hide
defaults write com.apple.dock autohide -bool true

# Cleanup
killall Dock 2>/dev/null || true
```

### Reference Dump Format

The dump file includes rich metadata for LLM/search:

```bash
# TrackpadThreeFingerDrag
# Type: bool
# Value: 1
# Keywords: trackpad three finger drag gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerDrag" -bool true
```

## Version Management

Eden uses a **per-version** approach:

- `defaults-15.sh` - macOS 15 (Sequoia) settings
- `defaults-16.sh` - macOS 16 settings (future)

Each file is self-contained. When you upgrade macOS:

```bash
# On new macOS 16
eden os dump                 # Generate new reference
eden os edit                 # Review/update settings
eden os apply                # Apply
```

## Tips

### Search with Keywords

```bash
# Find trackpad settings
grep -i trackpad defaults-15-dump.sh

# Find keyboard shortcuts
grep -i "keyboard\|shortcut\|key.*repeat" defaults-15-dump.sh

# Find animation settings
grep -i "animation\|motion\|transparency" defaults-15-dump.sh
```

### Test Before Applying

Review the generated config before applying:

```bash
cat defaults-15.sh           # Review commands
eden os apply                # Apply (no --dry-run yet)
```

### Selective Application

Comment out settings you don't want:

```bash
# Active (will be applied)
defaults write com.apple.dock autohide -bool true

# Disabled (commented out)
# defaults write com.apple.dock tilesize -int 48
```

## See Also

- `ARCHITECTURE.md` - Architecture, versioning, and popular settings reference
- [macos-defaults.com](https://macos-defaults.com) - Interactive reference
- [github.com/mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) - Popular defaults collection
