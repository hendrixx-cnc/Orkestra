#!/bin/bash

# AI Automation Menu
# Quick access to all coordination commands

clear
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         🤖 AI AUTOMATION CONTROL PANEL 🤖                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Choose an option:"
echo ""
echo "  1) 🎯 AI Coordinator - Who should I ping next?"
echo "  2) 📊 AI Status Dashboard - Full progress view"
echo "  3) 📝 View Current Task"
echo "  4) 📋 View Task Queue (all tasks)"
echo "  5) ✅ Mark Current Task Complete"
echo "  6) 🚀 Build Website (test production)"
echo "  7) 💾 Update 444 Status Log"
echo "  8) 📖 Open Quick Reference Guide"
echo "  9) 🔍 Check for Errors"
echo "  0) Exit"
echo ""
echo -n "Enter choice [0-9]: "
read choice

case $choice in
  1)
    clear
    /workspaces/The-Quantum-Self-/ai_coordinator.sh
    ;;
  2)
    clear
    /workspaces/The-Quantum-Self-/ai_status_check.sh
    ;;
  3)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "📝 CURRENT TASK"
    echo "════════════════════════════════════════════════════════════"
    cat /workspaces/The-Quantum-Self-/CURRENT_TASK.md
    ;;
  4)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "📋 TASK QUEUE"
    echo "════════════════════════════════════════════════════════════"
    if command -v jq &> /dev/null; then
      cat /workspaces/The-Quantum-Self-/TASK_QUEUE.json | jq -r '.queue[] | "\nTask #\(.id): \(.title)\nStatus: \(.status) | Priority: \(.priority) | Assigned: \(.assigned_to)\n"'
    else
      cat /workspaces/The-Quantum-Self-/TASK_QUEUE.json
    fi
    ;;
  5)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "✅ MARK TASK COMPLETE"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Current task status:"
    grep "Status:" /workspaces/The-Quantum-Self-/CURRENT_TASK.md | head -1
    echo ""
    echo "Mark as complete? (y/n): "
    read confirm
    if [ "$confirm" = "y" ]; then
      echo "✅ Task marked complete! Update CURRENT_TASK.md manually or run coordinator."
    fi
    ;;
  6)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "🚀 BUILDING WEBSITE..."
    echo "════════════════════════════════════════════════════════════"
    cd /workspaces/The-Quantum-Self-/2_The-Quantum-World && npm run build
    ;;
  7)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "💾 UPDATE 444 STATUS LOG"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "Enter one-line update: "
    read update
    if [ ! -z "$update" ]; then
      echo "" >> /workspaces/The-Quantum-Self-/444_STATUS_UPDATES.txt
      echo "**$(date '+%b %d, %Y'):** $update" >> /workspaces/The-Quantum-Self-/444_STATUS_UPDATES.txt
      echo "✅ Updated 444_STATUS_UPDATES.txt"
      tail -5 /workspaces/The-Quantum-Self-/444_STATUS_UPDATES.txt
    fi
    ;;
  8)
    clear
    cat /workspaces/The-Quantum-Self-/AI_QUICK_ACCESS.md
    ;;
  9)
    clear
    echo "════════════════════════════════════════════════════════════"
    echo "🔍 CHECKING FOR ERRORS..."
    echo "════════════════════════════════════════════════════════════"
    cd /workspaces/The-Quantum-Self-/2_The-Quantum-World
    echo ""
    echo "Frontend build test:"
    npm run build 2>&1 | tail -10
    echo ""
    echo "Backend status:"
    cd backend
    if [ -f "src/server.js" ]; then
      echo "✅ Backend files present"
    fi
    ;;
  0)
    clear
    echo "Goodbye! 👋"
    exit 0
    ;;
  *)
    clear
    echo "❌ Invalid choice. Try again."
    sleep 1
    /workspaces/The-Quantum-Self-/ai_menu.sh
    ;;
esac

echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Press Enter to return to menu..."
read
/workspaces/The-Quantum-Self-/ai_menu.sh
