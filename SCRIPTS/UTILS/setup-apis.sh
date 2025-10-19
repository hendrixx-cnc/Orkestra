#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA API KEYS SETUP
# ═══════════════════════════════════════════════════════════════════════════
# Interactive script to configure API keys for AI agents
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

CONFIG_FILE="$HOME/.config/orkestra/api-keys.env"

# ═══════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}ORKESTRA API KEYS SETUP${NC}                                      ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

print_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC}  $1"
}

prompt_api_key() {
    local service="$1"
    local var_name="$2"
    local url="$3"
    local current_value
    
    echo -e "\n${BOLD}━━━ $service ━━━${NC}"
    echo -e "Get your key from: ${CYAN}$url${NC}"
    
    # Check if key already exists
    if grep -q "^export $var_name=" "$CONFIG_FILE" 2>/dev/null; then
        current_value=$(grep "^export $var_name=" "$CONFIG_FILE" | cut -d'"' -f2)
        if [[ "$current_value" != "your-"*"-api-key-here" && -n "$current_value" ]]; then
            echo -e "${GREEN}✓${NC} Key already configured: ${current_value:0:10}..."
            read -p "Update it? (y/N): " -n 1 -r update
            echo
            if [[ ! $update =~ ^[Yy]$ ]]; then
                return
            fi
        fi
    fi
    
    read -p "Enter your $service API key (or press Enter to skip): " api_key
    
    if [[ -n "$api_key" ]]; then
        # Update or add the key
        if grep -q "^export $var_name=" "$CONFIG_FILE"; then
            sed -i "s|^export $var_name=.*|export $var_name=\"$api_key\"|" "$CONFIG_FILE"
        else
            echo "export $var_name=\"$api_key\"" >> "$CONFIG_FILE"
        fi
        print_success "$service API key configured"
    else
        print_warning "$service API key skipped"
    fi
}

verify_key() {
    local var_name="$1"
    local service="$2"
    
    source "$CONFIG_FILE" 2>/dev/null || true
    
    local value="${!var_name:-}"
    
    if [[ -n "$value" && "$value" != "your-"*"-api-key-here" ]]; then
        echo -e "  ${GREEN}✓${NC} $service: ${value:0:15}..."
        return 0
    else
        echo -e "  ${YELLOW}○${NC} $service: Not configured"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN SETUP
# ═══════════════════════════════════════════════════════════════════════════

main() {
    print_header
    
    # Ensure config directory exists
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Create template if doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_warning "Config file not found. Creating template..."
        cp /dev/stdin "$CONFIG_FILE" << 'EOF'
# Orkestra API Keys Configuration
# Edit this file to add your API keys

export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
export OPENAI_API_KEY="your-openai-api-key-here"
export GOOGLE_API_KEY="your-google-api-key-here"
export GEMINI_API_KEY="$GOOGLE_API_KEY"
export XAI_API_KEY="your-xai-api-key-here"
export GROK_API_KEY="$XAI_API_KEY"
EOF
        print_success "Template created at: $CONFIG_FILE"
    fi
    
    print_info "This script will help you configure API keys for AI agents."
    print_info "You can skip any service by pressing Enter.\n"
    
    # Prompt for each API key
    prompt_api_key "Anthropic Claude" "ANTHROPIC_API_KEY" "https://console.anthropic.com/"
    prompt_api_key "OpenAI ChatGPT" "OPENAI_API_KEY" "https://platform.openai.com/api-keys"
    prompt_api_key "Google Gemini" "GOOGLE_API_KEY" "https://makersuite.google.com/app/apikey"
    prompt_api_key "xAI Grok" "XAI_API_KEY" "https://console.x.ai/"
    
    # GitHub Copilot
    echo -e "\n${BOLD}━━━ GitHub Copilot ━━━${NC}"
    echo -e "Authenticate with: ${CYAN}gh auth login${NC}"
    read -p "Authenticate now? (y/N): " -n 1 -r auth_gh
    echo
    if [[ $auth_gh =~ ^[Yy]$ ]]; then
        gh auth login
    else
        print_warning "GitHub authentication skipped"
    fi
    
    # Verify configuration
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}API Keys Status:${NC}\n"
    
    verify_key "ANTHROPIC_API_KEY" "Anthropic Claude"
    verify_key "OPENAI_API_KEY" "OpenAI ChatGPT"
    verify_key "GOOGLE_API_KEY" "Google Gemini"
    verify_key "XAI_API_KEY" "xAI Grok"
    
    if gh auth status &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} GitHub: Authenticated ($(gh auth status 2>&1 | grep 'Logged in' | awk '{print $7}'))"
    else
        echo -e "  ${YELLOW}○${NC} GitHub: Not authenticated"
    fi
    
    # Final instructions
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Next Steps:${NC}\n"
    
    print_info "To activate the API keys in your current session:"
    echo -e "  ${CYAN}source ~/.config/orkestra/api-keys.env${NC}\n"
    
    print_info "To auto-load API keys on shell startup:"
    echo -e "  ${CYAN}echo 'source ~/.config/orkestra/api-keys.env' >> ~/.bashrc${NC}\n"
    
    print_info "To manually edit the config file:"
    echo -e "  ${CYAN}nano ~/.config/orkestra/api-keys.env${NC}\n"
    
    print_info "To verify API keys are working:"
    echo -e "  ${CYAN}./SCRIPTS/UTILS/test-apis.sh${NC}\n"
    
    print_success "API keys setup complete!"
    
    # Ask to load now
    read -p "Load API keys in this session now? (Y/n): " -n 1 -r load_now
    echo
    if [[ ! $load_now =~ ^[Nn]$ ]]; then
        source "$CONFIG_FILE"
        print_success "API keys loaded in current session"
    fi
    
    # Ask to add to bashrc
    if ! grep -q "source ~/.config/orkestra/api-keys.env" ~/.bashrc 2>/dev/null; then
        read -p "Add to ~/.bashrc for auto-loading? (Y/n): " -n 1 -r add_bashrc
        echo
        if [[ ! $add_bashrc =~ ^[Nn]$ ]]; then
            echo -e "\n# Orkestra API Keys" >> ~/.bashrc
            echo "source ~/.config/orkestra/api-keys.env" >> ~/.bashrc
            print_success "Added to ~/.bashrc"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# COMMAND LINE OPTIONS
# ═══════════════════════════════════════════════════════════════════════════

case "${1:-}" in
    --check|check)
        echo -e "${BOLD}API Keys Status:${NC}\n"
        verify_key "ANTHROPIC_API_KEY" "Anthropic Claude"
        verify_key "OPENAI_API_KEY" "OpenAI ChatGPT"
        verify_key "GOOGLE_API_KEY" "Google Gemini"
        verify_key "XAI_API_KEY" "xAI Grok"
        if gh auth status &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} GitHub: Authenticated"
        else
            echo -e "  ${YELLOW}○${NC} GitHub: Not authenticated"
        fi
        ;;
    --edit|edit)
        ${EDITOR:-nano} "$CONFIG_FILE"
        print_success "Config file edited"
        ;;
    --load|load)
        source "$CONFIG_FILE"
        print_success "API keys loaded in current session"
        ;;
    --help|help)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (none)     Interactive setup wizard"
        echo "  --check    Check API keys status"
        echo "  --edit     Edit config file"
        echo "  --load     Load API keys in current session"
        echo "  --help     Show this help message"
        ;;
    *)
        main
        ;;
esac
