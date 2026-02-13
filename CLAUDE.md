# Eden — Claude Code Context

Read `ARCHITECTURE.md` for full project context (layout, principles, CLI, branches).

## Critical Constraints

- **Never commit** files matching: `*.key`, `*.secret`, `*.token`, `.env`, `.env.*`
- Secrets come from 1Password at runtime — never store in tracked files
- Respect XDG env vars (`XDG_CONFIG_HOME`, etc.) with standard fallbacks
- All paths must be portable (`$HOME`-relative, no machine-specific absolutes)

## Git Commits

Use **conventional commits**. Format: `type(scope): description`

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`
Scope is optional — use when it adds clarity (e.g., `fix(graft): ...`, `feat(cli): ...`).

**Never add `Co-Authored-By` trailers** for AI bots (no Claude, Copilot, GPT, etc.).

## Testing

Validate changes with: `eden doctor`
