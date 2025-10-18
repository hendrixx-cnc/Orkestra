#!/bin/bash
# COPILOT TOOL
# Status checker, git commit handler, and initial project planner
# NOT autonomous - runs on-demand or triggered by user/other AIs

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function: Status check
status_check() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           COPILOT STATUS CHECK                           ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Task queue status
    echo -e "${CYAN}📋 TASK QUEUE STATUS:${NC}"
    local total=$(jq '.queue | length' "$TASK_QUEUE")
    local completed=$(jq '[.queue[] | select(.status == "completed")] | length' "$TASK_QUEUE")
    local in_progress=$(jq '[.queue[] | select(.status == "in_progress")] | length' "$TASK_QUEUE")
    local pending=$(jq '[.queue[] | select(.status == "pending")] | length' "$TASK_QUEUE")

    echo "   Total: $total tasks"
    echo "   ✅ Completed: $completed"
    echo "   ⚙️  In Progress: $in_progress"
    echo "   ⏸️  Pending: $pending"
    echo ""

    # AI status
    echo -e "${CYAN}🤖 AI STATUS:${NC}"
    for ai in Claude Gemini ChatGPT; do
        local status_file="$SCRIPT_DIR/status/${ai}.json"
        if [ -f "$status_file" ]; then
            local state=$(jq -r '.state' "$status_file")
            local detail=$(jq -r '.detail' "$status_file")
            echo "   $ai: $state - $detail"
        else
            echo "   $ai: offline"
        fi
    done
    echo ""

    # User prompts
    echo -e "${CYAN}❓ USER PROMPTS:${NC}"
    local waiting_prompts=$(find "$SCRIPT_DIR/user_prompts" -name "*_prompt_*.json" -type f 2>/dev/null | \
        xargs -I {} jq -r 'select(.status == "waiting") | .id' {} 2>/dev/null | wc -l)

    if [ "$waiting_prompts" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  $waiting_prompts prompts waiting for user${NC}"
        find "$SCRIPT_DIR/user_prompts" -name "*_prompt_*.json" -type f 2>/dev/null | \
            xargs -I {} jq -r 'select(.status == "waiting") | "      → \(.ai): \(.question)"' {} 2>/dev/null
    else
        echo "   ✅ No pending prompts"
    fi
    echo ""

    # Git status
    echo -e "${CYAN}📦 GIT STATUS:${NC}"
    cd "$PROJECT_ROOT"
    local modified=$(git status --porcelain | grep -c "^ M" || echo "0")
    local untracked=$(git status --porcelain | grep -c "^??" || echo "0")
    local branch=$(git branch --show-current)

    echo "   Branch: $branch"
    echo "   Modified files: $modified"
    echo "   Untracked files: $untracked"

    if [ $modified -gt 0 ] || [ $untracked -gt 0 ]; then
        echo -e "   ${YELLOW}💡 Tip: Run './copilot_tool.sh commit \"message\"' to commit${NC}"
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function: Git commit
git_commit() {
    local message="$1"

    if [ -z "$message" ]; then
        echo "❌ Error: Commit message required"
        echo "Usage: $0 commit \"your commit message\""
        exit 1
    fi

    cd "$PROJECT_ROOT"

    echo -e "${PURPLE}📦 Creating git commit...${NC}"
    echo ""

    # Show what will be committed
    git status --short

    echo ""
    read -p "Commit these changes? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add .
        git commit -m "$message

🤖 Generated with Claude Code
Co-Authored-By: Copilot <noreply@github.com>"

        echo ""
        echo -e "${GREEN}✅ Commit created successfully${NC}"
        echo ""
        echo -e "${CYAN}Latest commit:${NC}"
        git log -1 --oneline
    else
        echo "❌ Commit cancelled"
    fi
}

# Function: Create project plan
create_project_plan() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           COPILOT PROJECT PLANNER                        ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo "This tool helps break down a project into tasks for the AI team."
    echo ""

    read -p "Project name: " project_name
    read -p "Project description: " project_desc
    echo ""

    echo "Enter tasks (one per line, empty line to finish):"
    local task_counter=1
    local tasks=()

    while true; do
        read -p "Task $task_counter: " task
        if [ -z "$task" ]; then
            break
        fi
        tasks+=("$task")
        ((task_counter++))
    done

    echo ""
    echo "Assigning tasks to AIs..."
    echo ""

    # Simple AI assignment logic
    for i in "${!tasks[@]}"; do
        local task="${tasks[$i]}"
        local task_id=$((17 + i + 1))  # Start after test tasks
        local assigned_ai="Claude"  # Default

        # Simple keyword matching
        if echo "$task" | grep -qi "firebase\|cloud\|cost"; then
            assigned_ai="Gemini"
        elif echo "$task" | grep -qi "copy\|content\|marketing\|doc"; then
            assigned_ai="ChatGPT"
        fi

        echo "Task $task_id: $task → $assigned_ai"

        # Add to task queue (would need proper JSON manipulation)
        # For now, just print
    done

    echo ""
    echo -e "${GREEN}✅ Project plan created${NC}"
    echo -e "${YELLOW}💡 Review plan and add to TASK_QUEUE.json manually${NC}"
    echo -e "${YELLOW}💡 Then start the AI daemons to begin execution${NC}"
}

# Function: Show daemon status
daemon_status() {
    echo -e "${BLUE}🤖 AI DAEMON STATUS:${NC}"
    echo ""

    for ai in claude gemini chatgpt; do
        if ps aux | grep "[${ai:0:1}]${ai:1}_daemon.sh" > /dev/null; then
            echo -e "   ${GREEN}✅ ${ai^} daemon: RUNNING${NC}"
        else
            echo -e "   ${RED}❌ ${ai^} daemon: STOPPED${NC}"
        fi
    done

    echo ""
    echo -e "${YELLOW}To start daemons:${NC}"
    echo "   ./claude_daemon.sh &"
    echo "   ./gemini_auto_executor.sh watch &"
    echo "   ./chatgpt_auto_executor.sh watch &"
}

# Main menu
case "${1:-status}" in
    status)
        status_check
        ;;

    commit)
        git_commit "${2:-}"
        ;;

    plan)
        create_project_plan
        ;;

    daemons)
        daemon_status
        ;;

    help)
        cat << 'HELP'
╔════════════════════════════════════════════════════════════╗
║                    COPILOT TOOL                            ║
║   Status checks, git commits, and project planning        ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  ./copilot_tool.sh <command> [options]

COMMANDS:
  status              - Show comprehensive status check
  commit "<message>"  - Create git commit with changes
  plan                - Interactive project planner
  daemons             - Show AI daemon status
  help                - Show this help

EXAMPLES:
  # Check status
  ./copilot_tool.sh status

  # Create commit
  ./copilot_tool.sh commit "Add user authentication"

  # Create project plan
  ./copilot_tool.sh plan

  # Check if daemons are running
  ./copilot_tool.sh daemons

WORKFLOW:
  1. User creates project plan (Copilot plan)
  2. Copilot breaks into tasks, assigns to AIs
  3. Start AI daemons (Claude, Gemini, ChatGPT)
  4. AIs work autonomously, prompt user when needed
  5. User answers prompts with ./answer_prompt.sh
  6. Copilot commits completed work

HELP
        ;;

    *)
        echo "Unknown command: $1"
        echo "Run './copilot_tool.sh help' for usage"
        exit 1
        ;;
esac
