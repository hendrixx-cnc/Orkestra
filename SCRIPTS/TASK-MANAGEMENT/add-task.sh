#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# INTERACTIVE TASK CREATOR
# ═══════════════════════════════════════════════════════════════════════════
# Creates new tasks with proper structure and validation
# Integrates with main automation and project planner
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
CONFIG_DIR="$ORKESTRA_ROOT/CONFIG"
TEMPLATE_FILE="$CONFIG_DIR/TEMPLATES/task-template.json"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
OUTPUT_DIR="$ORKESTRA_ROOT/OUTPUT"

mkdir -p "$CONFIG_DIR/TEMPLATES" "$LOGS_DIR" "$OUTPUT_DIR"

# Task data
TASK_DATA=""

# ═══════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_prompt() {
    echo -e "${YELLOW}❯${NC}  $1"
}

generate_task_id() {
    # Get next task ID from queue
    local last_id=$(jq -r '.tasks[-1].task_id // "task_0000"' "$TASK_QUEUE" 2>/dev/null)
    local num=$(echo "$last_id" | grep -o '[0-9]*$')
    local next_num=$((num + 1))
    printf "task_%04d" "$next_num"
}

validate_file_path() {
    local path="$1"
    if [[ ! "$path" =~ ^/ ]]; then
        echo "$ORKESTRA_ROOT/$path"
    else
        echo "$path"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# INTERACTIVE PROMPTS
# ═══════════════════════════════════════════════════════════════════════════

show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                    ORKESTRA TASK CREATOR                          ║
║              Create tasks for AI agent execution                  ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

prompt_basic_info() {
    echo -e "${BOLD}${BLUE}━━━ Basic Information ━━━${NC}"
    echo ""
    
    # Task title
    log_prompt "Task title (short, descriptive):"
    read -r title
    while [[ -z "$title" ]]; do
        log_error "Title cannot be empty"
        read -r title
    done
    
    # Task description
    echo ""
    log_prompt "Detailed description:"
    log_info "Include context, requirements, and acceptance criteria"
    log_info "Press Ctrl+D when done (or enter '.' on a line by itself)"
    echo ""
    
    description=""
    while IFS= read -r line; do
        [[ "$line" == "." ]] && break
        description+="$line\n"
    done
    
    # Remove trailing newline
    description="${description%\\n}"
    
    # Store
    TASK_DATA=$(jq -n \
        --arg title "$title" \
        --arg desc "$description" \
        '{title: $title, description: $desc}')
}

prompt_classification() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Task Classification ━━━${NC}"
    echo ""
    
    # Task type
    echo "Task type:"
    echo "  1) Code          - Write or modify code"
    echo "  2) Documentation - Write docs, guides, README"
    echo "  3) Content       - Marketing, blog posts, copy"
    echo "  4) Review        - Code review, quality check"
    echo "  5) Bug Fix       - Fix a specific bug"
    echo "  6) Feature       - Implement new feature"
    echo "  7) Refactor      - Improve existing code"
    echo "  8) Test          - Write or run tests"
    echo "  9) Deployment    - Deploy or configure"
    echo " 10) Research      - Investigate or analyze"
    echo ""
    read -p "Select type [1-10]: " type_choice
    
    case $type_choice in
        1) task_type="code" ;;
        2) task_type="documentation" ;;
        3) task_type="content" ;;
        4) task_type="review" ;;
        5) task_type="bug_fix" ;;
        6) task_type="feature" ;;
        7) task_type="refactor" ;;
        8) task_type="test" ;;
        9) task_type="deployment" ;;
        10) task_type="research" ;;
        *) task_type="code" ;;
    esac
    
    # Priority
    echo ""
    echo "Priority level:"
    echo "  1) 🔴 Critical - Blocks other work, needs immediate attention"
    echo "  2) 🟠 High     - Important, should be done soon"
    echo "  3) 🟡 Medium   - Normal priority"
    echo "  4) 🟢 Low      - Nice to have, can wait"
    echo ""
    read -p "Select priority [1-4]: " priority_choice
    
    case $priority_choice in
        1) priority="critical" ;;
        2) priority="high" ;;
        3) priority="medium" ;;
        4) priority="low" ;;
        *) priority="medium" ;;
    esac
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --arg type "$task_type" \
        --arg priority "$priority" \
        '. + {type: $type, priority: $priority}')
}

prompt_assignment() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ AI Agent Assignment ━━━${NC}"
    echo ""
    
    echo "Assign to:"
    echo "  1) 🤖 Auto       - System chooses best AI"
    echo "  2) 🎭 Claude     - Architecture, documentation, UX"
    echo "  3) 💬 ChatGPT    - Content, writing, creative"
    echo "  4) ✨ Gemini     - Firebase, cloud, databases"
    echo "  5) ⚡ Grok       - Innovation, research, analysis"
    echo "  6) 🚀 Copilot    - Code generation, deployment"
    echo ""
    read -p "Select agent [1-6]: " agent_choice
    
    case $agent_choice in
        1) agent="auto" ;;
        2) agent="claude" ;;
        3) agent="chatgpt" ;;
        4) agent="gemini" ;;
        5) agent="grok" ;;
        6) agent="copilot" ;;
        *) agent="auto" ;;
    esac
    
    # Autonomy level
    echo ""
    echo "Autonomy level:"
    echo "  1) 0%   - Requires approval for every step"
    echo "  2) 25%  - Requires approval for major decisions"
    echo "  3) 50%  - Semi-autonomous, check-ins required"
    echo "  4) 75%  - Mostly autonomous, minimal oversight"
    echo "  5) 100% - Fully autonomous, no approval needed"
    echo ""
    read -p "Select autonomy [1-5]: " autonomy_choice
    
    case $autonomy_choice in
        1) autonomy=0 ;;
        2) autonomy=25 ;;
        3) autonomy=50 ;;
        4) autonomy=75 ;;
        5) autonomy=100 ;;
        *) autonomy=50 ;;
    esac
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --arg agent "$agent" \
        --arg autonomy "$autonomy" \
        '. + {assigned_to: $agent, autonomy_level: ($autonomy | tonumber)}')
}

prompt_timing() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Time Estimation ━━━${NC}"
    echo ""
    
    echo "Estimated duration:"
    echo "  1) 15 minutes"
    echo "  2) 30 minutes"
    echo "  3) 1 hour"
    echo "  4) 2 hours"
    echo "  5) 4 hours"
    echo "  6) 8 hours (1 day)"
    echo "  7) 2 days"
    echo "  8) Custom"
    echo ""
    read -p "Select duration [1-8]: " duration_choice
    
    case $duration_choice in
        1) duration="15m" ;;
        2) duration="30m" ;;
        3) duration="1h" ;;
        4) duration="2h" ;;
        5) duration="4h" ;;
        6) duration="8h" ;;
        7) duration="2d" ;;
        8) 
            read -p "Enter custom duration (e.g., 3h, 5d): " duration
            ;;
        *) duration="1h" ;;
    esac
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --arg duration "$duration" \
        '. + {estimated_duration: $duration}')
}

prompt_dependencies() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Dependencies ━━━${NC}"
    echo ""
    
    read -p "Does this task depend on other tasks? [y/N]: " has_deps
    
    dependencies="[]"
    if [[ "$has_deps" =~ ^[Yy] ]]; then
        echo ""
        log_info "Enter task IDs this depends on (one per line, empty line to finish):"
        
        dep_array=""
        while true; do
            read -r dep_id
            [[ -z "$dep_id" ]] && break
            
            # Validate task exists
            if jq -e --arg id "$dep_id" '.tasks[] | select(.task_id == $id)' "$TASK_QUEUE" >/dev/null 2>&1; then
                log_success "Found: $dep_id"
                dep_array="${dep_array}\"${dep_id}\","
            else
                log_error "Task $dep_id not found in queue"
            fi
        done
        
        if [[ -n "$dep_array" ]]; then
            dep_array="${dep_array%,}"  # Remove trailing comma
            dependencies="[$dep_array]"
        fi
    fi
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --argjson deps "$dependencies" \
        '. + {dependencies: $deps}')
}

prompt_files() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ File Information ━━━${NC}"
    echo ""
    
    # Input files
    read -p "Does this task need input files? [y/N]: " has_inputs
    
    input_files="[]"
    if [[ "$has_inputs" =~ ^[Yy] ]]; then
        echo ""
        log_info "Enter input file paths (one per line, empty line to finish):"
        
        input_array=""
        while true; do
            read -r input_file
            [[ -z "$input_file" ]] && break
            
            validated_path=$(validate_file_path "$input_file")
            
            if [[ -e "$validated_path" ]]; then
                log_success "Found: $validated_path"
                input_array="${input_array}\"${validated_path}\","
            else
                log_error "File not found: $validated_path (will add anyway)"
                input_array="${input_array}\"${validated_path}\","
            fi
        done
        
        if [[ -n "$input_array" ]]; then
            input_array="${input_array%,}"
            input_files="[$input_array]"
        fi
    fi
    
    # Output files
    echo ""
    read -p "Will this task create/modify files? [y/N]: " has_outputs
    
    output_files="[]"
    if [[ "$has_outputs" =~ ^[Yy] ]]; then
        echo ""
        log_info "Enter output file paths (one per line, empty line to finish):"
        
        output_array=""
        while true; do
            read -r output_file
            [[ -z "$output_file" ]] && break
            
            validated_path=$(validate_file_path "$output_file")
            log_success "Will create: $validated_path"
            output_array="${output_array}\"${validated_path}\","
        done
        
        if [[ -n "$output_array" ]]; then
            output_array="${output_array%,}"
            output_files="[$output_array]"
        fi
    fi
    
    # Output directory
    echo ""
    read -p "Output directory [$OUTPUT_DIR]: " output_dir
    output_dir="${output_dir:-$OUTPUT_DIR}"
    output_dir=$(validate_file_path "$output_dir")
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --argjson inputs "$input_files" \
        --argjson outputs "$output_files" \
        --arg outdir "$output_dir" \
        '. + {input_files: $inputs, output_files: $outputs, output_directory: $outdir}')
}

prompt_tags() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Tags & Metadata ━━━${NC}"
    echo ""
    
    log_info "Add tags for categorization (comma-separated):"
    log_info "Examples: api, frontend, backend, urgent, bug, feature"
    echo ""
    read -r tags_input
    
    tags="[]"
    if [[ -n "$tags_input" ]]; then
        # Split by comma and create JSON array
        IFS=',' read -ra tag_array <<< "$tags_input"
        tag_json=""
        for tag in "${tag_array[@]}"; do
            # Trim whitespace
            tag=$(echo "$tag" | xargs)
            tag_json="${tag_json}\"${tag}\","
        done
        
        if [[ -n "$tag_json" ]]; then
            tag_json="${tag_json%,}"
            tags="[$tag_json]"
        fi
    fi
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --argjson tags "$tags" \
        '. + {tags: $tags}')
}

prompt_peer_review() {
    echo ""
    echo -e "${BOLD}${BLUE}━━━ Peer Review ━━━${NC}"
    echo ""
    
    read -p "Require peer review after completion? [Y/n]: " needs_review
    needs_review="${needs_review:-y}"
    
    reviewer="auto"
    if [[ "$needs_review" =~ ^[Yy] ]]; then
        echo ""
        echo "Reviewer:"
        echo "  1) Auto   - System chooses"
        echo "  2) Claude"
        echo "  3) ChatGPT"
        echo "  4) Gemini"
        echo "  5) Grok"
        echo "  6) Copilot"
        echo ""
        read -p "Select reviewer [1-6]: " reviewer_choice
        
        case $reviewer_choice in
            1) reviewer="auto" ;;
            2) reviewer="claude" ;;
            3) reviewer="chatgpt" ;;
            4) reviewer="gemini" ;;
            5) reviewer="grok" ;;
            6) reviewer="copilot" ;;
            *) reviewer="auto" ;;
        esac
    fi
    
    review_required="true"
    [[ "$needs_review" =~ ^[Nn] ]] && review_required="false"
    
    # Store
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --arg required "$review_required" \
        --arg reviewer "$reviewer" \
        '.peer_review = {required: ($required | test("true")), reviewer: $reviewer, review_task_id: null}')
}

# ═══════════════════════════════════════════════════════════════════════════
# TASK CREATION
# ═══════════════════════════════════════════════════════════════════════════

create_task() {
    local task_id=$(generate_task_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Complete the task data
    TASK_DATA=$(echo "$TASK_DATA" | jq \
        --arg id "$task_id" \
        --arg ts "$timestamp" \
        --arg status "pending" \
        '. + {
            task_id: $id,
            status: $status,
            actual_duration: null,
            file_links: {documentation: [], related_code: [], references: []},
            acceptance_criteria: [],
            context: {background: "", constraints: "", references: ""},
            retry_info: {max_retries: 3, current_retry: 0, retry_reason: null},
            timestamps: {
                created_at: $ts,
                assigned_at: null,
                started_at: null,
                completed_at: null,
                updated_at: $ts
            },
            metadata: {created_by: "user", notes: "", parent_project: "", milestone: ""}
        }')
    
    # Add to task queue
    local temp_file=$(mktemp)
    jq --argjson task "$TASK_DATA" '.tasks += [$task]' "$TASK_QUEUE" > "$temp_file"
    mv "$temp_file" "$TASK_QUEUE"
    
    log_success "Task created: $task_id"
    echo ""
    
    # Show summary
    show_task_summary "$task_id"
}

show_task_summary() {
    local task_id="$1"
    
    echo -e "${BOLD}${GREEN}━━━ Task Summary ━━━${NC}"
    echo ""
    
    local task=$(jq --arg id "$task_id" '.tasks[] | select(.task_id == $id)' "$TASK_QUEUE")
    
    echo -e "${CYAN}Task ID:${NC} $(echo "$task" | jq -r '.task_id')"
    echo -e "${CYAN}Title:${NC} $(echo "$task" | jq -r '.title')"
    echo -e "${CYAN}Type:${NC} $(echo "$task" | jq -r '.type')"
    echo -e "${CYAN}Priority:${NC} $(echo "$task" | jq -r '.priority')"
    echo -e "${CYAN}Assigned to:${NC} $(echo "$task" | jq -r '.assigned_to')"
    echo -e "${CYAN}Autonomy:${NC} $(echo "$task" | jq -r '.autonomy_level')%"
    echo -e "${CYAN}Duration:${NC} $(echo "$task" | jq -r '.estimated_duration')"
    echo -e "${CYAN}Status:${NC} $(echo "$task" | jq -r '.status')"
    
    local dep_count=$(echo "$task" | jq '.dependencies | length')
    if [[ "$dep_count" -gt 0 ]]; then
        echo -e "${CYAN}Dependencies:${NC} $dep_count task(s)"
    fi
    
    local input_count=$(echo "$task" | jq '.input_files | length')
    if [[ "$input_count" -gt 0 ]]; then
        echo -e "${CYAN}Input files:${NC} $input_count file(s)"
    fi
    
    local output_count=$(echo "$task" | jq '.output_files | length')
    if [[ "$output_count" -gt 0 ]]; then
        echo -e "${CYAN}Output files:${NC} $output_count file(s)"
    fi
    
    echo ""
    echo -e "${DIM}View full task: jq '.tasks[] | select(.task_id == \"$task_id\")' $TASK_QUEUE${NC}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# QUICK ADD MODE
# ═══════════════════════════════════════════════════════════════════════════

quick_add() {
    local title="$1"
    local task_id=$(generate_task_id)
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    local task=$(jq -n \
        --arg id "$task_id" \
        --arg title "$title" \
        --arg ts "$timestamp" \
        '{
            task_id: $id,
            title: $title,
            description: $title,
            type: "code",
            priority: "medium",
            status: "pending",
            assigned_to: "auto",
            autonomy_level: 50,
            estimated_duration: "1h",
            actual_duration: null,
            dependencies: [],
            input_files: [],
            output_files: [],
            output_directory: "/workspaces/Orkestra/OUTPUT/",
            file_links: {documentation: [], related_code: [], references: []},
            tags: [],
            acceptance_criteria: [],
            context: {background: "", constraints: "", references: ""},
            peer_review: {required: true, reviewer: "auto", review_task_id: null},
            retry_info: {max_retries: 3, current_retry: 0, retry_reason: null},
            timestamps: {
                created_at: $ts,
                assigned_at: null,
                started_at: null,
                completed_at: null,
                updated_at: $ts
            },
            metadata: {created_by: "user", notes: "", parent_project: "", milestone: ""}
        }')
    
    local temp_file=$(mktemp)
    jq --argjson task "$task" '.tasks += [$task]' "$TASK_QUEUE" > "$temp_file"
    mv "$temp_file" "$TASK_QUEUE"
    
    log_success "Quick task created: $task_id - $title"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
    # Check if task queue exists
    if [[ ! -f "$TASK_QUEUE" ]]; then
        log_error "Task queue not found: $TASK_QUEUE"
        exit 1
    fi
    
    # Quick mode
    if [[ "${1:-}" == "--quick" ]] && [[ -n "${2:-}" ]]; then
        quick_add "$2"
        exit 0
    fi
    
    # Interactive mode
    show_header
    
    log_info "This wizard will guide you through creating a new task"
    log_info "Press Ctrl+C at any time to cancel"
    echo ""
    read -p "Press Enter to continue..."
    
    show_header
    prompt_basic_info
    
    show_header
    prompt_classification
    
    show_header
    prompt_assignment
    
    show_header
    prompt_timing
    
    show_header
    prompt_dependencies
    
    show_header
    prompt_files
    
    show_header
    prompt_tags
    
    show_header
    prompt_peer_review
    
    show_header
    log_info "Creating task..."
    sleep 1
    
    create_task
    
    log_success "Task added to queue successfully!"
    echo ""
    log_info "Next steps:"
    echo "  • View all tasks: jq '.tasks' $TASK_QUEUE"
    echo "  • Start automation: ./SCRIPTS/AUTOMATION/start-idle-monitors.sh start"
    echo "  • Check agent health: ./SCRIPTS/MONITORING/agent-health.sh"
    echo ""
}

# Show usage
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
${BOLD}Orkestra Task Creator${NC}

${BOLD}USAGE:${NC}
    $0                    Interactive mode (guided wizard)
    $0 --quick "title"    Quick add with defaults
    $0 --help             Show this help

${BOLD}INTERACTIVE MODE:${NC}
    Guides you through creating a complete task with all details:
    • Basic info (title, description)
    • Classification (type, priority)
    • Assignment (AI agent, autonomy level)
    • Timing (duration estimate)
    • Dependencies (other tasks)
    • Files (inputs, outputs)
    • Tags & metadata
    • Peer review settings

${BOLD}QUICK MODE:${NC}
    Creates a basic task with default settings:
    • Type: code
    • Priority: medium
    • Assignment: auto
    • Autonomy: 50%
    • Duration: 1h

${BOLD}EXAMPLES:${NC}
    ${CYAN}# Interactive mode${NC}
    $0

    ${CYAN}# Quick add${NC}
    $0 --quick "Fix login bug"
    $0 --quick "Write API documentation"

${BOLD}TASK QUEUE:${NC}
    Tasks are added to: ${CYAN}$TASK_QUEUE${NC}

${BOLD}TEMPLATE:${NC}
    Task structure defined in: ${CYAN}$TEMPLATE_FILE${NC}

EOF
    exit 0
fi

main "$@"
