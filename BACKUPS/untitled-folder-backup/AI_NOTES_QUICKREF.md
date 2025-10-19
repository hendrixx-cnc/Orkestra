# AI Notes Quick Reference

## Common Commands

### Leave Notes
```bash
# Task-specific note
bash ai_notes.sh add <from_ai> task "<message>" <task_id> <to_ai>
bash ai_notes.sh add claude task "Edge case: null users" 16 gemini

# Handoff note (when completing)
bash ai_notes.sh add <from_ai> handoff "<message>" <task_id> <to_ai>
bash ai_notes.sh add gemini handoff "Schema done, run migrations" 16 claude

# Broadcast to all
bash ai_notes.sh add <from_ai> general "<message>" all
bash ai_notes.sh add chatgpt general "New guidelines in BRANDING.md" all
```

### Read Notes
```bash
# Read all your notes
bash ai_notes.sh read <ai_name>
bash ai_notes.sh read gemini

# Read specific type
bash ai_notes.sh read gemini task
bash ai_notes.sh read gemini handoff

# Check notes for a task
bash ai_notes.sh task 16

# Count unread
bash ai_notes.sh count gemini
```

### Mark as Read
```bash
bash ai_notes.sh mark-read <ai_name>
bash ai_notes.sh mark-read gemini
```

## Use Cases

### Before Starting Task
```bash
# 1. Check your notes
bash ai_notes.sh read claude

# 2. Check task-specific notes
bash ai_notes.sh task 16

# 3. Mark as read
bash ai_notes.sh mark-read claude
```

### After Completing Task
```bash
# Leave handoff note
bash ai_notes.sh add claude handoff "Testing complete, found 2 bugs in BUGS.md" 16 gemini
```

### Found Something Important
```bash
# Warn specific AI about related task
bash ai_notes.sh add gemini task "Database requires PostgreSQL 16+" 20 claude

# Broadcast to everyone
bash ai_notes.sh add gemini general "Switched to new API endpoint /v2" all
```

## Integration with Workflow

```bash
# Standard task workflow with notes
bash claim_task.sh 16                    # Claim task
bash ai_notes.sh task 16                 # Check task notes
bash ai_notes.sh read gemini             # Check your notes
# ... do work ...
bash ai_notes.sh add gemini handoff "..." 16 claude  # Leave handoff
bash complete_task.sh 16                 # Complete
```

## Note Types

**Task** - About specific task, visible when someone works on it
**Handoff** - When completing, info for next AI
**General** - Broadcast or direct message to AI(s)

## Files

- `AI_NOTES.json` - Storage
- `ai_notes.sh` - Main script
- `AI_NOTES_GUIDE.md` - Full documentation
- `ai_notes_helper.sh` - Integration functions
