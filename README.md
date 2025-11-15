# Eden

Eden is a personal computing environment that travels across machines.

It holds configurations, small tools, and organizational patterns that enable coherent work on Arch Linux and macOS. The structure is simple: shared foundations in `common`, platform-specific adaptations in `arch` and `mac`, and symlink-based deployment using GNU Stow (wrapped in Eden's `plant` command for ease of use).

## Purpose

Computing should feel continuous. Eden reduces the friction of switching between machines by maintaining a single source of truth for configurations while respecting platform differences where they matter.

This is not a framework or a distribution. It is a working environment, shaped by daily use and refined over time.

## Installation

```bash
# Clone Eden
git clone <your-eden-repo> ~/eden
cd ~/eden

# Bootstrap: Install eden wrapper (no dependencies required)
./install.sh

# Install platform packages (includes stow)
eden install

# Plant configurations into your system
eden plant

# Graft branch configurations (after plant)
eden graft

# Validate installation
eden doctor
```

Eden grows in stages: first the command wrapper, then tools and packages, then configuration planting, then branch integration. This sequence requires only git at the start.

## Structure

Eden has three layers:

1. **Packages** (`common`, `arch`, `mac`) - Minimal, cross-platform core
2. **Default branch** (`branches/default`) - Opinionated extras (MCP servers, integrations)
3. **Personal branches** (optional) - Private, context-specific extensions

### Two Deployment Methods

**Planting** (`eden plant` - runs first):
- Uses GNU Stow to symlink Eden packages into `$HOME`
- One-to-one file mapping: each file has one source
- Installs the base configurations everyone needs
- Example: `~/.zshrc` → `eden/packages/common/.zshrc`

**Grafting** (`eden graft` - runs after plant):
- Intelligently merges configurations from multiple branches
- Multiple sources contribute to shared configs
- Enables composable, context-specific extensions
- Example: Work and personal branches both add MCP servers → merged into one `~/.config/mcp/servers.json`

The commands work together: `eden plant` installs the base system and grafter tools, then `eden graft` uses those tools to merge branch configurations. Personal branches can add binaries, environment variables, and configs without conflicts.

Local machine overrides live in `~/.config/eden/` (XDG-compliant), while Eden binaries are managed in `~/.eden/bin/` (like cargo, volta, fnm).

## Philosophy

Eden favors simplicity over control, portability over perfection, and transparency over automation. Secrets are fetched at runtime via 1Password CLI, never committed to version control.

This repository is public to share structure and philosophy. It reflects personal preferences, not universal best practices.

## Growth

Eden adapts. Configurations are added as needs arise, refined through use, and occasionally pruned. The goal is not completeness but coherence.

## License

MIT
