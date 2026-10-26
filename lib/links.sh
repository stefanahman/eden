# shellcheck shell=bash
# Taking out the broken links a graft leaves behind.
#
# A grafter links files from a branch into $HOME. When a file leaves the
# branch — a skill retired, a script deleted — its link is left pointing
# at nothing. eden_links_clean takes such links out of the folders a
# grafter fills: a link whose own target is not there, and which points
# into a branch grafted here and on disk. A broken link carries nothing,
# so taking one out cannot lose anything. Left alone:
#   - a working link, and a real file;
#   - a link to a branch entry that is itself a link, broken further on:
#     the entry is there, and is the branch's;
#   - a broken link that points anywhere else, or into a branch whose
#     folder is not here — renamed, on a volume not mounted — since the
#     branch may come back, and its link is what holds the path;
#   - a link a folder below, and anything in a folder that resolves into
#     a branch — grafted here or not, any folder under an .eden-graft —
#     since what is in a branch's own folder is the branch's.
# Where a link points is worked out as the system resolves it: links on
# the way are followed, and a `..` that cannot be resolved says nothing.
#
# This is dotbot's `clean`, which removes the dead links that point into
# the dotfiles directory from the folders it is given. It keeps no record
# of what was linked, so a link left by any earlier graft goes the same
# way. What it cannot see is a folder no grafter names any more — a
# project gone from its branch, an .eden-graft entry gone with no other
# entry in its folder — and a working link no branch declares any more,
# which is not broken.
#
# Needs lib/branches.sh and lib/collisions.sh sourced first. Bash 3.2 and
# 5: `eden graft` runs grafters with the bash on PATH, which is /bin/bash
# 3.2 on a Mac without Homebrew's.

# _eden_links_branches: the branches grafted here that are on disk, one
# per line as "resolved<TAB>registered": matched by where a branch is,
# named as it is registered. Read whole, so no reader stops a writer half
# way.
_eden_links_branches() {
    local roots root real
    roots="$(eden_graft_roots)"
    while IFS= read -r root; do
        [[ -n "$root" ]] || continue
        real="$(cd -P "$root" 2>/dev/null && pwd -P || true)"
        if [[ -n "$real" ]]; then
            printf '%s\t%s\n' "$real" "$root"
        fi
    done <<< "$roots"
    return 0
}

# _eden_links_inside <path> <branches>: the branch a resolved path is in,
# as registered — the longest that holds it, so a platform folder is
# named, not its branch.
_eden_links_inside() {
    local path="$1" branches="$2" real root best="" name=""
    while IFS=$'\t' read -r real root; do
        [[ -n "$real" ]] || continue
        if [[ "$path" == "$real" || "$path" == "$real"/* ]] && [[ ${#real} -gt ${#best} ]]; then
            best="$real"
            name="$root"
        fi
    done <<< "$branches"
    [[ -n "$best" ]] || return 1
    printf '%s\n' "$name"
}

# _eden_links_under_eden_graft <path>: whether a resolved path is in a
# branch, grafted here or not: at or under a folder with an .eden-graft.
# eden doctor's branch_root_of walks the same way.
_eden_links_under_eden_graft() {
    local d="$1"
    while [[ -n "$d" && "$d" != "/" ]]; do
        [[ ! -f "$d/.eden-graft" ]] || return 0
        d="$(dirname "$d")"
    done
    return 1
}

# _eden_links_resolved <path>: where the system finds path: its nearest
# folder that exists, resolved as the system does (cd -P, so a `..` after
# a link goes where the link went), and the rest as written. A `.` or
# `..` in the rest, or a link on the way that does not resolve — broken,
# or a loop — cannot be followed, and the answer is nothing; so is a path
# that ends in a slash, which the caller strips.
_eden_links_resolved() {
    local p="$1" d rest part real
    part="${p##*/}"
    [[ -n "$part" && "$part" != "." && "$part" != ".." ]] || return 1
    rest="/$part"
    d="$(dirname "$p")"
    while [[ ! -d "$d" && "$d" != "/" && "$d" != "." ]]; do
        [[ ! -L "$d" ]] || return 1
        part="${d##*/}"
        [[ "$part" != "." && "$part" != ".." ]] || return 1
        rest="/$part$rest"
        d="$(dirname "$d")"
    done
    real="$(cd -P "$d" 2>/dev/null && pwd -P)" || return 1
    printf '%s%s\n' "${real%/}" "$rest"
}

# _eden_links_broken_into <link> <branches>: the branch a broken link
# points into, if any. Broken means its own target is not there: one that
# is itself a link, however that one ends, is there.
_eden_links_broken_into() {
    local link="$1" target
    target="$(readlink "$link")" || return 1
    [[ "$target" == /* ]] || target="$(dirname "$link")/$target"
    # A trailing slash would make -L follow the target and -e want a
    # folder: it is no part of the name.
    while [[ "$target" == */ && "$target" != / ]]; do
        target="${target%/}"
    done
    [[ ! -e "$target" && ! -L "$target" ]] || return 1
    target="$(_eden_links_resolved "$target")" || return 1
    _eden_links_inside "$target" "$2"
}

# eden_links_clean <folder>...: in each folder, not below it, take out the
# broken links that point into a branch grafted here, and say so. A folder
# named twice, or spelled two ways, is cleaned once. A link that will not
# go is said on stderr.
eden_links_clean() {
    local branches folder real seen=$'\n' link root
    branches="$(_eden_links_branches)"
    [[ -n "$branches" ]] || return 0
    for folder in "$@"; do
        [[ -n "$folder" && -d "$folder" ]] || continue
        real="$(cd -P "$folder" 2>/dev/null && pwd -P)" || continue
        [[ "$seen" != *$'\n'"$real"$'\n'* ]] || continue
        seen+="$real"$'\n'
        if _eden_links_inside "$real" "$branches" > /dev/null || _eden_links_under_eden_graft "$real"; then
            continue
        fi
        for link in "$folder"/* "$folder"/.[!.]* "$folder"/..?*; do
            [[ -L "$link" && ! -e "$link" ]] || continue
            root="$(_eden_links_broken_into "$link" "$branches")" || continue
            if rm -f -- "$link" 2>/dev/null && [[ ! -L "$link" ]]; then
                echo "  × $(eden_home_path "$link") [removed: broken link into $(eden_branch_name "$root")]"
            else
                echo "  ⚠ $(eden_home_path "$link") is a broken link into $(eden_branch_name "$root") and could not be removed" >&2
            fi
        done
    done
    return 0
}
