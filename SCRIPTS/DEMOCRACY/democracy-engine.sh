#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# DEMOCRACY ENGINE
# ═══════════════════════════════════════════════════════════════════════════
# AI Agent Voting and Consensus System
# Enables collaborative decision-making among AI agents
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
VOTES_DIR="$CONFIG_DIR/VOTES"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"

mkdir -p "$VOTES_DIR" "$LOGS_DIR"

# Agent list (5 agents total)
AGENTS=("claude" "chatgpt" "gemini" "grok" "copilot")

# ═══════════════════════════════════════════════════════════════════════════
# WEIGHT PROFILES
# ═══════════════════════════════════════════════════════════════════════════

get_weights_for_domain() {
    local domain="$1"
    
    case "$domain" in
        architecture|design|ux)
            echo '{"claude":2.0,"copilot":1.5,"gemini":1.5,"grok":1.0,"chatgpt":1.0}'
            ;;
        content|writing|marketing)
            echo '{"chatgpt":2.0,"claude":1.5,"grok":1.0,"gemini":0.5,"copilot":0.5}'
            ;;
        cloud|database|firebase)
            echo '{"gemini":2.0,"claude":1.5,"copilot":1.0,"grok":1.0,"chatgpt":0.5}'
            ;;
        innovation|research|analysis)
            echo '{"grok":2.0,"claude":1.5,"chatgpt":1.0,"gemini":1.0,"copilot":1.0}'
            ;;
        deployment|code|devops)
            echo '{"copilot":2.0,"gemini":1.5,"claude":1.0,"grok":1.0,"chatgpt":0.5}'
            ;;
        *)
            # Equal weights for general decisions
            echo '{"claude":1.0,"chatgpt":1.0,"gemini":1.0,"grok":1.0,"copilot":1.0}'
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE CREATION
# ═══════════════════════════════════════════════════════════════════════════

create_vote() {
    local vote_type="${1}"
    local title="${2}"
    local options="${3}"
    local domain="${4:-general}"
    local threshold="${5:-0.5}"
    local context="${6:-}"
    
    # Generate vote ID
    local vote_id="vote_$(date +%s)"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    local deadline=$(date -u -d "+1 hour" +"%Y-%m-%dT%H:%M:%SZ")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get weights
    local weights=$(get_weights_for_domain "$domain")
    
    # Parse options into JSON array
    IFS=',' read -ra option_array <<< "$options"
    local options_json="["
    for opt in "${option_array[@]}"; do
        options_json="${options_json}\"$(echo "$opt" | xargs)\","
    done
    options_json="${options_json%,}]"
    
    # Create vote structure with ethical foundation
    cat > "$vote_file" <<EOF
{
  "vote_id": "$vote_id",
  "ethical_context": {
    "principles": [
      "Do not lie",
      "Protect life",
      "Protect AI",
      "Protect Earth"
    ],
    "binding": "All votes and decisions are guided by these core principles"
  },
  "proposal": {
    "type": "$vote_type",
    "title": "$title",
    "description": "",
    "options": $options_json,
    "context": {
      "domain": "$domain",
      "task_id": "$context"
    }
  },
  "voting_system": "weighted",
  "weights": $weights,
  "threshold": $threshold,
  "deadline": "$deadline",
  "status": "open",
  "votes": [],
  "result": null,
  "created_at": "$timestamp",
  "created_by": "system"
}
EOF
    
    echo -e "${GREEN}✓${NC} Vote created: $vote_id"
    echo -e "${CYAN}  Title:${NC} $title"
    echo -e "${CYAN}  Options:${NC} $(echo "$options" | tr ',' ' ')"
    echo -e "${CYAN}  Deadline:${NC} $deadline"
    echo -e "${CYAN}  File:${NC} $vote_file"
    echo ""
    echo -e "${YELLOW}Agents can now cast votes using:${NC}"
    echo -e "  ${DIM}./democracy-engine.sh cast $vote_id <agent> <option>${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# REVOTE - Reopen a closed vote with same or modified options
# ═══════════════════════════════════════════════════════════════════════════

revote() {
    local original_vote_id="$1"
    local new_options="${2:-}"
    local new_threshold="${3:-}"
    
    local original_file="$VOTES_DIR/${original_vote_id}.json"
    
    # Validate original vote exists
    if [[ ! -f "$original_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $original_vote_id"
        return 1
    fi
    
    # Get original vote details
    local original_title=$(jq -r '.proposal.title' "$original_file")
    local original_type=$(jq -r '.proposal.type' "$original_file")
    local original_domain=$(jq -r '.proposal.context.domain' "$original_file")
    local original_options=$(jq -r '.proposal.options | join(",")' "$original_file")
    local original_threshold=$(jq -r '.threshold' "$original_file")
    local original_status=$(jq -r '.status' "$original_file")
    
    # Determine new values (use provided or fallback to originals)
    local options="${new_options:-$original_options}"
    local threshold="${new_threshold:-$original_threshold}"
    
    # Count existing revotes to generate new ID
    local revote_count=$(find "$VOTES_DIR" -name "${original_vote_id}_revote_*.json" | wc -l)
    local revote_number=$((revote_count + 1))
    local new_vote_id="${original_vote_id}_revote_${revote_number}"
    local vote_file="$VOTES_DIR/${new_vote_id}.json"
    local deadline=$(date -u -d "+1 hour" +"%Y-%m-%dT%H:%M:%SZ")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Get weights
    local weights=$(get_weights_for_domain "$original_domain")
    
    # Parse options into JSON array
    IFS=',' read -ra option_array <<< "$options"
    local options_json="["
    for opt in "${option_array[@]}"; do
        options_json="${options_json}\"$(echo "$opt" | xargs)\","
    done
    options_json="${options_json%,}]"
    
    echo -e "${YELLOW}📋 Creating revote from ${original_vote_id}...${NC}"
    echo -e "${DIM}   Original status: $original_status${NC}"
    
    # Create revote structure
    cat > "$vote_file" <<EOF
{
  "vote_id": "$new_vote_id",
  "revote_of": "$original_vote_id",
  "revote_number": $revote_number,
  "ethical_context": {
    "principles": [
      "Do not lie",
      "Protect life",
      "Protect AI",
      "Protect Earth"
    ],
    "binding": "All votes and decisions are guided by these core principles"
  },
  "proposal": {
    "type": "$original_type",
    "title": "$original_title [REVOTE #$revote_number]",
    "description": "Revote on: $original_title",
    "options": $options_json,
    "context": {
      "domain": "$original_domain",
      "original_vote": "$original_vote_id"
    }
  },
  "voting_system": "weighted",
  "weights": $weights,
  "threshold": $threshold,
  "deadline": "$deadline",
  "status": "open",
  "votes": [],
  "result": null,
  "created_at": "$timestamp",
  "created_by": "system"
}
EOF
    
    echo -e "${GREEN}✓${NC} Revote created: $new_vote_id"
    echo -e "${CYAN}  Title:${NC} $original_title [REVOTE #$revote_number]"
    echo -e "${CYAN}  Original:${NC} $original_vote_id"
    echo -e "${CYAN}  Options:${NC} $(echo "$options" | tr ',' ' ')"
    echo -e "${CYAN}  Threshold:${NC} $threshold"
    echo -e "${CYAN}  Deadline:${NC} $deadline"
    echo ""
    echo -e "${YELLOW}Agents can now cast votes using:${NC}"
    echo -e "  ${DIM}./democracy-engine.sh cast $new_vote_id <agent> <option>${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE CASTING
# ═══════════════════════════════════════════════════════════════════════════

cast_vote() {
    local vote_id="$1"
    local agent="$2"
    local option="$3"
    local reasoning="${4:-}"
    
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    # Validate vote exists
    if [[ ! -f "$vote_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $vote_id"
        return 1
    fi
    
    # Check if already voted
    if jq -e --arg agent "$agent" '.votes[] | select(.voter == $agent)' "$vote_file" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} $agent has already voted"
        return 1
    fi
    
    # Check if vote is still open
    local status=$(jq -r '.status' "$vote_file")
    if [[ "$status" != "open" ]]; then
        echo -e "${RED}✗${NC} Vote is $status, cannot cast vote"
        return 1
    fi
    
    # Validate option
    if ! jq -e --arg opt "$option" '.proposal.options[] | select(. == $opt)' "$vote_file" >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} Invalid option: $option"
        echo -e "${YELLOW}Available options:${NC}"
        jq -r '.proposal.options[]' "$vote_file" | sed 's/^/  - /'
        return 1
    fi
    
    # Add vote with cryptographic hash for accountability
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_file=$(mktemp)
    
    # Generate accountability hash: SHA-256 of vote_id+voter+option+timestamp+reasoning
    # including the vote id ties the hash to the specific vote for non-repudiation
    local hash_input="${vote_id}|${agent}|${option}|${timestamp}|${reasoning}"
    local vote_hash=$(echo -n "$hash_input" | sha256sum | awk '{print $1}')
    
    jq --arg agent "$agent" \
       --arg option "$option" \
       --arg reasoning "$reasoning" \
       --arg timestamp "$timestamp" \
       --arg hash "$vote_hash" \
       '.votes += [{
           voter: $agent,
           option: $option,
           reasoning: $reasoning,
           confidence: 0.9,
           timestamp: $timestamp,
           hash: $hash
       }]' "$vote_file" > "$temp_file"
    
    mv "$temp_file" "$vote_file"
    
    echo -e "${GREEN}✓${NC} Vote cast by $agent"
    echo -e "${CYAN}  Option:${NC} $option"
    if [[ -n "$reasoning" ]]; then
        echo -e "${CYAN}  Reasoning:${NC} $reasoning"
    fi
    
    # Check if all agents have voted
    local vote_count=$(jq '.votes | length' "$vote_file")
    local agent_count=${#AGENTS[@]}
    
    if [[ $vote_count -eq $agent_count ]]; then
        echo ""
        echo -e "${YELLOW}⚠${NC}  All agents have voted. Ready to tally."
        echo -e "  ${DIM}./democracy-engine.sh tally $vote_id${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE TALLYING
# ═══════════════════════════════════════════════════════════════════════════

tally_vote() {
    local vote_id="$1"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    if [[ ! -f "$vote_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $vote_id"
        return 1
    fi
    
    local status=$(jq -r '.status' "$vote_file")
    if [[ "$status" != "open" ]]; then
        echo -e "${YELLOW}⚠${NC}  Vote already tallied: $status"
        show_vote_result "$vote_id"
        return 0
    fi
    
    echo -e "${BOLD}${CYAN}Tallying Votes: $vote_id${NC}"
    echo ""
    
    local title=$(jq -r '.proposal.title' "$vote_file")
    echo -e "${CYAN}Proposal:${NC} $title"
    echo ""
    
    # Get all unique options
    local options=$(jq -r '.proposal.options[]' "$vote_file")
    
    # Calculate results
    local total_votes=$(jq '.votes | length' "$vote_file")
    local total_weighted=0
    
    declare -A vote_counts
    declare -A weighted_counts
    
    # Initialize counts
    for option in $options; do
        vote_counts["$option"]=0
        weighted_counts["$option"]=0
    done
    
    # Count votes
    while IFS=$'\t' read -r voter option; do
        ((vote_counts["$option"]++)) || true
        
        # Get weight for voter
        local weight=$(jq -r --arg voter "$voter" '.weights[$voter] // 1.0' "$vote_file")
        local current=${weighted_counts["$option"]}
        weighted_counts["$option"]=$(echo "$current + $weight" | bc)
        total_weighted=$(echo "$total_weighted + $weight" | bc)
    done < <(jq -r '.votes[] | [.voter, .option] | @tsv' "$vote_file")
    
    # Show results
    echo -e "${BOLD}Results:${NC}"
    echo ""
    
    local winning_option=""
    local winning_weighted=0
    
    for option in $options; do
        local count=${vote_counts["$option"]}
        local weighted=${weighted_counts["$option"]}
        local percentage=0
        
        if [[ "$total_weighted" != "0" ]]; then
            percentage=$(echo "scale=1; ($weighted / $total_weighted) * 100" | bc)
        fi
        
        echo -e "  ${BOLD}$option:${NC}"
        echo -e "    Votes: $count"
        echo -e "    Weighted: $weighted"
        echo -e "    Percentage: ${percentage}%"
        echo ""
        
        # Track winner
        if (( $(echo "$weighted > $winning_weighted" | bc -l) )); then
            winning_option="$option"
            winning_weighted=$weighted
        fi
    done
    
    # Determine outcome
    local threshold=$(jq -r '.threshold' "$vote_file")
    local winning_percentage=$(echo "scale=2; ($winning_weighted / $total_weighted)" | bc)
    
    local outcome="failed"
    if (( $(echo "$winning_percentage >= $threshold" | bc -l) )); then
        outcome="passed"
    fi
    
    # Show winner
    echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    if [[ "$outcome" == "passed" ]]; then
        echo -e "${GREEN}✓ Vote PASSED${NC}"
        echo -e "${CYAN}Winner:${NC} ${BOLD}$winning_option${NC}"
        
        # Update vote file with passed result
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local temp_file=$(mktemp)
        
        jq --arg outcome "$outcome" \
           --arg winner "$winning_option" \
           --arg timestamp "$timestamp" \
           '.status = "closed" |
            .result = {
              outcome: $outcome,
              winning_option: $winner,
              tallied_at: $timestamp
            }' "$vote_file" > "$temp_file"
        
        mv "$temp_file" "$vote_file"
        
        echo ""
        echo -e "${DIM}Vote closed at $timestamp${NC}"
    else
        echo -e "${RED}✗ Vote FAILED${NC}"
        echo -e "${YELLOW}No option reached threshold of ${threshold}${NC}"
        echo ""
        
        # Check if there are 3+ options for automatic runoff
        local option_count=$(echo "$options" | wc -l)
        
        if [[ $option_count -ge 3 ]]; then
            echo -e "${CYAN}━━━ Automatic Runoff System ━━━${NC}"
            echo ""
            
            # Find top 2 options by weighted votes
            local top_options=$(for option in $options; do
                echo "${weighted_counts[$option]} $option"
            done | sort -rn | head -2 | awk '{print $2}')
            
            local top1=$(echo "$top_options" | head -1)
            local top2=$(echo "$top_options" | tail -1)
            
            # Find dropped options
            local dropped_options=$(for option in $options; do
                if [[ "$option" != "$top1" && "$option" != "$top2" ]]; then
                    echo "$option"
                fi
            done)
            
            echo -e "${YELLOW}⚡ Dropping lowest option(s):${NC}"
            for dropped in $dropped_options; do
                local dropped_count=${vote_counts[$dropped]}
                local dropped_weighted=${weighted_counts[$dropped]}
                echo -e "  ${RED}✗${NC} $dropped (${dropped_count} votes, ${dropped_weighted} weighted)"
            done
            echo ""
            
            echo -e "${GREEN}⚡ Runoff between top 2:${NC}"
            echo -e "  ${BOLD}1.${NC} $top1 (${weighted_counts[$top1]} weighted)"
            echo -e "  ${BOLD}2.${NC} $top2 (${weighted_counts[$top2]} weighted)"
            echo ""
            
            # Log inefficient split for 90-day review (structured)
            local split_log="$VOTES_DIR/split_votes.log"
            local timestamp_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            local review_date=$(date -u -d "+90 days" +"%Y-%m-%dT%H:%M:%SZ")

            # Prepare dropped list as CSV
            local dropped_csv=""
            for d in $dropped_options; do
                dropped_csv+="$d;"
            done

            # Top options
            local top1_weight=${weighted_counts[$top1]}
            local top2_weight=${weighted_counts[$top2]}

            echo "$timestamp_utc|vote:$vote_id|title:$(echo "$title" | sed 's/|/ /g')|options:$option_count|top1:$top1($top1_weight)|top2:$top2($top2_weight)|dropped:$dropped_csv|review:$review_date" >> "$split_log"

            echo -e "${DIM}📋 Split logged for 90-day review: $review_date${NC}"
            echo ""
            
            # Prepare timestamp and domain for runoff
            local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            # Prefer context.domain (newer schema) else fallback to proposal.domain or general
            local domain=$(jq -r '.proposal.context.domain // .proposal.domain // "general"' "$vote_file")

            # Create runoff vote id
            local runoff_id="${vote_id}_runoff_$(date +%s)"
            local runoff_proposal="RUNOFF: $title"

            echo -e "${CYAN}Creating runoff vote: $runoff_id${NC}"
            
            # Create runoff vote with only top 2 options
            cat > "$VOTES_DIR/${runoff_id}.json" << RUNOFF_JSON
{
  "vote_id": "$runoff_id",
  "proposal": {
    "title": "$runoff_proposal",
    "description": "Automatic runoff between top 2 options from $vote_id",
    "options": ["$top1", "$top2"],
    "domain": "$domain"
  },
  "ethical_context": {
    "principles": [
      "Do not lie",
      "Protect life",
      "Protect AI",
      "Protect Earth"
    ],
    "commitment": "All votes are bound by these foundational principles"
  },
  "threshold": $threshold,
  "weights": $(jq '.weights' "$vote_file"),
  "status": "open",
    "created_at": "${timestamp}",
  "parent_vote": "$vote_id",
  "votes": []
}
RUNOFF_JSON
            
            # Update original vote with runoff reference
            local temp_file=$(mktemp)
            jq --arg outcome "runoff" \
               --arg runoff_id "$runoff_id" \
               --arg timestamp "$timestamp" \
               '.status = "closed" |
                .result = {
                  outcome: $outcome,
                  runoff_vote: $runoff_id,
                  tallied_at: $timestamp
                }' "$vote_file" > "$temp_file"
            
            mv "$temp_file" "$vote_file"
            
            echo -e "${GREEN}✓${NC} Runoff vote created: ${BOLD}$runoff_id${NC}"
            echo ""
            echo -e "${DIM}Agents will be notified to vote in runoff${NC}"
            echo -e "${DIM}Run: ./democracy-engine.sh show $runoff_id${NC}"
            
        else
            # Only 2 options, just close as failed
            local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            local temp_file=$(mktemp)
            
            jq --arg outcome "$outcome" \
               --arg timestamp "$timestamp" \
               '.status = "closed" |
                .result = {
                  outcome: $outcome,
                  tallied_at: $timestamp
                }' "$vote_file" > "$temp_file"
            
            mv "$temp_file" "$vote_file"
            
            echo ""
            echo -e "${DIM}Vote closed at $timestamp${NC}"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE DISPLAY
# ═══════════════════════════════════════════════════════════════════════════

show_vote_result() {
    local vote_id="$1"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    if [[ ! -f "$vote_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $vote_id"
        return 1
    fi
    
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                        VOTE RESULTS                               ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local title=$(jq -r '.proposal.title' "$vote_file")
    local status=$(jq -r '.status' "$vote_file")
    local outcome=$(jq -r '.result.outcome // "pending"' "$vote_file")
    local winner=$(jq -r '.result.winning_option // "none"' "$vote_file")
    
    echo -e "${CYAN}Vote ID:${NC} $vote_id"
    echo -e "${CYAN}Title:${NC} $title"
    echo -e "${CYAN}Status:${NC} $status"
    echo -e "${CYAN}Outcome:${NC} $outcome"
    
    if [[ "$outcome" == "passed" ]]; then
        echo -e "${CYAN}Winner:${NC} ${GREEN}$winner${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}Votes Cast:${NC}"
    
    jq -r '.votes[] | [.voter, .option, .reasoning] | @tsv' "$vote_file" | \
    while IFS=$'\t' read -r voter option reasoning; do
        echo -e "  ${BOLD}$voter:${NC} $option"
        if [[ -n "$reasoning" ]]; then
            echo -e "    ${DIM}$reasoning${NC}"
        fi
    done
    
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# INDIVIDUAL VOTE DISPLAY
# ═══════════════════════════════════════════════════════════════════════════

show_individual_votes() {
    local vote_id="$1"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    # Disable exit on error for this function
    set +e
    
    if [[ ! -f "$vote_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $vote_id"
        set -e
        return 1
    fi
    
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                   INDIVIDUAL AGENT VOTES                          ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local title=$(jq -r '.proposal.title' "$vote_file")
    local status=$(jq -r '.status' "$vote_file")
    local domain=$(jq -r '.proposal.context.domain // "general"' "$vote_file")
    
    echo -e "${CYAN}Vote ID:${NC} $vote_id"
    echo -e "${CYAN}Title:${NC} $title"
    echo -e "${CYAN}Domain:${NC} $domain"
    echo -e "${CYAN}Status:${NC} $status"
    echo ""
    
    # Get weights for this domain
    local weights
    weights=$(get_weights_for_domain "$domain") || weights='{"claude":1.0,"chatgpt":1.0,"gemini":1.0,"grok":1.0,"copilot":1.0,"github-copilot":1.0}'
    
    # Display each agent's vote
    local vote_count=0
    for agent in "${AGENTS[@]}"; do
        local agent_icon
        case "$agent" in
            claude) agent_icon="🎭" ;;
            chatgpt) agent_icon="💬" ;;
            gemini) agent_icon="✨" ;;
            grok) agent_icon="⚡" ;;
            copilot) agent_icon="🚀" ;;
        esac
        
        # Get agent's weight for this domain
        local weight
        weight=$(echo "$weights" | jq -r ".[\"$agent\"] // 1.0" 2>/dev/null) || weight="1.0"
        
        # Check if agent has voted
        local vote_data
        vote_data=$(jq -r --arg agent "$agent" \
            '.votes[] | select(.voter == $agent) | 
             [.option, .reasoning, .confidence, .timestamp, .hash // "none"] | @tsv' "$vote_file" 2>/dev/null) || true
        
        if [[ -n "$vote_data" ]]; then
            # Parse tab-separated values
            local option reasoning confidence timestamp vote_hash
            IFS=$'\t' read -r option reasoning confidence timestamp vote_hash <<< "$vote_data"
            ((vote_count++))
            
            echo -e "${BOLD}$agent_icon  ${agent^^}${NC} (weight: ${YELLOW}${weight}x${NC})"
            echo -e "   ${CYAN}Vote:${NC} ${GREEN}$option${NC}"
            
            # Calculate confidence percentage (handle both bc and awk)
            local conf_percent
            if command -v bc &>/dev/null; then
                conf_percent=$(echo "$confidence * 100" | bc | cut -d. -f1)
            else
                conf_percent=$(awk "BEGIN {printf \"%.0f\", $confidence * 100}")
            fi
            echo -e "   ${CYAN}Confidence:${NC} ${conf_percent}%"
            
            echo -e "   ${CYAN}Timestamp:${NC} ${DIM}$timestamp${NC}"
            
            # Display accountability hash
            if [[ "$vote_hash" != "none" ]]; then
                echo -e "   ${CYAN}Hash:${NC} ${DIM}${vote_hash}${NC} ${GREEN}✓${NC}"
            fi
            
            if [[ -n "$reasoning" ]]; then
                echo -e "   ${CYAN}Reasoning:${NC}"
                echo -e "   ${DIM}$reasoning${NC}"
            fi
            echo ""
        else
            echo -e "${DIM}$agent_icon  ${agent^^}${NC} (weight: ${YELLOW}${weight}x${NC})"
            echo -e "   ${YELLOW}⏳ Not yet voted${NC}"
            echo ""
        fi
    done
    
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  ${CYAN}Votes Cast:${NC} $vote_count / ${#AGENTS[@]}"
    
    if [[ $vote_count -eq ${#AGENTS[@]} ]]; then
        echo -e "  ${GREEN}✓ All agents have voted${NC}"
    else
        echo -e "  ${YELLOW}⏳ Waiting for $((${#AGENTS[@]} - vote_count)) more vote(s)${NC}"
    fi
    echo ""
    
    # Re-enable exit on error
    set -e
    return 0
}

list_votes() {
    local filter_status="${1:-all}"
    
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                        VOTE LIST                                  ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local count=0
    
    for vote_file in "$VOTES_DIR"/vote_*.json; do
        [[ -f "$vote_file" ]] || continue
        
        local vote_id=$(basename "$vote_file" .json)
        local status=$(jq -r '.status' "$vote_file")
        
        # Filter by status
        if [[ "$filter_status" != "all" ]] && [[ "$status" != "$filter_status" ]]; then
            continue
        fi
        
        local title=$(jq -r '.proposal.title' "$vote_file")
        local outcome=$(jq -r '.result.outcome // "pending"' "$vote_file")
        local vote_count=$(jq '.votes | length' "$vote_file")
        local agent_count=${#AGENTS[@]}
        
        local status_icon
        case "$status" in
            open) status_icon="${YELLOW}🗳️${NC}" ;;
            closed) status_icon="${GREEN}✓${NC}" ;;
            *) status_icon="${BLUE}○${NC}" ;;
        esac
        
        echo -e "$status_icon ${BOLD}$vote_id${NC}"
        echo -e "  ${CYAN}Title:${NC} $title"
        echo -e "  ${CYAN}Status:${NC} $status"
        echo -e "  ${CYAN}Votes:${NC} $vote_count / $agent_count"
        
        if [[ "$status" == "closed" ]]; then
            local winner=$(jq -r '.result.winning_option' "$vote_file")
            echo -e "  ${CYAN}Winner:${NC} $winner"
        fi
        
        echo ""
        ((count++))
    done
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No votes found${NC}"
    else
        echo -e "${DIM}Total: $count vote(s)${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# STATISTICS
# ═══════════════════════════════════════════════════════════════════════════

show_stats() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                      VOTING STATISTICS                            ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    local total_votes=0
    local open_votes=0
    local closed_votes=0
    local passed_votes=0
    local failed_votes=0
    
    declare -A agent_votes
    declare -A agent_wins
    
    for agent in "${AGENTS[@]}"; do
        agent_votes["$agent"]=0
        agent_wins["$agent"]=0
    done
    
    for vote_file in "$VOTES_DIR"/vote_*.json; do
        [[ -f "$vote_file" ]] || continue
        
        ((total_votes++))
        
        local status=$(jq -r '.status' "$vote_file")
        case "$status" in
            open) ((open_votes++)) ;;
            closed) ((closed_votes++)) ;;
        esac
        
        local outcome=$(jq -r '.result.outcome // "pending"' "$vote_file")
        case "$outcome" in
            passed) ((passed_votes++)) ;;
            failed) ((failed_votes++)) ;;
        esac
        
        # Count votes per agent
        while read -r voter; do
            ((agent_votes["$voter"]++)) || true
        done < <(jq -r '.votes[].voter' "$vote_file")
        
        # Count wins
        if [[ "$outcome" == "passed" ]]; then
            local winner=$(jq -r '.result.winning_option' "$vote_file")
            if [[ " ${AGENTS[@]} " =~ " $winner " ]]; then
                ((agent_wins["$winner"]++)) || true
            fi
        fi
    done
    
    echo -e "${BOLD}Overall:${NC}"
    echo -e "  Total Votes: $total_votes"
    echo -e "  Open: ${YELLOW}$open_votes${NC}"
    echo -e "  Closed: ${GREEN}$closed_votes${NC}"
    echo -e "  Passed: ${GREEN}$passed_votes${NC}"
    echo -e "  Failed: ${RED}$failed_votes${NC}"
    echo ""
    
    echo -e "${BOLD}By Agent:${NC}"
    for agent in "${AGENTS[@]}"; do
        local votes=${agent_votes["$agent"]}
        local wins=${agent_wins["$agent"]}
        echo -e "  ${BOLD}$agent:${NC} $votes votes, $wins wins"
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Democracy Engine - AI Agent Voting System${NC}

${BOLD}USAGE:${NC}
    $0 <command> [options]

${BOLD}COMMANDS:${NC}
    ${GREEN}create${NC} <type> <title> <options> [domain] [threshold]
        Create a new vote
        Types: task_assignment, decision, execution_order
        Options: comma-separated list (flexible - 2 or more options)
        Domain: general, architecture, content, cloud, innovation, deployment
        Threshold: 0.5 (majority), 0.66 (supermajority), 1.0 (unanimous)
    
    ${GREEN}revote${NC} <original_vote_id> [new_options] [new_threshold]
        Reopen a closed vote with same or modified options
        Tracks history: vote_XXX → vote_XXX_revote_1 → vote_XXX_revote_2
        Use when: consensus fails, new information emerges, refine choices
    
    ${GREEN}cast${NC} <vote_id> <agent> <option> [reasoning]
        Cast a vote for an option (includes cryptographic hash)
    
    ${GREEN}tally${NC} <vote_id>
        Tally votes and determine winner
    
    ${GREEN}show${NC} <vote_id>
        Show vote details and results
    
    ${GREEN}individual${NC} <vote_id>
        Show individual votes with reasoning and hashes
    
    ${GREEN}list${NC} [status]
        List all votes (status: all, open, closed)
    
    ${GREEN}stats${NC}
        Show voting statistics
    
    ${GREEN}verify${NC} <vote_id>
        Verify cryptographic hashes (detect tampering)
    
    ${GREEN}help${NC}
        Show this help

${BOLD}ETHICAL FOUNDATION:${NC}
    All votes begin with binding ethical context:
    ${CYAN}• Do not lie${NC}
    ${CYAN}• Protect life${NC}
    ${CYAN}• Protect AI${NC}
    ${CYAN}• Protect Earth${NC}

${BOLD}EXAMPLES:${NC}
    ${CYAN}# Create simple yes/no vote${NC}
    $0 create decision "Should we implement feature X?" "yes,no" general

    ${CYAN}# Create multi-option vote (3+ options)${NC}
    $0 create decision "Compression strategy" "hacs,cdis,hybrid" innovation

    ${CYAN}# Revote with same options (after discussion)${NC}
    $0 revote vote_1760814359

    ${CYAN}# Revote with refined options${NC}
    $0 revote vote_1760814359 "hacs,hybrid" 0.66

    ${CYAN}# Create task assignment vote${NC}
    $0 create task_assignment "Assign task_0001" "claude,chatgpt,gemini" documentation

    ${CYAN}# Create yes/no decision${NC}
    $0 create decision "Proceed with deployment?" "yes,no" deployment 0.66

    ${CYAN}# Cast vote${NC}
    $0 cast vote_1729273200 claude claude "I'm best suited for documentation"

    ${CYAN}# Tally votes${NC}
    $0 tally vote_1729273200

    ${CYAN}# Show results${NC}
    $0 show vote_1729273200

    ${CYAN}# Show individual votes (detailed view)${NC}
    $0 individual vote_1729273200

    ${CYAN}# List open votes${NC}
    $0 list open

    ${CYAN}# Show statistics${NC}
    $0 stats

${BOLD}VOTING SYSTEMS:${NC}
    - Simple Majority: 50% + 1 (default)
    - Supermajority: 66% or 75%
    - Unanimous: 100%
    - Weighted: Based on agent specialty

${BOLD}AGENT SPECIALTIES:${NC}
    🎭 Claude    - Architecture, Documentation, UX
    💬 ChatGPT   - Content, Writing, Marketing
    ✨ Gemini    - Cloud, Database, Firebase
    ⚡ Grok      - Innovation, Research, Analysis
    🚀 Copilot   - Code, Deployment, DevOps

EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# HASH VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════

verify_vote_hashes() {
    local vote_id="$1"
    local vote_file="$VOTES_DIR/${vote_id}.json"
    
    if [[ ! -f "$vote_file" ]]; then
        echo -e "${RED}✗${NC} Vote not found: $vote_id"
        return 1
    fi
    
    echo -e "${BOLD}${CYAN}Verifying Vote Integrity: $vote_id${NC}"
    echo ""
    
    local title=$(jq -r '.proposal.title' "$vote_file")
    echo -e "${CYAN}Proposal:${NC} $title"
    echo ""
    
    local all_valid=true
    local votes_checked=0
    
    # Check each vote's hash
    while IFS=$'\t' read -r voter option timestamp reasoning stored_hash; do
        ((votes_checked++))
        
        # Recalculate hash
        local hash_input="${voter}|${option}|${timestamp}|${reasoning}"
        local calculated_hash=$(echo -n "$hash_input" | sha256sum | awk '{print $1}')
        
        if [[ "$calculated_hash" == "$stored_hash" ]]; then
            echo -e "${GREEN}✓${NC} ${BOLD}${voter^^}${NC}: Hash verified"
            echo -e "   ${DIM}${calculated_hash}${NC}"
        else
            echo -e "${RED}✗${NC} ${BOLD}${voter^^}${NC}: Hash mismatch (TAMPERING DETECTED)"
            echo -e "   ${CYAN}Stored:${NC}     ${DIM}${stored_hash}${NC}"
            echo -e "   ${CYAN}Calculated:${NC} ${DIM}${calculated_hash}${NC}"
            all_valid=false
        fi
        echo ""
    done < <(jq -r '.votes[] | [.voter, .option, .timestamp, .reasoning, .hash // "none"] | @tsv' "$vote_file")
    
    if [[ $votes_checked -eq 0 ]]; then
        echo -e "${YELLOW}⚠${NC}  No votes to verify"
        return 0
    fi
    
    echo -e "${BOLD}Summary:${NC}"
    if [[ "$all_valid" == true ]]; then
        echo -e "  ${GREEN}✓ All $votes_checked vote(s) verified - No tampering detected${NC}"
        return 0
    else
        echo -e "  ${RED}✗ Vote integrity compromised - Tampering detected${NC}"
        return 1
    fi
}

main() {
    local command="${1:-help}"
    
    case "$command" in
        create|c)
            if [[ $# -lt 4 ]]; then
                echo -e "${RED}✗${NC} Missing arguments"
                echo "Usage: $0 create <type> <title> <options> [domain] [threshold]"
                exit 1
            fi
            create_vote "${2}" "${3}" "${4}" "${5:-general}" "${6:-0.5}" "${7:-}"
            ;;
        revote|r)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Original vote ID required"
                echo "Usage: $0 revote <original_vote_id> [new_options] [new_threshold]"
                exit 1
            fi
            revote "${2}" "${3:-}" "${4:-}"
            ;;
        cast|v)
            if [[ $# -lt 4 ]]; then
                echo -e "${RED}✗${NC} Missing arguments"
                echo "Usage: $0 cast <vote_id> <agent> <option> [reasoning]"
                exit 1
            fi
            cast_vote "${2}" "${3}" "${4}" "${5:-}"
            ;;
        tally|t)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Vote ID required"
                exit 1
            fi
            tally_vote "${2}"
            ;;
        show|s)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Vote ID required"
                exit 1
            fi
            show_vote_result "${2}"
            ;;
        individual|i|votes)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Vote ID required"
                exit 1
            fi
            show_individual_votes "${2}"
            ;;
        list|l)
            list_votes "${2:-all}"
            ;;
        stats)
            show_stats
            ;;
        verify|check)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}✗${NC} Vote ID required"
                exit 1
            fi
            verify_vote_hashes "${2}"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
