#!/bin/bash
# IMMUTABLE AUDIT TRAIL SYSTEM
# Append-only log for complete task history

AUDIT_DIR="/workspaces/The-Quantum-Self-/AI/audit"
AUDIT_LOG="$AUDIT_DIR/task_audit.jsonl"  # JSONL = JSON Lines (append-only)

# Ensure audit directory exists
mkdir -p "$AUDIT_DIR"
touch "$AUDIT_LOG"

# Function: Log task event (append-only)
log_event() {
    local event_type="$1"
    local task_id="$2"
    local ai_name="$3"
    local details="$4"
    local status="${5:-}"
    
    local timestamp=$(date -Iseconds)
    local event_id=$(uuidgen 2>/dev/null || echo "$(date +%s)-$$-$RANDOM")
    
    # Create JSON event (single line)
    local json_event=$(jq -n \
        --arg id "$event_id" \
        --arg ts "$timestamp" \
        --arg type "$event_type" \
        --arg task "$task_id" \
        --arg ai "$ai_name" \
        --arg details "$details" \
        --arg status "$status" \
        '{
            event_id: $id,
            timestamp: $ts,
            event_type: $type,
            task_id: ($task | tonumber),
            ai_name: $ai,
            details: $details,
            status: $status
        }')
    
    # Append to audit log (atomic write)
    echo "$json_event" >> "$AUDIT_LOG"
    
    echo "📝 Audit: [$event_type] Task #$task_id by $ai_name"
}

# Function: Query audit log
query_events() {
    local filter="${1:-all}"
    local task_id="${2:-}"
    
    echo "📊 Audit Trail Query: $filter"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    case "$filter" in
        task)
            if [ -z "$task_id" ]; then
                echo "❌ Task ID required for 'task' filter"
                return 1
            fi
            cat "$AUDIT_LOG" | jq -r "select(.task_id == $task_id) | \"\(.timestamp) | \(.event_type) | \(.ai_name) | \(.details)\""
            ;;
        ai)
            local ai_name="$task_id"  # Reuse param
            cat "$AUDIT_LOG" | jq -r "select(.ai_name == \"$ai_name\") | \"\(.timestamp) | Task #\(.task_id) | \(.event_type) | \(.details)\""
            ;;
        errors)
            cat "$AUDIT_LOG" | jq -r 'select(.event_type == "ERROR" or .event_type == "TIMEOUT" or .event_type == "FAILED") | "\(.timestamp) | Task #\(.task_id) | \(.ai_name) | \(.details)"'
            ;;
        recent)
            local count="${task_id:-20}"
            tail -n "$count" "$AUDIT_LOG" | jq -r '"\(.timestamp) | Task #\(.task_id) | \(.event_type) | \(.ai_name) | \(.details)"'
            ;;
        stats)
            echo "Total Events: $(wc -l < "$AUDIT_LOG")"
            echo ""
            echo "Events by Type:"
            cat "$AUDIT_LOG" | jq -r '.event_type' | sort | uniq -c | sort -rn
            echo ""
            echo "Events by AI:"
            cat "$AUDIT_LOG" | jq -r '.ai_name' | sort | uniq -c | sort -rn
            ;;
        all|*)
            cat "$AUDIT_LOG" | jq -r '"\(.timestamp) | Task #\(.task_id) | \(.event_type) | \(.ai_name) | \(.details)"'
            ;;
    esac
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function: Replay task history
replay_task() {
    local task_id="$1"
    
    echo "🎬 Replaying Task #$task_id History:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cat "$AUDIT_LOG" | jq -r "select(.task_id == $task_id) | \"\(.timestamp) | \(.event_type) | \(.ai_name) | \(.details)\""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Summary
    local events=$(cat "$AUDIT_LOG" | jq "select(.task_id == $task_id)" | wc -l)
    local ais=$(cat "$AUDIT_LOG" | jq -r "select(.task_id == $task_id) | .ai_name" | sort -u | tr '\n' ', ' | sed 's/,$//')
    
    echo "Total Events: $events"
    echo "AIs Involved: $ais"
}

# Function: Export audit trail
export_audit() {
    local output_file="${1:-$AUDIT_DIR/audit_export_$(date +%Y%m%d_%H%M%S).json}"
    
    echo "💾 Exporting audit trail to: $output_file"
    
    # Convert JSONL to JSON array
    jq -s '.' "$AUDIT_LOG" > "$output_file"
    
    local size=$(du -h "$output_file" | cut -f1)
    local count=$(jq length "$output_file")
    
    echo "✅ Exported $count events ($size)"
}

# Function: Rotate audit log (for maintenance)
rotate_log() {
    local archive_file="$AUDIT_DIR/audit_$(date +%Y%m%d_%H%M%S).jsonl.gz"
    
    echo "🔄 Rotating audit log..."
    
    # Compress and archive current log
    gzip -c "$AUDIT_LOG" > "$archive_file"
    
    # Start fresh log
    > "$AUDIT_LOG"
    
    echo "✅ Archived to: $archive_file"
}

# Main command dispatcher
case "${1:-}" in
    log)
        log_event "$2" "$3" "$4" "$5" "$6"
        ;;
    query)
        query_events "$2" "$3"
        ;;
    replay)
        replay_task "$2"
        ;;
    export)
        export_audit "$2"
        ;;
    rotate)
        rotate_log
        ;;
    *)
        echo "Usage: $0 {log|query|replay|export|rotate} [options]"
        echo ""
        echo "Commands:"
        echo "  log <type> <task_id> <ai_name> <details> [status]  - Log event"
        echo "  query <filter> [param]                             - Query events"
        echo "    Filters: all, task <id>, ai <name>, errors, recent [count], stats"
        echo "  replay <task_id>                                   - Replay task history"
        echo "  export [file]                                      - Export to JSON"
        echo "  rotate                                             - Archive and rotate log"
        exit 1
        ;;
esac
