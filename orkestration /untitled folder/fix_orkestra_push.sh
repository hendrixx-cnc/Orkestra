#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# ORKESTRA PUSH - AUTHENTICATION FIX
# ═══════════════════════════════════════════════════════════════════════════════

set -e

REPO_DIR="/tmp/orkestra_migration/Orkestra"

echo ""
echo "🎼 OrKeStra - GitHub Push Authentication Fix"
echo "══════════════════════════════════════════════════════════════"
echo ""

cd "$REPO_DIR"

echo "The 403 error means GitHub authentication failed."
echo ""
echo "Choose your solution:"
echo ""
echo "1. Use GitHub CLI (gh) authentication"
echo "2. Use SSH instead of HTTPS"
echo "3. Create a bundle file for manual upload"
echo "4. Show me the commands to run elsewhere"
echo ""
read -p "Select option (1-4): " option

case $option in
    1)
        echo ""
        echo "🔐 Checking GitHub CLI authentication..."
        if ! gh auth status &>/dev/null; then
            echo "Not authenticated. Starting authentication..."
            echo ""
            echo "Please follow the prompts to authenticate with GitHub."
            echo "You'll need to:"
            echo "  1. Choose GitHub.com"
            echo "  2. Choose HTTPS"
            echo "  3. Authenticate with your browser or token"
            echo ""
            gh auth login
        else
            echo "✅ Already authenticated with GitHub CLI"
        fi
        
        echo ""
        echo "📤 Pushing to GitHub..."
        if git push -u origin main; then
            echo ""
            echo "✅ SUCCESS! Repository pushed to GitHub!"
            echo ""
            echo "🌐 View your repository:"
            echo "   https://github.com/hendrixx-cnc/Orkestra"
            echo ""
            
            # Set repository details
            echo "🎯 Setting repository details..."
            gh repo edit --description "🎼 OrKeStra - Multi-AI Orchestration System for coordinating Claude, ChatGPT, Gemini, Grok, and GitHub Copilot" || true
            gh repo edit --add-topic ai || true
            gh repo edit --add-topic orchestration || true
            gh repo edit --add-topic automation || true
            gh repo edit --add-topic devops || true
            gh repo edit --add-topic multi-agent || true
            
            echo ""
            echo "✅ All done!"
        else
            echo ""
            echo "❌ Push failed. Try option 2 or 3."
        fi
        ;;
        
    2)
        echo ""
        echo "🔑 Switching to SSH authentication..."
        echo ""
        echo "This requires SSH keys to be set up with GitHub."
        echo "See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
        echo ""
        read -p "Do you have SSH keys configured? (y/n): " has_ssh
        
        if [ "$has_ssh" = "y" ]; then
            echo ""
            echo "Changing remote to SSH..."
            git remote set-url origin git@github.com:hendrixx-cnc/Orkestra.git
            echo ""
            echo "📤 Pushing to GitHub via SSH..."
            if git push -u origin main; then
                echo ""
                echo "✅ SUCCESS! Repository pushed to GitHub!"
                echo ""
                echo "🌐 View your repository:"
                echo "   https://github.com/hendrixx-cnc/Orkestra"
            else
                echo ""
                echo "❌ Push failed. Your SSH keys may not be configured."
                echo "Reverting to HTTPS..."
                git remote set-url origin https://github.com/hendrixx-cnc/Orkestra.git
            fi
        else
            echo ""
            echo "Please set up SSH keys first:"
            echo "  https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
        fi
        ;;
        
    3)
        echo ""
        echo "📦 Creating git bundle for manual upload..."
        BUNDLE_FILE="/tmp/orkestra-$(date +%Y%m%d-%H%M%S).bundle"
        git bundle create "$BUNDLE_FILE" --all
        
        echo ""
        echo "✅ Bundle created: $BUNDLE_FILE"
        echo ""
        echo "To upload manually:"
        echo ""
        echo "  1. Download this file from your codespace:"
        echo "     $BUNDLE_FILE"
        echo ""
        echo "  2. On your local machine, clone the empty repo:"
        echo "     git clone https://github.com/hendrixx-cnc/Orkestra.git"
        echo ""
        echo "  3. Extract the bundle:"
        echo "     cd Orkestra"
        echo "     git pull /path/to/$(basename $BUNDLE_FILE)"
        echo ""
        echo "  4. Push to GitHub:"
        echo "     git push origin main"
        echo ""
        
        # Also create a tar.gz
        TAR_FILE="/tmp/orkestra-files-$(date +%Y%m%d-%H%M%S).tar.gz"
        cd /tmp/orkestra_migration
        tar -czf "$TAR_FILE" Orkestra/
        
        echo "  OR download the full directory:"
        echo "     $TAR_FILE"
        echo ""
        echo "  Then extract and push from your local machine."
        ;;
        
    4)
        echo ""
        echo "📋 Commands to run on your LOCAL machine:"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "# 1. Download the bundle file from codespace"
        echo "#    (Use VS Code download or scp)"
        echo ""
        echo "# 2. Clone the empty repository"
        echo "git clone https://github.com/hendrixx-cnc/Orkestra.git"
        echo "cd Orkestra"
        echo ""
        echo "# 3. If using bundle file:"
        echo "git bundle unbundle /path/to/orkestra-*.bundle"
        echo "git checkout main"
        echo ""
        echo "# OR if downloaded the tar.gz:"
        echo "# Extract it and cd into Orkestra directory, then:"
        echo "git remote add origin https://github.com/hendrixx-cnc/Orkestra.git"
        echo ""
        echo "# 4. Push to GitHub"
        echo "git push -u origin main"
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "The files are ready at: $REPO_DIR"
        ;;
        
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "══════════════════════════════════════════════════════════════"
