# 1Password CLI Setup

Eden uses 1Password to securely store and retrieve secrets at runtime.
The CLI integrates with the desktop app for biometric authentication.

## Installation

```bash
eden install
```

This installs both the 1Password desktop app and CLI:
- **macOS**: `1password` (cask) and `1password-cli` via Homebrew
- **Arch Linux**: `1password-beta` and `1password-cli` (from Omarchy repo or AUR)

## Setup

### 1. Launch 1Password and Add Accounts

Open the 1Password desktop app, add your accounts (personal, work, etc.), and sign in.

### 2. Enable CLI Integration

In 1Password: **Settings > Developer > "Integrate with 1Password CLI"**

### 3. Verify

```bash
op whoami          # Shows active account
op account list    # Shows all accounts
eden secrets validate  # Checks all Eden secrets
```

## MCP Wrapper Pattern

MCP servers that need secrets use wrapper scripts in `.local/bin/`. These fetch tokens from 1Password at runtime -- nothing is stored on disk.

### The `op-mcp-warmup` Helper

Multiple MCP servers start concurrently. Without coordination, each would trigger a separate Touch ID prompt. The `op-mcp-warmup` helper serializes biometric auth per 1Password account using mkdir-based locking:

```bash
source op-mcp-warmup
VALUE=$(op_read 'op://vault/item/field' account.1password.com)
```

First caller triggers Touch ID; others wait for the session to warm up. One prompt per account, not per server.

### Wrapper Script Pattern

```bash
#!/usr/bin/env bash
# MCP wrapper: fetches secrets from 1Password at runtime
set -euo pipefail

export PATH="$HOME/.eden/bin:$HOME/.volta/bin:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
source op-mcp-warmup

MY_TOKEN=$(op_read 'op://Vault/item-name/credential' account.1password.com)
export MY_TOKEN

exec npx -y @org/mcp-server
```

Place wrapper scripts in your branch's `.local/bin/` directory. Register the corresponding secrets in `.eden-secrets` so `eden secrets validate` can check them.

### Connecting the Pieces

1. **Secret definition** in `.eden-secrets` -- documents what's needed
2. **Wrapper script** in `.local/bin/` -- fetches secret and starts server
3. **MCP config** in `.config/mcp/servers.json` -- references the wrapper by name
4. **`eden graft`** -- symlinks the wrapper, merges the MCP config, aggregates the secret

## Troubleshooting

**"No accounts configured"** -- Install and sign into the 1Password desktop app, enable CLI integration.

**"Not signed in"** -- Open and unlock the 1Password desktop app.

**"Permission denied"** -- Verify the item exists and you have vault access.

**Multiple Touch ID prompts** -- Make sure your wrapper uses `source op-mcp-warmup` and `op_read` instead of calling `op read` directly.

## See Also

- [branches-and-secrets.md](branches-and-secrets.md) -- Branch system and `.eden-secrets` format
- [grafters.md](grafters.md) -- How `graft-bin` and `graft-mcp` integrate wrappers
