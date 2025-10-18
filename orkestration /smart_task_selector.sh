#!/bin/bash
# SMART TASK SELECTOR
# Any AI can do any task - priority given to AIs best suited for the task

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Function: Calculate AI suitability score for a task (0-100)
calculate_suitability_score() {
    local ai_name="$1"
    local task_id="$2"
    
    # Get task details
    local task_title=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$TASK_QUEUE")
    local task_instructions=$(jq -r ".queue[] | select(.id == $task_id) | .instructions // \"\"" "$TASK_QUEUE")
    local task_text="$task_title $task_instructions"
    
    # Get AI specialties
    local specialties=$(jq -r ".ai_agents[] | select(.name == \"$ai_name\") | .specialties[]" "$TASK_QUEUE")
    
    local score=50  # Base score - any AI can do any task
    
    # Boost score based on specialty matches
    while IFS= read -r specialty; do
        case "$specialty" in
            firebase|google_cloud|database_design|scaling|cost_optimization)
                if echo "$task_text" | grep -qi "firebase\|firestore\|cloud\|database\|scaling\|migration"; then
                    score=$((score + 15))
                fi
                ;;
            copywriting|marketing|creative_content)
                if echo "$task_text" | grep -qi "copy\|marketing\|landing\|newsletter\|content\|write"; then
                    score=$((score + 15))
                fi
                ;;
            content_review|tone_validation|documentation)
                if echo "$task_text" | grep -qi "review\|test\|documentation\|mobile\|ux\|tone"; then
                    score=$((score + 15))
                fi
                ;;
            svg_design|icon_creation|visual_design)
                if echo "$task_text" | grep -qi "design\|svg\|icon\|visual\|graphic\|ui"; then
                    score=$((score + 15))
                fi
                ;;
            project_management|system_maintenance)
                if echo "$task_text" | grep -qi "setup\|config\|system\|environment\|deploy"; then
                    score=$((score + 15))
                fi
                ;;
        esac
    done <<< "$specialties"
    
    # Cap at 100
    if [ $score -gt 100 ]; then
        score=100
    fi
    
    echo "$score"
}

# Function: Get AI current workload (0-100 scale)
get_workload_score() {
    local ai_name="$1"
    
    # Count in_progress tasks
    local active=$(jq -r ".queue[] | select(.status == \"in_progress\" and .assigned_to == \"$ai_name\") | .id" "$TASK_QUEUE" 2>/dev/null | wc -l)
    active=$(echo "$active" | tr -d '[:space:]')
    active=${active:-0}
    
    # Count locked tasks
    local locked=0
    if [ -d "$SCRIPT_DIR/locks" ]; then
        local lock_count=$(find "$SCRIPT_DIR/locks" -maxdepth 1 -type d -name "task_*.lock" 2>/dev/null | \
                 while read -r lock_dir; do
                     if [ -f "$lock_dir/owner" ]; then
                         cat "$lock_dir/owner"
                     fi
                 done | grep -c "^$ai_name$" 2>/dev/null)
        locked=${lock_count:-0}
    fi
    
    # Ensure numeric values
    case "$active" in
        ''|*[!0-9]*) active=0 ;;
    esac
    case "$locked" in
        ''|*[!0-9]*) locked=0 ;;
    esac
    
    local total=$((active + locked))
    
    # Convert to penalty score (more tasks = higher penalty)
    local penalty=$((total * 20))  # Each task adds 20 penalty points
    
    echo "$penalty"
}

# Function: Select best AI for a task
select_best_ai() {
    local task_id="$1"
    
    # Get all active AIs
    local ai_list=$(jq -r '.ai_agents[] | select(.status == "active") | .name' "$TASK_QUEUE")
    
    local best_ai=""
    local best_score=-999
    
    while IFS= read -r ai_name; do
        # Calculate suitability score
        local suitability=$(calculate_suitability_score "$ai_name" "$task_id")
        
        # Get workload penalty
        local workload_penalty=$(get_workload_score "$ai_name")
        
        # Final score = suitability - workload_penalty
        local final_score=$((suitability - workload_penalty))
        
        if [ $final_score -gt $best_score ]; then
            best_score=$final_score
            best_ai="$ai_name"
        fi
    done <<< "$ai_list"
    
    echo "$best_ai"
}

# Function: Reassign all unassigned tasks
reassign_all_tasks() {
    echo "Reassigning all pending tasks based on AI suitability and availability..."
    
    local pending_tasks=$(jq -r '.queue[] | select(.status == "pending") | .id' "$TASK_QUEUE")
    
    local count=0
    while IFS= read -r task_id; do
        [ -z "$task_id" ] && continue
        
        local best_ai=$(select_best_ai "$task_id")
        local task_title=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$TASK_QUEUE")
        
        echo "Task #$task_id: $task_title -> $best_ai"
        
        # Update assigned_to field (but don't claim yet)
        jq ".queue |= map(if .id == $task_id then .assigned_to = \"$best_ai\" else . end)" \
            "$TASK_QUEUE" > "${TASK_QUEUE}.tmp" && mv "${TASK_QUEUE}.tmp" "$TASK_QUEUE"
        
        count=$((count + 1))
    done <<< "$pending_tasks"
    
    echo "Reassigned $count tasks"
}

# Function: Show recommendations for next tasks
show_recommendations() {
    echo "AI Task Recommendations (Best Matches):"
    echo "========================================"
    
    local ai_list=$(jq -r '.ai_agents[] | select(.status == "active") | .name' "$TASK_QUEUE")
    
    while IFS= read -r ai_name; do
        echo ""
        echo "[$ai_name]"
        
        local pending_tasks=$(jq -r '.queue[] | select(.status == "pending") | .id' "$TASK_QUEUE")
        local best_task=""
        local best_score=-999
        
        while IFS= read -r task_id; do
            [ -z "$task_id" ] && continue
            
            local suitability=$(calculate_suitability_score "$ai_name" "$task_id")
            local workload_penalty=$(get_workload_score "$ai_name")
            local score=$((suitability - workload_penalty))
            
            if [ $score -gt $best_score ]; then
                best_score=$score
                best_task=$task_id
            fi
        done <<< "$pending_tasks"
        
        if [ -n "$best_task" ]; then
            local task_title=$(jq -r ".queue[] | select(.id == $best_task) | .title" "$TASK_QUEUE")
            echo "  Best match: Task #$best_task - $task_title (score: $best_score)"
        else
            echo "  No pending tasks available"
        fi
    done <<< "$ai_list"
}

# Main command dispatcher
case "${1:-}" in
    select)
        select_best_ai "$2"
        ;;
    reassign)
        reassign_all_tasks
        ;;
    recommend)
        show_recommendations
        ;;
    score)
        if [ -n "$2" ] && [ -n "$3" ]; then
            calculate_suitability_score "$2" "$3"
        else
            echo "Usage: $0 score <ai_name> <task_id>"
            exit 1
        fi
        ;;
    *)
        echo "Smart Task Selector - Dynamic AI Assignment"
        echo ""
        echo "Usage:"
        echo "  $0 select <task_id>     - Select best AI for a task"
        echo "  $0 reassign             - Reassign all pending tasks"
        echo "  $0 recommend            - Show recommendations for all AIs"
        echo "  $0 score <ai> <task>    - Calculate suitability score"
        exit 1
        ;;
esac
