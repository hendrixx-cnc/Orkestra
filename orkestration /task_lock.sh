#!/bin/bash
# ATOMIC TASK LOCKING SYSTEM
# Provides file-based locks with timeout and version control

LOCK_DIR="/workspaces/The-Quantum-Self-/AI/locks"
LOCK_TIMEOUT=3600  # 1 hour default timeout

# Ensure lock directory exists
mkdir -p "$LOCK_DIR"

# Function: Acquire lock atomically
acquire_lock() {
    local task_id="$1"
    local ai_name="$2"
    local lock_file="$LOCK_DIR/task_${task_id}.lock"
    local max_attempts=3
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        # Use mkdir for atomic lock creation (POSIX standard)
        if mkdir "$lock_file" 2>/dev/null; then
            # Lock acquired successfully
            echo "$ai_name" > "$lock_file/owner"
            date +%s > "$lock_file/timestamp"
            echo "$$" > "$lock_file/pid"
            echo "✅ Lock acquired for Task #$task_id by $ai_name"
            return 0
        fi
        
        # Lock exists, check if it's stale
        if [ -f "$lock_file/timestamp" ]; then
            local lock_time=$(cat "$lock_file/timestamp")
            local current_time=$(date +%s)
            local age=$((current_time - lock_time))
            
            if [ $age -gt $LOCK_TIMEOUT ]; then
                echo "⚠️  Stale lock detected (${age}s old), breaking..."
                release_lock "$task_id" "TIMEOUT"
                continue
            fi
        fi
        
        # Lock held by another AI, wait and retry
        local owner=$(cat "$lock_file/owner" 2>/dev/null || echo "unknown")
        echo "⏳ Task #$task_id locked by $owner, waiting... (attempt $((attempt + 1))/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    
    echo "❌ Failed to acquire lock for Task #$task_id after $max_attempts attempts"
    return 1
}

# Function: Release lock
release_lock() {
    local task_id="$1"
    local reason="${2:-COMPLETE}"
    local lock_file="$LOCK_DIR/task_${task_id}.lock"
    
    if [ -d "$lock_file" ]; then
        # Log release reason
        echo "$reason at $(date -Iseconds)" > "$lock_file/release_reason"
        
        # Remove lock directory
        rm -rf "$lock_file"
        echo "🔓 Lock released for Task #$task_id (reason: $reason)"
        return 0
    else
        echo "⚠️  No lock found for Task #$task_id"
        return 1
    fi
}

# Function: Check lock status
check_lock() {
    local task_id="$1"
    local lock_file="$LOCK_DIR/task_${task_id}.lock"
    
    if [ -d "$lock_file" ]; then
        local owner=$(cat "$lock_file/owner" 2>/dev/null || echo "unknown")
        local timestamp=$(cat "$lock_file/timestamp" 2>/dev/null || echo "0")
        local age=$(($(date +%s) - timestamp))
        
        echo "🔒 Task #$task_id locked by $owner (${age}s ago)"
        return 0
    else
        echo "🔓 Task #$task_id is unlocked"
        return 1
    fi
}

# Function: Clean stale locks
clean_stale_locks() {
    echo "🧹 Cleaning stale locks..."
    local cleaned=0
    
    for lock_file in "$LOCK_DIR"/task_*.lock; do
        [ -d "$lock_file" ] || continue
        
        local timestamp=$(cat "$lock_file/timestamp" 2>/dev/null || echo "0")
        local age=$(($(date +%s) - timestamp))
        
        if [ $age -gt $LOCK_TIMEOUT ]; then
            local task_id=$(basename "$lock_file" | sed 's/task_\(.*\)\.lock/\1/')
            echo "   Removing stale lock: Task #$task_id (${age}s old)"
            rm -rf "$lock_file"
            ((cleaned++))
        fi
    done
    
    echo "✅ Cleaned $cleaned stale lock(s)"
}

# Function: List all locks
list_locks() {
    echo "📋 Current Locks:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local count=0
    for lock_file in "$LOCK_DIR"/task_*.lock; do
        [ -d "$lock_file" ] || continue
        
        local task_id=$(basename "$lock_file" | sed 's/task_\(.*\)\.lock/\1/')
        local owner=$(cat "$lock_file/owner" 2>/dev/null || echo "unknown")
        local timestamp=$(cat "$lock_file/timestamp" 2>/dev/null || echo "0")
        local age=$(($(date +%s) - timestamp))
        local pid=$(cat "$lock_file/pid" 2>/dev/null || echo "unknown")
        
        printf "   Task #%-3s | Owner: %-10s | Age: %4ds | PID: %s\n" \
            "$task_id" "$owner" "$age" "$pid"
        ((count++))
    done
    
    if [ $count -eq 0 ]; then
        echo "   (no active locks)"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main command dispatcher
case "${1:-}" in
    acquire)
        acquire_lock "$2" "$3"
        ;;
    release)
        release_lock "$2" "${3:-COMPLETE}"
        ;;
    check)
        check_lock "$2"
        ;;
    clean)
        clean_stale_locks
        ;;
    list)
        list_locks
        ;;
    *)
        echo "Usage: $0 {acquire|release|check|clean|list} [task_id] [ai_name|reason]"
        echo ""
        echo "Commands:"
        echo "  acquire <task_id> <ai_name>  - Acquire atomic lock for task"
        echo "  release <task_id> [reason]   - Release lock (reason: COMPLETE, ERROR, TIMEOUT)"
        echo "  check <task_id>              - Check lock status"
        echo "  clean                        - Remove stale locks (>1 hour)"
        echo "  list                         - List all active locks"
        exit 1
        ;;
esac
