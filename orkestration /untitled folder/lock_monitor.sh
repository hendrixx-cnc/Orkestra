#!/bin/bash
# Lock Monitor Daemon
# Automatically cleans up stale locks based on configurable rules

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCK_DIR="$SCRIPT_DIR/locks"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
PID_FILE="$SCRIPT_DIR/locks/lock_monitor.pid"

# Configuration
CHECK_INTERVAL=60           # Check every 60 seconds
STALE_THRESHOLD=1800       # 30 minutes = stale lock
DEAD_PROCESS_CLEANUP=true  # Clean locks from dead processes
LOG_FILE="$SCRIPT_DIR/logs/lock_monitor.log"

mkdir -p "$SCRIPT_DIR/logs"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if daemon is already running
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
        echo "Lock monitor already running (PID: $old_pid)"
        exit 0
    else
        rm -f "$PID_FILE"
    fi
fi

# Save our PID
echo $$ > "$PID_FILE"

log "Lock monitor started (PID: $$)"

# Cleanup on exit
cleanup() {
    log "Lock monitor stopping..."
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Main monitoring loop
while true; do
    cleaned_count=0
    
    # Check each lock
    for lock_dir in "$LOCK_DIR"/task_*.lock; do
        [ -d "$lock_dir" ] || continue
        
        task_id=$(basename "$lock_dir" | sed 's/task_//' | sed 's/.lock//')
        
        # Get lock info
        if [ ! -f "$lock_dir/timestamp" ]; then
            log "CLEANUP: Task #$task_id - Missing timestamp, removing"
            rm -rf "$lock_dir"
            ((cleaned_count++))
            continue
        fi
        
        lock_time=$(cat "$lock_dir/timestamp")
        current_time=$(date +%s)
        age=$((current_time - lock_time))
        
        # Rule 1: Remove locks older than STALE_THRESHOLD
        if [ $age -gt $STALE_THRESHOLD ]; then
            owner=$(cat "$lock_dir/owner" 2>/dev/null || echo "unknown")
            log "CLEANUP: Task #$task_id - Stale lock (${age}s old, owner: $owner)"
            bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" "STALE_TIMEOUT" 2>/dev/null
            ((cleaned_count++))
            continue
        fi
        
        # Rule 2: Remove locks from dead processes
        if [ "$DEAD_PROCESS_CLEANUP" = true ] && [ -f "$lock_dir/pid" ]; then
            lock_pid=$(cat "$lock_dir/pid")
            if ! kill -0 "$lock_pid" 2>/dev/null; then
                owner=$(cat "$lock_dir/owner" 2>/dev/null || echo "unknown")
                log "CLEANUP: Task #$task_id - Dead process (PID: $lock_pid, owner: $owner)"
                bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" "DEAD_PROCESS" 2>/dev/null
                ((cleaned_count++))
                continue
            fi
        fi
        
        # Rule 3: Remove locks for completed tasks
        if [ -f "$TASK_QUEUE" ]; then
            task_status=$(jq -r ".queue[] | select(.id == $task_id) | .status" "$TASK_QUEUE" 2>/dev/null)
            if [ "$task_status" = "completed" ]; then
                owner=$(cat "$lock_dir/owner" 2>/dev/null || echo "unknown")
                log "CLEANUP: Task #$task_id - Task marked complete (owner: $owner)"
                bash "$SCRIPT_DIR/task_lock.sh" release "$task_id" "TASK_COMPLETED" 2>/dev/null
                ((cleaned_count++))
                continue
            fi
        fi
    done
    
    if [ $cleaned_count -gt 0 ]; then
        log "Cleaned $cleaned_count lock(s)"
    fi
    
    # Wait before next check
    sleep $CHECK_INTERVAL
done
