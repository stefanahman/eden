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

`eden graft` uses pluggable grafters in `bin/grafters/` to integrate branch content:
MCP configs, secrets, binaries. Each grafter handles one concern independently.

## Eden CLI Commands

| Command | Purpose |
|---------|---------|
| `eden install [pkg]` | Install platform packages or specific package (e.g., gcloud) |
| `eden plant` | Apply symlinks (wraps GNU Stow with checks) |
| `eden update` | Pull from git and re-apply symlinks |
| `eden graft` | Discover and integrate branch configs |
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

## AI Integration

MCP servers configured via `eden graft` with 1Password for tokens.
Branch repos can provide MCP server configs in `.config/mcp/servers.json`.

## Non-Goals

- Not a framework — personal environment, opinionated choices
- No distros beyond Arch Linux
- No OS beyond Arch Linux + macOS
- No automated 1Password authentication
- No automated package installation (user runs from lists)
