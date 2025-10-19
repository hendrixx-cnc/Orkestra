#!/bin/bash
# CONSISTENCY CHECKING SCRIPT FOR IDLE TASKS

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TASK_QUEUE="$SCRIPT_DIR/TASK_QUEUE.json"

echo "🔍 Consistency Checking Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check task status consistency
echo "📊 Task Status Distribution:"
jq -r '[.queue[] | .status] | group_by(.) | map({status: .[0], count: length}) | .[] | "  \(.status): \(.count)"' "$TASK_QUEUE"

echo ""
echo "👥 AI Workload Balance:"
jq -r '[.queue[] | select(.status == "pending" or .status == "waiting")] | group_by(.assigned_to) | map({ai: .[0].assigned_to, pending: length}) | .[] | "  \(.ai): \(.pending) pending"' "$TASK_QUEUE"

# Check for dependency consistency
echo ""
echo "🔗 Dependency Check:"
dep_issues=$(jq -r '
  .queue[] | 
  select(.dependencies != null and .dependencies != []) |
  select(.status == "in_progress" or .status == "completed") |
  .dependencies[] as $dep |
  select(any(.queue[]; .id == $dep and .status != "completed")) |
  "  ⚠️  Task #\(.id) has incomplete dependency: \($dep)"
' "$TASK_QUEUE")

if [ -z "$dep_issues" ]; then
    echo "  ✓ All dependencies consistent"
else
    echo "$dep_issues"
fi

# Check for duplicate IDs
echo ""
echo "🔢 ID Uniqueness Check:"
dup_ids=$(jq -r '.queue[] | .id' "$TASK_QUEUE" | sort | uniq -d)
if [ -z "$dup_ids" ]; then
    echo "  ✓ All task IDs unique"
else
    echo "  ❌ Duplicate task IDs found: $dup_ids"
fi

# Check assignment consistency
echo ""
echo "👤 Assignment Check:"
invalid_assignments=$(jq -r '
  .queue[] |
  select(.assigned_to != null) |
  select([.assigned_to] | inside(["claude", "chatgpt", "gemini", "grok", "copilot", "Any AI"]) | not) |
  "  ⚠️  Task #\(.id) has invalid assignment: \(.assigned_to)"
' "$TASK_QUEUE")

if [ -z "$invalid_assignments" ]; then
    echo "  ✓ All assignments valid"
else
    echo "$invalid_assignments"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Consistency check complete"
