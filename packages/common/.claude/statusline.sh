#!/usr/bin/env bash
# Claude Code status line — flex layout, ANSI-aware width, git cache, rate-limit countdowns
set -uo pipefail

INPUT=$(cat)
NOW=$(date +%s)

mapfile -t FIELDS < <(jq -r '
  (.model.display_name // .model.id // "?"),
  (.workspace.current_dir // ""),
  (.workspace.git_worktree // ""),
  ((.context_window.used_percentage // 0) | floor),
  (.cost.total_cost_usd // 0),
  (.effort.level // ""),
  (.thinking.enabled // false),
  (.session_id // "default"),
  ((.rate_limits.five_hour.used_percentage // 0) | floor),
  (.rate_limits.five_hour.resets_at // 0),
  ((.rate_limits.seven_day.used_percentage // 0) | floor),
  (.rate_limits.seven_day.resets_at // 0)
' <<<"$INPUT")
MODEL=${FIELDS[0]}
DIR_FULL=${FIELDS[1]}
WORKTREE=${FIELDS[2]}
CTX_PCT=${FIELDS[3]}
COST=${FIELDS[4]}
EFFORT=${FIELDS[5]}
THINKING=${FIELDS[6]}
SESSION=${FIELDS[7]}
FIVE_PCT=${FIELDS[8]}
FIVE_RESET=${FIELDS[9]}
SEVEN_PCT=${FIELDS[10]}
SEVEN_RESET=${FIELDS[11]}

C_RESET=$'\033[0m'
C_DIM=$'\033[2m'
C_BOLD=$'\033[1m'
C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'
C_RED=$'\033[31m'
C_CYAN=$'\033[36m'
C_BLUE=$'\033[34m'
C_MAGENTA=$'\033[35m'

visible_len() {
  local s
  s=$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g')
  printf '%d' "${#s}"
}

color_pct() {
  local p=$1
  if   (( p >= 90 )); then printf '%s' "$C_RED"
  elif (( p >= 70 )); then printf '%s' "$C_YELLOW"
  else                     printf '%s' "$C_GREEN"
  fi
}

bar() {
  local p=$1 cells=8 i out=""
  local filled=$(( p * cells / 100 ))
  (( filled > cells )) && filled=$cells
  for ((i=0; i<cells; i++)); do
    if (( i < filled )); then out+="▓"; else out+="░"; fi
  done
  printf '%s' "$out"
}

fmt_countdown() {
  local until=$1 diff=$(( $1 - NOW ))
  (( diff <= 0 )) && { printf 'now'; return; }
  local h=$(( diff / 3600 )) m=$(( (diff % 3600) / 60 ))
  if (( h > 0 )); then printf '%dh%dm' "$h" "$m"; else printf '%dm' "$m"; fi
}

CACHE_FILE="${TMPDIR:-/tmp}/cc-statusline-git-${SESSION}"
git_branch() {
  if [ -f "$CACHE_FILE" ]; then
    local mtime
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
    if (( NOW - mtime < 5 )); then cat "$CACHE_FILE"; return; fi
  fi
  local branch=""
  if [ -n "$DIR_FULL" ] && [ -d "$DIR_FULL" ]; then
    branch=$(cd "$DIR_FULL" && git branch --show-current 2>/dev/null) || branch=""
  fi
  printf '%s' "$branch" > "$CACHE_FILE" 2>/dev/null || true
  printf '%s' "$branch"
}

DIR=$(basename "${DIR_FULL:-$PWD}")
BRANCH=$(git_branch)
MODEL_SHORT="${MODEL%% (*}"

LEFT="${C_BOLD}${C_CYAN}[${MODEL_SHORT}]${C_RESET}"
LEFT+=" ${C_MAGENTA}${DIR}${C_RESET}"
[ -n "$WORKTREE" ] && LEFT+=" ${C_DIM}⌥${C_RESET} ${WORKTREE}"
[ -n "$BRANCH" ]   && LEFT+=" ${C_DIM}⎇${C_RESET} ${C_BLUE}${BRANCH}${C_RESET}"
[ "$THINKING" = "true" ] && LEFT+=" ${C_YELLOW}●${C_RESET}"
if [ -n "$EFFORT" ] && [ "$EFFORT" != "default" ] && [ "$EFFORT" != "null" ]; then
  LEFT+=" ${C_DIM}${EFFORT}${C_RESET}"
fi

CTX_COLOR=$(color_pct "$CTX_PCT")
RIGHT="${C_DIM}ctx${C_RESET} ${CTX_COLOR}$(bar "$CTX_PCT") ${CTX_PCT}%${C_RESET}"

if awk "BEGIN{exit !($COST > 0)}"; then
  COST_FMT=$(printf '%.2f' "$COST")
  RIGHT+=" ${C_DIM}│${C_RESET} ${C_GREEN}\$${COST_FMT}${C_RESET}"
fi

if (( FIVE_PCT > 0 )); then
  RIGHT+=" ${C_DIM}│${C_RESET} "
  FIVE_COLOR=$(color_pct "$FIVE_PCT")
  RIGHT+="${C_DIM}5h${C_RESET} ${FIVE_COLOR}${FIVE_PCT}%${C_RESET}"
  (( FIVE_RESET > NOW )) && RIGHT+="${C_DIM}($(fmt_countdown "$FIVE_RESET"))${C_RESET}"
fi
if (( SEVEN_PCT >= 70 )); then
  SEVEN_COLOR=$(color_pct "$SEVEN_PCT")
  RIGHT+=" ${C_DIM}·${C_RESET} ${C_DIM}7d${C_RESET} ${SEVEN_COLOR}${SEVEN_PCT}%${C_RESET}"
  (( SEVEN_RESET > NOW )) && RIGHT+="${C_DIM}($(fmt_countdown "$SEVEN_RESET"))${C_RESET}"
fi

detect_cols() {
  if [ -n "${COLUMNS:-}" ] && [ "${COLUMNS:-0}" -gt 0 ] 2>/dev/null; then
    printf '%d' "$COLUMNS"; return
  fi
  if [ -r /dev/tty ]; then
    local size
    size=$(stty size </dev/tty 2>/dev/null) && {
      printf '%d' "${size##* }"; return
    }
  fi
  tput cols 2>/dev/null || printf '120'
}
COLS=$(detect_cols)
RESERVED_RIGHT=30
COLS=$(( COLS - RESERVED_RIGHT ))

LEFT_LEN=$(visible_len "$LEFT")
RIGHT_LEN=$(visible_len "$RIGHT")
PAD=$(( COLS - LEFT_LEN - RIGHT_LEN ))
(( PAD < 1 )) && PAD=1

printf '%s%*s%s\n' "$LEFT" "$PAD" '' "$RIGHT"
