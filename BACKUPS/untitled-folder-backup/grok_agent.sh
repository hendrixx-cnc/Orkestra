#!/bin/bash
# Grok Agent - Task Execution & Coordination
# Part of The Quantum Self AI Orchestration System

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
GROK_CLI="$SCRIPT_DIR/grok_cli.sh"
TASK_LOCK="$SCRIPT_DIR/task_lock.sh"
TASK_COORDINATOR="$SCRIPT_DIR/task_coordinator.sh"
TASK_AUDIT="$SCRIPT_DIR/task_audit.sh"
STATUS_FILE="$SCRIPT_DIR/status/GROK_STATUS.md"
LOG_FILE="$SCRIPT_DIR/logs/grok_agent.log"

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR/logs" "$SCRIPT_DIR/status"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function: Execute a task
execute_task() {
    local task_id="${1:-}"
    
    if [ -z "$task_id" ]; then
        log "❌ No task ID provided"
        return 1
    fi
    
    log "🤖 Executing task #$task_id with Grok"
    
    # Get task details
    local task_info=$(jq -r ".queue[] | select(.id == $task_id)" "$TASK_QUEUE")
    if [ -z "$task_info" ]; then
        log "❌ Task #$task_id not found"
        return 1
    fi
    
    local title=$(echo "$task_info" | jq -r '.title')
    local instructions=$(echo "$task_info" | jq -r '.description // .instructions // empty')
    local input_file=$(echo "$task_info" | jq -r '.input_file // .task_file // empty')
    local output_file=$(echo "$task_info" | jq -r '.output_file')
    
    log "📋 Task: $title"
    
    # Try to claim the task
    if ! bash "$TASK_LOCK" acquire "$task_id" "grok"; then
        log "⚠️  Could not claim task #$task_id (may be locked by another AI)"
        return 1
    fi
    
    # Build prompt
    local prompt="You are Grok, working on The Quantum Self project - a personal development workbook using quantum physics metaphors.

TASK: $title

INSTRUCTIONS:
$instructions
"
    
    # Add input file context if exists (but skip task_file - it's too large for API)
    if [ -n "$input_file" ] && [ -f "$input_file" ] && [[ ! "$input_file" =~ task_file|TASK_ ]]; then
        local input_content=$(cat "$input_file")
        prompt="$prompt

INPUT FILE CONTENT:
$input_content
"
    fi
    
    prompt="$prompt

Please complete this task. Provide your output in a clear, well-formatted way."
    
    # Execute with Grok
    log "🧠 Processing with Grok..."
    local result
    if result=$(bash "$GROK_CLI" "$prompt" 2>&1); then
        # Create output directory if it doesn't exist
        mkdir -p "$(dirname "$output_file")"
        
        # Save output
        echo "$result" > "$output_file"
        log "✅ Task #$task_id completed"
        log "📄 Output saved to: $output_file"
        
        # Mark as completed
        bash "$TASK_COORDINATOR" complete "$task_id" "grok"
        bash "$TASK_AUDIT" log "$task_id" "completed" "grok" "Task completed successfully"
        
        # Release lock
        bash "$TASK_LOCK" release "$task_id"
        
        # Update status
        update_status "$task_id" "$title" "completed"
        
        return 0
    else
        log "❌ Task #$task_id failed: $result"
        bash "$TASK_LOCK" release "$task_id"
        bash "$TASK_AUDIT" log "$task_id" "failed" "grok" "Execution error: $result"
        return 1
    fi
}

# Function: Get next available task
get_next_task() {
    bash "$TASK_COORDINATOR" next "grok" "any" 2>/dev/null | tail -1
}

# Function: Update status file
update_status() {
    local task_id="$1"
    local task_title="$2"
    local status="$3"
    
    cat > "$STATUS_FILE" << EOF
# Grok Status - The Quantum Self

**Last Updated:** $(date -Iseconds)
**AI Agent:** Grok (xAI Grok-2)
**Role:** Content Creation & Research Specialist

---

## Last Task

- **ID:** #$task_id
- **Title:** $task_title
- **Status:** $status
- **Completed:** $(date '+%Y-%m-%d %H:%M:%S')

---

## Capabilities

- ✅ Real-time information access
- ✅ Witty, engaging content creation
- ✅ Code debugging and review
- ✅ Research and analysis
- ✅ Marketing copy (edgy tone)
- ✅ Outside perspective on humanity

---

## API Configuration

- **Model:** grok-2-latest (grok-2-1212)
- **API Key:** ${XAI_API_KEY:0:20}...
- **Endpoint:** https://api.x.ai/v1/chat/completions

---

## Recent Activity

$(tail -10 "$LOG_FILE" 2>/dev/null || echo "No recent activity")
EOF
}

# Function: Ask Grok a question (user prompt)
ask() {
    local question="$*"
    if [ -z "$question" ]; then
        echo "Usage: $0 ask <your question>"
        return 1
    fi
    
    log "❓ User question: $question"
    bash "$GROK_CLI" "$question"
}

# Function: Show status
show_status() {
    if [ -f "$STATUS_FILE" ]; then
        cat "$STATUS_FILE"
    else
        echo "📭 No status available yet. Grok hasn't completed any tasks."
    fi
}

# Main command dispatcher
case "${1:-}" in
    execute)
        task_id="${2:-$(get_next_task)}"
        if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
            echo "📭 No tasks available for Grok"
            exit 0
        fi
        execute_task "$task_id"
        ;;
    next)
        get_next_task
        ;;
    ask)
        shift
        ask "$@"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Grok Agent - The Quantum Self AI Orchestration"
        echo ""
        echo "Usage: $0 {execute|next|ask|status} [options]"
        echo ""
        echo "Commands:"
        echo "  execute [task_id]  - Execute a specific task or next available"
        echo "  next               - Show next available task ID"
        echo "  ask <question>     - Ask Grok a question"
        echo "  status             - Show Grok's current status"
        echo ""
        echo "Examples:"
        echo "  $0 execute         # Execute next available task"
        echo "  $0 execute 15      # Execute task #15"
        echo "  $0 ask What is quantum superposition?"
        echo "  $0 status"
        exit 1
        ;;
esac
