# shellcheck shell=bash
# Collisions between branches, for grafters.
#
# Before it writes anything, a grafter lists every target it is about to
# write as "target<TAB>owner" lines and pipes them to
# eden_check_collisions. Two owners writing the same target collide, and
# so do two owners where one target sits inside the other: a link into a
# linked directory would write into the other branch. Either way the
# grafter writes nothing and fails with both owners named.
#
# An owner listed twice for one target is not a collision. Bash 3.2 and
# POSIX awk only: the Macs run grafters with /bin/bash.

# eden_collisions: reads "target<TAB>owner" lines, prints one line per
# collision, in the order the targets were first listed.
eden_collisions() {
    awk -F '\t' '
        !(($1, $2) in seen) {
            seen[$1, $2] = 1
            if (!($1 in owners)) {
                targets[++n] = $1
                owners[$1] = $2
                first[$1] = $2
            } else {
                owners[$1] = owners[$1] ", " $2
                shared[$1] = 1
            }
        }
        END {
            for (i = 1; i <= n; i++)
                if (targets[i] in shared)
                    print targets[i] " (" owners[targets[i]] ")"
            for (i = 1; i <= n; i++)
                for (j = 1; j <= n; j++) {
                    outer = targets[i]; inner = targets[j]
                    if (i != j && index(inner, outer "/") == 1 && first[outer] != first[inner])
                        print inner " (" first[inner] ") is inside " outer " (" first[outer] ")"
                }
        }'
}

# eden_check_collisions: reads "target<TAB>owner" lines; prints the
# collisions and returns 1 if there are any.
eden_check_collisions() {
    local found line
    found="$(eden_collisions)"
    [[ -z "$found" ]] && return 0
    echo "  ✗ Branches collide, so nothing was grafted here:" >&2
    while IFS= read -r line; do
        echo "    • $line" >&2
    done <<< "$found"
    echo "    Keep the entry in one branch, move it to a shared branch, or make it per repo." >&2
    return 1
}

# eden_home_path <path>: the path with $HOME shown as ~, for messages.
eden_home_path() {
    local path="$1"
    if [[ "$path" == "$HOME" || "$path" == "$HOME"/* ]]; then
        printf '~%s\n' "${path#"$HOME"}"
    else
        printf '%s\n' "$path"
    fi
}
