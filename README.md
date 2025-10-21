# Eden

Eden is a personal computing environment that travels across machines.

It holds configurations, small tools, and organizational patterns that enable coherent work on Arch Linux and macOS. The structure is simple: shared foundations in `common`, platform-specific adaptations in `arch` and `mac`, and symlink-based deployment via GNU Stow.

## Purpose

Computing should feel continuous. Eden reduces the friction of switching between machines by maintaining a single source of truth for configurations while respecting platform differences where they matter.

This is not a framework or a distribution. It is a working environment, shaped by daily use and refined over time.

## Installation

```bash
# Clone Eden
git clone <your-eden-repo> ~/eden
cd ~/eden

# Install (symlink configs only)
./install.sh

# Or install with packages
./install.sh --packages

# Validate installation
./doctor.sh
```

Install packages manually anytime:
```bash
# macOS
brew bundle

# Arch Linux
sudo pacman -S --needed $(cat pacman.txt)
```

## Structure

- **common**: Cross-platform configurations
- **arch**: Arch Linux overlays (Hyprland, Omarchy)
- **mac**: macOS overlays (yabai, skhd)

Configurations are symlinked into `$HOME`. Platform-specific differences layer cleanly over shared foundations. Local machine overrides live in `~/.config/eden/` (XDG-compliant), while Eden binaries are managed in `~/.eden/bin/` (like cargo, volta, fnm).

## Philosophy

Eden favors simplicity over control, portability over perfection, and transparency over automation. Secrets are fetched at runtime via 1Password CLI, never committed to version control.

This repository is public to share structure and philosophy. It reflects personal preferences, not universal best practices.

## Growth

Eden adapts. Configurations are added as needs arise, refined through use, and occasionally pruned. The goal is not completeness but coherence.

## License

MIT
