#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA AUTOMATION ENGINE
# ═══════════════════════════════════════════════════════════════════════════
# Automated task processing system for Orkestra
# - Monitors task queue
# - Assigns tasks to available AIs
# - Handles task execution
# - Manages failures and retries
# - Load balancing across AI agents
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOCKS_DIR="$CONFIG_DIR/LOCKS"
LOG_DIR="$ORKESTRA_ROOT/LOGS"

# Create log directory
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/automation-$(date +%Y%m%d).log"

# Timing configuration
POLL_INTERVAL=10          # Check queue every 10 seconds
MAX_RETRIES=3             # Maximum retries per task
TASK_TIMEOUT=300          # 5 minutes timeout per task
STALE_TASK_THRESHOLD=3600 # 1 hour before considering task stale

# AI agent configuration
declare -A AI_SPECIALTIES=(
    ["claude"]="architecture,design,complex-reasoning"
    ["chatgpt"]="general,scripting,documentation"
    ["gemini"]="firebase,data,analysis"
    ["grok"]="innovation,creative,alternative"
    ["copilot"]="code-review,evaluation,github"
)

declare -A AI_MAX_CONCURRENT=(
    ["claude"]=2
    ["chatgpt"]=3
    ["gemini"]=2
    ["grok"]=1
    ["copilot"]=5
)

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
}

log_success() {
    log "SUCCESS" "$@"
}

log_warning() {
    log "WARNING" "$@"
}

log_error() {
    log "ERROR" "$@"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        log "DEBUG" "$@"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# TASK QUEUE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

ensure_task_queue() {
    if [ ! -f "$TASK_QUEUE" ]; then
        log_warning "Task queue not found, creating new one"
        mkdir -p "$(dirname "$TASK_QUEUE")"
        cat > "$TASK_QUEUE" << 'EOF'
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
        log_success "Created empty task queue"
    fi
    
    # Validate JSON
    if ! jq empty "$TASK_QUEUE" 2>/dev/null; then
        log_error "Task queue contains invalid JSON!"
        return 1
    fi
    
    return 0
}

get_pending_tasks() {
    jq -r '.tasks[] | select(.status == "pending") | .id' "$TASK_QUEUE" 2>/dev/null || echo ""
}

get_task_info() {
    local task_id="$1"
    jq -r ".tasks[] | select(.id == $task_id)" "$TASK_QUEUE" 2>/dev/null
}

update_task_status() {
    local task_id="$1"
    local new_status="$2"
    local assigned_to="${3:-}"
    
    local tmp_file=$(mktemp)
    
    if [ -n "$assigned_to" ]; then
        jq ".tasks = [.tasks[] | if .id == $task_id then .status = \"$new_status\" | .assigned_to = \"$assigned_to\" | .updated_at = \"$(date -Iseconds)\" else . end]" "$TASK_QUEUE" > "$tmp_file"
    else
        jq ".tasks = [.tasks[] | if .id == $task_id then .status = \"$new_status\" | .updated_at = \"$(date -Iseconds)\" else . end]" "$TASK_QUEUE" > "$tmp_file"
    fi
    
    mv "$tmp_file" "$TASK_QUEUE"
    log_debug "Updated task $task_id status to: $new_status"
}

increment_task_retries() {
    local task_id="$1"
    local tmp_file=$(mktemp)
    
    jq ".tasks = [.tasks[] | if .id == $task_id then .retries = (.retries // 0) + 1 else . end]" "$TASK_QUEUE" > "$tmp_file"
    mv "$tmp_file" "$TASK_QUEUE"
}

get_task_retries() {
    local task_id="$1"
    jq -r ".tasks[] | select(.id == $task_id) | .retries // 0" "$TASK_QUEUE"
}

# ═══════════════════════════════════════════════════════════════════════════
# AI WORKLOAD MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

get_ai_workload() {
    local ai_name="$1"
    
    # Count in_progress tasks
    local active=$(jq -r ".tasks[] | select(.status == \"in_progress\" and .assigned_to == \"$ai_name\") | .id" "$TASK_QUEUE" 2>/dev/null | wc -l)
    
    # Count locked tasks
    local locked=0
    if [ -d "$LOCKS_DIR" ]; then
        for lock_file in "$LOCKS_DIR"/task_*.lock; do
            if [ -f "$lock_file" ]; then
                local owner=$(cat "$lock_file" 2>/dev/null || echo "")
                if [ "$owner" = "$ai_name" ]; then
                    ((locked++)) || true
                fi
            fi
        done
    fi
    
    echo $((active + locked))
}

get_least_loaded_ai() {
    local min_load=9999
    local selected_ai=""
    
    for ai in "${!AI_SPECIALTIES[@]}"; do
        local workload=$(get_ai_workload "$ai")
        local max_allowed=${AI_MAX_CONCURRENT[$ai]}
        
        if [ $workload -lt $max_allowed ] && [ $workload -lt $min_load ]; then
            min_load=$workload
            selected_ai="$ai"
        fi
    done
    
    echo "$selected_ai"
}

get_best_ai_for_task() {
    local task_id="$1"
    local task_info=$(get_task_info "$task_id")
    
    if [ -z "$task_info" ]; then
        echo ""
        return 1
    fi
    
    # Check if task has preferred AI
    local preferred=$(echo "$task_info" | jq -r '.assigned_to // empty')
    if [ -n "$preferred" ] && [ "$preferred" != "null" ]; then
        local workload=$(get_ai_workload "$preferred")
        local max_allowed=${AI_MAX_CONCURRENT[$preferred]:-1}
        
        if [ $workload -lt $max_allowed ]; then
            echo "$preferred"
            return 0
        fi
    fi
    
    # Otherwise, get least loaded AI
    get_least_loaded_ai
}

# ═══════════════════════════════════════════════════════════════════════════
# LOCK MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

acquire_task_lock() {
    local task_id="$1"
    local ai_name="$2"
    local lock_file="$LOCKS_DIR/task_${task_id}.lock"
    
    # Check if already locked
    if [ -f "$lock_file" ]; then
        local existing_owner=$(cat "$lock_file")
        if [ "$existing_owner" = "$ai_name" ]; then
            log_debug "Task $task_id already locked by $ai_name"
            return 0
        else
            log_warning "Task $task_id locked by $existing_owner"
            return 1
        fi
    fi
    
    # Create lock
    mkdir -p "$LOCKS_DIR"
    echo "$ai_name" > "$lock_file"
    log_debug "Acquired lock for task $task_id by $ai_name"
    return 0
}

release_task_lock() {
    local task_id="$1"
    local lock_file="$LOCKS_DIR/task_${task_id}.lock"
    
    if [ -f "$lock_file" ]; then
        rm -f "$lock_file"
        log_debug "Released lock for task $task_id"
        return 0
    fi
    
    return 0
}

check_task_lock() {
    local task_id="$1"
    local lock_file="$LOCKS_DIR/task_${task_id}.lock"
    
    if [ -f "$lock_file" ]; then
        cat "$lock_file"
        return 0
    else
        echo ""
        return 1
    fi
}

clean_stale_locks() {
    if [ ! -d "$LOCKS_DIR" ]; then
        return 0
    fi
    
    local cleaned=0
    for lock_file in "$LOCKS_DIR"/task_*.lock; do
        if [ -f "$lock_file" ]; then
            # Check if lock is older than threshold
            local lock_age=$(($(date +%s) - $(stat -f%m "$lock_file" 2>/dev/null || stat -c%Y "$lock_file" 2>/dev/null || echo 0)))
            
            if [ $lock_age -gt $STALE_TASK_THRESHOLD ]; then
                log_warning "Removing stale lock: $lock_file (age: ${lock_age}s)"
                rm -f "$lock_file"
                ((cleaned++)) || true
            fi
        fi
    done
    
    if [ $cleaned -gt 0 ]; then
        log_info "Cleaned $cleaned stale locks"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# TASK EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

execute_task() {
    local task_id="$1"
    local ai_name="$2"
    
    log_info "Executing task $task_id with $ai_name"
    
    local task_info=$(get_task_info "$task_id")
    if [ -z "$task_info" ]; then
        log_error "Task $task_id not found"
        return 1
    fi
    
    local title=$(echo "$task_info" | jq -r '.title')
    local description=$(echo "$task_info" | jq -r '.description')
    
    log_info "Task: $title"
    log_debug "Description: $description"
    
    # Try to acquire lock
    if ! acquire_task_lock "$task_id" "$ai_name"; then
        log_warning "Could not acquire lock for task $task_id"
        return 1
    fi
    
    # Update status to in_progress
    update_task_status "$task_id" "in_progress" "$ai_name"
    
    # Execute task based on AI agent
    local success=false
    case "$ai_name" in
        claude|chatgpt|gemini|grok)
            # For external AIs, we would call their respective agent scripts
            log_info "Task $task_id would be executed by $ai_name (external AI integration needed)"
            # Placeholder for actual execution
            sleep 2
            success=true
            ;;
        copilot)
            # Copilot tasks are handled through VS Code
            log_info "Task $task_id assigned to Copilot (requires manual intervention)"
            success=true
            ;;
        *)
            log_error "Unknown AI agent: $ai_name"
            success=false
            ;;
    esac
    
    # Update task based on result
    if [ "$success" = true ]; then
        update_task_status "$task_id" "completed" "$ai_name"
        release_task_lock "$task_id"
        log_success "Task $task_id completed by $ai_name"
        return 0
    else
        # Handle failure
        local retries=$(get_task_retries "$task_id")
        increment_task_retries "$task_id"
        
        if [ $retries -ge $MAX_RETRIES ]; then
            update_task_status "$task_id" "failed"
            log_error "Task $task_id failed after $MAX_RETRIES retries"
        else
            update_task_status "$task_id" "pending"
            log_warning "Task $task_id failed, retry $((retries + 1))/$MAX_RETRIES"
        fi
        
        release_task_lock "$task_id"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN AUTOMATION LOOP
# ═══════════════════════════════════════════════════════════════════════════

process_tasks() {
    local pending_tasks=$(get_pending_tasks)
    
    if [ -z "$pending_tasks" ]; then
        log_debug "No pending tasks"
        return 0
    fi
    
    local processed=0
    for task_id in $pending_tasks; do
        # Get best AI for this task
        local ai_name=$(get_best_ai_for_task "$task_id")
        
        if [ -z "$ai_name" ]; then
            log_debug "No available AI for task $task_id"
            continue
        fi
        
        # Execute task in background
        (execute_task "$task_id" "$ai_name") &
        ((processed++)) || true
        
        # Small delay to prevent overwhelming the system
        sleep 1
    done
    
    if [ $processed -gt 0 ]; then
        log_info "Started processing $processed tasks"
    fi
}

run_automation() {
    log_info "Starting Orkestra Automation Engine"
    log_info "Task Queue: $TASK_QUEUE"
    log_info "Poll Interval: ${POLL_INTERVAL}s"
    log_info "Max Retries: $MAX_RETRIES"
    echo ""
    
    # Ensure task queue exists
    if ! ensure_task_queue; then
        log_error "Failed to initialize task queue"
        exit 1
    fi
    
    # Initial cleanup
    clean_stale_locks
    
    local iteration=0
    while true; do
        ((iteration++))
        
        # Clean stale locks periodically (every 10 iterations)
        if [ $((iteration % 10)) -eq 0 ]; then
            clean_stale_locks
        fi
        
        # Process tasks
        process_tasks
        
        # Wait before next iteration
        sleep "$POLL_INTERVAL"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
Orkestra Automation Engine

Usage: $(basename "$0") [OPTIONS]

Options:
    --daemon        Run in daemon mode (background)
    --once          Process tasks once and exit
    --debug         Enable debug logging
    --help          Show this help message

Environment Variables:
    POLL_INTERVAL       Seconds between queue checks (default: 10)
    MAX_RETRIES        Maximum task retries (default: 3)
    DEBUG              Enable debug mode (true/false)

Examples:
    # Run in foreground
    ./orkestra-automation.sh

    # Run once and exit
    ./orkestra-automation.sh --once

    # Run in background with debug
    DEBUG=true ./orkestra-automation.sh --daemon

EOF
}

main() {
    local run_once=false
    local daemon_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --once)
                run_once=true
                shift
                ;;
            --daemon)
                daemon_mode=true
                shift
                ;;
            --debug)
                export DEBUG=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Run in daemon mode
    if [ "$daemon_mode" = true ]; then
        log_info "Starting in daemon mode"
        nohup "$0" > "$LOG_DIR/automation-daemon.log" 2>&1 &
        local pid=$!
        echo $pid > "$ORKESTRA_ROOT/.automation.pid"
        log_success "Automation daemon started (PID: $pid)"
        exit 0
    fi
    
    # Run once or continuous
    if [ "$run_once" = true ]; then
        log_info "Processing tasks once"
        ensure_task_queue
        clean_stale_locks
        process_tasks
        log_info "Done"
    else
        run_automation
    fi
}

# Run main
main "$@"
