#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# COMMITTEE OF HUMAN-AI AFFAIRS
# ═══════════════════════════════════════════════════════════════════════════
# Interactive system for AI agent collaboration and decision-making
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
ARCHIVES_DIR="$COMMITTEE_DIR/ARCHIVES"
DEMOCRACY_ENGINE="$ORKESTRA_ROOT/SCRIPTS/DEMOCRACY/democracy-engine.sh"
AGENT_VOTER="$ORKESTRA_ROOT/SCRIPTS/AGENTS/agent-voter.sh"

# Ensure directories exist
mkdir -p "$MEETINGS_DIR" "$AGENTS_DIR" "$ARCHIVES_DIR"

# Agent list
AGENTS=("claude" "chatgpt" "gemini" "grok" "copilot")

# ═══════════════════════════════════════════════════════════════════════════
# AGENT API KEY SETUP
# ═══════════════════════════════════════════════════════════════════════════

setup_agent_keys() {
    echo -e "${CYAN}Setting up agent API keys...${NC}"
    
    # Create individual agent config files
    cat > "$AGENTS_DIR/claude.env" << EOF
# Claude API Configuration
AGENT_NAME="claude"
AGENT_ICON="🎭"
AGENT_SPECIALTY="Architecture, Design, UX"
API_KEY="\${ANTHROPIC_API_KEY}"
# NOTE: model names vary by Anthropic account; use a safe generic fallback. If you have access to
# newer/sonnet variants, update API_MODEL accordingly. (Previous sonnet versions caused not_found errors.)
API_MODEL="claude-3"
API_ENDPOINT="https://api.anthropic.com/v1/messages"
EOF

    cat > "$AGENTS_DIR/chatgpt.env" << EOF
# ChatGPT API Configuration
AGENT_NAME="chatgpt"
AGENT_ICON="💬"
AGENT_SPECIALTY="Content, Writing, Documentation"
API_KEY="\${OPENAI_API_KEY}"
API_MODEL="gpt-4"
API_ENDPOINT="https://api.openai.com/v1/chat/completions"
EOF

    cat > "$AGENTS_DIR/gemini.env" << EOF
# Gemini API Configuration
AGENT_NAME="gemini"
AGENT_ICON="✨"
AGENT_SPECIALTY="Cloud, Database, Storage"
API_KEY="\${GOOGLE_API_KEY}"
API_MODEL="gemini-pro"
API_ENDPOINT="https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
EOF

    cat > "$AGENTS_DIR/grok.env" << EOF
# Grok API Configuration
AGENT_NAME="grok"
AGENT_ICON="⚡"
AGENT_SPECIALTY="Innovation, Research, Analysis"
API_KEY="\${XAI_API_KEY}"
API_MODEL="grok-beta"
API_ENDPOINT="https://api.x.ai/v1/chat/completions"
EOF

    cat > "$AGENTS_DIR/copilot.env" << EOF
# Copilot API Configuration
AGENT_NAME="copilot"
AGENT_ICON="🚀"
AGENT_SPECIALTY="Code, Deployment, DevOps"
API_KEY="\${GITHUB_TOKEN}"
API_MODEL="gpt-4"
API_ENDPOINT="https://api.github.com/copilot"
EOF

    echo -e "${GREEN}✓${NC} Agent configurations created in $AGENTS_DIR"
}

# ═══════════════════════════════════════════════════════════════════════════
# MEETING SESSION
# ═══════════════════════════════════════════════════════════════════════════

create_meeting_session() {
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local session_dir="$MEETINGS_DIR/$timestamp"
    
    mkdir -p "$session_dir"
    
    cat > "$session_dir/README.md" << EOF
# Committee Meeting Session
**Date:** $(date +"%Y-%m-%d")
**Time:** $(date +"%H:%M:%S %Z")
**Session ID:** $timestamp

## Participants
🎭 Claude - Architecture Specialist
💬 ChatGPT - Content & Documentation
✨ Gemini - Cloud & Storage
⚡ Grok - Innovation & Research
🚀 Copilot - Code & Deployment

## Agenda
- Items to be added during session

## Minutes
- Session log below

---

EOF
    
    echo "$session_dir"
}

log_to_meeting() {
    local session_dir="$1"
    local message="$2"
    local timestamp=$(date +"%H:%M:%S")
    
    echo "[$timestamp] $message" >> "$session_dir/README.md"
}

# ═══════════════════════════════════════════════════════════════════════════
# VOTE CREATION
# ═══════════════════════════════════════════════════════════════════════════

take_vote() {
    local session_dir="$1"
    
    echo ""
    echo -e "${BOLD}${CYAN}CREATE NEW VOTE${NC}"
    echo ""
    
    # Vote type
    echo -e "${CYAN}Vote Type:${NC}"
    echo "  1) task_assignment"
    echo "  2) decision"
    echo "  3) execution_order"
    read -p "Select (1-3): " vote_type_choice
    
    case "$vote_type_choice" in
        1) local vote_type="task_assignment" ;;
        2) local vote_type="decision" ;;
        3) local vote_type="execution_order" ;;
        *) echo "Invalid choice"; return 1 ;;
    esac
    
    # Title
    read -p "Vote Title: " title
    
    # Options
    read -p "Options (comma-separated): " options
    
    # Domain
    echo -e "${CYAN}Domain:${NC}"
    echo "  1) general"
    echo "  2) architecture"
    echo "  3) content"
    echo "  4) cloud"
    echo "  5) innovation"
    echo "  6) deployment"
    read -p "Select (1-6): " domain_choice
    
    case "$domain_choice" in
        1) local domain="general" ;;
        2) local domain="architecture" ;;
        3) local domain="content" ;;
        4) local domain="cloud" ;;
        5) local domain="innovation" ;;
        6) local domain="deployment" ;;
        *) local domain="general" ;;
    esac
    
    # Threshold
    read -p "Threshold (0.5=majority, 0.66=supermajority, 1.0=unanimous) [0.5]: " threshold
    threshold=${threshold:-0.5}
    
    # Create vote
    echo ""
    echo -e "${CYAN}Creating vote...${NC}"
    local vote_output=$("$DEMOCRACY_ENGINE" create "$vote_type" "$title" "$options" "$domain" "$threshold" 2>&1)
    local vote_id=$(echo "$vote_output" | grep "Vote created:" | awk '{print $4}')
    
    echo "$vote_output"
    echo ""
    
    # Log to meeting
    log_to_meeting "$session_dir" "VOTE CREATED: $vote_id - $title"
    
    # Notify agents
    echo -e "${CYAN}Notifying agents...${NC}"
    "$ORKESTRA_ROOT/SCRIPTS/DEMOCRACY/vote-monitor.sh" once >/dev/null 2>&1
    
    # Trigger agent voting
    echo -e "${CYAN}Agents are voting...${NC}"
    for agent in "${AGENTS[@]}"; do
        "$AGENT_VOTER" "$agent" once 2>&1 | grep "Voting\|✓" || true
    done
    
    echo ""
    read -p "Press Enter to see results..."
    
    # Tally
    "$DEMOCRACY_ENGINE" tally "$vote_id"
    
    log_to_meeting "$session_dir" "VOTE TALLIED: $vote_id"
    
    echo ""
    read -p "Show individual votes? (y/n): " show_individual
    if [[ "$show_individual" == "y" ]]; then
        "$DEMOCRACY_ENGINE" individual "$vote_id"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ASK QUESTION - Two-Pass System
# ═══════════════════════════════════════════════════════════════════════════

ask_question() {
    local session_dir="$1"
    
    echo ""
    echo -e "${BOLD}${CYAN}ASK THE COMMITTEE A QUESTION${NC}"
    echo -e "${DIM}Two-pass system: Initial responses → Review others → Refined answers → Consensus${NC}"
    echo ""
    
    read -p "Your question: " question
    
    if [[ -z "$question" ]]; then
        echo -e "${RED}✗${NC} Question cannot be empty"
        return 1
    fi
    
    echo ""
    log_to_meeting "$session_dir" "QUESTION: $question"
    
    # Call the two-pass question script
    "$COMMITTEE_DIR/ask-question.sh" "$question" "$session_dir"
    
    # Link the question file to the session
    local latest_question=$(ls -t "$COMMITTEE_DIR/QUESTIONS"/question_*.md 2>/dev/null | head -1)
    if [[ -f "$latest_question" ]]; then
        local question_id=$(basename "$latest_question" .md)
        ln -sf "$latest_question" "$session_dir/${question_id}.md" 2>/dev/null || true
        log_to_meeting "$session_dir" "QUESTION COMPLETE: See ${question_id}.md"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════════════════

show_header() {
    clear
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║           COMMITTEE OF HUMAN-AI AFFAIRS                                   ║
║                                                                           ║
║           Multi-AI Collaborative Decision-Making System                   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_menu() {
    echo -e "${BOLD}COMMITTEE MEMBERS:${NC}"
    echo -e "  🎭 Claude    - Architecture, Design, UX"
    echo -e "  💬 ChatGPT   - Content, Writing, Documentation"
    echo -e "  ✨ Gemini    - Cloud, Database, Storage"
    echo -e "  ⚡ Grok      - Innovation, Research, Analysis"
    echo -e "  🚀 Copilot   - Code, Deployment, DevOps"
    echo ""
    echo -e "${BOLD}ACTIONS:${NC}"
    echo -e "  ${GREEN}1${NC}) Take a Vote        - Create vote and get agent consensus"
    echo -e "  ${GREEN}2${NC}) Ask a Question     - Get opinions from all agents"
    echo -e "  ${GREEN}3${NC}) View Open Votes    - See pending votes"
    echo -e "  ${GREEN}4${NC}) View Past Meetings - Browse archived sessions"
    echo -e "  ${GREEN}5${NC}) Setup Agent Keys   - Configure API access"
    echo -e "  ${GREEN}q${NC}) Exit Committee"
    echo ""
}

main() {
    # Setup if needed
    if [[ ! -f "$AGENTS_DIR/claude.env" ]]; then
        setup_agent_keys
        echo ""
    fi
    
    # Create session
    local session_dir=$(create_meeting_session)
    echo -e "${GREEN}✓${NC} Meeting session started: $(basename "$session_dir")"
    echo ""
    
    while true; do
        show_header
        echo -e "${CYAN}Session:${NC} $(basename "$session_dir")"
        echo ""
        show_menu
        
        read -p "Select action: " choice
        
        case "$choice" in
            1)
                take_vote "$session_dir"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                ask_question "$session_dir"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                echo ""
                "$DEMOCRACY_ENGINE" list open
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                echo ""
                echo -e "${CYAN}Past Meetings:${NC}"
                ls -1 "$MEETINGS_DIR" | tail -10
                echo ""
                read -p "Press Enter to continue..."
                ;;
            5)
                setup_agent_keys
                echo ""
                read -p "Press Enter to continue..."
                ;;
            q|Q)
                echo ""
                echo -e "${CYAN}Closing committee session...${NC}"
                log_to_meeting "$session_dir" "SESSION ENDED"
                echo -e "${GREEN}✓${NC} Meeting minutes saved to: $session_dir"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
