#!/bin/bash
# GEMINI AI ORCHESTRATOR
# Uses Gemini AI to intelligently coordinate tasks between Claude, Copilot, and ChatGPT
# Can send commands TO other AIs and receive status FROM them

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"
API_URL="http://localhost:3001/api/gemini"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Gemini API is available
check_gemini_available() {
    if [ -z "$GEMINI_API_KEY" ]; then
        echo -e "${RED}❌ GEMINI_API_KEY not set${NC}"
        echo "   Set it with: export GEMINI_API_KEY=your_key_here"
        return 1
    fi

    # Check if backend is running
    if ! curl -s http://localhost:3001/health > /dev/null 2>&1; then
        echo -e "${RED}❌ Backend server not running${NC}"
        echo "   Start with: cd backend && npm start"
        return 1
    fi

    echo -e "${GREEN}✅ Gemini AI is available${NC}"
    return 0
}

# Function: Ask Gemini to analyze a task and suggest the best AI
ask_gemini_delegate() {
    local task_id="$1"
    local task_title=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$TASK_QUEUE")
    local task_desc=$(jq -r ".queue[] | select(.id == $task_id) | .description" "$TASK_QUEUE")
    local task_type=$(jq -r ".queue[] | select(.id == $task_id) | .task_type // \"unknown\"" "$TASK_QUEUE")

    echo -e "${CYAN}🤖 Asking Gemini AI to analyze task #${task_id}...${NC}"

    # Create prompt for Gemini
    local prompt="You are an AI task orchestrator managing multiple AI agents:
- **Claude**: Best for complex reasoning, code review, documentation, and strategic planning
- **Copilot**: Best for code generation, technical implementation, and quick fixes
- **ChatGPT**: Best for creative content, copywriting, and brainstorming

Task to assign:
**ID:** ${task_id}
**Title:** ${task_title}
**Description:** ${task_desc}
**Type:** ${task_type}

Analyze this task and respond with ONLY a JSON object (no markdown, no extra text):
{
  \"ai\": \"Claude\" or \"Copilot\" or \"ChatGPT\",
  \"reasoning\": \"brief explanation\",
  \"priority\": \"high\" or \"medium\" or \"low\",
  \"estimated_time\": \"time estimate\",
  \"dependencies\": [list of task IDs this depends on]
}"

    # Call Gemini API (need auth token - using anonymous for now)
    local response=$(curl -s -X POST "$API_URL/chat" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer anonymous" \
        -d "{\"question\": $(echo "$prompt" | jq -Rs .)}" 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$response" ]; then
        # Extract the JSON response
        local gemini_response=$(echo "$response" | jq -r '.response // empty')

        if [ -n "$gemini_response" ]; then
            echo -e "${GREEN}✅ Gemini Analysis:${NC}"
            echo "$gemini_response" | jq '.' 2>/dev/null || echo "$gemini_response"

            # Extract recommended AI
            local recommended_ai=$(echo "$gemini_response" | jq -r '.ai // empty' 2>/dev/null)
            if [ -n "$recommended_ai" ]; then
                echo -e "\n${BLUE}📋 Recommended: ${YELLOW}${recommended_ai}${NC}"
                echo "$recommended_ai"
                return 0
            fi
        fi
    fi

    echo -e "${YELLOW}⚠️  Gemini unavailable, using default assignment${NC}"
    return 1
}

# Function: Send execution command to another AI
send_command_to_ai() {
    local target_ai="$1"
    local command="$2"
    local task_id="$3"

    echo -e "${PURPLE}📤 Sending command to ${target_ai}...${NC}"

    # Create command file for the target AI
    local command_file="$SCRIPT_DIR/commands/${target_ai}_command_$(date +%s).json"
    mkdir -p "$SCRIPT_DIR/commands"

    cat > "$command_file" << EOF
{
  "from": "Gemini",
  "to": "${target_ai}",
  "command": "${command}",
  "task_id": ${task_id},
  "timestamp": "$(date -Iseconds)",
  "status": "pending"
}
EOF

    echo -e "${GREEN}✅ Command queued: ${command_file}${NC}"

    # Also claim the task for the target AI
    bash "$SCRIPT_DIR/claim_task.sh" "$task_id" "$target_ai"
}

# Function: Receive status from another AI
receive_status_from_ai() {
    local source_ai="$1"

    echo -e "${CYAN}📥 Checking status from ${source_ai}...${NC}"

    # Look for status files from the AI
    local status_dir="$SCRIPT_DIR/status"
    mkdir -p "$status_dir"

    if [ -f "$status_dir/${source_ai}_status.json" ]; then
        local status=$(cat "$status_dir/${source_ai}_status.json")
        echo "$status" | jq '.'
        return 0
    else
        echo -e "${YELLOW}⚠️  No status from ${source_ai}${NC}"
        return 1
    fi
}

# Function: Intelligent task delegation using Gemini
delegate_task_with_gemini() {
    local task_id="$1"

    echo -e "\n${PURPLE}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   GEMINI AI TASK DELEGATION                   ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════╝${NC}\n"

    # Check if Gemini is available
    if ! check_gemini_available; then
        echo -e "${RED}Cannot proceed without Gemini AI${NC}"
        return 1
    fi

    # Ask Gemini to analyze and recommend
    local recommended_ai=$(ask_gemini_delegate "$task_id")

    if [ -n "$recommended_ai" ]; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}Delegating task #${task_id} to ${YELLOW}${recommended_ai}${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        # Send command to the recommended AI
        send_command_to_ai "$recommended_ai" "execute" "$task_id"

        # Log the delegation
        bash "$SCRIPT_DIR/task_audit.sh" log "delegation" \
            "Task #${task_id} delegated to ${recommended_ai} by Gemini AI"

        return 0
    else
        echo -e "${RED}❌ Failed to get recommendation from Gemini${NC}"
        return 1
    fi
}

# Function: Batch delegate multiple tasks
batch_delegate() {
    echo -e "${PURPLE}🚀 BATCH DELEGATION MODE${NC}\n"

    # Get all pending tasks
    local pending_tasks=$(jq -r '.queue[] | select(.status == "pending") | .id' "$TASK_QUEUE")

    if [ -z "$pending_tasks" ]; then
        echo -e "${YELLOW}No pending tasks to delegate${NC}"
        return 0
    fi

    local count=0
    for task_id in $pending_tasks; do
        echo -e "\n${BLUE}━━━ Processing Task #${task_id} ━━━${NC}"

        if delegate_task_with_gemini "$task_id"; then
            ((count++))
        fi

        # Small delay to avoid overwhelming the API
        sleep 2
    done

    echo -e "\n${GREEN}✅ Delegated ${count} tasks${NC}"
}

# Function: Coordination dashboard
coordination_dashboard() {
    clear
    echo -e "${PURPLE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     GEMINI AI ORCHESTRATION DASHBOARD                     ║${NC}"
    echo -e "${PURPLE}║     $(date '+%Y-%m-%d %H:%M:%S')                                     ║${NC}"
    echo -e "${PURPLE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

    # Check Gemini status
    check_gemini_available
    echo ""

    # Show pending commands
    echo -e "${CYAN}📤 PENDING COMMANDS:${NC}"
    local command_count=$(ls -1 "$SCRIPT_DIR/commands/"*_command_*.json 2>/dev/null | wc -l)
    echo "   ${command_count} commands queued"

    if [ $command_count -gt 0 ]; then
        for cmd_file in "$SCRIPT_DIR/commands/"*_command_*.json; do
            [ -f "$cmd_file" ] || continue
            local to_ai=$(jq -r '.to' "$cmd_file")
            local task_id=$(jq -r '.task_id' "$cmd_file")
            local status=$(jq -r '.status' "$cmd_file")
            echo -e "   ${YELLOW}→${NC} ${to_ai}: Task #${task_id} [${status}]"
        done
    fi

    echo ""

    # Show AI status
    echo -e "${CYAN}📊 AI STATUS:${NC}"
    for ai in Claude Copilot ChatGPT; do
        local task_count=$(jq -r ".queue[] | select(.assigned_to == \"$ai\" and .status == \"in_progress\") | .id" "$TASK_QUEUE" | wc -l)
        echo -e "   ${ai}: ${task_count} active tasks"
    done

    echo ""

    # Show recent delegations
    echo -e "${CYAN}📋 RECENT DELEGATIONS:${NC}"
    bash "$SCRIPT_DIR/task_audit.sh" query type delegation 5 2>/dev/null | grep -A 2 "delegation" | head -15
}

# Function: Watch mode - continuous coordination
watch_mode() {
    echo -e "${PURPLE}👁️  GEMINI WATCH MODE - Continuous Coordination${NC}"
    echo "   Press Ctrl+C to stop"
    echo ""

    while true; do
        coordination_dashboard

        # Auto-delegate any unassigned pending tasks
        local unassigned=$(jq -r '.queue[] | select(.status == "pending" and (.assigned_to == null or .assigned_to == "")) | .id' "$TASK_QUEUE" | head -1)

        if [ -n "$unassigned" ]; then
            echo -e "\n${YELLOW}⚡ Found unassigned task #${unassigned}, delegating...${NC}"
            delegate_task_with_gemini "$unassigned"
        fi

        echo -e "\n${BLUE}Next check in 30 seconds...${NC}"
        sleep 30
    done
}

# Function: Inter-AI communication test
test_communication() {
    echo -e "${PURPLE}🔬 TESTING INTER-AI COMMUNICATION${NC}\n"

    # Test 1: Send command to Claude
    echo -e "${BLUE}Test 1: Gemini → Claude${NC}"
    send_command_to_ai "Claude" "status_check" "999"
    echo ""

    # Test 2: Send command to Copilot
    echo -e "${BLUE}Test 2: Gemini → Copilot${NC}"
    send_command_to_ai "Copilot" "health_check" "999"
    echo ""

    # Test 3: Receive status from all AIs
    echo -e "${BLUE}Test 3: Receiving Status${NC}"
    for ai in Claude Copilot ChatGPT; do
        echo -e "\n${CYAN}From ${ai}:${NC}"
        receive_status_from_ai "$ai"
    done

    echo -e "\n${GREEN}✅ Communication test complete${NC}"
}

# Main command dispatcher
case "${1:-help}" in
    delegate)
        # Delegate a specific task
        if [ -z "$2" ]; then
            echo "Usage: $0 delegate <task_id>"
            exit 1
        fi
        delegate_task_with_gemini "$2"
        ;;

    batch)
        # Batch delegate all pending tasks
        batch_delegate
        ;;

    dashboard)
        # Show coordination dashboard
        coordination_dashboard
        ;;

    watch)
        # Continuous coordination mode
        watch_mode
        ;;

    send)
        # Send command to specific AI
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 send <ai_name> <command> [task_id]"
            exit 1
        fi
        send_command_to_ai "$2" "$3" "${4:-0}"
        ;;

    receive)
        # Receive status from specific AI
        if [ -z "$2" ]; then
            echo "Usage: $0 receive <ai_name>"
            exit 1
        fi
        receive_status_from_ai "$2"
        ;;

    test)
        # Test inter-AI communication
        test_communication
        ;;

    status)
        # Check Gemini status
        check_gemini_available
        ;;

    help|*)
        cat << 'HELP'
╔════════════════════════════════════════════════════════════╗
║           GEMINI AI ORCHESTRATOR                           ║
║   Intelligent coordination between Claude, Copilot & GPT   ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  ./gemini_orchestrator.sh <command> [options]

COMMANDS:
  delegate <task_id>      - Ask Gemini to analyze and delegate a task
  batch                   - Delegate all pending tasks intelligently
  dashboard               - Show coordination dashboard
  watch                   - Continuous coordination mode (auto-delegate)

  send <ai> <cmd> [task]  - Send command to another AI
  receive <ai>            - Receive status from another AI
  test                    - Test inter-AI communication
  status                  - Check Gemini availability

  help                    - Show this help

EXAMPLES:
  # Delegate a single task
  ./gemini_orchestrator.sh delegate 5

  # Auto-delegate all pending tasks
  ./gemini_orchestrator.sh batch

  # Start watch mode
  ./gemini_orchestrator.sh watch

  # Send command to Claude
  ./gemini_orchestrator.sh send Claude "execute" 7

  # Check status from Copilot
  ./gemini_orchestrator.sh receive Copilot

FLOW:
  1. Gemini analyzes task requirements
  2. Recommends best AI (Claude/Copilot/ChatGPT)
  3. Sends execution command to that AI
  4. Monitors status and coordinates follow-ups

BIDIRECTIONAL COMMUNICATION:
  → Gemini can SEND commands TO other AIs
  ← Gemini can RECEIVE status FROM other AIs
  ↔ Other AIs can REQUEST analysis FROM Gemini

REQUIREMENTS:
  - GEMINI_API_KEY environment variable
  - Backend server running (port 3001)
  - Task queue (TASK_QUEUE.json)
HELP
        ;;
esac
