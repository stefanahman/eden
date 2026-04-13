# Eden Branches and Secrets

## Overview

Eden supports **branches** -- separate git repositories that extend Eden with private, context-specific configurations. Each branch can define its own secrets in a `.eden-secrets` file.

## Branch Concept

```
Eden packages        Default Branch       Personal Branches
(minimal core)       (opinionated)        (private contexts)
├── common/          ├── .config/         ├── .eden-secrets
├── arch/            │   ├── mcp/         ├── .config/
├── mac/             │   ├── nvim/        ├── .local/bin/
└── eden/            │   └── zsh/         ├── Brewfile
                     ├── .local/bin/      └── projects/
                     ├── .eden-secrets
                     └── .eden-graft
```

**Eden packages**: Minimal, cross-platform foundations (stowed via `eden plant`)
**Default branch**: Opinionated extras shipped with Eden (MCP servers, neovim, window management)
**Personal branches**: Private extensions for specific contexts (work, personal, clients)

### Three Layers

1. **Eden Packages** (`packages/`) -- Minimal core, deployed via `eden plant` (stow)
2. **Default Branch** (`branches/default`) -- Opinionated defaults, grafted automatically
3. **Personal Branches** (e.g., `~/eden-private-branches/work`) -- Your private configs, grafted on demand

## Managing Branches

### Register a Branch

```bash
eden branch add ~/eden-private-branches/work
```

### Create a New Branch

```bash
eden branch new ~/eden-private-branches/personal
```

This scaffolds the branch directory structure and registers it.

### List Branches

```bash
eden branch list
```

Shows all registered branches with their secret counts and MCP config status.

### Remove a Branch

```bash
eden branch remove ~/eden-private-branches/work
```

## Branch Structure

Branches mirror `$HOME` for consistency. Place files where they would live under `$HOME`:

```
my-branch/
├── .eden-secrets              # 1Password secret definitions
├── .eden-graft                # Allowlist for graft-configs
├── Brewfile                   # Branch-specific brew packages (macOS)
├── .config/
│   ├── mcp/servers.json       # MCP servers (merged by graft-mcp)
│   ├── git/identities/work    # Git identity (routed by graft-git)
│   └── zsh/zshenv.d/work.zsh  # Env vars (collected by graft-zsh)
├── .local/bin/                # Scripts/wrappers (collected by graft-bin)
│   ├── mcp-slack
│   └── mcp-custom
├── .claude/
│   ├── rules/                 # Claude rules (collected by graft-claude)
│   └── skills/                # Claude skills
└── projects/                  # Project-scoped configs
    └── my-app/
        ├── .eden-target       # Contains: ~/Development/my-app
        ├── .claude/skills/    # Symlinked into the project
        └── .mcp/servers.json  # Generated as .mcp.json in the project
```

Grafters discover and merge content from each path. See [grafters.md](grafters.md) for which grafter handles what.

## Secrets Integration

### The `.eden-secrets` File

Each branch defines its 1Password requirements in `.eden-secrets`:

```ini
[secret]
id=slack-mcp-bot-token
name=Slack MCP Bot Token
path=op://Employee/slack-mcp-bot-token/credential
description=Slack Bot User OAuth Token for workspace messaging
required_by=mcp-slack
op_account=bardotechnology.1password.eu
setup_command=echo "Create app at https://api.slack.com/apps"
```

**Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `id` | Optional | Lookup key for `eden secrets lookup <id>` |
| `name` | Required | Human-readable name |
| `path` | Required | 1Password `op://` reference |
| `description` | Required | What this secret is for |
| `required_by` | Optional | What uses this secret |
| `op_account` | Optional | 1Password account domain (defaults to primary) |
| `setup_command` | Optional | Command to help set up the secret |

### Commands

```bash
# List all secrets from trunk + all branches
eden secrets list

# Validate secrets exist in 1Password
eden secrets validate

# Look up a specific secret by id
eden secrets lookup slack-mcp-bot-token
eden secrets lookup slack-mcp-bot-token path        # Just the op:// path
eden secrets lookup slack-mcp-bot-token op_account   # Just the account domain
```

### How MCP Wrappers Use Secrets

MCP wrapper scripts in `.local/bin/` fetch secrets at runtime via 1Password CLI. See [1password-setup.md](1password-setup.md) for the wrapper pattern.

## Context Switching

Branches enable clean context separation:

| Context | Setup | What it adds |
|---------|-------|-------------|
| Work laptop | Eden + branch-work | Company MCP servers, git identity, VPN, Slack, brew packages |
| Personal laptop | Eden + branch-personal | Personal API keys, home server access |
| Client machine | Eden + branch-client | Client-specific tokens and configs |

Opt out of defaults by removing `$EDEN_ROOT/branches/default` from `~/.config/eden/branches`.

## Philosophy

- **Packages** are the foundation everyone needs (shell, git, editor basics)
- **Default branch** has practical extras most users want (MCP servers, neovim, window management)
- **Personal branches** add your private, context-specific configs
- **Secrets** are centralized in 1Password, documented in `.eden-secrets`, fetched at runtime
