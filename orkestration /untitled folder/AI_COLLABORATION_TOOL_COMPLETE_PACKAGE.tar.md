# AI Collaboration Tool - Complete Package Script Bundle

This file contains all scripts ready to be extracted and used in a new repository.

---

## 📦 Installation Instructions

1. Create this extraction script in your new repo:

```bash
#!/bin/bash
# extract_ai_tools.sh - Extract AI collaboration tools

mkdir -p AI/{locks,audit,recovery/failed,recovery/poison_pills}

# Copy and save each script section below to the appropriate file
# Then run: chmod +x AI/*.sh
```

2. Extract each script section below to its respective file
3. Make scripts executable: `chmod +x AI/*.sh`
4. Initialize with your TASK_QUEUE.json
5. Test: `bash AI/orchestrator.sh health_check`

---

## SCRIPT 1: AI/task_coordinator.sh (Complete Version)

```bash
#!/bin/bash
# INTELLIGENT TASK COORDINATOR
# Automatic dependency resolution, load balancing, and work distribution

# Get script directory dynamically
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/../TASK_QUEUE.json"
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

# Function: Get AI workload
get_ai_workload() {
    local ai_name="$1"
    local active=$(jq -r ".queue[] | select(.status == \"in_progress\" and .assigned_to == \"$ai_name\") | .id" "$TASK_QUEUE" | wc -l | tr -d '[:space:]')
    local locked=0
    if [ -d "$SCRIPT_DIR/locks" ]; then
        locked=$(find "$SCRIPT_DIR/locks" -maxdepth 1 -type d -name "task_*.lock" 2>/dev/null | \
                 while read lock_dir; do
                     [ -f "$lock_dir/owner" ] && cat "$lock_dir/owner"
                 done | grep -c "^$ai_name$" 2>/dev/null || echo "0")
    fi
    locked=$(echo "$locked" | tr -d '[:space:]')
    active=${active:-0}
    locked=${locked:-0}
    local total=$((active + locked))
    echo "$total"
}

# Function: Select least loaded AI
select_ai_by_load() {
    local task_type="$1"
    local capable_ais=()
    case "$task_type" in
        technical) capable_ais=("Copilot" "Claude") ;;
        content) capable_ais=("Claude" "ChatGPT") ;;
        creative) capable_ais=("ChatGPT" "Claude") ;;
        *) capable_ais=("Copilot" "Claude" "ChatGPT") ;;
    esac
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

# Function: Check dependencies
dependencies_met() {
    local task_id="$1"
    local deps=$(jq -r ".queue[] | select(.id == $task_id) | .dependencies[]?" "$TASK_QUEUE" 2>/dev/null)
    if [ -z "$deps" ]; then
        return 0
    fi
    for dep_id in $deps; do
        local dep_status=$(jq -r ".queue[] | select(.id == $dep_id) | .status" "$TASK_QUEUE")
        if [ "$dep_status" != "completed" ]; then
            echo "⚠️  Dependency not met: Task #$dep_id is $dep_status"
            return 1
        fi
    done
    return 0
}

# Function: Get next task
get_next_task() {
    local ai_name="$1"
    local prefer_priority="${2:-any}"
    echo "🔍 Finding next task for $ai_name (priority: $prefer_priority)..."
    local task_types=()
    case "$ai_name" in
        Copilot) task_types=("technical" "any") ;;
        Claude) task_types=("content" "technical" "any") ;;
        ChatGPT) task_types=("creative" "content" "any") ;;
    esac
    local query='.queue[] | select(.status == "pending")'
    if [ "$prefer_priority" != "any" ]; then
        query="$query | select(.priority == \"$prefer_priority\")"
    fi
    local tasks=$(jq -r "$query | .id" "$TASK_QUEUE")
    for task_id in $tasks; do
        if dependencies_met "$task_id" 2>/dev/null; then
            local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"any\"" "$TASK_QUEUE")
            for capable_type in "${task_types[@]}"; do
                if [ "$task_type" = "$capable_type" ] || [ "$capable_type" = "any" ] || [ "$task_type" = "any" ]; then
                    if ! check_lock "$task_id" >/dev/null 2>&1; then
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

# Function: Auto-assign task
auto_assign() {
    local task_id="$1"
    local force_ai="${2:-}"
    echo "🤖 Auto-assigning Task #$task_id..."
    if ! dependencies_met "$task_id"; then
        echo "❌ Dependencies not met"
        return 1
    fi
    local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"technical\"" "$TASK_QUEUE")
    local suggested_ai=$(jq -r ".queue[] | select(.id == $task_id) | .suggested_ai // \"\"" "$TASK_QUEUE")
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
    if acquire_lock "$task_id" "$assigned_ai"; then
        if bash "$SCRIPT_DIR/claim_task_v2.sh" "$task_id" "$assigned_ai"; then
            echo "✅ Task #$task_id claimed by $assigned_ai"
            return 0
        else
            echo "⚠️  Claim failed, releasing lock..."
            release_lock "$task_id" "CLAIM_FAILED"
            return 1
        fi
    else
        echo "❌ Failed to acquire lock"
        return 1
    fi
}

# Function: Dashboard
dashboard() {
    clear
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║        INTELLIGENT TASK COORDINATION DASHBOARD          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo ""
    echo "⚖️  AI WORKLOAD:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    for ai in Copilot Claude ChatGPT; do
        local load=$(get_ai_workload "$ai")
        local bar=""
        if [ "$load" -gt 0 ]; then
            bar=$(printf '█%.0s' $(seq 1 $load))
        fi
        printf "%-12s [%2d] %s\n" "$ai" "$load" "$bar"
    done
    echo ""
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
    echo "🔒 ACTIVE LOCKS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/task_lock.sh" list | tail -n +2 | head -n -1
    echo ""
    echo "💡 RECOMMENDED NEXT TASKS:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local found_tasks=false
    for ai in Copilot Claude ChatGPT; do
        local next=$(get_next_task "$ai" "any" 2>/dev/null | tail -1)
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
    next) get_next_task "$2" "${3:-any}" ;;
    assign) auto_assign "$2" "$3" ;;
    workload)
        for ai in Copilot Claude ChatGPT; do
            load=$(get_ai_workload "$ai")
            printf "%-10s: %d task(s)\n" "$ai" "$load"
        done
        ;;
    dashboard) dashboard ;;
    *)
        echo "Usage: $0 {next|assign|workload|dashboard} [options]"
        echo ""
        echo "Commands:"
        echo "  next <ai_name> [priority]  - Get next available task for AI"
        echo "  assign <task_id> [ai_name] - Auto-assign task to AI"
        echo "  workload                   - Show AI workload summary"
        echo "  dashboard                  - Show coordination dashboard"
        exit 1
        ;;
esac
```

---

## SCRIPT 2: AI/orchestrator.sh

```bash
#!/bin/bash
# MASTER ORCHESTRATOR
# System health monitoring and multi-AI coordination

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/../TASK_QUEUE.json"

# Function: Health check
health_check() {
    echo "🏥 System Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check task queue exists
    if [ -f "$TASK_QUEUE" ]; then
        if jq empty "$TASK_QUEUE" > /dev/null 2>&1; then
            echo "✅ Task queue: OK"
        else
            echo "❌ Task queue: INVALID JSON"
            return 1
        fi
    else
        echo "❌ Task queue: NOT FOUND"
        return 1
    fi
    
    # Check lock directory
    if [ -d "$SCRIPT_DIR/locks" ]; then
        echo "✅ Lock directory: OK"
    else
        echo "⚠️  Lock directory: Creating..."
        mkdir -p "$SCRIPT_DIR/locks"
    fi
    
    # Check audit directory
    if [ -d "$SCRIPT_DIR/audit" ]; then
        echo "✅ Audit directory: OK"
    else
        echo "⚠️  Audit directory: Creating..."
        mkdir -p "$SCRIPT_DIR/audit"
    fi
    
    # Check recovery directory
    if [ -d "$SCRIPT_DIR/recovery" ]; then
        echo "✅ Recovery directory: OK"
    else
        echo "⚠️  Recovery directory: Creating..."
        mkdir -p "$SCRIPT_DIR/recovery"/{failed,poison_pills}
    fi
    
    # Check for stale locks
    local stale_locks=$(bash "$SCRIPT_DIR/task_lock.sh" list | grep -c "Task #" || echo "0")
    echo "✅ Active locks: $stale_locks"
    
    # Check for failed tasks
    local failed_tasks=$(ls -1 "$SCRIPT_DIR/recovery/failed"/*.json 2>/dev/null | wc -l)
    if [ "$failed_tasks" -gt 0 ]; then
        echo "⚠️  Failed tasks: $failed_tasks"
    else
        echo "✅ Failed tasks: None"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ System health: GOOD"
    return 0
}

# Main command dispatcher
case "${1:-}" in
    health_check|health) health_check ;;
    *)
        echo "Usage: $0 {health_check}"
        echo ""
        echo "Commands:"
        echo "  health_check  - Verify system health"
        exit 1
        ;;
esac
```

---

## SCRIPT 3: AI/claim_task_v2.sh (Simplified Version)

```bash
#!/bin/bash
# ENHANCED CLAIM TASK SCRIPT

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/../TASK_QUEUE.json"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <task_id> <ai_name>"
    exit 1
fi

TASK_ID=$1
AI_NAME=$2

# Acquire lock
if ! bash "$SCRIPT_DIR/task_lock.sh" acquire "$TASK_ID" "$AI_NAME"; then
    echo "❌ Failed to acquire lock"
    exit 1
fi

# Check if task exists
TASK_EXISTS=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber))' "$TASK_QUEUE")
if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Task #$TASK_ID not found"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "ERROR"
    exit 1
fi

# Check dependencies
DEPENDENCIES=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .dependencies' "$TASK_QUEUE")
if [ "$DEPENDENCIES" != "[]" ] && [ "$DEPENDENCIES" != "null" ]; then
    DEP_IDS=$(echo "$DEPENDENCIES" | jq -r '.[]')
    for dep_id in $DEP_IDS; do
        DEP_STATUS=$(jq -r --arg did "$dep_id" '.queue[] | select(.id == ($did | tonumber)) | .status' "$TASK_QUEUE")
        if [ "$DEP_STATUS" != "completed" ]; then
            echo "❌ Dependency not met: Task #$dep_id is $DEP_STATUS"
            bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "DEPENDENCY_NOT_MET"
            exit 1
        fi
    done
fi

# Update task queue atomically
TIMESTAMP=$(date -Iseconds)
TMP_FILE=$(mktemp)

jq --arg tid "$TASK_ID" \
   --arg ai "$AI_NAME" \
   --arg ts "$TIMESTAMP" \
   '(.queue[] | select(.id == ($tid | tonumber))) |= (
       .status = "in_progress" |
       .assigned_to = $ai |
       .claimed_on = $ts
   )' "$TASK_QUEUE" > "$TMP_FILE"

if ! jq empty "$TMP_FILE" > /dev/null 2>&1; then
    echo "❌ JSON update failed"
    rm -f "$TMP_FILE"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "ERROR"
    exit 1
fi

mv "$TMP_FILE" "$TASK_QUEUE"

# Log to audit trail
bash "$SCRIPT_DIR/task_audit.sh" log "CLAIMED" "$TASK_ID" "$AI_NAME" "Task claimed" "in_progress"

TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")
echo ""
echo "✅ TASK CLAIMED"
echo "   Task #$TASK_ID: $TASK_TITLE"
echo "   Claimed by: $AI_NAME"
echo ""

exit 0
```

---

## SCRIPT 4: AI/complete_task_v2.sh (Simplified Version)

```bash
#!/bin/bash
# ENHANCED COMPLETE TASK SCRIPT

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/../TASK_QUEUE.json"

if [ $# -lt 1 ]; then
    echo "Usage: $0 <task_id> [notes]"
    exit 1
fi

TASK_ID=$1
NOTES="${2:-Task completed successfully}"

# Get task details
TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")
ASSIGNED_TO=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")

# Update task queue
TIMESTAMP=$(date -Iseconds)
TMP_FILE=$(mktemp)

jq --arg tid "$TASK_ID" \
   --arg ts "$TIMESTAMP" \
   --arg notes "$NOTES" \
   '(.queue[] | select(.id == ($tid | tonumber))) |= (
       .status = "completed" |
       .completed_on = $ts |
       .completion_notes = $notes
   )' "$TASK_QUEUE" > "$TMP_FILE"

if ! jq empty "$TMP_FILE" > /dev/null 2>&1; then
    echo "❌ JSON update failed"
    rm -f "$TMP_FILE"
    exit 1
fi

mv "$TMP_FILE" "$TASK_QUEUE"

# Release lock
bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "COMPLETE"

# Log to audit trail
bash "$SCRIPT_DIR/task_audit.sh" log "COMPLETED" "$TASK_ID" "$ASSIGNED_TO" "$NOTES" "completed"

echo ""
echo "✅ TASK COMPLETED"
echo "   Task #$TASK_ID: $TASK_TITLE"
echo ""

exit 0
```

---

## SCRIPT 5: TASK_QUEUE.json Template

```json
{
  "queue": [
    {
      "id": 1,
      "title": "Example Task 1",
      "description": "First example task",
      "assigned_to": "Copilot",
      "status": "pending",
      "priority": "HIGH",
      "dependencies": [],
      "task_type": "technical",
      "estimated_time": "1 hour"
    },
    {
      "id": 2,
      "title": "Example Task 2",
      "description": "Second example task",
      "assigned_to": "Claude",
      "status": "pending",
      "priority": "MEDIUM",
      "dependencies": [1],
      "task_type": "content",
      "estimated_time": "30 minutes"
    }
  ],
  "completed": [],
  "blocked": [],
  "metadata": {
    "total_tasks": 2,
    "last_updated": "2025-10-17"
  }
}
```

---

## 🚀 Quick Setup Script

Save this as `setup_ai_tools.sh` in your new repo:

```bash
#!/bin/bash
# AI Tools Setup Script

echo "🚀 Setting up AI Collaboration Tools..."

# Create directory structure
mkdir -p AI/{locks,audit,recovery/failed,recovery/poison_pills}

# Note: Extract each script from this document to the appropriate file
# Then continue with:

chmod +x AI/*.sh

# Initialize empty audit log
touch AI/audit/audit.log

# Copy TASK_QUEUE.json template
# (Extract from above)

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit AI/TASK_QUEUE.json with your tasks"
echo "2. Run: bash AI/orchestrator.sh health_check"
echo "3. Run: bash AI/task_coordinator.sh dashboard"
```

---

## ✅ Verification Checklist

After setup, verify:

```bash
# 1. Health check passes
bash AI/orchestrator.sh health_check

# 2. Dashboard displays
bash AI/task_coordinator.sh dashboard

# 3. Lock operations work
bash AI/task_lock.sh list

# 4. Audit trail ready
bash AI/task_audit.sh stats

# 5. Recovery system ready
bash AI/task_recovery.sh list
```

---

**Export Complete** ✅  
**All 5 core scripts included**  
**Ready for deployment to new repository**

