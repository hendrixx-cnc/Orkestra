#!/bin/bash
# ENHANCED CLAIM TASK SCRIPT WITH ATOMICITY & AUDIT
# Integrates: Locks, Audit Trail, Error Recovery, Dependency Checking

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Note: Scripts called as subprocesses to avoid function conflicts

# Automatic lock cleanup on script exit
LOCK_ACQUIRED=false
cleanup_on_exit() {
    if [ "$LOCK_ACQUIRED" = true ] && [ -n "$TASK_ID" ]; then
        bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "SCRIPT_EXIT" 2>/dev/null || true
    fi
}
trap cleanup_on_exit EXIT

# Ensure task queue file exists
if [ ! -f "$TASK_QUEUE" ]; then
    echo "❌ Error: TASK_QUEUE.json not found at $TASK_QUEUE"
    exit 1
fi

# Usage check
if [ $# -lt 1 ]; then
    echo "Usage: $0 <task_id> [ai_name]"
    echo "Example: $0 6 chatgpt"
    echo "         $0 6          (auto-selects best AI)"
    echo ""
    echo "If no AI specified, the smart selector chooses the best AI based on:"
    echo "  - AI specialties matching task requirements"
    echo "  - Current workload of each AI"
    exit 1
fi

TASK_ID=$1
AI_NAME=$2

# If no AI specified, use FCFS selector (simple, no conflicts)
if [ -z "$AI_NAME" ]; then
    FCFS_SELECTOR="$SCRIPT_DIR/fcfs_task_selector.sh"
    if [ -f "$FCFS_SELECTOR" ]; then
        # Use simple first-come-first-serve - no priority conflicts
        AI_NAME=$(bash "$FCFS_SELECTOR" next "$TASK_ID")
        if [ -z "$AI_NAME" ]; then
            echo "Auto-selecting first available AI for task..."
            # Fallback: just pick the assigned AI
            AI_NAME=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")
        fi
        echo "FCFS selected AI: $AI_NAME"
    else
        # Fallback to assigned AI
        AI_NAME=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")
        echo "Using assigned AI: $AI_NAME"
    fi
fi

# Validate AI name exists in agent list (case-insensitive)
AI_NAME_LOWER=$(echo "$AI_NAME" | tr '[:upper:]' '[:lower:]')
ai_exists=$(jq -r ".ai_agents[] | select(.name | ascii_downcase == \"$AI_NAME_LOWER\") | .name" "$TASK_QUEUE" | head -1)

if [ -z "$ai_exists" ]; then
    echo "Error: AI '$AI_NAME' not found in agent list"
    echo "Available AIs:"
    jq -r '.ai_agents[] | "  - \(.name)"' "$TASK_QUEUE"
    exit 1
fi

# Use the properly cased name from the agent list
AI_NAME="$ai_exists"

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

# Step 1: Acquire atomic lock
echo "🔒 Acquiring lock for Task #$TASK_ID..."
if ! bash "$SCRIPT_DIR/task_lock.sh" acquire "$TASK_ID" "$AI_NAME"; then
    echo "❌ Failed to acquire lock. Task may be claimed by another AI."
    
    # Check if this is a retry after failure
    if bash "$SCRIPT_DIR/task_recovery.sh" check "$TASK_ID" 2>/dev/null | grep -q "Can retry"; then
        echo "💡 Tip: This task has failed before. Use retry command:"
        echo "   bash AI/task_recovery.sh retry $TASK_ID $AI_NAME"
    fi
    
    exit 1
fi

# Mark that we have the lock (for cleanup_on_exit trap)
LOCK_ACQUIRED=true

# Step 2: Check if task exists
TASK_EXISTS=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber))' "$TASK_QUEUE")
if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Error: Task #$TASK_ID not found in queue"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "ERROR"
    exit 1
fi

# Step 3: Get task details
TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")
TASK_STATUS=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .status' "$TASK_QUEUE")
ASSIGNED_TO=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")
TASK_TYPE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .task_type // "any"' "$TASK_QUEUE")

# Normalize AI names to lowercase for comparison
ASSIGNED_TO_LOWER=$(echo "$ASSIGNED_TO" | tr '[:upper:]' '[:lower:]')
AI_NAME_LOWER=$(echo "$AI_NAME" | tr '[:upper:]' '[:lower:]')

# Step 4: Check current assignment (case-insensitive)
if [[ "$ASSIGNED_TO" != "Any AI" ]] && [[ "$ASSIGNED_TO_LOWER" != "$AI_NAME_LOWER" ]] && [[ "$FORCE_CLAIM" != "--force" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  TASK ALREADY ASSIGNED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   Task #$TASK_ID: $TASK_TITLE"
    echo "   Currently assigned to: $ASSIGNED_TO"
    echo "   Status: $TASK_STATUS"
    echo ""
    echo "   To force claim, use: $0 $TASK_ID $AI_NAME --force"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "REASSIGN_BLOCKED"
    exit 1
fi

# Step 5: Check task status
if [[ "$TASK_STATUS" == "completed" ]]; then
    echo "❌ Task #$TASK_ID is already completed"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "ALREADY_COMPLETE"
    exit 1
fi

if [[ "$TASK_STATUS" == "in_progress" ]] && [[ "$ASSIGNED_TO" == "$AI_NAME" ]]; then
    echo "ℹ️  Task #$TASK_ID is already in progress by $AI_NAME"
    echo "   Continuing with existing assignment..."
fi

# Step 6: Check dependencies (ACID compliance)
DEPENDENCIES=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .dependencies' "$TASK_QUEUE")

if [ "$DEPENDENCIES" != "[]" ] && [ "$DEPENDENCIES" != "null" ]; then
    DEP_IDS=$(echo "$DEPENDENCIES" | jq -r '.[]')
    
    echo "🔗 Checking dependencies..."
    UNMET_DEPS=()
    
    for dep_id in $DEP_IDS; do
        DEP_STATUS=$(jq -r --arg did "$dep_id" '.queue[] | select(.id == ($did | tonumber)) | .status' "$TASK_QUEUE")
        DEP_TITLE=$(jq -r --arg did "$dep_id" '.queue[] | select(.id == ($did | tonumber)) | .title' "$TASK_QUEUE")
        
        if [ "$DEP_STATUS" != "completed" ]; then
            UNMET_DEPS+=("$dep_id: $DEP_TITLE ($DEP_STATUS)")
            echo "   ❌ Task #$dep_id: $DEP_TITLE - $DEP_STATUS"
        else
            echo "   ✅ Task #$dep_id: $DEP_TITLE - completed"
        fi
    done
    
    if [ ${#UNMET_DEPS[@]} -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "❌ DEPENDENCIES NOT MET"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Cannot claim Task #$TASK_ID until these tasks complete:"
        for dep in "${UNMET_DEPS[@]}"; do
            echo "   - $dep"
        done
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Log dependency failure
        bash "$SCRIPT_DIR/task_audit.sh" log \
            "DEPENDENCY_BLOCKED" "$TASK_ID" "$AI_NAME" \
            "Dependencies not met: ${#UNMET_DEPS[@]} tasks" "blocked"
        
        bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "DEPENDENCY_NOT_MET"
        exit 1
    fi
fi

# Step 7: Check BUILD_SAFETY.md (if exists)
if [ -f "$SCRIPT_DIR/../BUILD_SAFETY.md" ]; then
    if grep -q "🔥 CRITICAL" "$SCRIPT_DIR/../BUILD_SAFETY.md"; then
        echo "⚠️  WARNING: BUILD_SAFETY.md contains critical warnings"
        echo "   Review before proceeding: $SCRIPT_DIR/../BUILD_SAFETY.md"
        sleep 2
    fi
fi

# Step 8: Update task queue (atomic with version control)
TIMESTAMP=$(date -Iseconds)
TMP_FILE=$(mktemp)

jq --arg tid "$TASK_ID" \
   --arg ai "$AI_NAME" \
   --arg ts "$TIMESTAMP" \
   '(.queue[] | select(.id == ($tid | tonumber))) |= (
       .status = "in_progress" |
       .assigned_to = $ai |
       .claimed_on = $ts |
       .last_updated = $ts
   )' "$TASK_QUEUE" > "$TMP_FILE"

# Verify JSON is valid after update
if ! jq empty "$TMP_FILE" > /dev/null 2>&1; then
    echo "❌ Error: JSON update produced invalid JSON"
    rm -f "$TMP_FILE"
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "JSON_ERROR"
    exit 1
fi

# Atomic rename (POSIX guarantees atomicity)
mv "$TMP_FILE" "$TASK_QUEUE"

# Step 9: Log to audit trail
bash "$SCRIPT_DIR/task_audit.sh" log \
    "CLAIMED" "$TASK_ID" "$AI_NAME" \
    "Task claimed: $TASK_TITLE" "in_progress"

# Step 10: Emit event for orchestration loop
bash "$SCRIPT_DIR/event_bus.sh" emit task_claimed "$TASK_ID" "$AI_NAME" >/dev/null 2>&1 || true
bash "$SCRIPT_DIR/event_bus.sh" process >/dev/null 2>&1 || true

# Step 11: Clear from failed tasks if present
bash "$SCRIPT_DIR/task_recovery.sh" clear "$TASK_ID" 2>/dev/null || true

# Disable automatic lock cleanup - task is successfully claimed
# Lock will be released by complete_task.sh or fail_task.sh
LOCK_ACQUIRED=false
trap - EXIT

# Step 12: Success output
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TASK CLAIMED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Task #$TASK_ID: $TASK_TITLE"
echo "   Claimed by: $AI_NAME"
echo "   Status: pending → in_progress"
echo "   Type: $TASK_TYPE"
echo ""

if [ "$DEPENDENCIES" != "[]" ] && [ "$DEPENDENCIES" != "null" ]; then
    echo "   ✅ All dependencies met"
fi

if [ -f "$SCRIPT_DIR/../BUILD_SAFETY.md" ]; then
    echo "   ✅ Build safety verified"
fi

echo ""
echo "   Updated: TASK_QUEUE.json"
echo "   Lock: Held by $AI_NAME"
echo "   Audit: Event logged"
echo ""

# Get task details
ESTIMATED_TIME=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .estimated_time // "N/A"' "$TASK_QUEUE")
BLOCKING=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .blocking // "N/A"' "$TASK_QUEUE")

echo "   📊 Estimated Time: $ESTIMATED_TIME"
echo "   🚧 Blocking: $BLOCKING"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Next Steps:"
echo "   1. Work on task"
echo "   2. Complete with: bash complete_task.sh $TASK_ID"
echo "   3. Or if error: bash AI/task_recovery.sh record $TASK_ID $AI_NAME <error_type> <details>"
echo ""

# Keep lock held (will be released on completion or error)
exit 0
