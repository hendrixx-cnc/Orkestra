#!/bin/bash
# MASTER AI ORCHESTRATOR
# Coordinates multiple AIs with automatic recovery, load balancing, and monitoring

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EVENT_BUS="$SCRIPT_DIR/event_bus.sh"
EVENT_DIR="$SCRIPT_DIR/events"
COMMAND_DIR="$SCRIPT_DIR/commands"
STATUS_DIR="$SCRIPT_DIR/status"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$EVENT_DIR" "$COMMAND_DIR" "$STATUS_DIR" "$LOG_DIR"

# Note: Scripts are called as subprocesses, not sourced
# This prevents function conflicts and maintains modularity

# Configuration
MONITOR_INTERVAL=60  # Check every 60 seconds
MAX_STALE_TIME=7200  # 2 hours before considering task stale

# Function: Health check
health_check() {
    echo "🏥 System Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check if task queue exists and is valid JSON
    if [ ! -f "$SCRIPT_DIR/../TASK_QUEUE.json" ]; then
        echo "❌ CRITICAL: TASK_QUEUE.json not found"
        return 1
    fi
    
    if ! jq empty "$SCRIPT_DIR/../TASK_QUEUE.json" >/dev/null 2>&1; then
        echo "❌ CRITICAL: TASK_QUEUE.json contains invalid JSON"
        return 1
    fi
    
    echo "✅ Task queue: OK"
    
    # Check lock directory
    if [ ! -d "$SCRIPT_DIR/locks" ]; then
        mkdir -p "$SCRIPT_DIR/locks"
        echo "✅ Lock directory: Created"
    else
        echo "✅ Lock directory: OK"
    fi
    
    # Check audit directory
    if [ ! -d "$SCRIPT_DIR/audit" ]; then
        mkdir -p "$SCRIPT_DIR/audit"
        echo "✅ Audit directory: Created"
    else
        echo "✅ Audit directory: OK"
    fi
    
    # Check recovery directory
    if [ ! -d "$SCRIPT_DIR/recovery" ]; then
        mkdir -p "$SCRIPT_DIR/recovery"
        echo "✅ Recovery directory: Created"
    else
        echo "✅ Recovery directory: OK"
    fi
    
    # Check for stale locks
    local stale_count=0
    for lock_file in "$SCRIPT_DIR/locks"/task_*.lock; do
        [ -d "$lock_file" ] || continue
        
        local timestamp=$(cat "$lock_file/timestamp" 2>/dev/null || echo "0")
        local age=$(($(date +%s) - timestamp))
        
        if [ $age -gt $MAX_STALE_TIME ]; then
            ((stale_count++))
        fi
    done
    
    if [ $stale_count -gt 0 ]; then
        echo "⚠️  Stale locks: $stale_count (>2 hours old)"
    else
        echo "✅ Active locks: OK"
    fi
    
    # Check failed tasks
    local failed_count=$(jq '.failed | length' "$SCRIPT_DIR/recovery/failed_tasks.json" 2>/dev/null || echo 0)
    if [ $failed_count -gt 0 ]; then
        echo "⚠️  Failed tasks: $failed_count pending retry"
    else
        echo "✅ Failed tasks: None"
    fi
    
    # Check event bus
    if [ -x "$EVENT_BUS" ]; then
        local pending_events
        pending_events=$(ls -1 "$EVENT_DIR"/*.json 2>/dev/null | wc -l)
        if [ "$pending_events" -gt 0 ]; then
            echo "⚠️  Pending events: $pending_events awaiting processing"
        else
            echo "✅ Event bus: No pending events"
        fi
    else
        echo "⚠️  Event bus script missing (AI/event_bus.sh)"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 0
}

process_event_queue() {
    if [ -x "$EVENT_BUS" ]; then
        bash "$EVENT_BUS" process >/dev/null 2>&1
    fi
}

# Function: Auto-heal system
auto_heal() {
    echo "🔧 Auto-healing system..."
    
    # Check for stale locks
    bash "$SCRIPT_DIR/task_lock.sh" clean
    
    # Attempt recovery of failed tasks
    bash "$SCRIPT_DIR/task_recovery.sh" retry auto
    
    # Auto-execute Gemini tasks if API key is set
    if [ -n "${GEMINI_API_KEY:-}" ]; then
        echo "🤖 Auto-executing Gemini tasks..."
        bash "$SCRIPT_DIR/gemini_auto_executor.sh" all 2>&1 | tail -3
    fi
    
    # Auto-execute ChatGPT tasks if API key is set
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        echo "💬 Auto-executing ChatGPT tasks..."
        bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" all 2>&1 | tail -3
    fi
    
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo "🎭 Auto-executing Claude tasks..."
        bash "$SCRIPT_DIR/claude_auto_executor.sh" all 2>&1 | tail -3
    fi
    
    process_event_queue
    
    echo "✅ Auto-heal complete"
}

# Function: Monitor mode (continuous)
monitor_mode() {
    echo "👁️  Starting continuous monitoring..."
    echo "   Interval: ${MONITOR_INTERVAL}s"
    echo "   Press Ctrl+C to stop"
    echo ""
    
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║           AI ORCHESTRATOR - MONITORING MODE              ║"
        echo "║              $(date '+%Y-%m-%d %H:%M:%S')                       ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        
        # Show dashboard
        bash "$SCRIPT_DIR/task_coordinator.sh" dashboard
        
        # Process events to trigger follow-up actions immediately
        process_event_queue
        
        # Auto-heal every 5 minutes
        if [ $((SECONDS % 300)) -lt $MONITOR_INTERVAL ]; then
            auto_heal
        fi
        
        echo ""
        echo "Next update in ${MONITOR_INTERVAL}s..."
        sleep $MONITOR_INTERVAL
    done
}

# Function: Generate status report
status_report() {
    local output_file="${1:-$SCRIPT_DIR/../AI_STATUS_REPORT_$(date +%Y%m%d_%H%M%S).md}"
    
    echo "📄 Generating status report..."
    
    cat > "$output_file" << 'REPORT_START'
# AI Orchestration Status Report

**Generated:** $(date -Iseconds)

## System Health

REPORT_START
    
    # Add health check
    health_check >> "$output_file"
    
    # Add dashboard
    echo "" >> "$output_file"
    echo "## Current Status" >> "$output_file"
    echo "" >> "$output_file"
    bash "$SCRIPT_DIR/task_coordinator.sh" dashboard >> "$output_file"
    
    # Add recent audit events
    echo "" >> "$output_file"
    echo "## Recent Activity (Last 20 Events)" >> "$output_file"
    echo "" >> "$output_file"
    bash "$SCRIPT_DIR/task_audit.sh" query recent 20 >> "$output_file"
    
    # Add failed tasks
    echo "" >> "$output_file"
    echo "## Failed Tasks" >> "$output_file"
    echo "" >> "$output_file"
    bash "$SCRIPT_DIR/task_recovery.sh" list >> "$output_file"
    
    echo "✅ Report saved: $output_file"
}

# Function: Interactive menu
interactive_menu() {
    while true; do
        clear
        echo "╔══════════════════════════════════════════════════════════╗"
        echo "║              AI ORCHESTRATOR CONTROL PANEL               ║"
        echo "╚══════════════════════════════════════════════════════════╝"
        echo ""
        echo "  1. 📊 Dashboard          - View current status"
        echo "  2. 🏥 Health Check       - System diagnostics"
        echo "  3. 🔧 Auto-heal          - Fix issues & run Gemini"
        echo "  4. ⚖️  Balance Load       - Redistribute tasks"
        echo "  5. 👁️  Monitor Mode       - Continuous monitoring"
        echo "  6. 📄 Status Report      - Generate full report"
        echo "  7. 📋 Audit Log          - Recent activity"
        echo "  8. 🔄 Retry Failed       - Recover failed tasks"
        echo "  9. 🔐 Lock Management    - View/clean locks"
        echo "  🤖 Gemini Automation     - Execute Gemini tasks"
        echo "  💬 ChatGPT Automation    - Execute ChatGPT tasks"
        echo "  🎭 Claude Automation     - Execute Claude tasks"
        echo "  🚀 Automate All          - Run all automated AIs"
        echo "  0. 🚪 Exit"
        echo ""
        read -p "Select option: " choice
        
        case $choice in
            1)
                bash "$SCRIPT_DIR/task_coordinator.sh" dashboard
                read -p "Press Enter to continue..."
                ;;
            2)
                health_check
                read -p "Press Enter to continue..."
                ;;
            3)
                auto_heal
                read -p "Press Enter to continue..."
                ;;
            4)
                bash "$SCRIPT_DIR/task_coordinator.sh" balance
                read -p "Press Enter to continue..."
                ;;
            5)
                monitor_mode
                ;;
            6)
                status_report
                read -p "Press Enter to continue..."
                ;;
            7)
                bash "$SCRIPT_DIR/task_audit.sh" query recent 30
                read -p "Press Enter to continue..."
                ;;
            8)
                bash "$SCRIPT_DIR/task_recovery.sh" list
                echo ""
                read -p "Retry task ID (or Enter to skip): " retry_id
                if [ -n "$retry_id" ]; then
                    bash "$SCRIPT_DIR/task_recovery.sh" retry "$retry_id" auto
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                bash "$SCRIPT_DIR/task_lock.sh" list
                echo ""
                read -p "Clean stale locks? (y/N): " clean
                if [ "$clean" = "y" ] || [ "$clean" = "Y" ]; then
                    bash "$SCRIPT_DIR/task_lock.sh" clean
                fi
                read -p "Press Enter to continue..."
                ;;
            gemini|g|🤖)
                echo ""
                echo "🤖 Gemini Automation Options:"
                echo "  1. Execute one task"
                echo "  2. Execute all tasks"
                echo "  3. Start watch mode"
                echo "  4. Check status"
                echo ""
                read -p "Select option: " gemini_choice
                case $gemini_choice in
                    1) bash "$SCRIPT_DIR/gemini_auto_executor.sh" once ;;
                    2) bash "$SCRIPT_DIR/gemini_auto_executor.sh" all ;;
                    3) bash "$SCRIPT_DIR/gemini_auto_executor.sh" watch ;;
                    4) bash "$SCRIPT_DIR/gemini_agent.sh" status ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            chatgpt|c|💬)
                echo ""
                echo "💬 ChatGPT Automation Options:"
                echo "  1. Execute one task"
                echo "  2. Execute all tasks"
                echo "  3. Start watch mode"
                echo "  4. Check status"
                echo "  5. Generate marketing content"
                echo "  6. Create social media posts"
                echo ""
                read -p "Select option: " chatgpt_choice
                case $chatgpt_choice in
                    1) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" once ;;
                    2) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" all ;;
                    3) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" watch ;;
                    4) bash "$SCRIPT_DIR/chatgpt_agent.sh" status ;;
                    5)
                        read -p "Enter marketing context: " marketing_context
                        bash "$SCRIPT_DIR/chatgpt_agent.sh" marketing "$marketing_context"
                        ;;
                    6)
                        read -p "Enter social media context: " social_context
                        bash "$SCRIPT_DIR/chatgpt_agent.sh" social "$social_context"
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            claude|cl|🎭)
                echo ""
                echo "🎭 Claude Automation Options:"
                echo "  1. Execute one task"
                echo "  2. Execute all tasks"
                echo "  3. Start watch mode"
                echo "  4. Check status"
                echo "  5. Review content"
                echo "  6. Analyze UX"
                echo ""
                read -p "Select option: " claude_choice
                case $claude_choice in
                    1) bash "$SCRIPT_DIR/claude_auto_executor.sh" once ;;
                    2) bash "$SCRIPT_DIR/claude_auto_executor.sh" all ;;
                    3) bash "$SCRIPT_DIR/claude_auto_executor.sh" watch ;;
                    4) bash "$SCRIPT_DIR/claude_agent.sh" status ;;
                    5)
                        read -p "Enter file path to review: " file_path
                        bash "$SCRIPT_DIR/claude_agent.sh" review "$file_path"
                        ;;
                    6)
                        read -p "Enter UX context to analyze: " ux_context
                        bash "$SCRIPT_DIR/claude_agent.sh" ux "$ux_context"
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            automate|auto|🚀)
                echo ""
                echo "🚀 Automated AI Execution Options:"
                echo "  1. Execute all automated AI tasks once"
                echo "  2. Start watch mode for all automated AIs"
                echo ""
                read -p "Select option: " auto_choice
                case $auto_choice in
                    1)
                        echo "🤖 Executing all automated AI tasks..."
                        [ -n "${GEMINI_API_KEY:-}" ] && bash "$SCRIPT_DIR/gemini_auto_executor.sh" all
                        [ -n "${OPENAI_API_KEY:-}" ] && bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" all
                        [ -n "${ANTHROPIC_API_KEY:-}" ] && bash "$SCRIPT_DIR/claude_auto_executor.sh" all
                        ;;
                    2)
                        echo "👀 Starting watch mode for all automated AIs..."
                        echo "Press Ctrl+C to stop"
                        [ -n "${GEMINI_API_KEY:-}" ] && bash "$SCRIPT_DIR/gemini_auto_executor.sh" watch &
                        [ -n "${OPENAI_API_KEY:-}" ] && bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" watch &
                        [ -n "${ANTHROPIC_API_KEY:-}" ] && bash "$SCRIPT_DIR/claude_auto_executor.sh" watch &
                        wait
                        ;;
                esac
                read -p "Press Enter to continue..."
                ;;
            0)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# Main command dispatcher
case "${1:-menu}" in
    health)
        health_check
        ;;
    heal)
        auto_heal
        ;;
    monitor)
        monitor_mode
        ;;
    report)
        status_report "$2"
        ;;
    dashboard)
        bash "$SCRIPT_DIR/task_coordinator.sh" dashboard
        ;;
    gemini)
        # Gemini automation commands
        case "${2:-status}" in
            once) bash "$SCRIPT_DIR/gemini_auto_executor.sh" once ;;
            all) bash "$SCRIPT_DIR/gemini_auto_executor.sh" all ;;
            watch) bash "$SCRIPT_DIR/gemini_auto_executor.sh" watch ;;
            status) bash "$SCRIPT_DIR/gemini_agent.sh" status ;;
            *) 
                echo "Usage: $0 gemini {once|all|watch|status}"
                exit 1
                ;;
        esac
        ;;
    chatgpt)
        # ChatGPT automation commands
        case "${2:-status}" in
            once) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" once ;;
            all) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" all ;;
            watch) bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" watch ;;
            status) bash "$SCRIPT_DIR/chatgpt_agent.sh" status ;;
            *) 
                echo "Usage: $0 chatgpt {once|all|watch|status}"
                exit 1
                ;;
        esac
        ;;
    claude)
        # Claude automation commands
        case "${2:-status}" in
            once) bash "$SCRIPT_DIR/claude_auto_executor.sh" once ;;
            all) bash "$SCRIPT_DIR/claude_auto_executor.sh" all ;;
            watch) bash "$SCRIPT_DIR/claude_auto_executor.sh" watch ;;
            status) bash "$SCRIPT_DIR/claude_agent.sh" status ;;
            *) 
                echo "Usage: $0 claude {once|all|watch|status}"
                exit 1
                ;;
        esac
        ;;
    automate)
        # Run all automated AIs
        case "${2:-all}" in
            all)
                echo "🤖 Executing all automated AI tasks..."
                [ -n "${GEMINI_API_KEY:-}" ] && bash "$SCRIPT_DIR/gemini_auto_executor.sh" all
                [ -n "${OPENAI_API_KEY:-}" ] && bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" all
                [ -n "${ANTHROPIC_API_KEY:-}" ] && bash "$SCRIPT_DIR/claude_auto_executor.sh" all
                ;;
            watch)
                echo "👀 Starting watch mode for all automated AIs..."
                [ -n "${GEMINI_API_KEY:-}" ] && bash "$SCRIPT_DIR/gemini_auto_executor.sh" watch &
                [ -n "${OPENAI_API_KEY:-}" ] && bash "$SCRIPT_DIR/chatgpt_auto_executor.sh" watch &
                [ -n "${ANTHROPIC_API_KEY:-}" ] && bash "$SCRIPT_DIR/claude_auto_executor.sh" watch &
                wait
                ;;
            *)
                echo "Usage: $0 automate {all|watch}"
                exit 1
                ;;
        esac
        ;;
    events)
        process_event_queue
        ;;
    watch-events)
        if [ -x "$EVENT_BUS" ]; then
            bash "$EVENT_BUS" watch "${2:-5}"
        else
            echo "Event bus utility not found at $EVENT_BUS"
            exit 1
        fi
        ;;
    menu|*)
        interactive_menu
        ;;
esac
