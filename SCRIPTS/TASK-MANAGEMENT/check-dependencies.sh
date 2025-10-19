#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# DEPENDENCY CHECKER & VALIDATOR
# ═══════════════════════════════════════════════════════════════════════════
# Validates task dependencies and execution order
# Detects circular dependencies and blocking issues
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
TASK_QUEUE="$ORKESTRA_ROOT/CONFIG/TASK-QUEUES/task-queue.json"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"

mkdir -p "$LOGS_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

check_task_exists() {
    local task_id="$1"
    jq -e --arg id "$task_id" '.tasks[] | select(.task_id == $id)' "$TASK_QUEUE" >/dev/null 2>&1
}

get_task_dependencies() {
    local task_id="$1"
    jq -r --arg id "$task_id" '.tasks[] | select(.task_id == $id) | .dependencies[]' "$TASK_QUEUE" 2>/dev/null || echo ""
}

get_task_status() {
    local task_id="$1"
    jq -r --arg id "$task_id" '.tasks[] | select(.task_id == $id) | .status' "$TASK_QUEUE" 2>/dev/null || echo "not_found"
}

# Check for circular dependencies using DFS
check_circular_dependency() {
    local task_id="$1"
    local visited="$2"
    local recursion_stack="$3"
    
    # Mark current node as visited and add to recursion stack
    visited="$visited $task_id"
    recursion_stack="$recursion_stack $task_id"
    
    # Get dependencies
    local deps=$(get_task_dependencies "$task_id")
    
    for dep in $deps; do
        # If dependency not in visited set, recurse
        if [[ ! " $visited " =~ " $dep " ]]; then
            local result=$(check_circular_dependency "$dep" "$visited" "$recursion_stack")
            if [[ "$result" == "CIRCULAR:"* ]]; then
                echo "$result"
                return 1
            fi
            visited="$result"
        # If dependency in recursion stack, we found a cycle
        elif [[ " $recursion_stack " =~ " $dep " ]]; then
            echo "CIRCULAR: $recursion_stack → $dep"
            return 1
        fi
    done
    
    echo "$visited"
    return 0
}

validate_task_dependencies() {
    local task_id="$1"
    local errors=0
    
    echo -e "${CYAN}Validating dependencies for:${NC} $task_id"
    echo ""
    
    # Check if task exists
    if ! check_task_exists "$task_id"; then
        echo -e "${RED}✗${NC} Task does not exist: $task_id"
        return 1
    fi
    
    # Get task info
    local task=$(jq --arg id "$task_id" '.tasks[] | select(.task_id == $id)' "$TASK_QUEUE")
    local status=$(echo "$task" | jq -r '.status')
    
    # Get dependencies
    local deps=$(get_task_dependencies "$task_id")
    
    if [[ -z "$deps" ]]; then
        echo -e "${GREEN}✓${NC} No dependencies - can execute immediately"
        return 0
    fi
    
    # Check each dependency
    echo -e "${BOLD}Checking dependencies:${NC}"
    for dep in $deps; do
        # Check if dependency exists
        if ! check_task_exists "$dep"; then
            echo -e "${RED}✗${NC} Dependency not found: $dep"
            ((errors++))
            continue
        fi
        
        # Check dependency status
        local dep_status=$(get_task_status "$dep")
        case "$dep_status" in
            completed)
                echo -e "${GREEN}✓${NC} $dep - completed"
                ;;
            in_progress)
                echo -e "${YELLOW}⏳${NC} $dep - in progress (waiting)"
                ;;
            pending|assigned)
                echo -e "${YELLOW}⏳${NC} $dep - pending (waiting)"
                ;;
            failed)
                echo -e "${RED}✗${NC} $dep - failed (blocking)"
                ((errors++))
                ;;
            blocked)
                echo -e "${RED}✗${NC} $dep - blocked (blocking)"
                ((errors++))
                ;;
            *)
                echo -e "${YELLOW}?${NC} $dep - unknown status: $dep_status"
                ;;
        esac
    done
    
    echo ""
    
    # Check for circular dependencies
    echo -e "${BOLD}Checking for circular dependencies:${NC}"
    local result=$(check_circular_dependency "$task_id" "" "")
    if [[ "$result" == "CIRCULAR:"* ]]; then
        echo -e "${RED}✗${NC} Circular dependency detected!"
        echo -e "${RED}  Path:${NC} ${result#CIRCULAR: }"
        ((errors++))
    else
        echo -e "${GREEN}✓${NC} No circular dependencies"
    fi
    
    echo ""
    
    if [[ $errors -eq 0 ]]; then
        local can_execute=$(can_task_execute "$task_id")
        if [[ "$can_execute" == "true" ]]; then
            echo -e "${GREEN}✓ Task can execute${NC}"
        else
            echo -e "${YELLOW}⏳ Task waiting on dependencies${NC}"
        fi
        return 0
    else
        echo -e "${RED}✗ Found $errors error(s)${NC}"
        return 1
    fi
}

can_task_execute() {
    local task_id="$1"
    
    local deps=$(get_task_dependencies "$task_id")
    
    # No dependencies = can execute
    if [[ -z "$deps" ]]; then
        echo "true"
        return 0
    fi
    
    # Check all dependencies are completed
    for dep in $deps; do
        local dep_status=$(get_task_status "$dep")
        if [[ "$dep_status" != "completed" ]]; then
            echo "false"
            return 1
        fi
    done
    
    echo "true"
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# VISUALIZATION
# ═══════════════════════════════════════════════════════════════════════════

show_dependency_tree() {
    local task_id="$1"
    local prefix="${2:-}"
    local visited="${3:-}"
    
    # Prevent infinite loops
    if [[ " $visited " =~ " $task_id " ]]; then
        echo "${prefix}${task_id} ${RED}(circular!)${NC}"
        return
    fi
    
    visited="$visited $task_id"
    
    # Get task info
    local status=$(get_task_status "$task_id")
    local status_icon
    case "$status" in
        completed) status_icon="${GREEN}✓${NC}" ;;
        in_progress) status_icon="${YELLOW}⏳${NC}" ;;
        failed) status_icon="${RED}✗${NC}" ;;
        blocked) status_icon="${RED}🚫${NC}" ;;
        *) status_icon="${BLUE}○${NC}" ;;
    esac
    
    echo -e "${prefix}${status_icon} $task_id ($status)"
    
    # Get dependencies
    local deps=$(get_task_dependencies "$task_id")
    
    if [[ -n "$deps" ]]; then
        local dep_count=$(echo "$deps" | wc -w)
        local i=0
        for dep in $deps; do
            ((i++))
            if [[ $i -eq $dep_count ]]; then
                show_dependency_tree "$dep" "${prefix}    └── " "$visited"
            else
                show_dependency_tree "$dep" "${prefix}    ├── " "$visited"
            fi
        done
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# EXECUTION ORDER
# ═══════════════════════════════════════════════════════════════════════════

get_execution_order() {
    echo -e "${CYAN}${BOLD}Calculating Execution Order${NC}"
    echo ""
    
    local queue_file="$TASK_QUEUE"
    local processed=()
    local order=()
    local level=0
    
    # Find tasks with no incomplete dependencies (can execute now)
    while true; do
        local found=0
        local level_tasks=()
        
        # Get all pending/assigned tasks
        local all_tasks=$(jq -r '.tasks[] | select(.status == "pending" or .status == "assigned") | .task_id' "$queue_file")
        
        for task_id in $all_tasks; do
            # Skip if already processed
            if [[ " ${processed[@]:-} " =~ " $task_id " ]]; then
                continue
            fi
            
            # Check if can execute
            local can_exec="true"
            local deps=$(get_task_dependencies "$task_id")
            
            for dep in $deps; do
                local dep_status=$(get_task_status "$dep")
                # Check if dependency is not completed and not in current level
                if [[ "$dep_status" != "completed" ]] && [[ ! " ${level_tasks[@]:-} " =~ " $dep " ]]; then
                    can_exec="false"
                    break
                fi
            done
            
            if [[ "$can_exec" == "true" ]]; then
                level_tasks+=("$task_id")
                processed+=("$task_id")
                found=1
            fi
        done
        
        # If found tasks at this level, add to order
        if [[ $found -eq 1 ]]; then
            echo -e "${BOLD}Level $level:${NC}"
            for task in "${level_tasks[@]}"; do
                local task_info=$(jq --arg id "$task" '.tasks[] | select(.task_id == $id)' "$queue_file")
                local title=$(echo "$task_info" | jq -r '.title')
                local priority=$(echo "$task_info" | jq -r '.priority')
                
                local priority_color
                case "$priority" in
                    critical) priority_color="$RED" ;;
                    high) priority_color="$YELLOW" ;;
                    medium) priority_color="$BLUE" ;;
                    low) priority_color="$GREEN" ;;
                esac
                
                echo -e "  ${priority_color}●${NC} $task - $title"
                order+=("$task")
            done
            echo ""
            ((level++))
        else
            break
        fi
    done
    
    # Show blocked tasks
    local blocked_tasks=$(jq -r '.tasks[] | select(.status == "pending" or .status == "assigned") | .task_id' "$queue_file")
    local has_blocked=0
    for task_id in $blocked_tasks; do
        if [[ ! " ${processed[@]:-} " =~ " $task_id " ]]; then
            if [[ $has_blocked -eq 0 ]]; then
                echo -e "${RED}${BOLD}Blocked Tasks:${NC}"
                has_blocked=1
            fi
            local task_info=$(jq --arg id "$task_id" '.tasks[] | select(.task_id == $id)' "$queue_file")
            local title=$(echo "$task_info" | jq -r '.title')
            echo -e "  ${RED}🚫${NC} $task_id - $title"
            
            # Show blocking dependencies
            local deps=$(get_task_dependencies "$task_id")
            for dep in $deps; do
                local dep_status=$(get_task_status "$dep")
                if [[ "$dep_status" != "completed" ]]; then
                    echo -e "     ${RED}↳${NC} Waiting on: $dep ($dep_status)"
                fi
            done
        fi
    done
    
    if [[ $has_blocked -eq 0 ]]; then
        echo -e "${GREEN}✓ No blocked tasks${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION REPORT
# ═══════════════════════════════════════════════════════════════════════════

validate_all_dependencies() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║            DEPENDENCY VALIDATION REPORT                           ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local total_tasks=$(jq '.tasks | length' "$TASK_QUEUE")
    local errors=0
    local warnings=0
    
    echo -e "${CYAN}Total tasks:${NC} $total_tasks"
    echo ""
    
    # Check each task
    local all_tasks=$(jq -r '.tasks[] | .task_id' "$TASK_QUEUE")
    
    for task_id in $all_tasks; do
        echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ! validate_task_dependencies "$task_id" 2>&1 | grep -q "error"; then
            :
        else
            ((errors++))
        fi
    done
    
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ All dependencies valid${NC}"
        return 0
    else
        echo -e "${RED}${BOLD}✗ Found issues in $errors task(s)${NC}"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Dependency Checker & Validator${NC}

${BOLD}USAGE:${NC}
    $0 <command> [options]

${BOLD}COMMANDS:${NC}
    ${GREEN}check <task_id>${NC}        Validate dependencies for specific task
    ${GREEN}tree <task_id>${NC}         Show dependency tree
    ${GREEN}can-execute <task_id>${NC}  Check if task can execute now
    ${GREEN}order${NC}                  Show execution order for all tasks
    ${GREEN}validate-all${NC}           Validate all task dependencies
    ${GREEN}help${NC}                   Show this help

${BOLD}EXAMPLES:${NC}
    ${CYAN}# Check single task${NC}
    $0 check task_0001

    ${CYAN}# Show dependency tree${NC}
    $0 tree task_0001

    ${CYAN}# Check if can execute${NC}
    $0 can-execute task_0001

    ${CYAN}# Show execution order${NC}
    $0 order

    ${CYAN}# Validate all dependencies${NC}
    $0 validate-all

${BOLD}OUTPUTS:${NC}
    ✓ - Dependency satisfied
    ⏳ - Waiting on dependency
    ✗ - Dependency failed/blocking
    🚫 - Task blocked

EOF
}

main() {
    if [[ ! -f "$TASK_QUEUE" ]]; then
        echo -e "${RED}✗${NC} Task queue not found: $TASK_QUEUE"
        exit 1
    fi
    
    local command="${1:-help}"
    
    case "$command" in
        check|c)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Task ID required"
                exit 1
            fi
            validate_task_dependencies "$2"
            ;;
        tree|t)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Task ID required"
                exit 1
            fi
            echo ""
            echo -e "${BOLD}${CYAN}Dependency Tree for $2${NC}"
            echo ""
            show_dependency_tree "$2"
            echo ""
            ;;
        can-execute|can|x)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Task ID required"
                exit 1
            fi
            local can=$(can_task_execute "$2")
            if [[ "$can" == "true" ]]; then
                echo -e "${GREEN}✓${NC} Task $2 can execute now"
                exit 0
            else
                echo -e "${YELLOW}⏳${NC} Task $2 is waiting on dependencies"
                exit 1
            fi
            ;;
        order|o)
            get_execution_order
            ;;
        validate-all|validate|v)
            validate_all_dependencies
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
