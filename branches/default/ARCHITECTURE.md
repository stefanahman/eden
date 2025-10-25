# Default Branch Architecture

## Overview

The default branch is Eden's solution to the tension between keeping the core minimal and providing a good out-of-box experience.

## Three-Layer Design

```
┌─────────────────────────────────────────────────┐
│ Layer 3: Personal Branches (Private)           │
│ ~/branch-work, ~/branch-personal                │
│ • Work VPN configs, company git settings        │
│ • Personal experiments, beta tools              │
│ • Deployed: Grafted (merged intelligently)      │
└─────────────────────────────────────────────────┘
                     ↓ overrides
┌─────────────────────────────────────────────────┐
│ Layer 2: Default Branch (Opinionated)          │
│ $EDEN_ROOT/branches/default                     │
│ • MCP server integrations (GitHub)              │
│ • Common dev tool configurations                │
│ • Deployed: Grafted (merged intelligently)      │
└─────────────────────────────────────────────────┘
                     ↓ extends
┌─────────────────────────────────────────────────┐
│ Layer 1: Eden Packages (Minimal Core)          │
│ packages/common, packages/arch, packages/mac    │
│ • Shell configuration (zsh, bash)               │
│ • Editor config (neovim)                        │
│ • Git base config                               │
│ • Deployed: Stowed (symlinked)                  │
└─────────────────────────────────────────────────┘
```

## Why Three Layers?

### Layer 1: Packages (Stowed)
**Purpose**: Universal foundations everyone needs  
**Deployment**: `eden plant` (uses GNU Stow)  
**Versioning**: Git repository (Eden core)  
**Examples**: `.zshrc`, `.gitconfig`, `.config/nvim/`

**Why stow?**: One-to-one file mapping. Each file has one source. Perfect for base configurations.

### Layer 2: Default Branch (Grafted)
**Purpose**: Practical extras most users want  
**Deployment**: `eden graft` (intelligent merging)  
**Versioning**: Git repository (Eden core, in `branches/default`)  
**Examples**: MCP servers, common integrations

**Why graft?**: Multiple sources contribute. MCP servers from default + work + personal all merge into one `servers.json`. This is the key insight - grafters enable **composition**.

### Layer 3: Personal Branches (Grafted)
**Purpose**: Private, context-specific configs  
**Deployment**: `eden graft` (intelligent merging)  
**Versioning**: Separate private git repositories  
**Examples**: Work email, company VPN, personal API keys

**Why separate repos?**: Keep private configs private. Share Eden publicly without exposing personal details.

## Grafter System

Grafters are specialized mergers, each knowing how to combine configs from multiple branches:

### graft-mcp (Merge Strategy)
Combines JSON objects by key:
```json
// default branch
{"github-eden": {...}}

// work branch  
{"gitlab-company": {...}}

// Result: Both servers available
{"github-eden": {...}, "gitlab-company": {...}}
```

### graft-bin (Overwrite Strategy)
Creates symlinks, last branch wins:
```bash
# default: provides 'common-script'
# work: provides 'work-deploy'
# personal: provides 'personal-backup'
# Result: All three in ~/.eden/bin/
```

### graft-git (Append Strategy)
Adds includeIf directives:
```gitconfig
# Routes to branch-specific configs based on directory
[includeIf "gitdir:~/Development/work/"]
    path = ~/.config/eden/local/gitconfig.work
```

## Variable Expansion

The branches file (`~/.config/eden/branches`) supports variables:

```bash
# $EDEN_ROOT expands to Eden repository location
$EDEN_ROOT/branches/default

# ~ expands to home directory
~/branch-work
~/branch-personal
```

This makes the default branch portable - Eden can be cloned anywhere.

## Opting Out

Don't want the defaults? Comment out one line:

```bash
# $EDEN_ROOT/branches/default
```

Then run `eden graft` to remove grafted configs.

## Benefits

1. **Minimal Core**: Eden packages stay lean
2. **Good Defaults**: Most users get MCP, integrations out-of-box
3. **Easy Opt-Out**: One line to disable
4. **Composable**: Multiple branches merge intelligently
5. **Portable**: `$EDEN_ROOT` works regardless of Eden location
6. **Versioned**: Default branch updates with `eden update`

## Design Philosophy

> "Make the common case easy, the advanced case possible."

- **Common case**: Most users want MCP, integrations → default branch provides them
- **Advanced case**: Some users want different configs → easy to opt out or override
- **Expert case**: Power users add personal branches → grafters compose everything

The default branch is just another branch. It's first in the list, versioned with Eden, and provides good defaults. But it's not special - it follows the same rules as any personal branch.

