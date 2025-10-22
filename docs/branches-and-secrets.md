# Eden Branches and Secrets Integration

## Overview

Eden supports **branches** - separate git repositories that extend Eden with private, context-specific configurations. Each branch can define its own secrets in a `.eden-secrets` file.

## Branch Concept

```
Eden (trunk)              branch-work              branch-personal
├── packages/             ├── packages/            ├── packages/
├── .eden-secrets         ├── .eden-secrets        ├── .eden-secrets
└── (public repo)         └── (private repo)       └── (private repo)
```

**Eden trunk**: Public, cross-platform core configurations  
**Branches**: Private extensions for specific contexts (work, personal, clients)

## Secrets Integration

### How It Works

1. **Eden trunk** has `.eden-secrets` with shared secrets (GitHub MCP, etc.)
2. **Each branch** can have its own `.eden-secrets` for context-specific secrets
3. **`eden-secrets` command** aggregates all secrets from trunk + branches

### Example Setup

#### 1. Eden Trunk (`.eden-secrets`)
```ini
[secret]
name=GitHub MCP Token
path=op://Private/GitHub MCP Token/credential
description=GitHub Personal Access Token for MCP server integration
required_by=Cursor IDE (Model Context Protocol)
setup_command=eden-mcp-setup
```

#### 2. Work Branch (`~/branch-work/.eden-secrets`)
```ini
[secret]
name=Work VPN Certificate
path=op://Work/VPN Certificate/password
description=Corporate VPN authentication certificate password
required_by=OpenVPN connection to company network
setup_command=work-vpn-setup

[secret]
name=Work SSH Key Passphrase
path=op://Work/SSH Key/passphrase
description=Passphrase for work SSH private key
required_by=Git operations on company GitLab
```

#### 3. Personal Branch (`~/branch-personal/.eden-secrets`)
```ini
[secret]
name=Personal Server SSH Key
path=op://Personal/Home Server/ssh_key
description=SSH key for home server access
required_by=Home automation scripts

[secret]
name=Personal API Keys
path=op://Personal/API Keys/openai
description=OpenAI API key for personal projects
required_by=AI scripts and experiments
```

## Using Branch Secrets

### Register Branches

Create or edit `~/.config/eden/branches`:
```
~/branch-work
~/branch-personal
```

### List All Secrets (Trunk + Branches)

```bash
$ eden-secrets list

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Eden 1Password Requirements
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Name: GitHub MCP Token
Path: op://Private/GitHub MCP Token/credential
Description: GitHub Personal Access Token for MCP server integration
Required by: Cursor IDE (Model Context Protocol)
Setup: eden-mcp-setup
Source: Eden (trunk)

Name: Work VPN Certificate
Path: op://Work/VPN Certificate/password
Description: Corporate VPN authentication certificate password
Required by: OpenVPN connection to company network
Source: branch-work

Name: Work SSH Key Passphrase
Path: op://Work/SSH Key/passphrase
Description: Passphrase for work SSH private key
Required by: Git operations on company GitLab
Source: branch-work

Name: Personal Server SSH Key
Path: op://Personal/Home Server/ssh_key
Description: SSH key for home server access
Required by: Home automation scripts
Source: branch-personal
```

### Validate All Secrets

```bash
$ eden-secrets validate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Validating 1Password Secrets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking: GitHub MCP Token (Eden (trunk)) ... ✓
Checking: Work VPN Certificate (branch-work) ... ✓
Checking: Work SSH Key Passphrase (branch-work) ... ✓
Checking: Personal Server SSH Key (branch-personal) ... ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Results: 4 found, 0 missing
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ All required secrets are configured!
```

## Benefits

### ✅ Separation of Concerns
- **Trunk secrets**: Shared tools (GitHub, dev tools)
- **Work secrets**: Company VPN, SSH keys, work APIs
- **Personal secrets**: Home servers, personal APIs

### ✅ Security
- Each branch is a separate private git repo
- Secrets never committed to version control
- Can share different branches with different people/teams

### ✅ Portability
- Clone Eden trunk on new machine
- Optionally clone work/personal branches
- `eden-secrets validate` shows what's needed

### ✅ Context Switching
- Work laptop: Eden + branch-work
- Personal laptop: Eden + branch-personal
- Client machine: Eden + branch-client-acme

## Creating a Branch with Secrets

### 1. Create Branch Repository
```bash
mkdir -p ~/branch-work
cd ~/branch-work
git init
```

### 2. Add Configurations
```bash
# Branch structure
branch-work/
├── .eden-secrets          # Secret requirements
├── packages/
│   └── common/
│       ├── .config/
│       │   └── git/
│       │       └── config.local   # Work git config
│       └── .local/
│           └── bin/
│               └── work-vpn-setup  # Setup script
```

### 3. Create `.eden-secrets`
```bash
cat > .eden-secrets << 'EOF'
[secret]
name=Work VPN Certificate
path=op://Work/VPN Certificate/password
description=Corporate VPN authentication certificate password
required_by=OpenVPN connection to company network
setup_command=work-vpn-setup
EOF
```

### 4. Register Branch
```bash
echo "~/branch-work" >> ~/.config/eden/branches
```

### 5. Plant Branch Configs
```bash
# Recommended: Use eden's plant command (provides helpful checks)
cd ~/branch-work
eden plant

# Alternative: Use GNU Stow directly if you prefer
stow -t $HOME -d packages common
```

### 6. Validate Secrets
```bash
eden-secrets validate
# Will now check trunk + branch-work secrets
```

## Use Cases

### Work Context
```
Eden + branch-work
├── Work VPN credentials
├── Company SSH keys
├── Corporate git email
├── Company Slack tokens
└── Internal API keys
```

### Personal Context
```
Eden + branch-personal
├── Home server SSH keys
├── Personal API keys
├── Hobby project credentials
└── Self-hosted service tokens
```

### Client Context
```
Eden + branch-client-acme
├── Client VPN access
├── Client-specific SSH keys
├── Project-specific tokens
└── Client git credentials
```

## Philosophy

**Eden trunk**: Public, shareable, cross-platform foundation  
**Branches**: Private extensions for specific life contexts  
**Secrets**: Centralized in 1Password, documented in `.eden-secrets`  

This pattern enables:
- **One environment, many contexts**
- **Share Eden publicly, keep branches private**
- **Automatic secret discovery and validation**
- **Clear separation between public and private**

