#!/bin/bash
# Automatically update collaboration logs when tasks complete

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="/workspaces/The-Quantum-Self-/222_AI_COLLABORATION_CONVERSATION.txt"

COPILOT_DONE=$(grep "Ready for handoff: YES" "$SCRIPT_DIR/COPILOT_STATUS.md" 2>/dev/null)
CLAUDE_DONE=$(grep "Ready for handoff: YES" "$SCRIPT_DIR/CLAUDE_STATUS.md" 2>/dev/null)
CHATGPT_DONE=$(grep "Ready for handoff: YES" "$SCRIPT_DIR/CHATGPT_STATUS.md" 2>/dev/null)

if [ -n "$COPILOT_DONE" ]; then
    echo "Copilot completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    # Extract task details and append to log
    TASK=$(grep "Current Task:" "$SCRIPT_DIR/COPILOT_STATUS.md" | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] GitHub Copilot completed: $TASK" >> "$LOG_FILE"
fi

if [ -n "$CLAUDE_DONE" ]; then
    echo "Claude completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    TASK=$(grep "Current Task:" "$SCRIPT_DIR/CLAUDE_STATUS.md" | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] Claude completed: $TASK" >> "$LOG_FILE"
fi

if [ -n "$CHATGPT_DONE" ]; then
    echo "ChatGPT completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    TASK=$(grep "Current Task:" "$SCRIPT_DIR/CHATGPT_STATUS.md" | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] ChatGPT completed: $TASK" >> "$LOG_FILE"
fi
