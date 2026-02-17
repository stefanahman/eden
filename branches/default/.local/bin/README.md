# MCP Wrapper Scripts

## Why wrappers instead of inline `sh -c`?

MCP configs are JSON files read by AI-powered editors (Cursor, Zed, Claude Desktop).
These editors run the configured commands as child processes.

The naive approach puts shell scripts inline:

```json
{
  "command": "sh",
  "args": ["-c", "SECRET=$(op read '...') npx some-mcp-server"]
}
```

Problems:
- **Security**: gives the editor a raw shell with secret access in one opaque string
- **Auditability**: can't read, lint, or test a script crammed into JSON
- **Visibility**: `sh -c` hides what actually runs from process monitors

Wrapper scripts solve this:

```json
{
  "command": "mcp-github-eden",
  "args": []
}
```

The editor sees a binary name. The script is version-controlled, readable, and
uses `exec` to replace the shell process (no lingering parent).

## Convention

- Name: `mcp-<server-name>`
- Location: `branches/<branch>/.local/bin/` (grafted to `~/.eden/bin/` by `graft-bin`)
- Secrets: always via `op read` at runtime, never stored on disk
- Process: use `exec` to hand off to the real server
