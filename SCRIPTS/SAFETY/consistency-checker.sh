#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# CONSISTENCY CHECKER
# ═══════════════════════════════════════════════════════════════════════════
# Periodic system health monitoring
# Auto-fixes common issues
# Recommended: Run hourly via cron
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOCKS_DIR="$CONFIG_DIR/LOCKS"
RUNTIME_DIR="$CONFIG_DIR/RUNTIME"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"

# Consistency log
CONSISTENCY_LOG="$LOGS_DIR/consistency-check.log"
mkdir -p "$LOGS_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_check() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CONSISTENCY: $*" >> "$CONSISTENCY_LOG"
}

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}🔍 ORKESTRA CONSISTENCY CHECKER${NC}                            ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_check() {
    local status="$1"
    local message="$2"
    
    if [[ "$status" == "pass" ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        log_check "PASS: $message"
    elif [[ "$status" == "warn" ]]; then
        echo -e "  ${YELLOW}⚠${NC} $message"
        log_check "WARN: $message"
    elif [[ "$status" == "fixed" ]]; then
        echo -e "  ${CYAN}🔧${NC} $message"
        log_check "FIXED: $message"
    else
        echo -e "  ${RED}✗${NC} $message"
        log_check "FAIL: $message"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# CONSISTENCY CHECKS
# ═══════════════════════════════════════════════════════════════════════════

# Check 1: Task queue file integrity
check_task_queue_integrity() {
    echo ""
    echo -e "${BOLD}Check 1: Task Queue Integrity${NC}"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        print_check "fail" "Task queue file not found"
        return 1
    fi
    
    if jq empty "$TASK_QUEUE" 2>/dev/null; then
        print_check "pass" "Task queue JSON is valid"
        
        # Check for required fields
        local has_metadata=$(jq 'has("metadata")' "$TASK_QUEUE")
        local has_tasks=$(jq 'has("tasks")' "$TASK_QUEUE")
        
        if [[ "$has_metadata" == "true" && "$has_tasks" == "true" ]]; then
            print_check "pass" "Required fields present"
        else
            print_check "warn" "Missing required fields (metadata or tasks)"
        fi
    else
        print_check "fail" "Task queue has invalid JSON"
        return 1
    fi
}

# Check 2: Stale lock detection and cleanup
check_stale_locks() {
    echo ""
    echo -e "${BOLD}Check 2: Stale Lock Detection${NC}"
    
    local stale_locks=0
    local current_time=$(date +%s)
    local max_lock_age=3600  # 1 hour
    
    mkdir -p "$LOCKS_DIR"
    
    for lock_file in "$LOCKS_DIR"/*.lock; do
        if [[ -f "$lock_file" ]]; then
            local lock_age=$((current_time - $(stat -c %Y "$lock_file" 2>/dev/null || echo $current_time)))
            
            if [[ $lock_age -gt $max_lock_age ]]; then
                rm -f "$lock_file"
                print_check "fixed" "Removed stale lock: $(basename "$lock_file") (age: ${lock_age}s)"
                ((stale_locks++))
            fi
        fi
    done
    
    if [[ $stale_locks -eq 0 ]]; then
        print_check "pass" "No stale locks found"
    else
        print_check "fixed" "Cleaned $stale_locks stale lock(s)"
    fi
}

# Check 3: Task status vs lock alignment
check_task_lock_alignment() {
    echo ""
    echo -e "${BOLD}Check 3: Task Status vs Lock Alignment${NC}"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        return 1
    fi
    
    local misaligned=0
    
    # Check for "in_progress" tasks without locks
    local in_progress_tasks=$(jq -r '.tasks[] | select(.status == "in_progress") | .id' "$TASK_QUEUE" 2>/dev/null || echo "")
    
    while IFS= read -r task_id; do
        if [[ -n "$task_id" ]]; then
            if [[ ! -f "$LOCKS_DIR/task-${task_id}.lock" ]]; then
                # Task marked in_progress but no lock - reset to pending
                jq ".tasks |= map(if .id == \"$task_id\" and .status == \"in_progress\" then .status = \"pending\" else . end)" \
                    "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
                print_check "fixed" "Reset orphaned task $task_id to 'pending'"
                ((misaligned++))
            fi
        fi
    done <<< "$in_progress_tasks"
    
    if [[ $misaligned -eq 0 ]]; then
        print_check "pass" "Task status and locks aligned"
    fi
}

# Check 4: Dependency chain validation
check_dependency_chains() {
    echo ""
    echo -e "${BOLD}Check 4: Dependency Chain Validation${NC}"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        return 1
    fi
    
    local broken_deps=0
    
    # Check each task's dependencies exist
    local tasks=$(jq -r '.tasks[] | @json' "$TASK_QUEUE" 2>/dev/null || echo "")
    
    while IFS= read -r task; do
        if [[ -n "$task" ]]; then
            local task_id=$(echo "$task" | jq -r '.id')
            local dependencies=$(echo "$task" | jq -r '.dependencies // [] | .[]' 2>/dev/null || echo "")
            
            while IFS= read -r dep_id; do
                if [[ -n "$dep_id" ]]; then
                    local dep_exists=$(jq -r ".tasks[] | select(.id == \"$dep_id\") | .id" "$TASK_QUEUE" 2>/dev/null)
                    
                    if [[ -z "$dep_exists" ]]; then
                        print_check "warn" "Task $task_id references non-existent dependency: $dep_id"
                        ((broken_deps++))
                    fi
                fi
            done <<< "$dependencies"
        fi
    done <<< "$tasks"
    
    if [[ $broken_deps -eq 0 ]]; then
        print_check "pass" "All dependency chains valid"
    fi
}

# Check 5: API keys configuration
check_api_keys() {
    echo ""
    echo -e "${BOLD}Check 5: API Keys Configuration${NC}"
    
    local configured=0
    local total=5
    
    # Load API keys
    if [[ -f "$HOME/.config/orkestra/api-keys.env" ]]; then
        source "$HOME/.config/orkestra/api-keys.env"
    fi
    
    [[ -n "${ANTHROPIC_API_KEY:-}" && "$ANTHROPIC_API_KEY" != "your-anthropic-api-key-here" ]] && ((configured++)) && print_check "pass" "Claude API configured"
    [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "your-openai-api-key-here" ]] && ((configured++)) && print_check "pass" "ChatGPT API configured"
    [[ -n "${GOOGLE_API_KEY:-}" && "$GOOGLE_API_KEY" != "your-google-api-key-here" ]] && ((configured++)) && print_check "pass" "Gemini API configured"
    [[ -n "${XAI_API_KEY:-}" && "$XAI_API_KEY" != "your-xai-api-key-here" ]] && ((configured++)) && print_check "pass" "Grok API configured"
    gh auth status &>/dev/null && ((configured++)) && print_check "pass" "GitHub Copilot authenticated"
    
    if [[ $configured -eq $total ]]; then
        print_check "pass" "All AI agents configured ($configured/$total)"
    elif [[ $configured -gt 0 ]]; then
        print_check "warn" "Partial configuration ($configured/$total agents)"
    else
        print_check "fail" "No AI agents configured"
    fi
}

# Check 6: Directory structure
check_directory_structure() {
    echo ""
    echo -e "${BOLD}Check 6: Directory Structure${NC}"
    
    local missing=0
    
    for dir in "$CONFIG_DIR" "$LOCKS_DIR" "$RUNTIME_DIR" "$LOGS_DIR" "$SCRIPTS_DIR"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_check "fixed" "Created missing directory: $dir"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        print_check "pass" "All required directories exist"
    fi
}

# Check 7: Running services check
check_running_services() {
    echo ""
    echo -e "${BOLD}Check 7: Running Services${NC}"
    
    local orchestrator_running=false
    local monitor_running=false
    local automation_running=false
    
    [[ -f "$RUNTIME_DIR/orchestrator.pid" ]] && kill -0 $(cat "$RUNTIME_DIR/orchestrator.pid" 2>/dev/null) 2>/dev/null && orchestrator_running=true
    [[ -f "$RUNTIME_DIR/monitor.pid" ]] && kill -0 $(cat "$RUNTIME_DIR/monitor.pid" 2>/dev/null) 2>/dev/null && monitor_running=true
    [[ -f "$RUNTIME_DIR/automation.pid" ]] && kill -0 $(cat "$RUNTIME_DIR/automation.pid" 2>/dev/null) 2>/dev/null && automation_running=true
    
    $orchestrator_running && print_check "pass" "Orchestrator is running" || print_check "warn" "Orchestrator not running"
    $monitor_running && print_check "pass" "Monitor is running" || print_check "warn" "Monitor not running"
    $automation_running && print_check "pass" "Automation is running" || print_check "warn" "Automation not running"
}

# Check 8: Log file permissions
check_log_permissions() {
    echo ""
    echo -e "${BOLD}Check 8: Log File Permissions${NC}"
    
    if [[ -w "$LOGS_DIR" ]]; then
        print_check "pass" "Log directory is writable"
    else
        print_check "fail" "Log directory not writable"
        return 1
    fi
}

# Check 9: Task queue backup
check_task_queue_backup() {
    echo ""
    echo -e "${BOLD}Check 9: Task Queue Backup${NC}"
    
    local backup_dir="$ORKESTRA_ROOT/BACKUPS"
    mkdir -p "$backup_dir"
    
    if [[ -f "$TASK_QUEUE" ]]; then
        local backup_file="$backup_dir/task-queue-$(date +%Y%m%d).json"
        
        # Create daily backup if it doesn't exist
        if [[ ! -f "$backup_file" ]]; then
            cp "$TASK_QUEUE" "$backup_file"
            print_check "fixed" "Created daily backup: $(basename "$backup_file")"
        else
            print_check "pass" "Daily backup exists"
        fi
        
        # Clean old backups (keep last 7 days)
        find "$backup_dir" -name "task-queue-*.json" -mtime +7 -delete 2>/dev/null
    fi
}

# Check 10: Retry count management
check_retry_counts() {
    echo ""
    echo -e "${BOLD}Check 10: Retry Count Management${NC}"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        return 1
    fi
    
    local max_retries=3
    local exceeded=0
    
    # Check for tasks with excessive retries
    local high_retry_tasks=$(jq -r ".tasks[] | select(.retry_count >= $max_retries and .status != \"failed\") | .id" "$TASK_QUEUE" 2>/dev/null || echo "")
    
    while IFS= read -r task_id; do
        if [[ -n "$task_id" ]]; then
            jq ".tasks |= map(if .id == \"$task_id\" then .status = \"failed\" | .error = \"Max retries exceeded\" else . end)" \
                "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
            print_check "fixed" "Marked task $task_id as 'failed' (max retries exceeded)"
            ((exceeded++))
        fi
    done <<< "$high_retry_tasks"
    
    if [[ $exceeded -eq 0 ]]; then
        print_check "pass" "No tasks exceeding retry limit"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

run_consistency_check() {
    print_header
    
    log_check "Starting consistency check"
    
    local failed=0
    
    # Run all checks
    check_task_queue_integrity || ((failed++))
    check_stale_locks
    check_task_lock_alignment
    check_dependency_chains
    check_api_keys
    check_directory_structure
    check_running_services
    check_log_permissions || ((failed++))
    check_task_queue_backup
    check_retry_counts
    
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ Consistency check complete - System healthy${NC}"
        log_check "RESULT: System healthy"
        return 0
    else
        echo -e "${YELLOW}⚠ Consistency check complete - $failed issue(s) found${NC}"
        log_check "RESULT: $failed critical issues found"
        return 1
    fi
}

# Command line options
case "${1:-}" in
    --help|help)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (none)     Run full consistency check"
        echo "  --help     Show this help message"
        echo ""
        echo "Performs 10 system health checks:"
        echo "  1. Task queue integrity"
        echo "  2. Stale lock detection"
        echo "  3. Task/lock alignment"
        echo "  4. Dependency chains"
        echo "  5. API keys configuration"
        echo "  6. Directory structure"
        echo "  7. Running services"
        echo "  8. Log permissions"
        echo "  9. Task queue backup"
        echo "  10. Retry count management"
        echo ""
        echo "Recommended: Run hourly via cron"
        exit 0
        ;;
    *)
        run_consistency_check
        ;;
esac
