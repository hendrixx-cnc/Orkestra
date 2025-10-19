#!/bin/bash
# Competition Progress Monitor
# Watches for AI algorithm submissions

COMPETITION_DIR="/workspaces/The-Quantum-Self-/AI/hacs_algorithm_competition"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 HACS ALGORITHM COMPETITION - PROGRESS MONITOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checking for algorithm submissions..."
echo ""

# Count submissions
total_expected=4
submitted=0

# Check each AI's submission
check_submission() {
    local ai=$1
    local file="$COMPETITION_DIR/algorithm_${ai}.md"
    
    if [ -f "$file" ]; then
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        local timestamp=$(stat -f%Sm -t "%Y-%m-%d %H:%M" "$file" 2>/dev/null || stat -c%y "$file" 2>/dev/null | cut -d'.' -f1)
        echo "   ✅ $ai - SUBMITTED ($size bytes, $timestamp)"
        ((submitted++))
    else
        echo "   ⏳ $ai - PENDING"
    fi
}

check_submission "claude"
check_submission "chatgpt"
check_submission "gemini"
check_submission "grok"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📈 PROGRESS: $submitted / $total_expected algorithms submitted"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $submitted -eq $total_expected ]; then
    echo "🎉 ALL ALGORITHMS SUBMITTED!"
    echo ""
    echo "Next step: Run evaluation"
    echo "   cd /workspaces/The-Quantum-Self-/AI/hacs_algorithm_competition"
    echo "   python3 evaluate_algorithms.py"
    echo ""
else
    remaining=$((total_expected - submitted))
    echo "⏰ Waiting for $remaining more submission(s)..."
    echo ""
    echo "Monitor in real-time:"
    echo "   watch -n 5 '$0'"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
