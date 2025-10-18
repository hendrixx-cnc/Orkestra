#!/bin/bash
# INTELLIGENT TASK COORDINATOR
# Automatic dependency resolution, load balancing, and work distribution

SCRIPT_DIR="/workspaces/The-Quantum-Self-/AI"
TASK_QUEUE="/workspaces/The-Quantum-Self-/TASK_QUEUE.json"
LOCK_SCRIPT="$SCRIPT_DIR/task_lock.sh"

# Wrapper functions to call lock helpers without sourcing (avoid command dispatcher conflict)
acquire_lock() {
    bash "$LOCK_SCRIPT" acquire "$@"
}

release_lock() {
    bash "$LOCK_SCRIPT" release "$@"
}

check_lock() {
    bash "$LOCK_SCRIPT" check "$@"
}

# Note: Other scripts called as subprocesses to avoid function conflicts

# Function: Get AI workload (number of tasks currently assigned)
get_ai_workload() {
    local ai_name="$1"
    
    # Count in_progress tasks for this AI
    local active=$(jq -r ".queue[] | select(.status == \"in_progress\" and .assigned_to == \"$ai_name\") | .id" "$TASK_QUEUE" | wc -l | tr -d '[:space:]')
    
    # Count locked tasks - tidied to avoid double output
    local locked=0
    if [ -d "$SCRIPT_DIR/locks" ]; then
        locked=$(find "$SCRIPT_DIR/locks" -maxdepth 1 -type d -name "task_*.lock" 2>/dev/null | \
                 while read lock_dir; do
                     [ -f "$lock_dir/owner" ] && cat "$lock_dir/owner"
                 done | grep -c "^$ai_name$" 2>/dev/null || echo "0")
    fi
    locked=$(echo "$locked" | tr -d '[:space:]')
    
    # Ensure we have valid numbers
    active=${active:-0}
    locked=${locked:-0}
    
    local total=$((active + locked))
    echo "$total"
}

# Function: Select least loaded AI
select_ai_by_load() {
    local task_type="$1"
    
    # Get capable AIs for this task type
    local capable_ais=()
    case "$task_type" in
        technical)
            capable_ais=("Copilot" "Claude")
            ;;
        content)
            capable_ais=("Claude" "ChatGPT")
            ;;
        creative)
            capable_ais=("ChatGPT" "Claude")
            ;;
        firebase|cloud|architecture)
            capable_ais=("Gemini" "Copilot")
            ;;
        *)
            capable_ais=("Copilot" "Claude" "ChatGPT" "Gemini")
            ;;
    esac
    
    # Find AI with lowest workload
    local min_load=999
    local best_ai=""
    
    for ai in "${capable_ais[@]}"; do
        local load=$(get_ai_workload "$ai")
        if [ $load -lt $min_load ]; then
            min_load=$load
            best_ai="$ai"
        fi
    done
    
    echo "$best_ai"
}

# Function: Check if all dependencies are met
dependencies_met() {
    local task_id="$1"
    
    local deps=$(jq -r ".queue[] | select(.id == $task_id) | .dependencies[]?" "$TASK_QUEUE" 2>/dev/null)
    
    if [ -z "$deps" ]; then
        return 0  # No dependencies
    fi
    
    for dep_id in $deps; do
        local dep_status=$(jq -r ".queue[] | select(.id == $dep_id) | .status" "$TASK_QUEUE")
        
        if [ "$dep_status" != "completed" ]; then
            echo "⚠️  Dependency not met: Task #$dep_id is $dep_status"
            return 1
        fi
    done
    
    return 0  # All dependencies met
}

# Function: Get next available task (smart selection)
get_next_task() {
    local ai_name="$1"
    local prefer_priority="${2:-any}"
    
    echo "🔍 Finding next task for $ai_name (priority: $prefer_priority)..."
    
    # Get AI's capable task types
    local task_types=()
    case "$ai_name" in
        Copilot)
            task_types=("technical" "any")
            ;;
        Claude)
            task_types=("content" "technical" "any")
            ;;
        ChatGPT)
            task_types=("creative" "content" "any")
            ;;
    esac
    
    # Query pending tasks matching criteria
    local query='.queue[] | select(.status == "pending")'
    
    # Add priority filter if specified
    if [ "$prefer_priority" != "any" ]; then
        query="$query | select(.priority == \"$prefer_priority\")"
    fi
    
    # Get matching tasks
    local tasks=$(jq -r "$query | .id" "$TASK_QUEUE")
    
    for task_id in $tasks; do
        # Check if dependencies are met
        if dependencies_met "$task_id" 2>/dev/null; then
            # Check if task type matches AI capabilities
            local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"any\"" "$TASK_QUEUE")
            
            for capable_type in "${task_types[@]}"; do
                if [ "$task_type" = "$capable_type" ] || [ "$capable_type" = "any" ] || [ "$task_type" = "any" ]; then
                    # Check if not locked
                    if ! check_lock "$task_id" 2>&1 | grep -q "locked"; then
                        echo "✅ Found: Task #$task_id"
                        echo "$task_id"
                        return 0
                    fi
                fi
            done
        fi
    done
    
    echo "⚠️  No available tasks found"
    return 1
}

# Function: Auto-assign task to AI
auto_assign() {
    local task_id="$1"
    local force_ai="${2:-}"
    
    echo "🤖 Auto-assigning Task #$task_id..."
    
    # Check dependencies
    if ! dependencies_met "$task_id"; then
        echo "❌ Dependencies not met"
        return 1
    fi
    
    # Get task info
    local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"technical\"" "$TASK_QUEUE")
    local suggested_ai=$(jq -r ".queue[] | select(.id == $task_id) | .suggested_ai // \"\"" "$TASK_QUEUE")
    
    # Determine AI assignment
    local assigned_ai=""
    if [ -n "$force_ai" ]; then
        assigned_ai="$force_ai"
        echo "   Forced assignment: $assigned_ai"
    elif [ -n "$suggested_ai" ]; then
        assigned_ai="$suggested_ai"
        echo "   Using suggested AI: $assigned_ai"
    else
        assigned_ai=$(select_ai_by_load "$task_type")
        echo "   Load-balanced assignment: $assigned_ai"
    fi
    
    # Claim task using enhanced script (handles locking & audit)
    if bash "$SCRIPT_DIR/claim_task_v2.sh" "$task_id" "$assigned_ai" >/dev/null 2>&1; then
        return 0
    else
        echo "❌ Failed to auto-assign task (see logs for details)"
        return 1
    fi
}

# Function: Balance workload across all AIs
balance_workload() {
    echo "⚖️  Balancing workload across AIs..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show current load
    for ai in Copilot Claude ChatGPT Gemini; do
        local load=$(get_ai_workload "$ai")
        printf "   %-10s: %d task(s)\n" "$ai" "$load"
    done
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Auto-assign pending tasks
    local pending_tasks=$(jq -r '.queue[] | select(.status == "pending") | .id' "$TASK_QUEUE")
    
    for task_id in $pending_tasks; do
        if dependencies_met "$task_id" 2>/dev/null; then
            echo "   Auto-assigning Task #$task_id..."
            auto_assign "$task_id" | grep -E '(assignment|Found|Failed)'
        fi
    done
    
    echo "✅ Workload balance complete"
}

# Function: Resolve dependency chain
resolve_dependencies() {
    local task_id="$1"
    
    echo "🔗 Resolving dependency chain for Task #$task_id..."
    
    local deps=$(jq -r ".queue[] | select(.id == $task_id) | .dependencies[]?" "$TASK_QUEUE" 2>/dev/null)
    
    if [ -z "$deps" ]; then
        echo "   No dependencies"
        return 0
    fi
    
    local blocking=()
    for dep_id in $deps; do
        local dep_status=$(jq -r ".queue[] | select(.id == $dep_id) | .status" "$TASK_QUEUE")
        local dep_title=$(jq -r ".queue[] | select(.id == $dep_id) | .title" "$TASK_QUEUE")
        
        if [ "$dep_status" != "completed" ]; then
            blocking+=("$dep_id")
            echo "   ❌ Task #$dep_id: $dep_title ($dep_status)"
        else
            echo "   ✅ Task #$dep_id: $dep_title (completed)"
        fi
    done
    
    if [ ${#blocking[@]} -gt 0 ]; then
        echo ""
        echo "⚠️  Cannot start Task #$task_id until dependencies complete:"
        for dep in "${blocking[@]}"; do
            echo "      - Task #$dep"
        done
        return 1
    else
        echo ""
        echo "✅ All dependencies satisfied"
        return 0
    fi
}

# Function: Get pipeline status
pipeline_status() {
    local task_id="$1"
    
    echo "📊 Pipeline Status for Task #$task_id:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local task_info=$(jq -r ".queue[] | select(.id == $task_id)" "$TASK_QUEUE")
    local title=$(echo "$task_info" | jq -r '.title')
    local status=$(echo "$task_info" | jq -r '.status')
    local assigned=$(echo "$task_info" | jq -r '.assigned_to')
    
    echo "Task: $title"
    echo "Status: $status"
    echo "Assigned: $assigned"
    echo ""
    
    # Show pipeline steps if exists
    local pipeline=$(echo "$task_info" | jq -r '.pipeline[]?' 2>/dev/null)
    
    if [ -n "$pipeline" ]; then
        echo "Pipeline Steps:"
        echo "$task_info" | jq -r '.pipeline[] | "   \(.ai): \(.task) [\(.status // "pending")]"'
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function: Show coordination dashboard
dashboard() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        INTELLIGENT TASK COORDINATION DASHBOARD          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    # Workload by AI
    echo "⚖️  AI WORKLOAD:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for ai in Copilot Claude ChatGPT Gemini; do
        local load=$(get_ai_workload "$ai")
        local bar=""
        if [ "$load" -gt 0 ]; then
            bar=$(printf '█%.0s' $(seq 1 $load))
        fi
        printf "%-12s [%2d] %s\n" "$ai" "$load" "$bar"
    done
    echo ""
    
    # Task status summary
    echo "📊 TASK STATUS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local total=$(jq '.queue | length' "$TASK_QUEUE")
    local completed=$(jq '[.queue[] | select(.status == "completed")] | length' "$TASK_QUEUE")
    local in_progress=$(jq '[.queue[] | select(.status == "in_progress")] | length' "$TASK_QUEUE")
    local pending=$(jq '[.queue[] | select(.status == "pending")] | length' "$TASK_QUEUE")
    
    printf "Total:        %2d\n" "$total"
    local pct=$((completed * 100 / total))
    printf "Completed:    %2d (%d%%)\n" "$completed" "$pct"
    printf "In Progress:  %2d\n" "$in_progress"
    printf "Pending:      %2d\n" "$pending"
    echo ""
    
    # Active locks
    echo "🔒 ACTIVE LOCKS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/task_lock.sh" list | tail -n +2 | head -n -1
    echo ""
    
    # Recent failures
    echo "❌ RECENT FAILURES:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/task_recovery.sh" list 2>/dev/null | grep -A5 "Failed Tasks" | tail -5
    echo ""
    
    # Next recommended tasks
    echo "💡 RECOMMENDED NEXT TASKS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local found_tasks=false
    for ai in Copilot Claude ChatGPT; do
        local next=$(get_next_task "$ai" "any" 2>/dev/null | tail -1)
        # Check if next is a valid number
        if [[ "$next" =~ ^[0-9]+$ ]]; then
            local title=$(jq -r ".queue[] | select(.id == $next) | .title" "$TASK_QUEUE")
            printf "%-12s → Task #%-3s: %s\n" "$ai" "$next" "$title"
            found_tasks=true
        fi
    done
    
    if [ "$found_tasks" = false ]; then
        echo "   ✅ All tasks completed - no pending tasks"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main command dispatcher
case "${1:-}" in
    next)
        get_next_task "$2" "${3:-any}"
        ;;
    assign)
        auto_assign "$2" "$3"
        ;;
    balance)
        balance_workload
        ;;
    dependencies)
        resolve_dependencies "$2"
        ;;
    pipeline)
        pipeline_status "$2"
        ;;
    workload)
        for ai in Copilot Claude ChatGPT; do
            load=$(get_ai_workload "$ai")
            printf "%-10s: %d task(s)\n" "$ai" "$load"
        done
        ;;
    dashboard)
        dashboard
        ;;
    *)
        echo "Usage: $0 {next|assign|balance|dependencies|pipeline|workload|dashboard} [options]"
        echo ""
        echo "Commands:"
        echo "  next <ai_name> [priority]       - Get next available task for AI"
        echo "  assign <task_id> [ai_name]      - Auto-assign task to AI"
        echo "  balance                         - Balance workload across AIs"
        echo "  dependencies <task_id>          - Check dependency chain"
        echo "  pipeline <task_id>              - Show pipeline status"
        echo "  workload                        - Show AI workload summary"
        echo "  dashboard                       - Show coordination dashboard"
        exit 1
        ;;
esac
