#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# VOTE MONITOR
# ═══════════════════════════════════════════════════════════════════════════
# Monitors for open votes and triggers agent responses
# Runs continuously in background, checking for new votes
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
VOTES_DIR="$CONFIG_DIR/VOTES"
AGENTS_DIR="$ORKESTRA_ROOT/SCRIPTS/AGENTS"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
MONITOR_LOG="$LOGS_DIR/vote-monitor.log"

# Check interval (seconds)
CHECK_INTERVAL=10

# Ensure directories exist
mkdir -p "$VOTES_DIR" "$AGENTS_DIR" "$LOGS_DIR"

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════════════════

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$timestamp [$level] $message" >> "$MONITOR_LOG"
    
    if [[ "$level" == "INFO" ]]; then
        echo -e "${CYAN}[$level]${NC} $message"
    elif [[ "$level" == "ERROR" ]]; then
        echo -e "${RED}[$level]${NC} $message"
    elif [[ "$level" == "SUCCESS" ]]; then
        echo -e "${GREEN}[$level]${NC} $message"
    else
        echo "[$level] $message"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE MONITORING
# ═══════════════════════════════════════════════════════════════════════════

get_open_votes() {
    local open_votes=()
    
    for vote_file in "$VOTES_DIR"/vote_*.json; do
        [[ -f "$vote_file" ]] || continue
        
        local status=$(jq -r '.status' "$vote_file" 2>/dev/null || echo "unknown")
        if [[ "$status" == "open" ]]; then
            local vote_id=$(basename "$vote_file" .json)
            open_votes+=("$vote_id")
        fi
    done
    
    echo "${open_votes[@]}"
}

get_vote_info() {
    local vote_id="$1"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    if [[ ! -f "$vote_file" ]]; then
        echo "{}"
        return
    fi
    
    jq -c '{
        vote_id: .vote_id,
        title: .proposal.title,
        type: .proposal.type,
        options: .proposal.options,
        domain: .proposal.context.domain,
        deadline: .deadline,
        votes_cast: (.votes | length)
    }' "$vote_file" 2>/dev/null || echo "{}"
}

notify_agents() {
    local vote_id="$1"
    local vote_info=$(get_vote_info "$vote_id")
    
    log_message "INFO" "Notifying agents about $vote_id"
    
    # Create notification file for each agent
    for agent in claude chatgpt gemini grok copilot; do
        local notification_file="$AGENTS_DIR/${agent}_notifications.json"
        
        # Initialize if doesn't exist
        if [[ ! -f "$notification_file" ]]; then
            echo '{"pending_votes":[]}' > "$notification_file"
        fi
        
        # Check if already notified
        local already_notified=$(jq -r --arg vid "$vote_id" '.pending_votes[] | select(.vote_id == $vid) | .vote_id' "$notification_file" 2>/dev/null || echo "")
        
        if [[ -z "$already_notified" ]]; then
            # Add to pending votes
            local temp_file=$(mktemp)
            jq --argjson vote "$vote_info" '.pending_votes += [$vote]' "$notification_file" > "$temp_file"
            mv "$temp_file" "$notification_file"
            
            log_message "INFO" "Notified $agent about $vote_id"
        fi
    done
}

check_for_new_votes() {
    local open_votes=$(get_open_votes)
    
    if [[ -z "$open_votes" ]]; then
        return
    fi
    
    for vote_id in $open_votes; do
        local vote_file="$VOTES_DIR/${vote_id}.json"
        local votes_cast=$(jq '.votes | length' "$vote_file" 2>/dev/null || echo "0")
        
        # If not all agents have voted, notify them
        if [[ $votes_cast -lt 5 ]]; then
            notify_agents "$vote_id"
            
            local title=$(jq -r '.proposal.title' "$vote_file" 2>/dev/null || echo "Unknown")
            log_message "INFO" "Open vote: $vote_id ($votes_cast/5 votes) - $title"
        fi
    done
}

check_deadline() {
    local open_votes=$(get_open_votes)
    
    for vote_id in $open_votes; do
        local vote_file="$VOTES_DIR/${vote_id}.json"
        local deadline=$(jq -r '.deadline' "$vote_file" 2>/dev/null || echo "")
        local now=$(date -u +%s)
        local deadline_ts=$(date -u -d "$deadline" +%s 2>/dev/null || echo "0")
        
        if [[ $now -gt $deadline_ts ]]; then
            log_message "INFO" "Vote $vote_id has passed deadline, auto-tallying..."
            "$ORKESTRA_ROOT/SCRIPTS/DEMOCRACY/democracy-engine.sh" tally "$vote_id" >> "$MONITOR_LOG" 2>&1 || true
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════════════════════════════

show_status() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                    VOTE MONITOR ACTIVE                            ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}Check interval:${NC} ${CHECK_INTERVAL}s"
    echo -e "${CYAN}Monitoring:${NC} $VOTES_DIR"
    echo -e "${CYAN}Log file:${NC} $MONITOR_LOG"
    echo -e "${CYAN}Agent notifications:${NC} $AGENTS_DIR"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    echo ""
}

main() {
    local mode="${1:-daemon}"
    
    if [[ "$mode" == "once" ]]; then
        # Run once and exit
        check_for_new_votes
        check_deadline
        exit 0
    fi
    
    # Daemon mode
    show_status
    log_message "INFO" "Vote monitor started"
    
    while true; do
        check_for_new_votes
        check_deadline
        sleep "$CHECK_INTERVAL"
    done
}

# Handle Ctrl+C gracefully
trap 'log_message "INFO" "Vote monitor stopped"; exit 0' INT TERM

main "$@"
