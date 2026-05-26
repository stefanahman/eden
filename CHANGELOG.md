# Changelog

All notable changes to Eden are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!-- releases -->

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
