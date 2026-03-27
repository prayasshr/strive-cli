#!/bin/bash

# ============================================================================
# STRIVE-CLI: Interactive Mission Control (lib/interactive.sh)
#
# Provides a terminal-based selection UI with Arrow/Space navigation.
# ============================================================================

# State variables for the menu settings
INT_MIGRATE=true
INT_INSTALL=false
INT_FORCE=false
INT_DRY_RUN=false

# State for repo selection (array of true/false strings)
INT_REPO_STATES=()

draw_menu_item() {
    local index=$1
    local current=$2
    local label=$3
    local state=$4
    local is_repo=$5

    if [ "$index" -eq "$current" ]; then
        printf "  ${CYAN}${BOLD}>${NC} "
    else
        printf "    "
    fi

    if [ "$state" == "true" ]; then
        if [ "$is_repo" == "true" ]; then
            printf "${BLUE}[X]${NC} %s \033[K\n" "$label"
        else
            printf "${GREEN}[X]${NC} %s \033[K\n" "$label"
        fi
    else
        printf "[ ] %s \033[K\n" "$label"
    fi
}

show_mission_briefing() {
    # Accept initial flag states from CLI
    INT_MIGRATE=$1
    INT_INSTALL=$2
    INT_FORCE=$3
    INT_DRY_RUN=$4
    shift 4

    local repos=("$@")
    local num_repos=${#repos[@]}

    # Initialize all repos to selected (true)
    for ((i=0; i<num_repos; i++)); do INT_REPO_STATES[$i]="true"; done

    local cursor=0
    # Final Messaging: Option 3 (Plain English) + Force Everything clarity
    local menu_items=(
        "Switch to Main     (-m) [Smart checkout clean repos]"
        "Install Packages   (-i) [Update deps only on changes]"
        "Force Everything   (-f) [Pull & reinstall even if up-to-date]"
        "Dryrun Preview     (-d) [No-risk mission simulation]"
    )
    local num_options=${#menu_items[@]}
    local num_items=$((num_options + num_repos))

    echo -e "\n${CYAN}${BOLD}[⚡] STRIVE-SYNC MISSION BRIEFING${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    echo -e "Found ${BOLD}${num_repos}${NC} repositories.\n"

    # Reserve space for the menu
    for ((i=0; i<num_items+6; i++)); do echo ""; done

    while true; do
        # Up 5 lines based on our loop printed elements
        printf "\033[%dA" "$((num_items + 5))"

        echo -e "${YELLOW}${BOLD}CONFIGURE MISSION PARAMETERS:${NC}\033[K"
        for ((i=0; i<num_options; i++)); do
            local state
            case $i in
                0) state=$INT_MIGRATE ;;
                1) state=$INT_INSTALL ;;
                2) state=$INT_FORCE ;;
                3) state=$INT_DRY_RUN ;;
            esac
            draw_menu_item "$i" "$cursor" "${menu_items[$i]}" "$state" "false"
        done

        echo -e "\n${BLUE}${BOLD}SELECT REPOSITORIES TO SYNC:${NC}\033[K"
        for ((i=0; i<num_repos; i++)); do
            draw_menu_item $((i + num_options)) "$cursor" "${repos[$i]}" "${INT_REPO_STATES[$i]}" "true"
        done

        echo -e "\n${NC}${BOLD}↑/↓${NC} to Navigate | ${BOLD}SPACE${NC} to Toggle | ${BOLD}ENTER${NC} to Launch Mission\033[K"

        IFS= read -rsn1 key
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') ((cursor--)); [ "$cursor" -lt 0 ] && cursor=$((num_items-1)) ;;
                '[B') ((cursor++)); [ "$cursor" -ge "$num_items" ] && cursor=0 ;;
            esac
        elif [[ "$key" == " " ]]; then
            if [ "$cursor" -lt "$num_options" ]; then
                case "$cursor" in
                    0) [[ "$INT_MIGRATE" == "true" ]] && INT_MIGRATE=false || INT_MIGRATE=true ;;
                    1) [[ "$INT_INSTALL" == "true" ]] && INT_INSTALL=false || INT_INSTALL=true ;;
                    2) [[ "$INT_FORCE" == "true" ]] && INT_FORCE=false || INT_FORCE=true ;;
                    3) [[ "$INT_DRY_RUN" == "true" ]] && INT_DRY_RUN=false || INT_DRY_RUN=true ;;
                esac
            else
                local repo_idx=$((cursor - num_options))
                [[ "${INT_REPO_STATES[$repo_idx]}" == "true" ]] && INT_REPO_STATES[$repo_idx]="false" || INT_REPO_STATES[$repo_idx]="true"
            fi
        elif [[ "$key" == "" ]]; then
            break
        fi
    done

    # Sync variables back to the main script's expected names
    [[ "$INT_MIGRATE" == "true" ]] && MIGRATE_TO_MAIN=true  || MIGRATE_TO_MAIN=false
    [[ "$INT_INSTALL" == "true" ]] && AUTO_INSTALL=true    || AUTO_INSTALL=false
    [[ "$INT_FORCE"   == "true" ]] && FORCE_SYNC=true      || FORCE_SYNC=false
    [[ "$INT_DRY_RUN" == "true" ]] && DRY_RUN=true         || DRY_RUN=false

    local final_repos=()
    for ((i=0; i<num_repos; i++)); do
        if [ "${INT_REPO_STATES[$i]}" == "true" ]; then
            final_repos+=("${repos[$i]}")
        fi
    done
    REPOS=("${final_repos[@]}")

    if [ ${#REPOS[@]} -eq 0 ]; then
        echo -e "\n${RED}Error: Mission Aborted. No repositories selected for sync.${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}🚀 MISSION PARAMETERS LOCKED. LAUNCHING...${NC}\n"
    sleep 0.4
}
