#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA PROJECT MANAGER
# ═══════════════════════════════════════════════════════════════════════════
# Manages Orkestra projects:
# - start        : Start Orkestra with current/last project
# - new          : Create new project (resets system)
# - load         : Load existing project from list
# - list         : Show all saved projects
# - save         : Save current project state
# - reset        : Reset system to clean state
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

ORKESTRA_ROOT="/workspaces/Orkestra"
PROJECTS_DIR="$ORKESTRA_ROOT/PROJECTS"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"

# Project state files
CURRENT_PROJECT_FILE="$CONFIG_DIR/current-project.json"
PROJECTS_INDEX="$PROJECTS_DIR/projects-index.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# PROJECT INDEX MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

init_projects_index() {
    mkdir -p "$PROJECTS_DIR"
    
    if [ ! -f "$PROJECTS_INDEX" ]; then
        cat > "$PROJECTS_INDEX" << 'EOF'
{
  "projects": [],
  "last_used": null
}
EOF
        log_info "Created projects index"
    fi
}

get_all_projects() {
    init_projects_index
    jq -r '.projects[] | "\(.id)|\(.name)|\(.created)|\(.last_accessed // "never")"' "$PROJECTS_INDEX" 2>/dev/null || echo ""
}

get_project_by_id() {
    local project_id="$1"
    jq -r ".projects[] | select(.id == \"$project_id\")" "$PROJECTS_INDEX" 2>/dev/null
}

get_project_by_name() {
    local project_name="$1"
    jq -r ".projects[] | select(.name == \"$project_name\")" "$PROJECTS_INDEX" 2>/dev/null
}

add_project_to_index() {
    local project_id="$1"
    local project_name="$2"
    local project_path="$3"
    local description="${4:-}"
    
    local timestamp=$(date -Iseconds)
    local tmp_file=$(mktemp)
    
    jq ".projects += [{
        \"id\": \"$project_id\",
        \"name\": \"$project_name\",
        \"path\": \"$project_path\",
        \"description\": \"$description\",
        \"created\": \"$timestamp\",
        \"last_accessed\": \"$timestamp\"
    }] | .last_used = \"$project_id\"" "$PROJECTS_INDEX" > "$tmp_file"
    
    mv "$tmp_file" "$PROJECTS_INDEX"
}

update_project_access() {
    local project_id="$1"
    local timestamp=$(date -Iseconds)
    local tmp_file=$(mktemp)
    
    jq ".projects = [.projects[] | if .id == \"$project_id\" then .last_accessed = \"$timestamp\" else . end] | .last_used = \"$project_id\"" "$PROJECTS_INDEX" > "$tmp_file"
    mv "$tmp_file" "$PROJECTS_INDEX"
}

# ═══════════════════════════════════════════════════════════════════════════
# SYSTEM RESET
# ═══════════════════════════════════════════════════════════════════════════

reset_system() {
    log_section "Resetting Orkestra System"
    
    # Stop running services
    log_info "Stopping services..."
    pkill -f "orchestrator.sh" 2>/dev/null || true
    pkill -f "monitor.sh" 2>/dev/null || true
    pkill -f "orkestra-automation.sh" 2>/dev/null || true
    sleep 2
    log_success "Services stopped"
    
    # Clear locks
    log_info "Clearing locks..."
    rm -f "$CONFIG_DIR/LOCKS"/*.lock 2>/dev/null || true
    log_success "Locks cleared"
    
    # Clear runtime files
    log_info "Clearing runtime files..."
    rm -f "$CONFIG_DIR/RUNTIME"/*.pid 2>/dev/null || true
    log_success "Runtime files cleared"
    
    # Reset task queue
    log_info "Resetting task queue..."
    cat > "$CONFIG_DIR/TASK-QUEUES/task-queue.json" << 'EOF'
{
  "ai_agents": [
    {"name": "claude", "specialty": "architecture"},
    {"name": "chatgpt", "specialty": "general"},
    {"name": "gemini", "specialty": "firebase"},
    {"name": "grok", "specialty": "innovation"},
    {"name": "copilot", "specialty": "evaluation"}
  ],
  "tasks": []
}
EOF
    log_success "Task queue reset"
    
    # Clear logs (optional)
    if [ "${CLEAR_LOGS:-false}" = "true" ]; then
        log_info "Clearing logs..."
        rm -f "$LOGS_DIR"/*.log 2>/dev/null || true
        log_success "Logs cleared"
    fi
    
    # Clear current project
    rm -f "$CURRENT_PROJECT_FILE" 2>/dev/null || true
    
    log_success "System reset complete"
}

# ═══════════════════════════════════════════════════════════════════════════
# PROJECT OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════

create_new_project() {
    log_section "Create New Project"
    
    # Get project details
    echo ""
    read -p "Project name: " project_name
    
    if [ -z "$project_name" ]; then
        log_error "Project name cannot be empty"
        return 1
    fi
    
    # Check if project exists
    if get_project_by_name "$project_name" | grep -q "name"; then
        log_error "Project '$project_name' already exists"
        log_info "Use 'load' to switch to it"
        return 1
    fi
    
    read -p "Description (optional): " description
    
    # Generate project ID
    local project_id=$(echo "$project_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    local project_path="$PROJECTS_DIR/$project_id"
    
    # Confirm reset
    echo ""
    log_warning "Creating a new project will reset the Orkestra system"
    read -p "Continue? (y/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    # Reset system
    reset_system
    
    # Create project directory
    log_info "Creating project directory..."
    mkdir -p "$project_path"/{docs,data,config,notes}
    
    # Create project manifest
    cat > "$project_path/project.json" << EOF
{
  "id": "$project_id",
  "name": "$project_name",
  "description": "$description",
  "created": "$(date -Iseconds)",
  "version": "1.0.0"
}
EOF
    
    # Add to index
    add_project_to_index "$project_id" "$project_name" "$project_path" "$description"
    
    # Set as current project
    cp "$project_path/project.json" "$CURRENT_PROJECT_FILE"
    
    log_success "Project created: $project_name"
    log_info "Project ID: $project_id"
    log_info "Location: $project_path"
    echo ""
    
    # Start Orkestra
    log_info "Starting Orkestra with new project..."
    "$ORKESTRA_ROOT/start-orkestra.sh" --clean
}

load_project() {
    log_section "Load Project"
    
    init_projects_index
    
    # Get all projects
    local projects=$(get_all_projects)
    
    if [ -z "$projects" ]; then
        log_warning "No saved projects found"
        log_info "Use 'new' to create a project"
        return 1
    fi
    
    # Display projects
    echo ""
    echo -e "${BOLD}Available Projects:${NC}"
    echo ""
    echo -e "${BOLD}  #  Name                      Created              Last Accessed${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local index=1
    local -a project_ids=()
    
    while IFS='|' read -r id name created last_accessed; do
        project_ids+=("$id")
        printf "  ${CYAN}%-2d${NC}  %-25s %-20s %s\n" "$index" "$name" \
            "$(date -d "$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$created")" \
            "$(date -d "$last_accessed" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$last_accessed")"
        ((index++))
    done <<< "$projects"
    
    echo ""
    read -p "Select project number (or 'q' to quit): " selection
    
    if [[ "$selection" == "q" ]] || [[ "$selection" == "Q" ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -ge "$index" ]; then
        log_error "Invalid selection"
        return 1
    fi
    
    # Get selected project
    local selected_id="${project_ids[$((selection-1))]}"
    local project_info=$(get_project_by_id "$selected_id")
    local project_name=$(echo "$project_info" | jq -r '.name')
    local project_path=$(echo "$project_info" | jq -r '.path')
    
    echo ""
    log_info "Loading project: $project_name"
    
    # Reset system
    log_info "Resetting system..."
    reset_system
    
    # Set as current project
    cp "$project_path/project.json" "$CURRENT_PROJECT_FILE"
    update_project_access "$selected_id"
    
    log_success "Project loaded: $project_name"
    echo ""
    
    # Start Orkestra
    log_info "Starting Orkestra with loaded project..."
    "$ORKESTRA_ROOT/start-orkestra.sh" --clean
}

list_projects() {
    log_section "Saved Projects"
    
    init_projects_index
    
    local projects=$(get_all_projects)
    
    if [ -z "$projects" ]; then
        echo ""
        log_warning "No saved projects found"
        log_info "Use 'orkestra new' to create your first project"
        echo ""
        return 0
    fi
    
    echo ""
    echo -e "${BOLD}  Name                      Description                   Created              Last Accessed${NC}"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while IFS='|' read -r id name created last_accessed; do
        local project_info=$(get_project_by_id "$id")
        local description=$(echo "$project_info" | jq -r '.description // "No description"' | cut -c1-30)
        
        printf "  ${GREEN}%-25s${NC} %-30s %-20s %s\n" "$name" "$description" \
            "$(date -d "$created" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$created")" \
            "$(date -d "$last_accessed" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$last_accessed")"
    done <<< "$projects"
    
    echo ""
    
    # Show current project
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        local current_name=$(jq -r '.name' "$CURRENT_PROJECT_FILE")
        echo -e "${BOLD}Current Project:${NC} ${GREEN}$current_name${NC}"
        echo ""
    fi
}

start_orkestra() {
    log_section "Start Orkestra"
    
    # Check if there's a current project
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        local project_name=$(jq -r '.name' "$CURRENT_PROJECT_FILE")
        local project_id=$(jq -r '.id' "$CURRENT_PROJECT_FILE")
        
        echo ""
        log_info "Current project: $project_name"
        update_project_access "$project_id"
        echo ""
    else
        echo ""
        log_warning "No active project"
        log_info "Create one with: orkestra new"
        log_info "Or load one with: orkestra load"
        echo ""
        read -p "Start without a project? (y/N): " confirm
        
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Cancelled"
            return 0
        fi
        echo ""
    fi
    
    # Start Orkestra
    "$ORKESTRA_ROOT/start-orkestra.sh" "$@"
}

save_current_project() {
    log_section "Save Project State"
    
    if [ ! -f "$CURRENT_PROJECT_FILE" ]; then
        log_error "No active project to save"
        return 1
    fi
    
    local project_name=$(jq -r '.name' "$CURRENT_PROJECT_FILE")
    local project_id=$(jq -r '.id' "$CURRENT_PROJECT_FILE")
    local project_path="$PROJECTS_DIR/$project_id"
    
    log_info "Saving project: $project_name"
    
    # Create snapshot
    local snapshot_dir="$project_path/snapshots/$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$snapshot_dir"
    
    # Save task queue
    cp "$CONFIG_DIR/TASK-QUEUES/task-queue.json" "$snapshot_dir/" 2>/dev/null || true
    
    # Save logs
    cp "$LOGS_DIR"/*.log "$snapshot_dir/" 2>/dev/null || true
    
    update_project_access "$project_id"
    
    log_success "Project saved: $snapshot_dir"
}

show_current_project() {
    if [ -f "$CURRENT_PROJECT_FILE" ]; then
        echo ""
        echo -e "${BOLD}Current Project:${NC}"
        echo ""
        jq -r '"  Name:        \(.name)\n  ID:          \(.id)\n  Description: \(.description // "None")\n  Created:     \(.created)"' "$CURRENT_PROJECT_FILE"
        echo ""
    else
        echo ""
        log_warning "No active project"
        echo ""
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Orkestra Project Manager${NC}

${BOLD}USAGE:${NC}
    orkestra <command> [options]

${BOLD}COMMANDS:${NC}
    ${GREEN}start${NC}       Start Orkestra with current/last project
    ${GREEN}new${NC}         Create new project (resets system)
    ${GREEN}load${NC}        Load existing project from list
    ${GREEN}list${NC}        Show all saved projects
    ${GREEN}save${NC}        Save current project state
    ${GREEN}reset${NC}       Reset system to clean state
    ${GREEN}current${NC}     Show current project info
    ${GREEN}health${NC}      Monitor AI agent health status
    ${GREEN}help${NC}        Show this help message

${BOLD}EXAMPLES:${NC}
    ${CYAN}orkestra new${NC}              # Create a new project
    ${CYAN}orkestra load${NC}             # Choose from saved projects
    ${CYAN}orkestra start${NC}            # Start with current project
    ${CYAN}orkestra start --clean${NC}    # Start with clean locks
    ${CYAN}orkestra list${NC}             # List all projects
    ${CYAN}orkestra reset${NC}            # Reset system

${BOLD}PROJECT WORKFLOW:${NC}
    1. Create project:     ${CYAN}orkestra new${NC}
    2. Work on project:    Use Orkestra normally
    3. Save progress:      ${CYAN}orkestra save${NC}
    4. Switch projects:    ${CYAN}orkestra load${NC}
    5. Resume work:        ${CYAN}orkestra start${NC}

EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # Ensure directories exist
    mkdir -p "$PROJECTS_DIR" "$CONFIG_DIR" "$LOGS_DIR"
    init_projects_index
    
    # Parse command
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        start)
            start_orkestra "$@"
            ;;
        new)
            create_new_project
            ;;
        load)
            load_project
            ;;
        list|ls)
            list_projects
            ;;
        save)
            save_current_project
            ;;
        reset)
            reset_system
            log_success "System reset complete"
            ;;
        current|info)
            show_current_project
            ;;
        health|agents|status)
            "$SCRIPTS_DIR/MONITORING/agent-health.sh" "$@"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
