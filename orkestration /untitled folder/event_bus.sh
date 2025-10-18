#!/bin/bash
# Simple file-based event bus for AI orchestration
# Usage:
#   ./event_bus.sh emit task_completed <task_id> [message]
#   ./event_bus.sh process                # process pending events once
#   ./event_bus.sh watch                  # continuous processing loop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVENT_DIR="$SCRIPT_DIR/events"
PROCESSED_DIR="$EVENT_DIR/processed"
LOG_DIR="$SCRIPT_DIR/logs"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

mkdir -p "$EVENT_DIR" "$PROCESSED_DIR" "$LOG_DIR"

log() {
    local level="$1"
    local message="$2"
    printf "[%s] [%s] %s\n" "$(date -Iseconds)" "$level" "$message" | tee -a "$LOG_DIR/event_bus.log" >/dev/null
}

emit_event() {
    local event_type="$1"
    local task_id="${2:-}"
    local note="${3:-}"

    local timestamp="$(date -Iseconds)"
    local file_suffix="$(date +%s%3N)"
    local event_file="$EVENT_DIR/${event_type}_${file_suffix}.json"

    cat > "$event_file" <<EOF
{
  "type": "$event_type",
  "timestamp": "$timestamp",
  "task_id": ${task_id:-null},
  "note": ${note:+$(printf '%s' "$note" | jq -Rs .)},
  "processed": false
}
EOF

    log "INFO" "Emitted event ${event_type} (task_id=${task_id:-null})"
}

dependencies_completed() {
    local target_task="$1"

    jq --argjson target "$target_task" '
      . as $root
      | ($root.queue[] | select(.id == $target) | .dependencies) as $deps
      | if ($deps == null or ($deps | length == 0)) then
            true
        else
            ( $deps | all(. as $dep | ($root.queue[] | select(.id == $dep) | .status) == "completed") )
        end
    ' "$TASK_QUEUE"
}

auto_assign_dependents() {
    local completed_task="$1"

    local ready_tasks
    ready_tasks=$(jq --argjson completed "$completed_task" '
        . as $root
        | $root.queue[]
        | select(.status == "pending")
        | select(.dependencies != null and (.dependencies | index($completed)))
        | select(
            (.dependencies == null) or
            (.dependencies | length == 0) or
            (all(.dependencies[]; ($root.queue[] | select(.id == .) | .status) == "completed"))
          )
        | .id
    ' "$TASK_QUEUE")

    if [ -z "$ready_tasks" ]; then
        log "DEBUG" "No dependent tasks ready after completion of task $completed_task"
        return 0
    fi

    log "INFO" "Auto-assigning unlocked tasks after completion of $completed_task: $(echo "$ready_tasks" | tr '\n' ' ')"

    while read -r task_id; do
        [ -n "$task_id" ] || continue
        if bash "$SCRIPT_DIR/task_coordinator.sh" assign "$task_id" >/dev/null 2>&1; then
            log "INFO" "Task $task_id auto-assigned successfully"
        else
            log "WARN" "Task $task_id could not be auto-assigned"
        fi
    done <<< "$ready_tasks"
}

process_event_file() {
    local event_file="$1"

    local event_type
    event_type=$(jq -r '.type' "$event_file")

    case "$event_type" in
        task_completed)
            local completed_task
            completed_task=$(jq -r '.task_id' "$event_file")
            if [[ "$completed_task" =~ ^[0-9]+$ ]]; then
                auto_assign_dependents "$completed_task"
            else
                log "WARN" "task_completed event missing valid task_id in $event_file"
            fi
            ;;
        task_claimed)
            # Future use: notify other agents
            log "DEBUG" "Received task_claimed event (no action yet)"
            ;;
        *)
            log "WARN" "Unknown event type '$event_type' in $event_file"
            ;;
    esac

    jq '.processed = true | .processed_at = "'"$(date -Iseconds)"'"' "$event_file" > "$PROCESSED_DIR/$(basename "$event_file")"
    rm -f "$event_file"
}

process_events_once() {
    local found=false
    for event_file in "$EVENT_DIR"/*.json; do
        [ -e "$event_file" ] || continue
        found=true
        log "INFO" "Processing event $(basename "$event_file")"
        process_event_file "$event_file"
    done

    if [ "$found" = false ]; then
        log "DEBUG" "No pending events to process"
    fi
}

watch_events() {
    log "INFO" "Starting event bus watcher (polling every ${1:-5}s)"
    local interval="${1:-5}"
    while true; do
        process_events_once
        sleep "$interval"
    done
}

case "${1:-help}" in
    emit)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 emit <event_type> [task_id] [note]"
            exit 1
        fi
        emit_event "$2" "${3:-}" "${4:-}"
        ;;
    process)
        process_events_once
        ;;
    watch)
        watch_events "${2:-5}"
        ;;
    *)
        cat <<'HELP'
Event Bus Utility
Usage:
  event_bus.sh emit <event_type> [task_id] [note]  Emit a new event
  event_bus.sh process                            Process all pending events once
  event_bus.sh watch [interval]                   Continuous processing loop
HELP
        ;;
esac
