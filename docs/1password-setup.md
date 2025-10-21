# 1Password CLI Setup

Eden uses 1Password to securely store and retrieve secrets at runtime.

**This uses the 1Password CLI (`op`) integrated with the desktop app for authentication.**

## Installation

1Password CLI is included in Eden's package lists.

**Install Eden packages:**
```bash
./install.sh --packages
```

This installs both the 1Password desktop app and CLI:
- **macOS**: `1password` (cask) and `1password-cli` via Homebrew
- **Arch Linux**: `1password-beta` and `1password-cli`
  - If you have the **Omarchy repository** configured, packages come from there (pre-built, faster)
  - Otherwise, install from **AUR** using `yay`
- Plus all other Eden dependencies (fnm, pnpm, openvpn, etc.)

**Note:** We use the same packages as Omarchy (`1password-beta` + `1password-cli`) for the latest features and best compatibility.

## Setup

Eden works with 1Password CLI via desktop app integration.

### 1. Install via Eden (Recommended)

```bash
# Install all Eden packages including 1Password
./install.sh --packages
```

**Note for Arch users:** You'll need `yay` AUR helper:
```bash
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### 2. Launch 1Password

Open the 1Password desktop app (installed via Eden packages).

### 3. Add Your Accounts

In the 1Password desktop app:
1. Add your personal account (my.1password.com)
2. Add work accounts (e.g., company.1password.eu)
3. Sign in to each account

### 4. Enable CLI Integration

In 1Password desktop app:
1. Go to **Settings → Developer**
2. Enable **"Integrate with 1Password CLI"**

### 5. Verify

```bash
op whoami
# Shows your active account

op account list
# Shows all your accounts
```

**That's it!** The CLI now uses the desktop app for authentication. When the app is unlocked, the CLI works automatically.

## Verification

After setup, verify everything works:

```bash
# Check authentication
op whoami

# List vaults
op vault list

# Try reading a test item
op item list

# Test Eden integration
eden-secrets validate
```

## Troubleshooting

**"No accounts configured"**
- Install 1Password desktop app
- Add your accounts in the desktop app
- Enable CLI integration in Settings → Developer

**"Not signed in"**
- Open and unlock the 1Password desktop app

**"Permission denied" when reading secrets**
- Verify the item exists in 1Password
- Check you have access to the vault
- Ensure you're signed in: `op signin`

## Creating GitHub Personal Access Token for MCP

The GitHub MCP server enables AI-powered GitHub operations directly from Cursor.

**What you can do:**
- Ask AI to create issues from TODO comments in your code
- Have AI create pull requests with your current changes
- Let AI search repositories and read file contents
- Request AI to manage labels, milestones, and issue assignments
- Ask AI to fork repos, create branches, and merge PRs
- Have AI update files directly via GitHub API

**Setup instructions:**

1. **Visit GitHub Token Settings:**
   - Go to: https://github.com/settings/personal-access-tokens/new
   - ⚠️ **Use Fine-grained tokens** (more secure than classic tokens)

2. **Configure Token:**
   - **Token name:** `Eden MCP Server`
   - **Expiration:** 90 days (recommended) or your preference
   - **Repository access:** All repositories (or select specific repos)

3. **Repository Permissions:**
   
   **Required:**
   - ✓ `Contents` - **Read and write** (read files, push changes)
   - ✓ `Issues` - **Read and write** (create/manage issues)
   - ✓ `Pull requests` - **Read and write** (create/manage PRs)
   - ✓ `Metadata` - **Read-only** (repo metadata, automatically included)
   
   **Optional:**
   - `Commit statuses` - **Read-only** (check CI status)
   - `Discussions` - **Read and write** (manage discussions)
   - `Workflows` - **Read and write** (update GitHub Actions)

4. **Generate and Save:**
   - Click "Generate token"
   - **Important:** Copy it immediately - you won't see it again!
   - Run `eden-mcp-setup` to store it securely in 1Password

## Eden Integration

Once 1Password CLI is set up, Eden's secrets management will work:

```bash
# List all required secrets
eden-secrets list

# Validate secrets are configured
eden-secrets validate

# Setup scripts (like eden-mcp-setup) will automatically store secrets
eden-mcp-setup
```

**Naming Convention:**

All Eden-related 1Password items use kebab-case with `eden-` prefix for CLI-friendly names:
- `eden-github-mcp-token` - GitHub Personal Access Token for MCP
- `eden-[service]-[type]` - Future secrets follow this pattern

Benefits:
- CLI-friendly (no spaces, no quoting needed)
- Consistent with Eden command naming (`eden-secrets`, `eden-mcp-setup`)
- Easy to autocomplete in shell
- Easy to identify Eden secrets at a glance

## Quick Start

```bash
# 1. Install Eden packages (includes 1password desktop + CLI)
./install.sh --packages

# 2. Launch 1Password desktop app
# macOS: Open from Applications
# Arch: Run `1password` or find in app launcher

# 3. Add accounts in desktop app
# Personal account (my.1password.com)
# Work account (company.1password.eu)

# 4. Enable CLI integration
# Settings → Developer → "Integrate with 1Password CLI"

# 5. Verify
op whoami
op account list

# 6. Use Eden secrets
eden-secrets validate
```

Done! 🎉

**How it works:**
- Desktop app handles all authentication
- CLI automatically uses your unlocked accounts
- No need to sign in via terminal
- Supports multiple accounts (personal + work)
- Biometric unlock supported

