# Cursor IDE Configuration

## MCP (Model Context Protocol) Servers

Eden supports MCP server configuration with a merge system similar to gitconfig.

**Note:** Cursor does not follow XDG Base Directory Specification. It looks for configs in
`~/.cursor/` instead of `~/.config/cursor/`. Eden keeps source files XDG-compliant and uses
`eden-mcp-merge` to translate to Cursor's non-standard location. This pattern may be needed
for other programs that ignore XDG in the future.

### How it works:

1. **Trunk** (`packages/common/.config/cursor/mcp_config.json`)
   - Base MCP servers available to everyone
   - Committed to git

2. **Branches** (`eden-private/*/packages/common/.config/cursor/mcp_config.branch.json`)
   - Additional MCP servers specific to branches (work, personal, etc.)
   - Committed to private branch repos
   - NOT stowed directly

3. **Merged Result** (`~/.cursor/mcp.json`)
   - Final configuration used by Cursor (global config)
   - Created by `eden-mcp-merge`
   - NOT committed anywhere (in .stow-global-ignore)

### Usage:

```bash
# After stowing or adding branch MCP configs
eden-mcp-merge

# This is automatically run by install.sh
```

### Adding Branch-Specific MCP Servers:

Create `eden-private/[branch]/packages/common/.config/cursor/mcp_config.branch.json`:

```json
{
  "$comment": "Branch-specific MCP servers",
  "mcpServers": {
    "my-private-server": {
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

Then run `eden-mcp-merge` to combine with trunk config.

