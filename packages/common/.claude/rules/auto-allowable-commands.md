# Auto-allowable Commands

Goal: maximize unattended runs by preferring commands that can be auto-allowed via simple prefix rules. Some tools have flags that execute arbitrary commands or modify files (e.g. `find -exec`, `find -delete`), so a `Bash(find:*)` prefix rule cannot safely auto-allow them. When a safer equivalent exists, use it.

Destructive work (deleting, overwriting, force-pushing, etc.) is out of scope — those should prompt regardless.

## Cases

### Listing files: prefer `rg --files` over `find -name`

`rg --files -g 'pattern'` has no `-exec`/`-delete` equivalent, so `Bash(rg:*)` is safe to auto-allow. It's also faster and respects `.gitignore` by default.

Instead of:

```sh
find . -name "*.ts" -not -path "*/node_modules/*"
```

use:

```sh
rg --files -g '*.ts'
```

Use `find` only when you need behavior `rg --files` lacks (mtime filters, `-type d`, traversing past `.gitignore`).
