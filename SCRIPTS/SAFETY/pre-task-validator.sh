#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# PRE-TASK VALIDATOR
# ═══════════════════════════════════════════════════════════════════════════
# Validates conditions BEFORE task execution
# Prevents 90% of common execution errors
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
RUNTIME_DIR="$CONFIG_DIR/RUNTIME"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"

# Validation log
VALIDATION_LOG="$LOGS_DIR/safety-validation.log"
mkdir -p "$LOGS_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_validation() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PRE-VALIDATION: $*" >> "$VALIDATION_LOG"
}

log_check() {
    local status="$1"
    local message="$2"
    
    if [[ "$status" == "pass" ]]; then
        echo -e "  ${GREEN}✓${NC} $message"
        log_validation "PASS: $message"
    else
        echo -e "  ${RED}✗${NC} $message"
        log_validation "FAIL: $message"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VALIDATION CHECKS
# ═══════════════════════════════════════════════════════════════════════════

# Check 1: Task Queue file exists
check_task_queue_exists() {
    if [[ -f "$TASK_QUEUE" ]]; then
        log_check "pass" "Task queue file exists"
        return 0
    else
        log_check "fail" "Task queue file not found: $TASK_QUEUE"
        return 1
    fi
}

# Check 2: Valid JSON structure
check_valid_json() {
    if jq empty "$TASK_QUEUE" 2>/dev/null; then
        log_check "pass" "Task queue is valid JSON"
        return 0
    else
        log_check "fail" "Task queue has invalid JSON structure"
        return 1
    fi
}

# Check 3: Task exists in queue
check_task_exists() {
    local task_id="$1"
    
    local task_exists=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .id" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -n "$task_exists" ]]; then
        log_check "pass" "Task $task_id exists in queue"
        return 0
    else
        log_check "fail" "Task $task_id not found in queue"
        return 1
    fi
}

# Check 4: Task status is "pending"
check_task_status() {
    local task_id="$1"
    
    local status=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .status" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ "$status" == "pending" ]]; then
        log_check "pass" "Task $task_id status is 'pending'"
        return 0
    else
        log_check "fail" "Task $task_id status is '$status' (expected 'pending')"
        return 1
    fi
}

# Check 5: No conflicting locks
check_no_conflicting_locks() {
    local task_id="$1"
    
    if [[ -f "$LOCKS_DIR/task-${task_id}.lock" ]]; then
        # Check if lock is stale (older than 1 hour)
        local lock_age=$(($(date +%s) - $(stat -c %Y "$LOCKS_DIR/task-${task_id}.lock" 2>/dev/null || echo 0)))
        
        if [[ $lock_age -gt 3600 ]]; then
            log_check "pass" "Stale lock detected (${lock_age}s old), will be cleaned"
            rm -f "$LOCKS_DIR/task-${task_id}.lock"
            return 0
        else
            log_check "fail" "Task $task_id is locked by another process"
            return 1
        fi
    else
        log_check "pass" "No conflicting locks for task $task_id"
        return 0
    fi
}

# Check 6: Dependencies completed
check_dependencies_completed() {
    local task_id="$1"
    
    local dependencies=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .dependencies // [] | .[]" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -z "$dependencies" ]]; then
        log_check "pass" "No dependencies for task $task_id"
        return 0
    fi
    
    local all_completed=true
    while IFS= read -r dep_id; do
        local dep_status=$(jq -r ".tasks[] | select(.id == \"$dep_id\") | .status" "$TASK_QUEUE" 2>/dev/null)
        
        if [[ "$dep_status" != "completed" ]]; then
            log_check "fail" "Dependency $dep_id is not completed (status: $dep_status)"
            all_completed=false
        fi
    done <<< "$dependencies"
    
    if [[ "$all_completed" == "true" ]]; then
        log_check "pass" "All dependencies completed for task $task_id"
        return 0
    else
        return 1
    fi
}

# Check 7: Input files exist (if specified)
check_input_files() {
    local task_id="$1"
    
    local input_files=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .input_files // [] | .[]" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -z "$input_files" ]]; then
        log_check "pass" "No input files required for task $task_id"
        return 0
    fi
    
    local all_exist=true
    while IFS= read -r input_file; do
        if [[ ! -f "$input_file" ]]; then
            log_check "fail" "Input file not found: $input_file"
            all_exist=false
        fi
    done <<< "$input_files"
    
    if [[ "$all_exist" == "true" ]]; then
        log_check "pass" "All input files exist for task $task_id"
        return 0
    else
        return 1
    fi
}

# Check 8: Output directory writable
check_output_directory() {
    local task_id="$1"
    
    local output_file=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .output_file // \"\"" "$TASK_QUEUE" 2>/dev/null)
    
    if [[ -z "$output_file" ]]; then
        log_check "pass" "No output file specified for task $task_id"
        return 0
    fi
    
    local output_dir=$(dirname "$output_file")
    
    # Create directory if it doesn't exist
    if mkdir -p "$output_dir" 2>/dev/null; then
        if [[ -w "$output_dir" ]]; then
            log_check "pass" "Output directory is writable: $output_dir"
            return 0
        else
            log_check "fail" "Output directory not writable: $output_dir"
            return 1
        fi
    else
        log_check "fail" "Cannot create output directory: $output_dir"
        return 1
    fi
}

# Check 9: AI agent is active
check_ai_agent_active() {
    local ai_name="$1"
    
    # Check if agent is configured (has API key or is Copilot with gh auth)
    case "$ai_name" in
        claude)
            if [[ -n "${ANTHROPIC_API_KEY:-}" && "$ANTHROPIC_API_KEY" != "your-anthropic-api-key-here" ]]; then
                log_check "pass" "AI agent $ai_name is configured"
                return 0
            fi
            ;;
        chatgpt)
            if [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "your-openai-api-key-here" ]]; then
                log_check "pass" "AI agent $ai_name is configured"
                return 0
            fi
            ;;
        gemini)
            if [[ -n "${GOOGLE_API_KEY:-}" && "$GOOGLE_API_KEY" != "your-google-api-key-here" ]]; then
                log_check "pass" "AI agent $ai_name is configured"
                return 0
            fi
            ;;
        grok)
            if [[ -n "${XAI_API_KEY:-}" && "$XAI_API_KEY" != "your-xai-api-key-here" ]]; then
                log_check "pass" "AI agent $ai_name is configured"
                return 0
            fi
            ;;
        copilot)
            if gh auth status &>/dev/null; then
                log_check "pass" "AI agent $ai_name is configured"
                return 0
            fi
            ;;
    esac
    
    log_check "fail" "AI agent $ai_name is not configured or inactive"
    return 1
}

# Check 10: Retry count not exceeded
check_retry_count() {
    local task_id="$1"
    
    local retry_count=$(jq -r ".tasks[] | select(.id == \"$task_id\") | .retry_count // 0" "$TASK_QUEUE" 2>/dev/null)
    local max_retries=3
    
    if [[ $retry_count -lt $max_retries ]]; then
        log_check "pass" "Retry count OK ($retry_count/$max_retries)"
        return 0
    else
        log_check "fail" "Max retries exceeded ($retry_count/$max_retries)"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN VALIDATION
# ═══════════════════════════════════════════════════════════════════════════

validate_pre_task() {
    local task_id="$1"
    local ai_name="${2:-unknown}"
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Pre-Task Validation: Task $task_id (Agent: $ai_name)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log_validation "Starting pre-task validation for task $task_id (agent: $ai_name)"
    
    local failed=0
    
    # Run all checks
    check_task_queue_exists || ((failed++))
    check_valid_json || ((failed++))
    check_task_exists "$task_id" || ((failed++))
    check_task_status "$task_id" || ((failed++))
    check_no_conflicting_locks "$task_id" || ((failed++))
    check_dependencies_completed "$task_id" || ((failed++))
    check_input_files "$task_id" || ((failed++))
    check_output_directory "$task_id" || ((failed++))
    check_ai_agent_active "$ai_name" || ((failed++))
    check_retry_count "$task_id" || ((failed++))
    
    echo ""
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ All pre-task validation checks passed${NC}"
        log_validation "RESULT: All checks passed for task $task_id"
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
    echo "Validates conditions before task execution:"
    echo "  1. Task queue file exists"
    echo "  2. Valid JSON structure"
    echo "  3. Task exists in queue"
    echo "  4. Task status is 'pending'"
    echo "  5. No conflicting locks"
    echo "  6. Dependencies completed"
    echo "  7. Input files exist"
    echo "  8. Output directory writable"
    echo "  9. AI agent is active"
    echo "  10. Retry count not exceeded"
    echo ""
    echo "Returns: 0 if safe to proceed, 1 if validation fails"
    exit 1
fi

# Load API keys if available
if [[ -f "$HOME/.config/orkestra/api-keys.env" ]]; then
    source "$HOME/.config/orkestra/api-keys.env"
fi

# Run validation
validate_pre_task "$@"
