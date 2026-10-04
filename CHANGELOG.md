# Changelog

All notable changes to Eden are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- releases -->

## [v0.2.0] - 2026-10-04

- fix(publish): a tag outside main's history is refused, and --since names the base
- feat(doctor): name MCP servers whose command is gone
- fix(graft): a grafter without --api-version is not run to ask its version
- fix(doctor): Karabiner 16 renamed the processes it is found by
- feat(doctor): name the mise tools declared but not installed
- feat(graft-mise): eden graft installs the tools mise configs declare
- feat(branches): a .eden-graft is what makes a folder a branch
- fix(branches): a path's garden comes from the list, not from folder names
- feat(garden): eden garden branches lists each branch with its garden
- feat(branch): name a listed branch by its folder name
- feat(doctor): check .eden-gardens against the repo and this machine
- feat(garden): use switches the garden's MCP servers
- feat(update): eden update pulls the repo with the gardens
- feat(graft-mcp): a garden's global servers only while it is in view
- feat(graft-mcp): take out the servers it added that no branch declares
- feat(branches): the garden a graft root belongs to
- feat(init): eden init <repo> sets up gardens
- feat(branch): with gardens, branch commands edit .eden-gardens
- feat(garden): eden garden, which gardens grow here and which is in view
- feat(branches): gardens declared in .eden-gardens
- fix(branch): a relative path is relative to where eden was run
- refactor(branches): one check for whether a branch list is set up
- feat(branches): a project's .eden-target may list several paths
- fix(grafters): a branch's projects folder counts as grafted
- feat(env): env files that bash and zsh both load
- feat(graft-mcp): project servers go to Claude Code's local scope
- feat(graft-git): an identity applies to the remotes it names
- feat(branches): a platform folder is grafted on its platform only
- feat(graft): a collision between branches is an error
- fix(doctor): reach the deepest grafts, and ~/.ssh
- fix(doctor): ignore the lock links Chromium-based apps keep
- fix(branch): list counts a branch's secrets once
- fix(doctor): check links where grafts put them, and find leftovers
- fix(secrets): read each secret from the account it names
- fix(graft): report failed grafters, and pass --force to them
- fix(branch): add and remove compare whole entries
- refactor: one reader for the branch list
- fix(bash): login shells load the eden profile, cargo only if present
- fix(git): arch gets the platform file the common config includes
- fix(doctor): count broken symlinks without tripping set -e
- feat(graft-claude): graft output-styles/
- feat(graft-claude): graft top-level CLAUDE.md and *.local.md
- feat(graft-gh-dash): compose ~/.config/gh-dash/config.yml from branches
- fix(graft-claude): also graft commands/, settings.json, statusline.sh
- fix(graft-configs): symlink directories with ln -sfn instead of stow
- fix(doctor): handle empty git identity dir without leaking bash error

## [v0.1.0] - 2026-05-26

First public release of Eden — a layered dotfiles engine for macOS and Arch Linux.

### What Eden does

Eden manages dotfiles, packages, and personal environment tooling across machines. It splits responsibilities cleanly:

- A minimal **trunk** (engine: `git`, `stow`, `zsh`) you clone from this repo
- **Private branches** (your taste — apps, configs, secrets, identities, MCP servers) hosted in your own git repos
- **Grafters** that compose multiple branches into a coherent `$HOME`

Configs are deployed via GNU Stow (one-to-one symlinks); branches add intelligent composition on top.

### Install

```bash
# curl|bash (pins to the latest release tag)
curl -fsSL https://raw.githubusercontent.com/stefanahman/eden/main/get-eden.sh | bash

# Or clone + bootstrap
git clone https://github.com/stefanahman/eden.git ~/eden
cd ~/eden && ./install.sh
```

`install.sh` supports `--latest` (default), `--main` (bleeding edge), or a specific `vX.Y.Z`.

### Features

**Install & update**
- Tag-aware install (`install.sh --latest|--main|vX.Y.Z`) and update (`eden update [--check|--main|--latest|vX.Y.Z]`). Track mode persists in `~/.config/eden/track`.
- `get-eden.sh` for curl|bash bootstrapping.

**Branch system**
- 8 built-in grafters: `bin`, `brew`, `claude`, `configs`, `git`, `mcp`, `secrets`, `zsh`.
- Each grafter declares an API version (`EDEN_GRAFTER_API`) so breaking changes fail loudly instead of silently corrupting state.
- `branches/example/` ships as a functional starter (minimal entry per grafter input). Auto-loaded on fresh installs; `eden branch add` auto-deactivates it when you register your own.

**Secrets**
- 1Password (`op read`) is the default secret provider. Override `EDEN_SECRET_GET` to use any command (`pass show`, `age -d`, `vault read`, etc.).
- `eden-secrets` UX adapts: 1Password-specific failure hints only appear when op is configured.

**Health & ergonomics**
- `eden doctor` reports installation health. `--format=plain` emits machine-parseable `severity|message` lines. Tiered exit codes: `0` clean, `1` warnings, `2` errors.
- `eden init` walks you through first-run setup. `--yes` for non-interactive CI/Docker.
- `bin/eden-publish` cuts releases (bump VERSION, generate CHANGELOG, tag, push, create GitHub release) with strict preflight (clean tree, on main, canonical remote, in sync).

**Tested**
- Bats integration suite (`tests/bats/`) covering doctor format/exit codes and the grafter contract.
- GitHub Actions CI: `{macos-latest, ubuntu-latest} × {umask 022, 002}` + shellcheck.

### Platforms

- macOS (Apple Silicon + Intel)
- Arch Linux

### Documentation

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — layout, principles, branch model
- [`docs/branches-and-secrets.md`](docs/branches-and-secrets.md) — how branches and secrets compose
- [`docs/grafters.md`](docs/grafters.md) — grafter contract and how to write one

### Roadmap

11 deferred features filed as `someday`-labeled GitHub issues, each with an explicit trigger criterion: hooks system, `eden watch`, tags for selective planting, generations + rollback, file-suffix alternates, pluggable secret adapters, man pages, upgrade-method-aware update, stateVersion anchor, `--one-shot` ephemeral install, and `graft-pacman` for Arch package lists.
