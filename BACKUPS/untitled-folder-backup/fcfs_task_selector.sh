#!/bin/bash
# SIMPLE FIRST-COME-FIRST-SERVE (FCFS) TASK SELECTOR
# No priority conflicts - just grab the next task in line

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

# Get next available task for ANY AI (first-come-first-serve)
get_next_fcfs_task() {
    local ai_name="$1"
    
    # Get the FIRST pending task by ID (no priority sorting)
    # This prevents conflicts where multiple AIs fight over "high priority" tasks
    local task_id=$(jq -r --arg ai "$ai_name" \
        '.queue[] | 
         select(.assigned_to == $ai and (.status == "pending" or .status == "waiting")) | 
         select(.dependencies == null or .dependencies == [] or 
                (.dependencies | all(. as $dep | 
                    (.queue[] | select(.id == ($dep | tonumber)) | .status) == "completed"))) |
         .id' \
        "$TASK_QUEUE" | sort -n | head -1)
    
    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        echo ""
        return 1
    fi
    
    echo "$task_id"
    return 0
}

# Get next available task for ANY AI (not assignment-restricted)
get_next_any_ai_fcfs() {
    # Get the FIRST pending task that ANY AI can do
    # Ignores assignment completely - true FCFS
    local task_id=$(jq -r \
        '.queue[] | 
         select(.status == "pending" or .status == "waiting") | 
         select(.dependencies == null or .dependencies == [] or 
                (.dependencies | all(. as $dep | 
                    (.queue[] | select(.id == ($dep | tonumber)) | .status) == "completed"))) |
         .id' \
        "$TASK_QUEUE" | sort -n | head -1)
    
    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        echo ""
        return 1
    fi
    
    echo "$task_id"
    return 0
}

# Show next N tasks in FCFS order
show_fcfs_queue() {
    local ai_name="${1:-}"
    local count="${2:-10}"
    
    echo "📋 FCFS Task Queue (Next $count tasks)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [ -n "$ai_name" ]; then
        echo "For AI: $ai_name"
        jq -r --arg ai "$ai_name" --arg limit "$count" \
            '.queue[] | 
             select(.assigned_to == $ai and (.status == "pending" or .status == "waiting")) | 
             select(.dependencies == null or .dependencies == [] or 
                    (.dependencies | all(. as $dep | 
                        (.queue[] | select(.id == ($dep | tonumber)) | .status) == "completed"))) |
             "\(.id)|\(.title)|\(.assigned_to)"' \
            "$TASK_QUEUE" | sort -n | head -"$count" | \
            awk -F'|' '{printf "  %2d. Task #%s: %s\n", NR, $1, $2}'
    else
        echo "For all AIs (next available)"
        jq -r --arg limit "$count" \
            '.queue[] | 
             select(.status == "pending" or .status == "waiting") | 
             select(.dependencies == null or .dependencies == [] or 
                    (.dependencies | all(. as $dep | 
                        (.queue[] | select(.id == ($dep | tonumber)) | .status) == "completed"))) |
             "\(.id)|\(.title)|\(.assigned_to)"' \
            "$TASK_QUEUE" | sort -n | head -"$count" | \
            awk -F'|' '{printf "  %2d. Task #%s: %s (assigned: %s)\n", NR, $1, $2, $3}'
    fi
    echo ""
}

# Main command handler
case "${1:-}" in
    next)
        # Get next task for specific AI
        ai_name="$2"
        if [ -z "$ai_name" ]; then
            echo "Usage: $0 next <ai_name>"
            exit 1
        fi
        get_next_fcfs_task "$ai_name"
        ;;
    
    any)
        # Get next task for any AI
        get_next_any_ai_fcfs
        ;;
    
    show)
        # Show queue
        show_fcfs_queue "$2" "$3"
        ;;
    
    *)
        echo "Usage: $0 {next|any|show} [ai_name] [count]"
        echo ""
        echo "Commands:"
        echo "  next <ai>       - Get next task for specific AI (FCFS)"
        echo "  any             - Get next task for any AI (FCFS)"
        echo "  show [ai] [N]   - Show next N tasks in queue"
        echo ""
        echo "Examples:"
        echo "  $0 next gemini"
        echo "  $0 any"
        echo "  $0 show claude 5"
        echo "  $0 show \"\" 10"
        exit 1
        ;;
esac
