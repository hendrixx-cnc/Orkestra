#!/bin/bash
# AI Task Coordinator
# Checks CURRENT_TASK.md and tells Todd who should work next

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ASSIGNED_TO=$(grep "Assigned To:" "$SCRIPT_DIR/CURRENT_TASK.md" 2>/dev/null | head -1 | cut -d: -f2- | sed 's/\*\*//g' | xargs)
STATUS=$(grep "Status:" "$SCRIPT_DIR/CURRENT_TASK.md" 2>/dev/null | head -1 | cut -d: -f2 | sed 's/\*\*//g' | xargs)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI TASK COORDINATOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$STATUS" == *"IN PROGRESS"* ]]; then
    if [[ "$ASSIGNED_TO" == *"Any AI"* ]] || [[ "$ASSIGNED_TO" == *"any ai"* ]]; then
        echo "🎯 FLEXIBLE ASSIGNMENT: Any available AI can work on this!"
        echo ""
        echo "   Choose based on availability and task type:"
        echo "   • Copilot (technical tasks, implementation)"
        echo "   • Claude (content review, refinement)"
        echo "   • ChatGPT (creative writing, content creation)"
        echo ""
        echo "   Tell your chosen AI:"
        echo "   'Check CURRENT_TASK.md and execute'"
    elif [[ "$ASSIGNED_TO" == "COPILOT" ]] || [[ "$ASSIGNED_TO" == "Copilot" ]]; then
        echo "✅ ACTION: Tell GitHub Copilot:"
        echo "   'Check CURRENT_TASK.md and execute'"
    elif [[ "$ASSIGNED_TO" == "CLAUDE" ]] || [[ "$ASSIGNED_TO" == "Claude" ]]; then
        echo "✅ ACTION: Tell Claude:"
        echo "   'Check CURRENT_TASK.md and execute'"
    elif [[ "$ASSIGNED_TO" == "CHATGPT" ]] || [[ "$ASSIGNED_TO" == "ChatGPT" ]]; then
        echo "✅ ACTION: Tell ChatGPT:"
        echo "   'Check CURRENT_TASK.md and execute'"
    fi
elif [[ "$STATUS" == *"COMPLETE"* ]]; then
    echo "✅ Task complete! Checking for next task..."
    # Check if there's a next task in queue
    echo "⏭️  Move to next task in TASK_QUEUE.json"
else
    echo "⏸️  No active task. Review TASK_QUEUE.json"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
