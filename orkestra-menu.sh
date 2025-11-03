#!/bin/bash
# Orkestra Main Menu
# Central navigation for all Orkestra systems

# Detect script location dynamically
MENU_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="$MENU_SCRIPT_DIR/SCRIPTS"

# Try to find current project
CURRENT_PROJECT_FILE="$MENU_SCRIPT_DIR/CONFIG/current-project.json"
if [ -f "$CURRENT_PROJECT_FILE" ]; then
    PROJECT_PATH=$(python3 -c "import json; print(json.load(open('$CURRENT_PROJECT_FILE'))['path'])" 2>/dev/null || echo "")
    PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$CURRENT_PROJECT_FILE'))['name'])" 2>/dev/null || echo "Unknown")
else
    PROJECT_PATH=""
    PROJECT_NAME="No project loaded"
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

show_main_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║                    O R K E S T R A                         ║"
    echo "║                                                            ║"
    echo "║            Democratic AI Coordination System               ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${CYAN}Current Project:${NC} ${GREEN}$PROJECT_NAME${NC}"
    if [ -n "$PROJECT_PATH" ]; then
        echo -e "${CYAN}Location:${NC} ${GREEN}$PROJECT_PATH${NC}"
    fi
    echo ""
}

main_menu() {
    show_main_banner
    echo -e "${CYAN}═══ MAIN MENU ═══${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Project Planning    ${BLUE}(Create/Review Project Plan)${NC}"
    echo -e "${GREEN}2)${NC} Committee System    ${BLUE}(Vote/Question/Collaboration)${NC}"
    echo -e "${GREEN}3)${NC} Task Management     ${BLUE}(Queue/Status/Assign)${NC}"
    echo -e "${GREEN}4)${NC} Project Browser     ${BLUE}(View/Switch/Create)${NC}"
    echo -e "${GREEN}5)${NC} AI Status           ${BLUE}(Check all AI systems)${NC}"
    echo -e "${GREEN}6)${NC} Documentation       ${BLUE}(Guides/Quick Ref)${NC}"
    echo -e "${GREEN}7)${NC} System Info         ${BLUE}(Version/Status)${NC}"
    echo -e "${GREEN}8)${NC} Exit"
    echo ""
    read -p "Select option [1-8]: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/CORE/project-planning.sh" ;;
        2) "$SCRIPT_DIR/COMMITTEE/committee-menu.sh" ;;
        3) task_management_menu ;;
        4) project_browser_menu ;;
        5) ai_status_check ;;
        6) documentation_menu ;;
        7) system_info ;;
        8) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; main_menu ;;
    esac
}

task_management_menu() {
    echo -e "${YELLOW}Task Management - Coming Soon${NC}"
    sleep 2
    main_menu
}

project_browser_menu() {
    echo -e "${YELLOW}Project Browser - Coming Soon${NC}"
    sleep 2
    main_menu
}

ai_status_check() {
    echo -e "${YELLOW}AI Status Check - Coming Soon${NC}"
    sleep 2
    main_menu
}

documentation_menu() {
    echo -e "${YELLOW}Documentation - Coming Soon${NC}"
    sleep 2
    main_menu
}

system_info() {
    show_main_banner
    echo -e "${CYAN}═══ SYSTEM INFORMATION ═══${NC}"
    echo ""
    echo -e "${GREEN}Version:${NC} 1.0.0"
    echo -e "${GREEN}Date:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${GREEN}User:${NC} $USER"
    echo -e "${GREEN}Workspace:${NC} /workspaces/Orkestra"
    echo -e "${GREEN}Branch:${NC} $(cd /workspaces/Orkestra && git branch --show-current 2>/dev/null || echo 'N/A')"
    echo ""
    read -p "Press Enter to continue..."
    main_menu
}

# Start
main_menu
