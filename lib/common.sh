#!/bin/bash

# ============================================================================
# STRIVE-CLI: Shared UI Engine (lib/common.sh)
#
# A Striving Designs open-source tool — strivingdesigns.com
# Built by Prayas Shrestha · github.com/prayasshr/strive-cli
# License: MIT
#
# Sourced by all Strive CLI tools to provide shared colors, utilities,
# and the live terminal dashboard (render_dashboard).
# ============================================================================

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Wraps tput to no-op silently in non-interactive environments (CI, Docker, etc.)
safe_tput() {
    if command -v tput >/dev/null 2>&1; then
        tput "$@"
    fi
}

get_power_icon() {
    local icon="[⚡]"
    if command -v pmset >/dev/null 2>&1; then
        if pmset -g batt | grep -q "Battery Power"; then
            icon="[🔋]"
        fi
    fi
    echo "$icon"
}

get_relative_time() {
    local last_time=$1
    local now=$(date +%s)
    local diff=$((now - last_time))
    if   [ $diff -lt 60 ];    then echo "${diff}s ago"
    elif [ $diff -lt 3600 ];  then echo "$((diff / 60))m ago"
    elif [ $diff -lt 86400 ]; then echo "$((diff / 3600))h ago"
    else                           echo "$((diff / 86400))d ago"
    fi
}

# Writes a repo's current status string to its file in $STATUS_DIR.
# Called by workers — never write to stdout from a worker directly, as it
# will corrupt the dashboard's cursor position arithmetic.
update_status() {
    local id=$1
    local status_text=$2
    local status_file=$(echo "$id" | sed 's|/|__|g')
    [ "$id" == "." ] && status_file="__root__"
    echo -e "$status_text" > "$STATUS_DIR/$status_file"
}

# Live terminal HUD — runs as a background job (`render_dashboard &`).
#
# Reserves vertical space, then loops every 200ms reading $STATUS_DIR files
# and redrawing the block in-place using cursor-up escape sequences.
#
# SIGNAL: the main script deletes $STATUS_DIR/active to stop the loop.
# The main script then calls `wait $DASHBOARD_PID` — NOT sleep+kill — so the
# final render pass completes before anything else prints. A premature kill
# leaves the cursor mid-block, causing subsequent output to overwrite repo rows.
#
# Caller must set: $STATUS_DIR, $REPOS, $VERSION, $LAST_MISSION_STR,
#                  $BATT_ICON, $MISSION_TITLE
render_dashboard() {
    local num_items=${#REPOS[@]}
    local header_lines=4

    safe_tput civis 2>/dev/null

    # Reserve vertical space in the terminal for the HUD block
    for (( i=0; i < num_items + header_lines; i++ )); do echo ""; done

    while [ -f "$STATUS_DIR/active" ]; do
        printf "\033[%dA" "$((num_items + header_lines))"

        local contents=$(cat "$STATUS_DIR"/* 2>/dev/null)
        local success_count=$(echo "$contents" | grep -cE '\[SYNCED  \]|\[SUCCESS \]')
        local dirty_count=$(echo "$contents"   | grep -c  '\[DIRTY   \]')
        local failed_count=$(echo "$contents"  | grep -cE '\[FAILED  \]|\[MISSING \]|\[OUT SYNC\]')

        [ -z "$success_count" ] && success_count=0
        [ -z "$dirty_count"   ] && dirty_count=0
        [ -z "$failed_count"  ] && failed_count=0

        local resolved_count=$((success_count + dirty_count + failed_count))
        local pct=0
        [ "$num_items" -gt 0 ] && pct=$(( resolved_count * 100 / num_items ))

        local filled=$(( pct / 10 ))
        local bar="["
        for ((b=0; b < filled;       b++)); do bar+="▆"; done
        for ((b=0; b < 10 - filled;  b++)); do bar+="░"; done
        bar+="]"

        local bar_color="${GREEN}"
        [ "$failed_count" -gt 0 ] && bar_color="${RED}"
        [ "$dirty_count"  -gt 0 ] && [ "$failed_count" -eq 0 ] && bar_color="${YELLOW}"

        # \033[K erases to end of line — clears stale chars from previous renders
        echo -e "${CYAN}${BOLD}${BATT_ICON} $MISSION_TITLE${NC} | v$VERSION\033[K"
        echo -e "${PURPLE}${LAST_MISSION_STR}${NC}\033[K"
        echo -e "${BOLD}HEALTH: ${bar_color}${bar}${NC} ${BOLD}${pct}% | SYNCED: ${success_count} | DIRTY: ${dirty_count} | FAILED: ${failed_count}${NC}\033[K"
        echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}\033[K"

        for (( i=0; i < num_items; i++ )); do
            local item="${REPOS[$i]}"
            local display_name="$item"
            [ "$item" == "." ] && display_name=$(basename "$PWD")
            local status_file=$(echo "$item" | sed 's|/|__|g')
            [ "$item" == "." ] && status_file="__root__"
            local status
            status=$(cat "$STATUS_DIR/$status_file" 2>/dev/null \
                     || echo -e "${NC}[WAITING ] Waiting...${NC}")
            printf "   %-15s | %b\033[K\n" "$display_name" "$status"
        done

        sleep 0.2
    done

    # Final render — locks in the terminal state before cleanup prints below it
    printf "\033[%dA" "$((num_items + header_lines))"

    local contents=$(cat "$STATUS_DIR"/* 2>/dev/null)
    local success_count=$(echo "$contents" | grep -cE '\[SYNCED  \]|\[SUCCESS \]')
    local dirty_count=$(echo "$contents"   | grep -c  '\[DIRTY   \]')
    local failed_count=$(echo "$contents"  | grep -cE '\[FAILED  \]|\[MISSING \]|\[OUT SYNC\]')

    [ -z "$success_count" ] && success_count=0
    [ -z "$dirty_count"   ] && dirty_count=0
    [ -z "$failed_count"  ] && failed_count=0

    local resolved_count=$((success_count + dirty_count + failed_count))
    local pct=0
    [ "$num_items" -gt 0 ] && pct=$(( resolved_count * 100 / num_items ))

    local filled=$(( pct / 10 ))
    local bar="["
    for ((b=0; b < filled;       b++)); do bar+="▆"; done
    for ((b=0; b < 10 - filled;  b++)); do bar+="░"; done
    bar+="]"

    local bar_color="${GREEN}"
    [ "$failed_count" -gt 0 ] && bar_color="${RED}"
    [ "$dirty_count"  -gt 0 ] && [ "$failed_count" -eq 0 ] && bar_color="${YELLOW}"

    echo -e "${CYAN}${BOLD}${BATT_ICON} $MISSION_TITLE${NC} | v$VERSION\033[K"
    echo -e "${PURPLE}${LAST_MISSION_STR}${NC}\033[K"
    echo -e "${BOLD}HEALTH: ${bar_color}${bar}${NC} ${BOLD}${pct}% | SYNCED: ${success_count} | DIRTY: ${dirty_count} | FAILED: ${failed_count}${NC}\033[K"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}\033[K"

    for (( i=0; i < num_items; i++ )); do
        local item="${REPOS[$i]}"
        local display_name="$item"
        [ "$item" == "." ] && display_name=$(basename "$PWD")
        local status_file=$(echo "$item" | sed 's|/|__|g')
        [ "$item" == "." ] && status_file="__root__"
        local status
        status=$(cat "$STATUS_DIR/$status_file" 2>/dev/null \
                 || echo -e "${NC}[WAITING ] Waiting...${NC}")
        printf "   %-15s | %b\033[K\n" "$display_name" "$status"
    done

    safe_tput cnorm 2>/dev/null
}
