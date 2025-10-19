# OrKeStra Auto-Pilot System
**Self-Recovering Multi-AI Task Execution**

## Overview

The Auto-Pilot system enables AIs to automatically handle errors, recover from failures, and continue processing task queues without manual intervention. This allows for efficient "hands-off" execution of large task trees.

---

## Key Features

### 🔄 Automatic Error Recovery
- **3 automatic retries** per task
- **Exponential backoff** for API rate limits
- **Smart error categorization**:
  - File/directory errors → Auto-create missing paths
  - API errors → Wait and retry
  - Assignment conflicts → Skip and move to next task
  - Dependency issues → Defer and retry later
  - Timeout errors → Release lock and retry

### 🛡️ Self-Healing Capabilities
- Creates missing directories automatically
- Releases stale locks on failures
- Resets stuck tasks to pending state
- Handles API rate limiting gracefully

### 📊 Comprehensive Logging
- All activities logged with timestamps
- Error details captured for analysis
- Progress tracking per AI
- Daily log files for audit trail

### 🎯 Multiple Execution Modes
- **Continuous**: Process N tasks sequentially
- **Batch**: Process all pending tasks
- **Parallel**: All AIs run simultaneously

---

## Usage

### Basic Commands

```bash
# Sequential execution (safest, AIs run one after another)
cd /workspaces/The-Quantum-Self-/AI
bash orkestra_autopilot.sh continuous 10

# Parallel execution (fastest, all AIs run together)
bash orkestra_autopilot.sh parallel 15

# Batch mode (process ALL pending tasks)
bash orkestra_autopilot.sh batch

# Show help
bash orkestra_autopilot.sh help
```

### Advanced Usage

```bash
# Single AI continuous mode (10 tasks)
bash auto_executor_with_recovery.sh continuous gemini 10

# Single AI batch mode (all tasks)
bash auto_executor_with_recovery.sh batch claude

# Single task with recovery
bash auto_executor_with_recovery.sh single chatgpt 14
```

---

## How It Works

### Error Detection & Recovery Flow

```
Task Execution Attempt
    ↓
Success? → ✅ Mark complete, continue
    ↓
Failure Detected
    ↓
Categorize Error:
    │
    ├─ File Error → Create directories → Retry
    ├─ API Error → Wait (30s × retry_count) → Retry
    ├─ Timeout → Release lock → Retry
    ├─ Assignment Conflict → Skip task
    ├─ Dependencies Not Met → Defer task
    └─ Unknown Error → Log and retry
    ↓
Retry Count < 3?
    ├─ Yes → Wait 10s → Retry
    └─ No → Record failure → Reset to pending → Next task
```

### Task Selection Logic

1. **Get pending tasks** for specific AI
2. **Check dependencies** - skip if not met
3. **Check assignment** - skip if assigned to different AI
4. **Execute with timeout** (10 minutes default)
5. **Handle errors automatically**
6. **Move to next task**

---

## Error Handling Strategies

### 1. File/Directory Errors
```bash
Error: /path/to/file: No such file or directory
Action: 
  - Extract path from error
  - Create parent directory: mkdir -p $(dirname $path)
  - Retry task immediately
```

### 2. API Rate Limiting
```bash
Error: API rate limit exceeded / quota error
Action:
  - Wait: 30 seconds × retry_count
  - Release task lock
  - Retry task
```

### 3. Task Assignment Conflicts
```bash
Error: TASK ALREADY ASSIGNED
Action:
  - Skip this task (another AI owns it)
  - Move to next available task
  - No retry needed
```

### 4. Dependency Issues
```bash
Error: DEPENDENCIES NOT MET
Action:
  - Skip this task for now
  - Will be retried later when dependencies complete
  - Return code: 3 (deferred)
```

### 5. Timeout Errors
```bash
Error: Task exceeds 600-second timeout
Action:
  - Release task lock
  - Wait 10 seconds
  - Retry task with fresh timeout
```

---

## Configuration

### Retry Settings

Located in `/AI/recovery/retry_config.json`:

```json
{
  "max_retries": 3,
  "retry_delay_seconds": 10,
  "timeout_seconds": 600,
  "api_wait_multiplier": 30
}
```

### Adjustable Parameters

In `orkestra_autopilot.sh`:
- `TASK_LIMIT`: Maximum tasks per AI (default: 20)
- `MODE`: Execution mode (continuous/batch/parallel)

In `auto_executor_with_recovery.sh`:
- Timeout per task: Line 54 (`timeout 600`)
- Max retries: Line 41 (`max_retries=3`)
- Retry delays: Various locations

---

## Logging & Monitoring

### Log Files

```bash
# Daily log file
/AI/recovery/auto_execution_YYYYMMDD.log

# View in real-time
tail -f /workspaces/The-Quantum-Self-/AI/recovery/auto_execution_$(date +%Y%m%d).log

# Search for errors
grep ERROR /workspaces/The-Quantum-Self-/AI/recovery/auto_execution_*.log
```

### Log Format

```
[2025-10-18 08:30:15] [INFO] Starting Task #21 with grok
[2025-10-18 08:30:18] [SUCCESS] Task #21 completed by grok
[2025-10-18 08:30:20] [WARN] Task #14 timed out (attempt 1/3)
[2025-10-18 08:30:35] [ERROR] Task #14 failed after 3 attempts
```

### Real-Time Monitoring

```bash
# Watch task queue status
watch -n 5 'cd /workspaces/The-Quantum-Self-/AI && jq ".queue[] | select(.status == \"in_progress\") | {id, title, assigned_to}" TASK_QUEUE.json'

# Monitor active locks
watch -n 5 'cd /workspaces/The-Quantum-Self-/AI && bash task_lock.sh list'

# Check completion progress
watch -n 10 'cd /workspaces/The-Quantum-Self-/AI && jq "[.queue[] | .status] | group_by(.) | map({status: .[0], count: length})" TASK_QUEUE.json'
```

---

## Best Practices

### 1. Start with Sequential Mode
```bash
# Safest for first run
bash orkestra_autopilot.sh continuous 5
```
Test with small task limit first to ensure system is working correctly.

### 2. Use Parallel for Speed
```bash
# Once verified, use parallel for efficiency
bash orkestra_autopilot.sh parallel 20
```

### 3. Monitor Logs During Execution
```bash
# In separate terminal
tail -f /workspaces/The-Quantum-Self-/AI/recovery/auto_execution_$(date +%Y%m%d).log
```

### 4. Check Failed Tasks
```bash
# View tasks that exhausted retries
jq '.failed' /workspaces/The-Quantum-Self-/AI/recovery/failed_tasks.json
```

### 5. Clean Up Between Runs
```bash
# Release all locks
bash task_lock.sh clean

# Reset stuck tasks
jq '(.queue[] | select(.status == "in_progress") | .status) = "pending"' TASK_QUEUE.json > tmp.json && mv tmp.json TASK_QUEUE.json
```

---

## Troubleshooting

### Problem: AIs keep timing out
**Solution**: Increase timeout in `auto_executor_with_recovery.sh` line 54:
```bash
timeout 1200 bash "$SCRIPT_DIR/$agent_script" execute "$task_id"
```

### Problem: Too many API errors
**Solution**: Increase API wait time in error handling section:
```bash
local wait_time=$((60 * retry_count))  # Changed from 30
```

### Problem: Tasks stuck in "in_progress"
**Solution**: Run cleanup:
```bash
bash task_lock.sh clean
# Then manually reset tasks
```

### Problem: Want to stop execution
**Solution**: Kill background processes:
```bash
pkill -f "auto_executor_with_recovery.sh"
pkill -f "orkestra_autopilot.sh"
```

---

## Examples

### Example 1: Process 10 Tasks Per AI (Sequential)
```bash
cd /workspaces/The-Quantum-Self-/AI
bash orkestra_autopilot.sh continuous 10
```
**Time**: ~40-60 minutes  
**Safety**: High (one AI at a time)  
**Best for**: Testing, low-resource systems

### Example 2: All AIs Process Everything (Parallel)
```bash
bash orkestra_autopilot.sh parallel 50
```
**Time**: ~20-30 minutes  
**Safety**: Medium (concurrent execution)  
**Best for**: Production runs, high-resource systems

### Example 3: Single AI Marathon
```bash
bash auto_executor_with_recovery.sh batch claude
```
**Time**: Depends on task count  
**Best for**: One AI has many tasks

### Example 4: Emergency Single Task
```bash
bash auto_executor_with_recovery.sh single gemini 33
```
**Time**: 2-10 minutes  
**Best for**: Critical task needs completion

---

## Return Codes

- `0`: Success
- `1`: Failed after all retries
- `2`: Skipped (assignment conflict)
- `3`: Deferred (dependencies not met)

---

## Safety Features

1. **Lock Cleanup**: Automatic release on all error paths
2. **Task Reset**: Failed tasks returned to pending state for reassignment
3. **Failure Recording**: All failures logged for analysis
4. **Dependency Checking**: Won't start tasks with unmet dependencies
5. **Timeout Protection**: Tasks can't hang indefinitely
6. **Resource Limits**: Configurable task count prevents runaway execution

---

## Performance Tips

1. **Parallel mode** is fastest but uses more resources
2. **Continuous mode** is safest for stability
3. Start with **low task limits** (5-10) to test
4. Monitor **log files** for patterns
5. Adjust **timeout values** based on task complexity
6. Use **batch mode** overnight for unattended operation

---

## Summary

The Auto-Pilot system enables fully autonomous multi-AI task execution with:
- ✅ Automatic error recovery
- ✅ Self-healing capabilities
- ✅ Comprehensive logging
- ✅ Multiple execution modes
- ✅ Production-ready reliability

**Quick Start**: `bash orkestra_autopilot.sh parallel 10`

**Monitor**: `tail -f AI/recovery/auto_execution_$(date +%Y%m%d).log`

**Stop**: `pkill -f orkestra_autopilot`
