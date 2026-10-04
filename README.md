# eden

Dotfiles across machines: a public engine, your private configs on top.

[![test](https://github.com/stefanahman/eden/actions/workflows/test.yml/badge.svg)](https://github.com/stefanahman/eden/actions/workflows/test.yml)
[![release](https://img.shields.io/github/v/release/stefanahman/eden)](https://github.com/stefanahman/eden/releases)
[![license](https://img.shields.io/github/license/stefanahman/eden)](LICENSE)

eden keeps one environment on macOS and Arch Linux. This repo holds the
engine and a small shared base: zsh, bash and git config, and macOS
defaults. `eden plant` links the base into `$HOME` with GNU Stow.

Your own configs live in branches: private git repos laid out like
`$HOME`. `eden graft` merges them in: config files, scripts,
environment files, git identities, MCP servers, Claude Code settings
and Brewfiles. Secrets come from 1Password at runtime and are never
committed.

Gardens group branches by area of life, such as work and personal. A
machine grows the gardens it needs and shows one at a time; `eden
garden use` switches between them.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/stefanahman/eden/main/get-eden.sh | bash
eden install    # platform packages, GNU Stow among them
eden plant      # link the shared base into $HOME
```

The script clones eden into `~/eden` and puts the `eden` command in
`~/.local/bin`, pinned to the latest release. It needs only git. To do
it by hand: `git clone https://github.com/stefanahman/eden ~/eden`,
then `~/eden/install.sh`; `install.sh --help` lists the other tracks,
a pinned release or main.

## Quick start

Graft the example branch to see each grafter at work:

```sh
eden branch add ~/eden/branches/example
eden graft
eden doctor
```

Then make a branch of your own with `eden branch new <path>`. To group
branches into gardens, run `eden init <repo> --garden <name>` on each
machine: [docs/branches-and-secrets.md](docs/branches-and-secrets.md).

Day to day, `eden grow` plants and grafts in one step, and `eden update`
pulls the latest eden and your branches repo.

## Docs

- [Architecture](ARCHITECTURE.md): layout, layers, grafters, commands
- [Branches and secrets](docs/branches-and-secrets.md): branch layout,
  secrets, gardens
- [Grafters](docs/grafters.md): what each grafter does, and how to
  write one
- [1Password setup](docs/1password-setup.md): the CLI, and MCP servers
  that need secrets

The base is one person's setup, opinionated by design: fork it and make
it yours.

See also: [owl](https://github.com/stefanahman/owl) ·
[spaces](https://github.com/stefanahman/spaces) ·
[mux](https://github.com/stefanahman/mux) ·
[mcp-defer](https://github.com/stefanahman/mcp-defer) ·
[claude-status](https://github.com/stefanahman/claude-status) ·
[mindoro](https://github.com/stefanahman/mindoro)

## License

MIT
