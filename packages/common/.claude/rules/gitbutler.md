# GitButler Integration

Eden includes GitButler hooks that fire automatically on Edit/Write operations.
They silently no-op in repos without GitButler set up (`but setup`).

## When GitButler IS active in a project

Check with `but status`. If it works, GitButler is managing this repo:

- **Never run `git commit`** — GitButler handles all commits automatically via hooks
- **Never run `git add` or `git stage`** — GitButler tracks changes itself
- Hooks fire on every Edit/Write and commit changes when the session stops
- Use `but status` to see virtual branch state
- Use `but branch new <name>` to create virtual branches
- Use `but undo` to revert any operation

## When GitButler is NOT active

Use regular git workflow. The hooks silently no-op.

## Useful `but` commands

Always pass branch names explicitly (non-interactive terminal, no prompts):

| Command | What it does |
|---------|-------------|
| `but setup` | Initialize GitButler in current repo |
| `but teardown` | Remove GitButler from current repo |
| `but status` | Show virtual branch state |
| `but branch new <name>` | Create a virtual branch |
| `but stage <file> <branch>` | Stage a file to a specific branch |
| `but commit <branch> -m "msg"` | Commit to a specific branch |
| `but rub SOURCE TARGET` | Move/squash/amend commits |
| `but undo` | Undo last operation |
| `but push <branch>` | Push branch to remote |
| `but pr new <branch> --default` | Create a pull request |

If `but pr` fails with auth error, fall back to `gh pr create --head <branch>`.
