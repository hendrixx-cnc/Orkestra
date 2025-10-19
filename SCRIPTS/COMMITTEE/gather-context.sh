#!/bin/bash
# Context Gathering System
# Automatically gathers relevant files and information based on topic

TOPIC="$1"
WORKSPACE="/workspaces/Orkestra"

gather_context() {
    local topic="$1"
    
    echo "### Gathered Context"
    echo ""
    echo "**Topic Keywords**: ${topic}"
    echo ""
    
    # Search for relevant files
    echo "**Relevant Files**:"
    echo '```bash'
    
    # Search in DOCS
    if [ -d "$WORKSPACE/DOCS" ]; then
        grep -ril "$topic" "$WORKSPACE/DOCS" 2>/dev/null | head -5 | while read file; do
            echo "$file"
        done
    fi
    
    # Search in recent work
    if [ -d "$WORKSPACE/SCRIPTS" ]; then
        find "$WORKSPACE/SCRIPTS" -name "*.sh" -o -name "*.py" | xargs grep -l "$topic" 2>/dev/null | head -5 | while read file; do
            echo "$file"
        done
    fi
    
    echo '```'
    echo ""
    
    # Get recent git activity if applicable
    if [ -d "$WORKSPACE/.git" ]; then
        echo "**Recent Related Commits**:"
        echo '```'
        cd "$WORKSPACE"
        git log --all --oneline --grep="$topic" -n 3 2>/dev/null || echo "No recent commits"
        echo '```'
        echo ""
    fi
    
    # Current project context
    if [ -f "$WORKSPACE/CONFIG/current-project.json" ]; then
        echo "**Current Project**:"
        echo '```json'
        cat "$WORKSPACE/CONFIG/current-project.json"
        echo '```'
        echo ""
    fi
    
    # System status
    echo "**System Status**:"
    echo '```'
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "User: $USER"
    echo "Working Directory: $PWD"
    echo '```'
}

gather_context "$TOPIC"
