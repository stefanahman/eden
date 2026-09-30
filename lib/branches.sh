# shellcheck shell=bash
# branches.sh — the one reader of Eden's branch list.
#
# Source it after EDEN_ROOT is set:
#
#   source "$EDEN_ROOT/lib/branches.sh"
#
#   eden_branches_file          the list's path
#   eden_branch_expand <entry>  an entry as an absolute path
#   eden_branches               every entry, expanded, one per line, in order
#   eden_platform               this machine's platform: mac or arch
#   eden_graft_roots            what grafters walk: each entry, followed by
#                               its platforms/<platform>/ folder if it has one
#   eden_branch_name <root>     a root's name for messages: the folder name,
#                               or "<branch> (<platform>)" for a platform folder
#
# An entry is one line. Blank lines and lines whose first non-blank
# character is `#` are skipped. Surrounding whitespace is ignored, a
# trailing slash is dropped, and three forms are expanded: a leading `~`,
# `$EDEN_ROOT` and `$HOME` (with or without braces). Nothing else is
# evaluated. A last line without a newline is read like any other.

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

eden_branches() {
    local file line
    file="$(eden_branches_file)"
    [[ -f "$file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
        eden_branch_expand "$line"
    done < "$file"
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
