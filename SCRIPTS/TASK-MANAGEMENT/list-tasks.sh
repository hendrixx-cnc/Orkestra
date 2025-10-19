#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# TASK LIST VIEWER
# ═══════════════════════════════════════════════════════════════════════════
# View, filter, and manage tasks in the queue
# Multiple viewing modes and filtering options
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
TASK_QUEUE="$ORKESTRA_ROOT/CONFIG/TASK-QUEUES/task-queue.json"

# ═══════════════════════════════════════════════════════════════════════════
# DISPLAY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_header() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                     ORKESTRA TASK QUEUE                           ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

get_status_icon() {
    case "$1" in
        pending) echo "⏳" ;;
        assigned) echo "📋" ;;
        in_progress) echo "🔄" ;;
        review) echo "👁️" ;;
        completed) echo "✅" ;;
        failed) echo "❌" ;;
        blocked) echo "🚫" ;;
        *) echo "❓" ;;
    esac
}

get_priority_color() {
    case "$1" in
        critical) echo "$RED" ;;
        high) echo "$YELLOW" ;;
        medium) echo "$BLUE" ;;
        low) echo "$GREEN" ;;
        *) echo "$NC" ;;
    esac
}

get_agent_icon() {
    case "$1" in
        claude) echo "🎭" ;;
        chatgpt) echo "💬" ;;
        gemini) echo "✨" ;;
        grok) echo "⚡" ;;
        copilot) echo "🚀" ;;
        auto) echo "🤖" ;;
        *) echo "❓" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# VIEWING MODES
# ═══════════════════════════════════════════════════════════════════════════

list_all() {
    show_header
    
    local total=$(jq '.tasks | length' "$TASK_QUEUE")
    echo -e "${CYAN}Total tasks:${NC} $total"
    echo ""
    
    if [[ "$total" -eq 0 ]]; then
        echo -e "${YELLOW}No tasks in queue${NC}"
        return
    fi
    
    # Table header
    printf "${BOLD}%-12s %-8s %-10s %-12s %-40s %-10s${NC}\n" \
        "TASK ID" "STATUS" "PRIORITY" "AGENT" "TITLE" "DURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r '.tasks[] | [
        .task_id,
        .status,
        .priority,
        .assigned_to,
        .title,
        .estimated_duration
    ] | @tsv' "$TASK_QUEUE" | while IFS=$'\t' read -r id status priority agent title duration; do
        local status_icon=$(get_status_icon "$status")
        local agent_icon=$(get_agent_icon "$agent")
        local priority_color=$(get_priority_color "$priority")
        
        # Truncate title if too long
        if [[ ${#title} -gt 38 ]]; then
            title="${title:0:35}..."
        fi
        
        printf "%-12s ${status_icon} %-7s ${priority_color}%-10s${NC} ${agent_icon} %-11s %-40s %-10s\n" \
            "$id" "$status" "$priority" "$agent" "$title" "$duration"
    done
}

list_by_status() {
    local filter_status="$1"
    show_header
    
    echo -e "${CYAN}Filter:${NC} Status = ${BOLD}$filter_status${NC}"
    echo ""
    
    local count=$(jq --arg status "$filter_status" '.tasks[] | select(.status == $status)' "$TASK_QUEUE" | jq -s 'length')
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No tasks with status: $filter_status${NC}"
        return
    fi
    
    printf "${BOLD}%-12s %-10s %-12s %-40s %-10s${NC}\n" \
        "TASK ID" "PRIORITY" "AGENT" "TITLE" "DURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r --arg status "$filter_status" '.tasks[] | select(.status == $status) | [
        .task_id,
        .priority,
        .assigned_to,
        .title,
        .estimated_duration
    ] | @tsv' "$TASK_QUEUE" | while IFS=$'\t' read -r id priority agent title duration; do
        local agent_icon=$(get_agent_icon "$agent")
        local priority_color=$(get_priority_color "$priority")
        
        if [[ ${#title} -gt 38 ]]; then
            title="${title:0:35}..."
        fi
        
        printf "%-12s ${priority_color}%-10s${NC} ${agent_icon} %-11s %-40s %-10s\n" \
            "$id" "$priority" "$agent" "$title" "$duration"
    done
    
    echo ""
    echo -e "${CYAN}Found:${NC} $count task(s)"
}

list_by_agent() {
    local filter_agent="$1"
    show_header
    
    local agent_icon=$(get_agent_icon "$filter_agent")
    echo -e "${CYAN}Filter:${NC} Agent = ${agent_icon} ${BOLD}$filter_agent${NC}"
    echo ""
    
    local count=$(jq --arg agent "$filter_agent" '.tasks[] | select(.assigned_to == $agent)' "$TASK_QUEUE" | jq -s 'length')
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No tasks assigned to: $filter_agent${NC}"
        return
    fi
    
    printf "${BOLD}%-12s %-8s %-10s %-40s %-10s${NC}\n" \
        "TASK ID" "STATUS" "PRIORITY" "TITLE" "DURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r --arg agent "$filter_agent" '.tasks[] | select(.assigned_to == $agent) | [
        .task_id,
        .status,
        .priority,
        .title,
        .estimated_duration
    ] | @tsv' "$TASK_QUEUE" | while IFS=$'\t' read -r id status priority title duration; do
        local status_icon=$(get_status_icon "$status")
        local priority_color=$(get_priority_color "$priority")
        
        if [[ ${#title} -gt 38 ]]; then
            title="${title:0:35}..."
        fi
        
        printf "%-12s ${status_icon} %-7s ${priority_color}%-10s${NC} %-40s %-10s\n" \
            "$id" "$status" "$priority" "$title" "$duration"
    done
    
    echo ""
    echo -e "${CYAN}Found:${NC} $count task(s)"
}

list_by_priority() {
    local filter_priority="$1"
    show_header
    
    local priority_color=$(get_priority_color "$filter_priority")
    echo -e "${CYAN}Filter:${NC} Priority = ${priority_color}${BOLD}$filter_priority${NC}"
    echo ""
    
    local count=$(jq --arg priority "$filter_priority" '.tasks[] | select(.priority == $priority)' "$TASK_QUEUE" | jq -s 'length')
    
    if [[ "$count" -eq 0 ]]; then
        echo -e "${YELLOW}No tasks with priority: $filter_priority${NC}"
        return
    fi
    
    printf "${BOLD}%-12s %-8s %-12s %-40s %-10s${NC}\n" \
        "TASK ID" "STATUS" "AGENT" "TITLE" "DURATION"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r --arg priority "$filter_priority" '.tasks[] | select(.priority == $priority) | [
        .task_id,
        .status,
        .assigned_to,
        .title,
        .estimated_duration
    ] | @tsv' "$TASK_QUEUE" | while IFS=$'\t' read -r id status agent title duration; do
        local status_icon=$(get_status_icon "$status")
        local agent_icon=$(get_agent_icon "$agent")
        
        if [[ ${#title} -gt 38 ]]; then
            title="${title:0:35}..."
        fi
        
        printf "%-12s ${status_icon} %-7s ${agent_icon} %-11s %-40s %-10s\n" \
            "$id" "$status" "$agent" "$title" "$duration"
    done
    
    echo ""
    echo -e "${CYAN}Found:${NC} $count task(s)"
}

show_task_detail() {
    local task_id="$1"
    
    local task=$(jq --arg id "$task_id" '.tasks[] | select(.task_id == $id)' "$TASK_QUEUE")
    
    if [[ -z "$task" ]]; then
        echo -e "${RED}✗${NC} Task not found: $task_id"
        return 1
    fi
    
    show_header
    
    local status=$(echo "$task" | jq -r '.status')
    local priority=$(echo "$task" | jq -r '.priority')
    local agent=$(echo "$task" | jq -r '.assigned_to')
    
    local status_icon=$(get_status_icon "$status")
    local agent_icon=$(get_agent_icon "$agent")
    local priority_color=$(get_priority_color "$priority")
    
    echo -e "${BOLD}${CYAN}Task Details${NC}"
    echo ""
    echo -e "${CYAN}ID:${NC}              $(echo "$task" | jq -r '.task_id')"
    echo -e "${CYAN}Title:${NC}           $(echo "$task" | jq -r '.title')"
    echo -e "${CYAN}Status:${NC}          $status_icon $(echo "$task" | jq -r '.status')"
    echo -e "${CYAN}Priority:${NC}        ${priority_color}$(echo "$task" | jq -r '.priority')${NC}"
    echo -e "${CYAN}Type:${NC}            $(echo "$task" | jq -r '.type')"
    echo -e "${CYAN}Assigned to:${NC}     $agent_icon $(echo "$task" | jq -r '.assigned_to')"
    echo -e "${CYAN}Autonomy:${NC}        $(echo "$task" | jq -r '.autonomy_level')%"
    echo -e "${CYAN}Duration:${NC}        $(echo "$task" | jq -r '.estimated_duration')"
    echo ""
    
    echo -e "${BOLD}Description:${NC}"
    echo "$(echo "$task" | jq -r '.description')"
    echo ""
    
    # Dependencies
    local deps=$(echo "$task" | jq -r '.dependencies | length')
    if [[ "$deps" -gt 0 ]]; then
        echo -e "${BOLD}Dependencies:${NC}"
        echo "$task" | jq -r '.dependencies[]' | while read -r dep; do
            echo "  • $dep"
        done
        echo ""
    fi
    
    # Input files
    local inputs=$(echo "$task" | jq -r '.input_files | length')
    if [[ "$inputs" -gt 0 ]]; then
        echo -e "${BOLD}Input Files:${NC}"
        echo "$task" | jq -r '.input_files[]' | while read -r file; do
            if [[ -e "$file" ]]; then
                echo -e "  ${GREEN}✓${NC} $file"
            else
                echo -e "  ${RED}✗${NC} $file ${DIM}(not found)${NC}"
            fi
        done
        echo ""
    fi
    
    # Output files
    local outputs=$(echo "$task" | jq -r '.output_files | length')
    if [[ "$outputs" -gt 0 ]]; then
        echo -e "${BOLD}Output Files:${NC}"
        echo "$task" | jq -r '.output_files[]' | while read -r file; do
            echo "  • $file"
        done
        echo ""
    fi
    
    # Tags
    local tags=$(echo "$task" | jq -r '.tags | length')
    if [[ "$tags" -gt 0 ]]; then
        echo -e "${BOLD}Tags:${NC}"
        echo -n "  "
        echo "$task" | jq -r '.tags[]' | tr '\n' ', ' | sed 's/, $/\n/'
        echo ""
    fi
    
    # Timestamps
    echo -e "${BOLD}Timestamps:${NC}"
    echo -e "  ${CYAN}Created:${NC}     $(echo "$task" | jq -r '.timestamps.created_at')"
    
    local started=$(echo "$task" | jq -r '.timestamps.started_at')
    if [[ "$started" != "null" ]]; then
        echo -e "  ${CYAN}Started:${NC}     $started"
    fi
    
    local completed=$(echo "$task" | jq -r '.timestamps.completed_at')
    if [[ "$completed" != "null" ]]; then
        echo -e "  ${CYAN}Completed:${NC}   $completed"
    fi
    
    echo ""
    echo -e "${DIM}Full JSON: jq '.tasks[] | select(.task_id == \"$task_id\")' $TASK_QUEUE${NC}"
}

show_summary() {
    show_header
    
    local total=$(jq '.tasks | length' "$TASK_QUEUE")
    
    echo -e "${BOLD}${CYAN}Queue Summary${NC}"
    echo ""
    
    # By status
    echo -e "${BOLD}By Status:${NC}"
    local pending=$(jq '.tasks[] | select(.status == "pending")' "$TASK_QUEUE" | jq -s 'length')
    local assigned=$(jq '.tasks[] | select(.status == "assigned")' "$TASK_QUEUE" | jq -s 'length')
    local in_progress=$(jq '.tasks[] | select(.status == "in_progress")' "$TASK_QUEUE" | jq -s 'length')
    local review=$(jq '.tasks[] | select(.status == "review")' "$TASK_QUEUE" | jq -s 'length')
    local completed=$(jq '.tasks[] | select(.status == "completed")' "$TASK_QUEUE" | jq -s 'length')
    local failed=$(jq '.tasks[] | select(.status == "failed")' "$TASK_QUEUE" | jq -s 'length')
    local blocked=$(jq '.tasks[] | select(.status == "blocked")' "$TASK_QUEUE" | jq -s 'length')
    
    echo "  ⏳ Pending:     $pending"
    echo "  📋 Assigned:    $assigned"
    echo "  🔄 In Progress: $in_progress"
    echo "  👁️  Review:      $review"
    echo "  ✅ Completed:   $completed"
    echo "  ❌ Failed:      $failed"
    echo "  🚫 Blocked:     $blocked"
    echo ""
    
    # By agent
    echo -e "${BOLD}By Agent:${NC}"
    local claude=$(jq '.tasks[] | select(.assigned_to == "claude")' "$TASK_QUEUE" | jq -s 'length')
    local chatgpt=$(jq '.tasks[] | select(.assigned_to == "chatgpt")' "$TASK_QUEUE" | jq -s 'length')
    local gemini=$(jq '.tasks[] | select(.assigned_to == "gemini")' "$TASK_QUEUE" | jq -s 'length')
    local grok=$(jq '.tasks[] | select(.assigned_to == "grok")' "$TASK_QUEUE" | jq -s 'length')
    local copilot=$(jq '.tasks[] | select(.assigned_to == "copilot")' "$TASK_QUEUE" | jq -s 'length')
    local auto=$(jq '.tasks[] | select(.assigned_to == "auto")' "$TASK_QUEUE" | jq -s 'length')
    
    echo "  🎭 Claude:      $claude"
    echo "  💬 ChatGPT:     $chatgpt"
    echo "  ✨ Gemini:      $gemini"
    echo "  ⚡ Grok:        $grok"
    echo "  🚀 Copilot:     $copilot"
    echo "  🤖 Auto:        $auto"
    echo ""
    
    # By priority
    echo -e "${BOLD}By Priority:${NC}"
    local critical=$(jq '.tasks[] | select(.priority == "critical")' "$TASK_QUEUE" | jq -s 'length')
    local high=$(jq '.tasks[] | select(.priority == "high")' "$TASK_QUEUE" | jq -s 'length')
    local medium=$(jq '.tasks[] | select(.priority == "medium")' "$TASK_QUEUE" | jq -s 'length')
    local low=$(jq '.tasks[] | select(.priority == "low")' "$TASK_QUEUE" | jq -s 'length')
    
    echo -e "  ${RED}🔴 Critical:${NC}  $critical"
    echo -e "  ${YELLOW}🟠 High:${NC}      $high"
    echo -e "  ${BLUE}🟡 Medium:${NC}    $medium"
    echo -e "  ${GREEN}🟢 Low:${NC}       $low"
    echo ""
    
    echo -e "${CYAN}Total tasks:${NC} $total"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Orkestra Task List Viewer${NC}

${BOLD}USAGE:${NC}
    $0 [command] [options]

${BOLD}COMMANDS:${NC}
    ${GREEN}all${NC}                     List all tasks (default)
    ${GREEN}summary${NC}                 Show queue summary
    ${GREEN}status <status>${NC}         Filter by status
    ${GREEN}agent <agent>${NC}           Filter by agent
    ${GREEN}priority <priority>${NC}     Filter by priority
    ${GREEN}detail <task_id>${NC}        Show task details
    ${GREEN}help${NC}                    Show this help

${BOLD}STATUS OPTIONS:${NC}
    pending, assigned, in_progress, review, completed, failed, blocked

${BOLD}AGENT OPTIONS:${NC}
    claude, chatgpt, gemini, grok, copilot, auto

${BOLD}PRIORITY OPTIONS:${NC}
    critical, high, medium, low

${BOLD}EXAMPLES:${NC}
    ${CYAN}# List all tasks${NC}
    $0
    $0 all

    ${CYAN}# Show summary${NC}
    $0 summary

    ${CYAN}# Filter by status${NC}
    $0 status pending
    $0 status in_progress

    ${CYAN}# Filter by agent${NC}
    $0 agent claude
    $0 agent chatgpt

    ${CYAN}# Filter by priority${NC}
    $0 priority critical
    $0 priority high

    ${CYAN}# Show task details${NC}
    $0 detail task_0001

${BOLD}TASK QUEUE:${NC}
    ${CYAN}$TASK_QUEUE${NC}

EOF
}

main() {
    # Check if task queue exists
    if [[ ! -f "$TASK_QUEUE" ]]; then
        echo -e "${RED}✗${NC} Task queue not found: $TASK_QUEUE"
        exit 1
    fi
    
    local command="${1:-all}"
    
    case "$command" in
        all)
            list_all
            ;;
        summary|sum)
            show_summary
            ;;
        status|s)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Status filter required"
                echo "Usage: $0 status <pending|assigned|in_progress|review|completed|failed|blocked>"
                exit 1
            fi
            list_by_status "$2"
            ;;
        agent|a)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Agent filter required"
                echo "Usage: $0 agent <claude|chatgpt|gemini|grok|copilot|auto>"
                exit 1
            fi
            list_by_agent "$2"
            ;;
        priority|p)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Priority filter required"
                echo "Usage: $0 priority <critical|high|medium|low>"
                exit 1
            fi
            list_by_priority "$2"
            ;;
        detail|d)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Task ID required"
                echo "Usage: $0 detail <task_id>"
                exit 1
            fi
            show_task_detail "$2"
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
