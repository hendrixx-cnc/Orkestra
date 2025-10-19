#!/bin/bash
# AUTO EXECUTOR WITH SELF-RECOVERY
# Allows AIs to automatically handle errors and continue through task queues

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
RECOVERY_DIR="$SCRIPT_DIR/recovery"
LOG_FILE="$RECOVERY_DIR/auto_execution_$(date +%Y%m%d).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure recovery directory exists
mkdir -p "$RECOVERY_DIR"

# Log function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Execute task with automatic error recovery
execute_task_with_recovery() {
    local ai_name="$1"
    local task_id="$2"
    local agent_script=""
    local max_retries=3
    local retry_count=0
    
    # Determine agent script
    case "$ai_name" in
        claude) agent_script="claude_agent.sh" ;;
        chatgpt) agent_script="chatgpt_agent.sh" ;;
        gemini) agent_script="gemini_agent.sh" ;;
        grok) agent_script="grok_agent.sh" ;;
        *)
            log_message "ERROR" "Unknown AI: $ai_name"
            return 1
            ;;
    esac
    
    log_message "INFO" "Starting Task #$task_id with $ai_name"
    
    while [ $retry_count -lt $max_retries ]; do
        # Execute task with timeout and error capture
        local output_file=$(mktemp)
        local error_file=$(mktemp)
        
        timeout 600 bash "$SCRIPT_DIR/$agent_script" execute "$task_id" > "$output_file" 2> "$error_file"
        local exit_code=$?
        
        # Check result
        if [ $exit_code -eq 0 ]; then
            log_message "SUCCESS" "Task #$task_id completed by $ai_name"
            rm -f "$output_file" "$error_file"
            return 0
        fi
        
        # Handle specific errors
        local error_content=$(cat "$error_file")
        retry_count=$((retry_count + 1))
        
        if [ $exit_code -eq 124 ]; then
            # Timeout
            log_message "WARN" "Task #$task_id timed out (attempt $retry_count/$max_retries)"
            bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" 2>/dev/null || true
            
        elif echo "$error_content" | grep -q "TASK ALREADY ASSIGNED"; then
            # Assignment conflict - skip this task
            log_message "WARN" "Task #$task_id already assigned to different AI, skipping"
            rm -f "$output_file" "$error_file"
            return 2
            
        elif echo "$error_content" | grep -q "No such file or directory"; then
            # File/directory error - try to fix
            log_message "WARN" "File error in Task #$task_id, creating missing directories..."
            
            # Extract path from error and create directory
            local missing_path=$(echo "$error_content" | grep -oP '/[^:]+(?=: No such file)' | head -1)
            if [ -n "$missing_path" ]; then
                mkdir -p "$(dirname "$missing_path")" 2>/dev/null || true
                log_message "INFO" "Created directory: $(dirname "$missing_path")"
            fi
            
        elif echo "$error_content" | grep -qi "API.*error\|rate limit\|quota"; then
            # API error - wait and retry
            local wait_time=$((30 * retry_count))
            log_message "WARN" "API error for Task #$task_id, waiting ${wait_time}s before retry..."
            sleep "$wait_time"
            bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" 2>/dev/null || true
            
        elif echo "$error_content" | grep -q "DEPENDENCIES NOT MET"; then
            # Dependency issue - skip for now
            log_message "WARN" "Task #$task_id dependencies not met, will retry later"
            rm -f "$output_file" "$error_file"
            return 3
            
        else
            # Unknown error
            log_message "ERROR" "Task #$task_id failed with unknown error (attempt $retry_count/$max_retries)"
            log_message "ERROR" "Error: $(echo "$error_content" | head -5)"
            bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" 2>/dev/null || true
        fi
        
        rm -f "$output_file" "$error_file"
        
        # Wait before retry
        if [ $retry_count -lt $max_retries ]; then
            log_message "INFO" "Retrying Task #$task_id in 10 seconds..."
            sleep 10
        fi
    done
    
    # All retries exhausted
    log_message "ERROR" "Task #$task_id failed after $max_retries attempts"
    
    # Record failure for manual review
    bash "$SCRIPT_DIR/task_recovery.sh" record "$task_id" "$ai_name" "max_retries_exceeded" "Failed after $max_retries attempts" 2>/dev/null || true
    
    # Reset task to pending so another AI can try
    local tmp_file=$(mktemp)
    jq --arg tid "$task_id" \
       '(.queue[] | select(.id == ($tid | tonumber)) | .status) = "pending"' \
       "$TASK_QUEUE" > "$tmp_file" && mv "$tmp_file" "$TASK_QUEUE"
    
    return 1
}

# Get next available task for AI (FCFS - First Come First Serve)
get_next_task() {
    local ai_name="$1"
    
    # Get first pending task assigned to this AI (by task ID order = FCFS)
    # No priority sorting - just grab the next one in line
    local task_id=$(jq -r --arg ai "$ai_name" \
        '.queue[] | 
         select(.assigned_to == $ai and (.status == "pending" or .status == "waiting")) | 
         select(.dependencies == null or .dependencies == [] or 
                (.dependencies | all(. as $dep | any($dep == .queue[].id and .queue[].status == "completed")))) |
         .id' \
        "$TASK_QUEUE" | sort -n | head -1)
    
    echo "$task_id"
}

# Continuous execution mode
continuous_mode() {
    local ai_name="$1"
    local max_tasks="${2:-10}"
    local tasks_completed=0
    
    log_message "INFO" "Starting continuous mode for $ai_name (max $max_tasks tasks)"
    
    while [ $tasks_completed -lt $max_tasks ]; do
        local next_task=$(get_next_task "$ai_name")
        
        if [ -z "$next_task" ] || [ "$next_task" = "null" ]; then
            log_message "INFO" "No more tasks available for $ai_name"
            break
        fi
        
        execute_task_with_recovery "$ai_name" "$next_task"
        local result=$?
        
        if [ $result -eq 0 ]; then
            tasks_completed=$((tasks_completed + 1))
            log_message "INFO" "Progress: $tasks_completed/$max_tasks tasks completed"
        elif [ $result -eq 2 ] || [ $result -eq 3 ]; then
            # Skip conflicts and dependency issues
            log_message "INFO" "Skipping task and trying next one"
        fi
        
        # Small delay between tasks
        sleep 2
    done
    
    log_message "INFO" "Continuous mode finished for $ai_name: $tasks_completed tasks completed"
}

# Batch mode - process all pending tasks for AI
batch_mode() {
    local ai_name="$1"
    
    log_message "INFO" "Starting batch mode for $ai_name"
    
    # Get all pending tasks for this AI
    local tasks=$(jq -r --arg ai "$ai_name" \
        '.queue[] | 
         select(.assigned_to == $ai and (.status == "pending" or .status == "waiting")) | 
         .id' \
        "$TASK_QUEUE")
    
    if [ -z "$tasks" ]; then
        log_message "INFO" "No pending tasks for $ai_name"
        return
    fi
    
    local total=$(echo "$tasks" | wc -l)
    local completed=0
    
    log_message "INFO" "Found $total tasks for $ai_name"
    
    for task_id in $tasks; do
        execute_task_with_recovery "$ai_name" "$task_id"
        if [ $? -eq 0 ]; then
            completed=$((completed + 1))
        fi
        
        log_message "INFO" "Progress: $completed/$total tasks completed"
        sleep 2
    done
    
    log_message "INFO" "Batch mode finished for $ai_name: $completed/$total tasks completed"
}

# Main execution
main() {
    local mode="${1:-}"
    local ai_name="${2:-}"
    local count="${3:-10}"
    
    if [ -z "$mode" ]; then
        echo "Usage: $0 <mode> <ai_name> [count]"
        echo ""
        echo "Modes:"
        echo "  continuous <ai> [count]  - Execute up to [count] tasks (default: 10)"
        echo "  batch <ai>               - Execute all pending tasks"
        echo "  single <ai> <task_id>    - Execute single task with recovery"
        echo "  all-continuous [count]   - Run all AIs in continuous mode"
        echo ""
        echo "AI names: claude, chatgpt, gemini, grok"
        echo ""
        echo "Examples:"
        echo "  $0 continuous gemini 5"
        echo "  $0 batch claude"
        echo "  $0 single chatgpt 14"
        echo "  $0 all-continuous 20"
        exit 1
    fi
    
    case "$mode" in
        continuous)
            continuous_mode "$ai_name" "$count"
            ;;
        batch)
            batch_mode "$ai_name"
            ;;
        single)
            execute_task_with_recovery "$ai_name" "$count"
            ;;
        all-continuous)
            log_message "INFO" "Starting all AIs in continuous mode (max $ai_name tasks each)"
            
            # Run each AI in background
            continuous_mode "gemini" "$ai_name" &
            continuous_mode "claude" "$ai_name" &
            continuous_mode "chatgpt" "$ai_name" &
            continuous_mode "grok" "$ai_name" &
            
            # Wait for all to complete
            wait
            log_message "INFO" "All AIs completed continuous mode"
            ;;
        *)
            echo "Unknown mode: $mode"
            exit 1
            ;;
    esac
}

main "$@"
