# Eden Default Branch

This is Eden's opinionated default branch. It contains curated configurations and integrations that extend Eden's minimal core with practical everyday tools.

## Purpose

- **Eden packages** (`packages/common`, `packages/arch`, `packages/mac`) provide minimal, cross-platform foundations
- **Default branch** (`branches/default`) adds opinionated extras that most users want but aren't essential to core functionality
- **Personal branches** (e.g., `~/branch-work`, `~/branch-personal`) add private, context-specific configurations

## What's Included

### MCP (Model Context Protocol) Servers
- **GitHub integration**: Allows AI assistants to interact with GitHub repositories
- Secured with 1Password integration (token requirement in `.eden-secrets`)
- Works with Cursor, Claude Desktop, and other MCP clients

### Neovim Configuration
- **LazyVim**: Opinionated Neovim distribution
- Modern IDE-like features out of the box
- Plugin management, LSP, treesitter, telescope
- Custom theme and transparency settings

### pnpm Configuration
- XDG-compliant directory structure
- Auto-install peers for less friction
- Optimized for Node.js development workflow

### Future Additions
As Eden grows, more opinionated defaults may be added here:
- Additional MCP servers
- Development tool configurations
- Productivity scripts

## Opting Out

Don't want the defaults? You can opt out in two ways:

### 1. Comment out the default branch
Edit `~/.config/eden/branches`:
```bash
# Comment out this line to disable default branch:
# $EDEN_ROOT/branches/default
```

Then run `eden graft` to remove grafted configs.

### 2. Override in your personal branch
Your personal branches (listed after the default in `~/.config/eden/branches`) can override any defaults. Order matters - later branches win for conflicts.

## Philosophy

The default branch keeps Eden core minimal while providing a good out-of-box experience. It's versioned with Eden, so updates come automatically with `eden update`.

If you fork Eden, you can customize this branch or remove it entirely. It's just another branch in the grafting system.

