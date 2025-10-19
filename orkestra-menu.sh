#!/bin/bash
# Orkestra Main Menu
# Central navigation for all Orkestra systems

SCRIPT_DIR="/workspaces/Orkestra/SCRIPTS"

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
    echo ""
}

main_menu() {
    show_main_banner
    echo -e "${CYAN}═══ MAIN MENU ═══${NC}"
    echo ""
    echo -e "${GREEN}1)${NC} Committee System    ${BLUE}(Vote/Question/Collaboration)${NC}"
    echo -e "${GREEN}2)${NC} Task Management     ${BLUE}(Queue/Status/Assign)${NC}"
    echo -e "${GREEN}3)${NC} Project Browser     ${BLUE}(View/Switch/Create)${NC}"
    echo -e "${GREEN}4)${NC} AI Status           ${BLUE}(Check all AI systems)${NC}"
    echo -e "${GREEN}5)${NC} Compression Tools   ${BLUE}(HACS/CDIS)${NC}"
    echo -e "${GREEN}6)${NC} Documentation       ${BLUE}(Guides/Quick Ref)${NC}"
    echo -e "${GREEN}7)${NC} System Info         ${BLUE}(Version/Status)${NC}"
    echo -e "${GREEN}8)${NC} Exit"
    echo ""
    read -p "Select option [1-8]: " choice
    
    case $choice in
        1) "$SCRIPT_DIR/COMMITTEE/committee-menu.sh" ;;
        2) task_management_menu ;;
        3) project_browser_menu ;;
        4) ai_status_check ;;
        5) compression_tools_menu ;;
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

compression_tools_menu() {
    echo -e "${YELLOW}Compression Tools - Coming Soon${NC}"
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
