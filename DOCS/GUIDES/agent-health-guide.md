# Agent Health Monitor Guide

## Overview

The Agent Health Monitor provides real-time monitoring and diagnostics for all AI agents in the Orkestra system.

## Quick Start

```bash
# Interactive menu
orkestra health

# Quick summary
orkestra health --summary

# Detailed check
orkestra health --detailed
```

## Features

### 1. Quick Status Overview
Shows at-a-glance status of all agents:
- Configuration status
- Current workload (active tasks)
- Completed tasks count

### 2. Detailed Health Check
Performs actual API tests to verify:
- API key validity
- Network connectivity
- Rate limit status
- Authentication status

### 3. Test Specific Agent
Deep dive into individual agents:
```bash
orkestra health --test claude
orkestra health --test chatgpt
orkestra health --test gemini
orkestra health --test grok
orkestra health --test copilot
```

### 4. Workload Distribution
See how tasks are distributed across agents:
- Pending tasks
- In-progress tasks per agent
- Completed tasks per agent
- Total task counts

### 5. Auto-refresh Monitor
Real-time monitoring dashboard:
```bash
orkestra health --monitor
```
Updates every 5 seconds. Press Ctrl+C to stop.

## Interactive Menu

When you run `orkestra health`, you get an interactive menu:

```
╔══════════════════════════════════════════════════════════════════╗
║  🏥 ORKESTRA AGENT HEALTH MONITOR                          ║
╚══════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Main Menu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1) Quick Status Overview
  2) Detailed Health Check (with API tests)
  3) Test Specific Agent
  4) Configure API Keys
  5) View Workload Distribution
  6) Auto-refresh Monitor
  q) Quit
```

### Menu Options Explained

**Option 1: Quick Status Overview**
- Fast check of all agents
- Shows configuration status
- Displays current workload
- No API calls made (instant)

**Option 2: Detailed Health Check**
- Tests actual API connectivity
- Validates API keys
- Checks for rate limits
- Shows response times
- Takes 10-30 seconds

**Option 3: Test Specific Agent**
- Choose one agent to test
- Detailed diagnostics
- Connection testing
- Error details if any

**Option 4: Configure API Keys**
- Quick access to setup script
- Edit keys without leaving menu
- Reload configuration

**Option 5: View Workload Distribution**
- See task allocation
- Compare agent usage
- Identify bottlenecks

**Option 6: Auto-refresh Monitor**
- Live dashboard
- Updates every 5 seconds
- Shows real-time changes
- Press Ctrl+C to exit

## Status Indicators

### Configuration Status
- ✓ **Configured** - API key is set
- ○ **Not Configured** - No API key found

### Connection Status
- ✓ **Online** - API is accessible and responding
- ⚠ **Rate Limited** - API quota exceeded
- ✗ **Auth Failed** - Invalid API key
- ✗ **Error** - Connection or other error
- ? **Unknown** - Status not yet checked

### Workload Status
- **X active** - Currently processing X tasks
- **Y completed** - Completed Y tasks total

## Use Cases

### Daily Standup
Check all agents before starting work:
```bash
orkestra health --summary
```

### Troubleshooting
When tasks aren't completing:
```bash
orkestra health --detailed
```

### Performance Monitoring
Track workload distribution:
```bash
orkestra health --workload
```

### Real-time Monitoring
During heavy workload:
```bash
orkestra health --monitor
```

### Individual Agent Issues
When one agent has problems:
```bash
orkestra health --test claude
```

## Command Reference

### Interactive Mode
```bash
orkestra health
# Opens menu-driven interface
```

### Summary Mode
```bash
orkestra health --summary
# Quick status, no API tests
```

### Detailed Mode
```bash
orkestra health --detailed
# Full health check with API tests
```

### Test Specific Agent
```bash
orkestra health --test <agent>
# Agents: claude, chatgpt, gemini, grok, copilot
```

### Workload View
```bash
orkestra health --workload
# Show task distribution
```

### Monitor Mode
```bash
orkestra health --monitor
# Auto-refresh every 5 seconds
```

## Integration

### In Scripts
```bash
#!/bin/bash

# Check if all agents are healthy
if orkestra health --summary | grep -q "✓ Configured"; then
    echo "Agents ready"
else
    echo "Some agents not configured"
    orkestra health --detailed
fi
```

### With Start Script
```bash
# Check health before starting
orkestra health --summary
orkestra start
```

### In Automation
```bash
# Monitor during long-running tasks
orkestra health --monitor &
MONITOR_PID=$!

# Run your tasks
orkestra start

# Stop monitoring
kill $MONITOR_PID
```

## Troubleshooting

### "Unconfigured" Status
**Problem**: Agent shows as unconfigured  
**Solution**:
```bash
orkestra health  # Choose option 4
# Or directly:
./SCRIPTS/UTILS/setup-apis.sh
```

### "Auth Failed" Status
**Problem**: API key is invalid  
**Solution**:
1. Verify key at provider's website
2. Update key: `nano ~/.config/orkestra/api-keys.env`
3. Reload: `source ~/.config/orkestra/api-keys.env`
4. Test: `orkestra health --test <agent>`

### "Rate Limited" Status
**Problem**: Too many API requests  
**Solution**:
- Wait for rate limit to reset (usually 1 minute)
- Reduce concurrency in automation config
- Upgrade API plan if needed

### "Error" Status
**Problem**: Connection or other error  
**Solution**:
1. Check internet connectivity
2. Verify API endpoint is up
3. Check for service outages
4. Review detailed logs

### No Workload Showing
**Problem**: All agents show 0 tasks  
**Solution**:
- Check if Orkestra is running: `ps aux | grep orchestrator`
- Verify task queue: `cat CONFIG/TASK-QUEUES/task-queue.json`
- Start Orkestra: `orkestra start`

## Advanced Usage

### Custom Monitoring Interval
Edit the script to change refresh rate:
```bash
nano SCRIPTS/MONITORING/agent-health.sh
# Change: refresh_interval=5
```

### Export Status to File
```bash
orkestra health --summary > agent-status.txt
orkestra health --detailed > agent-detailed.txt
```

### Continuous Monitoring with Logging
```bash
while true; do
    date >> agent-health.log
    orkestra health --summary >> agent-health.log
    sleep 300  # Every 5 minutes
done
```

### Alert on Agent Down
```bash
#!/bin/bash
if orkestra health --summary | grep -q "✗"; then
    echo "ALERT: Agent health issue detected!"
    orkestra health --detailed
    # Send notification here
fi
```

## Tips

1. **Run health check after configuration**
   ```bash
   ./SCRIPTS/UTILS/setup-apis.sh
   orkestra health --detailed
   ```

2. **Check health before big tasks**
   ```bash
   orkestra health --summary && orkestra start
   ```

3. **Use monitor mode during development**
   ```bash
   orkestra health --monitor
   ```

4. **Test one agent after updating its key**
   ```bash
   orkestra health --test claude
   ```

5. **Check workload for load balancing**
   ```bash
   orkestra health --workload
   ```

## Related Commands

- `orkestra start --check` - System health check (includes agents)
- `./SCRIPTS/UTILS/setup-apis.sh` - Configure API keys
- `./SCRIPTS/UTILS/setup-apis.sh --check` - Quick API status
- `cat CONFIG/TASK-QUEUES/task-queue.json` - View task queue

## Files

- **Script**: `/workspaces/Orkestra/SCRIPTS/MONITORING/agent-health.sh`
- **API Keys**: `~/.config/orkestra/api-keys.env`
- **Task Queue**: `/workspaces/Orkestra/CONFIG/TASK-QUEUES/task-queue.json`

## Support

For issues with the health monitor:
1. Check the script has execute permissions
2. Verify jq is installed: `which jq`
3. Test manually: `./SCRIPTS/MONITORING/agent-health.sh --help`
4. Check API keys are loaded: `echo $ANTHROPIC_API_KEY`
