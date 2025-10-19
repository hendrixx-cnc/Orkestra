#!/bin/bash
# Quick demo of the agent health menu features

echo "=== ORKESTRA AGENT HEALTH DEMO ==="
echo ""

echo "1. Quick Summary:"
echo "   orkestra health --summary"
echo ""
./SCRIPTS/MONITORING/agent-health.sh --summary
echo ""
echo "Press Enter to continue..."
read

echo ""
echo "2. Workload Distribution:"
echo "   orkestra health --workload"
echo ""
./SCRIPTS/MONITORING/agent-health.sh --workload
echo ""
echo "Press Enter to continue..."
read

echo ""
echo "3. Test Specific Agent:"
echo "   orkestra health --test claude"
echo ""
./SCRIPTS/MONITORING/agent-health.sh --test claude
echo ""
echo "Press Enter to see all options..."
read

echo ""
echo "4. All Available Commands:"
echo "   orkestra health              # Interactive menu"
echo "   orkestra health --summary    # Quick status"
echo "   orkestra health --detailed   # Full API tests"
echo "   orkestra health --test <agent>  # Test one agent"
echo "   orkestra health --workload   # Show task distribution"
echo "   orkestra health --monitor    # Auto-refresh dashboard"
echo ""
echo "Demo complete!"
