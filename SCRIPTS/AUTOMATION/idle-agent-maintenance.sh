#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# IDLE AGENT AUTO-MAINTENANCE SYSTEM
# ═══════════════════════════════════════════════════════════════════════════
# When agents become idle for 2+ seconds, automatically run:
# - Health checks
# - Dependency validation
# - Error detection and recovery
# - Consistency checks
# - Self-healing procedures
# ═══════════════════════════════════════════════════════════════════════════

# Usage: idle-agent-maintenance.sh <agent_name>
# Monitors a specific agent and runs maintenance when idle

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
RUNTIME_DIR="$CONFIG_DIR/RUNTIME"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"

# Idle tracking
IDLE_THRESHOLD=2  # seconds
MAINTENANCE_LOG="$LOGS_DIR/agent-maintenance.log"
AGENT_STATE_DIR="$RUNTIME_DIR/agent-states"

mkdir -p "$AGENT_STATE_DIR" "$LOGS_DIR"

# Load API keys
if [[ -f "$HOME/.config/orkestra/api-keys.env" ]]; then
    source "$HOME/.config/orkestra/api-keys.env"
fi

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_maintenance() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$MAINTENANCE_LOG"
}

log_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
    log_maintenance "INFO: $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
    log_maintenance "SUCCESS: $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
    log_maintenance "WARNING: $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
    log_maintenance "ERROR: $1"
}

log_fixed() {
    echo -e "${MAGENTA}🔧${NC} $1"
    log_maintenance "FIXED: $1"
}

# ═══════════════════════════════════════════════════════════════════════════
# AGENT STATE TRACKING
# ═══════════════════════════════════════════════════════════════════════════

get_agent_state() {
    local agent_name="$1"
    local state_file="$AGENT_STATE_DIR/${agent_name}.state"
    
    if [[ -f "$state_file" ]]; then
        jq -r '.' "$state_file" 2>/dev/null || echo '{}'
    else
        echo '{}'
    fi
}

update_agent_state() {
    local agent_name="$1"
    local status="$2"
    local state_file="$AGENT_STATE_DIR/${agent_name}.state"
    
    cat > "$state_file" << EOF
{
  "agent": "$agent_name",
  "status": "$status",
  "last_update": "$(date -Iseconds)",
  "last_activity": "$(date +%s)"
}
EOF
}

get_agent_idle_time() {
    local agent_name="$1"
    local state=$(get_agent_state "$agent_name")
    local last_activity=$(echo "$state" | jq -r '.last_activity // 0')
    local current_time=$(date +%s)
    
    echo $((current_time - last_activity))
}

# ═══════════════════════════════════════════════════════════════════════════
# HEALTH CHECKS
# ═══════════════════════════════════════════════════════════════════════════

check_agent_health() {
    local agent_name="$1"
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Health Check: $agent_name ━━━${NC}"
    
    local issues_found=0
    
    # Check API connectivity
    case "$agent_name" in
        claude)
            if [[ -z "${ANTHROPIC_API_KEY:-}" || "$ANTHROPIC_API_KEY" == "your-anthropic-api-key-here" ]]; then
                log_warning "API key not configured for $agent_name"
                ((issues_found++))
            else
                log_success "API key configured"
            fi
            ;;
        chatgpt)
            if [[ -z "${OPENAI_API_KEY:-}" || "$OPENAI_API_KEY" == "your-openai-api-key-here" ]]; then
                log_warning "API key not configured for $agent_name"
                ((issues_found++))
            else
                log_success "API key configured"
            fi
            ;;
        gemini)
            if [[ -z "${GOOGLE_API_KEY:-}" || "$GOOGLE_API_KEY" == "your-google-api-key-here" ]]; then
                log_warning "API key not configured for $agent_name"
                ((issues_found++))
            else
                log_success "API key configured"
            fi
            ;;
        grok)
            if [[ -z "${XAI_API_KEY:-}" || "$XAI_API_KEY" == "your-xai-api-key-here" ]]; then
                log_warning "API key not configured for $agent_name"
                ((issues_found++))
            else
                log_success "API key configured"
            fi
            ;;
        copilot)
            if gh auth status &>/dev/null; then
                log_success "GitHub authenticated"
            else
                log_warning "GitHub not authenticated"
                ((issues_found++))
            fi
            ;;
    esac
    
    return $issues_found
}

# ═══════════════════════════════════════════════════════════════════════════
# DEPENDENCY VALIDATION
# ═══════════════════════════════════════════════════════════════════════════

check_dependencies() {
    local agent_name="$1"
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Dependency Check: $agent_name ━━━${NC}"
    
    local issues_found=0
    
    # Check required tools
    local required_tools=("jq" "curl")
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool is installed"
        else
            log_error "$tool is missing"
            ((issues_found++))
        fi
    done
    
    # Check task queue
    if [[ -f "$TASK_QUEUE" ]]; then
        if jq empty "$TASK_QUEUE" 2>/dev/null; then
            log_success "Task queue is valid"
        else
            log_error "Task queue has invalid JSON"
            # Auto-fix: Backup and reset
            cp "$TASK_QUEUE" "$TASK_QUEUE.broken.$(date +%s)"
            cat > "$TASK_QUEUE" << 'EOF'
{
  "tasks": [],
  "metadata": {
    "last_updated": "",
    "version": "1.0"
  }
}
EOF
            log_fixed "Task queue reset to valid structure"
            ((issues_found++))
        fi
    else
        log_error "Task queue file missing"
        # Auto-fix: Create new task queue
        mkdir -p "$(dirname "$TASK_QUEUE")"
        cat > "$TASK_QUEUE" << 'EOF'
{
  "tasks": [],
  "metadata": {
    "last_updated": "",
    "version": "1.0"
  }
}
EOF
        log_fixed "Created new task queue"
        ((issues_found++))
    fi
    
    return $issues_found
}

# ═══════════════════════════════════════════════════════════════════════════
# ERROR DETECTION AND RECOVERY
# ═══════════════════════════════════════════════════════════════════════════

detect_and_fix_errors() {
    local agent_name="$1"
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Error Detection & Recovery: $agent_name ━━━${NC}"
    
    local fixes_applied=0
    
    # Check for stale locks
    local stale_locks=0
    local current_time=$(date +%s)
    local max_lock_age=3600  # 1 hour
    
    if [[ -d "$CONFIG_DIR/LOCKS" ]]; then
        for lock_file in "$CONFIG_DIR/LOCKS"/*.lock; do
            if [[ -f "$lock_file" ]]; then
                local lock_age=$((current_time - $(stat -c %Y "$lock_file" 2>/dev/null || echo $current_time)))
                
                if [[ $lock_age -gt $max_lock_age ]]; then
                    rm -f "$lock_file"
                    log_fixed "Removed stale lock: $(basename "$lock_file") (age: ${lock_age}s)"
                    ((stale_locks++))
                    ((fixes_applied++))
                fi
            fi
        done
    fi
    
    if [[ $stale_locks -eq 0 ]]; then
        log_success "No stale locks found"
    fi
    
    # Check for orphaned tasks
    if [[ -f "$TASK_QUEUE" ]]; then
        local orphaned_tasks=$(jq -r '[.tasks[] | select(.status == "in_progress")] | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
        
        if [[ $orphaned_tasks -gt 0 ]]; then
            # Check if tasks have corresponding locks
            local reset_count=0
            local task_ids=$(jq -r '.tasks[] | select(.status == "in_progress") | .id' "$TASK_QUEUE" 2>/dev/null || echo "")
            
            while IFS= read -r task_id; do
                if [[ -n "$task_id" && ! -f "$CONFIG_DIR/LOCKS/task-${task_id}.lock" ]]; then
                    # Orphaned task - reset to pending
                    jq ".tasks |= map(if .id == \"$task_id\" then .status = \"pending\" else . end)" \
                        "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
                    log_fixed "Reset orphaned task to pending: $task_id"
                    ((reset_count++))
                    ((fixes_applied++))
                fi
            done <<< "$task_ids"
            
            if [[ $reset_count -eq 0 ]]; then
                log_success "All in-progress tasks have valid locks"
            fi
        else
            log_success "No orphaned tasks found"
        fi
    fi
    
    # Check for failed tasks with retries available
    if [[ -f "$TASK_QUEUE" ]]; then
        local failed_with_retries=$(jq -r '[.tasks[] | select(.status == "failed" and (.retry_count // 0) < 3)] | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
        
        if [[ $failed_with_retries -gt 0 ]]; then
            log_info "Found $failed_with_retries failed task(s) that can be retried"
            
            # Reset failed tasks to pending for retry
            jq '.tasks |= map(if .status == "failed" and (.retry_count // 0) < 3 then .status = "pending" else . end)' \
                "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
            log_fixed "Reset $failed_with_retries failed task(s) to pending for retry"
            ((fixes_applied++))
        fi
    fi
    
    # Check for missing directories
    local required_dirs=("$CONFIG_DIR" "$LOGS_DIR" "$CONFIG_DIR/LOCKS" "$RUNTIME_DIR" "$CONFIG_DIR/TASK-QUEUES")
    
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_fixed "Created missing directory: $dir"
            ((fixes_applied++))
        fi
    done
    
    if [[ $fixes_applied -eq 0 ]]; then
        log_success "No errors detected"
    else
        log_info "Applied $fixes_applied fix(es)"
    fi
    
    return $fixes_applied
}

# ═══════════════════════════════════════════════════════════════════════════
# CONSISTENCY CHECKS
# ═══════════════════════════════════════════════════════════════════════════

run_consistency_checks() {
    local agent_name="$1"
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Consistency Check: $agent_name ━━━${NC}"
    
    # Run the full consistency checker but capture output
    local issues=0
    
    if [[ -x "$SCRIPTS_DIR/SAFETY/consistency-checker.sh" ]]; then
        # Run consistency checker silently, just log results
        if "$SCRIPTS_DIR/SAFETY/consistency-checker.sh" >> "$MAINTENANCE_LOG" 2>&1; then
            log_success "System consistency verified"
        else
            log_warning "Consistency issues detected (see logs)"
            ((issues++))
        fi
    else
        log_info "Consistency checker not available"
    fi
    
    return $issues
}

# ═══════════════════════════════════════════════════════════════════════════
# SELF-HEALING PROCEDURES
# ═══════════════════════════════════════════════════════════════════════════

run_self_healing() {
    local agent_name="$1"
    
    echo ""
    echo -e "${BOLD}${MAGENTA}━━━ Self-Healing Procedures: $agent_name ━━━${NC}"
    
    local total_fixes=0
    
    # Health check
    check_agent_health "$agent_name" || true
    
    # Dependencies
    check_dependencies "$agent_name" || true
    
    # Error detection and recovery
    detect_and_fix_errors "$agent_name"
    total_fixes=$?
    
    # Consistency checks
    run_consistency_checks "$agent_name" || true
    
    echo ""
    if [[ $total_fixes -gt 0 ]]; then
        log_success "Self-healing complete: $total_fixes issue(s) fixed"
    else
        log_success "Self-healing complete: System healthy"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# IDLE MONITORING
# ═══════════════════════════════════════════════════════════════════════════

monitor_agent_idle() {
    local agent_name="$1"
    
    while true; do
        # Check if agent has pending tasks
        local pending_tasks=0
        if [[ -f "$TASK_QUEUE" ]]; then
            pending_tasks=$(jq -r ".tasks[] | select(.status == \"pending\" and (.assigned_to == \"$agent_name\" or .assigned_to == null or .assigned_to == \"\")) | .id" "$TASK_QUEUE" 2>/dev/null | wc -l)
        fi
        
        if [[ $pending_tasks -gt 0 ]]; then
            # Agent has work, reset idle timer
            update_agent_state "$agent_name" "busy"
            log_maintenance "$agent_name: Busy with $pending_tasks task(s)"
        else
            # Agent is idle, check idle time
            local idle_time=$(get_agent_idle_time "$agent_name")
            
            if [[ $idle_time -ge $IDLE_THRESHOLD ]]; then
                log_maintenance "$agent_name: Idle for ${idle_time}s, starting maintenance"
                
                echo ""
                echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}Idle Agent Auto-Maintenance: $agent_name${NC}"
                echo -e "${BOLD}${CYAN}║${NC}  Idle time: ${idle_time}s (threshold: ${IDLE_THRESHOLD}s)"
                echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
                
                # Run self-healing
                run_self_healing "$agent_name"
                
                # Reset idle timer after maintenance
                update_agent_state "$agent_name" "idle-maintained"
                
                # Wait before next maintenance cycle (don't spam)
                sleep 30
            fi
            
            update_agent_state "$agent_name" "idle"
        fi
        
        # Check every 2 seconds
        sleep 2
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    local agent_name="${1:-}"
    
    if [[ -z "$agent_name" ]]; then
        echo "Usage: $0 <agent_name>"
        echo ""
        echo "Available agents: claude, chatgpt, gemini, grok, copilot"
        echo ""
        echo "This script monitors an agent and automatically runs maintenance when idle for ${IDLE_THRESHOLD}+ seconds:"
        echo "  • Health checks"
        echo "  • Dependency validation"
        echo "  • Error detection and recovery"
        echo "  • Consistency checks"
        echo "  • Self-healing procedures"
        echo ""
        echo "Example:"
        echo "  $0 claude &"
        echo "  $0 chatgpt &"
        echo ""
        echo "To monitor all agents:"
        echo "  for agent in claude chatgpt gemini grok copilot; do"
        echo "    $0 \$agent &"
        echo "  done"
        exit 1
    fi
    
    log_maintenance "=========================================="
    log_maintenance "Starting idle monitoring for $agent_name"
    log_maintenance "Idle threshold: ${IDLE_THRESHOLD}s"
    log_maintenance "=========================================="
    
    # Initialize agent state
    update_agent_state "$agent_name" "starting"
    
    # Start monitoring
    monitor_agent_idle "$agent_name"
}

# Run main
main "$@"
