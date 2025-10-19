#!/bin/bash
# Process Question - Routes question through AI agents in rounds
# Each agent reviews previous responses and adds their input

QUESTION_FILE="$1"
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

# AI Agents (can be extended)
AGENTS=(
    "copilot:GitHub Copilot"
    "claude:Claude"
    "chatgpt:ChatGPT"
    "gemini:Gemini"
    "grok:Grok"
)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         PROCESSING COMMITTEE QUESTION                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Extract question details
QUESTION_ID=$(grep "^\*\*ID\*\*:" "$QUESTION_FILE" | cut -d: -f2- | xargs)
TOPIC=$(grep "^\*\*Topic\*\*:" "$QUESTION_FILE" | cut -d: -f2- | xargs)

echo -e "${GREEN}Question ID:${NC} $QUESTION_ID"
echo -e "${GREEN}Topic:${NC} $TOPIC"
echo -e "${GREEN}Rounds:${NC} $NUM_ROUNDS"
echo ""

# Process each round
for ((round=1; round<=NUM_ROUNDS; round++)); do
    echo -e "${YELLOW}═══ ROUND $round/$NUM_ROUNDS ═══${NC}"
    echo ""
    
    # Update round status
    sed -i "/### Round $round/,/^$/s/Status.*Pending/Status: 🔄 In Progress/" "$QUESTION_FILE"
    
    # Create round-specific response file
    round_response_file="$RESPONSES_DIR/question-${QUESTION_ID}-round${round}.md"
    
    cat > "$round_response_file" << EOF
# Question Responses - Round $round

**Question ID**: ${QUESTION_ID}
**Round**: ${round}/${NUM_ROUNDS}
**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Original Question

$(sed -n '/^## QUESTION/,/^---/p' "$QUESTION_FILE" | grep -v "^##" | grep -v "^---")

---

EOF
    
    # If not first round, include previous round's responses
    if [ $round -gt 1 ]; then
        prev_round=$((round - 1))
        cat >> "$round_response_file" << EOF
## Previous Round Summary

$(cat "$RESPONSES_DIR/question-${QUESTION_ID}-round${prev_round}.md" 2>/dev/null | tail -20)

---

EOF
    fi
    
    cat >> "$round_response_file" << EOF
## Agent Responses

EOF
    
    # Route to each AI agent
    for agent_entry in "${AGENTS[@]}"; do
        agent_id=$(echo "$agent_entry" | cut -d: -f1)
        agent_name=$(echo "$agent_entry" | cut -d: -f2)
        
        echo -e "  ${BLUE}→${NC} Routing to ${agent_name}..."
        
        # Create agent-specific input file
        agent_input="$AGENTS_DIR/${agent_id}-input-${QUESTION_ID}-r${round}.md"
        
        cat > "$agent_input" << EOF
# Input for ${agent_name} - Round ${round}

You are participating in a committee question review process.

**Your role**: Provide analysis, insights, and recommendations.

**Instructions**:
1. Read the question and context below
2. Review previous responses if this is not Round 1
3. Provide your unique perspective and analysis
4. Add specific, actionable recommendations
5. Keep response concise but thorough

---

$(cat "$round_response_file")

---

**Your Response** (${agent_name}):

EOF
        
        # Placeholder for AI integration
        # In production, this would call the actual AI API
        # For now, create a template response
        
        agent_output="$AGENTS_DIR/${agent_id}-output-${QUESTION_ID}-r${round}.md"
        
        cat > "$agent_output" << EOF
### ${agent_name} - Round ${round}

**Timestamp**: $(date '+%Y-%m-%d %H:%M:%S')
**Status**: ⏳ Awaiting AI response

**Analysis**: [AI response will be added here]

**Recommendations**: [AI recommendations will be added here]

**Confidence**: [High/Medium/Low]

---

EOF
        
        # Append to round response file
        cat "$agent_output" >> "$round_response_file"
        
        # Also append to main question file
        sed -i "/### Round $round/,/^###/{
            /<!-- Each AI adds response here -->/a\\
$(cat "$agent_output")
        }" "$QUESTION_FILE"
        
        echo -e "    ${GREEN}✓${NC} Input prepared: $agent_input"
    done
    
    echo ""
    echo -e "${GREEN}✓${NC} Round $round responses prepared"
    echo ""
    
    # Update round status
    sed -i "/### Round $round/,/^$/s/Status.*In Progress/Status: ✅ Complete/" "$QUESTION_FILE"
    
    # Pause between rounds if not last round
    if [ $round -lt $NUM_ROUNDS ]; then
        echo "Waiting for AI responses before next round..."
        echo "(In production, this waits for actual AI responses)"
        sleep 2
        echo ""
    fi
done

# Generate final summary
echo -e "${YELLOW}═══ GENERATING SUMMARY ═══${NC}"
echo ""

summary_file="$RESPONSES_DIR/question-${QUESTION_ID}-summary.md"

cat > "$summary_file" << EOF
# Committee Question Summary

**Question ID**: ${QUESTION_ID}
**Topic**: ${TOPIC}
**Rounds Completed**: ${NUM_ROUNDS}
**Generated**: $(date '+%Y-%m-%d %H:%M:%S')

---

## Original Question

$(sed -n '/^## QUESTION/,/^---/p' "$QUESTION_FILE" | grep -v "^##" | grep -v "^---")

---

## Summary of All Responses

EOF

# Collect all agent responses
for ((round=1; round<=NUM_ROUNDS; round++)); do
    echo "### Round $round" >> "$summary_file"
    echo "" >> "$summary_file"
    cat "$RESPONSES_DIR/question-${QUESTION_ID}-round${round}.md" >> "$summary_file" 2>/dev/null
    echo "" >> "$summary_file"
done

cat >> "$summary_file" << EOF

---

## Consolidated Recommendations

<!-- This section synthesizes all AI recommendations -->

**Key Insights**:
1. [Synthesize common themes]
2. [Highlight unique perspectives]
3. [Note areas of agreement/disagreement]

**Recommended Actions**:
1. [Action item 1]
2. [Action item 2]
3. [Action item 3]

**Next Steps**:
- [Next step 1]
- [Next step 2]

---

**Files Generated**:
- Question: \`${QUESTION_FILE}\`
- Summary: \`${summary_file}\`
- Round responses: \`${RESPONSES_DIR}/question-${QUESTION_ID}-round*.md\`

EOF

# Update main question file with summary
sed -i "/^## CONSOLIDATED RESPONSE/,/^---/{
    s/Status.*Awaiting completion/Status: ✅ Complete/
    /Summary.*TBD/c\\
**Summary**: See ${summary_file}
}" "$QUESTION_FILE"

# Update overall status
sed -i "s/Status.*ACTIVE/Status: ✅ COMPLETE/" "$QUESTION_FILE"

echo -e "${GREEN}✅ Question processing complete!${NC}"
echo ""
echo "Summary: $summary_file"
echo "Question file: $QUESTION_FILE"
echo ""

# Display summary
cat "$summary_file"
