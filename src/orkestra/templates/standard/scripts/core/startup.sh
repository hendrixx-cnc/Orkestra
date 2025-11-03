#!/bin/bash
# Orkestra System Startup Script

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "🎼 Starting Orkestra System..."
echo ""

# Start orchestrator in background
"$SCRIPT_DIR/orchestrator.sh" &
ORCHESTRATOR_PID=$!

echo "✓ Orchestrator started (PID: $ORCHESTRATOR_PID)"
echo ""
echo "System Status:"
echo "  - Orchestrator: Running"
echo "  - Project: $PROJECT_ROOT"
echo ""
echo "Commands:"
echo "  - Stop: pkill -f orchestrator.sh"
echo "  - Logs: tail -f logs/orchestrator.log"
echo "  - Status: orkestra status"
