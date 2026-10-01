# Eden Grafters Guide

## Overview

Grafters are pluggable scripts that intelligently merge configurations from multiple branches. Each grafter uses a specific **strategy** to combine sources, and none lets two branches write the same target.

## Quick Reference

| Grafter | Strategy | What it does | Branch path |
|---------|----------|-------------|-------------|
| `graft-bin` | Collection | Symlinks binaries into `~/.eden/bin/` | `.local/bin/*` |
| `graft-brew` | Aggregate | Runs `brew bundle` on branch Brewfiles (macOS only) | `Brewfile` |
| `graft-claude` | Collection | Symlinks Claude rules/agents/commands/skills + top-level files (global + project) | `.claude/{rules,agents,commands,skills}/`, `.claude/{settings.json,statusline.sh,CLAUDE.md,*.local.md}` |
| `graft-configs` | Allowlist | Symlinks paths listed in `.eden-graft` | Varies (per allowlist) |
| `graft-env` | Collection | Symlinks POSIX sh env files into `~/.config/eden/env.d/`, loaded by bash and zsh | `.config/eden/env.d/*.sh` |
| `graft-git` | Generate | Creates `includeIf` directives for branch git identities | `.config/git/identities/*` |
| `graft-mcp` | Merge | Merges MCP server JSON from all branches (global + project) | `.config/mcp/servers.json` |
| `graft-mise` | Install | Runs `mise install` from `$HOME`, after `graft-configs` has linked the branches' mise configs; `eden doctor` names a declared tool still missing | a mise config listed in `.eden-graft`, e.g. `.config/mise/conf.d/<name>.toml` |
| `graft-secrets` | Aggregate | Collects 1Password secret definitions for `eden secrets` | `.eden-secrets` |
| `graft-zsh` | Collection | Symlinks zsh-only env files into `~/.config/zsh/zshenv.d/` | `.config/zsh/zshenv.d/*.zsh` |

## Config Deployment: `.eden-graft` vs Dedicated Grafters

Most branch configs are deployed via the **`.eden-graft` allowlist** — a simple file listing paths that `graft-configs` should symlink to `$HOME`. This covers configs that don't need multi-branch merging (editor settings, window managers, etc.).

**Dedicated grafters** exist for configs where multiple branches contribute to the same logical output and need intelligent merging, routing, or aggregation.

### Decision: `.eden-graft` entry vs dedicated grafter

| Use `.eden-graft` when... | Create a grafter when... |
|---|---|
| Only one branch provides the config | Multiple branches contribute to the same file |
| Simple symlink is sufficient | Configs need merging or routing |
| Examples: karabiner, nvim, skhd | Examples: MCP servers, git identities, shell env |

### How `graft-configs` works

1. Reads `~/.config/eden/branches` to find registered branches
2. For each branch, reads its `.eden-graft` file (an allowlist of paths)
3. Symlinks each listed path from the branch into `$HOME` (directories via `stow`, files via `ln -sf`)
4. Paths not in `.eden-graft` are **not deployed** — this is intentional to prevent accidental grafting

### The `.eden-graft` file

Located at the root of each branch (e.g., `branches/example/.eden-graft`). Format:

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
- You need intelligent merging or routing

❌ **Don't create a grafter if:**
- Only one branch will ever provide the file (karabiner, nvim)
- Files are per-branch and shouldn't merge (list in `.eden-graft` instead)

## Grafter Strategies

### Project Scope

Some grafters support **project scope** in addition to global scope. Project-scoped
configs are placed in external project directories rather than `$HOME`.

Projects are discovered by `.eden-target` marker files anywhere under `projects/`:

```
branch/
├── .claude/rules/           # global → ~/.claude/rules/
├── .config/mcp/servers.json # global → ~/.config/mcp/servers.json
└── projects/
    ├── my-app/
    │   ├── .eden-target     # contains: ~/Development/my-app
    │   ├── .claude/skills/  # → ~/Development/my-app/.claude/skills/ (symlinked)
    │   └── .mcp/servers.json# → Claude Code's local scope for ~/Development/my-app
    └── games/my-game/       # any nesting depth allowed
        ├── .eden-target
        └── .mcp/servers.json
```

Directories without `.eden-target` are organizational folders (silently skipped).

An `.eden-target` lists where the repo is checked out, one path per line;
the first that exists on this machine wins, since machines check a repo
out in different places (`~/Development/app` on one, `~/Development/private/app`
on another). Blank lines and `#` comments are skipped, and `~`, `$HOME` and
`$EDEN_ROOT` expand as in the branch list. A project none of whose paths
exist is skipped with a warning.

**Grafters with project scope:**
- `graft-claude` — symlinks `.claude/{rules,agents,commands,skills}` and top-level `settings.json`, `statusline.sh`, `CLAUDE.md`, `*.local.md` into target (`*.local.md` = Claude Code's per-project plugin-settings files; `settings.local.json` is never grafted because Claude Code writes to it)
- `graft-mcp` — adds the servers to Claude Code's local scope for the target repo
  (`claude mcp add-json -s local`, run in the repo). Local scope keeps them in Claude Code's state
  file (`~/.claude.json`, or under `CLAUDE_CONFIG_DIR`), not in the repo, so they
  also reach its subdirectories and linked worktrees and leave no untracked
  file. A server already in place is left alone; a changed one is replaced.
  An untracked `.mcp.json` from earlier grafts is named, not deleted.

`graft-mcp` records what it puts in Claude Code — per state file, the
user-scope names and each repo's local-scope names — in
`~/.local/state/eden/mcp-servers.json`, and on the next graft takes out
the recorded servers no branch declares any more: dropped from a branch,
a project no longer listed, or a garden no longer grown. A server added
by hand stays, unless a branch declares one with the same name: Eden's
then takes its place and is later removed like any other of Eden's. A
repo not on the machine keeps its record until
it is back. With gardens, a garden branch's global servers are in user
scope only while its garden is in view (see
[Gardens](branches-and-secrets.md#gardens)).

### 1. Collection (Symlink)

**When to use:** Multiple branches contribute individual items to a collection

**How it works:** Symlink each item into a shared directory

**Examples:**
- `graft-bin`: Binaries from branches → `~/.eden/bin/`
- `graft-env`: POSIX sh env files from branches → `~/.config/eden/env.d/`
- `graft-zsh`: zsh-only env files from branches → `~/.config/zsh/zshenv.d/`
- `graft-claude`: Claude rules/agents/commands/skills + top-level files from branches → `~/.claude/` + project targets

**Pattern:**
```bash
# For each branch
for item in "$branch/.local/bin"/*; do
    ln -sf "$item" "$HOME/.eden/bin/$(basename "$item")"
done
```

**Collisions:** two branches linking the same target collide, and so does a
target inside another branch's linked directory (see
[Collisions between branches](#collisions-between-branches)). A real file
at the target is left alone and reported. Keep source in branch (editable).

**Pros:**
- Immediate updates (edit in branch, reflects instantly)
- Clear ownership (symlinks show source)
- No regeneration needed

**Cons:**
- Can break if branches move

### 2. Merge (JSON/Data)

**When to use:** Multiple branches contribute keys/values that combine into one file

**How it works:** Parse, merge, and write combined output

**Examples:**
- `graft-mcp`: MCP servers from branches → `~/.config/mcp/servers.json` (global) + Claude Code's local scope per project

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

**Collisions:** a named entry, such as an MCP server, given by two branches
collides; nothing is written.

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

**Pattern:** `graft-git` links each identity into `~/.config/git/identities/`
and writes the includes into `~/.config/eden/local/gitconfig`. `_default` is
included always. Another identity applies to the repos whose remotes it
names, in an `[eden]` section of the identity file:

```ini
# .config/git/identities/example-corp
[user]
    email = john@example-corp.com
[eden]
    remote = git@github.com:example-corp/**
    remote = https://github.com/example-corp/**
```

which becomes one include per pattern (git ≥ 2.36; SSH and HTTPS remotes
each need theirs):

```ini
[includeIf "hasconfig:remote.*.url:git@github.com:example-corp/**"]
    path = ~/.config/git/identities/example-corp
```

A repo with no remote, or none that matches, keeps `_default`. An identity
naming no remotes applies by directory instead,
`[includeIf "gitdir:~/Development/<name>/"]`. An identity file must not set
a remote URL: git refuses one in a file included this way.

**Collisions:** each identity routes on its own; two branches providing an
identity of the same name collide.

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

**Collisions:** a secret `id` given by two branches collides. A branch may
reuse an id from the trunk's own `.eden-secrets` to override it.

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
├── graft-brew         # Aggregate strategy (macOS only)
├── graft-claude       # Collection strategy
├── graft-configs      # Allowlist strategy (.eden-graft)
├── graft-env          # Collection strategy
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
trap 'echo "  !! graft-<name> failed at line $LINENO" >&2' ERR

# 1. Detect Eden root
# 2. source "$EDEN_ROOT/lib/branches.sh"
# 3. For each branch in `eden_branches`:
#    - Check if relevant files exist
#    - Apply strategy (symlink/merge/generate)
#    - (Optional) Discover projects via .eden-target for project scope
# 4. Report results
```

### Error Handling
- ERR trap reports script name and line number on `set -e` failures
- Exit 0 if nothing to do (not an error); any other non-zero exit fails
  the run — `eden graft` still runs every grafter, then exits non-zero
  and names the ones that failed
- Never prompt when `EDEN_GRAFT_FORCE=true` (set by `eden graft --force`):
  apply without asking, for non-interactive runs
- Fail on a collision between branches, before writing anything (see
  [Collisions between branches](#collisions-between-branches))
- Report summary (added/skipped, and targets left alone because a real
  file is in the way)

## Common Patterns

### Reading the Branch List

Every grafter reads the list through `lib/branches.sh`, never the file
directly, and walks the graft roots: each branch, followed by its
`platforms/<platform>/` folder when it has one for this machine (see
[Platform folders](branches-and-secrets.md#platform-folders)). The
branches are the grown gardens' when gardens are set up (see
[Gardens](branches-and-secrets.md#gardens)), else the registered ones;
`eden_branch_list_exists` says whether either is set up, for a grafter
that reports when there is nothing to graft:

```bash
# shellcheck source=lib/branches.sh
source "$EDEN_ROOT/lib/branches.sh"

while IFS= read -r branch_path; do
    # branch_path is absolute: blanks and comments are skipped,
    # and ~, $EDEN_ROOT and $HOME are expanded
    branch_name=$(eden_branch_name "$branch_path")   # "work", or "work (mac)"
    ...
done < <(eden_graft_roots)
```

`eden_branches` lists the branches alone, without platform folders, for
commands that show the list.

`eden_branch_expand <entry>` expands one entry the same way (for example
the path in a project's `.eden-target`). Nothing else in an entry is
evaluated.

### Collisions between branches

Two branches writing the same target is an error, never "last branch
wins". A grafter first lists every target it is about to write, then
checks the list with `lib/collisions.sh`, and only then writes:

```bash
# shellcheck source=lib/collisions.sh
source "$EDEN_ROOT/lib/collisions.sh"

# graft_all claims|link: the same walk twice. With "claims" it prints
# one "target<TAB>branch" line per target; with "link" it writes.
graft_all claims | eden_check_collisions || exit 1
graft_all link
```

A target is a path shown with `~` (`eden_home_path`) or, for a named entry
in a merged output, a label such as `MCP server <name>` or
`secret <id>`. `eden_check_collisions` reports a target listed by two
branches, and a target inside another branch's target (a link into a
linked directory would write into that branch), then returns 1. The
grafter exits without writing anything; `eden graft` runs the others and
names it. A collision is resolved in the branches: keep the entry in
one, move it to a shared branch, or make it per repo.

When linking, a link that already points elsewhere is replaced: the
check has ruled out another branch, so an earlier graft left it. A real
file or directory at the target is left alone and reported.

### Reporting
```bash
echo "  → Grafting <thing> from branches"
echo "  → Grafted <thing> from: $branch_name"
echo "  → Grafted N <things> from M branch(es)"
echo "  ⚠ Left alone (not a symlink):"
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
3. **Check collisions first**: List every target, check the list, then write
4. **Idempotent**: Running twice should be safe
5. **Report clearly**: Users should understand what happened
6. **Exit gracefully**: No files to graft is not an error

## See Also

- [branches-and-secrets.md](branches-and-secrets.md) - Branch system overview
- [../ARCHITECTURE.md](../ARCHITECTURE.md) - Eden's layered design

