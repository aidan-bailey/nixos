#!/usr/bin/env bash
# Claude Code status line
# Line 1: [Model] hostname | repo (clickable) | branch +staged ~modified
# Line 2: context bar PCT% | +added/-removed lines

input=$(cat)

# --- Extract JSON fields ---
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# --- Colors ---
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
MAGENTA='\033[35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Hostname ---
HOST=$(hostname -s 2>/dev/null || hostname)

# --- Git info (cached) ---
CACHE_FILE="/tmp/claude-statusline-git-cache-$(echo "$DIR" | md5sum | cut -d' ' -f1)"
CACHE_MAX_AGE=5

cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
    if git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
        BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null)
        STAGED=$(git -C "$DIR" diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
        MODIFIED=$(git -C "$DIR" diff --numstat 2>/dev/null | wc -l | tr -d ' ')
        REMOTE=$(git -C "$DIR" remote get-url origin 2>/dev/null \
            | sed 's/git@github\.com:/https:\/\/github.com\//' \
            | sed 's/git@gitlab\.com:/https:\/\/gitlab.com\//' \
            | sed 's/\.git$//')
        echo "${BRANCH}|${STAGED}|${MODIFIED}|${REMOTE}" > "$CACHE_FILE"
    else
        echo "|||" > "$CACHE_FILE"
    fi
fi

IFS='|' read -r BRANCH STAGED MODIFIED REMOTE < "$CACHE_FILE"

# --- Line 1: [Model] hostname | repo | branch +staged ~modified ---
LINE1="${CYAN}[${MODEL}]${RESET} ${MAGENTA}${HOST}${RESET}"

# Clickable repo link (OSC 8)
if [ -n "$REMOTE" ]; then
    REPO_NAME=$(basename "$REMOTE")
    LINE1="${LINE1} ${DIM}|${RESET} \e]8;;${REMOTE}\a${CYAN}${REPO_NAME}\e]8;;\a"
fi

# Branch and git status
if [ -n "$BRANCH" ]; then
    LINE1="${LINE1} ${DIM}|${RESET} ${GREEN}${BRANCH}${RESET}"
    [ "$STAGED" -gt 0 ] 2>/dev/null && LINE1="${LINE1} ${GREEN}+${STAGED}${RESET}"
    [ "$MODIFIED" -gt 0 ] 2>/dev/null && LINE1="${LINE1} ${YELLOW}~${MODIFIED}${RESET}"
fi

printf '%b\n' "$LINE1"

# --- Line 2: context bar | lines changed ---
if [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | tr ' ' '█')
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

LINE2="${BAR_COLOR}${BAR}${RESET} ${PCT}%"

# Lines changed
if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
    LINE2="${LINE2} ${DIM}|${RESET} ${GREEN}+${LINES_ADDED}${RESET}/${RED}-${LINES_REMOVED}${RESET} lines"
fi

printf '%b\n' "$LINE2"
