#!/usr/bin/env bash

# ======================================================================
# STRIVE-CLI: Installation Engine
# Sets up Strive tools as global or local CLI commands
# Striving Designs | Prayas Shrestha
# ======================================================================

set -e

# Default to global installation
INSTALL_DIR="/usr/local/bin"
IS_USER_INSTALL=false

# Check for --user flag
for arg in "$@"; do
    if [ "$arg" == "--user" ]; then
        INSTALL_DIR="$HOME/.strive/bin"
        IS_USER_INSTALL=true
        break
    fi
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$PROJECT_ROOT/bin"

# Professional HUD Engine Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}🏹 STRIVE-CLI INSTALLER${NC}"
echo -e "Target Directory: ${BOLD}$INSTALL_DIR${NC}"

# Helper function to run commands with sudo only if needed
run_cmd() {
    if $IS_USER_INSTALL; then
        "$@"
    else
        sudo "$@"
    fi
}

# Legacy Cleanup (sd-sync and other outdated versions)
for legacy in "sd-sync"; do
    if [ -L "$INSTALL_DIR/$legacy" ] || [ -f "$INSTALL_DIR/$legacy" ]; then
        echo -e "Cleaning up legacy command: ${BOLD}$legacy${NC}..."
        run_cmd rm "$INSTALL_DIR/$legacy"
    fi
done

# Check if target directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "Creating $INSTALL_DIR..."
    if $IS_USER_INSTALL; then
        mkdir -p "$INSTALL_DIR"
    else
        sudo mkdir -p "$INSTALL_DIR"
    fi
fi

# Install each tool from bin/
for tool_path in "$BIN_DIR"/strive-*; do
    if [ -f "$tool_path" ]; then
        tool_name=$(basename "$tool_path")
        target_path="$INSTALL_DIR/$tool_name"

        echo -en "Installing ${BOLD}$tool_name${NC}... "

        if [ -L "$target_path" ] || [ -f "$target_path" ]; then
            run_cmd rm "$target_path"
        fi

        run_cmd ln -s "$tool_path" "$target_path"
        run_cmd chmod +x "$target_path"
        
        echo -e "${GREEN}SUCCESS${NC}"
    fi
done

echo -e "\n${GREEN}${BOLD}Done!${NC} The Strive CLI Toolkit is now installed."

# PATH Check for User Installation
if $IS_USER_INSTALL; then
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo -e "${YELLOW}${BOLD}NOTE:${NC} $INSTALL_DIR is not in your PATH."
        echo -e "To use the commands from anywhere, add this to your shell profile (.zshrc or .bashrc):"
        echo -e "\n    ${BOLD}export PATH=\"\$HOME/.strive/bin:\$PATH\"${NC}\n"
        echo -e "Then restart your terminal or run: ${BOLD}source ~/.zshrc${NC}"
    else
        echo -e "Run ${BOLD}strive-sync${NC} or ${BOLD}strive-env${NC} from any directory."
    fi
else
    echo -e "Run ${BOLD}strive-sync${NC} or ${BOLD}strive-env${NC} from any directory."
fi
