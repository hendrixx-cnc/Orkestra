#!/bin/bash
# AI NOTES SYSTEM
# Allows AIs to leave notes for each other about tasks, considerations, and special situations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTES_FILE="$SCRIPT_DIR/AI_NOTES.json"

# Initialize notes file if it doesn't exist
if [ ! -f "$NOTES_FILE" ]; then
    cat > "$NOTES_FILE" <<'EOF'
{
  "notes": [],
  "task_notes": {},
  "general_notes": [],
  "handoff_notes": []
}
EOF
fi

# Function: Add a note
add_note() {
    local from_ai="$1"
    local note_type="$2"
    local message="$3"
    local task_id="${4:-}"
    local to_ai="${5:-all}"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    local note_id=$(date +%s)
    
    case "$note_type" in
        task)
            if [ -z "$task_id" ]; then
                echo "Error: task_id required for task notes"
                return 1
            fi
            
            # Add to task-specific notes
            jq --arg id "$note_id" \
               --arg from "$from_ai" \
               --arg to "$to_ai" \
               --arg msg "$message" \
               --arg task "$task_id" \
               --arg ts "$timestamp" \
               '.task_notes[$task] += [{
                 "id": $id,
                 "from": $from,
                 "to": $to,
                 "message": $msg,
                 "timestamp": $ts,
                 "read": false
               }]' "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            
            echo "Task note added: Task #$task_id from $from_ai to $to_ai"
            ;;
            
        handoff)
            # Handoff notes for when completing a task
            jq --arg id "$note_id" \
               --arg from "$from_ai" \
               --arg to "$to_ai" \
               --arg msg "$message" \
               --arg task "$task_id" \
               --arg ts "$timestamp" \
               '.handoff_notes += [{
                 "id": $id,
                 "from": $from,
                 "to": $to,
                 "message": $msg,
                 "task_id": $task,
                 "timestamp": $ts,
                 "read": false
               }]' "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            
            echo "Handoff note added from $from_ai to $to_ai"
            ;;
            
        general)
            # General notes for all AIs
            jq --arg id "$note_id" \
               --arg from "$from_ai" \
               --arg to "$to_ai" \
               --arg msg "$message" \
               --arg ts "$timestamp" \
               '.general_notes += [{
                 "id": $id,
                 "from": $from,
                 "to": $to,
                 "message": $msg,
                 "timestamp": $ts,
                 "read": false
               }]' "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            
            echo "General note added from $from_ai"
            ;;
            
        *)
            echo "Error: Invalid note type. Use: task, handoff, or general"
            return 1
            ;;
    esac
}

# Function: Read notes for an AI
read_notes() {
    local ai_name="$1"
    local filter="${2:-all}"
    
    echo "Notes for $ai_name:"
    echo "===================="
    echo ""
    
    case "$filter" in
        task)
            echo "TASK-SPECIFIC NOTES:"
            jq -r --arg ai "$ai_name" \
                '.task_notes | to_entries[] | 
                 .key as $task | .value[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "Task #\($task) from \(.from): \(.message) [\(.timestamp)]"' \
                "$NOTES_FILE"
            ;;
            
        handoff)
            echo "HANDOFF NOTES:"
            jq -r --arg ai "$ai_name" \
                '.handoff_notes[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "From \(.from) (Task #\(.task_id)): \(.message) [\(.timestamp)]"' \
                "$NOTES_FILE"
            ;;
            
        general)
            echo "GENERAL NOTES:"
            jq -r --arg ai "$ai_name" \
                '.general_notes[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "From \(.from): \(.message) [\(.timestamp)]"' \
                "$NOTES_FILE"
            ;;
            
        all|*)
            echo "TASK-SPECIFIC NOTES:"
            jq -r --arg ai "$ai_name" \
                '.task_notes | to_entries[] | 
                 .key as $task | .value[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "  Task #\($task) from \(.from): \(.message)"' \
                "$NOTES_FILE" || echo "  None"
            
            echo ""
            echo "HANDOFF NOTES:"
            jq -r --arg ai "$ai_name" \
                '.handoff_notes[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "  From \(.from) (Task #\(.task_id)): \(.message)"' \
                "$NOTES_FILE" || echo "  None"
            
            echo ""
            echo "GENERAL NOTES:"
            jq -r --arg ai "$ai_name" \
                '.general_notes[] | 
                 select(.to == $ai or .to == "all") | 
                 select(.read == false) |
                 "  From \(.from): \(.message)"' \
                "$NOTES_FILE" || echo "  None"
            ;;
    esac
}

# Function: Mark notes as read
mark_read() {
    local ai_name="$1"
    local note_type="${2:-all}"
    
    case "$note_type" in
        task)
            jq --arg ai "$ai_name" \
               '.task_notes = (.task_notes | to_entries | map({
                 key: .key,
                 value: (.value | map(if (.to == $ai or .to == "all") then .read = true else . end))
               }) | from_entries)' \
               "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            ;;
            
        handoff)
            jq --arg ai "$ai_name" \
               '(.handoff_notes[] | select(.to == $ai or .to == "all")).read = true' \
               "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            ;;
            
        general)
            jq --arg ai "$ai_name" \
               '(.general_notes[] | select(.to == $ai or .to == "all")).read = true' \
               "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            ;;
            
        all|*)
            # Mark all notes for this AI as read
            jq --arg ai "$ai_name" \
               '.task_notes = (.task_notes | to_entries | map({
                 key: .key,
                 value: (.value | map(if (.to == $ai or .to == "all") then .read = true else . end))
               }) | from_entries) |
               .handoff_notes = (.handoff_notes | map(if (.to == $ai or .to == "all") then .read = true else . end)) |
               .general_notes = (.general_notes | map(if (.to == $ai or .to == "all") then .read = true else . end))' \
               "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
            ;;
    esac
    
    echo "Notes marked as read for $ai_name"
}

# Function: Count unread notes
count_unread() {
    local ai_name="$1"
    
    local task_count=$(jq -r --arg ai "$ai_name" \
        '[.task_notes | to_entries[] | .value[] | select(.to == $ai or .to == "all") | select(.read == false)] | length' \
        "$NOTES_FILE")
    
    local handoff_count=$(jq -r --arg ai "$ai_name" \
        '[.handoff_notes[] | select(.to == $ai or .to == "all") | select(.read == false)] | length' \
        "$NOTES_FILE")
    
    local general_count=$(jq -r --arg ai "$ai_name" \
        '[.general_notes[] | select(.to == $ai or .to == "all") | select(.read == false)] | length' \
        "$NOTES_FILE")
    
    local total=$((task_count + handoff_count + general_count))
    
    echo "Unread notes for $ai_name: $total"
    echo "  Task notes: $task_count"
    echo "  Handoff notes: $handoff_count"
    echo "  General notes: $general_count"
}

# Function: Get notes for a specific task
get_task_notes() {
    local task_id="$1"
    
    echo "Notes for Task #$task_id:"
    echo "========================="
    
    jq -r --arg task "$task_id" \
        '.task_notes[$task][]? | 
         "From \(.from) to \(.to): \(.message) [\(.timestamp)]"' \
        "$NOTES_FILE" || echo "No notes for this task"
}

# Function: List all notes (admin view)
list_all() {
    echo "ALL AI NOTES"
    echo "============"
    echo ""
    
    echo "TASK NOTES:"
    jq -r '.task_notes | to_entries[] | 
           .key as $task | .value[] |
           "  Task #\($task): \(.from) -> \(.to): \(.message) [read: \(.read)]"' \
        "$NOTES_FILE" || echo "  None"
    
    echo ""
    echo "HANDOFF NOTES:"
    jq -r '.handoff_notes[] |
           "  Task #\(.task_id): \(.from) -> \(.to): \(.message) [read: \(.read)]"' \
        "$NOTES_FILE" || echo "  None"
    
    echo ""
    echo "GENERAL NOTES:"
    jq -r '.general_notes[] |
           "  \(.from) -> \(.to): \(.message) [read: \(.read)]"' \
        "$NOTES_FILE" || echo "  None"
}

# Function: Clean old read notes (optional cleanup)
clean_old() {
    local days="${1:-7}"
    local cutoff_date=$(date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%S+00:00" 2>/dev/null || date -u -v-${days}d +"%Y-%m-%dT%H:%M:%S+00:00")
    
    jq --arg cutoff "$cutoff_date" \
       '.task_notes = (.task_notes | to_entries | map({
         key: .key,
         value: (.value | map(select(.read == false or .timestamp > $cutoff)))
       }) | from_entries) |
       .handoff_notes = (.handoff_notes | map(select(.read == false or .timestamp > $cutoff))) |
       .general_notes = (.general_notes | map(select(.read == false or .timestamp > $cutoff)))' \
       "$NOTES_FILE" > "${NOTES_FILE}.tmp" && mv "${NOTES_FILE}.tmp" "$NOTES_FILE"
    
    echo "Cleaned notes older than $days days (kept unread)"
}

# Main command dispatcher
case "${1:-}" in
    add)
        if [ $# -lt 4 ]; then
            echo "Usage: $0 add <from_ai> <type> <message> [task_id] [to_ai]"
            echo ""
            echo "Types: task, handoff, general"
            echo "Examples:"
            echo "  $0 add claude task \"Watch out for edge case in validation\" 16 gemini"
            echo "  $0 add gemini handoff \"Database migration completed, updated schema\" 16 claude"
            echo "  $0 add chatgpt general \"New brand guidelines in BRANDING.md\" all"
            exit 1
        fi
        add_note "$2" "$3" "$4" "${5:-}" "${6:-all}"
        ;;
        
    read)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 read <ai_name> [type]"
            echo "Types: task, handoff, general, all (default)"
            exit 1
        fi
        read_notes "$2" "${3:-all}"
        ;;
        
    mark-read)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 mark-read <ai_name> [type]"
            exit 1
        fi
        mark_read "$2" "${3:-all}"
        ;;
        
    count)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 count <ai_name>"
            exit 1
        fi
        count_unread "$2"
        ;;
        
    task)
        if [ $# -lt 2 ]; then
            echo "Usage: $0 task <task_id>"
            exit 1
        fi
        get_task_notes "$2"
        ;;
        
    list)
        list_all
        ;;
        
    clean)
        clean_old "${2:-7}"
        ;;
        
    *)
        echo "AI Notes System - Inter-AI Communication"
        echo ""
        echo "Usage:"
        echo "  $0 add <from> <type> <message> [task_id] [to]  - Add a note"
        echo "  $0 read <ai_name> [type]                       - Read notes for AI"
        echo "  $0 mark-read <ai_name> [type]                  - Mark notes as read"
        echo "  $0 count <ai_name>                             - Count unread notes"
        echo "  $0 task <task_id>                              - Get all notes for task"
        echo "  $0 list                                        - List all notes (admin)"
        echo "  $0 clean [days]                                - Clean old read notes"
        echo ""
        echo "Note Types:"
        echo "  task     - Task-specific notes (requires task_id)"
        echo "  handoff  - Handoff notes when completing tasks"
        echo "  general  - General notes for all AIs"
        echo ""
        echo "Examples:"
        echo "  # Claude leaves note about Task 16 for Gemini"
        echo "  $0 add claude task \"Edge case: handle null users\" 16 gemini"
        echo ""
        echo "  # Gemini hands off completed work to Claude"
        echo "  $0 add gemini handoff \"Schema done, needs testing\" 16 claude"
        echo ""
        echo "  # ChatGPT broadcasts to all"
        echo "  $0 add chatgpt general \"Updated style guide\" all"
        echo ""
        echo "  # Gemini reads their notes"
        echo "  $0 read gemini"
        echo ""
        echo "  # Check what notes exist for Task 16"
        echo "  $0 task 16"
        exit 1
        ;;
esac
