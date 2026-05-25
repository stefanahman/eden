# Eden Example Branch

A small, **functional** example showing the structure of an Eden private branch.
Grafting it produces real (safe) symlinks, env vars, MCP entries, etc. so you
can see each grafter in action — then fork into your own private branches repo
and replace the placeholders with your real content.

## Use it

```bash
# Add to ~/.config/eden/branches (uncomment the example line):
$EDEN_ROOT/branches/example

# Then:
eden graft
```

After grafting you'll have:

- `~/.config/example-branch/marker.txt` — a symlink demonstrating `graft-configs`
- `~/.config/mcp/servers.json` — an `example-memory` MCP entry (no auth needed; runs locally via npx)
- `~/.config/zsh/zshenv.d/example.zsh` — sets `EDEN_EXAMPLE_BRANCH=loaded` in your shell
- `~/.eden/bin/eden-example-helper` — a script that prints a greeting
- `~/.claude/rules/example.md` — a sample Claude rule
- `~/.config/git/identities/_example` — sample git identity (scoped to `~/Development/example/`; does **not** become your default — create `_default` in your own private branch for that)
- `Brewfile` entries (`tree`) installed if you run `eden graft brew` on macOS

To remove: comment the line in `~/.config/eden/branches` and run `eden graft` again.

## Fork as a starter

```bash
# Make your own private branches repo:
gh repo create eden-branches --private
git clone <your-repo> ~/eden-branches

# Copy the example as a starting point:
cp -r /path/to/eden/branches/example ~/eden-branches/starter
cd ~/eden-branches
git add starter
git commit -m "Start from Eden example"
```

Then register `~/eden-branches/starter` in `~/.config/eden/branches` and customize.

## Files in this branch

| File | Grafter | Purpose |
|---|---|---|
| `.eden-graft` | graft-configs | Allowlist of paths to symlink |
| `.eden-secrets` | graft-secrets / eden-secrets | Declare secret store entries |
| `Brewfile` | graft-brew | macOS Homebrew packages |
| `.config/example-branch/marker.txt` | graft-configs | Demonstrates symlink behavior |
| `.config/mcp/servers.json` | graft-mcp | MCP server entries merged into `~/.config/mcp/servers.json` |
| `.config/git/identities/_example` | graft-git | Sample identity, directory-scoped (safe) |
| `.config/zsh/zshenv.d/example.zsh` | graft-zsh | Sourced in zsh startup |
| `.claude/rules/example.md` | graft-claude | Claude Code rule |
| `.local/bin/eden-example-helper` | graft-bin | Binary symlinked into `~/.eden/bin/` |

See the trunk's `ARCHITECTURE.md` for the full grafter model.
