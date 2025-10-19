#!/bin/bash
# Process Vote - Routes vote through AI agents in rounds
# Each agent casts vote and provides reasoning

VOTE_FILE="$1"
NUM_ROUNDS="$2"

RESPONSES_DIR="/workspaces/Orkestra/COMMITTEE/RESPONSES"
AGENTS_DIR="/workspaces/Orkestra/COMMITTEE/AGENTS"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure directories exist
mkdir -p "$RESPONSES_DIR" "$AGENTS_DIR"

# AI Agents
AGENTS=(
    "copilot:GitHub Copilot"
    "claude:Claude"
    "chatgpt:ChatGPT"
    "gemini:Gemini"
    "grok:Grok"
)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           PROCESSING COMMITTEE VOTE                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Extract vote details
VOTE_ID=$(grep "^\*\*ID\*\*:" "$VOTE_FILE" | cut -d: -f2- | xargs)
TOPIC=$(grep "^\*\*Topic\*\*:" "$VOTE_FILE" | cut -d: -f2- | xargs)

# Extract options
declare -a options
while IFS= read -r line; do
    if [[ "$line" =~ ^###\ Option\ [0-9]+:\ (.+)$ ]]; then
        options+=("${BASH_REMATCH[1]}")
    fi
done < "$VOTE_FILE"

NUM_OPTIONS=${#options[@]}

echo -e "${GREEN}Vote ID:${NC} $VOTE_ID"
echo -e "${GREEN}Topic:${NC} $TOPIC"
echo -e "${GREEN}Options:${NC} $NUM_OPTIONS"
echo -e "${GREEN}Rounds:${NC} $NUM_ROUNDS"
echo ""

# Initialize vote counters
declare -A vote_counts
for ((i=0; i<NUM_OPTIONS; i++)); do
    vote_counts[$i]=0
done

# Process each round
for ((round=1; round<=NUM_ROUNDS; round++)); do
    echo -e "${YELLOW}═══ ROUND $round/$NUM_ROUNDS ═══${NC}"
    echo ""
    
    # Update round status
    sed -i "/### Round $round/,/^$/s/Status.*Pending/Status: 🔄 In Progress/" "$VOTE_FILE"
    
    # Create round-specific response file
    round_response_file="$RESPONSES_DIR/vote-${VOTE_ID}-round${round}.md"
    
    cat > "$round_response_file" << EOF
# Vote Responses - Round $round

**Vote ID**: ${VOTE_ID}
**Round**: ${round}/${NUM_ROUNDS}
**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Vote Question

${TOPIC}

---

## Options

EOF
    
    for ((i=0; i<NUM_OPTIONS; i++)); do
        echo "$((i+1)). ${options[$i]}" >> "$round_response_file"
    done
    
    cat >> "$round_response_file" << EOF

---

## Agent Votes

EOF
    
    # Route to each AI agent
    for agent_entry in "${AGENTS[@]}"; do
        agent_id=$(echo "$agent_entry" | cut -d: -f1)
        agent_name=$(echo "$agent_entry" | cut -d: -f2)
        
        echo -e "  ${BLUE}→${NC} Routing to ${agent_name}..."
        
        # Create agent-specific input file
        agent_input="$AGENTS_DIR/${agent_id}-vote-input-${VOTE_ID}-r${round}.md"
        
        cat > "$agent_input" << EOF
# Vote Input for ${agent_name} - Round ${round}

You are participating in a committee vote.

**Instructions**:
1. Review the question and all options
2. Consider the context provided
3. Cast your vote by selecting ONE option
4. Provide clear reasoning for your choice
5. Rate your confidence (High/Medium/Low)

---

## Question

${TOPIC}

---

## Options

EOF
        
        for ((i=0; i<NUM_OPTIONS; i++)); do
            echo "$((i+1)). ${options[$i]}" >> "$agent_input"
        done
        
        cat >> "$agent_input" << EOF

---

## Context

$(sed -n '/^## CONTEXT/,/^---/p' "$VOTE_FILE" | grep -v "^##" | grep -v "^---")

---

**Your Vote**:
- Option: [1-${NUM_OPTIONS}]
- Reasoning: [Your analysis]
- Confidence: [High/Medium/Low]

EOF
        
        # Placeholder for AI response
        # In production, this calls actual AI
        # For now, random vote for demonstration
        random_vote=$((RANDOM % NUM_OPTIONS + 1))
        
        agent_output="$AGENTS_DIR/${agent_id}-vote-output-${VOTE_ID}-r${round}.md"
        
        cat > "$agent_output" << EOF
### ${agent_name} - Round ${round}

**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')
**Vote**: Option ${random_vote} - ${options[$((random_vote-1))]}
**Reasoning**: [AI reasoning will be added here - currently placeholder]
**Confidence**: [AI confidence rating - currently placeholder]

---

EOF
        
        # Update vote count
        vote_counts[$((random_vote-1))]=$((${vote_counts[$((random_vote-1))]} + 1))
        
        # Append to round response file
        cat "$agent_output" >> "$round_response_file"
        
        # Also append to main vote file
        sed -i "/### Round $round/,/^###/{
            /<!-- Agents add responses here -->/a\\
$(cat "$agent_output")
        }" "$VOTE_FILE"
        
        echo -e "    ${GREEN}✓${NC} Vote cast: Option ${random_vote}"
    done
    
    echo ""
    echo -e "${GREEN}✓${NC} Round $round voting complete"
    echo ""
    
    # Update round status
    sed -i "/### Round $round/,/^$/s/Status.*In Progress/Status: ✅ Complete/" "$VOTE_FILE"
    
    # Pause between rounds
    if [ $round -lt $NUM_ROUNDS ]; then
        sleep 2
    fi
done

# Calculate final results
echo -e "${YELLOW}═══ CALCULATING RESULTS ═══${NC}"
echo ""

max_votes=0
winner_idx=0

for ((i=0; i<NUM_OPTIONS; i++)); do
    echo "Option $((i+1)): ${options[$i]} - ${vote_counts[$i]} votes"
    if [ ${vote_counts[$i]} -gt $max_votes ]; then
        max_votes=${vote_counts[$i]}
        winner_idx=$i
    fi
done

echo ""
echo -e "${GREEN}Winner: Option $((winner_idx+1)) - ${options[$winner_idx]}${NC}"
echo ""

# Generate summary
summary_file="$RESPONSES_DIR/vote-${VOTE_ID}-summary.md"

cat > "$summary_file" << EOF
# Committee Vote Summary

**Vote ID**: ${VOTE_ID}
**Topic**: ${TOPIC}
**Rounds Completed**: ${NUM_ROUNDS}
**Total Votes Cast**: $((${#AGENTS[@]} * NUM_ROUNDS))
**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Question

${TOPIC}

---

## Final Results

EOF

for ((i=0; i<NUM_OPTIONS; i++)); do
    percentage=$((${vote_counts[$i]} * 100 / (${#AGENTS[@]} * NUM_ROUNDS)))
    cat >> "$summary_file" << EOF
### Option $((i+1)): ${options[$i]}

**Votes**: ${vote_counts[$i]} / $((${#AGENTS[@]} * NUM_ROUNDS)) (${percentage}%)

EOF
done

cat >> "$summary_file" << EOF

---

## Winner

**🏆 Option $((winner_idx+1)): ${options[$winner_idx]}**

**Vote Count**: ${max_votes} / $((${#AGENTS[@]} * NUM_ROUNDS))

---

## Reasoning Summary

<!-- Synthesize all reasoning from agents -->

**Common Themes**:
1. [Theme 1]
2. [Theme 2]

**Key Arguments**:
- [Argument 1]
- [Argument 2]

---

**Files Generated**:
- Vote: \`${VOTE_FILE}\`
- Summary: \`${summary_file}\`
- Round responses: \`${RESPONSES_DIR}/vote-${VOTE_ID}-round*.md\`

EOF

# Update main vote file
sed -i "/^## FINAL RESULTS/,/^---/{
    s/Status.*Awaiting completion/Status: ✅ Complete/
    s/Winner.*TBD/Winner: Option $((winner_idx+1)) - ${options[$winner_idx]}/
    s/Summary.*TBD/Summary: See ${summary_file}/
}" "$VOTE_FILE"

# Update overall status
sed -i "s/Status.*ACTIVE/Status: ✅ COMPLETE/" "$VOTE_FILE"

echo -e "${GREEN}✅ Vote processing complete!${NC}"
echo ""
echo "Summary: $summary_file"
echo "Vote file: $VOTE_FILE"
echo ""

# Display summary
cat "$summary_file"
