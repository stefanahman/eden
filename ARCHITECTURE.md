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
├── lib/                    # Shell libraries sourced by bin/ and grafters (branches.sh, collisions.sh)
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

- Register: `eden branch add ~/branch-work`, or declare gardens (below)
- Integrate: `eden graft` discovers branches and merges MCP configs, secrets, binaries
- Structure mirrors `$HOME` for consistency

**Gardens** group branches into areas of life (work, personal). The
repo holding the branches declares them in `.eden-gardens`; each machine
runs `eden init <repo>`, grows some of the gardens, and puts one in view
(`eden garden use`). The branch list is then worked out on every graft —
the shared branches, then the grown gardens' — and the branches file is
not read. See docs/branches-and-secrets.md, "Gardens".

## Pluggable Grafter System

`eden graft` uses pluggable grafters in `packages/eden/.eden/libexec/grafters/` to
integrate branch content. Each grafter handles one concern independently.

| Grafter | What it does |
|---------|-------------|
| `graft-bin` | Symlinks branch binaries into `~/.eden/bin/` |
| `graft-brew` | Runs `brew bundle` on branch Brewfiles (macOS only) |
| `graft-claude` | Symlinks Claude rules, agents, commands, output styles, skills, `settings.json`, `statusline.sh`, `CLAUDE.md` and `*.local.md` |
| `graft-configs` | Symlinks paths listed in branch `.eden-graft` allowlists |
| `graft-env` | Symlinks POSIX sh env files into `~/.config/eden/env.d/`, loaded by bash and zsh |
| `graft-git` | Creates git `includeIf` directives for branch identities |
| `graft-mcp` | Merges MCP server JSON from all branches |
| `graft-mise` | Installs the tools branches' mise configs declare (`mise install`) |
| `graft-secrets` | Collects 1Password secret definitions |
| `graft-zsh` | Symlinks zsh env files into `zshenv.d/` |

Grafters support two scopes:
- **Global**: branch configs merged into `$HOME` (e.g. `~/.config/mcp/servers.json`)
- **Project**: configs for one repo, found through `.eden-target` markers
  (e.g. `projects/games/my-game/.mcp/servers.json` → Claude Code's local scope for
  `~/Development/games/my-game`)

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
| `eden init [<repo>]` | First-run setup; with a repo that has `.eden-gardens`, grows its gardens and grafts |
| `eden update` | Pull from git and re-apply symlinks; fast-forwards the gardens' repo |
| `eden branch` | Manage branches (add, list, remove, new; move with gardens) |
| `eden garden` | Gardens grown here and the one in view (list, add, remove, use, new) |
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
- Planting is reversible (`eden unplant`, via stow); grafting does not yet remove what a branch left behind when it is unregistered
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

**Example branch (`branches/example`)** -- starter template, not auto-loaded:

A minimal but functional branch demonstrating each grafter (configs, mcp, zsh, git, claude, bin, brew, secrets). Fork into your own private branches repo and replace placeholders with real content, or uncomment in `~/.config/eden/branches` to graft as-is.

**Personal branches (private, `eden graft`)** -- where your real configs live:

Git identity (`_default`, plus identities scoped by remote or directory), MCP servers, secrets, Brewfiles, Claude skills, binaries.
See [docs/branches-and-secrets.md](docs/branches-and-secrets.md).

## Non-Goals

- Not a framework — personal environment, opinionated choices
- No distros beyond Arch Linux
- No OS beyond Arch Linux + macOS
- No automated 1Password authentication
- No implicit installation of trunk packages: `eden install` runs the lists when asked (branch Brewfiles are the exception: `graft-brew` applies them on macOS during `eden graft`)
