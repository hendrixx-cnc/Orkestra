#!/bin/bash
# Complete Task Script
# Updates TASK_QUEUE.json when an AI completes a task

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Usage check
if [ $# -ne 1 ]; then
    echo "Usage: $0 <task_id>"
    echo "Example: $0 6"
    exit 1
fi

TASK_ID=$1

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not installed. Manual update required."
    echo "   Update TASK_QUEUE.json manually:"
    echo "   - Find task id $TASK_ID"
    echo "   - Change 'status' to 'completed'"
    exit 1
fi

# Get task title before update
TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")

# Update TASK_QUEUE.json
jq --arg tid "$TASK_ID" '
    .queue |= map(
        if (.id | tostring) == $tid then
            .status = "completed" |
            .completed_on = (now | strftime("%Y-%m-%d %H:%M"))
        else
            .
        end
    )
' "$TASK_QUEUE" > "$TASK_QUEUE.tmp" && mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"

# Auto-release lock (if task_lock.sh exists)
if [ -f "$SCRIPT_DIR/task_lock.sh" ]; then
    bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "COMPLETED" 2>/dev/null || true
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TASK COMPLETED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Task #$TASK_ID: $TASK_TITLE"
echo "   Status: in_progress → completed"
echo "   Lock: Released automatically"
echo ""
echo "   Updated: TASK_QUEUE.json"
echo ""
echo "   Next: Run ai_coordinator.sh to see what's next!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
