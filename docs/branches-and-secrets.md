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
**Example branch**: A functional starter template that demonstrates each grafter (auto-loaded on fresh install, auto-deactivated when you register your own)
**Personal branches**: Private extensions for specific contexts (work, personal, clients)

### Two Layers + a Starter

1. **Eden Packages** (`packages/`) -- Minimal core, deployed via `eden plant` (stow)
2. **Branches** -- Your real configs, grafted via `eden graft`
   - `branches/example` -- starter template; safe to graft as-is to see Eden working. Auto-deactivated by `eden branch add` when you register your own.
   - Personal branches (e.g., `~/eden-private-branches/work`) -- where your real configs live

## Managing Branches

These register branches one by one in `~/.config/eden/branches`. With
[gardens](#gardens) set up, the same commands edit the repo's
`.eden-gardens` instead.

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
│   ├── git/identities/work    # Git identity, for its remotes (graft-git)
│   ├── eden/env.d/work.sh     # Env vars, POSIX sh, for bash and zsh (graft-env)
│   └── zsh/zshenv.d/work.zsh  # zsh-only env (collected by graft-zsh)
├── .local/bin/                # Scripts/wrappers (collected by graft-bin)
│   ├── mcp-slack
│   └── mcp-custom
├── .claude/
│   ├── rules/                 # Claude rules (collected by graft-claude)
│   └── skills/                # Claude skills
├── projects/                  # Project-scoped configs
│   └── my-app/
│       ├── .eden-target       # Contains: ~/Development/my-app
│       ├── .claude/skills/    # Symlinked into the project
│       └── .mcp/servers.json  # Claude Code's local scope for the project
└── platforms/                 # Parts for one platform only
    ├── mac/                   # Grafted on macOS, right after the branch
    │   ├── .eden-graft
    │   └── .local/bin/open-browser
    └── arch/                  # Grafted on Arch Linux
        └── .eden-graft
```

Grafters discover and merge content from each path. See [grafters.md](grafters.md) for which grafter handles what.

### Environment

Env files in a branch's `.config/eden/env.d/*.sh` are POSIX sh, grafted
into `~/.config/eden/env.d/` by `graft-env`, and loaded by both shells:
zsh from `.zshenv`, bash from `~/.config/bash/env`, which bash login
shells source through the trunk's profile. Interactive bash reads only
`~/.bashrc`, which Eden does not own, so it needs one line there:

```sh
. ~/.config/bash/env
```

`eden doctor` checks for it where bash is the login shell. Keep env files
to exports that can run twice; zsh-only settings stay in
`.config/zsh/zshenv.d/*.zsh`.

### Platform folders

A branch that is used on more than one platform keeps its platform-only
parts in `platforms/<platform>/`, named as the trunk's platform packages
are: `mac` and `arch`. Each folder mirrors `$HOME` like the branch itself,
with its own `.eden-graft`, `.local/bin/` and so on, and is grafted right
after its branch on that platform only. Nothing else marks an entry as
platform-only, so every grafter gates it the same way. A platform folder
and its branch writing the same target collide like two branches.

`eden branch list` shows a branch's platform folders and which one this
machine grafts. `EDEN_PLATFORM=mac` or `arch` overrides the detection.

## Secrets Integration

### The `.eden-secrets` File

Each branch defines its 1Password requirements in `.eden-secrets`:

```ini
[secret]
id=slack-bot-token
name=Slack Bot Token
path=op://Employee/slack-bot-token/credential
description=Slack Bot User OAuth Token for workspace messaging
required_by=mcp-slack
op_account=example-corp.1password.com
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
| `op_account` | Optional | 1Password account the secret lives in; passed to the fetch as `op read --account`, or to another provider as `EDEN_SECRET_ACCOUNT` (without it, `op` picks its default account) |
| `setup_command` | Optional | Command to help set up the secret |

### Commands

```bash
# List all secrets from trunk + all branches
eden secrets list

# Validate secrets exist in 1Password
eden secrets validate

# Look up a specific secret by id
eden secrets lookup slack-bot-token
eden secrets lookup slack-bot-token path        # Just the op:// path
eden secrets lookup slack-bot-token op_account   # Just the account domain
```

### How MCP Wrappers Use Secrets

MCP wrapper scripts in `.local/bin/` fetch secrets at runtime via 1Password CLI. See [1password-setup.md](1password-setup.md) for the wrapper pattern.

## Gardens

A **garden** is a named group of one or more branches that make up one
area of life — its accounts, git remotes and tools: `work` for Example
Corp, `personal` for John Doe. A machine grows one or more gardens, and
shows one at a time, the **garden in view**. A branch in no garden is
**shared**: grafted in every garden.

### Declaring them

The repo that holds your branches declares its gardens in one file at
its root, `.eden-gardens`:

```ini
[shared]
common
mac-desktop    mac
linux-desktop  arch

[work]
work

[personal]
personal
```

Each section is a garden, except `[shared]`. Each line is a branch
folder relative to the file, optionally followed by the one platform it
is grafted on (`mac` or `arch`). Blank lines and `#` lines are skipped;
a line before any section is not read. A branch belongs to one section.

The file is yours and tracked with your branches; the commands below
edit it, or edit it by hand and commit it:

```bash
eden garden new school                        # an empty [school]
eden branch new branches/chess --garden school  # create a branch, list it under [school]
eden branch add branches/tools --shared --platform mac
eden branch move chess --garden personal      # to another garden, platform kept
eden branch remove chess                      # delist; the folder stays
eden branch list                              # each garden's branches, ✓ where grafted here
```

### Setting up a machine

```bash
eden init ~/eden-branches --garden personal   # or: eden init ~/eden-branches, and pick
```

`eden init <repo>` records the repo in `~/.config/eden/branches-repo`, grows the
gardens named with `--garden` (at a terminal it asks which), grafts, and
puts the first in view; `--no-graft` stops before grafting. The machine
keeps its own choices, untracked:

| What | Where |
|---|---|
| Where the repo is | `~/.config/eden/branches-repo` |
| The gardens this machine grows | `~/.config/eden/gardens` |
| The garden in view | `~/.local/state/eden/garden` |

From then on `eden graft` works out the branch list on every run: the
shared branches for this platform, then each grown garden's branches,
in the order `.eden-gardens` gives them. `~/.config/eden/branches` is not
read while gardens are set up. A garden that gains a branch needs one
edit to `.eden-gardens`, then `eden graft` on each machine — `eden
update` fast-forwards the repo first.

### Growing and switching

```bash
eden garden list           # what the file declares, and the state of each here
eden garden add work       # grow it here, then: eden graft
eden garden remove work    # stop growing it; what it grafted stays (eden doctor reports it)
eden garden use work       # put it in view
eden garden                # the garden in view
eden garden branches       # for scripts: <garden or shared> TAB <path> TAB <platform>
```

`eden garden use` records the garden and runs every executable in
`~/.config/eden/garden.d/`, in name order, with the garden as its
argument. A branch grafts its own hook there for what a switch changes
beyond what reads the state itself: a link to the garden's config for
some tool, a window manager reload. A hook that fails is reported and
the rest still run.

Last, `use` re-runs the MCP grafter. MCP servers come in three layers:

| Declared in | In Claude Code | Applies |
|---|---|---|
| a shared branch's `.config/mcp/servers.json` | user scope | always |
| a garden branch's `.config/mcp/servers.json` | user scope | while its garden is in view |
| `projects/<repo>/.mcp/servers.json` | that repo's local scope | in the repo, for every grown garden |

A switch takes the previous garden's servers out of user scope and puts
the new one's in. A Claude Code already running keeps the servers it
started with. Two gardens may declare the same server name, since they
are never in user scope together.

`eden doctor` checks the file against the repo and the machine: a branch
the file does not list, a listed folder that is missing or not a branch,
a branch listed twice, an unknown platform, and a machine that grows no
garden, has none in view, or still has a branches file.

## Without gardens

A machine can register its branches one by one instead:

| Machine | Setup | What it adds |
|---------|-------|-------------|
| Work laptop | Eden + branch-work | Company MCP servers, git identity, VPN, Slack, brew packages |
| Personal laptop | Eden + branch-personal | Personal API keys, home server access |

The example branch deactivates automatically when you run `eden branch add` for any other branch. To remove it manually, comment out or delete the `$EDEN_ROOT/branches/example` line in `~/.config/eden/branches`.

## Philosophy

- **Packages** are the foundation everyone needs (shell, git, editor basics)
- **Example branch** is a functional starter that demonstrates each grafter (replace, don't extend)
- **Personal branches** are where your real configs live (your private repos)
- **Secrets** are declared in `.eden-secrets`, fetched at runtime via `EDEN_SECRET_GET` (default: `op read` for 1Password)
