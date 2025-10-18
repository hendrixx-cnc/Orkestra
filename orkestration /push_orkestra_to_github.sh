#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# ORKESTRA GITHUB PUSH HELPER
# ═══════════════════════════════════════════════════════════════════════════════

set -e

REPO_DIR="/tmp/orkestra_migration/Orkestra"

echo "🎼 OrKeStra GitHub Push Helper"
echo "══════════════════════════════════════════════════════════════"
echo ""

if [ ! -d "$REPO_DIR" ]; then
    echo "❌ Error: Orkestra repository not found at $REPO_DIR"
    exit 1
fi

cd "$REPO_DIR"

echo "📍 Current location: $REPO_DIR"
echo ""

# Check if gh CLI is available
if command -v gh &> /dev/null; then
    echo "✅ GitHub CLI (gh) is available"
    echo ""
    echo "Choose authentication method:"
    echo ""
    echo "1. GitHub CLI (Recommended)"
    echo "2. SSH"
    echo "3. Personal Access Token"
    echo "4. Create Archive for Manual Upload"
    echo ""
    read -p "Select option (1-4): " option
    
    case $option in
        1)
            echo ""
            echo "🔐 Authenticating with GitHub CLI..."
            gh auth login
            echo ""
            echo "📤 Pushing to GitHub..."
            git push -u origin main
            echo ""
            echo "✅ Push complete!"
            echo ""
            echo "🎯 Setting repository details..."
            gh repo edit --description "🎼 OrKeStra - Multi-AI Orchestration System for coordinating Claude, ChatGPT, Gemini, Grok, and GitHub Copilot"
            gh repo edit --add-topic ai
            gh repo edit --add-topic orchestration
            gh repo edit --add-topic automation
            gh repo edit --add-topic devops
            gh repo edit --add-topic multi-agent
            gh repo edit --add-topic coordination
            echo ""
            echo "✅ Repository setup complete!"
            echo ""
            echo "🌐 View your repository:"
            gh repo view --web
            ;;
        2)
            echo ""
            echo "🔑 Configuring SSH remote..."
            git remote set-url origin git@github.com:hendrixx-cnc/Orkestra.git
            echo ""
            echo "📤 Pushing to GitHub..."
            git push -u origin main
            echo ""
            echo "✅ Push complete!"
            ;;
        3)
            echo ""
            read -p "Enter your GitHub Personal Access Token: " token
            git remote set-url origin "https://${token}@github.com/hendrixx-cnc/Orkestra.git"
            echo ""
            echo "📤 Pushing to GitHub..."
            git push -u origin main
            echo ""
            echo "✅ Push complete!"
            ;;
        4)
            echo ""
            echo "📦 Creating archive for manual upload..."
            cd /tmp/orkestra_migration
            tar -czf orkestra-migrated-$(date +%Y%m%d-%H%M%S).tar.gz Orkestra/
            echo ""
            echo "✅ Archive created: /tmp/orkestra_migration/orkestra-migrated-*.tar.gz"
            echo ""
            echo "To upload manually:"
            echo "1. Download the archive file"
            echo "2. Extract it on your local machine"
            echo "3. Push from there using git push"
            ;;
        *)
            echo "Invalid option"
            exit 1
            ;;
    esac
else
    echo "⚠️  GitHub CLI not found"
    echo ""
    echo "Available options:"
    echo ""
    echo "1. Install GitHub CLI:"
    echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
    echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
    echo "   sudo apt update"
    echo "   sudo apt install gh"
    echo ""
    echo "2. Use SSH (if configured):"
    echo "   git remote set-url origin git@github.com:hendrixx-cnc/Orkestra.git"
    echo "   git push -u origin main"
    echo ""
    echo "3. Use Personal Access Token:"
    echo "   git remote set-url origin https://YOUR_TOKEN@github.com/hendrixx-cnc/Orkestra.git"
    echo "   git push -u origin main"
    echo ""
    echo "4. Create archive for manual upload:"
    echo "   cd /tmp/orkestra_migration"
    echo "   tar -czf orkestra-migrated.tar.gz Orkestra/"
fi

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "📚 For more details, see: ORKESTRA_MIGRATION_COMPLETE.md"
echo "══════════════════════════════════════════════════════════════"
