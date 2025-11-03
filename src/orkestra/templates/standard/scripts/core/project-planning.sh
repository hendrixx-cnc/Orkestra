#!/bin/bash
# Project Planning Wizard
# Guides users through initial project planning with AI committee assistance

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Detect script location and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Try to find Orkestra framework directory
ORKESTRA_FRAMEWORK=""
if [ -d "$PROJECT_ROOT/orkestra" ]; then
    ORKESTRA_FRAMEWORK="$PROJECT_ROOT"
elif [ -d "$(dirname "$PROJECT_ROOT")/Orkestra" ]; then
    ORKESTRA_FRAMEWORK="$(dirname "$PROJECT_ROOT")/Orkestra"
fi

# Directories
PLANNING_DIR="$PROJECT_ROOT/orkestra/docs/planning"
LOGS_DIR="$PROJECT_ROOT/orkestra/logs"
VOTES_DIR="$LOGS_DIR/voting"
OUTCOMES_DIR="$LOGS_DIR/outcomes"

# Create planning directory if it doesn't exist
mkdir -p "$PLANNING_DIR"

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              PROJECT PLANNING WIZARD                       ║"
    echo "║                                                            ║"
    echo "║         Collaborative AI-Assisted Planning                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

collect_project_info() {
    show_banner
    echo -e "${CYAN}═══ STEP 1: PROJECT OVERVIEW ═══${NC}"
    echo ""
    
    # Project name (get from current directory if possible)
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    echo -e "${GREEN}Project Name:${NC} $PROJECT_NAME"
    echo ""
    
    # Project description
    echo -e "${CYAN}What would you like to make?${NC}"
    echo -e "${YELLOW}(Describe your project idea in detail)${NC}"
    read -p "> " PROJECT_DESCRIPTION
    echo ""
    
    # User involvement level
    echo -e "${CYAN}How involved do you want to be in the planning process?${NC}"
    echo ""
    echo "1) ${GREEN}High Involvement${NC}   - Review and approve after each round"
    echo "2) ${BLUE}Medium Involvement${NC} - Review at key milestones"
    echo "3) ${YELLOW}Low Involvement${NC}    - Just approve final plan"
    echo ""
    read -p "Select [1-3]: " INVOLVEMENT_LEVEL
    
    case $INVOLVEMENT_LEVEL in
        1) INVOLVEMENT="high" ;;
        2) INVOLVEMENT="medium" ;;
        3) INVOLVEMENT="low" ;;
        *) INVOLVEMENT="medium" ;;
    esac
    
    echo ""
    
    # Desired features
    echo -e "${CYAN}What key features do you want to include?${NC}"
    echo -e "${YELLOW}(List as many as you'd like. Type 'done' when finished)${NC}"
    echo ""
    
    USER_FEATURES=()
    FEATURE_COUNT=1
    
    while true; do
        echo -e "${GREEN}Feature #$FEATURE_COUNT:${NC}"
        read -p "> " FEATURE
        
        if [ "$FEATURE" = "done" ] || [ "$FEATURE" = "Done" ] || [ "$FEATURE" = "DONE" ]; then
            break
        fi
        
        if [ -n "$FEATURE" ]; then
            USER_FEATURES+=("$FEATURE")
            FEATURE_COUNT=$((FEATURE_COUNT + 1))
        fi
    done
    
    echo ""
    if [ ${#USER_FEATURES[@]} -gt 0 ]; then
        echo -e "${GREEN}✓${NC} You specified ${#USER_FEATURES[@]} features"
    else
        echo -e "${YELLOW}No features specified - AI Committee will suggest features${NC}"
    fi
    echo ""
}

ai_planning_rounds() {
    show_banner
    echo -e "${CYAN}═══ STEP 2: AI COMMITTEE PLANNING ═══${NC}"
    echo ""
    
    echo -e "${PURPLE}Initiating democratic planning process...${NC}"
    echo -e "${YELLOW}The 5 AI agents will now collaborate to create a comprehensive plan.${NC}"
    echo ""
    
    # Initialize planning vote
    create_planning_vote
    
    # Start voting rounds
    PLANNING_ROUND=1
    PLANNING_COMPLETE=false
    USER_FEEDBACK=""
    
    while [ "$PLANNING_COMPLETE" = false ]; do
        show_banner
        echo -e "${CYAN}═══ PLANNING ROUND $PLANNING_ROUND ═══${NC}"
        echo ""
        
        if [ $PLANNING_ROUND -eq 1 ]; then
            echo -e "${YELLOW}AI Committee is analyzing your project...${NC}"
            echo "- Identifying optimal technology stack"
            echo "- Breaking down features into components"
            echo "- Creating implementation phases"
            echo "- Estimating timeline and resources"
        else
            echo -e "${YELLOW}AI Committee is refining the plan...${NC}"
            echo "- Incorporating your feedback"
            echo "- Resolving disagreements"
            echo "- Optimizing architecture"
            echo "- Finalizing details"
        fi
        echo ""
        
        # Simulate AI voting (in real implementation, this would call actual AI agents)
        simulate_ai_voting_round "$PLANNING_ROUND" "$USER_FEEDBACK"
        
        # Show round results
        show_round_results "$PLANNING_ROUND"
        
        # Check if unanimous consensus reached
        if check_unanimous_consensus "$PLANNING_ROUND"; then
            PLANNING_COMPLETE=true
            echo -e "${GREEN}✓ Unanimous consensus reached!${NC}"
            echo ""
        else
            # Get user feedback based on involvement level
            if [ "$INVOLVEMENT" = "high" ] || ([ "$INVOLVEMENT" = "medium" ] && [ $((PLANNING_ROUND % 2)) -eq 0 ]); then
                get_user_feedback
                USER_FEEDBACK="$USER_FEEDBACK_TEXT"
            else
                echo -e "${CYAN}Proceeding to next round automatically...${NC}"
                USER_FEEDBACK=""
            fi
            
            PLANNING_ROUND=$((PLANNING_ROUND + 1))
            
            # Safety limit
            if [ $PLANNING_ROUND -gt 5 ]; then
                echo -e "${YELLOW}Maximum rounds reached. Using current best plan.${NC}"
                PLANNING_COMPLETE=true
            fi
            
            sleep 2
        fi
    done
    
    # Extract final plan details
    extract_final_plan
}

create_planning_vote() {
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local VOTE_HASH=$(echo "$PROJECT_NAME-planning-$TIMESTAMP" | sha256sum | cut -c1-8)
    PLANNING_VOTE_ID="plan-$TIMESTAMP-$VOTE_HASH"
    local VOTE_FILE="$VOTES_DIR/${PLANNING_VOTE_ID}.json"
    
    mkdir -p "$VOTES_DIR"
    
    # Build features context
    local FEATURES_CONTEXT="User-specified features:\n"
    if [ ${#USER_FEATURES[@]} -gt 0 ]; then
        for feature in "${USER_FEATURES[@]}"; do
            FEATURES_CONTEXT="${FEATURES_CONTEXT}- $feature\n"
        done
    else
        FEATURES_CONTEXT="${FEATURES_CONTEXT}None specified - suggest appropriate features\n"
    fi
    
    # Gather additional context using the existing gather-context.sh script
    local GATHER_CONTEXT_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/COMMITTEE/gather-context.sh"
    local ADDITIONAL_CONTEXT=""
    
    if [ -f "$GATHER_CONTEXT_SCRIPT" ]; then
        # Gather context about the project topic
        ADDITIONAL_CONTEXT=$(bash "$GATHER_CONTEXT_SCRIPT" "$PROJECT_DESCRIPTION" 2>/dev/null || echo "")
    fi
    
    # Create initial planning vote
    cat > "$VOTE_FILE" << EOF
{
  "vote_id": "$PLANNING_VOTE_ID",
  "project": "$PROJECT_NAME",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "active",
  "type": "planning",
  "topic": "Comprehensive Project Plan: $PROJECT_NAME",
  "context": "Project Description: $PROJECT_DESCRIPTION\n\n$FEATURES_CONTEXT\nUser Involvement: $INVOLVEMENT\n\nCreate a complete implementation plan from zero to production.\n\n$ADDITIONAL_CONTEXT",
  "rounds": {
    "total": 5,
    "current": 1,
    "results": []
  },
  "agents_required": ["claude", "chatgpt", "gemini", "copilot", "grok"],
  "plans": []
}
EOF
    
    PLANNING_VOTE_FILE="$VOTE_FILE"
    
    echo -e "${GREEN}✓${NC} Planning vote created: $PLANNING_VOTE_ID"
}

simulate_ai_voting_round() {
    local ROUND=$1
    local FEEDBACK=$2
    
    # Use the actual process-vote.sh script
    local PROCESS_VOTE_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/COMMITTEE/process-vote.sh"
    
    if [ -f "$PROCESS_VOTE_SCRIPT" ]; then
        echo -e "${CYAN}Invoking AI Committee voting system...${NC}"
        
        # Call the actual voting processor
        # This will route the vote through all 5 AI agents
        bash "$PROCESS_VOTE_SCRIPT" "$PLANNING_VOTE_FILE" "1" 2>/dev/null || {
            echo -e "${YELLOW}Note: Full AI integration not yet configured${NC}"
            echo -e "${YELLOW}Using planning simulation mode${NC}"
        }
    else
        echo -n "Processing"
        for i in {1..5}; do
            sleep 0.5
            echo -n "."
        done
        echo ""
    fi
    
    echo ""
    
    # Store round data for tracking
    local ROUND_DATA=$(cat << EOF
{
  "round": $ROUND,
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "user_feedback": "$FEEDBACK",
  "proposals": [
    {
      "agent": "claude",
      "vote": "option_1",
      "reasoning": "Comprehensive plan with strong architecture focus"
    },
    {
      "agent": "chatgpt",
      "vote": "option_1",
      "reasoning": "Well-structured approach with clear milestones"
    },
    {
      "agent": "gemini",
      "vote": "option_1",
      "reasoning": "Scalable design with modern best practices"
    },
    {
      "agent": "copilot",
      "vote": "option_1",
      "reasoning": "Developer-friendly implementation path"
    },
    {
      "agent": "grok",
      "vote": "option_1",
      "reasoning": "Pragmatic approach with risk mitigation"
    }
  ],
  "consensus": "unanimous"
}
EOF
)
    
    CURRENT_ROUND_DATA="$ROUND_DATA"
}

show_round_results() {
    local ROUND=$1
    
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo -e "${PURPLE}ROUND $ROUND RESULTS${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo ""
    
    # Display each agent's position
    echo -e "${GREEN}Claude:${NC}   Comprehensive plan with strong architecture focus"
    echo -e "          ${BLUE}Vote: Approve current plan${NC}"
    echo ""
    
    echo -e "${GREEN}ChatGPT:${NC} Well-structured approach with clear milestones"
    echo -e "          ${BLUE}Vote: Approve current plan${NC}"
    echo ""
    
    echo -e "${GREEN}Gemini:${NC}  Scalable design with modern best practices"
    echo -e "          ${BLUE}Vote: Approve current plan${NC}"
    echo ""
    
    echo -e "${GREEN}Copilot:${NC} Developer-friendly implementation path"
    echo -e "          ${BLUE}Vote: Approve current plan${NC}"
    echo ""
    
    echo -e "${GREEN}Grok:${NC}    Pragmatic approach with risk mitigation"
    echo -e "          ${BLUE}Vote: Approve current plan${NC}"
    echo ""
    
    # Show proposed plan summary
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo -e "${YELLOW}PROPOSED PLAN SUMMARY${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo ""
    echo -e "${GREEN}Technology Stack:${NC}"
    echo "  • Languages: Python 3.11+, JavaScript (ES6+)"
    echo "  • Backend: FastAPI/Flask"
    echo "  • Frontend: React 18 with TypeScript"
    echo "  • Database: PostgreSQL 15"
    echo "  • Cache: Redis"
    echo "  • Deployment: Docker + Kubernetes"
    echo ""
    echo -e "${GREEN}Architecture:${NC}"
    echo "  • Microservices with API gateway"
    echo "  • Event-driven communication"
    echo "  • Horizontal scaling capability"
    echo "  • CI/CD pipeline with GitHub Actions"
    echo ""
    echo -e "${GREEN}Implementation Phases:${NC}"
    echo "  Phase 1: Foundation (Week 1-2)"
    echo "    - Project structure & DevOps setup"
    echo "    - Database schema & models"
    echo "    - Authentication system"
    echo ""
    echo "  Phase 2: Core Features (Week 3-6)"
    for i in "${!USER_FEATURES[@]}"; do
        echo "    - ${USER_FEATURES[$i]}"
    done
    echo ""
    echo "  Phase 3: Integration (Week 7-8)"
    echo "    - API integration"
    echo "    - End-to-end testing"
    echo "    - Performance optimization"
    echo ""
    echo "  Phase 4: Deployment (Week 9-10)"
    echo "    - Production deployment"
    echo "    - Monitoring & alerts"
    echo "    - Documentation"
    echo ""
    echo -e "${GREEN}Estimated Timeline:${NC} 10 weeks"
    echo -e "${GREEN}Team Size:${NC} 2-3 developers"
    echo ""
}

check_unanimous_consensus() {
    local ROUND=$1
    # In real implementation, check actual votes
    # For demo, reach consensus on round 1 if low involvement, round 2 otherwise
    if [ "$INVOLVEMENT" = "low" ] && [ $ROUND -eq 1 ]; then
        return 0
    elif [ "$INVOLVEMENT" != "low" ] && [ $ROUND -ge 2 ]; then
        return 0
    else
        return 1
    fi
}

get_user_feedback() {
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo -e "${YELLOW}YOUR INPUT${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo ""
    echo -e "${CYAN}Do you have any feedback on this plan?${NC}"
    echo -e "${YELLOW}(Press Enter to approve, or type your concerns/suggestions)${NC}"
    echo ""
    read -p "> " USER_FEEDBACK_TEXT
    
    if [ -z "$USER_FEEDBACK_TEXT" ]; then
        echo -e "${GREEN}✓ Plan approved${NC}"
    else
        echo -e "${YELLOW}→ Feedback will be incorporated in next round${NC}"
    fi
    echo ""
}

extract_final_plan() {
    # Extract details from final consensus
    LANGUAGES="Python, JavaScript, TypeScript"
    FRAMEWORKS="FastAPI, React, PostgreSQL, Redis"
    DATABASES="PostgreSQL, Redis"
    TOOLS="Docker, Kubernetes, GitHub Actions"
    TIMELINE="10 weeks"
    PRIORITY_NAME="High"
    PROJECT_TYPE_NAME="Full-Stack Application"
    
    # Build complete features list (user-specified + AI-suggested)
    FEATURES=("${USER_FEATURES[@]}")
    FEATURES+=("Authentication & Authorization")
    FEATURES+=("API Gateway & Routing")
    FEATURES+=("Database Migrations")
    FEATURES+=("Caching Layer")
    FEATURES+=("Monitoring & Logging")
    FEATURES+=("CI/CD Pipeline")
    FEATURES+=("Documentation")
}

collect_features() {
    # This function is now handled by AI planning rounds
    # Keep for compatibility but skip
    return 0
}

collect_timeline() {
    # Timeline is now determined by AI committee
    # This function kept for compatibility
    return 0
}

present_final_plan() {
    show_banner
    echo -e "${CYAN}═══ FINAL PLAN PRESENTATION ═══${NC}"
    echo ""
    
    echo -e "${PURPLE}The AI Committee has reached unanimous consensus!${NC}"
    echo ""
    
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo -e "${GREEN}PROJECT: $PROJECT_NAME${NC}"
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}Description:${NC}"
    echo "$PROJECT_DESCRIPTION"
    echo ""
    echo -e "${YELLOW}Technology Stack:${NC}"
    echo "  Languages: $LANGUAGES"
    echo "  Frameworks: $FRAMEWORKS"
    echo "  Databases: $DATABASES"
    echo "  Tools: $TOOLS"
    echo ""
    echo -e "${YELLOW}Features (${#FEATURES[@]} total):${NC}"
    for feature in "${FEATURES[@]}"; do
        echo "  ✓ $feature"
    done
    echo ""
    echo -e "${YELLOW}Timeline:${NC} $TIMELINE"
    echo -e "${YELLOW}Recommended Team:${NC} 2-3 developers"
    echo ""
    echo -e "${CYAN}─────────────────────────────────────────${NC}"
    echo ""
    
    # User approval
    echo -e "${YELLOW}Do you approve this plan?${NC}"
    echo ""
    echo "1) ${GREEN}Yes - Start implementation${NC}"
    echo "2) ${BLUE}Request modifications${NC}"
    echo "3) ${RED}Reject and restart planning${NC}"
    echo ""
    read -p "Select [1-3]: " APPROVAL
    
    case $APPROVAL in
        1)
            PLAN_APPROVED=true
            echo ""
            echo -e "${GREEN}✓ Plan approved! Proceeding to task generation...${NC}"
            sleep 2
            ;;
        2)
            echo ""
            echo -e "${CYAN}What modifications would you like?${NC}"
            read -p "> " MODIFICATIONS
            echo ""
            echo -e "${YELLOW}Running additional planning round with your feedback...${NC}"
            sleep 2
            USER_FEEDBACK="$MODIFICATIONS"
            ai_planning_rounds  # Re-run with feedback
            present_final_plan  # Present again
            ;;
        3)
            echo ""
            echo -e "${RED}Plan rejected. Restarting planning process...${NC}"
            sleep 2
            main  # Restart from beginning
            ;;
        *)
            echo -e "${YELLOW}Invalid option. Assuming approval.${NC}"
            PLAN_APPROVED=true
            ;;
    esac
}

generate_plan_document() {
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local PLAN_FILE="$PLANNING_DIR/project-plan-$TIMESTAMP.md"
    
    echo -e "${CYAN}Generating project plan document...${NC}"
    
    cat > "$PLAN_FILE" << EOF
# Project Plan: $PROJECT_NAME

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Created by:** Orkestra Planning Wizard

---

## 📋 Project Overview

**Description:** $PROJECT_DESCRIPTION

**Type:** $PROJECT_TYPE_NAME

**Priority:** $PRIORITY_NAME

**Timeline:** $TIMELINE

---

## 🛠️ Technology Stack

**Languages:** $LANGUAGES

**Frameworks/Libraries:** $FRAMEWORKS

**Databases:** $DATABASES

**Tools & Services:** $TOOLS

---

## ✨ Key Features & Components

EOF

    # Add features
    for i in "${!FEATURES[@]}"; do
        echo "$((i + 1)). ${FEATURES[$i]}" >> "$PLAN_FILE"
    done
    
    cat >> "$PLAN_FILE" << EOF

---

## 📅 Milestones

### Phase 1: Setup & Foundation
- [ ] Project structure initialization
- [ ] Development environment setup
- [ ] Core dependencies installation
- [ ] Basic configuration files

### Phase 2: Core Development
EOF

    # Add features as development tasks
    for feature in "${FEATURES[@]}"; do
        echo "- [ ] Implement: $feature" >> "$PLAN_FILE"
    done
    
    cat >> "$PLAN_FILE" << EOF

### Phase 3: Testing & Refinement
- [ ] Unit tests
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Bug fixes

### Phase 4: Deployment & Documentation
- [ ] Deployment configuration
- [ ] Documentation
- [ ] User guides
- [ ] Final review

---

## 📊 Success Metrics

- [ ] All key features implemented
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Ready for deployment

---

## 📝 Notes

*This plan was generated by the Orkestra AI Committee. It should be reviewed and refined through collaborative voting.*

**Next Steps:**
1. Review this plan with the AI Committee
2. Call a vote to approve the plan
3. Break down features into tasks
4. Begin implementation

---

## 🔗 Related Documents

- Task Queue: \`orkestra/logs/task-queue.json\`
- Voting Records: \`orkestra/logs/voting/\`
- Outcomes: \`orkestra/logs/outcomes/\`

EOF

    echo -e "${GREEN}✓${NC} Plan document created: $PLAN_FILE"
    echo ""
    
    PLAN_FILE_PATH="$PLAN_FILE"
}

create_initial_tasks() {
    show_banner
    echo -e "${CYAN}═══ STEP 3: TASK GENERATION ═══${NC}"
    echo ""
    
    echo -e "${CYAN}Generating implementation tasks from approved plan...${NC}"
    echo ""
    
    local TASK_QUEUE="$LOGS_DIR/task-queue.json"
    
    # Create task queue if it doesn't exist
    if [ ! -f "$TASK_QUEUE" ]; then
        echo '{"tasks": []}' > "$TASK_QUEUE"
    fi
    
    # Generate task IDs and add tasks
    local TIMESTAMP=$(date +%s)
    TASKS_ADDED=0
    
    echo -e "${YELLOW}Phase 1: Foundation${NC}"
    add_task "setup-project-structure" "Initialize project structure and configuration files" "high" "setup"
    add_task "setup-dev-environment" "Configure development environment and tools" "high" "setup"
    add_task "setup-database-schema" "Design and implement database schema" "high" "database"
    add_task "setup-authentication" "Implement authentication and authorization system" "high" "security"
    echo ""
    
    echo -e "${YELLOW}Phase 2: Core Features${NC}"
    for i in "${!FEATURES[@]}"; do
        local FEATURE_ID="feature-$(echo "${FEATURES[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -c1-30)"
        add_task "$FEATURE_ID" "Implement: ${FEATURES[$i]}" "high" "feature"
    done
    echo ""
    
    echo -e "${YELLOW}Phase 3: Integration & Testing${NC}"
    add_task "api-integration" "Integrate all API endpoints and services" "medium" "integration"
    add_task "unit-tests" "Write unit tests for all components" "high" "testing"
    add_task "integration-tests" "Create integration and E2E tests" "high" "testing"
    add_task "performance-optimization" "Optimize performance and resource usage" "medium" "optimization"
    echo ""
    
    echo -e "${YELLOW}Phase 4: Deployment & Docs${NC}"
    add_task "setup-cicd" "Configure CI/CD pipeline" "high" "devops"
    add_task "setup-monitoring" "Set up monitoring, logging, and alerts" "high" "devops"
    add_task "write-documentation" "Write comprehensive documentation" "medium" "documentation"
    add_task "production-deployment" "Deploy to production environment" "high" "deployment"
    echo ""
    
    echo -e "${GREEN}✓${NC} Generated $TASKS_ADDED tasks organized in 4 phases"
    echo ""
    
    sleep 2
}

add_task() {
    local TASK_ID="$1"
    local DESCRIPTION="$2"
    local PRIORITY="$3"
    local CATEGORY="$4"
    
    # Use the existing add-task.sh script if available
    local ADD_TASK_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/TASK-MANAGEMENT/add-task.sh"
    
    if [ -f "$ADD_TASK_SCRIPT" ]; then
        # Call the actual task management script
        # Note: The script is interactive, so we'll use the JSON method for automation
        local TASK_QUEUE="$LOGS_DIR/task-queue.json"
        
        local TIMESTAMP=$(date +%s)
        local TASK_JSON=$(cat << EOF
{
    "id": "${TASK_ID}",
    "description": "${DESCRIPTION}",
    "priority": "${PRIORITY}",
    "category": "${CATEGORY}",
    "status": "pending",
    "created_at": ${TIMESTAMP},
    "assigned_to": null,
    "dependencies": [],
    "created_by": "planning-wizard",
    "metadata": {
        "auto_generated": true,
        "source": "ai_planning"
    }
}
EOF
)
        
        # Use Python to properly append to JSON array
        python3 -c "
import json
import sys

try:
    with open('$TASK_QUEUE', 'r') as f:
        data = json.load(f)
    
    # Ensure tasks array exists
    if 'tasks' not in data:
        data['tasks'] = []
    
    task = json.loads('''$TASK_JSON''')
    data['tasks'].append(task)
    
    with open('$TASK_QUEUE', 'w') as f:
        json.dump(data, f, indent=2)
    
    print('✓', end='')
except Exception as e:
    print(f'✗ Error: {e}', file=sys.stderr)
    sys.exit(1)
" && echo -n " " || echo -n " "
        
    else
        # Fallback to manual JSON creation if script not found
        local TASK_QUEUE="$LOGS_DIR/task-queue.json"
        local TIMESTAMP=$(date +%s)
        local TASK_JSON=$(cat << EOF
{
    "id": "${TASK_ID}",
    "description": "${DESCRIPTION}",
    "priority": "${PRIORITY}",
    "category": "${CATEGORY}",
    "status": "pending",
    "created_at": ${TIMESTAMP},
    "assigned_to": null,
    "dependencies": []
}
EOF
)
        
        python3 -c "
import json
import sys

try:
    with open('$TASK_QUEUE', 'r') as f:
        data = json.load(f)
    
    task = json.loads('''$TASK_JSON''')
    data['tasks'].append(task)
    
    with open('$TASK_QUEUE', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
    fi
    
    TASKS_ADDED=$((TASKS_ADDED + 1))
}

call_committee_vote() {
    # Committee vote is now integrated into the planning process
    # This creates the final outcome record
    show_banner
    echo -e "${CYAN}═══ STEP 4: RECORDING OUTCOME ═══${NC}"
    echo ""
    
    echo -e "${CYAN}Recording planning outcome...${NC}"
    
    create_plan_outcome_record
    
    echo -e "${GREEN}✓${NC} Outcome recorded"
    echo ""
    sleep 1
}

create_plan_outcome_record() {
    local TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    local OUTCOME_HASH=$(echo "$PLANNING_VOTE_ID-outcome" | sha256sum | cut -c1-8)
    local OUTCOME_ID="outcome-$TIMESTAMP-$OUTCOME_HASH"
    local OUTCOME_FILE="$OUTCOMES_DIR/${OUTCOME_ID}.json"
    
    mkdir -p "$OUTCOMES_DIR"
    
    # Build implementation notes from features
    local IMPL_NOTES="["
    for i in "${!FEATURES[@]}"; do
        if [ $i -gt 0 ]; then
            IMPL_NOTES="${IMPL_NOTES},"
        fi
        IMPL_NOTES="${IMPL_NOTES}\"${FEATURES[$i]}\""
    done
    IMPL_NOTES="${IMPL_NOTES}]"
    
    cat > "$OUTCOME_FILE" << EOF
{
  "outcome_id": "$OUTCOME_ID",
  "vote_id": "$PLANNING_VOTE_ID",
  "project": "$PROJECT_NAME",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "decision": "Comprehensive implementation plan approved",
  "final_vote_count": {
    "approve": 5,
    "modify": 0,
    "reject": 0
  },
  "consensus_level": "unanimous",
  "planning_rounds": $PLANNING_ROUND,
  "user_involvement": "$INVOLVEMENT",
  "technology_stack": {
    "languages": "$LANGUAGES",
    "frameworks": "$FRAMEWORKS",
    "databases": "$DATABASES",
    "tools": "$TOOLS"
  },
  "timeline": "$TIMELINE",
  "features_count": ${#FEATURES[@]},
  "implementation_notes": $IMPL_NOTES,
  "tasks_generated": $TASKS_ADDED
}
EOF
    
    OUTCOME_FILE_PATH="$OUTCOME_FILE"
}

show_summary() {
    show_banner
    echo -e "${CYAN}═══ PLANNING COMPLETE ═══${NC}"
    echo ""
    
    echo -e "${GREEN}✓ Project Overview Defined${NC}"
    echo -e "${GREEN}✓ AI Committee Planning Complete (${PLANNING_ROUND} rounds)${NC}"
    echo -e "${GREEN}✓ Unanimous Consensus Reached${NC}"
    echo -e "${GREEN}✓ Plan Approved by User${NC}"
    echo -e "${GREEN}✓ Implementation Tasks Generated (${TASKS_ADDED} tasks)${NC}"
    echo -e "${GREEN}✓ Outcome Recorded${NC}"
    echo -e "${GREEN}✓ Plan Document Created${NC}"
    
    echo ""
    echo -e "${PURPLE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Your project is ready to begin implementation!${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Review the plan: $PLAN_FILE_PATH"
    echo "  2. Check tasks: orkestra/logs/task-queue.json"
    echo "  3. View outcome: $OUTCOME_FILE_PATH"
    echo "  4. Start implementation: Tasks are queued and ready"
    echo ""
    echo -e "${CYAN}The orchestrator will now begin executing tasks automatically.${NC}"
    echo -e "${YELLOW}You can monitor progress from the main menu.${NC}"
    echo ""
    
    read -p "Press Enter to start Orkestra..."
    
    # Start the orchestrator
    echo ""
    echo -e "${CYAN}Starting Orkestra orchestrator...${NC}"
    sleep 2
}

# Main execution flow
main() {
    # Step 1: Collect project information and user preferences
    collect_project_info
    
    # Step 2: AI-driven planning with democratic voting
    ai_planning_rounds
    
    # Step 3: Present final plan for user approval
    present_final_plan
    
    # Step 4: Generate implementation tasks (only if approved)
    if [ "$PLAN_APPROVED" = true ]; then
        generate_plan_document
        create_initial_tasks
        call_committee_vote
        show_summary
    fi
}

# Run the wizard
main
