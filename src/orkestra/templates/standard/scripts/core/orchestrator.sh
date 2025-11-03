#!/bin/bash
# Orkestra Orchestrator - Simplified for Package Distribution
# This is a minimal orchestrator that can be extended

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ORKESTRA_FRAMEWORK="$(cd "$SCRIPT_DIR/../../../.." && cd Orkestra 2>/dev/null || echo "")"

echo "🎼 Orkestra Orchestrator Starting..."
echo "Project Root: $PROJECT_ROOT"

# Load global API keys (shared across all projects)
GLOBAL_API_KEYS=""
if [ -n "$ORKESTRA_FRAMEWORK" ] && [ -f "$ORKESTRA_FRAMEWORK/CONFIG/api-keys.env" ]; then
    GLOBAL_API_KEYS="$ORKESTRA_FRAMEWORK/CONFIG/api-keys.env"
elif [ -f "$HOME/.orkestra/api-keys.env" ]; then
    GLOBAL_API_KEYS="$HOME/.orkestra/api-keys.env"
fi

if [ -n "$GLOBAL_API_KEYS" ]; then
    source "$GLOBAL_API_KEYS"
    echo "✓ Global API keys loaded from: $GLOBAL_API_KEYS"
else
    echo "⚠ Warning: API keys not configured."
    echo "   Set up once: Copy api-keys.env.example to api-keys.env in Orkestra CONFIG folder"
    echo "   Or create: ~/.orkestra/api-keys.env"
fi

# Create necessary directories
mkdir -p "$PROJECT_ROOT/orkestra/logs"
mkdir -p "$PROJECT_ROOT/orkestra/config/runtime"
mkdir -p "$PROJECT_ROOT/orkestra/config/locks"

echo "✓ Directories initialized"

# Main orchestrator loop
echo ""
echo "Orchestrator running. Press Ctrl+C to stop."
echo "Logs: $PROJECT_ROOT/orkestra/logs/orchestrator.log"

while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Orchestrator heartbeat" >> "$PROJECT_ROOT/orkestra/logs/orchestrator.log"
    sleep 60
done
