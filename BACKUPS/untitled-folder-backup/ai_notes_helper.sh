#!/bin/bash
# AI Notes Integration Helper
# Source this file in agent scripts to add automatic note checking

NOTES_SCRIPT="${SCRIPT_DIR:-/workspaces/The-Quantum-Self-/AI}/ai_notes.sh"

# Function: Check and display notes for an AI at startup
check_ai_notes() {
    local ai_name="$1"
    
    if [ ! -f "$NOTES_SCRIPT" ]; then
        return 0  # Notes system not available
    fi
    
    # Count unread notes
    local unread=$(bash "$NOTES_SCRIPT" count "$ai_name" 2>/dev/null | grep "Unread notes" | grep -o '[0-9]*' | head -1)
    
    if [ -z "$unread" ] || [ "$unread" = "0" ]; then
        return 0  # No unread notes
    fi
    
    echo ""
    echo "════════════════════════════════════════════════"
    echo "📬 You have $unread unread note(s)"
    echo "════════════════════════════════════════════════"
    bash "$NOTES_SCRIPT" read "$ai_name" 2>/dev/null || true
    echo "════════════════════════════════════════════════"
    echo ""
    
    # Mark as read
    bash "$NOTES_SCRIPT" mark-read "$ai_name" 2>/dev/null || true
}

# Function: Show task-specific notes when claiming a task
show_task_notes() {
    local task_id="$1"
    
    if [ ! -f "$NOTES_SCRIPT" ]; then
        return 0
    fi
    
    local notes=$(bash "$NOTES_SCRIPT" task "$task_id" 2>/dev/null)
    
    if echo "$notes" | grep -q "No notes for this task"; then
        return 0
    fi
    
    echo ""
    echo "════════════════════════════════════════════════"
    echo "📝 Notes for Task #$task_id:"
    echo "════════════════════════════════════════════════"
    bash "$NOTES_SCRIPT" task "$task_id" 2>/dev/null || true
    echo "════════════════════════════════════════════════"
    echo ""
}

# Function: Prompt for handoff note when completing task
prompt_handoff_note() {
    local ai_name="$1"
    local task_id="$2"
    
    if [ ! -f "$NOTES_SCRIPT" ]; then
        return 0
    fi
    
    echo ""
    echo "Task completed! Would you like to leave a handoff note? (y/N)"
    read -t 10 -r response || response="n"
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Enter note for next AI (or press Enter to skip):"
        read -r note_message
        
        if [ -n "$note_message" ]; then
            echo "Send to specific AI? (claude/chatgpt/gemini/grok/all) [all]:"
            read -r to_ai
            to_ai=${to_ai:-all}
            
            bash "$NOTES_SCRIPT" add "$ai_name" handoff "$note_message" "$task_id" "$to_ai"
            echo "Handoff note added"
        fi
    fi
}

# Function: Quick add note (for use in scripts)
add_note_quick() {
    local from_ai="$1"
    local type="$2"
    local message="$3"
    local task_id="${4:-}"
    local to_ai="${5:-all}"
    
    if [ ! -f "$NOTES_SCRIPT" ]; then
        return 0
    fi
    
    bash "$NOTES_SCRIPT" add "$from_ai" "$type" "$message" "$task_id" "$to_ai" 2>/dev/null || true
}

# Export functions for use in other scripts
export -f check_ai_notes
export -f show_task_notes
export -f prompt_handoff_note
export -f add_note_quick
