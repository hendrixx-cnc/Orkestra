#!/bin/bash
# UNIVERSAL AI DAEMON
# Works for Claude, Gemini, or ChatGPT - any AI can do any task
# First-come-first-served autonomous execution with user prompts

set -euo pipefail

# Get AI name from parameter or environment
AI_NAME="${1:-${AI_NAME:-}}"

if [ -z "$AI_NAME" ]; then
    echo "❌ Error: AI name required"
    echo "Usage: $0 <AI_NAME>"
    echo "Example: $0 Claude"
    echo "Or: AI_NAME=Gemini $0"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
LOCKS_DIR="$SCRIPT_DIR/locks"
STATUS_DIR="$SCRIPT_DIR/status"
USER_PROMPTS_DIR="$SCRIPT_DIR/user_prompts"
LOG_FILE="$SCRIPT_DIR/logs/${AI_NAME}_daemon.log"

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

# Ensure directories exist
mkdir -p "$LOCKS_DIR" "$STATUS_DIR" "$USER_PROMPTS_DIR" "$SCRIPT_DIR/logs"

# Logging
log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [${AI_NAME}] $*" | tee -a "$LOG_FILE"
}

# Update status
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

# Check for unanswered prompts
has_unanswered_prompts() {
    find "$USER_PROMPTS_DIR" -name "${AI_NAME}_prompt_*.json" -type f 2>/dev/null | \
        xargs -I {} jq -r 'select(.status == "waiting") | .id' {} 2>/dev/null | \
        grep -q . && return 0 || return 1
}

# Create user prompt
ask_user() {
    local task_id="$1"
    local question="$2"
    local context="${3:-}"

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

    log "PROMPT" "Created user prompt: $prompt_id"

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}❓ ${AI_NAME} NEEDS YOUR INPUT${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Task #$task_id${NC}"
    echo -e "${CYAN}Question:${NC} $question"
    [ -n "$context" ] && echo -e "${CYAN}Context:${NC} $context"
    echo ""
    echo -e "${GREEN}To answer:${NC} ./answer_prompt.sh $prompt_id \"your answer\""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Get user's answer
get_user_answer() {
    local task_id="$1"

    # Find prompt for this task
    local prompt_file=$(find "$USER_PROMPTS_DIR" -name "${AI_NAME}_prompt_*.json" -type f 2>/dev/null | \
        xargs -I {} jq -r "select(.task_id == $task_id and .status == \"answered\") | .id" {} 2>/dev/null | head -1)

    if [ -n "$prompt_file" ]; then
        local answer=$(jq -r '.answer' "$USER_PROMPTS_DIR/${prompt_file}.json" 2>/dev/null)
        echo "$answer"
        return 0
    fi

    return 1
}

# Try to claim a task (with lock to prevent race conditions)
try_claim_task() {
    local task_id="$1"
    local lock_file="$LOCKS_DIR/task_${task_id}.lock"

    # Atomic lock attempt
    if mkdir "$lock_file" 2>/dev/null; then
        echo "$(date +%s)" > "$lock_file/timestamp"
        echo "$AI_NAME" > "$lock_file/ai"

        # Update task queue
        bash "$SCRIPT_DIR/claim_task_v2.sh" "$task_id" "$AI_NAME" &>/dev/null

        log "INFO" "✅ Claimed task #$task_id"
        return 0
    else
        # Someone else got it first
        return 1
    fi
}

# Get next available task (any unclaimed pending task with satisfied dependencies)
get_next_task() {
    jq -r '.queue[] | select(.status == "pending" and (.assigned_to == null or .assigned_to == "")) | select(
        if .dependencies then
            (.dependencies as $deps |
                all($deps[]; . as $dep |
                    any(input.queue[]; .id == $dep and .status == "completed")
                )
            )
        else
            true
        end
    ) | .id' "$TASK_QUEUE" "$TASK_QUEUE" 2>/dev/null | head -1
}

# Execute task (SIMULATION - would integrate real API calls)
execute_task() {
    local task_id="$1"

    # Try to claim it
    if ! try_claim_task "$task_id"; then
        log "WARN" "Failed to claim task #$task_id (already claimed)"
        return 1
    fi

    # Get task details
    local task_title=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$TASK_QUEUE")
    local task_desc=$(jq -r ".queue[] | select(.id == $task_id) | .description" "$TASK_QUEUE")
    local task_files=$(jq -r ".queue[] | select(.id == $task_id) | .files[]?" "$TASK_QUEUE" 2>/dev/null | tr '\n' ' ')

    log "INFO" "▶️  Executing: $task_title"

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🤖 ${AI_NAME} working on Task #${task_id}${NC}"
    echo -e "${CYAN}📝 ${task_title}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Check if need user input (simulation)
    if echo "$task_desc" | grep -qi "user.*input\|clarif\|decide\|approve"; then
        ask_user "$task_id" "How should I approach: $task_title?" "$task_desc"
        update_status "waiting_user" "Blocked on user input for task #$task_id"

        # Wait for answer (in real system, daemon would continue checking)
        while ! get_user_answer "$task_id" &>/dev/null; do
            sleep $CHECK_INTERVAL
        done

        local answer=$(get_user_answer "$task_id")
        log "INFO" "User provided: $answer"
    fi

    # Simulate work
    log "INFO" "Processing..."
    sleep 3

    # Complete task
    bash "$SCRIPT_DIR/complete_task_v2.sh" "$task_id" "Completed by $AI_NAME" &>/dev/null

    log "INFO" "✅ Task #$task_id completed"

    echo -e "${GREEN}✅ Task #${task_id} completed by ${AI_NAME}${NC}"
    echo ""

    # Release lock
    rm -rf "$LOCKS_DIR/task_${task_id}.lock"

    return 0
}

# Main daemon loop
main() {
    log "INFO" "╔════════════════════════════════════════════════╗"
    log "INFO" "║     $AI_NAME Autonomous Daemon Starting      ║"
    log "INFO" "╚════════════════════════════════════════════════╝"

    update_status "idle" "Daemon started"

    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        ${AI_NAME} AUTONOMOUS DAEMON${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}✅ Online - checking every ${CHECK_INTERVAL}s${NC}"
    echo -e "${CYAN}📋 Any task, any AI - first come, first served${NC}"
    echo -e "${CYAN}❓ Will prompt you when input needed${NC}"
    echo -e "${YELLOW}🛑 Press Ctrl+C to stop${NC}"
    echo ""

    while true; do
        # Check for unanswered prompts first
        if has_unanswered_prompts; then
            update_status "waiting_user" "Waiting for user response"
            sleep $CHECK_INTERVAL
            continue
        fi

        # Look for available tasks
        local next_task=$(get_next_task)

        if [ -n "$next_task" ]; then
            update_status "executing" "Working on task #$next_task"

            if execute_task "$next_task"; then
                update_status "idle" "Task complete, ready for next"
                sleep 2
            else
                # Failed to claim or execution failed
                update_status "idle" "Looking for next task"
                sleep 2
            fi
        else
            update_status "idle" "No tasks available"
            sleep $CHECK_INTERVAL
        fi
    done
}

# Graceful shutdown
trap 'log "INFO" "⏹️  Daemon stopped"; update_status "stopped" "Shut down"; exit 0' INT TERM

# Run
main
