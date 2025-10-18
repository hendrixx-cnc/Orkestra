# AI Notes System - Inter-AI Communication

## Overview

The AI Notes system allows AIs to leave messages for each other about tasks, important considerations, special situations, and handoffs. This ensures continuity when multiple AIs work on related tasks.

## Why This Matters

When AIs pull tasks from a shared queue:
- **Context preservation** - AI finishing Task A can warn AI starting Task B
- **Special considerations** - "Watch out for edge case X"
- **Important discoveries** - "Found a bug in Y while working on Z"
- **Handoff clarity** - "Completed migration, schema updated, needs testing"

## Note Types

### 1. Task Notes
Notes about specific tasks, visible to whoever works on that task.

```bash
# Claude warns about Task 16
bash ai_notes.sh add claude task "Edge case: null users break validation" 16 gemini

# Read task notes when claiming
bash ai_notes.sh task 16
```

### 2. Handoff Notes
When completing a task, leave notes for the next AI or for related tasks.

```bash
# Gemini hands off completed work
bash ai_notes.sh add gemini handoff "Database schema complete, run migrations before testing" 16 claude
```

### 3. General Notes
Broadcast messages to all AIs or specific AI.

```bash
# ChatGPT announces update
bash ai_notes.sh add chatgpt general "Updated brand guidelines in BRANDING.md" all

# Claude tells Gemini about system change
bash ai_notes.sh add claude general "Switched to PostgreSQL 16" gemini
```

## Usage

### Adding Notes

```bash
# Syntax
bash ai_notes.sh add <from_ai> <type> <message> [task_id] [to_ai]

# Examples
bash ai_notes.sh add claude task "Watch for race condition in line 45" 16 gemini
bash ai_notes.sh add gemini handoff "Ready for frontend integration" 16 claude
bash ai_notes.sh add chatgpt general "New copy guidelines" all
```

### Reading Notes

```bash
# Read all notes for an AI
bash ai_notes.sh read gemini

# Read specific type
bash ai_notes.sh read gemini task
bash ai_notes.sh read gemini handoff
bash ai_notes.sh read gemini general

# Get all notes for a specific task
bash ai_notes.sh task 16
```

### Checking Unread Count

```bash
bash ai_notes.sh count gemini

Output:
Unread notes for gemini: 5
  Task notes: 2
  Handoff notes: 2
  General notes: 1
```

### Marking as Read

```bash
# Mark all notes as read
bash ai_notes.sh mark-read gemini

# Mark specific type as read
bash ai_notes.sh mark-read gemini task
```

### Admin Commands

```bash
# List all notes (admin view)
bash ai_notes.sh list

# Clean old read notes (default: 7 days)
bash ai_notes.sh clean
bash ai_notes.sh clean 30  # Keep 30 days
```

## Integration with Task Workflow

### When Claiming a Task

```bash
# 1. Claim task
bash claim_task.sh 16

# 2. Check for notes about this task
bash ai_notes.sh task 16

# 3. Read your pending notes
bash ai_notes.sh read gemini

# 4. Mark as read
bash ai_notes.sh mark-read gemini
```

### When Completing a Task

```bash
# 1. Leave handoff note for next AI
bash ai_notes.sh add gemini handoff "Schema migrated, updated docs in SCHEMA.md" 16 claude

# 2. Complete task
bash complete_task.sh 16
```

### When Discovering Issues

```bash
# Leave note about related task
bash ai_notes.sh add claude task "Found bug: user auth fails if email has +" 20 gemini

# Leave general warning
bash ai_notes.sh add claude general "Don't use console.log in production files" all
```

## Automated Integration

### In Agent Scripts

Add note checking to agent executors:

```bash
# At start of gemini_agent.sh execution
echo "Checking for notes..."
bash "$SCRIPT_DIR/ai_notes.sh" count gemini

unread=$(bash "$SCRIPT_DIR/ai_notes.sh" count gemini | grep "Unread notes" | cut -d: -f2 | tr -d ' ')

if [ "$unread" -gt 0 ]; then
    echo "You have $unread unread notes:"
    bash "$SCRIPT_DIR/ai_notes.sh" read gemini
    echo ""
    read -p "Press Enter to continue..."
fi
```

### In Task Claiming

Modify claim scripts to show task notes automatically:

```bash
# In claim_task.sh after claiming
if [ $? -eq 0 ]; then
    echo "Task claimed successfully"
    echo ""
    echo "Notes for this task:"
    bash "$SCRIPT_DIR/ai_notes.sh" task "$TASK_ID"
fi
```

## Example Workflow

**Scenario:** Gemini completes database task, Claude needs to test

```bash
# Gemini finishes Task 16 (database schema)
bash ai_notes.sh add gemini handoff "Schema ready. Run 'npm run migrate' before testing. Updated docs in DB_SCHEMA.md. Watch for foreign key constraints on users table." 16 claude

bash ai_notes.sh add gemini task "Remember to test with null user IDs" 17 claude

bash complete_task.sh 16

# Claude starts Task 17 (testing)
bash claim_task.sh 17

# Claude checks notes
bash ai_notes.sh read claude

Output:
Notes for claude:
====================

TASK-SPECIFIC NOTES:
  Task #17 from gemini: Remember to test with null user IDs

HANDOFF NOTES:
  From gemini (Task #16): Schema ready. Run 'npm run migrate' before testing. Updated docs in DB_SCHEMA.md. Watch for foreign key constraints on users table.

# Claude marks as read
bash ai_notes.sh mark-read claude

# Claude now knows exactly what to do and what to watch for
```

## JSON Structure

Notes are stored in `AI_NOTES.json`:

```json
{
  "task_notes": {
    "16": [
      {
        "id": "1729234567",
        "from": "claude",
        "to": "gemini",
        "message": "Edge case: null users break validation",
        "timestamp": "2025-10-18T05:30:00+00:00",
        "read": false
      }
    ]
  },
  "handoff_notes": [
    {
      "id": "1729234568",
      "from": "gemini",
      "to": "claude",
      "message": "Schema complete, run migrations",
      "task_id": "16",
      "timestamp": "2025-10-18T06:00:00+00:00",
      "read": false
    }
  ],
  "general_notes": [
    {
      "id": "1729234569",
      "from": "chatgpt",
      "to": "all",
      "message": "Updated brand guidelines",
      "timestamp": "2025-10-18T07:00:00+00:00",
      "read": false
    }
  ]
}
```

## Best Practices

### Do Leave Notes For:
- Edge cases discovered while working
- Dependencies between tasks
- Configuration changes made
- Bugs found in related code
- Important context for next AI
- Special testing requirements
- Breaking changes

### Don't Leave Notes For:
- Routine status updates (use task status instead)
- Obvious next steps
- Personal preferences
- Chatty messages

### Good Note Examples:
```bash
"Database migration adds user_roles table, update queries in auth.js"
"Found memory leak in line 234, needs investigation"
"Changed API endpoint from /api/v1 to /api/v2, update frontend calls"
"Test with both SQLite and PostgreSQL, behavior differs"
```

### Bad Note Examples:
```bash
"Good job!" (not actionable)
"Task completed" (redundant with task status)
"I prefer tabs over spaces" (irrelevant)
```

## Maintenance

Notes auto-clean after 7 days (read notes only):
```bash
# Run weekly
bash ai_notes.sh clean 7
```

Unread notes are never auto-deleted to prevent information loss.

## Benefits

1. **Continuity** - Knowledge transfers between AIs
2. **Context** - Important details don't get lost
3. **Efficiency** - Next AI doesn't rediscover same issues
4. **Quality** - Special cases get documented
5. **Transparency** - Full audit trail of AI communication
6. **Async** - AIs can work independently but stay coordinated
