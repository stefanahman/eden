# Eden — Claude Code Context

Read `ARCHITECTURE.md` for full project context (layout, principles, CLI, branches).

## Critical Constraints

- **Never commit** files matching: `*.key`, `*.secret`, `*.token`, `.env`, `.env.*`
- Secrets come from 1Password at runtime — never store in tracked files
- Respect XDG env vars (`XDG_CONFIG_HOME`, etc.) with standard fallbacks
- All paths must be portable (`$HOME`-relative, no machine-specific absolutes)

## Testing

Validate changes with: `eden doctor`
