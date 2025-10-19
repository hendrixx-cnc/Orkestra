#!/bin/bash
# ENHANCED COMPLETE TASK SCRIPT WITH ATOMICITY & AUDIT
# Integrates: Lock Release, Audit Trail, Success Tracking

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Note: Scripts called as subprocesses to avoid function conflicts

# Ensure task queue file exists
if [ ! -f "$TASK_QUEUE" ]; then
    echo "❌ Error: TASK_QUEUE.json not found at $TASK_QUEUE"
    exit 1
fi

# Usage check
if [ $# -lt 1 ]; then
    echo "Usage: $0 <task_id> [notes]"
    echo "Example: $0 6 'Added author bio to landing page'"
    exit 1
fi

TASK_ID=$1
NOTES="${2:-Task completed successfully}"

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq not installed. Required for atomic operations."
    exit 1
fi

# Validate TASK_QUEUE.json
if ! jq empty "$TASK_QUEUE" > /dev/null 2>&1; then
    echo "❌ Error: TASK_QUEUE.json contains invalid JSON"
    exit 1
fi

# Step 1: Check if task exists
TASK_EXISTS=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber))' "$TASK_QUEUE")
if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Error: Task #$TASK_ID not found in queue"
    exit 1
fi

# Step 2: Get task details
TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")
TASK_STATUS=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .status' "$TASK_QUEUE")
ASSIGNED_TO=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")
CLAIMED_ON=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .claimed_on // "unknown"' "$TASK_QUEUE")

# Step 3: Check if task is in progress
if [ "$TASK_STATUS" = "completed" ]; then
    echo "ℹ️  Task #$TASK_ID is already completed"
    exit 0
fi

if [ "$TASK_STATUS" != "in_progress" ]; then
    echo "⚠️  Warning: Task #$TASK_ID status is '$TASK_STATUS', not 'in_progress'"
    echo "   Marking as completed anyway..."
fi

# Step 4: Calculate actual time
TIMESTAMP=$(date -Iseconds)
ACTUAL_TIME="unknown"

if [ "$CLAIMED_ON" != "unknown" ] && [ "$CLAIMED_ON" != "null" ]; then
    CLAIMED_EPOCH=$(date -d "$CLAIMED_ON" +%s 2>/dev/null || echo 0)
    COMPLETED_EPOCH=$(date +%s)
    
    if [ $CLAIMED_EPOCH -gt 0 ]; then
        DURATION_SECONDS=$((COMPLETED_EPOCH - CLAIMED_EPOCH))
        HOURS=$((DURATION_SECONDS / 3600))
        MINUTES=$(((DURATION_SECONDS % 3600) / 60))
        
        if [ $HOURS -gt 0 ]; then
            ACTUAL_TIME="${HOURS}h ${MINUTES}m"
        else
            ACTUAL_TIME="${MINUTES}m"
        fi
    fi
fi

# Step 5: Update task queue (atomic with version control)
TMP_FILE=$(mktemp)

jq --arg tid "$TASK_ID" \
   --arg ts "$TIMESTAMP" \
   --arg notes "$NOTES" \
   --arg time "$ACTUAL_TIME" \
   '(.queue[] | select(.id == ($tid | tonumber))) |= (
       .status = "completed" |
       .completed_on = $ts |
       .last_updated = $ts |
       .actual_time = $time |
       .completion_notes = $notes
   )' "$TASK_QUEUE" > "$TMP_FILE"

# Verify JSON is valid after update
if ! jq empty "$TMP_FILE" > /dev/null 2>&1; then
    echo "❌ Error: JSON update produced invalid JSON"
    rm -f "$TMP_FILE"
    exit 1
fi

# Atomic rename (POSIX guarantees atomicity)
mv "$TMP_FILE" "$TASK_QUEUE"

# Step 6: Release lock
bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "COMPLETE"

# Step 7: Log to audit trail
bash "$SCRIPT_DIR/task_audit.sh" log \
    "COMPLETED" "$TASK_ID" "$ASSIGNED_TO" \
    "Task completed: $NOTES" "completed"

# Step 8a: Emit completion event for orchestrator triggers
bash "$SCRIPT_DIR/event_bus.sh" emit task_completed "$TASK_ID" "$NOTES" >/dev/null 2>&1 || true
bash "$SCRIPT_DIR/event_bus.sh" process >/dev/null 2>&1 || true

# Step 8: Success output
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TASK COMPLETED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Task #$TASK_ID: $TASK_TITLE"
echo "   Status: in_progress → completed"
echo ""
echo "   Updated: TASK_QUEUE.json"
echo "   Actual Time: $ACTUAL_TIME"
echo ""

# Step 9: Check for dependent tasks
DEPENDENT_TASKS=$(jq -r --arg tid "$TASK_ID" \
    '.queue[] | select(.dependencies != null) | select(.dependencies[] == ($tid | tonumber)) | .id' \
    "$TASK_QUEUE")

if [ -n "$DEPENDENT_TASKS" ]; then
    echo "   🔓 Unlocked dependent tasks:"
    for dep_task in $DEPENDENT_TASKS; do
        DEP_TITLE=$(jq -r --arg did "$dep_task" '.queue[] | select(.id == ($did | tonumber)) | .title' "$TASK_QUEUE")
        DEP_STATUS=$(jq -r --arg did "$dep_task" '.queue[] | select(.id == ($did | tonumber)) | .status' "$TASK_QUEUE")
        
        if [ "$DEP_STATUS" = "pending" ]; then
            echo "      → Task #$dep_task: $DEP_TITLE (now available)"
        fi
    done
    echo ""
fi

# Step 10: Show progress
TOTAL_TASKS=$(jq '.queue | length' "$TASK_QUEUE")
COMPLETED_TASKS=$(jq '[.queue[] | select(.status == "completed")] | length' "$TASK_QUEUE")
PROGRESS=$((COMPLETED_TASKS * 100 / TOTAL_TASKS))

echo "   📊 Overall Progress: $COMPLETED_TASKS/$TOTAL_TASKS tasks ($PROGRESS%)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Next: Run ai_coordinator.sh to see what's next!"
echo ""

exit 0
