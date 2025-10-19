#!/bin/bash
# ORKESTRA AUTO-PILOT MODE
# Launch all AIs in self-recovering continuous execution mode

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AUTO_EXECUTOR="$SCRIPT_DIR/auto_executor_with_recovery.sh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  OrKeStra Auto-Pilot Mode${NC}"
echo -e "${BLUE}  Self-Recovering Multi-AI Execution${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Get mode and task limit
MODE="${1:-continuous}"
TASK_LIMIT="${2:-20}"

if [ "$MODE" = "help" ] || [ "$MODE" = "-h" ] || [ "$MODE" = "--help" ]; then
    echo "Usage: $0 [mode] [task_limit]"
    echo ""
    echo "Modes:"
    echo "  continuous [N]  - Each AI processes up to N tasks (default: 20)"
    echo "  batch           - Each AI processes ALL their pending tasks"
    echo "  parallel N      - All AIs run simultaneously, N tasks each"
    echo ""
    echo "Features:"
    echo "  • Automatic error recovery (3 retries per task)"
    echo "  • Self-healing for file/directory errors"
    echo "  • API rate limit handling"
    echo "  • Dependency checking"
    echo "  • Task reassignment on repeated failures"
    echo "  • Comprehensive logging"
    echo ""
    echo "Examples:"
    echo "  $0 continuous 10    # Each AI does 10 tasks sequentially"
    echo "  $0 batch            # Process all pending tasks"
    echo "  $0 parallel 15      # All AIs run together, 15 tasks each"
    exit 0
fi

# Create log directory
mkdir -p "$SCRIPT_DIR/recovery"

echo "📋 Configuration:"
echo "  Mode: $MODE"
echo "  Task Limit: $TASK_LIMIT per AI"
echo "  Auto-Recovery: Enabled (3 retries)"
echo "  Self-Healing: Enabled"
echo ""

# Check system health
echo "🔍 System Health Check..."
bash "$SCRIPT_DIR/orkestra_start.sh" | grep -E "✓|→|✗" | head -10
echo ""

case "$MODE" in
    continuous)
        echo -e "${GREEN}🚀 Launching Sequential Auto-Pilot Mode${NC}"
        echo "   AIs will execute one after another"
        echo ""
        
        echo -e "${BLUE}Starting Gemini...${NC}"
        bash "$AUTO_EXECUTOR" continuous gemini "$TASK_LIMIT"
        
        echo ""
        echo -e "${BLUE}Starting Claude...${NC}"
        bash "$AUTO_EXECUTOR" continuous claude "$TASK_LIMIT"
        
        echo ""
        echo -e "${BLUE}Starting ChatGPT...${NC}"
        bash "$AUTO_EXECUTOR" continuous chatgpt "$TASK_LIMIT"
        
        echo ""
        echo -e "${BLUE}Starting Grok...${NC}"
        bash "$AUTO_EXECUTOR" continuous grok "$TASK_LIMIT"
        ;;
        
    batch)
        echo -e "${GREEN}🚀 Launching Batch Auto-Pilot Mode${NC}"
        echo "   AIs will process ALL pending tasks"
        echo ""
        
        bash "$AUTO_EXECUTOR" batch gemini &
        bash "$AUTO_EXECUTOR" batch claude &
        bash "$AUTO_EXECUTOR" batch chatgpt &
        bash "$AUTO_EXECUTOR" batch grok &
        
        echo "⏳ Waiting for all AIs to complete..."
        wait
        ;;
        
    parallel)
        echo -e "${GREEN}🚀 Launching Parallel Auto-Pilot Mode${NC}"
        echo "   All AIs executing simultaneously"
        echo ""
        
        bash "$AUTO_EXECUTOR" continuous gemini "$TASK_LIMIT" &
        bash "$AUTO_EXECUTOR" continuous claude "$TASK_LIMIT" &
        bash "$AUTO_EXECUTOR" continuous chatgpt "$TASK_LIMIT" &
        bash "$AUTO_EXECUTOR" continuous grok "$TASK_LIMIT" &
        
        echo "⏳ Waiting for all AIs to complete..."
        wait
        ;;
        
    *)
        echo "Unknown mode: $MODE"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Auto-Pilot Execution Complete${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
echo ""

# Show final stats
echo "📊 Final Status:"
cd "$SCRIPT_DIR"
COMPLETED=$(jq '[.queue[] | select(.status == "completed")] | length' TASK_QUEUE.json)
IN_PROGRESS=$(jq '[.queue[] | select(.status == "in_progress")] | length' TASK_QUEUE.json)
PENDING=$(jq '[.queue[] | select(.status == "pending" or .status == "waiting")] | length' TASK_QUEUE.json)

echo "  Completed: $COMPLETED/40"
echo "  In Progress: $IN_PROGRESS"
echo "  Pending: $PENDING"
echo ""

# Show recent log entries
if [ -f "$SCRIPT_DIR/recovery/auto_execution_$(date +%Y%m%d).log" ]; then
    echo "📝 Recent Activity (last 10 lines):"
    tail -10 "$SCRIPT_DIR/recovery/auto_execution_$(date +%Y%m%d).log" | sed 's/^/  /'
    echo ""
    echo "Full log: $SCRIPT_DIR/recovery/auto_execution_$(date +%Y%m%d).log"
fi

echo ""
echo -e "${BLUE}💡 To view detailed logs:${NC}"
echo "   tail -f $SCRIPT_DIR/recovery/auto_execution_$(date +%Y%m%d).log"
