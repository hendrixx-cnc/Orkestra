#!/bin/bash
# Committee Menu System
# Interactive menu for committee votes and questions

COMMITTEE_DIR="/workspaces/Orkestra/COMMITTEE"
MEETINGS_DIR="$COMMITTEE_DIR/MEETINGS"
VOTES_DIR="$COMMITTEE_DIR/VOTES"
QUESTIONS_DIR="$COMMITTEE_DIR/QUESTIONS"
RESPONSES_DIR="$COMMITTEE_DIR/RESPONSES"

# Ensure directories exist
mkdir -p "$MEETINGS_DIR" "$VOTES_DIR" "$QUESTIONS_DIR" "$RESPONSES_DIR"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                  COMMITTEE SYSTEM                          ║"
    echo "║              Democratic AI Collaboration                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

committee_main_menu() {
    show_banner
    echo -e "${GREEN}Committee Options:${NC}"
    echo ""
    echo "  1) Call a Vote"
    echo "  2) Ask a Question"
    echo "  3) View Active Items"
    echo "  4) View Results"
    echo "  5) Exit"
    echo ""
    read -p "Select option [1-5]: " choice
    
    case $choice in
        1) call_vote ;;
        2) ask_question ;;
        3) view_active ;;
        4) view_results ;;
        5) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1; committee_main_menu ;;
    esac
}

call_vote() {
    show_banner
    echo -e "${YELLOW}=== CALL A VOTE ===${NC}"
    echo ""
    
    # Get vote details
    read -p "Vote topic: " topic
    read -p "Number of options (2-10): " num_options
    read -p "Number of rounds (1-10): " num_rounds
    
    # Validate
    if [[ ! "$num_options" =~ ^[0-9]+$ ]] || [ "$num_options" -lt 2 ] || [ "$num_options" -gt 10 ]; then
        echo -e "${RED}Invalid number of options${NC}"
        sleep 2
        call_vote
        return
    fi
    
    # Create vote file
    timestamp=$(date +%s)
    date_str=$(date +%Y%m%d-%H%M%S)
    hash=$(echo "$topic$timestamp" | sha256sum | cut -c1-8)
    
    vote_file="$VOTES_DIR/vote-${date_str}-${hash}.md"
    
    # Gather options
    echo ""
    echo "Enter options (one per line):"
    declare -a options
    for ((i=1; i<=num_options; i++)); do
        read -p "  Option $i: " opt
        options+=("$opt")
    done
    
    # Gather context
    echo ""
    echo -e "${BLUE}Gathering relevant context...${NC}"
    context=$(/workspaces/Orkestra/SCRIPTS/COMMITTEE/gather-context.sh "$topic")
    
    # Create vote document
    cat > "$vote_file" << EOF
# COMMITTEE VOTE

**ID**: ${hash}
**Timestamp**: $(date -d @$timestamp '+%Y-%m-%d %H:%M:%S')
**Unix Time**: ${timestamp}
**Topic**: ${topic}
**Rounds**: ${num_rounds}
**Status**: 🟢 ACTIVE

---

## VOTE QUESTION

${topic}

---

## OPTIONS

EOF
    
    for ((i=0; i<${#options[@]}; i++)); do
        echo "### Option $((i+1)): ${options[$i]}" >> "$vote_file"
        echo "" >> "$vote_file"
        echo "**Votes**: 0" >> "$vote_file"
        echo "**Reasoning**: [Pending]" >> "$vote_file"
        echo "" >> "$vote_file"
    done
    
    cat >> "$vote_file" << EOF

---

## CONTEXT

${context}

---

## VOTING ROUNDS

EOF
    
    for ((r=1; r<=num_rounds; r++)); do
        cat >> "$vote_file" << EOF

### Round $r

**Status**: ⏳ Pending

#### Agent Responses:
<!-- Agents add responses here -->

EOF
    done
    
    cat >> "$vote_file" << EOF

---

## FINAL RESULTS

**Status**: ⏳ Awaiting completion

**Winner**: [TBD]

**Summary**: [TBD]

---

**Vote File**: \`${vote_file}\`
EOF
    
    echo -e "${GREEN}✅ Vote created!${NC}"
    echo ""
    echo "File: $vote_file"
    echo "Hash: $hash"
    echo ""
    
    # Launch committee process
    read -p "Start committee process now? [y/N]: " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        /workspaces/Orkestra/SCRIPTS/COMMITTEE/process-vote.sh "$vote_file" "$num_rounds"
    fi
    
    read -p "Press Enter to continue..."
    committee_main_menu
}

ask_question() {
    show_banner
    echo -e "${YELLOW}=== ASK A QUESTION ===${NC}"
    echo ""
    
    # Get question details
    read -p "Question topic: " topic
    echo ""
    echo "Enter your question (end with empty line):"
    question=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        question="${question}${line}"$'\n'
    done
    
    read -p "Number of rounds (1-10): " num_rounds
    
    # Validate
    if [[ ! "$num_rounds" =~ ^[0-9]+$ ]] || [ "$num_rounds" -lt 1 ] || [ "$num_rounds" -gt 10 ]; then
        echo -e "${RED}Invalid number of rounds${NC}"
        sleep 2
        ask_question
        return
    fi
    
    # Create question file
    timestamp=$(date +%s)
    date_str=$(date +%Y%m%d-%H%M%S)
    hash=$(echo "$topic$question$timestamp" | sha256sum | cut -c1-8)
    
    question_file="$QUESTIONS_DIR/question-${date_str}-${hash}.md"
    
    # Gather context
    echo ""
    echo -e "${BLUE}Gathering relevant context...${NC}"
    context=$(/workspaces/Orkestra/SCRIPTS/COMMITTEE/gather-context.sh "$topic")
    
    # Create question document
    cat > "$question_file" << EOF
# COMMITTEE QUESTION

**ID**: ${hash}
**Timestamp**: $(date -d @$timestamp '+%Y-%m-%d %H:%M:%S')
**Unix Time**: ${timestamp}
**Topic**: ${topic}
**Rounds**: ${num_rounds}
**Status**: 🟢 ACTIVE

---

## QUESTION

${question}

---

## CONTEXT

${context}

---

## RESPONSE ROUNDS

EOF
    
    for ((r=1; r<=num_rounds; r++)); do
        cat >> "$question_file" << EOF

### Round $r

**Status**: ⏳ Pending

#### AI Agent Responses:

<!-- Each AI adds response here -->

EOF
    done
    
    cat >> "$question_file" << EOF

---

## CONSOLIDATED RESPONSE

**Status**: ⏳ Awaiting completion

**Summary**: [TBD]

**Action Items**: [TBD]

---

**Question File**: \`${question_file}\`
EOF
    
    echo -e "${GREEN}✅ Question created!${NC}"
    echo ""
    echo "File: $question_file"
    echo "Hash: $hash"
    echo ""
    
    # Launch committee process
    read -p "Start committee process now? [y/N]: " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        /workspaces/Orkestra/SCRIPTS/COMMITTEE/process-question.sh "$question_file" "$num_rounds"
    fi
    
    read -p "Press Enter to continue..."
    committee_main_menu
}

view_active() {
    show_banner
    echo -e "${YELLOW}=== ACTIVE ITEMS ===${NC}"
    echo ""
    
    echo -e "${GREEN}Active Votes:${NC}"
    grep -l "Status.*ACTIVE" "$VOTES_DIR"/*.md 2>/dev/null | while read file; do
        topic=$(grep "^\*\*Topic\*\*:" "$file" | cut -d: -f2- | xargs)
        hash=$(grep "^\*\*ID\*\*:" "$file" | cut -d: -f2- | xargs)
        echo "  [$hash] $topic"
        echo "    File: $file"
        echo ""
    done
    
    echo -e "${GREEN}Active Questions:${NC}"
    grep -l "Status.*ACTIVE" "$QUESTIONS_DIR"/*.md 2>/dev/null | while read file; do
        topic=$(grep "^\*\*Topic\*\*:" "$file" | cut -d: -f2- | xargs)
        hash=$(grep "^\*\*ID\*\*:" "$file" | cut -d: -f2- | xargs)
        echo "  [$hash] $topic"
        echo "    File: $file"
        echo ""
    done
    
    read -p "Press Enter to continue..."
    committee_main_menu
}

view_results() {
    show_banner
    echo -e "${YELLOW}=== COMPLETED ITEMS ===${NC}"
    echo ""
    
    echo -e "${GREEN}Completed Votes:${NC}"
    grep -l "Status.*COMPLETE" "$VOTES_DIR"/*.md 2>/dev/null | while read file; do
        topic=$(grep "^\*\*Topic\*\*:" "$file" | cut -d: -f2- | xargs)
        hash=$(grep "^\*\*ID\*\*:" "$file" | cut -d: -f2- | xargs)
        winner=$(grep "^\*\*Winner\*\*:" "$file" | cut -d: -f2- | xargs)
        echo "  [$hash] $topic"
        echo "    Winner: $winner"
        echo "    File: $file"
        echo ""
    done
    
    echo -e "${GREEN}Answered Questions:${NC}"
    grep -l "Status.*COMPLETE" "$QUESTIONS_DIR"/*.md 2>/dev/null | while read file; do
        topic=$(grep "^\*\*Topic\*\*:" "$file" | cut -d: -f2- | xargs)
        hash=$(grep "^\*\*ID\*\*:" "$file" | cut -d: -f2- | xargs)
        echo "  [$hash] $topic"
        echo "    File: $file"
        echo ""
    done
    
    read -p "Press Enter to continue..."
    committee_main_menu
}

# Start the menu
committee_main_menu
