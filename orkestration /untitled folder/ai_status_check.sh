#!/bin/bash
# Quick status check for all three AIs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI COLLABORATION STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 GITHUB COPILOT:"
if [ -f "$SCRIPT_DIR/COPILOT_STATUS.md" ]; then
    grep "Status:" "$SCRIPT_DIR/COPILOT_STATUS.md" 2>/dev/null | head -1
    grep "Current Task:" "$SCRIPT_DIR/COPILOT_STATUS.md" 2>/dev/null | head -1
    grep "Ready for handoff:" "$SCRIPT_DIR/COPILOT_STATUS.md" 2>/dev/null | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "📊 CLAUDE:"
if [ -f "$SCRIPT_DIR/CLAUDE_STATUS.md" ]; then
    grep "Status:" "$SCRIPT_DIR/CLAUDE_STATUS.md" 2>/dev/null | head -1
    grep "Current Task:" "$SCRIPT_DIR/CLAUDE_STATUS.md" 2>/dev/null | head -1
    grep "Ready for handoff:" "$SCRIPT_DIR/CLAUDE_STATUS.md" 2>/dev/null | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "📊 CHATGPT:"
if [ -f "$SCRIPT_DIR/CHATGPT_STATUS.md" ]; then
    grep "Status:" "$SCRIPT_DIR/CHATGPT_STATUS.md" 2>/dev/null | head -1
    grep "Current Task:" "$SCRIPT_DIR/CHATGPT_STATUS.md" 2>/dev/null | head -1
    grep "Ready for handoff:" "$SCRIPT_DIR/CHATGPT_STATUS.md" 2>/dev/null | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
