#!/bin/bash
# Claim Task Script
# Updates TASK_QUEUE.json when an AI claims a task
# Checks dependencies to prevent breaking the build

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Ensure task queue file exists
if [ ! -f "$TASK_QUEUE" ]; then
    echo "❌ Error: TASK_QUEUE.json not found at $TASK_QUEUE"
    exit 1
fi

# Usage check
if [ $# -lt 1 ]; then
    echo "Usage: $0 <task_id> [ai_name]"
    echo "Example: $0 6 ChatGPT"
    echo "         $0 6          (auto-selects best AI)"
    echo ""
    echo "If no AI specified, the smart selector chooses the best AI based on:"
    echo "  - AI specialties matching task requirements"
    echo "  - Current workload of each AI"
    exit 1
fi

TASK_ID=$1
AI_NAME=$2

# If no AI specified, use smart selector
if [ -z "$AI_NAME" ]; then
    SMART_SELECTOR="$SCRIPT_DIR/smart_task_selector.sh"
    if [ -f "$SMART_SELECTOR" ]; then
        AI_NAME=$(bash "$SMART_SELECTOR" select "$TASK_ID")
        echo "Auto-selected best AI: $AI_NAME"
    else
        echo "Error: No AI specified and smart selector not found"
        exit 1
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
    echo "⚠️  jq not installed. Manual update required."
    echo "   Update TASK_QUEUE.json manually:"
    echo "   - Find task id $TASK_ID"
    echo "   - Check dependencies are completed first"
    echo "   - Change 'status' to 'in_progress'"
    echo "   - Change 'assigned_to' to '$AI_NAME'"
    exit 1
fi

# Validate TASK_QUEUE.json contents before operating on it
if ! jq empty "$TASK_QUEUE" > /dev/null 2>&1; then
    echo "❌ Error: TASK_QUEUE.json contains invalid JSON. Please fix the file before claiming tasks."
    exit 1
fi

# Check if task exists
TASK_EXISTS=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber))' "$TASK_QUEUE")
if [ -z "$TASK_EXISTS" ]; then
    echo "❌ Error: Task #$TASK_ID not found in queue"
    exit 1
fi

# Get task details
TASK_TITLE=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .title' "$TASK_QUEUE")
TASK_STATUS=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .status' "$TASK_QUEUE")
ASSIGNED_TO=$(jq -r --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .assigned_to' "$TASK_QUEUE")

# Check if already assigned to someone else
if [[ "$ASSIGNED_TO" != "Any AI" ]] && [[ "$ASSIGNED_TO" != "$AI_NAME" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  TASK ALREADY ASSIGNED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   Task #$TASK_ID: $TASK_TITLE"
    echo "   Currently assigned to: $ASSIGNED_TO"
    echo "   Status: $TASK_STATUS"
    echo ""
    echo "   Cannot claim. Choose a different task."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# Check if task is already in progress or completed
if [[ "$TASK_STATUS" == "in_progress" ]] || [[ "$TASK_STATUS" == "completed" ]]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  TASK NOT AVAILABLE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   Task #$TASK_ID: $TASK_TITLE"
    echo "   Status: $TASK_STATUS"
    echo ""
    echo "   Cannot claim tasks that are already $TASK_STATUS."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
fi

# Get task dependencies
DEPENDENCIES=$(jq --arg tid "$TASK_ID" '.queue[] | select(.id == ($tid | tonumber)) | .dependencies' "$TASK_QUEUE")

# Check if dependencies are met
if [ "$DEPENDENCIES" != "[]" ] && [ "$DEPENDENCIES" != "null" ]; then
    # Get list of dependency IDs
    DEP_IDS=$(echo "$DEPENDENCIES" | jq -r '.[]')
    
    UNMET_DEPS=""
    for dep_id in $DEP_IDS; do
        DEP_STATUS=$(jq -r --arg did "$dep_id" '.queue[] | select(.id == ($did | tonumber)) | .status' "$TASK_QUEUE")
        DEP_TITLE=$(jq -r --arg did "$dep_id" '.queue[] | select(.id == ($did | tonumber)) | .title' "$TASK_QUEUE")
        
        if [ "$DEP_STATUS" != "completed" ]; then
            UNMET_DEPS="$UNMET_DEPS\n   • Task #$dep_id: $DEP_TITLE (status: $DEP_STATUS)"
        fi
    done
    
    if [ -n "$UNMET_DEPS" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "❌ DEPENDENCIES NOT MET"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "   Task #$TASK_ID: $TASK_TITLE"
        echo ""
        echo "   This task depends on:"
        echo -e "$UNMET_DEPS"
        echo ""
        echo "   ⚠️  Cannot claim until dependencies are completed."
        echo "   This prevents breaking the build!"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        exit 1
    fi
fi

# All checks passed - claim the task
TMP_FILE=$(mktemp "${TASK_QUEUE}.XXXXXX") || {
    echo "❌ Error: Unable to create temporary file for TASK_QUEUE update."
    exit 1
}
trap 'rm -f "$TMP_FILE"' EXIT

if ! jq --arg tid "$TASK_ID" --arg ai "$AI_NAME" '
    .queue |= map(
        if (.id | tostring) == $tid then
            .assigned_to = $ai |
            .status = "in_progress" |
            .claimed_on = (now | strftime("%Y-%m-%d %H:%M"))
        else
            .
        end
    )
' "$TASK_QUEUE" > "$TMP_FILE"; then
    echo "❌ Error: Failed to update TASK_QUEUE.json."
    exit 1
fi

if ! mv "$TMP_FILE" "$TASK_QUEUE"; then
    echo "❌ Error: Unable to replace TASK_QUEUE.json."
    exit 1
fi
trap - EXIT

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TASK CLAIMED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   Task #$TASK_ID: $TASK_TITLE"
echo "   Claimed by: $AI_NAME"
echo "   Status: pending → in_progress"
echo ""
echo "   ✅ All dependencies met"
echo "   ✅ Build safety verified"
echo ""
echo "   Updated: TASK_QUEUE.json"
echo "   Next: Check CURRENT_TASK.md and execute!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
