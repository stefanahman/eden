# Runs once before every file in this directory (bats >= 1.5).
#
# git hands an absolute GIT_DIR to what `git rebase --exec`, `git bisect
# run` and git hooks run in a linked worktree, and this suite's git —
# init, commit, remote add — then acts on the repository the suite was
# run from instead of its fixtures. Elsewhere that set core.bare=true on
# two real repositories, with stray commits and refs. git names the
# variables that point it at a repository itself.
setup_suite() {
  local name
  for name in $(git rev-parse --local-env-vars); do
    unset "$name"
  done
}
