#!/bin/bash

# Claude Auto-Executor for The Quantum Self
# Automatically discovers and executes tasks assigned to Claude
# Part of the 4-AI coordination system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_AGENT="$SCRIPT_DIR/claude_agent.sh"
LOG_FILE="$SCRIPT_DIR/logs/claude_auto_executor.log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Ensure log directory exists
mkdir -p "$SCRIPT_DIR/logs"

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if API key is set
check_api_key() {
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        log "❌ ANTHROPIC_API_KEY not set - skipping Claude automation"
        return 1
    fi
    return 0
}

# Get next Claude task from TASK_QUEUE.json
get_next_claude_task() {
    local task_file="$SCRIPT_DIR/TASK_QUEUE.json"
    
    if [ ! -f "$task_file" ]; then
        return 1
    fi
    
    # Find next task assigned to claude
    jq -r '
        .queue[] | 
        select((.assigned_to == "claude" or .assigned_to == "Claude") and (.status == "not_started" or .status == "pending" or .status == "waiting")) |
        .id
    ' "$task_file" 2>/dev/null | head -1
}

# Execute a single task with exponential backoff
execute_task() {
    local task_id="$1"
    local max_retries=3
    local retry=0
    local wait_time=1
    
    while [ $retry -le $max_retries ]; do
        if [ $retry -gt 0 ]; then
            log "⏳ Retry $retry/$max_retries after ${wait_time}s wait..."
            sleep $wait_time
            wait_time=$((wait_time * 2))  # Exponential backoff: 1s, 2s, 4s
        fi
        
        log "▶️  Executing task #$task_id (attempt $((retry + 1)))"
        
        if bash "$CLAUDE_AGENT" execute "$task_id" >> "$LOG_FILE" 2>&1; then
            log "✅ Task #$task_id completed successfully"
            return 0
        fi
        
        retry=$((retry + 1))
    done
    
    log "❌ Task #$task_id failed after $max_retries retries"
    return 1
}

# Main execution function
main() {
    local mode="${1:-once}"
    
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Auto-Executor - The Quantum Self     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check API key
    if ! check_api_key; then
        echo -e "${RED}❌ ANTHROPIC_API_KEY not set${NC}"
        echo ""
        echo "Please set your API key:"
        echo "  export ANTHROPIC_API_KEY='sk-ant-...'"
        exit 1
    fi
    
    log "🚀 Claude auto-executor started (mode: $mode)"
    
    case "$mode" in
        once)
            # Execute one task and exit
            echo "Checking for available tasks..."
            
            local task_id
            task_id=$(get_next_claude_task)
            
            if [ -z "$task_id" ]; then
                echo -e "${YELLOW}📭 No tasks available for Claude${NC}"
                log "📭 No tasks found"
                exit 0
            fi
            
            echo -e "${GREEN}✅ Found task #$task_id${NC}"
            echo ""
            
            if execute_task "$task_id"; then
                echo ""
                echo -e "${GREEN}✅ Task completed successfully${NC}"
            else
                echo ""
                echo -e "${RED}❌ Task execution failed${NC}"
                exit 1
            fi
            ;;
            
        all)
            # Execute all available tasks
            echo "Checking for available tasks..."
            
            local executed=0
            local failed=0
            local max_failures=5  # Stop after 5 consecutive failures
            local consecutive_failures=0
            
            while true; do
                local task_id
                task_id=$(get_next_claude_task)
                
                if [ -z "$task_id" ]; then
                    break
                fi
                
                echo ""
                echo -e "${BLUE}▶️  Executing task #$task_id...${NC}"
                
                if execute_task "$task_id"; then
                    ((executed++))
                    consecutive_failures=0
                    echo -e "${GREEN}✅ Task #$task_id completed${NC}"
                else
                    ((failed++))
                    ((consecutive_failures++))
                    echo -e "${RED}❌ Task #$task_id failed${NC}"
                    
                    if [ $consecutive_failures -ge $max_failures ]; then
                        echo -e "${RED}🛑 Stopping: $max_failures consecutive failures${NC}"
                        log "🛑 Stopped after $max_failures consecutive failures"
                        break
                    fi
                fi
            done
            
            echo ""
            if [ $executed -eq 0 ]; then
                echo -e "${YELLOW}📭 No tasks available for Claude${NC}"
                log "📭 No tasks found"
            else
                echo -e "${GREEN}✅ Completed: $executed tasks${NC}"
                if [ $failed -gt 0 ]; then
                    echo -e "${RED}❌ Failed: $failed tasks${NC}"
                fi
                log "✅ Completed $executed tasks, $failed failed"
            fi
            ;;
            
        watch)
            # Continuous monitoring mode
            echo -e "${BLUE}👀 Starting watch mode...${NC}"
            echo "Monitoring for new Claude tasks (Ctrl+C to stop)"
            echo ""
            log "👀 Watch mode started"
            
            while true; do
                local task_id
                task_id=$(get_next_claude_task)
                
                if [ -n "$task_id" ]; then
                    echo ""
                    echo -e "${GREEN}✅ Found task #$task_id${NC}"
                    
                    if execute_task "$task_id"; then
                        echo -e "${GREEN}✅ Task #$task_id completed${NC}"
                    else
                        echo -e "${RED}❌ Task #$task_id failed${NC}"
                    fi
                else
                    echo -e "${YELLOW}.${NC}" # Progress indicator
                fi
                
                sleep 60  # Check every 60 seconds
            done
            ;;
            
        *)
            echo "Usage: $0 {once|all|watch}"
            exit 1
            ;;
    esac
    
    log "🏁 Claude auto-executor finished"
}

# Run main function
main "$@"
