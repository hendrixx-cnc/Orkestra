#!/bin/bash

# ChatGPT AI Agent Automation Script
# Uses shell-gpt CLI to execute tasks automatically

set -euo pipefail

# Configuration
CHATGPT_CLI="sgpt"
AI_DIR="/workspaces/The-Quantum-Self-/AI"
TASK_QUEUE="$AI_DIR/TASK_QUEUE.json"
CHATGPT_STATUS="$AI_DIR/CHATGPT_STATUS.md"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if API key is configured
check_api_key() {
    if [ -z "${OPENAI_API_KEY:-}" ]; then
        echo -e "${RED}❌ Error: OPENAI_API_KEY not set${NC}"
        echo ""
        echo "To get an API key:"
        echo "1. Visit: https://platform.openai.com/api-keys"
        echo "2. Create a new API key"
        echo "3. Export it: export OPENAI_API_KEY='your-key-here'"
        echo ""
        echo "Or add to ~/.bashrc:"
        echo "echo 'export OPENAI_API_KEY=\"your-key-here\"' >> ~/.bashrc"
        exit 1
    fi
    echo -e "${GREEN}✅ API key configured${NC}"
}

# Function to call ChatGPT CLI
call_chatgpt() {
    local prompt="$1"
    local output_file="${2:-}"
    
    echo -e "${BLUE}🤖 Calling ChatGPT...${NC}"
    
    if [ -n "$output_file" ]; then
        # Ensure output directory exists
        mkdir -p "$(dirname "$output_file")"
        
        # Save response to file
        $CHATGPT_CLI "$prompt" > "$output_file" 2>&1
        echo -e "${GREEN}✅ Response saved to: $output_file${NC}"
    else
        # Print to console
        $CHATGPT_CLI "$prompt"
    fi
}

# Function to execute a task
execute_task() {
    local task_id="$1"
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🎯 Executing Task #$task_id with ChatGPT${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Claim the task
    echo -e "${BLUE}📌 Claiming task...${NC}"
    bash "$AI_DIR/claim_task_v2.sh" "$task_id" chatgpt
    
    # Get task details from queue
    local task_details=$(jq -r ".queue[] | select(.id == $task_id)" "$TASK_QUEUE" 2>/dev/null || jq -r ".queue[] | select(.id == $task_id)" "$TASK_QUEUE" 2>/dev/null)
    local task_title=$(echo "$task_details" | jq -r '.title')
    local task_instructions=$(echo "$task_details" | jq -r '.description // .instructions // empty')
    local input_file=$(echo "$task_details" | jq -r '.input_file // .task_file // empty')
    local output_file=$(echo "$task_details" | jq -r '.output_file')
    
    echo -e "${GREEN}Task: $task_title${NC}"
    echo -e "${GREEN}Instructions: $task_instructions${NC}"
    
    # Build the prompt
    local prompt="You are ChatGPT, the Content Creator & Marketing Expert on The Quantum Self AI team.

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
    
    # Call ChatGPT
    call_chatgpt "$prompt" "$AI_DIR/$output_file"
    
    # Complete the task
    echo -e "${BLUE}✓ Marking task complete...${NC}"
    bash "$AI_DIR/complete_task_v2.sh" "$task_id" chatgpt
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Task #$task_id completed!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to get next available task for ChatGPT
get_next_task() {
    local next_task=$(jq -r '.queue[] | select(.assigned_to == "chatgpt" and .status == "waiting") | .id' "$TASK_QUEUE" 2>/dev/null | head -1)
    if [ -z "$next_task" ]; then
        next_task=$(jq -r '.queue[] | select(.assigned_to == "chatgpt" and .status == "waiting") | .id' "$TASK_QUEUE" 2>/dev/null | head -1)
    fi
    echo "$next_task"
}

# Function to generate marketing content
generate_marketing() {
    local context="$1"
    
    echo -e "${BLUE}📣 Marketing Content Generation${NC}"
    
    local prompt="You are ChatGPT, Content Creator & Marketing Expert.

Generate marketing content for:

$context

Please provide:
1. Compelling headline
2. Short description (150 words)
3. Long description (300-500 words)
4. 5 social media post variations
5. Call-to-action suggestions
"
    
    call_chatgpt "$prompt"
}

# Function to create social media content
create_social_media() {
    local topic="$1"
    
    echo -e "${BLUE}📱 Social Media Content Creation${NC}"
    
    local prompt="You are ChatGPT, Content Creator & Marketing Expert.

Create 5 engaging social media posts about:
$topic

Include:
- Twitter/X format (280 chars)
- LinkedIn format (professional)
- Instagram caption with hashtags
- Facebook post
- Threads/short-form content

Make them engaging, on-brand, and include relevant hashtags.
"
    
    call_chatgpt "$prompt"
}

# Main menu
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     ChatGPT AI Agent - The Quantum Self      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check API key first
    check_api_key
    
    echo ""
    echo "Available commands:"
    echo "  1. execute <task_id>      - Execute a specific task"
    echo "  2. next                   - Execute next available task"
    echo "  3. marketing <context>    - Generate marketing content"
    echo "  4. social <topic>         - Create social media posts"
    echo "  5. ask '<question>'       - Ask ChatGPT a question"
    echo "  6. status                 - Show ChatGPT status"
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
                echo -e "${YELLOW}No tasks available for ChatGPT${NC}"
                exit 0
            fi
            execute_task "$next_task"
            ;;
        marketing)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Context required${NC}"
                exit 1
            fi
            generate_marketing "$2"
            ;;
        social)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Topic required${NC}"
                exit 1
            fi
            create_social_media "$2"
            ;;
        ask)
            if [ -z "${2:-}" ]; then
                echo -e "${RED}Error: Question required${NC}"
                echo "Usage: $0 ask 'your question here'"
                exit 1
            fi
            call_chatgpt "$2"
            ;;
        status)
            if [ -f "$CHATGPT_STATUS" ]; then
                cat "$CHATGPT_STATUS"
            else
                echo "ChatGPT Status: Ready for assignment"
                echo "Role: Content Creator & Marketing Expert"
                echo "Specialties: Copywriting, marketing, creative content"
            fi
            ;;
        *)
            echo -e "${YELLOW}No command specified. Use one of the commands above.${NC}"
            ;;
    esac
}

# Run main function
main "$@"
