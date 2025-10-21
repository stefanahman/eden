# Eden Tests

Validation scripts for Eden development.

## Quick Start

**Run all tests from repo root:**
```bash
./test.sh
```

## Individual Test Scripts

### `validate-setup.sh`

Validates the Node.js/MCP integration setup before committing.

**Run directly:**
```bash
./tests/validate-setup.sh
```

**What it checks:**
- Script syntax (bash, shell configs)
- File permissions (executables)
- JSON validity (MCP configs)
- Required files exist
- No hardcoded secrets
- XDG compliance
- fnm integration
- 1Password integration
- Stow dry-run (symlink validation)
- Package lists updated

**Exit codes:**
- `0` - All tests passed
- `1` - Some tests failed

### `validate-secrets.sh`

Optional test that checks if 1Password secrets are configured.

**Run directly:**
```bash
./tests/validate-secrets.sh
```

**What it checks:**
- 1Password CLI installed
- 1Password CLI authenticated
- Required secrets exist in 1Password (from `.eden-secrets` registry)

**Note:** This test is informational only. Missing secrets won't fail the build since they're optional for development.

**Skip secrets check:**
```bash
SKIP_SECRETS=1 ./test.sh
```

## Eden Secrets Management

Eden uses `eden-secrets` command to manage 1Password requirements:

```bash
# List all required 1Password items
eden-secrets list

# Validate that required items exist
eden-secrets validate
```

Requirements are tracked in `.eden-secrets` file at repo root.

## Adding Tests

Add new validation scripts to this directory as Eden grows. Keep them:
- Fast (< 5 seconds)
- Focused (one concern per script)
- Informative (clear pass/fail output)

