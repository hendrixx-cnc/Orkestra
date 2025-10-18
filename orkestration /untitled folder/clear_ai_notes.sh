#!/bin/bash
# Clear AI Notes and Context
# Removes all shared notes and context from AI status files

WORKSPACE_ROOT="/workspaces/The-Quantum-Self-"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 CLEAR AI NOTES & CONTEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

clear_ai_notes() {
    local ai_name=$1
    local status_file="$WORKSPACE_ROOT/${ai_name}_STATUS.md"
    
    if [ ! -f "$status_file" ]; then
        echo "   ⚠️  ${ai_name}_STATUS.md not found"
        return
    fi
    
    # Extract everything up to (but not including) "## AI Notes" or "## Shared Context"
    local main_content=$(sed '/## AI Notes/,$d; /## Shared Context/,$d' "$status_file")
    
    # Rewrite file with just the main content
    echo "$main_content" > "$status_file"
    
    echo "   ✅ Cleared notes/context from ${ai_name}_STATUS.md"
}

echo "Clearing AI notes and shared context..."
echo ""

clear_ai_notes "CLAUDE"
clear_ai_notes "CHATGPT"
clear_ai_notes "GEMINI"
clear_ai_notes "GROK"
clear_ai_notes "COPILOT"
clear_ai_notes "ORKESTRA"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All AI notes and context cleared"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
