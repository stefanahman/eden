# Gardens — design (proposed)

> **Status:** proposed, not implemented. Where this differs from current
> behaviour, the difference is the point. When a part is built, move its
> text into ARCHITECTURE.md and docs/grafters.md and delete it here.

## The problem

Today a machine has one branch list, `~/.config/eden/branches`, and in
practice one area of life: a work laptop grafts the work branch, a
personal laptop the personal one. That no longer fits when one machine
is used for both — work in the daytime, personal in the evening and at
weekends — and when one area has to run on more than one platform.

## The approach

**Graft every garden a machine grows, keep them from colliding, and let
the garden in view decide what is global.** Switching gardens changes
only the few global things that belong to one garden — keys,
workspaces, tools that span many repos, MCP servers outside a repo.
The branches' files stay grafted and nothing is removed from disk, so a
switch is quick and reversible.

This works because most of a garden's configuration can be scoped
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
| **Garden** | A named group of one or more branches that make up one area of life — its accounts, git remotes and tools; e.g. `work` for Example Corp, `personal` for John Doe. A branch belongs to at most one garden. |
| **Shared branch** | A branch in no garden: grafted in every garden, optionally on one platform only. |
| **Garden in view** | The garden a machine shows. One at a time. |

## Defining gardens

*Built:* docs/branches-and-secrets.md, "Gardens": `.eden-gardens` in the
repo, the machine's choices in `~/.config/eden/`, the branch list worked
out on every graft, `eden init <repo>`, `eden garden`, the branch
commands that edit the file, and doctor's checks.

## Levels

Every grafted output belongs to one of three levels. The aim is to
keep the middle level large and the last one small.

| Level | Acts | Active | Mechanisms |
|---|---|---|---|
| **Shared** | everywhere | always | shell and editor config, Claude rules and settings, the default git identity, shared branches' MCP servers |
| **Per repo** | inside matching repos only | always | git identity by remote, Claude project config, project MCP servers in the client's local scope |
| **Per garden** | globally, for one garden | only while its garden is in view | keys, workspaces, tools that span repos (configured per session), browser profile, the garden's MCP servers outside a repo |

### Per-repo mechanisms

- **Git identity by remote.** *Built:* docs/grafters.md, `graft-git`.
- **Project MCP servers in the client's local scope.** *Built:*
  docs/grafters.md, "Project Scope".

### Per-garden mechanisms

- **Session environment** for tools that span repos: each garden has
  its own terminal-multiplexer session, and that session's server starts
  with the garden's environment (a tool's config path, for example).
  Panes inherit the server's environment, so everything started in the
  session sees it — including workspaces that other tools create inside
  it without passing any environment of their own. Setting variables
  per workspace is not enough for that reason.
- **Garden-aware readers**: the few programs that own global keys and
  workspaces read the garden in view and show only its branches and the
  shared ones.
- **MCP servers outside a repo.** A shared branch's
  `.config/mcp/servers.json` goes into the client's user scope always,
  a garden branch's only while its garden is in view. `eden garden use`
  re-runs the MCP grafter, which removes the servers it added before
  that no branch in view declares any more; servers added by hand are
  never touched. A client already running keeps the servers it started
  with.

## Rules that make coexistence safe

1. **A collision is an error.** *Built:* docs/grafters.md, "Collisions
   between branches".
2. **Platform-only entries are gated.** *Built:* a branch's
   `platforms/<mac|arch>/` folder (docs/branches-and-secrets.md, "Platform
   folders").
3. **Secrets name their account.** *Built:* docs/branches-and-secrets.md,
   `op_account`.
4. **The environment is shell-neutral.** *Built:*
   docs/branches-and-secrets.md, "Environment".
5. **Shared config directories tolerate several gardens.** A tool that
   reads every file in a directory (`*.d/*.yaml`) sees every grown
   garden's files at once; if it rejects duplicate names or keys, it must
   either select by garden or the gardens must not share names.
6. **Grafting reports failure.** *Built:* docs/grafters.md, "Error
   Handling".

## Switching gardens

*Built:* docs/branches-and-secrets.md, "Growing and switching":
`eden garden use <name>` records the garden in view in
`~/.local/state/eden/garden` and runs the hooks branches graft into
`~/.config/eden/garden.d/`, which reload what cannot read the state
itself. Readers that read the state on each use need nothing.

Still to build: `use` re-running the MCP grafter, for the garden's MCP
servers outside a repo.

## Deferred, and why

| Deferred | Needed only when |
|---|---|
| Removing what an unregistered branch grafted (link scan, record of merged entries) | a branch stops being grafted on a machine — rare, since gardens stay grafted. `eden doctor` reports leftovers meanwhile. The MCP grafter keeps its own record, for garden MCP servers. |
| Branch kinds and precedence | a branch must override another's output. None does today: no branch grafts a path the trunk plants. |
| Check before apply (grafter API v2, plan mode) | collisions can't be caught inside each grafter. The runner accepts exactly one API version (bin/eden-graft:50), so a v2 must either move all grafters in one change or first teach the runner to accept both. |
| A Claude configuration folder per garden (`CLAUDE_CONFIG_DIR`) | two gardens need separate Claude accounts. Claude Code documents the variable for running accounts side by side. |

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

- ARCHITECTURE.md: Branches (gardens, shared branches, `.eden-gardens`), Layering Guidance (the
  three levels), Constraints (grafting and removal).
- docs/grafters.md: the collision rule, platform gating, identities by
  remote, project MCP servers in local scope, garden MCP servers.
- docs/branches-and-secrets.md: "Context Switching" becomes gardens;
  setup with `eden init` and `eden garden add`; secrets name their
  account.

## Open questions

1. *Settled:* platform-only parts live in a branch's `platforms/<platform>/`
   folder, with the trunk's names, `mac` and `arch`.
2. *Settled:* the state is `~/.local/state/eden/garden` and the command
   `eden garden`; readers read the state on each use, and hooks in
   `~/.config/eden/garden.d/` reload the rest.
3. *Settled:* Cursor is no longer supported, so only Claude Code's local
   scope matters.
4. The data format for keys, and whether renderers live in the trunk or
   in platform branches.
5. Where machine-specific facts live (network, window positions,
   checkout paths): a tracked branch per machine, or the untracked
   `~/.config/eden/local/`.
