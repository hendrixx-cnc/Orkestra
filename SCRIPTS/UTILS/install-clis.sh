#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA CLI INSTALLER
# ═══════════════════════════════════════════════════════════════════════════
# Installs CLI tools for AI agents integration
# - Anthropic Claude CLI
# - OpenAI ChatGPT CLI
# - Google Gemini CLI
# - xAI Grok CLI (if available)
# - GitHub CLI (for Copilot)
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/orkestra"

# Ensure directories exist
mkdir -p "$INSTALL_DIR" "$CONFIG_DIR"

# Add to PATH if not already there
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    export PATH="$INSTALL_DIR:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# ═══════════════════════════════════════════════════════════════════════════
# LOGGING FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}ℹ${NC}  $1"
}

log_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

log_error() {
    echo -e "${RED}✗${NC}  $1"
}

log_section() {
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE} $1${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ═══════════════════════════════════════════════════════════════════════════
# CHECK DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════

check_dependencies() {
    log_section "Checking System Dependencies"
    
    local missing=0
    
    # Check for required tools
    for tool in curl jq python3 pip3 node npm; do
        if command -v "$tool" &> /dev/null; then
            log_success "$tool is installed"
        else
            log_error "$tool is NOT installed"
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_error "$missing required tools missing"
        log_info "Install missing tools before continuing"
        return 1
    else
        log_success "All system dependencies satisfied"
        return 0
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# GITHUB CLI (for Copilot)
# ═══════════════════════════════════════════════════════════════════════════

install_github_cli() {
    log_section "Installing GitHub CLI"
    
    if command -v gh &> /dev/null; then
        local version=$(gh --version | head -n1)
        log_success "GitHub CLI already installed: $version"
        return 0
    fi
    
    log_info "Installing GitHub CLI..."
    
    # Detect OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu/Debian
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt-get update
            sudo apt-get install -y gh
        else
            log_warning "Unable to install GitHub CLI automatically on this system"
            log_info "Please install manually: https://github.com/cli/cli#installation"
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install gh
        else
            log_warning "Homebrew not found. Install from: https://github.com/cli/cli#installation"
            return 1
        fi
    fi
    
    if command -v gh &> /dev/null; then
        log_success "GitHub CLI installed successfully"
        log_info "Authenticate with: gh auth login"
        return 0
    else
        log_error "GitHub CLI installation failed"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# ANTHROPIC CLAUDE CLI
# ═══════════════════════════════════════════════════════════════════════════

install_claude_cli() {
    log_section "Installing Claude CLI"
    
    # Check if already installed
    if [ -f "$INSTALL_DIR/claude" ]; then
        log_success "Claude CLI already installed"
        return 0
    fi
    
    log_info "Installing Claude CLI via Python..."
    
    # Install anthropic Python package
    pip3 install --user anthropic
    
    # Create wrapper script
    cat > "$INSTALL_DIR/claude" << 'EOFCLAUDE'
#!/usr/bin/env python3
import os
import sys
from anthropic import Anthropic

def main():
    api_key = os.getenv('ANTHROPIC_API_KEY')
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)
    
    client = Anthropic(api_key=api_key)
    
    if len(sys.argv) < 2:
        print("Usage: claude <prompt>", file=sys.stderr)
        sys.exit(1)
    
    prompt = ' '.join(sys.argv[1:])
    
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    print(message.content[0].text)

if __name__ == '__main__':
    main()
EOFCLAUDE
    
    chmod +x "$INSTALL_DIR/claude"
    log_success "Claude CLI installed: $INSTALL_DIR/claude"
    log_info "Set ANTHROPIC_API_KEY environment variable to use"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# OPENAI CHATGPT CLI
# ═══════════════════════════════════════════════════════════════════════════

install_chatgpt_cli() {
    log_section "Installing ChatGPT CLI"
    
    # Check if already installed
    if [ -f "$INSTALL_DIR/chatgpt" ]; then
        log_success "ChatGPT CLI already installed"
        return 0
    fi
    
    log_info "Installing OpenAI CLI via Python..."
    
    # Install openai Python package
    pip3 install --user openai
    
    # Create wrapper script
    cat > "$INSTALL_DIR/chatgpt" << 'EOFCHATGPT'
#!/usr/bin/env python3
import os
import sys
from openai import OpenAI

def main():
    api_key = os.getenv('OPENAI_API_KEY')
    if not api_key:
        print("Error: OPENAI_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)
    
    client = OpenAI(api_key=api_key)
    
    if len(sys.argv) < 2:
        print("Usage: chatgpt <prompt>", file=sys.stderr)
        sys.exit(1)
    
    prompt = ' '.join(sys.argv[1:])
    
    response = client.chat.completions.create(
        model="gpt-4-turbo-preview",
        messages=[
            {"role": "user", "content": prompt}
        ]
    )
    
    print(response.choices[0].message.content)

if __name__ == '__main__':
    main()
EOFCHATGPT
    
    chmod +x "$INSTALL_DIR/chatgpt"
    log_success "ChatGPT CLI installed: $INSTALL_DIR/chatgpt"
    log_info "Set OPENAI_API_KEY environment variable to use"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# GOOGLE GEMINI CLI
# ═══════════════════════════════════════════════════════════════════════════

install_gemini_cli() {
    log_section "Installing Gemini CLI"
    
    # Check if already installed
    if [ -f "$INSTALL_DIR/gemini" ]; then
        log_success "Gemini CLI already installed"
        return 0
    fi
    
    log_info "Installing Gemini CLI via Python..."
    
    # Install google-generativeai Python package
    pip3 install --user google-generativeai
    
    # Create wrapper script
    cat > "$INSTALL_DIR/gemini" << 'EOFGEMINI'
#!/usr/bin/env python3
import os
import sys
import google.generativeai as genai

def main():
    api_key = os.getenv('GEMINI_API_KEY')
    if not api_key:
        print("Error: GEMINI_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)
    
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-pro')
    
    if len(sys.argv) < 2:
        print("Usage: gemini <prompt>", file=sys.stderr)
        sys.exit(1)
    
    prompt = ' '.join(sys.argv[1:])
    response = model.generate_content(prompt)
    
    print(response.text)

if __name__ == '__main__':
    main()
EOFGEMINI
    
    chmod +x "$INSTALL_DIR/gemini"
    log_success "Gemini CLI installed: $INSTALL_DIR/gemini"
    log_info "Set GEMINI_API_KEY environment variable to use"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# XAAI GROK CLI
# ═══════════════════════════════════════════════════════════════════════════

install_grok_cli() {
    log_section "Installing Grok CLI"
    
    # Check if already installed
    if [ -f "$INSTALL_DIR/grok" ]; then
        log_success "Grok CLI already installed"
        return 0
    fi
    
    log_info "Installing Grok CLI..."
    log_warning "Note: Grok API may not be publicly available yet"
    
    # Create placeholder wrapper script (will need updating when API is available)
    cat > "$INSTALL_DIR/grok" << 'EOFGROK'
#!/usr/bin/env python3
import os
import sys
import requests

def main():
    api_key = os.getenv('XAI_API_KEY')
    if not api_key:
        print("Error: XAI_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)
    
    if len(sys.argv) < 2:
        print("Usage: grok <prompt>", file=sys.stderr)
        sys.exit(1)
    
    prompt = ' '.join(sys.argv[1:])
    
    # Placeholder - update when xAI API is available
    print("Note: Grok API integration pending. Visit https://x.ai for updates")
    print(f"Prompt received: {prompt}")

if __name__ == '__main__':
    main()
EOFGROK
    
    chmod +x "$INSTALL_DIR/grok"
    log_success "Grok CLI installed (placeholder): $INSTALL_DIR/grok"
    log_info "Set XAI_API_KEY environment variable when available"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# API KEY CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

setup_api_keys() {
    log_section "API Key Configuration"
    
    local env_file="$CONFIG_DIR/api-keys.env"
    
    if [ -f "$env_file" ]; then
        log_info "API keys configuration exists: $env_file"
        log_info "Source with: source $env_file"
        return 0
    fi
    
    log_info "Creating API keys template..."
    
    cat > "$env_file" << 'EOFENV'
# Orkestra AI API Keys
# Source this file: source ~/.config/orkestra/api-keys.env

# Anthropic Claude
export ANTHROPIC_API_KEY="your-anthropic-api-key-here"

# OpenAI ChatGPT
export OPENAI_API_KEY="your-openai-api-key-here"

# Google Gemini
export GEMINI_API_KEY="your-gemini-api-key-here"

# xAI Grok (when available)
export XAI_API_KEY="your-xai-api-key-here"

# GitHub (for Copilot)
# Use: gh auth login
EOFENV
    
    chmod 600 "$env_file"
    log_success "API keys template created: $env_file"
    log_warning "Edit this file and add your actual API keys"
    log_info "Then add to ~/.bashrc: source $env_file"
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════

verify_installation() {
    log_section "Verifying Installation"
    
    local installed=0
    local total=5
    
    for cli in gh claude chatgpt gemini grok; do
        if command -v "$cli" &> /dev/null; then
            log_success "$cli: $(which $cli)"
            ((installed++))
        else
            log_warning "$cli: Not found in PATH"
        fi
    done
    
    echo ""
    log_info "Installed: $installed/$total CLIs"
    
    if [ $installed -eq $total ]; then
        log_success "All CLIs installed successfully!"
    elif [ $installed -gt 0 ]; then
        log_warning "Some CLIs installed. Check errors above."
    else
        log_error "No CLIs installed. Check errors above."
        return 1
    fi
    
    return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN INSTALLATION
# ═══════════════════════════════════════════════════════════════════════════

main() {
    clear
    echo ""
    echo -e "${BOLD}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}║                ${CYAN}🛠  ORKESTRA CLI INSTALLER${NC}${BOLD}                 ║${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}║          ${BLUE}Installing AI Agent Command-Line Tools${NC}${BOLD}             ║${NC}"
    echo -e "${BOLD}║                                                                ║${NC}"
    echo -e "${BOLD}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Config directory: $CONFIG_DIR"
    echo ""
    
    # Check dependencies
    if ! check_dependencies; then
        log_error "Missing required dependencies. Install them first."
        exit 1
    fi
    
    # Install CLIs
    install_github_cli || true
    install_claude_cli || true
    install_chatgpt_cli || true
    install_gemini_cli || true
    install_grok_cli || true
    
    # Setup API keys
    setup_api_keys
    
    # Verify
    verify_installation
    
    # Final instructions
    log_section "Next Steps"
    echo ""
    log_info "1. Add API keys to: $CONFIG_DIR/api-keys.env"
    log_info "2. Source API keys: source $CONFIG_DIR/api-keys.env"
    log_info "3. Add to ~/.bashrc: source $CONFIG_DIR/api-keys.env"
    log_info "4. Authenticate GitHub: gh auth login"
    log_info "5. Test CLIs:"
    echo "     claude 'Hello, Claude!'"
    echo "     chatgpt 'Hello, GPT!'"
    echo "     gemini 'Hello, Gemini!'"
    echo "     gh --version"
    echo ""
    log_section "Installation Complete"
    echo ""
}

# Run installation
main "$@"
