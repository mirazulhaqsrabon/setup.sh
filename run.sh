#!/bin/bash

# Terminal Welcome Script Manager
# Simple installer/uninstaller with clean interface

set -e  # Exit on any error

# Colors
G='\033[0;32m'  # Green
B='\033[0;34m'  # Blue
Y='\033[1;33m'  # Yellow
R='\033[0;31m'  # Red
NC='\033[0m'    # No Color

# Configuration
SCRIPT_DIR="$HOME/.local/bin"
SCRIPT_NAME="welcome.sh"
SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_NAME"
DEFAULT_COMMAND="sysinfo"

# Detect shell config
if [[ "$SHELL" == *"zsh"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

# Simple spinner
spinner() {
    local pid=$1
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    while kill -0 $pid 2>/dev/null; do
        for (( i=0; i<${#chars}; i++ )); do
            printf "\r${chars:$i:1} $2"
            sleep 0.1
        done
    done
    printf "\r✓ $2\n"
}

# Progress display
progress() {
    printf "  ${B}→${NC} $1... "
    sleep 0.3
    echo -e "${G}done${NC}"
}

# Header
header() {
    clear
    echo -e "${B}╭───────────────────────────────────────╮${NC}"
    echo -e "${B}│ github.com/mirazulhaqsrabon//terminal │${NC}"
    echo -e "${B}╰───────────────────────────────────────╯${NC}"
    echo
}

# Check if installed
is_installed() {
    [[ -f "$SCRIPT_PATH" ]] && grep -q "$SCRIPT_PATH" "$SHELL_CONFIG" 2>/dev/null
}

# Install function
install() {
    header
    echo -e "${Y}Installing Terminal Welcome Script${NC}"
    echo

    # Create directory
    progress "Creating directories"
    mkdir -p "$SCRIPT_DIR"

    # ⭐ Command name with 3s timeout (no Enter needed)
    echo -ne "${B}Command name [${DEFAULT_COMMAND}] (3s): ${NC}"
    COMMAND_NAME=""
    for i in 3 2 1; do
        read -t 1 -r COMMAND_NAME && break
        echo -ne "\r${B}Command name [${DEFAULT_COMMAND}] (${i}s): ${NC}"
    done
    echo
    COMMAND_NAME=${COMMAND_NAME:-$DEFAULT_COMMAND}
    echo -e "  ${G}✓${NC} Using command: ${Y}$COMMAND_NAME${NC}"
    echo

    # Check if command exists
    if command -v "$COMMAND_NAME" &>/dev/null && [[ "$COMMAND_NAME" != "$DEFAULT_COMMAND" ]]; then
        echo -e "${R}⚠ Command '$COMMAND_NAME' already exists!${NC}"
        echo -e "${B}Use anyway? (y/N):${NC} "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${Y}Installation cancelled${NC}"
            exit 1
        fi
    fi

    progress "Creating welcome script"

    # Create the main script
    cat > "$SCRIPT_PATH" << 'SCRIPT_EOF'
#!/bin/bash
# Terminal Welcome Script

# Colors
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; P='\033[0;35m'
C='\033[0;36m'; W='\033[1;37m'; NC='\033[0m'

# System info functions
get_battery() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pmset -g batt 2>/dev/null | grep -Eo "\d+%" | head -1 || echo "N/A"
    else
        [[ -f /sys/class/power_supply/BAT0/capacity ]] && echo "$(cat /sys/class/power_supply/BAT0/capacity)%" || echo "N/A"
    fi
}

get_memory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local total=$(sysctl -n hw.memsize 2>/dev/null)
        [[ -n "$total" ]] && echo "$((total/1024/1024/1024))GB total" || echo "N/A"
    else
        free -h 2>/dev/null | awk '/^Mem:/ {print $4 " free of " $2}' || echo "N/A"
    fi
}

get_storage() {
    df -h / 2>/dev/null | awk 'NR==2 {print $4 " free of " $2}' || echo "N/A"
}

get_network() {
    local ip
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ip=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
    else
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    echo "${ip:-N/A}"
}

# Display system info
clear

echo -e "${G} Time:    ${NC}$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${B} User:    ${NC}miraz@admin"
echo -e "${P} Network: ${NC}$(get_network)"
echo -e "${C} Storage: ${NC}$(get_storage)"
echo -e "${G} Memory:  ${NC}$(get_memory)"

# Battery (if available)
battery=$(get_battery)
[[ "$battery" != "N/A" ]] && echo -e "${Y} Battery: ${NC}$battery"

# Git info (if in repo)
if git rev-parse --git-dir &>/dev/null; then
    branch=$(git branch --show-current 2>/dev/null)
    [[ -n "$branch" ]] && echo -e "${P} Git:     ${NC}$branch"
fi


echo -e "${C} Current: ${NC}$(pwd)"
echo
SCRIPT_EOF

    chmod +x "$SCRIPT_PATH"
    progress "Setting permissions"

    # Create command link
    if [[ "$COMMAND_NAME" != "welcome.sh" ]]; then
        ln -sf "$SCRIPT_PATH" "$SCRIPT_DIR/$COMMAND_NAME"
        progress "Creating command '$COMMAND_NAME'"
    fi

    # Add to PATH if needed
    if [[ ":$PATH:" != *":$SCRIPT_DIR:"* ]]; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Terminal welcome script PATH" >> "$SHELL_CONFIG"
        echo "export PATH=\"$SCRIPT_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        progress "Adding to PATH"
    fi

    # Add auto-run to shell config
    if ! grep -q "$SCRIPT_PATH" "$SHELL_CONFIG" 2>/dev/null; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Auto-run terminal welcome" >> "$SHELL_CONFIG"
        echo "$SCRIPT_PATH" >> "$SHELL_CONFIG"
        progress "Adding to shell startup"
    fi

    # ⭐ Add prompt override (space + miraz@admin)
    if ! grep -q "terminal-welcome prompt override" "$SHELL_CONFIG" 2>/dev/null; then
        if [[ "$SHELL" == *"zsh"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
            cat >> "$SHELL_CONFIG" << 'PROMPT_EOF'

# >>> terminal-welcome prompt override >>>
export PROMPT=' %F{green}%Bmiraz@admin%b%f:%F{blue}%~%f%# '
# <<< terminal-welcome prompt override <<<
PROMPT_EOF
        else
            cat >> "$SHELL_CONFIG" << 'PROMPT_EOF'

# >>> terminal-welcome prompt override >>>
export PS1=' \[\e[1;32m\]miraz@admin\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
# <<< terminal-welcome prompt override <<<
PROMPT_EOF
        fi
        progress "Overriding prompt → miraz@admin"
    fi

    echo
    echo -e "${G}✓ Installation complete!${NC}"
    echo
    echo -e "${B}Usage:${NC}"
    echo -e "  • Automatic: Opens with every new terminal"
    echo -e "  • Manual: Run '${Y}$COMMAND_NAME${NC}' anytime"
    echo -e "  • Prompt: ${Y}miraz@admin${NC} (root@localhost এর বদলে)"
    echo -e "  • Test now: ${Y}source $SHELL_CONFIG${NC}"
    echo
}

# Uninstall function
uninstall() {
    header
    echo -e "${Y}Uninstalling Terminal Welcome Script${NC}"
    echo

    if ! is_installed; then
        echo -e "${R}⚠ Terminal welcome script is not installed${NC}"
        exit 1
    fi

    progress "Removing script files"
    rm -f "$SCRIPT_PATH"
    
    # Remove command links
    for cmd in "$SCRIPT_DIR"/*; do
        if [[ -L "$cmd" ]] && [[ "$(readlink "$cmd")" == "$SCRIPT_PATH" ]]; then
            rm -f "$cmd"
        fi
    done

    progress "Cleaning shell configuration"
    
    # Create a backup
    cp "$SHELL_CONFIG" "${SHELL_CONFIG}.backup.$(date +%s)"
    
    # Remove all welcome script related lines more thoroughly
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/export PATH.*\.local\/bin/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '' '/# Terminal welcome script PATH/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '' '/# Auto-run terminal welcome/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '' "\\|$SCRIPT_PATH|d" "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '' '/welcome\.sh/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '' '/# Terminal welcome script$/d' "$SHELL_CONFIG" 2>/dev/null || true
        # Remove prompt override block
        sed -i '' '/>>> terminal-welcome prompt override >>>/,/<<< terminal-welcome prompt override <<</d' "$SHELL_CONFIG" 2>/dev/null || true
    else
        sed -i '/export PATH.*\.local\/bin/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '/# Terminal welcome script PATH/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '/# Auto-run terminal welcome/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i "\\|$SCRIPT_PATH|d" "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '/welcome\.sh/d' "$SHELL_CONFIG" 2>/dev/null || true
        sed -i '/# Terminal welcome script$/d' "$SHELL_CONFIG" 2>/dev/null || true
        # Remove prompt override block
        sed -i '/>>> terminal-welcome prompt override >>>/,/<<< terminal-welcome prompt override <<</d' "$SHELL_CONFIG" 2>/dev/null || true
    fi
    
    # Clean up empty lines
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^$/N;/^\n$/d' "$SHELL_CONFIG" 2>/dev/null || true
    else
        sed -i '/^$/N;/^\n$/d' "$SHELL_CONFIG" 2>/dev/null || true
    fi

    progress "Cleaning empty directories"
    [[ -d "$SCRIPT_DIR" ]] && rmdir "$SCRIPT_DIR" 2>/dev/null || true

    echo
    echo -e "${G}✓ Uninstallation complete!${NC}"
    echo -e "${B}Removed:${NC}"
    echo -e "  • Script files and commands"
    echo -e "  • Shell configuration entries"
    echo -e "  • PATH modifications"
    echo -e "  • Prompt override"
    echo -e "${Y}⚠ Restart your terminal or run 'source $SHELL_CONFIG' to apply changes${NC}"
    echo -e "${B}Backup created: ${SHELL_CONFIG}.backup.*${NC}"
    echo
}

# Status function
status() {
    header
    echo -e "${Y}Terminal Welcome Script Status${NC}"
    echo

    if is_installed; then
        echo -e "${G}✓ Installed${NC}"
        echo -e "${B}  Script: ${NC}$SCRIPT_PATH"
        echo -e "${B}  Config: ${NC}$SHELL_CONFIG"
        
        local commands=()
        for cmd in "$SCRIPT_DIR"/*; do
            if [[ -L "$cmd" ]] && [[ "$(readlink "$cmd")" == "$SCRIPT_PATH" ]]; then
                commands+=($(basename "$cmd"))
            fi
        done
        
        if [[ ${#commands[@]} -gt 0 ]]; then
            echo -e "${B}  Commands: ${NC}${commands[*]}"
        fi

        if grep -q "terminal-welcome prompt override" "$SHELL_CONFIG" 2>/dev/null; then
            echo -e "${B}  Prompt:   ${NC}miraz@admin ${G}(active)${NC}"
        else
            echo -e "${B}  Prompt:   ${NC}${R}not overridden${NC}"
        fi
    else
        echo -e "${R}✗ Not installed${NC}"
    fi
    echo
}

# Main menu
main() {
    header
    
    if is_installed; then
        echo -e "${G}✓ Terminal Welcome Script is installed${NC}"
        echo
        echo -e "${B}Options:${NC}"
        echo -e "  ${Y}1${NC}) Show status"
        echo -e "  ${Y}2${NC}) Reinstall"
        echo -e "  ${Y}3${NC}) Uninstall"
        echo -e "  ${Y}4${NC}) Exit"
        
        echo
        echo -e "${B}Choose an option [1-4]:${NC} "
        read -r choice
        
        case $choice in
            1) status ;;
            2) uninstall && echo && install ;;
            3) uninstall ;;
            4) echo -e "${B}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${R}Invalid option${NC}"; main ;;
        esac
    else
        echo -e "${Y}Terminal Welcome Script is not installed${NC}"
        echo
        echo -e "${B}Options:${NC}"
        echo -e "  ${Y}1${NC}) Install"
        echo -e "  ${Y}2${NC}) Exit"
        
        echo
        echo -e "${B}Choose an option [1-2]:${NC} "
        read -r choice
        
        case $choice in
            1) install ;;
            2) echo -e "${B}Goodbye!${NC}"; exit 0 ;;
            *) echo -e "${R}Invalid option${NC}"; main ;;
        esac
    fi
}

# Handle command line arguments
case "${1:-}" in
    install|i)   install ;;
    uninstall|u) uninstall ;;
    status|s)    status ;;
    *)           main ;;
esac