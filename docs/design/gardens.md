# Gardens — design (proposed)

> **Status:** proposed, not implemented. Where this differs from current
> behaviour, the difference is the point. When a part is built, move its
> text into ARCHITECTURE.md and docs/grafters.md and delete it here.

## The problem

Today a machine has one branch list, `~/.config/eden/branches`, and in
practice one context: a work laptop grafts the work branch, a personal
laptop the personal one. That no longer fits when one machine is used
for both — work in the daytime, personal in the evening and at weekends
— and when a context has to run on more than one platform.

## The approach

**Graft every context a machine is used for, keep them from colliding,
and let the garden decide what is in view.** Switching gardens changes
only the few global things that belong to one context — keys,
workspaces, tools that span many repos. Nothing is re-grafted and
nothing is removed, so a switch is instant and reversible.

This works because most context-specific configuration can be scoped
to the repos it belongs to, and repo-scoped configuration never
collides: a work repo's identity, project settings and project tools
act only inside that repo, whichever garden is in view.

The trade-off: in the personal garden, work is out of view, not absent.
Its scripts, repo configuration and packages stay installed.

## Terms

| Term | Meaning |
|---|---|
| **Eden** | The whole: the trunk and every garden grown from it. |
| **Trunk** | This repo. Its packages are planted by `eden plant` (stow). |
| **Branch** | A folder that mirrors `$HOME`, grafted by `eden graft`. Unchanged. |
| **Context** | A branch that carries one area's identity: its accounts, git remotes and tools — e.g. `work` for Example Corp, `personal` for John Doe. |
| **Garden** | A named choice of contexts in view, e.g. `work` and `personal`. |
| **Active garden** | The garden in view on a machine. One at a time. |

## Levels

Every grafted output belongs to one of three levels. The aim is to
keep the middle level large and the last one small.

| Level | Acts | Active | Mechanisms |
|---|---|---|---|
| **Shared** | everywhere | always | shell and editor config, Claude rules and settings, the default git identity |
| **Per repo** | inside matching repos only | always | git identity by remote, Claude project config, project MCP servers in the client's local scope |
| **Per garden** | globally, for one context | only while its garden is in view | keys, workspaces, tools that span repos (configured per session), browser profile |

### Per-repo mechanisms

- **Git identity by remote.** *Built:* docs/grafters.md, `graft-git`.
- **Project MCP servers in the client's local scope.** *Built:*
  docs/grafters.md, "Project Scope".

### Per-garden mechanisms

- **Session environment** for tools that span repos: each context has
  its own terminal-multiplexer session, and that session's server starts
  with the context's environment (a tool's config path, for example).
  Panes inherit the server's environment, so everything started in the
  session sees it — including workspaces that other tools create inside
  it without passing any environment of their own. Setting variables
  per workspace is not enough for that reason.
- **Garden-aware readers**: the few programs that own global keys and
  workspaces read the active garden and show only its contexts.

## Rules that make coexistence safe

1. **A collision is an error.** *Built:* docs/grafters.md, "Collisions
   between branches".
2. **Platform-only entries are gated.** *Built:* a branch's
   `platforms/<mac|arch>/` folder (docs/branches-and-secrets.md, "Platform
   folders").
3. **Secrets name their account.** *Built:* docs/branches-and-secrets.md,
   `op_account`.
4. **The environment is shell-neutral.** Env files in POSIX `sh` syntax,
   sourced by zsh and bash alike, instead of zsh-only `zshenv.d`.
5. **Shared config directories tolerate several contexts.** A tool that
   reads every file in a directory (`*.d/*.yaml`) sees both contexts'
   files at once; if it rejects duplicate names or keys, it must either
   select by garden or the contexts must not share names.
6. **Grafting reports failure.** *Built:* docs/grafters.md, "Error
   Handling".

## Switching gardens

`eden garden use <name>` records the active garden in one state file
and asks the garden-aware readers to reload. It does not graft.

Where the state and the command live is open: in the branches first,
as a script, moving into the trunk once the shape has proven itself; or
in the trunk from the start.

## Deferred, and why

| Deferred | Needed only when |
|---|---|
| Removing what an unregistered branch grafted (link scan, record of merged entries) | a branch is unregistered — rare, since contexts stay grafted. `eden doctor` reports leftovers meanwhile. |
| Branch kinds and precedence | a branch must override another's output. None does today: no branch grafts a path the trunk plants. |
| Check before apply (grafter API v2, plan mode) | collisions can't be caught inside each grafter. The runner accepts exactly one API version (bin/eden-graft:50), so a v2 must either move all grafters in one change or first teach the runner to accept both. |
| A Claude configuration folder per garden (`CLAUDE_CONFIG_DIR`) | two contexts need separate Claude accounts. Claude Code documents the variable for running accounts side by side. |

## Interfaces across platforms

Where the same need has a macOS and a Linux implementation, branches
describe the need and the platform branch supplies the implementation.

- **Actions** — open an app, a URL or a browser profile; focus a window;
  notify; lock; silence notifications. Each is one command name on
  `PATH`, implemented by the platform branch. One platform branch is
  active per machine, so the names never collide.
- **Configuration** — keys, window placement, workspaces, background
  services, package lists. Branches declare data; the platform branch
  renders it into the platform's format.
- **Already interfaces** — git's per-platform file
  (`packages/{mac,arch}/.config/git/platform`), and workspace files read
  by one tool per platform.
- **One-sided needs stay plain files** until a second platform needs
  them.

## Documentation that changes when this is built

- ARCHITECTURE.md: Branches (contexts, gardens), Layering Guidance (the
  three levels), Constraints (grafting and removal).
- docs/grafters.md: the collision rule, platform gating, identities by
  remote, project MCP servers in local scope.
- docs/branches-and-secrets.md: "Context Switching" becomes gardens;
  secrets name their account.

## Open questions

1. *Settled:* platform-only parts live in a branch's `platforms/<platform>/`
   folder, with the trunk's names, `mac` and `arch`.
2. Where the garden state and `eden garden` live, and how readers are
   told to reload.
3. Whether Cursor has a per-project equivalent of Claude Code's local
   scope. Meanwhile a repo with `.cursor/` still gets `.cursor/mcp.json`.
4. The data format for keys, and whether renderers live in the trunk or
   in platform branches.
5. Where machine-specific facts live (network, window positions,
   checkout paths): a tracked branch per machine, or the untracked
   `~/.config/eden/local/`.
