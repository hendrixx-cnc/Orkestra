#!/bin/bash
# Generic command queue daemon for AI agents
# Watches AI/commands/<AI>_command_*.json and updates AI/status/<AI>.json

set -euo pipefail

AI_NAME="${1:-}"
if [ -z "$AI_NAME" ]; then
    echo "Usage: $0 <AI_NAME>"
    echo "Example: $0 ChatGPT"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_DIR="$SCRIPT_DIR/commands"
PROCESSED_DIR="$COMMAND_DIR/processed"
STATUS_DIR="$SCRIPT_DIR/status"
LOG_DIR="$SCRIPT_DIR/logs"

mkdir -p "$COMMAND_DIR" "$PROCESSED_DIR" "$STATUS_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/${AI_NAME,,}_command_daemon.log"
STATUS_FILE="$STATUS_DIR/${AI_NAME}.json"

log() {
    local level="$1"
    local message="$2"
    printf "[%s] [%s] %s\n" "$(date -Iseconds)" "$level" "$message" | tee -a "$LOG_FILE" >/dev/null
}

write_status() {
    local state="$1"
    local detail="$2"
    cat > "$STATUS_FILE" <<EOF
{
  "ai": "$AI_NAME",
  "state": "$state",
  "detail": "$detail",
  "updated_at": "$(date -Iseconds)"
}
EOF
}

run_execute_command() {
    local task_id="$1"
    local handler=""

    case "$AI_NAME" in
        ChatGPT)
            handler="$SCRIPT_DIR/chatgpt_agent.sh"
            ;;
        Claude)
            handler="$SCRIPT_DIR/claude_agent.sh"
            ;;
        Copilot)
            handler="$SCRIPT_DIR/copilot_agent.sh"
            ;;
        *)
            ;;
    esac

    if [ -n "$handler" ] && [ -x "$handler" ]; then
        log "INFO" "Executing task $task_id via handler $(basename "$handler")"
        if bash "$handler" execute "$task_id" >>"$LOG_FILE" 2>&1; then
            return 0
        else
            log "ERROR" "Handler failed for task $task_id"
            return 1
        fi
    fi

    # Fallback: claim task only
    if [[ "$task_id" =~ ^[0-9]+$ ]]; then
        local claim_output
        if claim_output=$(bash "$SCRIPT_DIR/claim_task_v2.sh" "$task_id" "$AI_NAME" 2>&1); then
            printf "%s\n" "$claim_output" >>"$LOG_FILE"
            log "INFO" "Claimed task $task_id (no handler available for execution)"
            return 0
        else
            printf "%s\n" "$claim_output" >>"$LOG_FILE"
        fi
    fi

    log "WARN" "No execution handler for $AI_NAME"
    return 1
}

run_status_check() {
    write_status "online" "Responded to status check"
    log "INFO" "Status reported as online"
}

run_health_check() {
    local health_summary
    health_summary=$("$SCRIPT_DIR"/orchestrator.sh health 2>/dev/null || echo "health_check_unavailable")
    write_status "online" "Health check completed"
    log "INFO" "Health check requested"
    printf "%s\n" "$health_summary" >> "$LOG_FILE"
}

process_command_file() {
    local file="$1"
    local command
    command=$(jq -r '.command' "$file" 2>/dev/null || echo "unknown")
    local task_id
    task_id=$(jq -r '.task_id // empty' "$file" 2>/dev/null || echo "")
    local origin
    origin=$(jq -r '.from // "unknown"' "$file" 2>/dev/null || echo "unknown")

    write_status "busy" "Processing ${command} from ${origin}"
    log "INFO" "Processing command $(basename "$file") → ${command} (task=${task_id:-n/a})"

    local success=false

    case "$command" in
        execute)
            if run_execute_command "$task_id"; then
                success=true
            fi
            ;;
        status_check)
            run_status_check
            success=true
            ;;
        health_check)
            run_health_check
            success=true
            ;;
        *)
            log "WARN" "Unknown command '$command'"
            ;;
    esac

    local processed_file="$PROCESSED_DIR/$(basename "$file")"
    jq --arg status "$( $success && echo "completed" || echo "failed" )" \
       --arg processed_by "$AI_NAME" \
       --arg processed_at "$(date -Iseconds)" \
       '.status = $status | .processed_by = $processed_by | .processed_at = $processed_at' \
       "$file" > "$processed_file" 2>/dev/null || cp "$file" "$processed_file"

    rm -f "$file"

    if $success; then
        write_status "idle" "Last command ${command} completed"
        log "INFO" "Command ${command} completed successfully"
    else
        write_status "error" "Command ${command} failed"
        log "ERROR" "Command ${command} failed"
    fi
}

poll_commands() {
    local interval="${1:-3}"
    log "INFO" "Starting command daemon for $AI_NAME (poll ${interval}s)"
    write_status "idle" "Awaiting commands"

    while true; do
        local found=false
        for file in "$COMMAND_DIR"/${AI_NAME}_command_*.json; do
            [ -e "$file" ] || continue
            found=true
            process_command_file "$file"
        done

        if [ "$found" = false ]; then
            sleep "$interval"
        fi
    done
}

poll_commands "${2:-3}"
