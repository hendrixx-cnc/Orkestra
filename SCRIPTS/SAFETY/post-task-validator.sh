#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# POST-TASK VALIDATOR
# ═══════════════════════════════════════════════════════════════════════════
# Validates conditions AFTER task completion
# Ensures quality and consistency
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOCKS_DIR="$CONFIG_DIR/LOCKS"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"

# Validation log
VALIDATION_LOG="$LOGS_DIR/safety-validation.log"
mkdir -p "$LOGS_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_validation() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] POST-VALIDATION: $*" >> "$VALIDATION_LOG"
}

log_check() {
    local status="$1"
    local message="$2"
    
    if [[ "$status" == "pass" ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        log_validation "PASS: $message"
    elif [[ "$status" == "warn" ]]; then
        echo -e "  ${YELLOW}⚠${NC} $message"
        log_validation "WARN: $message"
    else
        echo -e "  ${RED}✗${NC} $message"
        log_validation "FAIL: $message"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION CHECKS
# ═══════════════════════════════════════════════════════════════════════════

# Check 1: Task status updated to "completed"
check_task_completed() {
    local task_id="$1"
    
    local status=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .status" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ "$status" == "completed" ]]; then
        log_check "pass" "Task $task_id marked as 'completed'"
        return 0
    else
        log_check "fail" "Task $task_id not marked as completed (status: $status)"
        return 1
    fi
}

# Check 2: Output file exists
check_output_file_exists() {
    local task_id="$1"
    
    local output_file=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .output_file // \"\"" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -z "$output_file" ]]; then
        log_check "warn" "No output file specified for task $task_id"
        return 0  # Warning, not failure
    fi
    
    if [[ -f "$output_file" ]]; then
        log_check "pass" "Output file exists: $output_file"
        return 0
    else
        log_check "fail" "Output file not found: $output_file"
        return 1
    fi
}

# Check 3: Output file not empty
check_output_file_not_empty() {
    local task_id="$1"
    
    local output_file=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .output_file // \"\"" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -z "$output_file" || ! -f "$output_file" ]]; then
        return 0  # Skip if no output file
    fi
    
    if [[ -s "$output_file" ]]; then
        local size=$(stat -c%s "$output_file" 2>/dev/null || echo 0)
        log_check "pass" "Output file not empty ($size bytes)"
        return 0
    else
        log_check "fail" "Output file is empty: $output_file"
        return 1
    fi
}

# Check 4: Lock properly released
check_lock_released() {
    local task_id="$1"
    
    if [[ ! -f "$LOCKS_DIR/task-${task_id}.lock" ]]; then
        log_check "pass" "Lock properly released for task $task_id"
        return 0
    else
        log_check "fail" "Lock still exists for task $task_id"
        # Auto-fix: Remove stale lock
        rm -f "$LOCKS_DIR/task-${task_id}.lock"
        log_check "pass" "Auto-fixed: Removed stale lock"
        return 0  # Fixed
    fi
}

# Check 5: Audit log entry created
check_audit_log() {
    local task_id="$1"
    local ai_name="$2"
    
    # Check if audit log exists and contains entry for this task
    local audit_log="$LOGS_DIR/audit.log"
    
    if [[ -f "$audit_log" ]] && grep -q "task.*$task_id.*$ai_name" "$audit_log" 2>/dev/null; then
        log_check "pass" "Audit log entry found for task $task_id"
        return 0
    else
        log_check "warn" "No audit log entry found for task $task_id"
        # Auto-create entry
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Task $task_id completed by $ai_name (post-validation backfill)" >> "$audit_log"
        log_check "pass" "Auto-fixed: Created audit log entry"
        return 0  # Fixed
    fi
}

# Check 6: Task assigned to correct AI
check_correct_assignment() {
    local task_id="$1"
    local ai_name="$2"
    
    local assigned_to=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .assigned_to // \"\"" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ "$assigned_to" == "$ai_name" ]]; then
        log_check "pass" "Task correctly assigned to $ai_name"
        return 0
    elif [[ -z "$assigned_to" ]]; then
        log_check "warn" "Task has no assignment recorded"
        return 0  # Warning, not failure
    else
        log_check "warn" "Task assigned to $assigned_to but completed by $ai_name"
        return 0  # Warning, not failure
    fi
}

# Check 7: Peer review queued
check_peer_review_queued() {
    local task_id="$1"
    
    local needs_review=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .needs_review // false" "$TASK_QUEUE" 2>/dev/null)
    local reviewed=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .reviewed // false" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ "$needs_review" == "true" || "$reviewed" == "true" ]]; then
        log_check "pass" "Peer review queued or completed for task $task_id"
        return 0
    else
        log_check "warn" "Peer review not queued for task $task_id"
        # Auto-fix: Queue review
        jq ".tasks |= map(if .id == \"$task_id\" then .needs_review = true else . end)" "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
        log_check "pass" "Auto-fixed: Queued peer review"
        return 0  # Fixed
    fi
}

# Check 8: No orphaned temp files
check_no_temp_files() {
    local task_id="$1"
    
    # Check for common temp file patterns
    local temp_pattern="/tmp/*task-${task_id}*"
    local temp_files=$(find /tmp -name "*task-${task_id}*" 2>/dev/null || echo "")
    
    if [[ -z "$temp_files" ]]; then
        log_check "pass" "No orphaned temp files for task $task_id"
        return 0
    else
        log_check "warn" "Found temp files for task $task_id"
        # Auto-fix: Clean up
        find /tmp -name "*task-${task_id}*" -delete 2>/dev/null || true
        log_check "pass" "Auto-fixed: Cleaned temp files"
        return 0  # Fixed
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN VALIDATION
# ═══════════════════════════════════════════════════════════════════════════

validate_post_task() {
    local task_id="$1"
    local ai_name="${2:-unknown}"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Post-Task Validation: Task $task_id (Agent: $ai_name)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log_validation "Starting post-task validation for task $task_id (agent: $ai_name)"
    
    local failed=0
    local warnings=0
    
    # Run all checks
    check_task_completed "$task_id" || ((failed++))
    check_output_file_exists "$task_id" || ((failed++))
    check_output_file_not_empty "$task_id" || ((failed++))
    check_lock_released "$task_id" || ((failed++))
    check_audit_log "$task_id" "$ai_name" || ((warnings++))
    check_correct_assignment "$task_id" "$ai_name" || ((warnings++))
    check_peer_review_queued "$task_id" || ((warnings++))
    check_no_temp_files "$task_id" || ((warnings++))
    
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        if [[ $warnings -gt 0 ]]; then
            echo -e "${YELLOW}⚠ Post-task validation passed with $warnings warning(s)${NC}"
            log_validation "RESULT: Passed with $warnings warnings for task $task_id"
        else
            echo -e "${GREEN}✓ All post-task validation checks passed${NC}"
            log_validation "RESULT: All checks passed for task $task_id"
        fi
        return 0
    else
        echo -e "${RED}✗ $failed validation check(s) failed${NC}"
        log_validation "RESULT: $failed checks failed for task $task_id"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# USAGE
# ═══════════════════════════════════════════════════════════════════════════

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <task_id> [ai_name]"
    echo ""
    echo "Validates conditions after task completion:"
    echo "  1. Task status updated to 'completed'"
    echo "  2. Output file exists"
    echo "  3. Output file not empty"
    echo "  4. Lock properly released"
    echo "  5. Audit log entry created"
    echo "  6. Task assigned to correct AI"
    echo "  7. Peer review queued"
    echo "  8. No orphaned temp files"
    echo ""
    echo "Returns: 0 if validation passes, 1 if critical failures"
    exit 1
fi

# Run validation
validate_post_task "$@"
