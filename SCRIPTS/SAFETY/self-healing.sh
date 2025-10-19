#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# SELF-HEALING AGENT SYSTEM
# ═══════════════════════════════════════════════════════════════════════════
# Enables AI agents to detect, diagnose, and fix their own errors
# Automatic error recovery with learning capabilities
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

# Self-healing specific
HEALING_LOG="$LOGS_DIR/self-healing.log"
ERROR_DB="$CONFIG_DIR/error-database.json"
RECOVERY_STATE="$RUNTIME_DIR/recovery-state.json"

mkdir -p "$LOGS_DIR" "$RUNTIME_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_healing() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SELF-HEAL: $*" >> "$HEALING_LOG"
}

print_header() {
    echo ""
    echo -e "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${MAGENTA}║${NC}  ${BOLD}🔮 SELF-HEALING AGENT SYSTEM${NC}                              ${BOLD}${MAGENTA}║${NC}"
    echo -e "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

log_step() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "detect")
            echo -e "  ${YELLOW}🔍${NC} ${message}"
            log_healing "DETECT: $message"
            ;;
        "diagnose")
            echo -e "  ${BLUE}🔬${NC} ${message}"
            log_healing "DIAGNOSE: $message"
            ;;
        "heal")
            echo -e "  ${GREEN}🔧${NC} ${message}"
            log_healing "HEAL: $message"
            ;;
        "success")
            echo -e "  ${GREEN}✓${NC} ${message}"
            log_healing "SUCCESS: $message"
            ;;
        "fail")
            echo -e "  ${RED}✗${NC} ${message}"
            log_healing "FAIL: $message"
            ;;
        "learn")
            echo -e "  ${CYAN}📚${NC} ${message}"
            log_healing "LEARN: $message"
            ;;
        *)
            echo -e "  ${NC}  ${message}"
            log_healing "INFO: $message"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# ERROR DATABASE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════

init_error_database() {
    if [[ ! -f "$ERROR_DB" ]]; then
        cat > "$ERROR_DB" << 'EOF'
{
  "known_errors": [
    {
      "id": "err-001",
      "type": "api_rate_limit",
      "pattern": "rate limit|429|too many requests",
      "severity": "medium",
      "auto_fix": true,
      "recovery_strategy": "exponential_backoff",
      "success_rate": 0.95
    },
    {
      "id": "err-002",
      "type": "api_auth_failed",
      "pattern": "unauthorized|401|invalid api key",
      "severity": "high",
      "auto_fix": true,
      "recovery_strategy": "reload_credentials",
      "success_rate": 0.85
    },
    {
      "id": "err-003",
      "type": "file_not_found",
      "pattern": "no such file|file not found|ENOENT",
      "severity": "high",
      "auto_fix": true,
      "recovery_strategy": "create_missing_file",
      "success_rate": 0.90
    },
    {
      "id": "err-004",
      "type": "json_parse_error",
      "pattern": "invalid json|parse error|unexpected token",
      "severity": "high",
      "auto_fix": true,
      "recovery_strategy": "restore_from_backup",
      "success_rate": 0.92
    },
    {
      "id": "err-005",
      "type": "lock_timeout",
      "pattern": "lock timeout|failed to acquire lock",
      "severity": "medium",
      "auto_fix": true,
      "recovery_strategy": "force_unlock",
      "success_rate": 0.88
    },
    {
      "id": "err-006",
      "type": "network_timeout",
      "pattern": "timeout|connection refused|ETIMEDOUT",
      "severity": "medium",
      "auto_fix": true,
      "recovery_strategy": "retry_with_backoff",
      "success_rate": 0.80
    },
    {
      "id": "err-007",
      "type": "disk_full",
      "pattern": "no space left|disk full|ENOSPC",
      "severity": "critical",
      "auto_fix": true,
      "recovery_strategy": "cleanup_temp_files",
      "success_rate": 0.75
    },
    {
      "id": "err-008",
      "type": "permission_denied",
      "pattern": "permission denied|EACCES",
      "severity": "high",
      "auto_fix": true,
      "recovery_strategy": "fix_permissions",
      "success_rate": 0.93
    },
    {
      "id": "err-009",
      "type": "dependency_missing",
      "pattern": "command not found|module not found|import error",
      "severity": "critical",
      "auto_fix": false,
      "recovery_strategy": "notify_admin",
      "success_rate": 0.00
    },
    {
      "id": "err-010",
      "type": "memory_exhausted",
      "pattern": "out of memory|OOM|memory exhausted",
      "severity": "critical",
      "auto_fix": true,
      "recovery_strategy": "restart_service",
      "success_rate": 0.70
    }
  ],
  "recovery_history": [],
  "learning_stats": {
    "total_errors_detected": 0,
    "total_auto_fixed": 0,
    "total_manual_intervention": 0,
    "success_rate": 0.0
  }
}
EOF
        log_healing "Initialized error database"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ERROR DETECTION
# ═══════════════════════════════════════════════════════════════════════════

detect_error_from_log() {
    local log_file="$1"
    local lookback_lines="${2:-100}"
    
    if [[ ! -f "$log_file" ]]; then
        return 1
    fi
    
    # Get recent errors from log
    local recent_errors=$(tail -n "$lookback_lines" "$log_file" | grep -iE "error|fail|exception|critical" || echo "")
    
    if [[ -z "$recent_errors" ]]; then
        return 1
    fi
    
    echo "$recent_errors"
}

detect_error_from_task() {
    local task_id="$1"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        return 1
    fi
    
    local error_msg=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .error // \"\"" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -n "$error_msg" ]]; then
        echo "$error_msg"
        return 0
    fi
    
    return 1
}

detect_system_errors() {
    local errors_found=0
    
    echo -e "${BOLD}🔍 Scanning for System Errors...${NC}"
    echo ""
    
    # Check orchestrator log
    if [[ -f "$LOGS_DIR/orchestrator.log" ]]; then
        local orch_errors=$(detect_error_from_log "$LOGS_DIR/orchestrator.log" 50)
        if [[ -n "$orch_errors" ]]; then
            log_step "detect" "Errors found in orchestrator.log"
            ((errors_found++))
        fi
    fi
    
    # Check automation log
    if [[ -f "$LOGS_DIR/automation.log" ]]; then
        local auto_errors=$(detect_error_from_log "$LOGS_DIR/automation.log" 50)
        if [[ -n "$auto_errors" ]]; then
            log_step "detect" "Errors found in automation.log"
            ((errors_found++))
        fi
    fi
    
    # Check failed tasks
    local failed_tasks=$(jq -r '.tasks[] | select(.status == "failed") | .id' "$TASK_QUEUE" 2>/dev/null || echo "")
    if [[ -n "$failed_tasks" ]]; then
        while IFS= read -r task_id; do
            if [[ -n "$task_id" ]]; then
                log_step "detect" "Failed task found: $task_id"
                ((errors_found++))
            fi
        done <<< "$failed_tasks"
    fi
    
    echo ""
    if [[ $errors_found -gt 0 ]]; then
        log_step "detect" "Total errors detected: $errors_found"
        return 0
    else
        log_step "success" "No errors detected"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ERROR DIAGNOSIS
# ═══════════════════════════════════════════════════════════════════════════

diagnose_error() {
    local error_msg="$1"
    
    init_error_database
    
    # Match against known error patterns
    local matched_error=$(jq -r --arg msg "$error_msg" '
        .known_errors[] | 
        select(.pattern as $p | $msg | test($p; "i")) |
        @json
    ' "$ERROR_DB" 2>/dev/null | head -1)
    
    if [[ -n "$matched_error" ]]; then
        echo "$matched_error"
        return 0
    fi
    
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# RECOVERY STRATEGIES
# ═══════════════════════════════════════════════════════════════════════════

recovery_exponential_backoff() {
    local attempt="${1:-1}"
    local base_delay=2
    
    local wait_time=$((base_delay ** attempt))
    log_step "heal" "Waiting ${wait_time}s before retry (attempt $attempt)"
    sleep "$wait_time"
}

recovery_reload_credentials() {
    log_step "heal" "Reloading API credentials..."
    
    if [[ -f "$HOME/.config/orkestra/api-keys.env" ]]; then
        source "$HOME/.config/orkestra/api-keys.env"
        log_step "success" "Credentials reloaded"
        return 0
    else
        log_step "fail" "Credentials file not found"
        return 1
    fi
}

recovery_create_missing_file() {
    local file_path="$1"
    
    if [[ -z "$file_path" ]]; then
        # Try to extract path from error message
        file_path=$(echo "$2" | grep -oP '(?<=file: |path: )[^ ]+' || echo "")
    fi
    
    if [[ -n "$file_path" ]]; then
        log_step "heal" "Creating missing file: $file_path"
        
        local dir_path=$(dirname "$file_path")
        mkdir -p "$dir_path"
        touch "$file_path"
        
        log_step "success" "File created: $file_path"
        return 0
    fi
    
    return 1
}

recovery_restore_from_backup() {
    local target_file="${1:-$TASK_QUEUE}"
    
    log_step "heal" "Attempting to restore from backup..."
    
    # Find most recent backup
    local backup_file=$(ls -t "$ORKESTRA_ROOT/BACKUPS"/task-queue-*.json 2>/dev/null | head -1)
    
    if [[ -n "$backup_file" && -f "$backup_file" ]]; then
        # Validate backup
        if jq empty "$backup_file" 2>/dev/null; then
            cp "$backup_file" "$target_file"
            log_step "success" "Restored from backup: $(basename "$backup_file")"
            return 0
        fi
    fi
    
    log_step "fail" "No valid backup found"
    return 1
}

recovery_force_unlock() {
    local task_id="$1"
    
    log_step "heal" "Force unlocking stale locks..."
    
    if [[ -n "$task_id" ]]; then
        rm -f "$LOCKS_DIR/task-${task_id}.lock"
        log_step "success" "Lock removed for task $task_id"
    else
        # Remove all old locks
        find "$LOCKS_DIR" -name "*.lock" -mmin +60 -delete
        log_step "success" "All stale locks removed"
    fi
    
    return 0
}

recovery_retry_with_backoff() {
    local max_retries=3
    local attempt=1
    
    while [[ $attempt -le $max_retries ]]; do
        log_step "heal" "Retry attempt $attempt of $max_retries"
        
        recovery_exponential_backoff "$attempt"
        
        # Caller should check if error is resolved
        ((attempt++))
    done
}

recovery_cleanup_temp_files() {
    log_step "heal" "Cleaning up temporary files..."
    
    local space_freed=0
    
    # Clean /tmp
    find /tmp -type f -mtime +1 -delete 2>/dev/null || true
    
    # Clean old logs
    find "$LOGS_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
    
    # Clean old backups
    find "$ORKESTRA_ROOT/BACKUPS" -name "*.json" -mtime +14 -delete 2>/dev/null || true
    
    log_step "success" "Cleanup complete"
    return 0
}

recovery_fix_permissions() {
    local target="${1:-$ORKESTRA_ROOT}"
    
    log_step "heal" "Fixing permissions..."
    
    # Fix directory permissions
    find "$target" -type d -exec chmod 755 {} \; 2>/dev/null || true
    
    # Fix file permissions
    find "$target" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    # Fix log directory
    chmod -R 755 "$LOGS_DIR" 2>/dev/null || true
    
    log_step "success" "Permissions fixed"
    return 0
}

recovery_restart_service() {
    local service="$1"
    
    log_step "heal" "Restarting service: $service"
    
    # Stop service if running
    if [[ -f "$RUNTIME_DIR/${service}.pid" ]]; then
        local pid=$(cat "$RUNTIME_DIR/${service}.pid")
        kill "$pid" 2>/dev/null || true
        rm -f "$RUNTIME_DIR/${service}.pid"
    fi
    
    # Restart based on service type
    case "$service" in
        orchestrator)
            "$SCRIPTS_DIR/CORE/orchestrator.sh" &
            ;;
        monitor)
            "$SCRIPTS_DIR/MONITORING/monitor.sh" &
            ;;
        automation)
            "$SCRIPTS_DIR/AUTOMATION/orkestra-automation.sh" --daemon &
            ;;
    esac
    
    log_step "success" "Service restarted: $service"
    return 0
}

recovery_notify_admin() {
    local error_msg="$1"
    
    log_step "heal" "Admin notification required"
    
    # Log to special admin alert file
    local alert_file="$LOGS_DIR/admin-alerts.log"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] CRITICAL: $error_msg" >> "$alert_file"
    
    log_step "fail" "Manual intervention required - admin notified"
    return 1
}

# ═══════════════════════════════════════════════════════════════════════════
# SELF-HEALING ENGINE
# ═══════════════════════════════════════════════════════════════════════════

attempt_self_heal() {
    local error_msg="$1"
    local context="${2:-general}"
    
    log_step "diagnose" "Analyzing error: ${error_msg:0:80}..."
    
    # Diagnose error
    local diagnosis=$(diagnose_error "$error_msg")
    
    if [[ -z "$diagnosis" ]]; then
        log_step "fail" "Unknown error type - cannot auto-heal"
        return 1
    fi
    
    # Extract diagnosis details
    local error_type=$(echo "$diagnosis" | jq -r '.type')
    local auto_fix=$(echo "$diagnosis" | jq -r '.auto_fix')
    local recovery_strategy=$(echo "$diagnosis" | jq -r '.recovery_strategy')
    local severity=$(echo "$diagnosis" | jq -r '.severity')
    
    log_step "diagnose" "Error type: $error_type (severity: $severity)"
    
    if [[ "$auto_fix" != "true" ]]; then
        log_step "fail" "Auto-fix not available for this error type"
        recovery_notify_admin "$error_msg"
        return 1
    fi
    
    log_step "heal" "Applying recovery strategy: $recovery_strategy"
    
    # Execute recovery strategy
    local recovery_result=1
    case "$recovery_strategy" in
        exponential_backoff)
            recovery_exponential_backoff 1
            recovery_result=$?
            ;;
        reload_credentials)
            recovery_reload_credentials
            recovery_result=$?
            ;;
        create_missing_file)
            recovery_create_missing_file "" "$error_msg"
            recovery_result=$?
            ;;
        restore_from_backup)
            recovery_restore_from_backup
            recovery_result=$?
            ;;
        force_unlock)
            recovery_force_unlock
            recovery_result=$?
            ;;
        retry_with_backoff)
            recovery_retry_with_backoff
            recovery_result=$?
            ;;
        cleanup_temp_files)
            recovery_cleanup_temp_files
            recovery_result=$?
            ;;
        fix_permissions)
            recovery_fix_permissions
            recovery_result=$?
            ;;
        restart_service)
            recovery_restart_service "$context"
            recovery_result=$?
            ;;
        notify_admin)
            recovery_notify_admin "$error_msg"
            recovery_result=$?
            ;;
        *)
            log_step "fail" "Unknown recovery strategy: $recovery_strategy"
            return 1
            ;;
    esac
    
    # Record result
    if [[ $recovery_result -eq 0 ]]; then
        log_step "success" "Recovery successful!"
        record_recovery_success "$error_type" "$recovery_strategy"
        return 0
    else
        log_step "fail" "Recovery failed"
        record_recovery_failure "$error_type" "$recovery_strategy"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# LEARNING & STATISTICS
# ═══════════════════════════════════════════════════════════════════════════

record_recovery_success() {
    local error_type="$1"
    local strategy="$2"
    
    init_error_database
    
    # Update success rate
    jq --arg type "$error_type" --arg strat "$strategy" '
        .known_errors |= map(
            if .type == $type and .recovery_strategy == $strat then
                .success_rate = (((.success_rate * 100) + 1) / 101)
            else . end
        ) |
        .learning_stats.total_errors_detected += 1 |
        .learning_stats.total_auto_fixed += 1 |
        .recovery_history += [{
            "timestamp": now | todate,
            "error_type": $type,
            "strategy": $strat,
            "result": "success"
        }]
    ' "$ERROR_DB" > "$ERROR_DB.tmp" && mv "$ERROR_DB.tmp" "$ERROR_DB"
    
    log_step "learn" "Updated success statistics for $error_type"
}

record_recovery_failure() {
    local error_type="$1"
    local strategy="$2"
    
    init_error_database
    
    jq --arg type "$error_type" --arg strat "$strategy" '
        .known_errors |= map(
            if .type == $type and .recovery_strategy == $strat then
                .success_rate = (((.success_rate * 100) - 1) / 101)
            else . end
        ) |
        .learning_stats.total_errors_detected += 1 |
        .learning_stats.total_manual_intervention += 1 |
        .recovery_history += [{
            "timestamp": now | todate,
            "error_type": $type,
            "strategy": $strat,
            "result": "failure"
        }]
    ' "$ERROR_DB" > "$ERROR_DB.tmp" && mv "$ERROR_DB.tmp" "$ERROR_DB"
    
    log_step "learn" "Recorded failure for learning"
}

show_healing_stats() {
    init_error_database
    
    echo ""
    echo -e "${BOLD}📊 Self-Healing Statistics${NC}"
    echo ""
    
    jq -r '
        "Total Errors Detected: \(.learning_stats.total_errors_detected)",
        "Auto-Fixed: \(.learning_stats.total_auto_fixed)",
        "Manual Intervention: \(.learning_stats.total_manual_intervention)",
        "Success Rate: \((.learning_stats.total_auto_fixed / (.learning_stats.total_errors_detected + 0.0001) * 100 | floor))%"
    ' "$ERROR_DB"
    
    echo ""
    echo -e "${BOLD}Known Error Types:${NC}"
    jq -r '.known_errors[] | "  • \(.type): \(.success_rate * 100 | floor)% success (\(.severity) severity)"' "$ERROR_DB"
    
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# AGENT-SPECIFIC HEALING
# ═══════════════════════════════════════════════════════════════════════════

heal_agent_task() {
    local agent_name="$1"
    local task_id="$2"
    
    print_header
    echo -e "${BOLD}Agent:${NC} $agent_name"
    echo -e "${BOLD}Task:${NC} $task_id"
    echo ""
    
    # Detect error from task
    local error_msg=$(detect_error_from_task "$task_id")
    
    if [[ -z "$error_msg" ]]; then
        log_step "success" "No error found for task $task_id"
        return 0
    fi
    
    log_step "detect" "Error detected in task $task_id"
    echo ""
    
    # Attempt healing
    if attempt_self_heal "$error_msg" "$agent_name"; then
        # Reset task to pending for retry
        jq ".tasks |= map(if .id == \"$task_id\" then .status = \"pending\" | .error = null | .retry_count = ((.retry_count // 0) + 1) else . end)" \
            "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
        
        log_step "success" "Task $task_id reset for retry"
        return 0
    else
        log_step "fail" "Unable to heal task $task_id"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MONITORING MODE
# ═══════════════════════════════════════════════════════════════════════════

monitor_and_heal() {
    local interval="${1:-60}"
    
    print_header
    echo -e "${BOLD}Continuous monitoring mode${NC}"
    echo -e "${BOLD}Interval:${NC} ${interval}s"
    echo ""
    
    while true; do
        echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} Scanning for errors..."
        
        if detect_system_errors >/dev/null 2>&1; then
            # Errors found - attempt healing
            heal_system_errors
        fi
        
        sleep "$interval"
    done
}

heal_system_errors() {
    # Check for failed tasks
    local failed_tasks=$(jq -r '.tasks[] | select(.status == "failed" and (.retry_count // 0) < 3) | .id' "$TASK_QUEUE" 2>/dev/null || echo "")
    
    while IFS= read -r task_id; do
        if [[ -n "$task_id" ]]; then
            local assigned_to=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .assigned_to // \"unknown\"" "$TASK_QUEUE")
            heal_agent_task "$assigned_to" "$task_id"
        fi
    done <<< "$failed_tasks"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    heal-task)
        if [[ $# -lt 3 ]]; then
            echo "Usage: $0 heal-task <agent_name> <task_id>"
            exit 1
        fi
        heal_agent_task "$2" "$3"
        ;;
    heal-error)
        if [[ $# -lt 2 ]]; then
            echo "Usage: $0 heal-error <error_message>"
            exit 1
        fi
        print_header
        attempt_self_heal "$2"
        ;;
    detect)
        print_header
        detect_system_errors
        ;;
    stats)
        print_header
        show_healing_stats
        ;;
    monitor)
        monitor_and_heal "${2:-60}"
        ;;
    init)
        init_error_database
        echo "✓ Error database initialized"
        ;;
    --help|help)
        cat << 'EOF'
Self-Healing Agent System

USAGE:
    self-healing.sh <command> [options]

COMMANDS:
    heal-task <agent> <task_id>  Heal a specific failed task
    heal-error <error_message>   Attempt to heal a specific error
    detect                       Scan for system errors
    stats                        Show healing statistics
    monitor [interval]           Continuous monitoring mode (default: 60s)
    init                         Initialize error database
    help                         Show this help message

EXAMPLES:
    # Heal a failed task
    ./self-healing.sh heal-task claude task-001

    # Monitor and auto-heal continuously
    ./self-healing.sh monitor 30

    # Show healing statistics
    ./self-healing.sh stats

    # Detect current errors
    ./self-healing.sh detect

RECOVERY STRATEGIES:
    • exponential_backoff     - Wait with increasing delays
    • reload_credentials      - Reload API keys
    • create_missing_file     - Create missing files
    • restore_from_backup     - Restore from backup
    • force_unlock            - Remove stale locks
    • retry_with_backoff      - Retry with delays
    • cleanup_temp_files      - Clean disk space
    • fix_permissions         - Fix file permissions
    • restart_service         - Restart failed services
    • notify_admin            - Alert for manual intervention

ERROR TYPES DETECTED:
    • api_rate_limit          - API quota exceeded
    • api_auth_failed         - Invalid credentials
    • file_not_found          - Missing files
    • json_parse_error        - Corrupted JSON
    • lock_timeout            - Stale locks
    • network_timeout         - Connection issues
    • disk_full               - No disk space
    • permission_denied       - Permission issues
    • dependency_missing      - Missing dependencies
    • memory_exhausted        - Out of memory

EOF
        ;;
    *)
        print_header
        echo "Self-healing agent system ready."
        echo ""
        echo "Run '$0 help' for usage information."
        echo "Run '$0 detect' to scan for errors."
        echo "Run '$0 monitor' to enable continuous auto-healing."
        echo ""
        ;;
esac
