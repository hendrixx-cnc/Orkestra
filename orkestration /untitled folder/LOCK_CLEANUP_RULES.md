# Lock Cleanup Rules

## Automatic Lock Cleanup System

This document defines the rules for automatic lock cleanup in the AI orchestration system.

## Design Philosophy

**Rule**: Locks are cleared when no longer needed.

This prevents deadlocks, stale locks, and ensures system availability. Multiple cleanup mechanisms work together to enforce this rule.

## Cleanup Mechanisms

### 1. Explicit Cleanup (Immediate)

Scripts explicitly release locks at the end of successful operations:

**complete_task.sh**
```bash
bash task_lock.sh release "$TASK_ID" "COMPLETED"
```
- Triggered: When task completes successfully
- Reason: COMPLETED
- Priority: Highest (immediate)

**fail_task.sh**
```bash
bash task_lock.sh release "$TASK_ID" "FAILED"
```
- Triggered: When task fails
- Reason: FAILED
- Priority: Highest (immediate)

### 2. Error Path Cleanup (Immediate)

Scripts release locks on errors in claim_task_v2.sh:

- **Task not found**: Release with reason "ERROR"
- **Assignment conflict**: Release with reason "REASSIGN_BLOCKED"
- **Already complete**: Release with reason "ALREADY_COMPLETE"
- **Dependencies not met**: Release with reason "DEPENDENCY_NOT_MET"
- **JSON corruption**: Release with reason "JSON_ERROR"

### 3. Trap-Based Cleanup (On Exit)

claim_task_v2.sh uses bash trap to ensure cleanup:

```bash
cleanup_on_exit() {
    if [ "$LOCK_ACQUIRED" = true ] && [ -n "$TASK_ID" ]; then
        bash "$SCRIPT_DIR/task_lock.sh" release "$TASK_ID" "SCRIPT_EXIT" 2>/dev/null || true
    fi
}
trap cleanup_on_exit EXIT
```

- Triggered: Script exits unexpectedly (Ctrl+C, kill, crash)
- Reason: SCRIPT_EXIT
- Priority: High (catches all uncaught exits)
- Note: Disabled after successful claim (task keeps lock)

### 4. Background Monitor (Periodic)

lock_monitor.sh daemon runs continuous cleanup:

**Configuration**
- Check interval: 60 seconds
- Stale threshold: 1800 seconds (30 minutes)
- Dead process cleanup: Enabled

**Cleanup Rules**

**Rule 1: Stale Timeout**
```bash
if [ $age -gt $STALE_THRESHOLD ]; then
    release with reason "STALE_TIMEOUT"
fi
```
- Any lock older than 30 minutes is released
- Protects against hung processes

**Rule 2: Dead Process**
```bash
if ! kill -0 "$lock_pid" 2>/dev/null; then
    release with reason "DEAD_PROCESS"
fi
```
- Releases locks from processes that no longer exist
- Checks PID stored in lock directory

**Rule 3: Task Completed**
```bash
if [ "$task_status" = "completed" ]; then
    release with reason "TASK_COMPLETED"
fi
```
- Releases locks for tasks marked complete
- Catches cases where complete_task.sh failed to release

### 5. Manual Cleanup (On Demand)

Administrators can manually release locks:

```bash
bash task_lock.sh release <task_id> "MANUAL"
bash task_lock.sh clean-stale
```

## Lock Lifecycle

```
┌─────────────────────────────────────────────────────────┐
│ 1. ACQUIRE LOCK                                         │
│    bash task_lock.sh acquire $TASK_ID $AI_NAME          │
│    - Creates lock directory atomically                  │
│    - Stores: timestamp, owner, PID                      │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│ 2. WORK ON TASK                                         │
│    - Execute task operations                            │
│    - trap cleanup_on_exit is ACTIVE                     │
│    - Monitor checks every 60s                           │
└─────────────────┬───────────────────────────────────────┘
                  │
                  ▼
           ┌──────┴───────┐
           │              │
           ▼              ▼
    ┌────────────┐   ┌────────────┐
    │  SUCCESS   │   │   FAILURE  │
    └──────┬─────┘   └──────┬─────┘
           │                │
           ▼                ▼
┌─────────────────────────────────────────────────────────┐
│ 3. RELEASE LOCK                                         │
│    Method depends on outcome:                           │
│    - complete_task.sh → "COMPLETED"                     │
│    - fail_task.sh → "FAILED"                            │
│    - Error handler → specific reason                    │
│    - trap → "SCRIPT_EXIT"                               │
│    - Monitor → "STALE_TIMEOUT" / "DEAD_PROCESS"         │
│    - Manual → "MANUAL"                                  │
└─────────────────────────────────────────────────────────┘
```

## Monitoring & Logging

All lock operations are logged to audit trail:

```bash
bash task_audit.sh log "LOCK_RELEASED" "$TASK_ID" "$AI_NAME" "Reason: $REASON" "released"
```

View lock status:
```bash
bash task_lock.sh list           # Show all locks
bash task_lock.sh check $TASK_ID # Check specific task
```

View monitor logs:
```bash
tail -f AI/logs/lock_monitor.log
```

## Starting the Monitor

The lock monitor should run continuously:

```bash
# Start monitor in background
bash AI/lock_monitor.sh &

# Check if running
ps aux | grep lock_monitor

# Stop monitor
kill $(cat AI/locks/lock_monitor.pid)
```

## Troubleshooting

### Lock Won't Release

1. Check if process is still running:
```bash
cat AI/locks/task_$TASK_ID.lock/pid
ps -p <pid>
```

2. Check lock age:
```bash
bash task_lock.sh check $TASK_ID
```

3. Manual release if needed:
```bash
bash task_lock.sh release $TASK_ID "MANUAL"
```

### Monitor Not Cleaning

1. Check monitor is running:
```bash
ps aux | grep lock_monitor.sh
cat AI/locks/lock_monitor.pid
```

2. Check monitor logs:
```bash
tail -f AI/logs/lock_monitor.log
```

3. Restart monitor:
```bash
kill $(cat AI/locks/lock_monitor.pid)
bash AI/lock_monitor.sh &
```

### Stale Locks After Crash

Run manual cleanup:
```bash
bash task_lock.sh clean-stale
```

This releases all locks older than timeout threshold.

## Best Practices

1. **Always use complete_task.sh or fail_task.sh** - Don't manipulate TASK_QUEUE.json directly
2. **Run lock monitor continuously** - Provides safety net for unexpected failures
3. **Check lock status before forcing** - Understand why lock exists before releasing manually
4. **Monitor the logs** - Watch for patterns of stale locks indicating system issues
5. **Adjust thresholds if needed** - 30-minute timeout may need tuning based on task duration

## Configuration

Edit lock_monitor.sh to adjust cleanup behavior:

```bash
CHECK_INTERVAL=60           # Check every 60 seconds
STALE_THRESHOLD=1800       # 30 minutes = stale
DEAD_PROCESS_CLEANUP=true  # Clean locks from dead processes
```

## Recovery Scenarios

### Scenario 1: AI Crashes Mid-Task
- **Trap cleanup**: Releases lock with "SCRIPT_EXIT"
- **If trap fails**: Monitor releases after 30 minutes with "STALE_TIMEOUT"

### Scenario 2: System Restart
- **All processes killed**: Locks remain in filesystem
- **Monitor restart**: Detects dead processes, releases with "DEAD_PROCESS"

### Scenario 3: Network Interruption
- **Process continues**: Lock remains valid
- **If process hangs**: Monitor releases after 30 minutes

### Scenario 4: Task Completes but Script Fails
- **complete_task.sh fails**: Trap attempts cleanup
- **If trap fails**: Monitor checks task status, releases with "TASK_COMPLETED"

## Summary

The lock cleanup system uses **5 layers of defense**:

1. **Explicit** - Scripts release at end of operations
2. **Error handlers** - Release on known errors
3. **Trap** - Catch unexpected exits
4. **Monitor** - Periodic cleanup of stale/dead locks
5. **Manual** - Admin override when needed

This ensures locks are **always** cleared when no longer needed, preventing deadlocks and maintaining system availability.
