#!/bin/bash

# Claude AI Agent for The Quantum Self
# Uses Anthropic Python SDK for Claude API access
# Part of the 4-AI coordination system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_CLI="$SCRIPT_DIR/claude_cli.py"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if API key is set
check_api_key() {
    if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
        echo -e "${RED}❌ Error: ANTHROPIC_API_KEY not set${NC}"
        echo ""
        echo "Please set your Anthropic API key:"
        echo "  export ANTHROPIC_API_KEY='sk-ant-...'"
        echo ""
        echo "Or add to ~/.bashrc:"
        echo "  echo 'export ANTHROPIC_API_KEY=\"sk-ant-...\"' >> ~/.bashrc"
        exit 1
    fi
}

# Call Claude API
call_claude() {
    local prompt="$1"
    python3 "$CLAUDE_CLI" "$prompt"
}

# Execute a specific task
execute_task() {
    local task_id="$1"
    
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Claude AI Agent - The Quantum Self       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Claim the task using standardized claim script
    echo "📋 Claiming task #$task_id..."
    if ! bash "$SCRIPT_DIR/claim_task_v2.sh" "$task_id" claude; then
        echo -e "${RED}❌ Failed to claim task${NC}"
        exit 1
    fi
    
    # Read task from TASK_QUEUE.json
    local task_file="$SCRIPT_DIR/TASK_QUEUE.json"
    if [ ! -f "$task_file" ]; then
        echo -e "${RED}❌ TASK_QUEUE.json not found${NC}"
        bash "$SCRIPT_DIR/task_lock.sh" release "$task_id"
        exit 1
    fi
    
    # Extract task details
    local task_description=$(jq -r ".queue[] | select(.id == $task_id) | .title" "$task_file")
    local task_instructions=$(jq -r ".queue[] | select(.id == $task_id) | .description // .instructions // empty" "$task_file")
    local output_file=$(jq -r ".queue[] | select(.id == $task_id) | .output_file // empty" "$task_file")
    local input_file=$(jq -r ".queue[] | select(.id == $task_id) | .input_file // .task_file // empty" "$task_file")
    
    if [ -z "$task_description" ] || [ "$task_description" = "null" ]; then
        echo -e "${RED}❌ Task #$task_id not found in TASK_QUEUE.json${NC}"
        bash "$SCRIPT_DIR/task_lock.sh" release "$task_id"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Task claimed successfully${NC}"
    echo ""
    echo "📄 Task: $task_description"
    echo ""
    
    # Build context-aware prompt
    local prompt="You are Claude, the Content & UX Specialist on The Quantum Self AI team.

Your role: Review and refine content, ensure UX best practices, provide creative feedback.

Current Task #$task_id: $task_description"
    
    if [ -n "$task_instructions" ] && [ "$task_instructions" != "null" ]; then
        prompt="$prompt

Instructions:
$task_instructions"
    fi
    
    if [ -n "$input_file" ] && [ "$input_file" != "null" ] && [ -f "$input_file" ]; then
        prompt="$prompt

Input file available at: $input_file"
    fi
    
    prompt="$prompt

Please complete this task. Provide your response in a clear, structured format."
    
    # Execute task with Claude
    echo "🤖 Calling Claude API..."
    echo ""
    
    local result
    result=$(call_claude "$prompt")
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}❌ Claude API call failed${NC}"
        bash "$SCRIPT_DIR/task_lock.sh" release "$task_id"
        bash "$SCRIPT_DIR/task_recovery.sh" fail "$task_id" "Claude API error"
        exit 1
    fi
    
    echo "$result"
    echo ""
    
    # Write output if file specified
    if [ -n "$output_file" ] && [ "$output_file" != "null" ]; then
        local full_output_path="$SCRIPT_DIR/../$output_file"
        mkdir -p "$(dirname "$full_output_path")"
        echo "$result" > "$full_output_path"
        echo -e "${GREEN}✅ Output written to: $output_file${NC}"
    fi
    
    # Complete the task (releases lock automatically)
    bash "$SCRIPT_DIR/complete_task_v2.sh" "$task_id" claude
    
    echo ""
    echo -e "${GREEN}✅ Task #$task_id completed successfully${NC}"
}

# Get next available Claude task
get_next_task() {
    local task_file="$SCRIPT_DIR/TASK_QUEUE.json"
    
    if [ ! -f "$task_file" ]; then
        echo "❌ TASK_QUEUE.json not found"
        return 1
    fi
    
    # Find next task assigned to claude with status not_started or pending
    local next_task=$(jq -r '.tasks[] | select((.assigned_to == "claude" or .assigned_to == "Claude") and (.status == "not_started" or .status == "pending")) | .id' "$task_file" | head -1)
    
    if [ -z "$next_task" ]; then
        echo "📭 No tasks available for Claude"
        return 1
    fi
    
    echo "📋 Next task: #$next_task"
    execute_task "$next_task"
}

# Review content (specialized command)
review_content() {
    local content_path="$1"
    
    if [ -z "$content_path" ]; then
        echo -e "${RED}❌ Please provide a file path to review${NC}"
        exit 1
    fi
    
    if [ ! -f "$content_path" ]; then
        echo -e "${RED}❌ File not found: $content_path${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Claude AI Agent - Content Review         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local content=$(cat "$content_path")
    
    local prompt="You are Claude, the Content & UX Specialist on The Quantum Self AI team.

Please review the following content for:
1. Clarity and readability
2. Grammar and style
3. UX best practices (if applicable)
4. Suggestions for improvement

Content to review:
---
$content
---

Provide a structured review with specific suggestions."
    
    echo "🤖 Calling Claude for content review..."
    echo ""
    
    call_claude "$prompt"
}

# UX analysis (specialized command)
analyze_ux() {
    local context="$1"
    
    if [ -z "$context" ]; then
        echo -e "${RED}❌ Please provide context for UX analysis${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Claude AI Agent - UX Analysis            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local prompt="You are Claude, the Content & UX Specialist on The Quantum Self AI team.

Please analyze the following from a UX perspective:

$context

Provide:
1. UX assessment
2. User pain points (if any)
3. Best practice recommendations
4. Specific improvements"
    
    echo "🤖 Calling Claude for UX analysis..."
    echo ""
    
    call_claude "$prompt"
}

# Ask Claude a question
ask_claude() {
    local question="$1"
    
    if [ -z "$question" ]; then
        echo -e "${RED}❌ Please provide a question${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Claude AI Agent - The Quantum Self       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local prompt="You are Claude, the Content & UX Specialist on The Quantum Self AI team.

Question: $question

Please provide a helpful, concise answer."
    
    echo "🤖 Calling Claude..."
    echo ""
    
    call_claude "$prompt"
}

# Show status
show_status() {
    echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      Claude AI Agent - The Quantum Self       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
        echo -e "${GREEN}✅ API key configured${NC}"
    else
        echo -e "${RED}❌ API key not set${NC}"
    fi
    
    echo ""
    echo "Available commands:"
    echo "  1. execute <task_id>      - Execute a specific task"
    echo "  2. next                   - Execute next available task"
    echo "  3. review <file>          - Review content in a file"
    echo "  4. ux '<context>'         - Analyze UX for given context"
    echo "  5. ask '<question>'       - Ask Claude a question"
    echo "  6. status                 - Show Claude status"
    echo ""
    
    # Show status from CLAUDE_STATUS.md if it exists
    local status_file="$SCRIPT_DIR/CLAUDE_STATUS.md"
    if [ -f "$status_file" ]; then
        cat "$status_file"
    fi
}

# Main command dispatcher
check_api_key

case "${1:-status}" in
    execute)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please provide a task ID${NC}"
            echo "Usage: $0 execute <task_id>"
            exit 1
        fi
        execute_task "$2"
        ;;
    next)
        get_next_task
        ;;
    review)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please provide a file path${NC}"
            echo "Usage: $0 review <file_path>"
            exit 1
        fi
        review_content "$2"
        ;;
    ux)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please provide context for UX analysis${NC}"
            echo "Usage: $0 ux '<context>'"
            exit 1
        fi
        analyze_ux "$2"
        ;;
    ask)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please provide a question${NC}"
            echo "Usage: $0 ask '<question>'"
            exit 1
        fi
        ask_claude "$2"
        ;;
    status)
        show_status
        ;;
    *)
        echo "Usage: $0 {execute|next|review|ux|ask|status}"
        exit 1
        ;;
esac
