# Eden Grafters Guide

## Overview

Grafters are pluggable scripts that intelligently merge configurations from multiple branches. Each grafter uses a specific **strategy** to handle conflicts and combine sources.

## Config Deployment: `.eden-graft` vs Dedicated Grafters

Most branch configs are deployed via the **`.eden-graft` allowlist** — a simple file listing paths that `graft-configs` should symlink to `$HOME`. This covers configs that don't need multi-branch merging (editor settings, window managers, etc.).

**Dedicated grafters** exist for configs where multiple branches contribute to the same logical output and need intelligent merging, routing, or aggregation.

### Decision: `.eden-graft` entry vs dedicated grafter

| Use `.eden-graft` when... | Create a grafter when... |
|---|---|
| Only one branch provides the config | Multiple branches contribute to the same file |
| Simple symlink is sufficient | Configs need merging, routing, or conflict detection |
| Examples: karabiner, nvim, skhd | Examples: MCP servers, git identities, shell env |

### How `graft-configs` works

1. Reads `~/.config/eden/branches` to find registered branches
2. For each branch, reads its `.eden-graft` file (an allowlist of paths)
3. Symlinks each listed path from the branch into `$HOME` (directories via `stow`, files via `ln -sf`)
4. Paths not in `.eden-graft` are **not deployed** — this is intentional to prevent accidental grafting

### The `.eden-graft` file

Located at the root of each branch (e.g., `branches/default/.eden-graft`). Format:

```
# Comments and blank lines are ignored
.config/karabiner/karabiner.json
.config/nvim
.config/pnpm/rc
```

The file also documents which paths are auto-handled by dedicated grafters (so you know what NOT to list). `eden doctor` warns about configs that exist in a branch but aren't covered by either mechanism.

## When to Create a Grafter

Create a grafter when branches need to contribute to the same logical configuration:

✅ **Create a grafter if:**
- Multiple branches provide different values for the same thing (MCP servers, binaries, env vars)
- Branches need to add to a shared collection
- You need intelligent merging or conflict detection

❌ **Don't create a grafter if:**
- Only one branch will ever provide the file (karabiner, nvim)
- Files are per-branch and shouldn't merge (list in `.eden-graft` instead)

## Grafter Strategies

### 1. Collection (Symlink)

**When to use:** Multiple branches contribute individual items to a collection

**How it works:** Symlink each item into a shared directory

**Examples:**
- `graft-bin`: Binaries from branches → `~/.eden/bin/`
- `graft-zsh`: Env files from branches → `~/.config/zsh/zshenv.d/`

**Pattern:**
```bash
# For each branch
for item in "$branch/.local/bin"/*; do
    ln -sf "$item" "$HOME/.eden/bin/$(basename "$item")"
done
```

**Conflict resolution:** 
- Detect conflicts (file already exists)
- Last branch wins (or warn user)
- Keep source in branch (editable)

**Pros:**
- Immediate updates (edit in branch, reflects instantly)
- Clear ownership (symlinks show source)
- No regeneration needed

**Cons:**
- Can break if branches move
- Conflicts need manual resolution

### 2. Merge (JSON/Data)

**When to use:** Multiple branches contribute keys/values that combine into one file

**How it works:** Parse, merge, and write combined output

**Examples:**
- `graft-mcp`: MCP servers from branches → `~/.config/mcp/servers.json`

**Pattern:**
```bash
# Start with empty
MERGED_JSON='{"mcpServers": {}}'

# For each branch
for branch in branches; do
    # Merge branch JSON into MERGED_JSON
    MERGED_JSON=$(jq '.mcpServers += $branch[0].mcpServers' ...)
done

# Write final result
echo "$MERGED_JSON" > ~/.config/mcp/servers.json
```

**Conflict resolution:**
- Last branch wins for duplicate keys
- Or: detect and warn about conflicts
- Or: custom merge logic per data type

**Pros:**
- Single canonical file
- Can validate/transform during merge
- Clear final state

**Cons:**
- Must re-graft after branch changes
- Loses source attribution
- More complex logic

### 3. Generate (Routing/Config)

**When to use:** Create routing or conditional config based on branches

**How it works:** Generate directives that route to branch-specific files

**Examples:**
- `graft-git`: Git includeIf directives → `~/.config/eden/local/gitconfig`

**Pattern:**
```bash
# For each branch with git context
for context in branches; do
    # Add routing directive
    cat >> ~/.config/eden/local/gitconfig << EOF
[includeIf "gitdir:~/Development/$context/"]
    path = ~/.config/eden/local/gitconfig.$context
EOF
done
```

**Conflict resolution:**
- Directory-based (git) or conditional routing
- No conflicts - each context has its own route

**Pros:**
- Preserves branch-specific configs
- Dynamic routing based on context
- No actual merging needed

**Cons:**
- Requires app support (includeIf, conditional loading)
- Generated config needs regeneration

### 4. Aggregate (Metadata)

**When to use:** Collect information about branches without merging content

**How it works:** Read and aggregate metadata from branches

**Examples:**
- `graft-secrets`: List all secrets from branches

**Pattern:**
```bash
# For each branch
for branch in branches; do
    # Parse .eden-secrets and aggregate
    # Don't merge - just list/validate
done
```

**Conflict resolution:**
- Usually none needed (read-only)
- Can detect duplicates and warn

**Pros:**
- No file generation
- Simple read-only operation
- Easy to understand

**Cons:**
- Limited to metadata/validation use cases

## Decision Tree

```
Do multiple branches contribute?
├─ No → Don't create grafter (use stow or manual)
└─ Yes → What are you merging?
    ├─ Individual files/binaries?
    │   └─ Use: Collection (Symlink) strategy
    │       Examples: graft-bin, graft-zsh
    │
    ├─ Data that combines (JSON/YAML)?
    │   └─ Use: Merge strategy
    │       Examples: graft-mcp
    │
    ├─ Routing to branch-specific configs?
    │   └─ Use: Generate strategy
    │       Examples: graft-git
    │
    └─ Just reading/validating?
        └─ Use: Aggregate strategy
            Examples: graft-secrets
```

## Implementation Guidelines

### File Location
```
packages/eden/.eden/libexec/grafters/
├── graft-bin          # Collection strategy
├── graft-claude       # Collection strategy
├── graft-configs      # Allowlist strategy (.eden-graft)
├── graft-git          # Generate strategy
├── graft-mcp          # Merge strategy
├── graft-secrets      # Aggregate strategy
└── graft-zsh          # Collection strategy
```

### Naming Convention
- Prefix: `graft-`
- Name: What it grafts (bin, zsh, mcp)
- Must be executable

### Structure
```bash
#!/bin/bash
# graft-<name> - <description>
# Part of Eden's pluggable grafter system
set -e

# 1. Detect Eden root
# 2. Load branches file
# 3. Expand branch paths
# 4. For each branch:
#    - Check if relevant files exist
#    - Apply strategy (symlink/merge/generate)
# 5. Report results
```

### Error Handling
- Exit 0 if nothing to do (not an error)
- Warn but continue on conflicts
- Report summary (added/skipped/conflicts)

## Common Patterns

### Branch Path Expansion
```bash
expand_branch_path() {
    local path="$1"
    path="${path//\$EDEN_ROOT/$EDEN_ROOT}"
    path="${path/#\~/$HOME}"
    echo "$path"
}
```

### Conflict Detection
```bash
if [ -L "$target" ]; then
    current=$(readlink "$target")
    if [ "$current" != "$source" ]; then
        # Conflict: already linked elsewhere
    fi
elif [ -e "$target" ]; then
    # Conflict: file exists (not a symlink)
fi
```

### Reporting
```bash
echo "  → Grafting <thing> from branches"
echo "  → Grafted <thing> from: $branch_name"
echo "  → Grafted N <things> from M branch(es)"
echo "  ⚠ Conflicts detected:"
```

## Examples

### Creating a New Grafter

**Scenario:** You want branches to contribute custom aliases to `~/.config/shell/aliases.d/`

**Strategy:** Collection (Symlink) - similar to graft-zsh

**Implementation:**
```bash
#!/bin/bash
# graft-aliases - Graft shell aliases from branches
set -e

ALIASES_D="$HOME/.config/shell/aliases.d"
mkdir -p "$ALIASES_D"

# For each branch with .config/shell/aliases.d/
for branch in branches; do
    BRANCH_ALIASES="$branch/.config/shell/aliases.d"
    if [[ -d "$BRANCH_ALIASES" ]]; then
        for file in "$BRANCH_ALIASES"/*.sh; do
            [[ -e "$file" ]] || continue
            ln -sf "$file" "$ALIASES_D/$(basename "$file")"
        done
    fi
done
```

## Best Practices

1. **Keep source in branches**: Prefer symlinks over copying
2. **Clear ownership**: Make it obvious which branch owns what
3. **Detect conflicts**: Warn users about duplicate names
4. **Idempotent**: Running twice should be safe
5. **Report clearly**: Users should understand what happened
6. **Exit gracefully**: No files to graft is not an error

## See Also

- [branches-and-secrets.md](branches-and-secrets.md) - Branch system overview
- [ARCHITECTURE.md](../branches/default/ARCHITECTURE.md) - Three-layer design

