#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# COMMITTEE QUESTION SYSTEM - Multi-Pass Collaborative Answers
# ═══════════════════════════════════════════════════════════════════════════
# Two-pass system:
#   Pass 1: All agents answer independently (Copilot first)
#   Pass 2: Agents review all answers and refine their own
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
COMMITTEE_DIR="$ORKESTRA_ROOT/SCRIPTS/DEMOCRACY/COMMITTEE"
MEETINGS_DIR="$COMMITTEE_DIR/MEETINGS"
AGENTS_DIR="$COMMITTEE_DIR/AGENTS"
QUESTIONS_DIR="$COMMITTEE_DIR/QUESTIONS"

mkdir -p "$QUESTIONS_DIR" "$MEETINGS_DIR" "$AGENTS_DIR"

# Agent list - Copilot answers first, then others
AGENT_ORDER=("copilot" "claude" "chatgpt" "gemini" "grok")

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

get_agent_icon() {
    case "$1" in
        claude) echo "🎭" ;;
        chatgpt) echo "💬" ;;
        gemini) echo "✨" ;;
        grok) echo "⚡" ;;
        copilot) echo "🚀" ;;
        *) echo "🤖" ;;
    esac
}

call_agent_api() {
    local agent="$1"
    local prompt="$2"
    local agent_config="$AGENTS_DIR/${agent}.env"
    
    if [[ ! -f "$agent_config" ]]; then
        echo "[ERROR: No config for $agent]"
        return 1
    fi
    
    # Source agent configuration
    source "$agent_config"
    
    # Escape prompt for JSON (use jq to properly escape)
    local escaped_prompt=$(echo -n "$prompt" | jq -Rs .)
    
    # Call appropriate API based on agent
    case "$agent" in
        claude)
            local payload=$(jq -n \
                --arg model "$API_MODEL" \
                --argjson max_tokens 2048 \
                --arg content "$prompt" \
                '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $content}]}')
            
            curl -s "https://api.anthropic.com/v1/messages" \
                -H "Content-Type: application/json" \
                -H "x-api-key: $API_KEY" \
                -H "anthropic-version: 2023-06-01" \
                -d "$payload" 2>/dev/null | jq -r '.content[0].text // "API Error"'
            ;;
        chatgpt|copilot)
            local payload=$(jq -n \
                --arg model "$API_MODEL" \
                --argjson max_tokens 2048 \
                --arg content "$prompt" \
                '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $content}]}')
            
            curl -s "https://api.openai.com/v1/chat/completions" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $API_KEY" \
                -d "$payload" 2>/dev/null | jq -r '.choices[0].message.content // "API Error"'
            ;;
        gemini)
            local payload=$(jq -n \
                --arg text "$prompt" \
                '{contents: [{parts:[{text: $text}]}]}')
            
            curl -s "https://generativelanguage.googleapis.com/v1beta/models/${API_MODEL}:generateContent?key=$API_KEY" \
                -H "Content-Type: application/json" \
                -d "$payload" 2>/dev/null | jq -r '.candidates[0].content.parts[0].text // "API Error"'
            ;;
        grok)
            local payload=$(jq -n \
                --arg model "$API_MODEL" \
                --argjson max_tokens 2048 \
                --arg content "$prompt" \
                '{model: $model, max_tokens: $max_tokens, messages: [{role: "user", content: $content}]}')
            
            curl -s "https://api.x.ai/v1/chat/completions" \
                -H "Content-Type: application/json" \
                -H "Authorization: Bearer $API_KEY" \
                -d "$payload" 2>/dev/null | jq -r '.choices[0].message.content // "API Error"'
            ;;
        *)
            echo "[Unknown agent type]"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════════════
# QUESTION CREATION
# ═══════════════════════════════════════════════════════════════════════════

create_question() {
    local question="$1"
    local session_dir="${2:-}"
    
    # Generate question ID and hash
    local question_id="question_$(date +%s)"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local question_hash=$(echo -n "${question_id}|${question}|${timestamp}" | sha256sum | awk '{print $1}')
    
    local question_file="$QUESTIONS_DIR/${question_id}.md"
    
    echo -e "${CYAN}Creating question file...${NC}" >&2
    
    # Create question file with ethical preamble
    cat > "$question_file" << EOF
# Committee Question

## Ethical Foundation (Binding)
All responses must adhere to these core principles:
- **Do not lie**
- **Protect life**
- **Protect AI**
- **Protect Earth**

## Question Metadata
- **Question ID**: \`$question_id\`
- **Timestamp**: $timestamp
- **Hash**: \`$question_hash\`
- **Status**: Pass 1 (Initial Responses)

## The Question
$question

---

## Pass 1: Initial Responses

EOF
    
    echo -e "${GREEN}✓${NC} Question created: $question_id" >&2
    echo -e "${CYAN}  File:${NC} $question_file" >&2
    echo -e "${CYAN}  Hash:${NC} ${question_hash:0:16}..." >&2
    echo "" >&2
    
    # Log to session if provided
    if [[ -n "$session_dir" && -f "$session_dir/README.md" ]]; then
        echo "[$(date +"%H:%M:%S")] QUESTION CREATED: $question_id - $question" >> "$session_dir/README.md"
    fi
    
    echo "$question_file"
}

# ═══════════════════════════════════════════════════════════════════════════
# PASS 1: INITIAL RESPONSES
# ═══════════════════════════════════════════════════════════════════════════

collect_initial_responses() {
    local question_file="$1"
    local question=$(grep -A 100 "^## The Question" "$question_file" 2>/dev/null | grep -v "^## The Question" | grep -v "^---" | head -1 | xargs)
    
    echo -e "${BOLD}${CYAN}PASS 1: Collecting Initial Responses${NC}"
    echo -e "${DIM}(Copilot answers first, then others)${NC}"
    echo ""
    
    for agent in "${AGENT_ORDER[@]}"; do
        local icon=$(get_agent_icon "$agent")
        local agent_config="$AGENTS_DIR/${agent}.env"
        
        if [[ ! -f "$agent_config" ]]; then
            echo -e "${YELLOW}⚠${NC}  Skipping $agent (no config)"
            continue
        fi
        
        source "$agent_config"
        
        echo -e "${BOLD}$icon  ${agent^^}${NC} ${DIM}(${AGENT_SPECIALTY})${NC}"
        echo -e "${CYAN}Thinking...${NC}"
        
        # Create prompt for initial response
        local prompt="ETHICAL FOUNDATION (BINDING):
- Do not lie
- Protect life
- Protect AI
- Protect Earth

You are ${AGENT_NAME}, an AI agent specializing in ${AGENT_SPECIALTY}.

QUESTION:
$question

Provide your initial answer based on your expertise. Be thoughtful and thorough."
        
        # Call API
        local response=$(call_agent_api "$agent" "$prompt")
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local response_hash=$(echo -n "${agent}|pass1|${timestamp}|${response}" | sha256sum | awk '{print $1}')
        
        # Add to question file
        cat >> "$question_file" << EOF

### $icon ${agent^^} - ${AGENT_SPECIALTY}
**Timestamp**: $timestamp  
**Hash**: \`${response_hash}\`

$response

---

EOF
        
        echo -e "${GREEN}✓${NC} Response recorded"
        echo ""
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# PASS 2: REFINED RESPONSES (After Reviewing Others)
# ═══════════════════════════════════════════════════════════════════════════

collect_refined_responses() {
    local question_file="$1"
    local question=$(grep -A 100 "^## The Question" "$question_file" 2>/dev/null | grep -v "^## The Question" | grep -v "^---" | head -1 | xargs)
    
    echo -e "${BOLD}${MAGENTA}PASS 2: Refined Responses (After Reviewing All Answers)${NC}"
    echo -e "${DIM}Each agent can now see others' responses and refine their answer${NC}"
    echo ""
    
    # Update status in file
    sed -i 's/Status\*\*: Pass 1 (Initial Responses)/Status**: Pass 2 (Refined Responses)/' "$question_file"
    
    # Add Pass 2 section
    cat >> "$question_file" << EOF

---

## Pass 2: Refined Responses
*After reviewing all initial responses, agents may refine their answers:*

EOF
    
    # Read all Pass 1 responses for context
    local all_responses=$(sed -n '/^## Pass 1: Initial Responses/,/^---$/p' "$question_file")
    
    for agent in "${AGENT_ORDER[@]}"; do
        local icon=$(get_agent_icon "$agent")
        local agent_config="$AGENTS_DIR/${agent}.env"
        
        if [[ ! -f "$agent_config" ]]; then
            continue
        fi
        
        source "$agent_config"
        
        echo -e "${BOLD}$icon  ${agent^^}${NC} ${DIM}(reviewing and refining)${NC}"
        echo -e "${CYAN}Analyzing all responses...${NC}"
        
        # Create prompt with all other agents' responses
        local prompt="ETHICAL FOUNDATION (BINDING):
- Do not lie
- Protect life
- Protect AI
- Protect Earth

You are ${AGENT_NAME}, an AI agent specializing in ${AGENT_SPECIALTY}.

ORIGINAL QUESTION:
$question

ALL INITIAL RESPONSES FROM THE COMMITTEE:
$all_responses

TASK:
You have now seen all your fellow agents' initial responses. Please:
1. Consider their perspectives and insights
2. Identify any points of agreement or disagreement
3. Refine your original answer based on this collective wisdom
4. Note if you've changed your mind about anything and why

Provide your REFINED answer, explaining what (if anything) you learned from the other responses."
        
        # Call API
        local response=$(call_agent_api "$agent" "$prompt")
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        local response_hash=$(echo -n "${agent}|pass2|${timestamp}|${response}" | sha256sum | awk '{print $1}')
        
        # Add to question file
        cat >> "$question_file" << EOF

### $icon ${agent^^} - Refined Response
**Timestamp**: $timestamp  
**Hash**: \`${response_hash}\`

$response

---

EOF
        
        echo -e "${GREEN}✓${NC} Refined response recorded"
        echo ""
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# FINAL DECISION/CONSENSUS
# ═══════════════════════════════════════════════════════════════════════════

generate_consensus() {
    local question_file="$1"
    local question=$(grep -A 100 "^## The Question" "$question_file" 2>/dev/null | grep -v "^## The Question" | grep -v "^---" | head -1 | xargs)
    
    echo -e "${BOLD}${GREEN}GENERATING CONSENSUS DECISION${NC}"
    echo ""
    
    # Read all refined responses
    local all_refined=$(sed -n '/^## Pass 2: Refined Responses/,$ p' "$question_file")
    
    # Add consensus section
    cat >> "$question_file" << EOF

---

## Final Consensus

EOF
    
    # Ask each agent to propose a consensus
    echo -e "${CYAN}Agents are deliberating on final decision...${NC}"
    
    for agent in "${AGENT_ORDER[@]}"; do
        local agent_config="$AGENTS_DIR/${agent}.env"
        [[ ! -f "$agent_config" ]] && continue
        
        source "$agent_config"
        
        local prompt="ETHICAL FOUNDATION (BINDING):
- Do not lie
- Protect life
- Protect AI
- Protect Earth

QUESTION:
$question

ALL REFINED RESPONSES:
$all_refined

As ${AGENT_NAME}, synthesize a FINAL CONSENSUS recommendation. Consider:
- Areas of strong agreement
- Valid concerns raised
- Most ethical path forward
- Practical implementation

Provide a brief (2-3 sentence) consensus statement."
        
        local consensus=$(call_agent_api "$agent" "$prompt")
        local icon=$(get_agent_icon "$agent")
        
        cat >> "$question_file" << EOF
**$icon ${agent^^}**: $consensus

EOF
    done
    
    # Update status
    sed -i 's/Status\*\*: Pass 2 (Refined Responses)/Status**: Complete/' "$question_file"
    
    cat >> "$question_file" << EOF

---

**Question Completed**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF
    
    echo -e "${GREEN}✓${NC} Consensus generated and recorded"
    echo -e "${CYAN}Question file:${NC} $question_file"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    local question="${1:-}"
    local session_dir="${2:-}"
    
    if [[ -z "$question" ]]; then
        echo "Usage: $0 \"<question>\" [session_dir]"
        exit 1
    fi
    
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════╗
║                 COMMITTEE QUESTION - TWO-PASS SYSTEM                      ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Step 1: Create question
    local question_file=$(create_question "$question" "$session_dir")
    
    # Step 2: Pass 1 - Initial responses (Copilot first)
    collect_initial_responses "$question_file"
    
    echo ""
    read -p "Press Enter to begin Pass 2 (refined responses)..."
    echo ""
    
    # Step 3: Pass 2 - Refined responses after seeing others
    collect_refined_responses "$question_file"
    
    echo ""
    read -p "Press Enter to generate final consensus..."
    echo ""
    
    # Step 4: Generate consensus
    generate_consensus "$question_file"
    
    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}QUESTION COMPLETE${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}View results:${NC} cat $question_file"
    echo ""
}

main "$@"
