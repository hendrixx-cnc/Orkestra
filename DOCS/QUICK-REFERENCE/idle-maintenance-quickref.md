# 🏥 Idle Maintenance Quick Reference

## 🚀 Quick Start

```bash
# Start all idle monitors
./SCRIPTS/AUTOMATION/start-idle-monitors.sh start

# Check status
./SCRIPTS/AUTOMATION/start-idle-monitors.sh status

# Stop all monitors
./SCRIPTS/AUTOMATION/start-idle-monitors.sh stop
```

## 📊 What It Does

When agents are **idle for 2+ seconds**, they automatically run:

✅ **Health Checks** - API keys, connectivity  
✅ **Dependencies** - Tools, files, JSON integrity  
✅ **Error Detection** - Stale locks, orphaned tasks  
✅ **Consistency** - System-wide validation  
✅ **Self-Healing** - Auto-repair detected issues  

## 🔍 Monitoring

```bash
# Watch all maintenance activity
tail -f LOGS/agent-maintenance.log

# Watch specific agent
tail -f LOGS/idle-monitor-claude.log

# Check which agents are being monitored
./SCRIPTS/AUTOMATION/start-idle-monitors.sh status
```

## 🎯 Status Indicators

- **● GREEN** - Monitor running, agent healthy
- **○ YELLOW** - Monitor stopped
- **✓ PASS** - Check passed
- **⚠ WARNING** - Non-critical issue
- **✗ FAIL** - Critical issue (auto-repair attempted)

## 🔧 Common Commands

```bash
# Restart all monitors
./SCRIPTS/AUTOMATION/start-idle-monitors.sh restart

# Start specific agent monitor
./SCRIPTS/AUTOMATION/idle-agent-maintenance.sh claude &

# Manual safety checks
./SCRIPTS/SAFETY/consistency-checker.sh

# Pre-task validation
./SCRIPTS/SAFETY/pre-task-validator.sh <task_id> <ai_name>

# Post-task validation
./SCRIPTS/SAFETY/post-task-validator.sh <task_id> <ai_name>
```

## 📁 Key Files

| File | Purpose |
|------|---------|
| `idle-monitor-<agent>.log` | Agent-specific monitoring |
| `agent-maintenance.log` | General maintenance events |
| `self-healing.log` | Auto-repair operations |
| `CONFIG/RUNTIME/idle-monitors/*.pid` | Monitor process IDs |

## 🚨 Troubleshooting

**Monitor won't start:**
```bash
# Remove stale PIDs
rm -f CONFIG/RUNTIME/idle-monitors/*.pid

# Check script is executable
chmod +x SCRIPTS/AUTOMATION/*.sh

# Restart
./SCRIPTS/AUTOMATION/start-idle-monitors.sh restart
```

**Too many maintenance cycles:**
```bash
# Increase idle threshold (default 2s)
# Edit SCRIPTS/AUTOMATION/idle-agent-maintenance.sh
IDLE_THRESHOLD=5  # Set to 5 seconds
```

**Check logs for errors:**
```bash
grep -i "error\|fail" LOGS/idle-monitor-*.log
grep -i "error\|fail" LOGS/agent-maintenance.log
```

## 🎛️ Configuration

**Idle Threshold:** 2 seconds (configurable)  
**Maintenance Interval:** 30 seconds between cycles  
**Stale Lock Threshold:** 1 hour  
**Retry Limit:** 3 attempts per task  

## 📚 More Info

- Full documentation: `DOCS/TECHNICAL/self-healing-system.md`
- Safety system: `DOCS/TECHNICAL/safety-system.md`
- Agent health: `DOCS/TECHNICAL/agent-health.md`
