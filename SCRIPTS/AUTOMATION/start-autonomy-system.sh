#!/bin/bash
# QUICK START SCRIPT FOR AUTONOMY-BASED AI SYSTEM

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🎮 Starting Autonomy-Based AI Orchestration System"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if autonomy config exists
if [ ! -f "$SCRIPT_DIR/autonomy_config.json" ]; then
    echo "❌ Error: autonomy_config.json not found"
    echo "   Please create it first or copy from template"
    exit 1
fi

echo "📋 Current Autonomy Configuration:"
jq -r '.autonomy_levels | to_entries[] | "  \(.key): \(.value)%"' "$SCRIPT_DIR/autonomy_config.json"
echo ""

# Ask how many AIs to start
echo "How many AIs would you like to start? (1-5)"
read -p "Enter number [default: 4]: " num_ais
num_ais=${num_ais:-4}

# Ask how many tasks each AI should process
echo ""
echo "How many tasks should each AI process before checking back?"
read -p "Enter number [default: 10, 0 for continuous]: " tasks_per_ai
tasks_per_ai=${tasks_per_ai:-10}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting $num_ais AI(s)..."
echo ""

# Array of AI names
ai_names=("gemini" "claude" "chatgpt" "grok" "copilot")

# Start the requested number of AIs
for ((i=0; i<num_ais; i++)); do
    ai="${ai_names[$i]}"
    echo "  Starting $ai..."
    bash "$SCRIPT_DIR/autonomy_executor.sh" "$ai" continuous "$tasks_per_ai" > "$SCRIPT_DIR/logs/${ai}_autonomy.log" 2>&1 &
    sleep 1
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ $num_ais AI(s) started!"
echo ""
echo "📊 What's Happening:"
echo "  • AIs are working on tasks based on autonomy levels"
echo "  • High autonomy tasks (≥50%) complete automatically"
echo "  • Low autonomy tasks (<50%) will request your approval"
echo "  • When no tasks available, AIs do error/consistency checks"
echo ""
echo "💬 When an AI needs approval:"
echo "  1. Check: ls AI/user_approvals/"
echo "  2. Review: cat AI/user_approvals/task_<id>_iter_<n>.json"
echo "  3. Respond: bash AI/respond_to_approval.sh <id> [approve|iterate|skip]"
echo ""
echo "📝 Monitor Progress:"
echo "  • View logs: tail -f AI/logs/*_autonomy.log"
echo "  • Check queue: jq '.queue[] | select(.status==\"in_progress\")' AI/TASK_QUEUE.json"
echo "  • View approvals: ls -lh AI/user_approvals/"
echo ""
echo "🛑 Stop System:"
echo "  • Press Ctrl+C or run: pkill -f autonomy_executor.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "System running! Watch for approval requests in AI/user_approvals/"
echo ""

# Optional: tail the first AI's log
# tail -f "$SCRIPT_DIR/logs/${ai_names[0]}_autonomy.log"
