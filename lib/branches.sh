# shellcheck shell=bash
# branches.sh — the one reader of Eden's branch list.
#
# Source it after EDEN_ROOT is set:
#
#   source "$EDEN_ROOT/lib/branches.sh"
#
#   eden_branches_file          the list's path
#   eden_branch_list_exists     whether a branch list is set up at all
#   eden_branch_expand <entry>  an entry as an absolute path
#   eden_branches               every branch to graft, one per line, in order:
#                               from the gardens when they are set up, else
#                               from the list
#   eden_platform               this machine's platform: mac or arch
#   eden_graft_roots            what grafters walk: each entry, followed by
#                               its platforms/<platform>/ folder if it has one
#   eden_branch_name <root>     a root's name for messages: the folder name,
#                               or "<branch> (<platform>)" for a platform folder
#   eden_project_target <file>  a project's repo: the first path in its
#                               .eden-target that exists (else the first, exit 1)
#
# An entry is one line. Blank lines and lines whose first non-blank
# character is `#` are skipped. Surrounding whitespace is ignored, a
# trailing slash is dropped, and three forms are expanded: a leading `~`,
# `$EDEN_ROOT` and `$HOME` (with or without braces). Nothing else is
# evaluated. A last line without a newline is read like any other.
#
# Gardens, when set up, replace the list:
#
#   eden_branches_repo_file              where the repo eden init pointed at is kept
#   eden_grown_file             the gardens this machine grows, one per line
#   eden_garden_state_file      the garden in view
#   eden_branches_repo                   that repo, when it has a .eden-gardens
#   eden_branches_repo_problem  why the repo recorded there is not usable
#                               (exit 1 when it is, or none is recorded)
#   eden_gardens_file           its .eden-gardens
#   eden_gardens_entries        every line of it: section<TAB>path<TAB>platform
#   eden_gardens_declared       the gardens it declares, in order
#   eden_gardens_grown          the gardens this machine grows
#   eden_garden_in_view         the garden in view (exit 1 if none)
#   eden_garden_of <root>       the section a graft root's branch is listed
#                               in, shared included (exit 1 if none)
#   eden_in_view <root>         whether what a root declares for its garden
#                               applies now: always without gardens and for
#                               shared branches, else while its garden is in
#                               view
#
# .eden-gardens is a [shared] section and one section per garden. Each
# line is a branch folder relative to the file, optionally followed by
# the one platform it is grafted on (mac or arch). Blank lines and #
# lines are skipped, and so is a # comment after whitespace at the end of
# a line.

eden_branches_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/eden/branches"
}

eden_branch_expand() {
    local p="$1"
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    p="${p//\$\{EDEN_ROOT\}/$EDEN_ROOT}"
    p="${p//\$EDEN_ROOT/$EDEN_ROOT}"
    p="${p//\$\{HOME\}/$HOME}"
    p="${p//\$HOME/$HOME}"
    # shellcheck disable=SC2088  # a literal ~ is what is being matched
    if [[ "$p" == "~" || "$p" == "~/"* ]]; then
        p="$HOME${p:1}"
    fi
    if [[ "$p" != "/" ]]; then
        p="${p%/}"
    fi
    printf '%s\n' "$p"
}

# Once eden init has recorded a branches repo, the gardens are the list:
# a recorded repo that has no .eden-gardens (moved, or the file gone)
# leaves no list rather than an old branches file.
eden_branch_list_exists() {
    if eden_branches_repo_named >/dev/null; then
        eden_branches_repo >/dev/null
        return
    fi
    [[ -f "$(eden_branches_file)" ]]
}

eden_branches() {
    if eden_branches_repo_named >/dev/null; then
        if eden_branches_repo >/dev/null; then
            eden_garden_branches
        fi
        return 0
    fi
    local file line
    file="$(eden_branches_file)"
    [[ -f "$file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        eden_branch_expand "$line"
    done < "$file"
}

eden_branches_repo_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/eden/branches-repo"
}

eden_grown_file() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/eden/gardens"
}

eden_garden_state_file() {
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/eden/garden"
}

# eden_lines <file>: its entries, trimmed, blank and # lines skipped.
eden_lines() {
    local line
    [[ -f "$1" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        line="${line#"${line%%[![:space:]]*}"}"
        printf '%s\n' "${line%"${line##*[![:space:]]}"}"
    done < "$1"
}

# eden_gardens_lines <file>: its lines as eden_lines gives them, a
# trailing " # comment" taken off.
eden_gardens_lines() {
    local line
    while IFS= read -r line; do
        if [[ "$line" =~ ^(.*[^[:space:]])[[:space:]]+#.*$ ]]; then
            line="${BASH_REMATCH[1]}"
        fi
        printf '%s\n' "$line"
    done < <(eden_lines "$1")
}

# eden_branches_repo_named: the repo eden init recorded, usable or not.
eden_branches_repo_named() {
    local repo
    # The whole list, then its first line: a reader that stops early
    # leaves the writer a broken pipe, which it reports where SIGPIPE is
    # ignored (CI runners, some launchers).
    repo="$(eden_lines "$(eden_branches_repo_file)")"
    repo="${repo%%$'\n'*}"
    [[ -n "$repo" ]] || return 1
    eden_branch_expand "$repo"
}

eden_branches_repo() {
    local repo
    repo="$(eden_branches_repo_named)" || return 1
    [[ -f "$repo/.eden-gardens" ]] || return 1
    printf '%s\n' "$repo"
}

eden_branches_repo_problem() {
    local repo file
    repo="$(eden_branches_repo_named)" || return 1
    [[ -f "$repo/.eden-gardens" ]] && return 1
    file="$(eden_branches_repo_file)"
    # shellcheck disable=SC2088  # the ~ is shown to the reader
    [[ "$file" == "$HOME"/* ]] && file="~${file#"$HOME"}"
    printf '%s names %s, which has no .eden-gardens: if the repo moved, run eden init <its new path>\n' "$file" "$repo"
}

eden_gardens_file() {
    local repo
    repo="$(eden_branches_repo)" || return 1
    printf '%s\n' "$repo/.eden-gardens"
}

eden_gardens_entries() {
    local repo line section="" folder platform
    repo="$(eden_branches_repo)" || return 0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[([^]]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        [[ -n "$section" ]] || continue
        read -r folder platform _ <<< "$line"
        folder="$(eden_branch_expand "$folder")"
        [[ "$folder" == /* ]] || folder="$repo/$folder"
        printf '%s\t%s\t%s\n' "$section" "$folder" "$platform"
    done < <(eden_gardens_lines "$repo/.eden-gardens")
}

# A garden is declared by its section, with or without branches yet.
eden_gardens_declared() {
    local file line section seen=$'\n'
    file="$(eden_gardens_file)" || return 0
    while IFS= read -r line; do
        [[ "$line" =~ ^\[([^]]+)\]$ ]] || continue
        section="${BASH_REMATCH[1]}"
        [[ "$section" == shared ]] && continue
        [[ "$seen" == *$'\n'"$section"$'\n'* ]] && continue
        seen+="$section"$'\n'
        printf '%s\n' "$section"
    done < <(eden_gardens_lines "$file")
}

eden_gardens_grown() {
    eden_lines "$(eden_grown_file)"
}

eden_garden_in_view() {
    local name
    name="$(eden_lines "$(eden_garden_state_file)")"
    name="${name%%$'\n'*}"
    [[ -n "$name" ]] || return 1
    printf '%s\n' "$name"
}

eden_garden_of() {
    local root="${1%/}" entries section path
    if [[ "$(basename "$(dirname "$root")")" == platforms ]]; then
        root="$(dirname "$(dirname "$root")")"
    fi
    # Read whole before the loop returns early: see eden_branches_repo.
    entries="$(eden_gardens_entries)"
    while IFS=$'\t' read -r section path _; do
        if [[ "$path" == "$root" ]]; then
            printf '%s\n' "$section"
            return 0
        fi
    done <<< "$entries"
    return 1
}

eden_in_view() {
    local garden here
    garden="$(eden_garden_of "$1")" || return 0
    [[ "$garden" == shared ]] && return 0
    here="$(eden_garden_in_view)" || return 1
    [[ "$garden" == "$here" ]]
}

# The shared branches for this platform, then each grown garden's, in the
# order .eden-gardens lists them; a branch listed twice is printed once.
eden_garden_branches() {
    local here grown section path platform pass printed=$'\n'
    here="$(eden_platform)" || here=""
    grown=$'\n'"$(eden_gardens_grown)"$'\n'
    for pass in shared gardens; do
        while IFS=$'\t' read -r section path platform; do
            if [[ "$pass" == shared ]]; then
                [[ "$section" == shared ]] || continue
            else
                [[ "$section" != shared && "$grown" == *$'\n'"$section"$'\n'* ]] || continue
            fi
            [[ -z "$platform" || "$platform" == "$here" ]] || continue
            [[ "$printed" == *$'\n'"$path"$'\n'* ]] && continue
            printed+="$path"$'\n'
            printf '%s\n' "$path"
        done < <(eden_gardens_entries)
    done
}

# The trunk's names for its platform packages (packages/mac, packages/arch).
# EDEN_PLATFORM overrides the detection.
eden_platform() {
    if [[ -n "${EDEN_PLATFORM:-}" ]]; then
        printf '%s\n' "$EDEN_PLATFORM"
        return 0
    fi
    case "$(uname -s)" in
        Darwin) echo mac ;;
        Linux) echo arch ;;
        *) return 1 ;;
    esac
}

# A branch's parts for one platform live in platforms/<platform>/, which
# mirrors $HOME like the branch itself and is grafted right after it, on
# that platform only.
eden_graft_roots() {
    local branch platform
    platform="$(eden_platform)" || platform=""
    while IFS= read -r branch; do
        printf '%s\n' "$branch"
        if [[ -n "$platform" && -d "$branch/platforms/$platform" ]]; then
            printf '%s\n' "$branch/platforms/$platform"
        fi
    done < <(eden_branches)
}

eden_branch_name() {
    local root="${1%/}"
    if [[ "$(basename "$(dirname "$root")")" == platforms ]]; then
        printf '%s (%s)\n' "$(basename "$(dirname "$(dirname "$root")")")" "$(basename "$root")"
    else
        basename "$root"
    fi
}

# A project's .eden-target names where its repo is checked out, one path
# per line (blank and # lines skipped, expanded as branch entries are).
# Machines check a repo out in different places, so the first path that
# exists here wins. With none, the first is printed and the status is 1.
eden_project_target() {
    local line path first=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        path="$(eden_branch_expand "$line")"
        [[ -z "$first" ]] && first="$path"
        if [[ -d "$path" ]]; then
            printf '%s\n' "$path"
            return 0
        fi
    done < "$1"
    printf '%s\n' "$first"
    return 1
}
