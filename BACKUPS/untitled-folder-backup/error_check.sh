#!/bin/bash
# ERROR CHECKING SCRIPT FOR IDLE TASKS

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR/.."

echo "🔍 Error Checking Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for common errors in recent files
echo "📝 Checking recent file modifications..."

# Check markdown files
find "$PROJECT_ROOT" -name "*.md" -mtime -1 -type f | while read file; do
    # Check for broken links
    broken_links=$(grep -oP '\[.*?\]\(.*?\)' "$file" | grep -v "^http" | wc -l)
    if [ $broken_links -gt 0 ]; then
        echo "  ⚠️  $file: $broken_links potential broken links"
    fi
done

# Check JSON files for syntax
echo ""
echo "📦 Checking JSON files..."
find "$PROJECT_ROOT" -name "*.json" -type f | while read file; do
    if ! jq empty "$file" 2>/dev/null; then
        echo "  ❌ $file: Invalid JSON"
    fi
done

# Check for stale locks
echo ""
echo "🔒 Checking for stale locks..."
if [ -f "$SCRIPT_DIR/locks" ]; then
    lock_count=$(find "$SCRIPT_DIR/locks" -name "*.lock" 2>/dev/null | wc -l)
    if [ $lock_count -gt 0 ]; then
        echo "  ⚠️  Found $lock_count active locks"
        bash "$SCRIPT_DIR/task_lock.sh" list
    else
        echo "  ✓ No stale locks"
    fi
else
    echo "  ✓ No locks directory (clean)"
fi

# Check task queue consistency
echo ""
echo "📋 Checking task queue consistency..."
in_progress=$(jq '[.queue[] | select(.status == "in_progress")] | length' "$SCRIPT_DIR/TASK_QUEUE.json")
if [ $in_progress -gt 5 ]; then
    echo "  ⚠️  Warning: $in_progress tasks in progress (unusually high)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Error check complete"
