#!/bin/bash
# USER APPROVAL RESPONSE HANDLER
# Processes user decisions on AI-generated work

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
USER_APPROVAL_DIR="$SCRIPT_DIR/user_approvals"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TASK_ID="$1"
DECISION="$2"
FEEDBACK="${@:3}"

if [ -z "$TASK_ID" ] || [ -z "$DECISION" ]; then
    echo "Usage: $0 <task_id> <decision> [feedback]"
    echo ""
    echo "Decisions:"
    echo "  a, approve  - Approve and complete task"
    echo "  i, iterate  - Request changes (provide feedback)"
    echo "  s, skip     - Skip for now, will ask again later"
    echo "  r, reject   - Reject and reset to pending"
    echo ""
    echo "Examples:"
    echo "  $0 21 approve"
    echo "  $0 21 iterate 'Make the atom icon more circular'"
    echo "  $0 21 skip"
    exit 1
fi

# Find latest approval request
APPROVAL_FILE=$(ls -t "$USER_APPROVAL_DIR/task_${TASK_ID}_iter_"*.json 2>/dev/null | head -1)

if [ -z "$APPROVAL_FILE" ]; then
    echo "Error: No approval request found for Task #$TASK_ID"
    exit 1
fi

# Get details
TASK_TITLE=$(jq -r '.title' "$APPROVAL_FILE")
ITERATION=$(jq -r '.iteration' "$APPROVAL_FILE")
AI_NAME=$(jq -r --arg id "$TASK_ID" '.queue[] | select(.id == ($id | tonumber)) | .assigned_to' "$TASK_QUEUE")

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Processing your response for Task #$TASK_ID${NC}"
echo -e "${BLUE}$TASK_TITLE${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

case "$DECISION" in
    a|approve)
        echo -e "${GREEN}✓ Task approved!${NC}"
        
        # Mark task as completed
        bash "$SCRIPT_DIR/complete_task_v2.sh" "$TASK_ID" "$AI_NAME"
        
        # Update approval record
        jq '.status = "approved"' "$APPROVAL_FILE" > "${APPROVAL_FILE}.tmp" && mv "${APPROVAL_FILE}.tmp" "$APPROVAL_FILE"
        
        echo -e "${GREEN}Task #$TASK_ID marked as complete${NC}"
        ;;
        
    i|iterate)
        echo -e "${YELLOW}🔄 Requesting iteration with feedback${NC}"
        
        if [ -z "$FEEDBACK" ]; then
            echo -e "${YELLOW}Please provide feedback:${NC}"
            read -p "> " FEEDBACK
        fi
        
        # Save feedback
        local NEW_ITERATION=$((ITERATION + 1))
        jq --arg feedback "$FEEDBACK" \
           '.status = "iteration_requested" | .user_feedback = $feedback' \
           "$APPROVAL_FILE" > "${APPROVAL_FILE}.tmp" && mv "${APPROVAL_FILE}.tmp" "$APPROVAL_FILE"
        
        echo ""
        echo -e "${BLUE}Feedback saved:${NC} $FEEDBACK"
        echo -e "${YELLOW}AI will revise and present iteration #$NEW_ITERATION${NC}"
        echo ""
        echo "To retry with feedback:"
        echo "  bash autonomy_executor.sh $AI_NAME single $TASK_ID"
        ;;
        
    s|skip)
        echo -e "${YELLOW}⏭️  Skipped for now${NC}"
        
        jq '.status = "skipped"' "$APPROVAL_FILE" > "${APPROVAL_FILE}.tmp" && mv "${APPROVAL_FILE}.tmp" "$APPROVAL_FILE"
        
        echo "Task will remain in queue for later review"
        ;;
        
    r|reject)
        echo -e "${RED}✗ Task rejected${NC}"
        
        # Reset task to pending
        TMP_FILE=$(mktemp)
        jq --arg id "$TASK_ID" \
           '(.queue[] | select(.id == ($id | tonumber)) | .status) = "pending"' \
           "$TASK_QUEUE" > "$TMP_FILE" && mv "$TMP_FILE" "$TASK_QUEUE"
        
        # Release lock
        bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" 2>/dev/null || true
        
        # Update approval record
        jq '.status = "rejected"' "$APPROVAL_FILE" > "${APPROVAL_FILE}.tmp" && mv "${APPROVAL_FILE}.tmp" "$APPROVAL_FILE"
        
        echo "Task reset to pending for different approach"
        ;;
        
    *)
        echo "Unknown decision: $DECISION"
        echo "Use: approve, iterate, skip, or reject"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
