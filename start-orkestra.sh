#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA START - Main System Launcher
# ═══════════════════════════════════════════════════════════════════════════
# This script initializes and starts the complete Orkestra AI orchestration system
# 
# Usage: ./start-orkestra.sh [OPTIONS]
# Options:
#   --clean      Clean start (reset locks and clear stale tasks)
#   --check      Health check only (don't start services)
#   --monitor    Start with monitoring enabled
#   --help       Show this help message
# ═══════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

ORKESTRA_ROOT="/workspaces/Orkestra"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
DOCS_DIR="$ORKESTRA_ROOT/DOCS"

TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOCKS_DIR="$CONFIG_DIR/LOCKS"
STATUS_FILE="$ORKESTRA_ROOT/orkestra-status.md"

# Script paths
CORE_SCRIPTS="$SCRIPTS_DIR/CORE"
AUTO_SCRIPTS="$SCRIPTS_DIR/AUTOMATION"
MONITOR_SCRIPTS="$SCRIPTS_DIR/MONITORING"
UTILS_SCRIPTS="$SCRIPTS_DIR/UTILS"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse command line arguments
CLEAN_START=false
CHECK_ONLY=false
ENABLE_MONITOR=true
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_START=true
            shift
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        --monitor)
            ENABLE_MONITOR=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -v "!/bin/bash" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# SYSTEM CHECKS
# ═══════════════════════════════════════════════════════════════════════════

check_directories() {
    log_section "Directory Structure Check"
    
    local missing=0
    
    # Check essential directories
    for dir in "$SCRIPTS_DIR" "$CONFIG_DIR" "$DOCS_DIR" "$LOCKS_DIR" "$CONFIG_DIR/TASK-QUEUES"; do
        if [ -d "$dir" ]; then
            log_success "$(basename $dir) directory exists"
        else
            log_error "$(basename $dir) directory missing: $dir"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        log_success "All directories present"
        return 0
    else
        log_error "$missing directories missing"
        return 1
    fi
}

check_task_queue() {
    log_section "Task Queue Check"
    
    if [ ! -f "$TASK_QUEUE" ]; then
        log_warning "Task queue not found, creating new one..."
        mkdir -p "$(dirname "$TASK_QUEUE")"
        echo '{"tasks": []}' > "$TASK_QUEUE"
        log_success "Created empty task queue"
        return 0
    fi
    
    # Validate JSON
    if jq empty "$TASK_QUEUE" 2>/dev/null; then
        local task_count=$(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
        log_success "Task queue is valid JSON"
        log_info "Current tasks in queue: $task_count"
        return 0
    else
        log_error "Task queue contains invalid JSON!"
        return 1
    fi
}

check_scripts() {
    log_section "Script Availability Check"
    
    local missing=0
    local scripts=(
        "orchestrator.sh:CORE"
        "task-coordinator.sh:AUTOMATION"
        "monitor.sh:MONITORING"
    )
    
    for script_info in "${scripts[@]}"; do
        script_name="${script_info%%:*}"
        script_dir="${script_info##*:}"
        script_path="$SCRIPTS_DIR/$script_dir/$script_name"
        
        if [ -f "$script_path" ] && [ -x "$script_path" ]; then
            log_success "$script_name is available and executable"
        elif [ -f "$script_path" ]; then
            log_warning "$script_name exists but not executable, fixing..."
            chmod +x "$script_path"
            log_success "Made $script_name executable"
        else
            log_error "$script_name not found: $script_path"
            ((missing++))
        fi
    done
    
    if [ $missing -eq 0 ]; then
        log_success "All core scripts available"
        return 0
    else
        log_error "$missing scripts missing"
        return 1
    fi
}

check_api_keys() {
    log_section "API Keys Check"
    
    local api_count=0
    
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        log_success "Claude (Anthropic) API key configured"
        ((api_count++))
    else
        log_warning "Claude API key not set (ANTHROPIC_API_KEY)"
    fi
    
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        log_success "ChatGPT (OpenAI) API key configured"
        ((api_count++))
    else
        log_warning "ChatGPT API key not set (OPENAI_API_KEY)"
    fi
    
    if [ -n "${GEMINI_API_KEY:-}" ]; then
        log_success "Gemini API key configured"
        ((api_count++))
    else
        log_warning "Gemini API key not set (GEMINI_API_KEY)"
    fi
    
    if [ -n "${XAI_API_KEY:-}" ]; then
        log_success "Grok (xAI) API key configured"
        ((api_count++))
    fi
    
    log_info "Configured APIs: $api_count (GitHub Copilot always available)"
    
    if [ $api_count -eq 0 ]; then
        log_warning "No external AI APIs configured. Only GitHub Copilot will be available."
    fi
}

clean_locks() {
    log_section "Cleaning Stale Locks"
    
    if [ -d "$LOCKS_DIR" ]; then
        local lock_count=$(find "$LOCKS_DIR" -name "*.lock" 2>/dev/null | wc -l)
        
        if [ $lock_count -gt 0 ]; then
            log_info "Found $lock_count lock file(s)"
            rm -f "$LOCKS_DIR"/*.lock
            log_success "Cleared all locks"
        else
            log_success "No stale locks found"
        fi
    else
        mkdir -p "$LOCKS_DIR"
        log_success "Created locks directory"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# STARTUP FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

run_health_check() {
    log_section "Running Health Check"
    
    local checks_passed=0
    local checks_failed=0
    
    if check_directories; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    
    if check_task_queue; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    
    if check_scripts; then
        ((checks_passed++))
    else
        ((checks_failed++))
    fi
    
    check_api_keys  # Always run but don't fail on this
    
    echo ""
    if [ $checks_failed -eq 0 ]; then
        log_success "Health check passed: $checks_passed/$checks_passed checks OK"
        return 0
    else
        log_error "Health check failed: $checks_failed check(s) failed"
        return 1
    fi
}

start_orchestrator() {
    log_section "Starting Orchestrator"
    
    # Create logs and runtime directories
    mkdir -p "$ORKESTRA_ROOT/LOGS" "$CONFIG_DIR/RUNTIME"
    
    # Check if orchestrator is already running
    if pgrep -f "orchestrator.sh" > /dev/null; then
        log_warning "Orchestrator already running"
        log_info "PID: $(pgrep -f 'orchestrator.sh')"
        return 0
    fi
    
    # Start orchestrator in background
    if [ -f "$CORE_SCRIPTS/orchestrator.sh" ]; then
        nohup "$CORE_SCRIPTS/orchestrator.sh" > "$ORKESTRA_ROOT/LOGS/orchestrator.log" 2>&1 &
        local pid=$!
        sleep 2
        
        if ps -p $pid > /dev/null; then
            log_success "Orchestrator started (PID: $pid)"
            echo $pid > "$CONFIG_DIR/RUNTIME/orchestrator.pid"
            return 0
        else
            log_error "Orchestrator failed to start"
            return 1
        fi
    else
        log_error "orchestrator.sh not found"
        return 1
    fi
}

start_monitoring() {
    log_section "Starting Monitoring"
    
    # Create logs and runtime directories
    mkdir -p "$ORKESTRA_ROOT/LOGS" "$CONFIG_DIR/RUNTIME"
    
    # Check if monitor is already running
    if pgrep -f "monitor.sh" > /dev/null; then
        log_warning "Monitor already running"
        return 0
    fi
    
    if [ -f "$MONITOR_SCRIPTS/monitor.sh" ]; then
        nohup "$MONITOR_SCRIPTS/monitor.sh" > "$ORKESTRA_ROOT/LOGS/monitor.log" 2>&1 &
        local pid=$!
        sleep 1
        
        if ps -p $pid > /dev/null; then
            log_success "Monitor started (PID: $pid)"
            echo $pid > "$CONFIG_DIR/RUNTIME/monitor.pid"
            return 0
        else
            log_warning "Monitor failed to start (non-critical)"
            return 0
        fi
    else
        log_warning "monitor.sh not found (non-critical)"
        return 0
    fi
}

update_status() {
    log_section "Updating System Status"
    
    cat > "$STATUS_FILE" << EOF
# Orkestra Status

**Last Started**: $(date '+%Y-%m-%d %H:%M:%S')
**Status**: Running

## Active Components

- **Orchestrator**: $([ -f "$CONFIG_DIR/RUNTIME/orchestrator.pid" ] && echo "Running (PID: $(cat "$CONFIG_DIR/RUNTIME/orchestrator.pid"))" || echo "Not running")
- **Monitor**: $([ -f "$CONFIG_DIR/RUNTIME/monitor.pid" ] && echo "Running (PID: $(cat "$CONFIG_DIR/RUNTIME/monitor.pid"))" || echo "Not running")

## Task Queue

- **Location**: \`CONFIG/TASK-QUEUES/task-queue.json\`
- **Tasks**: $(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null || echo "N/A")

## Quick Commands

\`\`\`bash
# View orchestrator logs
tail -f LOGS/orchestrator.log

# View monitor logs
tail -f LOGS/monitor.log

# Check task queue
cat CONFIG/TASK-QUEUES/task-queue.json

# Stop Orkestra
pkill -f orchestrator.sh
pkill -f monitor.sh
\`\`\`

---
*Auto-generated by start-orkestra.sh*
EOF
    
    log_success "Status file updated: $STATUS_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════════════

main() {
    clear
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}║                    ${CYAN}🎭 ORKESTRA LAUNCHER${NC}${BOLD}                     ║${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}║         ${BLUE}AI Orchestration System for Multi-Agent Workflows${NC}${BOLD}      ║${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Starting Orkestra initialization..."
    log_info "Root: $ORKESTRA_ROOT"
    echo ""
    
    # Clean start if requested
    if [ "$CLEAN_START" = true ]; then
        clean_locks
    fi
    
    # Run health check
    if ! run_health_check; then
        echo ""
        log_error "Health check failed! Cannot start Orkestra."
        log_info "Review errors above and fix issues before starting."
        exit 1
    fi
    
    # If check-only mode, exit here
    if [ "$CHECK_ONLY" = true ]; then
        echo ""
        log_success "Health check complete. System is ready to start."
        exit 0
    fi
    
    # Start orchestrator
    if ! start_orchestrator; then
        log_error "Failed to start orchestrator. Aborting."
        exit 1
    fi
    
    # Start monitoring if enabled
    if [ "$ENABLE_MONITOR" = true ]; then
        start_monitoring
    fi
    
    # Update status file
    update_status
    
    # Final summary
    log_section "Startup Complete"
    echo ""
    log_success "Orkestra is now running!"
    echo ""
    echo -e "${BOLD}Active Services:${NC}"
    echo "  • Orchestrator: $([ -f "$CONFIG_DIR/RUNTIME/orchestrator.pid" ] && echo -e "${GREEN}Running${NC}" || echo -e "${RED}Stopped${NC}")"
    echo "  • Monitor:      $([ -f "$CONFIG_DIR/RUNTIME/monitor.pid" ] && echo -e "${GREEN}Running${NC}" || echo -e "${YELLOW}Stopped${NC}")"
    echo ""
    echo -e "${BOLD}Logs:${NC}"
    echo "  • Orchestrator: tail -f LOGS/orchestrator.log"
    echo "  • Monitor:      tail -f LOGS/monitor.log"
    echo ""
    echo -e "${BOLD}Task Queue:${NC}"
    echo "  • Location: CONFIG/TASK-QUEUES/task-queue.json"
    echo "  • Tasks:    $(jq '.tasks | length' "$TASK_QUEUE" 2>/dev/null || echo "N/A")"
    echo ""
    echo -e "${BOLD}Documentation:${NC}"
    echo "  • Overview:     cat readme.md"
    echo "  • Quick Start:  cat DOCS/GUIDES/quick-start-autopilot.md"
    echo "  • Status:       cat orkestra-status.md"
    echo ""
    echo -e "${BOLD}To stop Orkestra:${NC}"
    echo "  pkill -f orchestrator.sh && pkill -f monitor.sh"
    echo ""
    log_section "Ready for Tasks"
    echo ""
}

# Run main function
main "$@"
