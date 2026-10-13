#!/usr/bin/env bats
# setup_suite.bash clears the GIT_DIR git hands what `git rebase --exec`,
# `git bisect run` and git hooks run in a linked worktree. Without it
# this suite's git — init, commit, remote add — writes into the
# repository that GIT_DIR names: elsewhere that set core.bare=true on a
# real repository. A file whose fixtures run git, run under a GIT_DIR
# pointed at a canary, must leave the canary as it was.

@test "the suite ignores an inherited GIT_DIR" {
  canary="$BATS_TEST_TMPDIR/canary"
  git init -q "$canary"
  GIT_DIR="$canary/.git" bats "$BATS_TEST_DIRNAME/identities.bats" >"$BATS_TEST_TMPDIR/out" 2>&1 || {
    cat "$BATS_TEST_TMPDIR/out"
    return 1
  }
  refs="$(git -C "$canary" for-each-ref)"
  [ -z "$refs" ]
  [ "$(git -C "$canary" config --get core.bare)" = false ]
  [ -z "$(git -C "$canary" config --get-regexp '^remote\.' || true)" ]
}
