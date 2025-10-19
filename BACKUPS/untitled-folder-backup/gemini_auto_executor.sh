#!/bin/bash

# Gemini Auto-Executor
# Automatically executes Gemini tasks when available
# Integrates with the task coordination system

set -euo pipefail

SCRIPT_DIR="/workspaces/The-Quantum-Self-/AI"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
GEMINI_AGENT="$SCRIPT_DIR/gemini_agent.sh"
LOG_FILE="$SCRIPT_DIR/logs/gemini_auto_executor.log"

# Ensure log directory exists
mkdir -p "$SCRIPT_DIR/logs"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if API key is set
check_api_key() {
    if [ -z "${GEMINI_API_KEY:-}" ]; then
        log "❌ GEMINI_API_KEY not set - cannot execute tasks"
        return 1
    fi
    return 0
}

# Get next available Gemini task
get_next_gemini_task() {
    # Find first task assigned to Gemini
    jq -r '
        .queue[] |
        select((.assigned_to == "gemini" or .assigned_to == "Gemini") and (.status == "waiting" or .status == "pending" or .status == "not_started")) |
        .id
    ' "$TASK_QUEUE" 2>/dev/null | head -1
}

# Execute a task
execute_task() {
    local task_id="$1"
    local max_retries=3
    local retry=0
    local wait_time=1
    
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    while [ $retry -le $max_retries ]; do
        if [ $retry -gt 0 ]; then
            log "⏳ Retry $retry/$max_retries after ${wait_time}s wait..."
            sleep $wait_time
            wait_time=$((wait_time * 2))
        fi
        
        log "🤖 Auto-executing Task #$task_id with Gemini (attempt $((retry + 1)))"
        
        if bash "$GEMINI_AGENT" execute "$task_id" >> "$LOG_FILE" 2>&1; then
            log "✅ Task #$task_id completed successfully"
            return 0
        fi
        
        retry=$((retry + 1))
    done
    
    log "❌ Task #$task_id failed after $max_retries retries"
    return 1
}

# Main execution loop
main() {
    local mode="${1:-once}"
    
    log "╔════════════════════════════════════════════════╗"
    log "║   Gemini Auto-Executor Starting...            ║"
    log "╚════════════════════════════════════════════════╝"
    log "Mode: $mode"
    
    # Check API key
    if ! check_api_key; then
        log "Please set GEMINI_API_KEY environment variable"
        log "Get key from: https://aistudio.google.com/app/apikey"
        exit 1
    fi
    
    log "✅ API key configured"
    
    case "$mode" in
        once)
            # Execute one task and exit
            local next_task=$(get_next_gemini_task)
            
            if [ -z "$next_task" ]; then
                log "ℹ️  No tasks available for Gemini"
                exit 0
            fi
            
            execute_task "$next_task"
            ;;
            
        all)
            # Execute all available tasks
            local task_count=0
            
            while true; do
                local next_task=$(get_next_gemini_task)
                
                if [ -z "$next_task" ]; then
                    log "✅ All Gemini tasks completed ($task_count tasks)"
                    break
                fi
                
                if execute_task "$next_task"; then
                    ((task_count++))
                    sleep 2  # Brief pause between tasks
                else
                    log "⚠️  Stopping due to task failure"
                    break
                fi
            done
            ;;
            
        watch)
            # Continuous monitoring mode
            log "👀 Entering watch mode (checking every 60s)"
            log "Press Ctrl+C to stop"
            
            while true; do
                local next_task=$(get_next_gemini_task)
                
                if [ -n "$next_task" ]; then
                    execute_task "$next_task" || true
                    sleep 10
                else
                    # No tasks, wait before checking again
                    sleep 60
                fi
            done
            ;;
            
        *)
            echo "Usage: $0 {once|all|watch}"
            echo ""
            echo "Modes:"
            echo "  once   - Execute one task and exit"
            echo "  all    - Execute all available tasks and exit"
            echo "  watch  - Continuously monitor for new tasks"
            exit 1
            ;;
    esac
}

# Handle Ctrl+C gracefully
trap 'log "⏹️  Auto-executor stopped by user"; exit 0' INT TERM

# Run main
main "$@"
