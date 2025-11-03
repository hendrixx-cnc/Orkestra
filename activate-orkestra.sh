#!/bin/bash
# Quick activation script for Orkestra virtual environment

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "🎼 Activating Orkestra virtual environment..."
source "$SCRIPT_DIR/venv/bin/activate"

echo "✓ Virtual environment activated!"
echo ""
echo "Available commands:"
echo "  orkestra --version"
echo "  orkestra new <project-name>"
echo "  orkestra start"
echo "  orkestra --help"
echo ""
echo "To deactivate: type 'deactivate'"
