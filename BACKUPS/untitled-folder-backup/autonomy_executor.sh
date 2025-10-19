#!/bin/bash
# AUTONOMY-AWARE TASK EXECUTOR
# Checks autonomy levels and consults user when needed

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AUTONOMY_CONFIG="$SCRIPT_DIR/autonomy_config.json"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
USER_APPROVAL_DIR="$SCRIPT_DIR/user_approvals"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$USER_APPROVAL_DIR"

# Get task type from task title
get_task_type() {
    local task_title="$1"
    
    # Check patterns from config
    local patterns=$(jq -r '.task_type_mapping | to_entries[] | "\(.key):\(.value)"' "$AUTONOMY_CONFIG")
    
    while IFS=: read -r pattern type; do
        if echo "$task_title" | grep -qiE "$pattern"; then
            echo "$type"
            return 0
        fi
    done
    
    # Default to content if no match
    echo "content"
}

# Get autonomy level for task type
get_autonomy_level() {
    local task_type="$1"
    jq -r --arg type "$task_type" '.autonomy_levels[$type] // 50' "$AUTONOMY_CONFIG"
}

# Check if task requires user consultation
requires_consultation() {
    local autonomy_level="$1"
    local threshold=$(jq -r '.consultation_rules.require_approval_below' "$AUTONOMY_CONFIG")
    
    [ "$autonomy_level" -lt "$threshold" ]
}

# Check if task requires iteration with user
requires_iteration() {
    local autonomy_level="$1"
    local threshold=$(jq -r '.consultation_rules.iterate_with_user_below' "$AUTONOMY_CONFIG")
    
    [ "$autonomy_level" -lt "$threshold" ]
}

# Present work to user for approval
request_user_approval() {
    local task_id="$1"
    local task_title="$2"
    local task_type="$3"
    local autonomy_level="$4"
    local output_file="$5"
    local iteration="${6:-1}"
    
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           USER APPROVAL REQUIRED                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Task #$task_id:${NC} $task_title"
    echo -e "${BLUE}Type:${NC} $task_type"
    echo -e "${BLUE}Autonomy Level:${NC} ${autonomy_level}% (requires approval)"
    echo -e "${BLUE}Iteration:${NC} $iteration"
    echo ""
    
    if [ -n "$output_file" ] && [ -f "$output_file" ]; then
        echo -e "${YELLOW}📄 Generated Output:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        head -50 "$output_file"
        if [ $(wc -l < "$output_file") -gt 50 ]; then
            echo ""
            echo "... ($(wc -l < "$output_file") total lines, showing first 50)"
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo -e "${BLUE}Full output:${NC} $output_file"
    fi
    
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo "  [a] Approve - Task complete, mark as done"
    echo "  [i] Iterate - Provide feedback for AI to revise"
    echo "  [s] Skip - Skip this task for now"
    echo "  [r] Reject - Reject and reset task to pending"
    echo ""
    
    # Save approval request
    local approval_file="$USER_APPROVAL_DIR/task_${task_id}_iter_${iteration}.json"
    jq -n \
        --arg task_id "$task_id" \
        --arg title "$task_title" \
        --arg type "$task_type" \
        --arg level "$autonomy_level" \
        --arg output "$output_file" \
        --arg iter "$iteration" \
        --arg timestamp "$(date -Iseconds)" \
        '{
            task_id: $task_id,
            title: $title,
            type: $type,
            autonomy_level: $level,
            output_file: $output,
            iteration: $iter,
            timestamp: $timestamp,
            status: "pending_approval"
        }' > "$approval_file"
    
    echo -e "${YELLOW}⏸️  Task paused - waiting for your decision${NC}"
    echo -e "${YELLOW}Approval request saved: $approval_file${NC}"
    echo ""
    echo "To respond:"
    echo "  bash respond_to_approval.sh $task_id [a|i|s|r] [feedback]"
    echo ""
    
    return 2  # Return code 2 = pending user approval
}

# Execute task with autonomy awareness
execute_with_autonomy() {
    local ai_name="$1"
    local task_id="$2"
    
    # Get task details
    local task_details=$(jq --arg id "$task_id" '.queue[] | select(.id == ($id | tonumber))' "$TASK_QUEUE")
    local task_title=$(echo "$task_details" | jq -r '.title')
    local task_status=$(echo "$task_details" | jq -r '.status')
    
    # Check if already pending approval
    local approval_file="$USER_APPROVAL_DIR/task_${task_id}_iter_*.json"
    if compgen -G "$approval_file" > /dev/null 2>&1; then
        local latest_approval=$(ls -t $approval_file 2>/dev/null | head -1)
        local approval_status=$(jq -r '.status' "$latest_approval" 2>/dev/null)
        
        if [ "$approval_status" = "pending_approval" ]; then
            echo -e "${YELLOW}⏸️  Task #$task_id already pending user approval${NC}"
            echo "   Check: $latest_approval"
            return 2
        fi
    fi
    
    # Determine task type and autonomy level
    local task_type=$(get_task_type "$task_title")
    local autonomy_level=$(get_autonomy_level "$task_type")
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Task #$task_id:${NC} $task_title"
    echo -e "${BLUE}Type:${NC} $task_type | ${BLUE}Autonomy:${NC} ${autonomy_level}%"
    
    if [ "$autonomy_level" -ge 100 ]; then
        echo -e "${GREEN}✓ Fully autonomous - executing without consultation${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Execute normally
        bash "$SCRIPT_DIR/auto_executor_with_recovery.sh" single "$ai_name" "$task_id"
        return $?
        
    elif requires_consultation "$autonomy_level"; then
        echo -e "${YELLOW}⚠️  Requires user approval (autonomy < 50%)${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Execute task first
        local output_file=$(jq -r --arg id "$task_id" '.queue[] | select(.id == ($id | tonumber)) | .output_file' "$TASK_QUEUE")
        bash "$SCRIPT_DIR/auto_executor_with_recovery.sh" single "$ai_name" "$task_id"
        
        # If successful, request approval
        if [ $? -eq 0 ]; then
            request_user_approval "$task_id" "$task_title" "$task_type" "$autonomy_level" "$SCRIPT_DIR/../$output_file" 1
            return 2
        fi
        
    elif requires_iteration "$autonomy_level"; then
        echo -e "${YELLOW}ℹ️  May iterate with user (autonomy < 75%)${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        # Execute and complete, but make available for review
        bash "$SCRIPT_DIR/auto_executor_with_recovery.sh" single "$ai_name" "$task_id"
        local result=$?
        
        if [ $result -eq 0 ]; then
            echo -e "${GREEN}✓ Task completed${NC}"
            echo -e "${CYAN}💡 You can review and request changes if needed${NC}"
        fi
        
        return $result
    else
        echo -e "${GREEN}✓ High autonomy - executing independently${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        bash "$SCRIPT_DIR/auto_executor_with_recovery.sh" single "$ai_name" "$task_id"
        return $?
    fi
}

# Get next task with dependency checking only
get_next_fcfs_task() {
    local ai_name="$1"
    
    # Get oldest pending task for this AI with met dependencies
    local task_id=$(jq -r --arg ai "$ai_name" '
        .queue[] | 
        select(.assigned_to == $ai and (.status == "pending" or .status == "waiting")) |
        select(.dependencies == null or .dependencies == [] or 
               (.dependencies | all(. as $dep | 
                   any([$dep] | inside([.queue[].id]) and 
                       (.queue[] | select(.id == $dep) | .status == "completed"))
               ))
        ) |
        .id
    ' "$TASK_QUEUE" | head -1)
    
    echo "$task_id"
}

# Idle tasks when no work available
perform_idle_tasks() {
    local ai_name="$1"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}   $ai_name - No tasks available${NC}"
    echo -e "${CYAN}   Performing idle tasks (100% autonomous)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Check for errors in completed tasks
    echo -e "${BLUE}🔍 Running error checks...${NC}"
    bash "$SCRIPT_DIR/error_check.sh" 2>/dev/null || echo "No errors found"
    
    # Check for inconsistencies
    echo -e "${BLUE}🔍 Running inconsistency checks...${NC}"
    bash "$SCRIPT_DIR/consistency_check.sh" 2>/dev/null || echo "No inconsistencies found"
    
    # Review documentation
    echo -e "${BLUE}📖 Reviewing documentation...${NC}"
    local doc_files=$(find "$SCRIPT_DIR/.." -name "*.md" -mtime -1 | head -5)
    if [ -n "$doc_files" ]; then
        echo "Recent documentation files reviewed:"
        echo "$doc_files" | sed 's/^/  • /'
    fi
    
    echo ""
    echo -e "${YELLOW}⏸️  Waiting for new tasks or user input...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Main execution loop
main() {
    local ai_name="$1"
    local mode="${2:-continuous}"
    local max_tasks="${3:-10}"
    
    if [ -z "$ai_name" ]; then
        echo "Usage: $0 <ai_name> [mode] [max_tasks]"
        echo ""
        echo "Modes:"
        echo "  continuous [N]  - Process up to N tasks"
        echo "  single <id>     - Execute single task with autonomy check"
        echo "  idle            - Perform idle tasks (error/consistency checks)"
        echo ""
        exit 1
    fi
    
    case "$mode" in
        single)
            execute_with_autonomy "$ai_name" "$max_tasks"
            ;;
            
        idle)
            perform_idle_tasks "$ai_name"
            ;;
            
        continuous)
            local completed=0
            local skipped=0
            
            while [ $completed -lt $max_tasks ]; do
                local next_task=$(get_next_fcfs_task "$ai_name")
                
                if [ -z "$next_task" ] || [ "$next_task" = "null" ]; then
                    echo ""
                    echo -e "${YELLOW}No more available tasks for $ai_name${NC}"
                    
                    # Perform idle tasks
                    perform_idle_tasks "$ai_name"
                    break
                fi
                
                execute_with_autonomy "$ai_name" "$next_task"
                local result=$?
                
                if [ $result -eq 0 ]; then
                    completed=$((completed + 1))
                    echo -e "${GREEN}✓ Progress: $completed/$max_tasks tasks completed${NC}"
                elif [ $result -eq 2 ]; then
                    # Pending approval - skip for now
                    skipped=$((skipped + 1))
                    echo -e "${YELLOW}⏸️  Task pending approval (will resume after user feedback)${NC}"
                fi
                
                sleep 2
            done
            
            echo ""
            echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}$ai_name Summary:${NC}"
            echo "  Completed: $completed tasks"
            echo "  Pending Approval: $skipped tasks"
            echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            ;;
            
        *)
            echo "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

main "$@"
