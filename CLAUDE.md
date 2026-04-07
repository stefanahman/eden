# Eden — Claude Code Context

Read `ARCHITECTURE.md` for full project context (layout, principles, CLI, branches).

## Critical Constraints

- **Never commit** files matching: `*.key`, `*.secret`, `*.token`, `.env`, `.env.*`
- Secrets come from 1Password at runtime — never store in tracked files
- Respect XDG env vars (`XDG_CONFIG_HOME`, etc.) with standard fallbacks
- All paths must be portable (`$HOME`-relative, no machine-specific absolutes)

## 1Password / AFK Mode

If a git command fails with `1Password: agent returned an error` (exit code 128),
run `claude-afk` and retry the command. This switches to a standalone SSH key
that doesn't require biometric auth.

## Testing

Validate changes with: `eden doctor`
