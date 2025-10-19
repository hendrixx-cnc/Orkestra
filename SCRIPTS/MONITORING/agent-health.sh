#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA AGENT HEALTH MONITOR
# ═══════════════════════════════════════════════════════════════════════════
# Monitor and test AI agent health status
# Shows API connectivity, rate limits, and workload
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
RUNTIME_DIR="$CONFIG_DIR/RUNTIME"
TASK_QUEUE="$CONFIG_DIR/TASK-QUEUES/task-queue.json"

# Load API keys if available
if [[ -f "$HOME/.config/orkestra/api-keys.env" ]]; then
    source "$HOME/.config/orkestra/api-keys.env"
fi

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

print_header() {
    clear
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}🏥 ORKESTRA AGENT HEALTH MONITOR${NC}                          ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
    echo -e "${DIM}Last updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
}

print_status() {
    local status="$1"
    case "$status" in
        "healthy")
            echo -e "${GREEN}●${NC} Healthy"
            ;;
        "degraded")
            echo -e "${YELLOW}●${NC} Degraded"
            ;;
        "down")
            echo -e "${RED}●${NC} Down"
            ;;
        "unknown")
            echo -e "${DIM}○${NC} Unknown"
            ;;
        *)
            echo -e "${DIM}○${NC} $status"
            ;;
    esac
}

get_agent_workload() {
    local agent="$1"
    if [[ ! -f "$TASK_QUEUE" ]]; then
        echo "0"
        return
    fi
    
    jq -r --arg agent "$agent" '
        [.tasks[] | select(.status == "in_progress" and .assigned_to == $agent)] | length
    ' "$TASK_QUEUE" 2>/dev/null || echo "0"
}

get_agent_completed() {
    local agent="$1"
    if [[ ! -f "$TASK_QUEUE" ]]; then
        echo "0"
        return
    fi
    
    jq -r --arg agent "$agent" '
        [.tasks[] | select(.status == "completed" and .assigned_to == $agent)] | length
    ' "$TASK_QUEUE" 2>/dev/null || echo "0"
}

test_anthropic_api() {
    if [[ -z "${ANTHROPIC_API_KEY:-}" || "$ANTHROPIC_API_KEY" == "your-anthropic-api-key-here" ]]; then
        echo "unconfigured"
        return 1
    fi
    
    local response
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -X POST https://api.anthropic.com/v1/messages \
        -d '{
            "model": "claude-3-haiku-20240307",
            "max_tokens": 10,
            "messages": [{"role": "user", "content": "test"}]
        }' 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo "healthy"
        return 0
    elif [[ "$http_code" == "429" ]]; then
        echo "rate_limited"
        return 1
    elif [[ "$http_code" =~ ^40[13]$ ]]; then
        echo "auth_failed"
        return 1
    else
        echo "error"
        return 1
    fi
}

test_openai_api() {
    if [[ -z "${OPENAI_API_KEY:-}" || "$OPENAI_API_KEY" == "your-openai-api-key-here" ]]; then
        echo "unconfigured"
        return 1
    fi
    
    local response
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -X POST https://api.openai.com/v1/chat/completions \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "test"}],
            "max_tokens": 5
        }' 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo "healthy"
        return 0
    elif [[ "$http_code" == "429" ]]; then
        echo "rate_limited"
        return 1
    elif [[ "$http_code" =~ ^40[13]$ ]]; then
        echo "auth_failed"
        return 1
    else
        echo "error"
        return 1
    fi
}

test_google_api() {
    if [[ -z "${GOOGLE_API_KEY:-}" || "$GOOGLE_API_KEY" == "your-google-api-key-here" ]]; then
        echo "unconfigured"
        return 1
    fi
    
    local response
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        -H "Content-Type: application/json" \
        -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GOOGLE_API_KEY" \
        -d '{
            "contents": [{"parts": [{"text": "test"}]}]
        }' 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo "healthy"
        return 0
    elif [[ "$http_code" == "429" ]]; then
        echo "rate_limited"
        return 1
    elif [[ "$http_code" =~ ^40[03]$ ]]; then
        echo "auth_failed"
        return 1
    else
        echo "error"
        return 1
    fi
}

test_xai_api() {
    if [[ -z "${XAI_API_KEY:-}" || "$XAI_API_KEY" == "your-xai-api-key-here" ]]; then
        echo "unconfigured"
        return 1
    fi
    
    # xAI/Grok API test (using OpenAI-compatible endpoint)
    local response
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        -H "Authorization: Bearer $XAI_API_KEY" \
        -H "Content-Type: application/json" \
        -X POST https://api.x.ai/v1/chat/completions \
        -d '{
            "model": "grok-beta",
            "messages": [{"role": "user", "content": "test"}],
            "max_tokens": 5
        }' 2>/dev/null)
    
    local http_code=$(echo "$response" | tail -n1)
    
    if [[ "$http_code" == "200" ]]; then
        echo "healthy"
        return 0
    elif [[ "$http_code" == "429" ]]; then
        echo "rate_limited"
        return 1
    elif [[ "$http_code" =~ ^40[13]$ ]]; then
        echo "auth_failed"
        return 1
    else
        echo "error"
        return 1
    fi
}

test_github_auth() {
    if command -v gh >/dev/null 2>&1; then
        if gh auth status &>/dev/null; then
            echo "healthy"
            return 0
        else
            echo "auth_failed"
            return 1
        fi
    else
        echo "unconfigured"
        return 1
    fi
}

format_status() {
    local status="$1"
    case "$status" in
        "healthy")
            echo -e "${GREEN}✓ Online${NC}"
            ;;
        "unconfigured")
            echo -e "${YELLOW}○ Not Configured${NC}"
            ;;
        "rate_limited")
            echo -e "${YELLOW}⚠ Rate Limited${NC}"
            ;;
        "auth_failed")
            echo -e "${RED}✗ Auth Failed${NC}"
            ;;
        "error")
            echo -e "${RED}✗ Error${NC}"
            ;;
        *)
            echo -e "${DIM}? Unknown${NC}"
            ;;
    esac
}

get_response_time() {
    local start=$(date +%s%N)
    "$@" >/dev/null 2>&1
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))
    echo "${duration}ms"
}

# ═══════════════════════════════════════════════════════════════════════════
# DISPLAY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

show_agent_summary() {
    print_header
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD} Agent Status Overview${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Quick status check (cached)
    local claude_status="unknown"
    local chatgpt_status="unknown"
    local gemini_status="unknown"
    local grok_status="unknown"
    local github_status="unknown"
    
    [[ -n "${ANTHROPIC_API_KEY:-}" && "$ANTHROPIC_API_KEY" != "your-anthropic-api-key-here" ]] && claude_status="configured" || claude_status="unconfigured"
    [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "your-openai-api-key-here" ]] && chatgpt_status="configured" || chatgpt_status="unconfigured"
    [[ -n "${GOOGLE_API_KEY:-}" && "$GOOGLE_API_KEY" != "your-google-api-key-here" ]] && gemini_status="configured" || gemini_status="unconfigured"
    [[ -n "${XAI_API_KEY:-}" && "$XAI_API_KEY" != "your-xai-api-key-here" ]] && grok_status="configured" || grok_status="unconfigured"
    gh auth status &>/dev/null && github_status="configured" || github_status="unconfigured"
    
    printf "  ${BOLD}%-20s${NC} %-20s %-15s %-10s\n" "Agent" "Status" "Workload" "Completed"
    echo -e "  ${DIM}────────────────────────────────────────────────────────────${NC}"
    
    # Claude
    local claude_workload=$(get_agent_workload "claude")
    local claude_completed=$(get_agent_completed "claude")
    printf "  %-20s " "🤖 Claude"
    [[ "$claude_status" == "configured" ]] && echo -e "${GREEN}✓ Configured${NC}     ${CYAN}$claude_workload active${NC}   ${GREEN}$claude_completed${NC}" || echo -e "${YELLOW}○ Not Setup${NC}"
    
    # ChatGPT
    local chatgpt_workload=$(get_agent_workload "chatgpt")
    local chatgpt_completed=$(get_agent_completed "chatgpt")
    printf "  %-20s " "💬 ChatGPT"
    [[ "$chatgpt_status" == "configured" ]] && echo -e "${GREEN}✓ Configured${NC}     ${CYAN}$chatgpt_workload active${NC}   ${GREEN}$chatgpt_completed${NC}" || echo -e "${YELLOW}○ Not Setup${NC}"
    
    # Gemini
    local gemini_workload=$(get_agent_workload "gemini")
    local gemini_completed=$(get_agent_completed "gemini")
    printf "  %-20s " "✨ Gemini"
    [[ "$gemini_status" == "configured" ]] && echo -e "${GREEN}✓ Configured${NC}     ${CYAN}$gemini_workload active${NC}   ${GREEN}$gemini_completed${NC}" || echo -e "${YELLOW}○ Not Setup${NC}"
    
    # Grok
    local grok_workload=$(get_agent_workload "grok")
    local grok_completed=$(get_agent_completed "grok")
    printf "  %-20s " "🚀 Grok"
    [[ "$grok_status" == "configured" ]] && echo -e "${GREEN}✓ Configured${NC}     ${CYAN}$grok_workload active${NC}   ${GREEN}$grok_completed${NC}" || echo -e "${YELLOW}○ Not Setup${NC}"
    
    # GitHub Copilot
    local copilot_workload=$(get_agent_workload "copilot")
    local copilot_completed=$(get_agent_completed "copilot")
    printf "  %-20s " "🐙 GitHub Copilot"
    [[ "$github_status" == "configured" ]] && echo -e "${GREEN}✓ Authenticated${NC}  ${CYAN}$copilot_workload active${NC}   ${GREEN}$copilot_completed${NC}" || echo -e "${YELLOW}○ Not Auth'd${NC}"
    
    echo ""
}

show_detailed_status() {
    print_header
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD} Detailed Agent Health Check${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}ℹ${NC}  Testing API connectivity... This may take a few seconds.\n"
    
    # Claude / Anthropic
    echo -e "${BOLD}🤖 Claude (Anthropic)${NC}"
    echo -n "   Status: "
    local claude_status=$(test_anthropic_api)
    format_status "$claude_status"
    if [[ -n "${ANTHROPIC_API_KEY:-}" && "$ANTHROPIC_API_KEY" != "your-anthropic-api-key-here" ]]; then
        echo -e "   API Key: ${GREEN}${ANTHROPIC_API_KEY:0:20}...${NC}"
    fi
    echo -e "   Workload: $(get_agent_workload "claude") active tasks"
    echo -e "   Completed: $(get_agent_completed "claude") tasks"
    echo ""
    
    # ChatGPT / OpenAI
    echo -e "${BOLD}💬 ChatGPT (OpenAI)${NC}"
    echo -n "   Status: "
    local chatgpt_status=$(test_openai_api)
    format_status "$chatgpt_status"
    if [[ -n "${OPENAI_API_KEY:-}" && "$OPENAI_API_KEY" != "your-openai-api-key-here" ]]; then
        echo -e "   API Key: ${GREEN}${OPENAI_API_KEY:0:20}...${NC}"
    fi
    echo -e "   Workload: $(get_agent_workload "chatgpt") active tasks"
    echo -e "   Completed: $(get_agent_completed "chatgpt") tasks"
    echo ""
    
    # Gemini / Google
    echo -e "${BOLD}✨ Gemini (Google)${NC}"
    echo -n "   Status: "
    local gemini_status=$(test_google_api)
    format_status "$gemini_status"
    if [[ -n "${GOOGLE_API_KEY:-}" && "$GOOGLE_API_KEY" != "your-google-api-key-here" ]]; then
        echo -e "   API Key: ${GREEN}${GOOGLE_API_KEY:0:20}...${NC}"
    fi
    echo -e "   Workload: $(get_agent_workload "gemini") active tasks"
    echo -e "   Completed: $(get_agent_completed "gemini") tasks"
    echo ""
    
    # Grok / xAI
    echo -e "${BOLD}🚀 Grok (xAI)${NC}"
    echo -n "   Status: "
    local grok_status=$(test_xai_api)
    format_status "$grok_status"
    if [[ -n "${XAI_API_KEY:-}" && "$XAI_API_KEY" != "your-xai-api-key-here" ]]; then
        echo -e "   API Key: ${GREEN}${XAI_API_KEY:0:20}...${NC}"
    fi
    echo -e "   Workload: $(get_agent_workload "grok") active tasks"
    echo -e "   Completed: $(get_agent_completed "grok") tasks"
    echo ""
    
    # GitHub Copilot
    echo -e "${BOLD}🐙 GitHub Copilot${NC}"
    echo -n "   Status: "
    local github_status=$(test_github_auth)
    format_status "$github_status"
    if gh auth status &>/dev/null; then
        local gh_user=$(gh api user -q .login 2>/dev/null || echo "unknown")
        echo -e "   User: ${GREEN}$gh_user${NC}"
    fi
    echo -e "   Workload: $(get_agent_workload "copilot") active tasks"
    echo -e "   Completed: $(get_agent_completed "copilot") tasks"
    echo ""
}

test_specific_agent() {
    local agent="$1"
    
    print_header
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD} Testing Agent: $agent${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    case "$agent" in
        "claude")
            echo -e "${BOLD}🤖 Testing Claude (Anthropic)${NC}\n"
            echo -n "   Checking API key... "
            if [[ -z "${ANTHROPIC_API_KEY:-}" || "$ANTHROPIC_API_KEY" == "your-anthropic-api-key-here" ]]; then
                echo -e "${RED}✗ Not configured${NC}"
                return 1
            fi
            echo -e "${GREEN}✓${NC}"
            
            echo -n "   Testing API connection... "
            local status=$(test_anthropic_api)
            format_status "$status"
            ;;
            
        "chatgpt")
            echo -e "${BOLD}💬 Testing ChatGPT (OpenAI)${NC}\n"
            echo -n "   Checking API key... "
            if [[ -z "${OPENAI_API_KEY:-}" || "$OPENAI_API_KEY" == "your-openai-api-key-here" ]]; then
                echo -e "${RED}✗ Not configured${NC}"
                return 1
            fi
            echo -e "${GREEN}✓${NC}"
            
            echo -n "   Testing API connection... "
            local status=$(test_openai_api)
            format_status "$status"
            ;;
            
        "gemini")
            echo -e "${BOLD}✨ Testing Gemini (Google)${NC}\n"
            echo -n "   Checking API key... "
            if [[ -z "${GOOGLE_API_KEY:-}" || "$GOOGLE_API_KEY" == "your-google-api-key-here" ]]; then
                echo -e "${RED}✗ Not configured${NC}"
                return 1
            fi
            echo -e "${GREEN}✓${NC}"
            
            echo -n "   Testing API connection... "
            local status=$(test_google_api)
            format_status "$status"
            ;;
            
        "grok")
            echo -e "${BOLD}🚀 Testing Grok (xAI)${NC}\n"
            echo -n "   Checking API key... "
            if [[ -z "${XAI_API_KEY:-}" || "$XAI_API_KEY" == "your-xai-api-key-here" ]]; then
                echo -e "${RED}✗ Not configured${NC}"
                return 1
            fi
            echo -e "${GREEN}✓${NC}"
            
            echo -n "   Testing API connection... "
            local status=$(test_xai_api)
            format_status "$status"
            ;;
            
        "copilot")
            echo -e "${BOLD}🐙 Testing GitHub Copilot${NC}\n"
            echo -n "   Checking GitHub CLI... "
            if ! command -v gh >/dev/null 2>&1; then
                echo -e "${RED}✗ Not installed${NC}"
                return 1
            fi
            echo -e "${GREEN}✓${NC}"
            
            echo -n "   Testing authentication... "
            local status=$(test_github_auth)
            format_status "$status"
            ;;
    esac
    
    echo ""
}

show_menu() {
    print_header
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD} Main Menu${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "  ${BOLD}1)${NC} Quick Status Overview"
    echo -e "  ${BOLD}2)${NC} Detailed Health Check (with API tests)"
    echo -e "  ${BOLD}3)${NC} Test Specific Agent"
    echo -e "  ${BOLD}4)${NC} Configure API Keys"
    echo -e "  ${BOLD}5)${NC} View Workload Distribution"
    echo -e "  ${BOLD}6)${NC} Auto-refresh Monitor"
    echo -e "  ${BOLD}q)${NC} Quit"
    
    echo ""
}

show_workload_distribution() {
    print_header
    
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD} Workload Distribution${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [[ ! -f "$TASK_QUEUE" ]]; then
        echo -e "${YELLOW}⚠${NC}  No task queue found\n"
        return
    fi
    
    # Get task counts per agent
    local total_pending=$(jq -r '[.tasks[] | select(.status == "pending")] | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
    local total_in_progress=$(jq -r '[.tasks[] | select(.status == "in_progress")] | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
    local total_completed=$(jq -r '[.tasks[] | select(.status == "completed")] | length' "$TASK_QUEUE" 2>/dev/null || echo "0")
    
    echo -e "  ${BOLD}Total Tasks:${NC}"
    echo -e "    Pending:     ${YELLOW}$total_pending${NC}"
    echo -e "    In Progress: ${CYAN}$total_in_progress${NC}"
    echo -e "    Completed:   ${GREEN}$total_completed${NC}"
    echo ""
    
    echo -e "  ${BOLD}Per Agent:${NC}\n"
    
    for agent in claude chatgpt gemini grok copilot; do
        local active=$(get_agent_workload "$agent")
        local completed=$(get_agent_completed "$agent")
        local total=$((active + completed))
        
        printf "    %-15s " "$agent"
        
        if [[ $total -gt 0 ]]; then
            echo -e "${CYAN}$active${NC} active, ${GREEN}$completed${NC} completed (${BOLD}$total${NC} total)"
        else
            echo -e "${DIM}No tasks${NC}"
        fi
    done
    
    echo ""
}

auto_refresh_monitor() {
    local refresh_interval=5
    
    while true; do
        show_agent_summary
        
        echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${DIM}Auto-refreshing every ${refresh_interval}s. Press Ctrl+C to stop.${NC}"
        
        sleep $refresh_interval
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN MENU LOOP
# ═══════════════════════════════════════════════════════════════════════════

main_menu() {
    while true; do
        show_menu
        read -p "Select option: " -n 1 -r choice
        echo
        
        case "$choice" in
            1)
                show_agent_summary
                echo ""
                read -p "Press Enter to continue..."
                ;;
            2)
                show_detailed_status
                echo ""
                read -p "Press Enter to continue..."
                ;;
            3)
                clear
                echo -e "${BOLD}Select agent to test:${NC}\n"
                echo "  1) Claude"
                echo "  2) ChatGPT"
                echo "  3) Gemini"
                echo "  4) Grok"
                echo "  5) GitHub Copilot"
                echo ""
                read -p "Select agent: " -n 1 -r agent_choice
                echo ""
                
                case "$agent_choice" in
                    1) test_specific_agent "claude" ;;
                    2) test_specific_agent "chatgpt" ;;
                    3) test_specific_agent "gemini" ;;
                    4) test_specific_agent "grok" ;;
                    5) test_specific_agent "copilot" ;;
                    *) echo -e "${RED}✗${NC} Invalid choice" ;;
                esac
                echo ""
                read -p "Press Enter to continue..."
                ;;
            4)
                clear
                echo -e "${CYAN}ℹ${NC}  Opening API keys configuration...\n"
                "$ORKESTRA_ROOT/SCRIPTS/UTILS/setup-apis.sh"
                read -p "Press Enter to continue..."
                ;;
            5)
                show_workload_distribution
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                auto_refresh_monitor
                ;;
            q|Q)
                echo -e "${GREEN}✓${NC}  Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}✗${NC}  Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════
# COMMAND LINE OPTIONS
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    --summary|summary)
        show_agent_summary
        ;;
    --detailed|detailed)
        show_detailed_status
        ;;
    --test)
        if [[ -n "${2:-}" ]]; then
            test_specific_agent "$2"
        else
            echo "Usage: $0 --test <agent>"
            echo "Agents: claude, chatgpt, gemini, grok, copilot"
            exit 1
        fi
        ;;
    --workload|workload)
        show_workload_distribution
        ;;
    --monitor|monitor)
        auto_refresh_monitor
        ;;
    --help|help)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (none)        Interactive menu"
        echo "  --summary     Quick status overview"
        echo "  --detailed    Detailed health check with API tests"
        echo "  --test <agent> Test specific agent"
        echo "  --workload    Show workload distribution"
        echo "  --monitor     Auto-refresh monitor"
        echo "  --help        Show this help message"
        echo ""
        echo "Agents: claude, chatgpt, gemini, grok, copilot"
        ;;
    *)
        main_menu
        ;;
esac
