#!/bin/bash

# ======================================================================
# STRIVE-CLI CORE: Shared Mission Control Logic
# Common UI elements and rendering for the Strive ecosystem
# Striving Designs | Prayas Shrestha
# ======================================================================

# Branding & Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

safe_tput() {
    if command -v tput >/dev/null 2>&1; then
        tput "$@"
    fi
}

# Battery/Power Icon Detection
get_power_icon() {
    local icon="[⚡]"
    if command -v pmset >/dev/null 2>&1; then
        if pmset -g batt | grep -q "Battery Power"; then
            icon="[🔋]"
        fi
    fi
    echo "$icon"
}

# Time Relative Calculation
get_relative_time() {
    local last_time=$1
    local now=$(date +%s)
    local diff=$((now - last_time))
    
    if [ $diff -lt 60 ]; then echo "${diff}s ago"
    elif [ $diff -lt 3600 ]; then echo "$((diff/60))m ago"
    elif [ $diff -lt 86400 ]; then echo "$((diff/3600))h ago"
    else echo "$((diff/86400))d ago"; fi
}

# Update a single item status
update_status() {
    local id=$1
    local status_text=$2
    local status_file=$(echo "$id" | sed 's|/|__|g')
    [ "$id" == "." ] && status_file="__root__"
    echo -e "$status_text" > "$STATUS_DIR/$status_file"
}

# Live Dashboard Renderer (Generative)
# Requires globals: STATUS_DIR, REPOS[], VERSION, LAST_MISSION_STR, BATT_ICON
render_dashboard() {
    local num_items=${#REPOS[@]}
    tput civis 2>/dev/null # Hide cursor
    
    local header_lines=4
    # Reserve space
    for (( i=0; i<num_items + header_lines; i++ )); do echo ""; done

    while [ -f "$STATUS_DIR/active" ]; do
        # Move back up to the start of the block
        printf "\033[%dA" "$((num_items + header_lines))"
        
        # Calculate Health stats
        local contents=$(cat "$STATUS_DIR"/* 2>/dev/null)
        local success_count=$(echo "$contents" | grep -cE '\[SYNCED  \]|\[SUCCESS \]')
        local dirty_count=$(echo "$contents" | grep -c '\[DIRTY   \]')
        local failed_count=$(echo "$contents" | grep -cE '\[FAILED  \]|\[MISSING \]|\[OUT SYNC\]')
        local waiting_count=$(echo "$contents" | grep -c '\[WAITING \]')
        
        [ -z "$success_count" ] && success_count=0
        [ -z "$dirty_count" ] && dirty_count=0
        [ -z "$failed_count" ] && failed_count=0
        
        local resolved_count=$((success_count + dirty_count + failed_count))
        local pct=0
        [ "$num_items" -gt 0 ] && pct=$(( resolved_count * 100 / num_items ))
        
        local filled=$(( pct / 10 ))
        local empty=$(( 10 - filled ))
        local bar="["
        for ((b=0; b<filled; b++)); do bar+="▆"; done
        for ((b=0; b<empty; b++)); do bar+="░"; done
        bar+="]"

        local bar_color="${GREEN}"
        [ "$failed_count" -gt 0 ] && bar_color="${RED}"
        [ "$dirty_count" -gt 0 ] && [ "$failed_count" -eq 0 ] && bar_color="${YELLOW}"

        # Header
        echo -e "${CYAN}${BOLD}${BATT_ICON} $MISSION_TITLE${NC} | v$VERSION\033[K"
        echo -e "${PURPLE}${LAST_MISSION_STR}${NC}\033[K"
        echo -e "${BOLD}HEALTH: ${bar_color}${bar}${NC} ${BOLD}${pct}% | SYNCED: ${success_count} | DIRTY: ${dirty_count} | FAILED: ${failed_count}${NC}\033[K"
        echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}\033[K"
        
        for (( i=0; i<num_items; i++ )); do
            local item=${REPOS[$i]}
            local display_name="$item"
            [ "$item" == "." ] && display_name=$(basename "$PWD")
            local status_file=$(echo "$item" | sed 's|/|__|g')
            [ "$item" == "." ] && status_file="__root__"
            local status=$(cat "$STATUS_DIR/$status_file" 2>/dev/null || echo -e "${NC}[WAITING ] Waiting...${NC}")
            printf "   %-15s | %b\033[K\n" "$display_name" "$status"
        done
        sleep 0.2
    done

    # --- Final Render Pass ---
    printf "\033[%dA" "$((num_items + header_lines))"
    local contents=$(cat "$STATUS_DIR"/* 2>/dev/null)
    local success_count=$(echo "$contents" | grep -cE '\[SYNCED  \]|\[SUCCESS \]')
    local dirty_count=$(echo "$contents" | grep -c '\[DIRTY   \]')
    local failed_count=$(echo "$contents" | grep -cE '\[FAILED  \]|\[MISSING \]|\[OUT SYNC\]')
    
    [ -z "$success_count" ] && success_count=0
    [ -z "$dirty_count" ] && dirty_count=0
    [ -z "$failed_count" ] && failed_count=0
    
    local resolved_count=$((success_count + dirty_count + failed_count))
    local pct=0
    [ "$num_items" -gt 0 ] && pct=$(( resolved_count * 100 / num_items ))
    local filled=$(( pct / 10 ))
    local bar="["
    for ((b=0; b<filled; b++)); do bar+="▆"; done
    for ((b=0; b<10-filled; b++)); do bar+="░"; done
    bar+="]"

    local bar_color="${GREEN}"
    [ "$failed_count" -gt 0 ] && bar_color="${RED}"
    [ "$dirty_count" -gt 0 ] && [ "$failed_count" -eq 0 ] && bar_color="${YELLOW}"

    echo -e "${CYAN}${BOLD}${BATT_ICON} $MISSION_TITLE${NC} | v$VERSION\033[K"
    echo -e "${PURPLE}${LAST_MISSION_STR}${NC}\033[K"
    echo -e "${BOLD}HEALTH: ${bar_color}${bar}${NC} ${BOLD}${pct}% | SYNCED: ${success_count} | DIRTY: ${dirty_count} | FAILED: ${failed_count}${NC}\033[K"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}\033[K"

    for (( i=0; i<num_items; i++ )); do
        local item=${REPOS[$i]}
        local display_name="$item"
        [ "$item" == "." ] && display_name=$(basename "$PWD")
        local status_file=$(echo "$item" | sed 's|/|__|g')
        [ "$item" == "." ] && status_file="__root__"
        local status=$(cat "$STATUS_DIR/$status_file" 2>/dev/null || echo -e "${NC}[WAITING ] Waiting...${NC}")
        printf "   %-15s | %b\033[K\n" "$display_name" "$status"
    done
    
    tput cnorm 2>/dev/null # Restore cursor
}
