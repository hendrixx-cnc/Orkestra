#!/bin/bash
# CLAUDE AUTONOMOUS DAEMON
# Continuously monitors task queue and executes Claude tasks autonomously
# Prompts user when clarification needed

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
COMMANDS_DIR="$SCRIPT_DIR/commands"
STATUS_DIR="$SCRIPT_DIR/status"
USER_PROMPTS_DIR="$SCRIPT_DIR/user_prompts"
LOG_FILE="$SCRIPT_DIR/logs/claude_daemon.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
CHECK_INTERVAL=10  # Check every 10 seconds
AI_NAME="Claude"

# Ensure directories exist
mkdir -p "$COMMANDS_DIR" "$STATUS_DIR" "$USER_PROMPTS_DIR" "$SCRIPT_DIR/logs"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Update AI status
update_status() {
    local state="$1"
    local detail="$2"

    cat > "$STATUS_DIR/${AI_NAME}.json" << EOF
{
  "ai": "$AI_NAME",
  "state": "$state",
  "detail": "$detail",
  "updated_at": "$(date -Iseconds)"
}
EOF
}

# Check for user prompts that need answering
check_user_prompts() {
    local unanswered=$(find "$USER_PROMPTS_DIR" -name "${AI_NAME}_prompt_*.json" -type f 2>/dev/null | \
        xargs -I {} jq -r 'select(.status == "waiting") | .id' {} 2>/dev/null | head -1)

    if [ -n "$unanswered" ]; then
        return 0  # Has unanswered prompts
    fi
    return 1  # No unanswered prompts
}

# Create user prompt when blocked
create_user_prompt() {
    local task_id="$1"
    local question="$2"
    local context="$3"

    local prompt_id="${AI_NAME}_prompt_$(date +%s)"
    local prompt_file="$USER_PROMPTS_DIR/${prompt_id}.json"

    cat > "$prompt_file" << EOF
{
  "id": "$prompt_id",
  "ai": "$AI_NAME",
  "task_id": $task_id,
  "question": "$question",
  "context": "$context",
  "status": "waiting",
  "created_at": "$(date -Iseconds)",
  "answer": null
}
EOF

    log "INFO" "🤔 Created user prompt: $prompt_id"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}❓ USER INPUT NEEDED${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}AI:${NC} $AI_NAME"
    echo -e "${CYAN}Task:${NC} #$task_id"
    echo -e "${CYAN}Question:${NC} $question"
    echo -e "${CYAN}Context:${NC} $context"
    echo ""
    echo -e "${YELLOW}To answer: ./answer_prompt.sh $prompt_id \"your answer\"${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    return 0
}

# Check for commands from other AIs
check_commands() {
    local cmd_file=$(find "$COMMANDS_DIR" -name "${AI_NAME}_command_*.json" -type f 2>/dev/null | head -1)

    if [ -n "$cmd_file" ] && [ -f "$cmd_file" ]; then
        local command=$(jq -r '.command' "$cmd_file")
        local task_id=$(jq -r '.task_id' "$cmd_file")

        log "INFO" "📨 Received command: $command for task #$task_id"

        # Process command
        case "$command" in
            execute)
                echo "$task_id"
                ;;
            status_check)
                log "INFO" "Status check requested"
                echo ""
                ;;
            *)
                log "WARN" "Unknown command: $command"
                echo ""
                ;;
        esac

        # Move to processed
        mkdir -p "$COMMANDS_DIR/processed"
        jq '. + {status: "completed", processed_by: "'$AI_NAME'", processed_at: "'$(date -Iseconds)'"}' \
            "$cmd_file" > "$COMMANDS_DIR/processed/$(basename "$cmd_file")"
        rm "$cmd_file"
    else
        echo ""
    fi
}

# Get next available task
get_next_task() {
    # Check commands first
    local cmd_task=$(check_commands)
    if [ -n "$cmd_task" ]; then
        echo "$cmd_task"
        return 0
    fi

    # Check task queue for assigned tasks
    local next_task=$(jq -r ".queue[] | select(.assigned_to == \"$AI_NAME\" and .status == \"pending\") | select(
        if .dependencies then
            (.dependencies as \$deps |
                [\$deps[]] | all(. as \$dep |
                    any(input.queue[]; .id == \$dep and .status == \"completed\")
                )
            )
        else
            true
        end
    ) | .id" "$TASK_QUEUE" "$TASK_QUEUE" 2>/dev/null | head -1)

    echo "$next_task"
}

# Execute a task (simplified - you'd implement actual Claude API calls here)
execute_task() {
    local task_id="$1"

    log "INFO" "▶️  Executing task #$task_id"

    # Claim task
    bash "$SCRIPT_DIR/claim_task.sh" "$task_id" "$AI_NAME" 2>&1 | tee -a "$LOG_FILE"

    # Get task details
    local task_title=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$TASK_QUEUE")
    local task_desc=$(jq -r ".queue[] | select(.id == $task_id) | .description" "$TASK_QUEUE")

    log "INFO" "Task: $task_title"

    # SIMULATION: In production, this would call Claude API
    # For now, we'll simulate by checking if we need user input

    # Example: Check if task requires clarification
    if echo "$task_desc" | grep -qi "user input\|clarification\|decide"; then
        create_user_prompt "$task_id" \
            "How should I approach this task?" \
            "$task_desc"

        update_status "waiting_user" "Blocked on user prompt for task #$task_id"
        return 1  # Don't complete yet, waiting for user
    fi

    # Simulate work
    log "INFO" "Processing task..."
    sleep 2

    # Complete task
    bash "$SCRIPT_DIR/complete_task.sh" "$task_id" 2>&1 | tee -a "$LOG_FILE"

    log "INFO" "✅ Task #$task_id completed"

    # Check if this unlocked dependent tasks and notify other AIs
    local dependent_tasks=$(jq -r ".queue[] | select(.dependencies[]? == $task_id) | .id" "$TASK_QUEUE" 2>/dev/null)

    if [ -n "$dependent_tasks" ]; then
        log "INFO" "🔓 Task completion unlocked dependent tasks: $dependent_tasks"
    fi

    return 0
}

# Main daemon loop
main() {
    log "INFO" "╔════════════════════════════════════════════════╗"
    log "INFO" "║     Claude Autonomous Daemon Starting         ║"
    log "INFO" "╚════════════════════════════════════════════════╝"

    update_status "idle" "Daemon started, monitoring for tasks"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🤖 Claude Autonomous Daemon${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Daemon active - monitoring every ${CHECK_INTERVAL}s${NC}"
    echo -e "${CYAN}📋 Task Queue: $TASK_QUEUE${NC}"
    echo -e "${CYAN}📨 Commands: $COMMANDS_DIR${NC}"
    echo -e "${CYAN}❓ Prompts: $USER_PROMPTS_DIR${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    while true; do
        # Check if we're waiting on user input
        if check_user_prompts; then
            update_status "waiting_user" "Waiting for user to answer prompt"
            sleep $CHECK_INTERVAL
            continue
        fi

        # Get next task
        local next_task=$(get_next_task)

        if [ -n "$next_task" ]; then
            update_status "executing" "Working on task #$next_task"

            if execute_task "$next_task"; then
                update_status "idle" "Task completed, looking for next"
                sleep 2  # Brief pause between tasks
            else
                # Task blocked on user input, already updated status
                sleep $CHECK_INTERVAL
            fi
        else
            update_status "idle" "No tasks available"
            sleep $CHECK_INTERVAL
        fi
    done
}

# Graceful shutdown
trap 'log "INFO" "⏹️  Daemon stopped by user"; update_status "stopped" "Daemon shut down"; exit 0' INT TERM

# Run
main "$@"
