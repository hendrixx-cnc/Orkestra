#!/bin/bash

# AI DEMOCRACY ENGINE
# Collaborative decision-making system for multiple AIs
# Each AI proposes 3 options, voting eliminates most popular, repeat until consensus or user decides

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DECISIONS_DIR="$SCRIPT_DIR/decisions"
VOTES_DIR="$DECISIONS_DIR/votes"
RESULTS_DIR="$DECISIONS_DIR/results"

# Create directories
mkdir -p "$DECISIONS_DIR" "$VOTES_DIR" "$RESULTS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE FUNCTIONS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🏛️  AI DEMOCRACY ENGINE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CREATE NEW DECISION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

create_decision() {
    local decision_id="$1"
    local question="$2"
    local context="${3:-}"
    local expert="${4:-none}"

    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    if [[ -f "$decision_file" ]]; then
        echo -e "${RED}❌ Decision ID already exists: $decision_id${NC}"
        return 1
    fi

    # Validate expert if provided
    if [[ "$expert" != "none" ]] && [[ ! "$expert" =~ ^(copilot|claude|chatgpt|gemini|grok)$ ]]; then
        echo -e "${RED}❌ Invalid expert. Must be: copilot, claude, chatgpt, gemini, or grok${NC}"
        return 1
    fi

    cat > "$decision_file" <<EOF
{
  "id": "$decision_id",
  "question": "$question",
  "context": "$context",
  "expert": "$expert",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")",
  "status": "collecting_options",
  "round": 1,
  "ai_agents": ["copilot", "claude", "chatgpt", "gemini", "grok"],
  "options": [],
  "eliminated": [],
  "final_decision": null,
  "decided_by": null
}
EOF

    echo -e "${GREEN}✅ Decision created: $decision_id${NC}"
    echo -e "${CYAN}📋 Question: $question${NC}"
    echo ""
    echo -e "${YELLOW}Next step: Each AI (including Copilot) submits 3 options${NC}"
    echo -e "   ${PURPLE}./democracy_engine.sh submit $decision_id <ai_name> \"option1\" \"option2\" \"option3\"${NC}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SUBMIT OPTIONS (AI proposes 3 options)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

submit_options() {
    local decision_id="$1"
    local ai_name="$2"
    local option1="$3"
    local option2="$4"
    local option3="$5"

    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    if [[ ! -f "$decision_file" ]]; then
        echo -e "${RED}❌ Decision not found: $decision_id${NC}"
        return 1
    fi

    local status=$(jq -r '.status' "$decision_file")
    local round=$(jq -r '.round' "$decision_file")

    if [[ "$status" != "collecting_options" && "$status" != "voting_round_$round" ]]; then
        echo -e "${RED}❌ Decision not accepting options. Status: $status${NC}"
        return 1
    fi

    # Check if AI already submitted
    local already_submitted=$(jq -r --arg ai "$ai_name" --arg round "$round" \
        '.options[] | select(.submitted_by == $ai and .round == ($round | tonumber)) | .submitted_by' \
        "$decision_file")

    if [[ -n "$already_submitted" ]]; then
        echo -e "${RED}❌ $ai_name already submitted options for round $round${NC}"
        return 1
    fi

    # Add options
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")

    jq --arg ai "$ai_name" \
       --arg opt1 "$option1" \
       --arg opt2 "$option2" \
       --arg opt3 "$option3" \
       --arg ts "$timestamp" \
       --arg round "$round" \
       '.options += [
         {
           "text": $opt1,
           "submitted_by": $ai,
           "submitted_at": $ts,
           "round": ($round | tonumber),
           "votes": 0,
           "id": ((.options | length) + 1)
         },
         {
           "text": $opt2,
           "submitted_by": $ai,
           "submitted_at": $ts,
           "round": ($round | tonumber),
           "votes": 0,
           "id": ((.options | length) + 2)
         },
         {
           "text": $opt3,
           "submitted_by": $ai,
           "submitted_at": $ts,
           "round": ($round | tonumber),
           "votes": 0,
           "id": ((.options | length) + 3)
         }
       ]' "$decision_file" > "${decision_file}.tmp" && mv "${decision_file}.tmp" "$decision_file"

    echo -e "${GREEN}✅ Options submitted by $ai_name${NC}"
    echo -e "   1. $option1"
    echo -e "   2. $option2"
    echo -e "   3. $option3"

    # Check if all AIs have submitted
    check_ready_for_voting "$decision_id"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK IF READY FOR VOTING
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_ready_for_voting() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local round=$(jq -r '.round' "$decision_file")
    local ai_count=$(jq -r '.ai_agents | length' "$decision_file")
    local submitted_count=$(jq -r --arg round "$round" \
        '[.options[] | select(.round == ($round | tonumber)) | .submitted_by] | unique | length' \
        "$decision_file")

    if [[ $submitted_count -eq $ai_count ]]; then
        jq --arg round "$round" \
           '.status = "voting_round_" + $round' \
           "$decision_file" > "${decision_file}.tmp" && mv "${decision_file}.tmp" "$decision_file"

        echo ""
        echo -e "${YELLOW}🗳️  All AIs have submitted options for Round $round${NC}"
        echo -e "${CYAN}Ready for voting!${NC}"
        echo ""
        show_options "$decision_id"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SHOW OPTIONS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_options() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local question=$(jq -r '.question' "$decision_file")
    local round=$(jq -r '.round' "$decision_file")

    echo -e "${PURPLE}📊 ROUND $round OPTIONS${NC}"
    echo -e "${CYAN}Question: $question${NC}"
    echo ""

    jq -r --arg round "$round" \
        '.options[] | select(.round == ($round | tonumber)) |
         "  [\(.id)] \(.text)\n      Proposed by: \(.submitted_by) | Votes: \(.votes)"' \
        "$decision_file"

    echo ""
    echo -e "${YELLOW}Next: Each AI votes for their preferred option${NC}"
    echo -e "   ${PURPLE}Note: All AIs have 1 equal vote${NC}"
    echo -e "   ${PURPLE}./democracy_engine.sh vote $decision_id <ai_name> <option_id>${NC}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VOTE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

vote() {
    local decision_id="$1"
    local ai_name="$2"
    local option_id="$3"

    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    if [[ ! -f "$decision_file" ]]; then
        echo -e "${RED}❌ Decision not found: $decision_id${NC}"
        return 1
    fi

    local round=$(jq -r '.round' "$decision_file")
    local status=$(jq -r '.status' "$decision_file")

    if [[ "$status" != "voting_round_$round" ]]; then
        echo -e "${RED}❌ Not in voting phase. Current status: $status${NC}"
        return 1
    fi

    # Check if option exists in current round
    local option_exists=$(jq -r --arg id "$option_id" --arg round "$round" \
        '.options[] | select(.id == ($id | tonumber) and .round == ($round | tonumber)) | .id' \
        "$decision_file")

    if [[ -z "$option_exists" ]]; then
        echo -e "${RED}❌ Option $option_id not found in round $round${NC}"
        return 1
    fi

    # Record vote
    local vote_file="$VOTES_DIR/${decision_id}_round${round}_${ai_name}.vote"

    if [[ -f "$vote_file" ]]; then
        echo -e "${RED}❌ $ai_name already voted in round $round${NC}"
        return 1
    fi

    echo "$option_id" > "$vote_file"

    # Each AI gets 1 equal vote
    local vote_weight=1

    # Increment vote count (everyone gets 1 vote)
    jq --arg id "$option_id" --arg weight "$vote_weight" \
       '(.options[] | select(.id == ($id | tonumber)) | .votes) += ($weight | tonumber)' \
       "$decision_file" > "${decision_file}.tmp" && mv "${decision_file}.tmp" "$decision_file"

    echo -e "${GREEN}✅ Vote recorded: $ai_name voted for option $option_id (1 vote)${NC}"

    # Check if all votes are in
    check_voting_complete "$decision_id"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CHECK VOTING COMPLETE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

check_voting_complete() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local round=$(jq -r '.round' "$decision_file")
    local ai_count=$(jq -r '.ai_agents | length' "$decision_file")
    local vote_count=$(ls -1 "$VOTES_DIR/${decision_id}_round${round}_"*.vote 2>/dev/null | wc -l)

    if [[ $vote_count -eq $ai_count ]]; then
        echo ""
        echo -e "${YELLOW}🗳️  All votes collected for Round $round${NC}"
        tally_votes "$decision_id"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TALLY VOTES - SIMPLE: 3+ VOTES = WINNER
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

tally_votes() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local round=$(jq -r '.round' "$decision_file")

    echo ""
    echo -e "${PURPLE}📊 VOTE TALLY - ROUND $round${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show results sorted by votes
    jq -r --arg round "$round" \
        '.options[] | select(.round == ($round | tonumber)) |
         "\(.votes) votes - [\(.id)] \(.text) (by \(.submitted_by))"' \
        "$decision_file" | sort -rn

    echo ""

    # SIMPLE RULE: First option to get 3+ votes wins
    local winner=$(jq -r --arg round "$round" \
        '[.options[] | select(.round == ($round | tonumber) and .votes >= 3)] | 
         sort_by(.votes) | reverse | .[0] | .id' \
        "$decision_file")

    if [[ "$winner" != "null" && -n "$winner" ]]; then
        echo -e "${GREEN}✅ WINNER: Option got 3+ votes!${NC}"
        finalize_decision "$decision_id" "consensus"
        return
    fi

    # No winner yet - check for ties
    local max_votes=$(jq -r --arg round "$round" \
        '[.options[] | select(.round == ($round | tonumber)) | .votes] | max' \
        "$decision_file")

    local top_count=$(jq -r --arg round "$round" --arg max "$max_votes" \
        '[.options[] | select(.round == ($round | tonumber) and .votes == ($max | tonumber))] | length' \
        "$decision_file")

    # If multiple options tied at top - user decides
    if [[ $top_count -gt 1 ]]; then
        echo -e "${YELLOW}⚖️  Multiple options tied with $max_votes votes - user must decide${NC}"
        request_user_decision "$decision_id"
        return
    fi

    # Single leader but less than 3 votes - that's the winner (best available)
    echo -e "${GREEN}✅ Clear winner with $max_votes votes${NC}"
    finalize_decision "$decision_id" "consensus"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# REQUEST USER DECISION (TIE BREAKER)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

request_user_decision() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local round=$(jq -r '.round' "$decision_file")

    jq '.status = "awaiting_user_decision"' \
       "$decision_file" > "${decision_file}.tmp" && mv "${decision_file}.tmp" "$decision_file"

    echo ""
    echo -e "${RED}🤝 TIE DETECTED - USER MUST DECIDE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}The remaining options are tied. Please choose:${NC}"
    echo ""

    jq -r --arg round "$round" \
        '.options[] | select(.round == ($round | tonumber)) |
         "  [\(.id)] \(.text) (\(.votes) votes)"' \
        "$decision_file"

    echo ""
    echo -e "${CYAN}To decide:${NC}"
    echo -e "   ${PURPLE}./democracy_engine.sh user-decide $decision_id <option_id>${NC}"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# USER DECIDES (TIE BREAKER)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

user_decide() {
    local decision_id="$1"
    local option_id="$2"

    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    local status=$(jq -r '.status' "$decision_file")

    if [[ "$status" != "awaiting_user_decision" ]]; then
        echo -e "${RED}❌ Not awaiting user decision. Status: $status${NC}"
        return 1
    fi

    finalize_decision "$decision_id" "user" "$option_id"
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FINALIZE DECISION
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

finalize_decision() {
    local decision_id="$1"
    local decided_by="$2"
    local option_id="${3:-}"

    local decision_file="$DECISIONS_DIR/${decision_id}.json"
    local round=$(jq -r '.round' "$decision_file")

    # If consensus, find the option with most votes
    if [[ "$decided_by" == "consensus" ]]; then
        option_id=$(jq -r --arg round "$round" \
            '[.options[] | select(.round == ($round | tonumber))] |
             max_by(.votes) | .id' \
            "$decision_file")
    fi

    local final_text=$(jq -r --arg id "$option_id" \
        '.options[] | select(.id == ($id | tonumber)) | .text' \
        "$decision_file")

    local final_proposer=$(jq -r --arg id "$option_id" \
        '.options[] | select(.id == ($id | tonumber)) | .submitted_by' \
        "$decision_file")

    jq --arg decided "$decided_by" \
       --arg text "$final_text" \
       --arg proposer "$final_proposer" \
       --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")" \
       '.status = "completed" |
        .decided_by = $decided |
        .final_decision = {
          "text": $text,
          "proposed_by": $proposer,
          "finalized_at": $ts
        }' \
       "$decision_file" > "${decision_file}.tmp" && mv "${decision_file}.tmp" "$decision_file"

    # Copy to results
    cp "$decision_file" "$RESULTS_DIR/${decision_id}_result.json"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ DECISION FINALIZED${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}Question:${NC} $(jq -r '.question' "$decision_file")"
    echo ""
    echo -e "${YELLOW}Decision:${NC} $final_text"
    echo ""
    echo -e "${PURPLE}Proposed by:${NC} $final_proposer"
    echo -e "${PURPLE}Decided by:${NC} $decided_by"
    echo -e "${PURPLE}Rounds:${NC} $round"
    echo ""
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

show_status() {
    local decision_id="$1"
    local decision_file="$DECISIONS_DIR/${decision_id}.json"

    if [[ ! -f "$decision_file" ]]; then
        echo -e "${RED}❌ Decision not found: $decision_id${NC}"
        return 1
    fi

    show_header

    local question=$(jq -r '.question' "$decision_file")
    local status=$(jq -r '.status' "$decision_file")
    local round=$(jq -r '.round' "$decision_file")

    echo -e "${CYAN}Decision ID:${NC} $decision_id"
    echo -e "${CYAN}Question:${NC} $question"
    echo -e "${CYAN}Status:${NC} $status"
    echo -e "${CYAN}Round:${NC} $round"
    echo ""

    if [[ "$status" == "completed" ]]; then
        local final=$(jq -r '.final_decision.text' "$decision_file")
        local proposer=$(jq -r '.final_decision.proposed_by' "$decision_file")
        local decided_by=$(jq -r '.decided_by' "$decision_file")

        echo -e "${GREEN}✅ FINAL DECISION:${NC} $final"
        echo -e "${PURPLE}Proposed by:${NC} $proposer"
        echo -e "${PURPLE}Decided by:${NC} $decided_by"
    else
        show_options "$decision_id"
    fi
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LIST DECISIONS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

list_decisions() {
    show_header

    echo -e "${PURPLE}📋 ALL DECISIONS${NC}"
    echo ""

    for file in "$DECISIONS_DIR"/*.json; do
        if [[ -f "$file" ]]; then
            local id=$(jq -r '.id' "$file")
            local question=$(jq -r '.question' "$file")
            local status=$(jq -r '.status' "$file")

            echo -e "${CYAN}[$id]${NC} $question"
            echo -e "      Status: $status"
            echo ""
        fi
    done
}

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    local command="${1:-}"

    case "$command" in
        create)
            show_header
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 create <decision_id> <question> [context] [expert]"
                echo ""
                echo "expert: claude, chatgpt, gemini, or grok (optional)"
                echo "        Expert's vote counts as 3 votes (others count as 2)"
                exit 1
            fi
            create_decision "$2" "$3" "${4:-}" "${5:-none}"
            ;;
        submit)
            if [[ $# -lt 6 ]]; then
                echo "Usage: $0 submit <decision_id> <ai_name> <option1> <option2> <option3>"
                exit 1
            fi
            submit_options "$2" "$3" "$4" "$5" "$6"
            ;;
        vote)
            if [[ $# -lt 4 ]]; then
                echo "Usage: $0 vote <decision_id> <ai_name> <option_id>"
                exit 1
            fi
            vote "$2" "$3" "$4"
            ;;
        user-decide)
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 user-decide <decision_id> <option_id>"
                exit 1
            fi
            user_decide "$2" "$3"
            ;;
        status)
            if [[ $# -lt 2 ]]; then
                echo "Usage: $0 status <decision_id>"
                exit 1
            fi
            show_status "$2"
            ;;
        list)
            list_decisions
            ;;
        *)
            show_header
            echo "AI Democracy Engine - Collaborative Decision Making"
            echo ""
            echo "Usage:"
            echo "  $0 create <decision_id> <question> [context] [expert]"
            echo "  $0 submit <decision_id> <ai_name> <opt1> <opt2> <opt3>"
            echo "  $0 vote <decision_id> <ai_name> <option_id>"
            echo "  $0 user-decide <decision_id> <option_id>"
            echo "  $0 status <decision_id>"
            echo "  $0 list"
            echo ""
            echo "All 5 AIs participate equally: copilot, claude, chatgpt, gemini, grok"
            echo ""
            echo "Simple Process:"
            echo "  1. Create decision with question"
            echo "  2. Each AI submits 3 options"
            echo "  3. All 5 AIs vote (1 vote each)"
            echo "  4. First option to get 3+ votes wins"
            echo "  5. If tie at top, user decides"
            ;;
    esac
}

main "$@"
