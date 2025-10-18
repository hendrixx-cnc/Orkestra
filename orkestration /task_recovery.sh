#!/bin/bash
# ERROR RECOVERY & RETRY SYSTEM
# Handles failures, timeouts, and automatic retry logic

RECOVERY_DIR="/workspaces/The-Quantum-Self-/AI/recovery"
FAILED_TASKS="$RECOVERY_DIR/failed_tasks.json"
RETRY_CONFIG="$RECOVERY_DIR/retry_config.json"

# Ensure recovery directory exists
mkdir -p "$RECOVERY_DIR"
[ -f "$FAILED_TASKS" ] || echo '{"failed": []}' > "$FAILED_TASKS"

# Initialize retry config if missing
if [ ! -f "$RETRY_CONFIG" ]; then
    cat > "$RETRY_CONFIG" << 'EOF'
{
  "max_retries": 3,
  "retry_delay_seconds": 300,
  "backoff_multiplier": 2,
  "timeout_seconds": 7200,
  "poison_pill_threshold": 5,
  "auto_reassign": true
}
EOF
fi

# Function: Record task failure
record_failure() {
    local task_id="$1"
    local ai_name="$2"
    local error_type="$3"
    local error_details="$4"
    
    local timestamp=$(date -Iseconds)
    
    # Add failure record
    local tmp_file=$(mktemp)
    jq --arg task "$task_id" \
       --arg ai "$ai_name" \
       --arg type "$error_type" \
       --arg details "$error_details" \
       --arg ts "$timestamp" \
       '.failed += [{
           task_id: ($task | tonumber),
           ai_name: $ai,
           error_type: $type,
           error_details: $details,
           timestamp: $ts,
           retry_count: 0,
           status: "pending_retry"
       }]' "$FAILED_TASKS" > "$tmp_file" && mv "$tmp_file" "$FAILED_TASKS"
    
    echo "❌ Failure recorded: Task #$task_id ($error_type)"
    
    # Log to audit trail
    bash /workspaces/The-Quantum-Self-/AI/task_audit.sh log \
        "FAILED" "$task_id" "$ai_name" "$error_details" "$error_type"
    
    # Release lock
    bash /workspaces/The-Quantum-Self-/AI/task_lock.sh release "$task_id" "ERROR"
}

# Function: Check if task should be retried
should_retry() {
    local task_id="$1"
    
    local max_retries=$(jq -r '.max_retries' "$RETRY_CONFIG")
    local retry_count=$(jq -r ".failed[] | select(.task_id == $task_id) | .retry_count" "$FAILED_TASKS" | tail -1)
    
    if [ -z "$retry_count" ]; then
        return 0  # Not in failed list, can proceed
    fi
    
    if [ "$retry_count" -lt "$max_retries" ]; then
        return 0  # Under retry limit
    else
        return 1  # Exceeded retry limit
    fi
}

# Function: Calculate retry delay (exponential backoff)
get_retry_delay() {
    local retry_count="$1"
    
    local base_delay=$(jq -r '.retry_delay_seconds' "$RETRY_CONFIG")
    local multiplier=$(jq -r '.backoff_multiplier' "$RETRY_CONFIG")
    
    # Exponential backoff: delay * (multiplier ^ retry_count)
    local delay=$(echo "$base_delay * ($multiplier ^ $retry_count)" | bc)
    echo "${delay%.*}"  # Round to integer
}

# Function: Retry failed task
retry_task() {
    local task_id="$1"
    local ai_name="${2:-auto}"
    
    # Check if task is in failed list
    local failure=$(jq -r ".failed[] | select(.task_id == $task_id and .status == \"pending_retry\")" "$FAILED_TASKS" | head -1)
    
    if [ -z "$failure" ]; then
        echo "⚠️  Task #$task_id not found in failed tasks"
        return 1
    fi
    
    # Check retry limit
    if ! should_retry "$task_id"; then
        echo "❌ Task #$task_id exceeded max retries (poison pill)"
        mark_poison_pill "$task_id"
        return 1
    fi
    
    # Get retry count and delay
    local retry_count=$(echo "$failure" | jq -r '.retry_count')
    local delay=$(get_retry_delay "$retry_count")
    local last_attempt=$(echo "$failure" | jq -r '.timestamp')
    local time_since=$(( $(date +%s) - $(date -d "$last_attempt" +%s 2>/dev/null || echo 0) ))
    
    if [ "$time_since" -lt "$delay" ]; then
        local wait_time=$((delay - time_since))
        echo "⏳ Too soon to retry. Wait $wait_time more seconds."
        return 1
    fi
    
    echo "🔄 Retrying Task #$task_id (attempt $((retry_count + 1)))"
    
    # Auto-reassign if enabled
    if [ "$ai_name" = "auto" ] && [ "$(jq -r '.auto_reassign' "$RETRY_CONFIG")" = "true" ]; then
        ai_name=$(select_best_ai "$task_id")
        echo "   Auto-assigned to: $ai_name"
    fi
    
    # Update retry count
    local tmp_file=$(mktemp)
    jq --arg task "$task_id" \
       '(.failed[] | select(.task_id == ($task | tonumber) and .status == "pending_retry") | .retry_count) |= (. + 1) |
        (.failed[] | select(.task_id == ($task | tonumber) and .status == "pending_retry") | .timestamp) |= now | todate |
        (.failed[] | select(.task_id == ($task | tonumber) and .status == "pending_retry") | .ai_name) |= "'"$ai_name"'"' \
       "$FAILED_TASKS" > "$tmp_file" && mv "$tmp_file" "$FAILED_TASKS"
    
    # Log retry attempt
    bash /workspaces/The-Quantum-Self-/AI/task_audit.sh log \
        "RETRY" "$task_id" "$ai_name" "Retry attempt $((retry_count + 1))" "pending"
    
    echo "✅ Task #$task_id ready for retry by $ai_name"
    echo "   Run: bash claim_task.sh $task_id $ai_name"
}

# Function: Mark task as poison pill
mark_poison_pill() {
    local task_id="$1"
    
    echo "☠️  Marking Task #$task_id as POISON PILL"
    
    local tmp_file=$(mktemp)
    jq --arg task "$task_id" \
       '(.failed[] | select(.task_id == ($task | tonumber)) | .status) |= "poison_pill"' \
       "$FAILED_TASKS" > "$tmp_file" && mv "$tmp_file" "$FAILED_TASKS"
    
    # Log poison pill
    bash /workspaces/The-Quantum-Self-/AI/task_audit.sh log \
        "POISON_PILL" "$task_id" "SYSTEM" "Exceeded max retries - manual intervention required" "poison_pill"
    
    echo "⚠️  MANUAL INTERVENTION REQUIRED for Task #$task_id"
}

# Function: Clear task from failed list
clear_failure() {
    local task_id="$1"
    
    local tmp_file=$(mktemp)
    jq --arg task "$task_id" \
       '.failed = [.failed[] | select(.task_id != ($task | tonumber))]' \
       "$FAILED_TASKS" > "$tmp_file" && mv "$tmp_file" "$FAILED_TASKS"
    
    echo "✅ Cleared Task #$task_id from failed tasks"
}

# Function: Select best AI for retry (load balancing)
select_best_ai() {
    local task_id="$1"
    
    # Get task type from queue
    local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type" \
        /workspaces/The-Quantum-Self-/TASK_QUEUE.json 2>/dev/null || echo "technical")
    
    # AI selection logic based on task type and current load
    case "$task_type" in
        content)
            echo "Claude"
            ;;
        creative)
            echo "ChatGPT"
            ;;
        technical|*)
            echo "Copilot"
            ;;
    esac
}

# Function: List failed tasks
list_failures() {
    echo "❌ Failed Tasks:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    jq -r '.failed[] | select(.status == "pending_retry") | 
        "Task #\(.task_id) | \(.ai_name) | Retries: \(.retry_count) | \(.error_type) | \(.timestamp)"' \
        "$FAILED_TASKS"
    
    echo ""
    echo "☠️  Poison Pills:"
    jq -r '.failed[] | select(.status == "poison_pill") | 
        "Task #\(.task_id) | \(.ai_name) | \(.error_details)"' \
        "$FAILED_TASKS"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function: Auto-retry all eligible tasks
auto_retry_all() {
    echo "🔄 Auto-retry: Checking all failed tasks..."
    
    local task_ids=$(jq -r '.failed[] | select(.status == "pending_retry") | .task_id' "$FAILED_TASKS")
    
    for task_id in $task_ids; do
        retry_task "$task_id" "auto" 2>&1 | grep -E '(Retrying|ready for retry|Too soon)'
    done
    
    echo "✅ Auto-retry check complete"
}

# Main command dispatcher
case "${1:-}" in
    record)
        record_failure "$2" "$3" "$4" "$5"
        ;;
    retry)
        retry_task "$2" "$3"
        ;;
    clear)
        clear_failure "$2"
        ;;
    list)
        list_failures
        ;;
    auto)
        auto_retry_all
        ;;
    check)
        should_retry "$2" && echo "✅ Can retry" || echo "❌ Cannot retry (poison pill)"
        ;;
    *)
        echo "Usage: $0 {record|retry|clear|list|auto|check} [options]"
        echo ""
        echo "Commands:"
        echo "  record <task_id> <ai_name> <error_type> <details>  - Record failure"
        echo "  retry <task_id> [ai_name]                          - Retry failed task"
        echo "  clear <task_id>                                    - Clear from failed list"
        echo "  list                                               - List failed tasks"
        echo "  auto                                               - Auto-retry all eligible"
        echo "  check <task_id>                                    - Check retry eligibility"
        exit 1
        ;;
esac
