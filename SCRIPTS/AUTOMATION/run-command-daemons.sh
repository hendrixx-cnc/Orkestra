#!/bin/bash
# Launch command queue daemons for all registered AIs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ais=("$@")
if [ ${#ais[@]} -eq 0 ]; then
    ais=("Copilot" "Claude" "ChatGPT")
fi

echo "🚀 Starting command daemons: ${ais[*]}"

for ai in "${ais[@]}"; do
    "$SCRIPT_DIR/command_daemon.sh" "$ai" &
    echo "   → $ai daemon running (PID $!)"
done

echo ""
echo "Daemons running in background. Use 'jobs' or 'ps' to monitor."
echo "Stop with: kill <PID>"
