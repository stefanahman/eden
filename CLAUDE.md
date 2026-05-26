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

Validate changes with: `eden doctor`. Run the bats integration suite with `./test.sh` (requires `bats-core` — see Dev dependencies below).

## Dev dependencies

Maintainer-only toolchain — not installed by `eden install`. Install manually:

- `bats-core` — runs `tests/bats/` integration suite via `./test.sh`
- `shellcheck` — lints shell scripts (CI runs this; install for local lint)
- `gh` — used by `bin/eden-publish` to create GitHub releases

macOS: `brew install bats-core shellcheck gh`
Arch:  `sudo pacman -S bats shellcheck github-cli`

## Versioning

- Semver in `VERSION` at repo root; `eden --version` prints it.
- Cut releases via `bin/eden-publish [--major|--minor|--patch]` (maintainer-only). Defaults to `--patch`. Generates `CHANGELOG.md` entries from conventional commits (`feat:`, `fix:`, `perf:`, `refactor:`) since the last tag; tags, pushes, and creates a GitHub release.
- Use conventional commits (`type(scope): description`) so the changelog generates cleanly.
- Grafter contract version (`EDEN_GRAFTER_API` in `bin/eden-graft`) is **separate** from the CLI version. Bump it on breaking changes to how grafters are invoked, discovered, or what env vars they may rely on — not on optional additions.
