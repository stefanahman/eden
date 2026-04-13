# Eden Architecture

Eden is a personal, cross-platform environment manager for Arch Linux and macOS.
Public repo — secrets stay in 1Password, fetched at runtime via `op` CLI.

## Principles

- Simplicity over control
- Portability over perfection
- Transparency over automation
- No secrets in VCS; fetch at runtime via 1Password CLI

This is a personal environment, not a framework. Opinionated by design.

## Three-Layer Stow System

Eden deploys configs via GNU Stow symlinks in three layers:

1. **common** — OS-agnostic dotfiles (git, zsh, neovim, scripts)
2. **platform** (`arch`/`mac`) — OS-specific overlays (window managers, credential helpers)
3. **local** — per-machine overrides via include directives (`~/.config/eden/local/`)

Common is stowed first, then platform overlays. Stow merges directories naturally.

## Repo Layout

```
eden/
├── eden                    # Root wrapper (copies to ~/.local/bin/eden)
├── bin/                    # Core scripts: eden, eden-doctor, eden-graft, eden-update, ...
├── install.sh              # Bootstrap installer (only requires git + stow)
├── packages/
│   ├── common/             # Stows to $HOME — shared dotfiles + scripts
│   ├── eden/               # Stows to $HOME — internal utilities (~/.eden/libexec/)
│   ├── arch/               # Stows to $HOME — Arch Linux overlays
│   └── mac/                # Stows to $HOME — macOS overlays
├── branches/               # Local branch experiments (git-ignored)
├── Brewfile                # macOS packages (brew bundle)
└── pacman.txt              # Arch packages (one per line)
```

## Smart Wrapper Pattern

`~/.local/bin/eden` is a thin wrapper copied during install. It always calls
`bin/eden` from the repo, so `eden` works before/after stow and always runs
latest code. Only `eden uninstall` removes the wrapper.

## Branches

Branches are separate git repos that extend Eden with private/contextual configs.
Eden is the trunk (public); branches are extensions (private, context-specific).

- Register: `eden branch add ~/branch-work`
- Integrate: `eden graft` discovers branches and merges MCP configs, secrets, binaries
- Structure mirrors `$HOME` for consistency

## Pluggable Grafter System

`eden graft` uses pluggable grafters in `packages/eden/.eden/libexec/grafters/` to
integrate branch content. Each grafter handles one concern independently.

| Grafter | What it does |
|---------|-------------|
| `graft-bin` | Symlinks branch binaries into `~/.eden/bin/` |
| `graft-brew` | Runs `brew bundle` on branch Brewfiles (macOS only) |
| `graft-claude` | Symlinks Claude rules, agents, and skills |
| `graft-configs` | Symlinks paths listed in branch `.eden-graft` allowlists |
| `graft-git` | Creates git `includeIf` directives for branch identities |
| `graft-mcp` | Merges MCP server JSON from all branches |
| `graft-secrets` | Collects 1Password secret definitions |
| `graft-zsh` | Symlinks zsh env files into `zshenv.d/` |

Grafters support two scopes:
- **Global**: branch configs merged into `$HOME` (e.g. `~/.config/mcp/servers.json`)
- **Project**: configs placed in external project directories via `.eden-target` markers
  (e.g. `projects/games/greenwash/.mcp/servers.json` → `~/Development/.../greenwash/.mcp.json`)

See [docs/grafters.md](docs/grafters.md) for strategies, patterns, and how to create new grafters.

## Eden CLI Commands

| Command | Purpose |
|---------|---------|
| `eden grow` | Plant configs + run all grafters (the main command) |
| `eden plant` | Apply symlinks (wraps GNU Stow with smart conflict handling) |
| `eden unplant` | Remove Eden symlinks |
| `eden graft [name]` | Run all grafters, or a specific one (e.g., `eden graft git`) |
| `eden graft --list` | Show available grafters |
| `eden install [pkg]` | Install platform packages or specific package (e.g., gcloud) |
| `eden update` | Pull from git and re-apply symlinks |
| `eden branch` | Manage branch registration (add, list, remove, new) |
| `eden secrets` | Manage 1Password secrets across branches |
| `eden doctor` | Validate installation health |
| `eden status` | Show system overview |

## Secret Management

Provider: 1Password CLI (`op`). Secrets are fetched at runtime, never stored in tracked files.

**Forbidden patterns** (must never be committed):
`*.key`, `*.secret`, `*.token`, `.env`, `.env.*`, `.config/env.d/secrets.sh`

## Layering Guidance

| Layer | Use when... |
|-------|-------------|
| **common** | Config works identically on both platforms (git aliases, shell functions, editor settings) |
| **platform** | OS-specific paths, credential helpers, window managers, platform tool syntax |
| **local** | Per-machine overrides: work vs personal email, proxy settings, experimental configs |

## Constraints

- No credentials or secrets in VCS
- User-space overrides only (no modifying system defaults like `~/.local/share/omarchy`)
- All deploys reversible (stow provides this naturally)
- Portable paths: use `$HOME` and XDG locations, no machine-specific absolute paths
- Respect XDG environment variables (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, etc.)

## Dependencies

**Required:** git, GNU Stow >= 2.3
**Optional:** 1Password CLI (`op`), fnm, pnpm

## What Ships Where

**Packages (core, `eden plant`)** -- minimal foundation that works without branches:

| Package | Contents |
|---------|----------|
| `common` | zsh/bash config, git config, starship prompt, editor settings, Claude Code rules |
| `mac` | Ghostty terminal, macOS defaults system, platform shell/git overrides |
| `arch` | Platform shell/git overrides |
| `eden` | Grafters, setup helpers (`node-setup`, `gcloud-setup`) |

**Default branch (opinionated, `eden graft`)** -- practical extras, opt-out by removing from branches file:

| Category | What |
|----------|------|
| MCP servers | GitHub, Context7, Linear (with 1Password wrappers) |
| Editor | Neovim/LazyVim configuration |
| Window management | yabai, skhd, karabiner (macOS) |
| Shell | Claude AFK mode, default tool env vars (Docker, Bat, Volta) |
| Tools | pnpm config, `op-mcp-warmup` helper |

**Personal branches (private, `eden graft`)** -- context-specific extensions:

MCP servers, git identities, secrets, Brewfiles, Claude skills, binaries.
See [docs/branches-and-secrets.md](docs/branches-and-secrets.md).

## Non-Goals

- Not a framework — personal environment, opinionated choices
- No distros beyond Arch Linux
- No OS beyond Arch Linux + macOS
- No automated 1Password authentication
- No automated package installation (user runs from lists)
