# Contributing

```sh
brew install bats-core shellcheck        # Arch: sudo pacman -S bats shellcheck
bash -c "trap '' PIPE; bats tests/bats"  # the bats suite, as CI runs it
shellcheck --severity=error bin/eden bin/eden-* install.sh get-eden.sh lib/*.sh \
  packages/eden/.eden/libexec/grafters/graft-*
eden doctor
```

CI ignores SIGPIPE, so a reader that stops early (`| head`, `| grep -q`)
leaves its writer a `write error: Broken pipe` that a terminal never
shows. Running the suite under `trap '' PIPE` catches it before CI does.

Commits are conventional (`type(scope): description`): the changelog
is generated from them.
