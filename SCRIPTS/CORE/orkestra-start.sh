#!/bin/bash
# OrKeStra Startup - Get the AI system working

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════"
echo "  OrKeStra AI System - Startup & Health Check"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 1: Clean any stale locks
echo "1. Cleaning stale locks..."
for lock_dir in "$SCRIPT_DIR/locks"/task_*.lock; do
    if [ -d "$lock_dir" ]; then
        task_num=$(basename "$lock_dir" | sed 's/task_//' | sed 's/.lock//')
        bash "$SCRIPT_DIR/task_lock.sh" release "$task_num" 2>/dev/null || true
    fi
done
echo "   ✓ Locks cleared"
echo ""

# Step 2: Check API keys
echo "2. Checking API keys..."
api_count=0

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    echo "   ✓ Claude (Anthropic) API key set"
    ((api_count++))
else
    echo "   ✗ Claude API key missing"
fi

if [ -n "${OPENAI_API_KEY:-}" ]; then
    echo "   ✓ ChatGPT (OpenAI) API key set"
    ((api_count++))
else
    echo "   ✗ ChatGPT API key missing"
fi

if [ -n "${GEMINI_API_KEY:-}" ]; then
    echo "   ✓ Gemini API key set"
    ((api_count++))
else
    echo "   ✗ Gemini API key missing"
fi

echo "   → $api_count/3 external AI APIs configured"
echo ""

# Step 3: Verify CLIs exist
echo "3. Checking AI CLIs..."
if [ -f "$SCRIPT_DIR/claude_cli.py" ]; then
    echo "   ✓ Claude CLI exists"
fi
if [ -f "$SCRIPT_DIR/gemini-cli/bundle/gemini.js" ]; then
    echo "   ✓ Gemini CLI exists"
fi
echo ""

# Step 4: Check task queue
echo "4. Task Queue Status..."
pending=$(jq -r '.queue[] | select(.status == "pending") | .id' "$SCRIPT_DIR/TASK_QUEUE.json" 2>/dev/null | wc -l)
in_progress=$(jq -r '.queue[] | select(.status == "in_progress") | .id' "$SCRIPT_DIR/TASK_QUEUE.json" 2>/dev/null | wc -l)
completed=$(jq -r '.queue[] | select(.status == "completed") | .id' "$SCRIPT_DIR/TASK_QUEUE.json" 2>/dev/null | wc -l)

echo "   Pending: $pending"
echo "   In Progress: $in_progress"
echo "   Completed: $completed"
echo ""

# Step 5: Show recommendations
echo "5. Task Recommendations (What should run next)..."
bash "$SCRIPT_DIR/smart_task_selector.sh" recommend 2>/dev/null | grep -A 1 "\[" | head -15
echo ""

# Step 6: Check for notes
echo "6. Unread AI Notes..."
for ai in copilot claude chatgpt gemini grok; do
    unread=$(bash "$SCRIPT_DIR/ai_notes.sh" count "$ai" 2>/dev/null | grep "Unread notes" | grep -o '[0-9]*' | head -1)
    if [ "$unread" -gt 0 ] 2>/dev/null; then
        echo "   $ai: $unread unread notes"
    fi
done
echo ""

# Step 7: Show next actions
echo "═══════════════════════════════════════════════════"
echo "  READY TO RUN"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Quick Start Options:"
echo ""
echo "1. Run Copilot (me) on recommended task:"
echo "   → I can execute tasks directly in VS Code"
echo "   → Just ask me: 'Execute task 17'"
echo ""
echo "2. Run automated executor for specific AI:"
echo "   bash gemini_auto_executor.sh once"
echo "   bash claude_auto_executor.sh once"
echo "   bash chatgpt_auto_executor.sh once"
echo ""
echo "3. View detailed task info:"
echo "   bash ai_notes.sh task <task_id>"
echo "   jq '.queue[] | select(.id == 17)' TASK_QUEUE.json"
echo ""
echo "4. Manual task claiming:"
echo "   bash claim_task.sh <task_id>  # Auto-selects best AI"
echo "   bash claim_task.sh <task_id> <ai_name>"
echo ""
echo "5. Check system status:"
echo "   bash task_coordinator.sh dashboard"
echo ""
