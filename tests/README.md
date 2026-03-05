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

### Grafter Integration Tests (`grafter/`)

Sandboxed tests that exercise grafters against a temporary `$HOME`. Each test
file creates a temp directory, overrides `HOME`/`XDG_CONFIG_HOME`/`EDEN_ROOT`,
and validates symlinks, generated files, and conflict detection.

**Run a single grafter test:**
```bash
bash tests/grafter/test-claude.sh
```

**Available tests:**
- `test-claude.sh` — graft-claude (symlinks, project scope, conflicts, idempotency)
- `test-mcp.sh` — graft-mcp (JSON merge, project scope, client sync, isolation)

Shared helpers are in `tests/helpers.sh` (sandbox lifecycle, assertions).

## Adding Tests

Add new validation scripts to this directory as Eden grows. Keep them:
- Fast (< 5 seconds)
- Focused (one concern per script)
- Informative (clear pass/fail output)

For grafter tests, add `tests/grafter/test-<name>.sh` — they're picked up
automatically by `test.sh`.

