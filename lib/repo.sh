# shellcheck shell=bash
# repo.sh — keeping the repo with the gardens up to date.
#
# Source it after lib/branches.sh:
#
#   eden_branches_repo_pull    fast-forwards the repo eden init pointed at, when it is
#                     a git checkout; prints what happened. Exit 0 when it is
#                     up to date or was updated (or there is none), 1 when it
#                     could not be pulled, 2 when it was updated.

eden_branches_repo_pull() {
    local repo before after
    repo="$(eden_branches_repo)" || return 0
    git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || return 0
    before="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
    if ! git -C "$repo" pull --ff-only --quiet >/dev/null 2>&1; then
        printf 'Could not fast-forward %s (local commits, a conflict with local changes, or no upstream); pull it by hand\n' "$repo"
        return 1
    fi
    after="$(git -C "$repo" rev-parse HEAD 2>/dev/null)"
    if [[ "$before" == "$after" ]]; then
        printf '%s is up to date\n' "$repo"
        return 0
    fi
    printf '%s updated: %s\n' "$repo" "$(git -C "$repo" log --oneline "$before..$after" | wc -l | tr -d ' ') new commit(s)"
    return 2
}
