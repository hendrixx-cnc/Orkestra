# Lock Cleanup Quick Reference

## Monitor Control

| Command | Description |
|---------|-------------|
| `bash monitor.sh start` | Start lock monitor daemon |
| `bash monitor.sh stop` | Stop lock monitor daemon |
| `bash monitor.sh restart` | Restart lock monitor daemon |
| `bash monitor.sh status` | Check if running + recent activity |
| `bash monitor.sh logs` | Show last 50 log entries |
| `bash monitor.sh logs -f` | Follow logs in real-time |

## Manual Lock Operations

| Command | Description |
|---------|-------------|
| `bash task_lock.sh list` | Show all current locks |
| `bash task_lock.sh check <id>` | Check specific lock status |
| `bash task_lock.sh release <id> "REASON"` | Manually release a lock |
| `bash task_lock.sh clean-stale` | Clean all stale locks (>1 hour) |

## Cleanup Mechanisms

| Layer | Trigger | Reason Code | Priority |
|-------|---------|-------------|----------|
| **Explicit** | Task completes | COMPLETED | Highest |
| **Error Handler** | Known error | ERROR/BLOCKED/etc | High |
| **Trap** | Script exit | SCRIPT_EXIT | High |
| **Monitor** | Every 60s check | STALE/DEAD/COMPLETED | Medium |
| **Manual** | Admin command | MANUAL | Override |

## Monitor Rules

| Rule | Condition | Action |
|------|-----------|--------|
| **Stale Timeout** | Lock > 30 min old | Release with "STALE_TIMEOUT" |
| **Dead Process** | PID no longer exists | Release with "DEAD_PROCESS" |
| **Task Complete** | Task status = "completed" | Release with "TASK_COMPLETED" |

## Quick Troubleshooting

### Lock Won't Release
```bash
# Check if process exists
cat AI/locks/task_X.lock/pid
ps -p <pid>

# Check lock age
bash task_lock.sh check <id>

# Force release if needed
bash task_lock.sh release <id> "MANUAL"
```

### Monitor Not Running
```bash
# Check status
bash monitor.sh status

# Restart
bash monitor.sh restart

# Check logs
bash monitor.sh logs -f
```

### Multiple Stale Locks
```bash
# Clean all at once
bash task_lock.sh clean-stale

# Check monitor is running
bash monitor.sh status
```

## File Locations

- **Monitor Script**: `AI/lock_monitor.sh`
- **Management Script**: `AI/monitor.sh`
- **Lock Directory**: `AI/locks/`
- **Monitor Logs**: `AI/logs/lock_monitor.log`
- **PID File**: `AI/locks/lock_monitor.pid`

## Configuration

Edit `AI/lock_monitor.sh`:
```bash
CHECK_INTERVAL=60       # Seconds between checks
STALE_THRESHOLD=1800   # Seconds (30 min) before stale
DEAD_PROCESS_CLEANUP=true  # Enable dead process cleanup
```

## Integration Points

- `complete_task.sh` → Auto-release on completion
- `claim_task_v2.sh` → Trap for unexpected exits
- `task_lock.sh` → Core lock operations
- `task_audit.sh` → Audit trail logging
- `TASK_QUEUE.json` → Task status checking

## Best Practices

1. Always run monitor daemon in production
2. Check logs for cleanup patterns
3. Don't force release without investigating
4. Adjust thresholds based on task duration
5. Monitor the monitor (check status regularly)

## Recovery Scenarios

| Scenario | Recovery Method |
|----------|----------------|
| AI crashes | Trap cleanup → Monitor (3 min) |
| System restart | Monitor detects dead processes |
| Network hang | Monitor timeout (30 min) |
| Complete fails | Monitor checks task status |
| Manual intervention | Admin force release |

## Monitoring Commands

```bash
# Watch monitor activity
watch -n 5 'bash AI/monitor.sh status'

# Follow cleanup events
grep CLEANUP AI/logs/lock_monitor.log | tail -20

# Check lock count
bash task_lock.sh list | grep -c "Task #"

# See all lock ages
for lock in AI/locks/task_*.lock; do 
  [ -d "$lock" ] && bash task_lock.sh check ${lock#*task_} | head -1
done
```

## Rule Summary

**Locks are cleared when no longer needed**

This rule is enforced automatically at 5 levels:
1. Scripts release on completion
2. Error handlers release on failure
3. Trap catches unexpected exits
4. Monitor cleans stale/dead locks
5. Manual override always available

No user action required for normal operation.
