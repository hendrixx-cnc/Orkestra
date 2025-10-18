#!/bin/bash
# Advanced Resilience System for Orchestra
# Implements: Exponential Backoff, Auto-Failover, Circuit Breakers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
RESILIENCE_STATE="$SCRIPT_DIR/.resilience_state.json"
LOG_FILE="$SCRIPT_DIR/logs/resilience.log"

# Initialize resilience state if not exists
if [ ! -f "$RESILIENCE_STATE" ]; then
    cat > "$RESILIENCE_STATE" << 'EOF'
{
  "circuit_breakers": {
    "claude": {"state": "closed", "failures": 0, "last_failure": null},
    "chatgpt": {"state": "closed", "failures": 0, "last_failure": null},
    "grok": {"state": "closed", "failures": 0, "last_failure": null},
    "gemini": {"state": "closed", "failures": 0, "last_failure": null}
  },
  "backoff_multipliers": {
    "claude": 1,
    "chatgpt": 1,
    "grok": 1,
    "gemini": 1
  },
  "failover_history": []
}
EOF
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Exponential Backoff Calculator
# Usage: calculate_backoff <ai_name> <retry_attempt>
calculate_backoff() {
    local ai_name="$1"
    local retry_attempt="${2:-1}"
    local base_delay=2  # 2 seconds base
    
    # Exponential: 2^retry * base_delay
    local delay=$((base_delay * (2 ** (retry_attempt - 1))))
    
    # Cap at 5 minutes (300 seconds)
    if [ $delay -gt 300 ]; then
        delay=300
    fi
    
    echo $delay
}

# Apply exponential backoff
# Usage: apply_backoff <ai_name> <retry_attempt>
apply_backoff() {
    local ai_name="$1"
    local retry_attempt="$2"
    local delay=$(calculate_backoff "$ai_name" "$retry_attempt")
    
    log "⏳ Applying exponential backoff for $ai_name (attempt $retry_attempt): ${delay}s"
    sleep "$delay"
}

# Circuit Breaker: Check if AI is available
# Returns 0 if closed (available), 1 if open (unavailable)
check_circuit_breaker() {
    local ai_name="$1"
    local state=$(jq -r ".circuit_breakers.\"$ai_name\".state" "$RESILIENCE_STATE")
    local failures=$(jq -r ".circuit_breakers.\"$ai_name\".failures" "$RESILIENCE_STATE")
    local last_failure=$(jq -r ".circuit_breakers.\"$ai_name\".last_failure // \"null\"" "$RESILIENCE_STATE")
    
    # If circuit is open, check if cooldown period passed (5 minutes)
    if [ "$state" = "open" ]; then
        if [ "$last_failure" != "null" ]; then
            local now=$(date +%s)
            local last_fail_time=$(date -d "$last_failure" +%s 2>/dev/null || echo 0)
            local cooldown=300  # 5 minutes
            
            if [ $((now - last_fail_time)) -gt $cooldown ]; then
                log "🔄 Circuit breaker for $ai_name: half-open (testing)"
                update_circuit_state "$ai_name" "half-open"
                return 0
            else
                log "🚫 Circuit breaker for $ai_name: OPEN (failures: $failures)"
                return 1
            fi
        fi
        return 1
    fi
    
    # Closed or half-open: allow request
    return 0
}

# Update circuit breaker state
update_circuit_state() {
    local ai_name="$1"
    local new_state="$2"
    local timestamp=$(date -Iseconds)
    
    jq ".circuit_breakers.\"$ai_name\".state = \"$new_state\" | \
        .circuit_breakers.\"$ai_name\".last_failure = \"$timestamp\"" \
        "$RESILIENCE_STATE" > "$RESILIENCE_STATE.tmp"
    mv "$RESILIENCE_STATE.tmp" "$RESILIENCE_STATE"
    
    log "🔧 Circuit breaker for $ai_name: $new_state"
}

# Record failure
record_failure() {
    local ai_name="$1"
    local task_id="${2:-unknown}"
    local error="${3:-unknown}"
    local timestamp=$(date -Iseconds)
    
    # Increment failure count
    jq ".circuit_breakers.\"$ai_name\".failures += 1 | \
        .circuit_breakers.\"$ai_name\".last_failure = \"$timestamp\"" \
        "$RESILIENCE_STATE" > "$RESILIENCE_STATE.tmp"
    mv "$RESILIENCE_STATE.tmp" "$RESILIENCE_STATE"
    
    local failures=$(jq -r ".circuit_breakers.\"$ai_name\".failures" "$RESILIENCE_STATE")
    
    # Open circuit if failures >= 3
    if [ "$failures" -ge 3 ]; then
        update_circuit_state "$ai_name" "open"
        log "⚠️  Circuit breaker OPENED for $ai_name (3+ failures)"
    fi
    
    log "❌ Failure recorded for $ai_name: Task #$task_id - $error"
}

# Record success
record_success() {
    local ai_name="$1"
    
    # Reset failures and close circuit
    jq ".circuit_breakers.\"$ai_name\".failures = 0 | \
        .circuit_breakers.\"$ai_name\".state = \"closed\"" \
        "$RESILIENCE_STATE" > "$RESILIENCE_STATE.tmp"
    mv "$RESILIENCE_STATE.tmp" "$RESILIENCE_STATE"
    
    log "✅ Success recorded for $ai_name (circuit breaker reset)"
}

# Auto-Failover: Find alternative AI for task
# Usage: find_failover_ai <original_ai> <task_id>
find_failover_ai() {
    local original_ai="$1"
    local task_id="$2"
    
    # Get task specialties/type
    local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"general\"" "$TASK_QUEUE")
    
    # Define AI capabilities priority
    declare -A AI_PRIORITIES
    case "$task_type" in
        "content"|"copywriting"|"marketing")
            AI_PRIORITIES=(["chatgpt"]=1 ["claude"]=2 ["grok"]=3 ["gemini"]=4)
            ;;
        "creative"|"design"|"svg")
            AI_PRIORITIES=(["grok"]=1 ["chatgpt"]=2 ["claude"]=3 ["gemini"]=4)
            ;;
        "firebase"|"cloud"|"database")
            AI_PRIORITIES=(["gemini"]=1 ["chatgpt"]=2 ["claude"]=3 ["grok"]=4)
            ;;
        "review"|"documentation"|"ux")
            AI_PRIORITIES=(["claude"]=1 ["chatgpt"]=2 ["grok"]=3 ["gemini"]=4)
            ;;
        *)
            AI_PRIORITIES=(["claude"]=1 ["chatgpt"]=2 ["grok"]=3 ["gemini"]=4)
            ;;
    esac
    
    # Find best available AI (circuit breaker closed)
    for ai in claude chatgpt grok gemini; do
        if [ "$ai" != "$original_ai" ]; then
            if check_circuit_breaker "$ai"; then
                log "🔄 Failover: $original_ai → $ai for Task #$task_id"
                
                # Record failover
                jq ".failover_history += [{
                    \"timestamp\": \"$(date -Iseconds)\",
                    \"task_id\": $task_id,
                    \"from\": \"$original_ai\",
                    \"to\": \"$ai\",
                    \"reason\": \"circuit_breaker_open\"
                }]" "$RESILIENCE_STATE" > "$RESILIENCE_STATE.tmp"
                mv "$RESILIENCE_STATE.tmp" "$RESILIENCE_STATE"
                
                echo "$ai"
                return 0
            fi
        fi
    done
    
    log "⚠️  No failover AI available for Task #$task_id"
    return 1
}

# Reassign task with failover
reassign_task_with_failover() {
    local task_id="$1"
    local original_ai="$2"
    
    local new_ai=$(find_failover_ai "$original_ai" "$task_id")
    
    if [ -n "$new_ai" ]; then
        # Update task assignment in queue
        jq ".queue = [.queue[] | if .id == $task_id then .assigned_to = \"$new_ai\" | .failover_from = \"$original_ai\" else . end]" \
            "$TASK_QUEUE" > "$TASK_QUEUE.tmp"
        mv "$TASK_QUEUE.tmp" "$TASK_QUEUE"
        
        log "✅ Task #$task_id reassigned: $original_ai → $new_ai"
        echo "$new_ai"
        return 0
    else
        log "❌ Could not reassign Task #$task_id (no AI available)"
        return 1
    fi
}

# Execute task with resilience (exponential backoff + failover)
execute_with_resilience() {
    local task_id="$1"
    local ai_name="$2"
    local max_retries=3
    local retry=1
    
    while [ $retry -le $max_retries ]; do
        log "🎯 Attempt $retry/$max_retries: Executing Task #$task_id with $ai_name"
        
        # Check circuit breaker
        if ! check_circuit_breaker "$ai_name"; then
            log "⚠️  Circuit breaker open for $ai_name, attempting failover..."
            local new_ai=$(reassign_task_with_failover "$task_id" "$ai_name")
            if [ -n "$new_ai" ]; then
                ai_name="$new_ai"
            else
                return 1
            fi
        fi
        
        # Execute task
        if bash "$SCRIPT_DIR/${ai_name}_agent.sh" execute "$task_id" 2>&1; then
            record_success "$ai_name"
            log "✅ Task #$task_id completed successfully by $ai_name"
            return 0
        else
            local error="Execution failed (attempt $retry)"
            record_failure "$ai_name" "$task_id" "$error"
            
            if [ $retry -lt $max_retries ]; then
                apply_backoff "$ai_name" "$retry"
                ((retry++))
            else
                log "❌ Task #$task_id failed after $max_retries attempts"
                
                # Try failover as last resort
                log "🔄 Attempting final failover for Task #$task_id..."
                local new_ai=$(reassign_task_with_failover "$task_id" "$ai_name")
                if [ -n "$new_ai" ]; then
                    log "🎯 Final attempt with failover AI: $new_ai"
                    if bash "$SCRIPT_DIR/${new_ai}_agent.sh" execute "$task_id" 2>&1; then
                        record_success "$new_ai"
                        log "✅ Task #$task_id completed by failover AI: $new_ai"
                        return 0
                    fi
                fi
                
                return 1
            fi
        fi
    done
}

# Reset circuit breaker manually
reset_circuit_breaker() {
    local ai_name="$1"
    
    jq ".circuit_breakers.\"$ai_name\" = {\"state\": \"closed\", \"failures\": 0, \"last_failure\": null}" \
        "$RESILIENCE_STATE" > "$RESILIENCE_STATE.tmp"
    mv "$RESILIENCE_STATE.tmp" "$RESILIENCE_STATE"
    
    log "🔧 Circuit breaker reset for $ai_name"
}

# Show resilience status
show_status() {
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║          Orchestra Resilience System Status           ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "Circuit Breakers:"
    jq -r '.circuit_breakers | to_entries[] | "  \(.key): \(.value.state) (failures: \(.value.failures))"' "$RESILIENCE_STATE"
    echo ""
    echo "Recent Failovers:"
    jq -r '.failover_history[-5:] | .[] | "  [\(.timestamp)] Task #\(.task_id): \(.from) → \(.to)"' "$RESILIENCE_STATE"
}

# Main command dispatcher
case "${1:-status}" in
    execute)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 execute <task_id> <ai_name>"
            exit 1
        fi
        execute_with_resilience "$2" "$3"
        ;;
    record_failure)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 record_failure <ai_name> <task_id> [error]"
            exit 1
        fi
        record_failure "$2" "$3" "${4:-unknown}"
        ;;
    record_success)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 record_success <ai_name>"
            exit 1
        fi
        record_success "$2"
        ;;
    reset)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 reset <ai_name>"
            exit 1
        fi
        reset_circuit_breaker "$2"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Orchestra Resilience System"
        echo ""
        echo "Usage: $0 {execute|record_failure|record_success|reset|status} [options]"
        echo ""
        echo "Commands:"
        echo "  execute <task_id> <ai_name>          - Execute task with resilience"
        echo "  record_failure <ai> <task> [error]   - Record AI failure"
        echo "  record_success <ai>                   - Record AI success"
        echo "  reset <ai_name>                       - Reset circuit breaker"
        echo "  status                                - Show system status"
        exit 1
        ;;
esac
