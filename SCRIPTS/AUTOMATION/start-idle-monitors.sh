#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# START ALL IDLE AGENT MONITORS
# ═══════════════════════════════════════════════════════════════════════════
# Starts idle monitoring for all AI agents
# Each agent automatically runs self-healing when idle for 2+ seconds
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
RUNTIME_DIR="$ORKESTRA_ROOT/CONFIG/RUNTIME"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
SCRIPTS_DIR="$ORKESTRA_ROOT/SCRIPTS"

# PID directory
PID_DIR="$RUNTIME_DIR/idle-monitors"
mkdir -p "$PID_DIR" "$LOGS_DIR"

# Agents to monitor
AGENTS=("claude" "chatgpt" "gemini" "grok" "copilot")

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTIONS
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

is_monitor_running() {
    local agent="$1"
    local pid_file="$PID_DIR/${agent}.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

start_monitor() {
    local agent="$1"
    local pid_file="$PID_DIR/${agent}.pid"
    local log_file="$LOGS_DIR/idle-monitor-${agent}.log"
    
    if is_monitor_running "$agent"; then
        log_warning "$agent monitor already running (PID: $(cat "$pid_file"))"
        return 1
    fi
    
    # Start monitor in background
    nohup "$SCRIPTS_DIR/AUTOMATION/idle-agent-maintenance.sh" "$agent" >> "$log_file" 2>&1 &
    local pid=$!
    
    echo "$pid" > "$pid_file"
    log_success "Started $agent monitor (PID: $pid)"
    sleep 0.5  # Give it time to start
    
    if kill -0 "$pid" 2>/dev/null; then
        return 0
    else
        log_warning "$agent monitor failed to start"
        rm -f "$pid_file"
        return 1
    fi
}

stop_monitor() {
    local agent="$1"
    local pid_file="$PID_DIR/${agent}.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            rm -f "$pid_file"
            log_success "Stopped $agent monitor"
        else
            rm -f "$pid_file"
            log_warning "$agent monitor was not running"
        fi
    else
        log_warning "$agent monitor PID file not found"
    fi
}

status_monitor() {
    local agent="$1"
    local pid_file="$PID_DIR/${agent}.pid"
    
    if is_monitor_running "$agent"; then
        local pid=$(cat "$pid_file")
        echo -e "  ${GREEN}●${NC} $agent - Running (PID: $pid)"
    else
        echo -e "  ${YELLOW}○${NC} $agent - Stopped"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

start_all() {
    echo ""
    echo -e "${BOLD}${CYAN}Starting Idle Agent Monitors${NC}"
    echo ""
    
    local started=0
    for agent in "${AGENTS[@]}"; do
        if start_monitor "$agent"; then
            ((started++))
        fi
    done
    
    echo ""
    log_success "Started $started/${#AGENTS[@]} agent monitor(s)"
    echo ""
    log_info "Monitors will automatically run maintenance when agents are idle for 2+ seconds"
    log_info "View logs: tail -f $LOGS_DIR/idle-monitor-*.log"
    echo ""
}

stop_all() {
    echo ""
    echo -e "${BOLD}${CYAN}Stopping Idle Agent Monitors${NC}"
    echo ""
    
    for agent in "${AGENTS[@]}"; do
        stop_monitor "$agent"
    done
    
    echo ""
    log_success "All monitors stopped"
    echo ""
}

status_all() {
    echo ""
    echo -e "${BOLD}${CYAN}Idle Agent Monitor Status${NC}"
    echo ""
    
    for agent in "${AGENTS[@]}"; do
        status_monitor "$agent"
    done
    
    echo ""
}

restart_all() {
    stop_all
    sleep 1
    start_all
}

# ═══════════════════════════════════════════════════════════════════════════
# COMMAND LINE INTERFACE
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Idle Agent Monitor Manager${NC}

${BOLD}USAGE:${NC}
    $0 <command>

${BOLD}COMMANDS:${NC}
    ${GREEN}start${NC}       Start all agent monitors
    ${GREEN}stop${NC}        Stop all agent monitors
    ${GREEN}restart${NC}     Restart all agent monitors
    ${GREEN}status${NC}      Show monitor status
    ${GREEN}help${NC}        Show this help message

${BOLD}WHAT IT DOES:${NC}
    Each agent monitor runs in the background and checks every 2 seconds.
    When an agent is idle for 2+ seconds, it automatically runs:
    
    • Health checks (API keys, connectivity)
    • Dependency validation (tools, files, JSON)
    • Error detection and recovery (stale locks, orphaned tasks)
    • Consistency checks (system integrity)
    • Self-healing procedures (auto-fix issues)

${BOLD}EXAMPLES:${NC}
    ${CYAN}$0 start${NC}         # Start all monitors
    ${CYAN}$0 status${NC}        # Check which are running
    ${CYAN}$0 stop${NC}          # Stop all monitors

${BOLD}LOGS:${NC}
    Monitor logs: ${CYAN}$LOGS_DIR/idle-monitor-<agent>.log${NC}
    Maintenance:  ${CYAN}$LOGS_DIR/agent-maintenance.log${NC}

EOF
}

case "${1:-}" in
    start)
        start_all
        ;;
    stop)
        stop_all
        ;;
    restart)
        restart_all
        ;;
    status)
        status_all
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        if [[ -n "${1:-}" ]]; then
            echo -e "${YELLOW}Unknown command: $1${NC}"
            echo ""
        fi
        show_usage
        exit 1
        ;;
esac
