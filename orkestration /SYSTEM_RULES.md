# AI Orchestration System Rules & Safety Guidelines

## Core Principles
1. **Single Source of Truth** - All scripts MUST reference AI/TASK_QUEUE.json (never ../TASK_QUEUE.json)
2. **Atomic Operations** - Every task claim/update must be locked
3. **Pre/Post Validation** - Validate state before and after every task
4. **Peer Review** - Round-robin AI reviews all completed work
5. **Fail Safe** - Never loop on failed tasks, log and skip
6. **Consistency First** - Check file paths, JSON structure, dependencies before execution
7. **NAMING CONVENTION** - ALL identifiers MUST be lowercase (ai names, file names, keys)

---

## 🔤 NAMING CONVENTION RULES (MANDATORY)

### Rule: Everything Lowercase
**ALL** names, identifiers, and keys MUST be lowercase. NO EXCEPTIONS.

### ✅ CORRECT (lowercase)
```json
{
  "assigned_to": "claude",
  "assigned_to": "chatgpt",
  "assigned_to": "gemini",
  "assigned_to": "grok",
  "assigned_to": "copilot"
}
```

```bash
AI_NAME="claude"      # lowercase
AI_NAME="chatgpt"     # lowercase
AI_NAME="gemini"      # lowercase
```

### ❌ INCORRECT (mixed case - FORBIDDEN)
```json
{
  "assigned_to": "Claude",     # WRONG
  "assigned_to": "ChatGPT",    # WRONG
  "assigned_to": "Gemini",     # WRONG
  "assigned_to": "Grok",       # WRONG
}
```

### Enforcement
1. **Pre-Validation**: Scripts MUST normalize names to lowercase before comparison
2. **Task Creation**: All new tasks MUST use lowercase AI names
3. **Comparison Logic**: Always use case-insensitive comparison OR normalize both sides
4. **File Names**: All log files, output files use lowercase: `claude_task_9.log`

### Code Pattern (Required)
```bash
# ALWAYS normalize before comparison
ASSIGNED_TO_LOWER=$(echo "$ASSIGNED_TO" | tr '[:upper:]' '[:lower:]')
AI_NAME_LOWER=$(echo "$AI_NAME" | tr '[:upper:]' '[:lower:]')

if [[ "$ASSIGNED_TO_LOWER" == "$AI_NAME_LOWER" ]]; then
  # Match found
fi
```

---

## File Path Rules

### ✅ CORRECT Paths
```bash
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"           # AI scripts reference AI/TASK_QUEUE.json
TASK_QUEUE="/workspaces/The-Quantum-Self-/AI/TASK_QUEUE.json"  # Absolute path
```

### ❌ INCORRECT Paths (NEVER USE)
```bash
TASK_QUEUE="$SCRIPT_DIR/../TASK_QUEUE.json"        # Points to root (old file)
TASK_QUEUE="/workspaces/The-Quantum-Self-/TASK_QUEUE.json"  # Root location (deprecated)
```

### Required Directory Structure
```
/workspaces/The-Quantum-Self-/AI/
  ├── TASK_QUEUE.json              # PRIMARY task queue (ONLY source of truth)
  ├── locks/                       # Task locks directory
  ├── logs/                        # All agent logs
  ├── status/                      # Agent status files
  ├── audit/                       # Task audit logs
  └── validation/                  # Pre/post validation results
```

---

## Task Execution Rules

### Rule 1: Pre-Task Validation (MANDATORY)
Before executing ANY task, validate:
1. Task exists in TASK_QUEUE.json
2. Task status is "pending" (not "completed" or "in_progress")
3. Dependencies are completed
4. Output directory exists or can be created
5. Input files exist (if specified)
6. No conflicting locks exist

### Rule 2: Lock Management
- Acquire lock BEFORE claiming task
- Release lock AFTER updating status
- Auto-clean stale locks (>1 hour)
- NEVER proceed without successful lock acquisition

### Rule 3: Post-Task Validation (MANDATORY)
After completing ANY task, validate:
1. Output file exists and is not empty
2. Task status updated to "completed" in TASK_QUEUE.json
3. Lock properly released
4. Audit log entry created
5. Peer review request queued

### Rule 4: Failure Handling
- Log failure with full context
- Release locks immediately
- Mark task as "failed" (not retry indefinitely)
- Skip to next task
- Alert if same task fails 3+ times

### Rule 5: Peer Review Round-Robin
After each task completion:
1. Select next AI in rotation for review
2. Queue review task (5-10 min evaluation)
3. Reviewer validates: quality, completeness, style consistency
4. Reviewer approves or requests revision
5. Rotate to next reviewer for next task

---

## JSON Structure Rules

### Task Queue Structure (ENFORCED)
```json
{
  "active_task": <number>,
  "ai_agents": [
    {
      "name": "string",
      "role": "string", 
      "specialties": ["array"],
      "status": "active|paused|error"
    }
  ],
  "queue": [
    {
      "id": <number>,
      "title": "string",
      "assigned_to": "copilot|claude|chatgpt|gemini|grok",
      "status": "pending|in_progress|completed|failed",
      "priority": "high|medium|low",
      "depends_on": <number|null>,
      "input_file": "string|null",
      "output_file": "string",
      "instructions": "string",
      "reviewed_by": "string|null",
      "review_status": "pending|approved|revision_needed|null"
    }
  ],
  "review_rotation": ["claude", "chatgpt", "grok", "gemini", "copilot"]
}
```

### NEVER Use Deprecated Fields
- ❌ `.tasks[]` (use `.queue[]`)
- ❌ `"waiting"` status (use `"pending"`)
- ❌ `"not_started"` status (use `"pending"`)

---

## Consistency Checks (Run Before/After Each Task)

### 1. Path Consistency Check
```bash
# Ensure all scripts reference correct TASK_QUEUE
grep -l 'TASK_QUEUE.*\.\./TASK_QUEUE' AI/*.sh
# Should return EMPTY (no results)
```

### 2. Lock Consistency Check
```bash
# No orphaned locks older than 1 hour
find AI/locks/*.lock -mmin +60 -delete
```

### 3. Status Consistency Check
```bash
# No tasks marked "in_progress" without corresponding locks
jq '.queue[] | select(.status == "in_progress") | .id' AI/TASK_QUEUE.json
# Cross-reference with locks/ directory
```

### 4. Dependency Consistency Check
```bash
# All dependencies must exist and be completed
jq '.queue[] | select(.depends_on != null) | {id, depends_on, dep_status: (.queue[] | select(.id == .depends_on) | .status)}' AI/TASK_QUEUE.json
```

---

## Round-Robin Peer Review System

### Review Rotation Order (4-AI Circle)
1. Claude reviews ChatGPT's work
2. ChatGPT reviews Grok's work
3. Grok reviews Gemini's work
4. Gemini reviews Claude's work (completes the circle)

**Note**: Copilot (GitHub Copilot/human operator) is excluded from the rotation and handles:
- Project management and coordination
- High-level strategic tasks
- Manual review and quality assurance
- System maintenance and troubleshooting
- Specific tasks requested directly by the user

### Review Criteria
- **Completeness**: All requirements met
- **Quality**: Meets project standards
- **Consistency**: Matches existing code/content style
- **Accuracy**: Technically correct
- **Usability**: Ready for integration

### Review Actions
- `approved`: Accept as-is, move to next task
- `approved_with_notes`: Accept but document improvements
- `revision_needed`: Return to original AI for fixes
- `failed`: Reassign to different AI

---

## Auto-Executor Safety Rules

### Rule 1: Single Task Mode First
- Test with `once` mode before using `all` or `watch`
- Verify task completes successfully
- Check output file quality

### Rule 2: No Infinite Loops
- Max 3 retry attempts per task
- If task fails 3x, mark as "failed" and skip
- Auto-executors must check retry count

### Rule 3: Resource Limits
- Max 10 tasks per AI per hour (rate limiting)
- Max 5 concurrent tasks across all AIs
- Pause automation if error rate >20%

### Rule 4: Graceful Degradation
- If API key missing, skip that AI (don't crash)
- If lock acquisition fails, wait 30s and retry once
- If output file creation fails, log and skip task

---

## Error Prevention Checklist

### Before Starting Automation
- [ ] All API keys set (OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, XAI_API_KEY)
- [ ] TASK_QUEUE.json validates with `jq empty`
- [ ] All scripts reference `AI/TASK_QUEUE.json` (not `../TASK_QUEUE.json`)
- [ ] No stale locks in `AI/locks/`
- [ ] Log directories exist (`logs/`, `audit/`, `status/`)
- [ ] All dependencies installed (jq, curl, sgpt, grok)

### During Task Execution
- [ ] Lock acquired successfully
- [ ] Task status is "pending"
- [ ] Dependencies completed (if any)
- [ ] Output directory exists
- [ ] Input file exists (if required)

### After Task Completion
- [ ] Output file created and non-empty
- [ ] Task status updated to "completed"
- [ ] Lock released
- [ ] Audit log entry created
- [ ] Peer review queued

---

## Known Issues & Fixes

### Issue 1: Multiple TASK_QUEUE.json Files
**Problem**: `/TASK_QUEUE.json` (root) vs `/AI/TASK_QUEUE.json`  
**Fix**: Use `/AI/TASK_QUEUE.json` exclusively, delete root copy  
**Prevention**: All scripts must use `$SCRIPT_DIR/TASK_QUEUE.json`

### Issue 2: Task Loop on Failed Task
**Problem**: Auto-executor retries same failed task infinitely  
**Fix**: Add retry counter, max 3 attempts, then mark "failed"  
**Prevention**: Check task status before execution

### Issue 3: Stale Locks
**Problem**: Lock files remain after crash/timeout  
**Fix**: Auto-clean locks older than 1 hour  
**Prevention**: Use timeout in lock acquisition

### Issue 4: Path Inconsistencies
**Problem**: Scripts use relative paths, break when run from different directories  
**Fix**: Use absolute paths or `$SCRIPT_DIR` relative paths  
**Prevention**: All scripts start with `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`

---

## Validation Scripts

All validation scripts located in `/AI/validation/`:
- `pre_task_validator.sh` - Run before task execution
- `post_task_validator.sh` - Run after task completion
- `consistency_checker.sh` - Run hourly via cron
- `path_validator.sh` - Ensure all scripts use correct paths
- `peer_review_queue.sh` - Manage round-robin reviews

---

## Emergency Procedures

### Stop All Automation
```bash
pkill -f "auto_executor\|universal_daemon\|orchestrator"
bash AI/task_lock.sh clean  # Remove all locks
```

### Reset Failed Tasks
```bash
jq '.queue = [.queue[] | if .status == "failed" then .status = "pending" else . end]' AI/TASK_QUEUE.json > /tmp/reset.json
mv /tmp/reset.json AI/TASK_QUEUE.json
```

### Audit Trail Check
```bash
tail -100 AI/audit/*.log | grep ERROR
```

### Manual Override
```bash
# Force complete a task (use with caution)
bash AI/complete_task_v2.sh <task_id> --force

# Force claim a task (bypasses locks)
bash AI/claim_task_v2.sh <task_id> <ai_name> --force
```

---

## Version Control Rules

### Commit Frequency
- After every 5 completed tasks
- Before/after major automation runs
- When system rules change

### Commit Message Format
```
[AI] <action>: <description>

Examples:
[AI] TASK_COMPLETE: Generated Module 01 prompts (100 prompts)
[AI] FIX: Corrected TASK_QUEUE path in 8 scripts
[AI] REVIEW: Claude approved ChatGPT Task #14 marketing copy
```

---

## Monitoring & Alerts

### Dashboard Metrics
- Tasks completed per hour
- Error rate per AI
- Average task duration
- Lock contention events
- Review backlog size

### Alert Thresholds
- ⚠️ Warning: Error rate >10%
- 🚨 Critical: Error rate >20% or 3 consecutive failures
- ⛔ Stop: Same task fails 5+ times

---

*Last Updated: 2025-10-18*  
*Version: 2.0*
