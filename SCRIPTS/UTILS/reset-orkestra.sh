#!/bin/bash
# OrKeStra Reset Script
# Clears all tasks, locks, and status to start fresh

WORKSPACE_ROOT="/workspaces/The-Quantum-Self-"
AI_DIR="$WORKSPACE_ROOT/AI"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 ORKESTRA RESET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Backup current state
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$WORKSPACE_ROOT/orkestra_backup_$TIMESTAMP"

echo "📦 Creating backup: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup task queue
if [ -f "$WORKSPACE_ROOT/TASK_QUEUE.json" ]; then
    cp "$WORKSPACE_ROOT/TASK_QUEUE.json" "$BACKUP_DIR/"
    echo "   ✅ Backed up TASK_QUEUE.json"
fi

# Backup AI status files
for ai in CLAUDE CHATGPT GEMINI GROK COPILOT ORKESTRA; do
    if [ -f "$WORKSPACE_ROOT/${ai}_STATUS.md" ]; then
        cp "$WORKSPACE_ROOT/${ai}_STATUS.md" "$BACKUP_DIR/"
        echo "   ✅ Backed up ${ai}_STATUS.md"
    fi
done

# Backup locks
if [ -d "$AI_DIR/locks" ]; then
    cp -r "$AI_DIR/locks" "$BACKUP_DIR/" 2>/dev/null
    echo "   ✅ Backed up locks/"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Clearing OrKeStra State"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clear task queue
echo "📋 Clearing task queue..."
cat > "$WORKSPACE_ROOT/TASK_QUEUE.json" << 'EOF'
{
  "meta": {
    "last_updated": "TIMESTAMP_PLACEHOLDER",
    "status": "EMPTY"
  },
  "queue": []
}
EOF
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$WORKSPACE_ROOT/TASK_QUEUE.json"
echo "   ✅ Task queue cleared"

# Clear locks
if [ -d "$AI_DIR/locks" ]; then
    rm -f "$AI_DIR/locks"/*.lock 2>/dev/null
    echo "   ✅ Cleared task locks"
fi

# Clear events
if [ -d "$AI_DIR/events" ]; then
    rm -f "$AI_DIR/events"/*.event 2>/dev/null
    echo "   ✅ Cleared events"
fi

# Clear commands
if [ -d "$AI_DIR/commands" ]; then
    rm -f "$AI_DIR/commands"/*.cmd 2>/dev/null
    echo "   ✅ Cleared commands"
fi

# Reset AI status files (preserve notes and context)
echo ""
echo "🤖 Resetting AI status files (preserving AI notes/context)..."

reset_ai_status() {
    local ai_name=$1
    local status_file="$WORKSPACE_ROOT/${ai_name}_STATUS.md"
    
    # Extract existing notes/context sections if they exist
    local notes_section=""
    local context_section=""
    local capabilities_section=""
    
    if [ -f "$status_file" ]; then
        # Try to preserve AI Notes, Context, and Capabilities sections
        notes_section=$(sed -n '/## AI Notes/,/^## /p' "$status_file" | sed '$d' 2>/dev/null)
        context_section=$(sed -n '/## Shared Context/,/^## /p' "$status_file" | sed '$d' 2>/dev/null)
        capabilities_section=$(sed -n '/## Capabilities/,/^## /p' "$status_file" | sed '$d' 2>/dev/null)
        
        # If no specific sections found, preserve everything after "Capabilities"
        if [ -z "$capabilities_section" ]; then
            capabilities_section=$(sed -n '/## Capabilities/,$p' "$status_file" 2>/dev/null)
        fi
    fi
    
    # Create new status file with preserved sections
    cat > "$status_file" << EOF
# $ai_name Status

**Last Updated:** $(date -u +"%Y-%m-%d %H:%M:%S (UTC)")
**Current Task:** None
**Status:** 🟢 READY

---

## Recent Activity

*System reset - awaiting new task assignment*

---

EOF

    # Append preserved sections
    if [ -n "$capabilities_section" ]; then
        echo "$capabilities_section" >> "$status_file"
    else
        echo "## Capabilities" >> "$status_file"
        echo "" >> "$status_file"
        echo "Ready to receive tasks from OrKeStra." >> "$status_file"
    fi
    
    if [ -n "$notes_section" ]; then
        echo "" >> "$status_file"
        echo "$notes_section" >> "$status_file"
    fi
    
    if [ -n "$context_section" ]; then
        echo "" >> "$status_file"
        echo "$context_section" >> "$status_file"
    fi
    
    echo "   ✅ Reset ${ai_name}_STATUS.md (preserved context/notes)"
}

reset_ai_status "CLAUDE"
reset_ai_status "CHATGPT"
reset_ai_status "GEMINI"
reset_ai_status "GROK"
reset_ai_status "COPILOT"
reset_ai_status "ORKESTRA"

# Clear current task
echo ""
echo "📝 Clearing current task..."
cat > "$WORKSPACE_ROOT/CURRENT_TASK.md" << 'EOF'
# Current Task

**Status:** No active task
**Last Updated:** TIMESTAMP_PLACEHOLDER

---

## Awaiting Task Assignment

No tasks currently in queue.

Use OrKeStra to assign new tasks.

EOF
sed -i "s/TIMESTAMP_PLACEHOLDER/$(date -u +"%Y-%m-%d %H:%M:%S (UTC)")/" "$WORKSPACE_ROOT/CURRENT_TASK.md"
echo "   ✅ Cleared CURRENT_TASK.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ORKESTRA RESET COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Backup saved to: $BACKUP_DIR"
echo ""
echo "🎯 OrKeStra is now in a clean state:"
echo "   - Task queue: Empty"
echo "   - All locks: Cleared"
echo "   - AI status: Reset to READY"
echo "   - Events/commands: Cleared"
echo ""
echo "Ready to accept new tasks!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
