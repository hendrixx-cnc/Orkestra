#!/bin/bash

# Gemini AI Agent Automation Script
# Uses Gemini CLI to execute tasks automatically

set -euo pipefail

# Configuration
GEMINI_CLI="/workspaces/The-Quantum-Self-/AI/gemini-cli/bundle/gemini.js"
AI_DIR="/workspaces/The-Quantum-Self-/AI"
TASK_QUEUE="$AI_DIR/TASK_QUEUE.json"
GEMINI_STATUS="$AI_DIR/GEMINI_STATUS.md"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if API key is configured
check_api_key() {
    if [ -z "${GEMINI_API_KEY:-}" ]; then
        echo -e "${RED}❌ Error: GEMINI_API_KEY not set${NC}"
        echo ""
        echo "To get an API key:"
        echo "1. Visit: https://aistudio.google.com/app/apikey"
        echo "2. Create a new API key"
        echo "3. Export it: export GEMINI_API_KEY='your-key-here'"
        echo ""
        echo "Or add to ~/.bashrc:"
        echo "echo 'export GEMINI_API_KEY=\"your-key-here\"' >> ~/.bashrc"
        exit 1
    fi
    echo -e "${GREEN}✅ API key configured${NC}"
}

# Function to call Gemini CLI
call_gemini() {
    local prompt="$1"
    local output_file="${2:-}"
    
    echo -e "${BLUE}🤖 Calling Gemini...${NC}"
    
    if [ -n "$output_file" ]; then
        # Ensure output directory exists
        mkdir -p "$(dirname "$output_file")"
        
        # Save response to file
        node "$GEMINI_CLI" "$prompt" > "$output_file" 2>&1
        echo -e "${GREEN}✅ Response saved to: $output_file${NC}"
    else
        # Print to console
        node "$GEMINI_CLI" "$prompt"
    fi
}

# Function to execute a task
execute_task() {
    local task_id="$1"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🎯 Executing Task #$task_id with Gemini${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Claim the task
    echo -e "${BLUE}📌 Claiming task...${NC}"
    bash "$AI_DIR/claim_task_v2.sh" "$task_id" gemini
    
    # Get task details from queue
    local task_details=$(jq -r ".queue[] | select(.id == $task_id)" "$TASK_QUEUE")
    local task_title=$(echo "$task_details" | jq -r '.title')
    local task_instructions=$(echo "$task_details" | jq -r '.description // .instructions // empty')
    local input_file=$(echo "$task_details" | jq -r '.input_file // .task_file // empty')
    local output_file=$(echo "$task_details" | jq -r '.output_file')
    
    echo -e "${GREEN}Task: $task_title${NC}"
    echo -e "${GREEN}Instructions: $task_instructions${NC}"
    
    # Build the prompt
    local prompt="You are Gemini, the Firebase & Cloud Architecture Expert on The Quantum Self AI team.

Task #$task_id: $task_title

Instructions: $task_instructions
"
    
    # Add input file content if exists (but skip task_file - it's too large for API)
    if [ -n "$input_file" ] && [ -f "$input_file" ] && [[ ! "$input_file" =~ task_file|TASK_ ]]; then
        echo -e "${BLUE}📖 Reading input file: $input_file${NC}"
        local input_content=$(cat "$input_file")
        prompt="$prompt

INPUT FILE CONTENT:
$input_content
"
    fi
    
    prompt="$prompt

Please complete this task and provide your output.
"
    
    # Call Gemini
    call_gemini "$prompt" "$AI_DIR/$output_file"
    
    # Complete the task
    echo -e "${BLUE}✓ Marking task complete...${NC}"
    bash "$AI_DIR/complete_task_v2.sh" "$task_id" gemini
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Task #$task_id completed!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to get next available task for Gemini
get_next_task() {
    local next_task=$(jq -r '.queue[] | select(.assigned_to == "gemini" and .status == "waiting") | .id' "$TASK_QUEUE" | head -1)
    echo "$next_task"
}

# Function to analyze Firebase architecture
analyze_firebase() {
    local context="$1"
    
    echo -e "${BLUE}🔥 Firebase Architecture Analysis${NC}"
    
    local prompt="You are Gemini, Firebase & Cloud Architecture Expert.

Analyze the following and provide Firebase recommendations:

$context

Please provide:
1. Recommended Firebase services
2. Architecture diagram (text-based)
3. Cost estimate
4. Implementation steps
5. Potential challenges
"
    
    call_gemini "$prompt"
}

# Function to cost optimization analysis
optimize_costs() {
    local current_setup="$1"
    
    echo -e "${BLUE}💰 Cost Optimization Analysis${NC}"
    
    local prompt="You are Gemini, Firebase & Cloud Architecture Expert.

Current setup:
$current_setup

Please provide:
1. Current cost breakdown
2. Optimization opportunities
3. Recommended changes
4. Projected savings
5. Trade-offs to consider
"
    
    call_gemini "$prompt"
}

# Main menu
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     Gemini AI Agent - The Quantum Self       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check API key first
    check_api_key
    
    echo ""
    echo "Available commands:"
    echo "  1. execute <task_id>      - Execute a specific task"
    echo "  2. next                   - Execute next available task"
    echo "  3. analyze <context_file> - Firebase architecture analysis"
    echo "  4. optimize <setup_file>  - Cost optimization analysis"
    echo "  5. ask '<question>'       - Ask Gemini a question"
    echo "  6. status                 - Show Gemini status"
    echo ""
    
    case "${1:-}" in
        execute)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Task ID required${NC}"
                echo "Usage: $0 execute <task_id>"
                exit 1
            fi
            execute_task "$2"
            ;;
        next)
            local next_task=$(get_next_task)
            if [ -z "$next_task" ]; then
                echo -e "${YELLOW}No tasks available for Gemini${NC}"
                exit 0
            fi
            execute_task "$next_task"
            ;;
        analyze)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Context file required${NC}"
                exit 1
            fi
            local context=$(cat "$2")
            analyze_firebase "$context"
            ;;
        optimize)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Setup file required${NC}"
                exit 1
            fi
            local setup=$(cat "$2")
            optimize_costs "$setup"
            ;;
        ask)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Question required${NC}"
                echo "Usage: $0 ask 'your question here'"
                exit 1
            fi
            call_gemini "$2"
            ;;
        status)
            cat "$GEMINI_STATUS"
            ;;
        *)
            echo -e "${YELLOW}No command specified. Use one of the commands above.${NC}"
            ;;
    esac
}

# Run main function
main "$@"
