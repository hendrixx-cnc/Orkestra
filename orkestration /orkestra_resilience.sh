#!/bin/bash
# OrKeStra - Advanced Resilience System
# Exponential backoff, auto-failover, circuit breakers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CIRCUIT_BREAKER_FILE="$SCRIPT_DIR/circuit_breakers.json"
RETRY_LOG="$SCRIPT_DIR/logs/retry_attempts.log"

# Initialize circuit breaker file
if [ ! -f "$CIRCUIT_BREAKER_FILE" ]; then
    cat > "$CIRCUIT_BREAKER_FILE" << 'EOF'
{
  "circuit_breakers": {
    "claude": {"status": "closed", "failures": 0, "last_failure": null},
    "chatgpt": {"status": "closed", "failures": 0, "last_failure": null},
    "grok": {"status": "closed", "failures": 0, "last_failure": null},
    "gemini": {"status": "closed", "failures": 0, "last_failure": null}
  },
  "thresholds": {
    "failure_threshold": 3,
    "timeout_seconds": 300,
    "half_open_wait": 60
  }
}
EOF
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$RETRY_LOG"
}

# Function: Exponential backoff
exponential_backoff() {
    local attempt=$1
    local max_attempts=5
    local base_delay=2
    
    if [ $attempt -ge $max_attempts ]; then
        log "Max retry attempts ($max_attempts) reached"
        return 1
    fi
    
    local delay=$((base_delay ** attempt))
    log "⏱️  Retry attempt $attempt/$max_attempts - waiting ${delay}s (exponential backoff)"
    sleep $delay
    return 0
}

# Function: Check circuit breaker status
check_circuit_breaker() {
    local ai_name="$1"
    local status=$(jq -r ".circuit_breakers.${ai_name}.status" "$CIRCUIT_BREAKER_FILE")
    
    if [ "$status" = "open" ]; then
        log "🔴 Circuit breaker OPEN for $ai_name - AI unavailable"
        return 1
    elif [ "$status" = "half_open" ]; then
        log "🟡 Circuit breaker HALF-OPEN for $ai_name - testing recovery"
        return 0
    else
        log "🟢 Circuit breaker CLOSED for $ai_name - AI available"
        return 0
    fi
}

# Function: Record failure
record_failure() {
    local ai_name="$1"
    local current_failures=$(jq -r ".circuit_breakers.${ai_name}.failures" "$CIRCUIT_BREAKER_FILE")
    local threshold=$(jq -r ".thresholds.failure_threshold" "$CIRCUIT_BREAKER_FILE")
    local new_failures=$((current_failures + 1))
    
    log "❌ Recording failure for $ai_name (${new_failures}/${threshold})"
    
    # Update failure count and timestamp
    jq ".circuit_breakers.${ai_name}.failures = $new_failures | \
        .circuit_breakers.${ai_name}.last_failure = \"$(date -Iseconds)\"" \
        "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp"
    mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
    
    # Open circuit breaker if threshold exceeded
    if [ $new_failures -ge $threshold ]; then
        log "🔴 Opening circuit breaker for $ai_name (threshold exceeded)"
        jq ".circuit_breakers.${ai_name}.status = \"open\"" \
            "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp"
        mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
        return 1
    fi
    
    return 0
}

# Function: Record success
record_success() {
    local ai_name="$1"
    
    log "✅ Recording success for $ai_name - resetting failure count"
    
    jq ".circuit_breakers.${ai_name}.failures = 0 | \
        .circuit_breakers.${ai_name}.status = \"closed\"" \
        "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp"
    mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
}

# Function: Auto-failover to different AI
auto_failover() {
    local failed_ai="$1"
    local task_id="$2"
    local task_type="$3"
    
    log "🔄 Auto-failover initiated for $failed_ai on Task #$task_id"
    
    # AI priority order for different task types
    declare -A FAILOVER_MAP=(
        ["claude"]="chatgpt grok gemini"
        ["chatgpt"]="claude grok gemini"
        ["grok"]="chatgpt claude gemini"
        ["gemini"]="claude chatgpt grok"
    )
    
    local candidates="${FAILOVER_MAP[$failed_ai]}"
    
    for candidate_ai in $candidates; do
        if check_circuit_breaker "$candidate_ai"; then
            log "✅ Failing over to: $candidate_ai"
            
            # Reassign task in TASK_QUEUE.json
            jq ".queue = [.queue[] | if .id == $task_id then .assigned_to = \"$candidate_ai\" | .failover_from = \"$failed_ai\" else . end]" \
                "$SCRIPT_DIR/TASK_QUEUE.json" > "${SCRIPT_DIR}/TASK_QUEUE.json.tmp"
            mv "${SCRIPT_DIR}/TASK_QUEUE.json.tmp" "$SCRIPT_DIR/TASK_QUEUE.json"
            
            echo "$candidate_ai"
            return 0
        fi
    done
    
    log "❌ No available AI for failover"
    return 1
}

# Function: Try circuit breaker recovery
try_recovery() {
    local ai_name="$1"
    local wait_time=$(jq -r ".thresholds.half_open_wait" "$CIRCUIT_BREAKER_FILE")
    local last_failure=$(jq -r ".circuit_breakers.${ai_name}.last_failure" "$CIRCUIT_BREAKER_FILE")
    
    if [ "$last_failure" = "null" ]; then
        return 0
    fi
    
    local last_failure_ts=$(date -d "$last_failure" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$last_failure" +%s 2>/dev/null)
    local current_ts=$(date +%s)
    local elapsed=$((current_ts - last_failure_ts))
    
    if [ $elapsed -ge $wait_time ]; then
        log "🟡 Trying recovery for $ai_name (half-open state)"
        jq ".circuit_breakers.${ai_name}.status = \"half_open\"" \
            "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp"
        mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
        return 0
    fi
    
    return 1
}

# Function: Execute with resilience
execute_with_resilience() {
    local ai_name="$1"
    local task_id="$2"
    local max_retries=3
    local attempt=0
    
    log "🎯 Executing Task #$task_id with $ai_name (resilient mode)"
    
    while [ $attempt -lt $max_retries ]; do
        # Check circuit breaker
        if ! check_circuit_breaker "$ai_name"; then
            # Try recovery
            if try_recovery "$ai_name"; then
                log "Attempting recovery execution..."
            else
                # Auto-failover
                local new_ai=$(auto_failover "$ai_name" "$task_id" "any")
                if [ -n "$new_ai" ]; then
                    ai_name="$new_ai"
                else
                    log "❌ Task #$task_id failed - no AI available"
                    return 1
                fi
            fi
        fi
        
        # Attempt execution
        log "Attempt $(($attempt + 1))/$max_retries for $ai_name"
        
        if bash "$SCRIPT_DIR/${ai_name}_agent.sh" execute "$task_id" 2>&1; then
            record_success "$ai_name"
            log "✅ Task #$task_id completed successfully"
            return 0
        else
            log "❌ Attempt $(($attempt + 1)) failed"
            record_failure "$ai_name"
            
            attempt=$((attempt + 1))
            if [ $attempt -lt $max_retries ]; then
                exponential_backoff $attempt || break
            fi
        fi
    done
    
    log "❌ Task #$task_id failed after $max_retries attempts"
    
    # Final failover attempt
    local new_ai=$(auto_failover "$ai_name" "$task_id" "any")
    if [ -n "$new_ai" ]; then
        log "🔄 Final failover attempt with $new_ai"
        if bash "$SCRIPT_DIR/${new_ai}_agent.sh" execute "$task_id" 2>&1; then
            record_success "$new_ai"
            return 0
        fi
    fi
    
    return 1
}

# Function: Show circuit breaker status
show_status() {
    echo "🎼 OrKeStra - Circuit Breaker Status"
    echo "======================================"
    jq -r '.circuit_breakers | to_entries[] | "[\(.value.status | ascii_upcase)] \(.key): \(.value.failures) failures"' \
        "$CIRCUIT_BREAKER_FILE"
}

# Function: Reset circuit breaker
reset_breaker() {
    local ai_name="$1"
    log "🔄 Resetting circuit breaker for $ai_name"
    
    jq ".circuit_breakers.${ai_name}.status = \"closed\" | \
        .circuit_breakers.${ai_name}.failures = 0 | \
        .circuit_breakers.${ai_name}.last_failure = null" \
        "$CIRCUIT_BREAKER_FILE" > "${CIRCUIT_BREAKER_FILE}.tmp"
    mv "${CIRCUIT_BREAKER_FILE}.tmp" "$CIRCUIT_BREAKER_FILE"
    
    log "✅ Circuit breaker reset for $ai_name"
}

# Main command dispatcher
case "${1:-help}" in
    execute)
        if [ $# -lt 3 ]; then
            echo "Usage: $0 execute <ai_name> <task_id>"
            exit 1
        fi
        execute_with_resilience "$2" "$3"
        ;;
    check)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 check <ai_name>"
            exit 1
        fi
        check_circuit_breaker "$2"
        ;;
    reset)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 reset <ai_name>"
            exit 1
        fi
        reset_breaker "$2"
        ;;
    status)
        show_status
        ;;
    *)
        echo "OrKeStra - Resilience System"
        echo ""
        echo "Usage: $0 {execute|check|reset|status} [options]"
        echo ""
        echo "Commands:"
        echo "  execute <ai_name> <task_id>  - Execute with exponential backoff + failover"
        echo "  check <ai_name>               - Check circuit breaker status"
        echo "  reset <ai_name>               - Reset circuit breaker"
        echo "  status                        - Show all circuit breakers"
        echo ""
        echo "Features:"
        echo "  - Exponential backoff (2^n seconds)"
        echo "  - Auto-failover to different AI"
        echo "  - Circuit breakers (3 failures = open)"
        echo "  - Automatic recovery attempts"
        ;;
esac
