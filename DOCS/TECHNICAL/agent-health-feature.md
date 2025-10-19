# 🏥 Agent Health Menu - Feature Summary

## What Was Added

A comprehensive AI agent health monitoring system for Orkestra.

## New Files Created

1. **`SCRIPTS/MONITORING/agent-health.sh`** (18KB)
   - Main health monitoring script
   - Interactive menu system
   - API connectivity testing
   - Workload tracking

2. **`DOCS/GUIDES/agent-health-guide.md`** (6KB)
   - Complete user guide
   - Troubleshooting tips
   - Use case examples

3. **`SCRIPTS/UTILS/demo-agent-health.sh`**
   - Interactive demo script

## Files Updated

1. **`orkestra`** - Added `health` command
2. **`DOCS/GUIDES/orkestra-quick-reference.md`** - Added health monitoring section

---

## 🎯 Features

### 1. Quick Status Overview
```bash
orkestra health --summary
```
- Shows all 5 AI agents at a glance
- Configuration status (✓ Configured / ○ Not Setup)
- Current workload (X active tasks)
- Completed tasks count
- **Fast**: No API calls, instant results

### 2. Detailed Health Check
```bash
orkestra health --detailed
```
- Tests actual API connectivity
- Validates API keys
- Checks for rate limits
- Shows authentication status
- Displays agent workload and completion stats
- **Thorough**: Makes real API calls (10-30 seconds)

### 3. Test Specific Agent
```bash
orkestra health --test claude
orkestra health --test chatgpt
orkestra health --test gemini
orkestra health --test grok
orkestra health --test copilot
```
- Deep dive into one agent
- Detailed diagnostics
- Connection testing
- Error details

### 4. Workload Distribution
```bash
orkestra health --workload
```
- Total tasks (pending/in-progress/completed)
- Per-agent breakdown
- Task allocation visibility
- Load balancing insights

### 5. Auto-Refresh Monitor
```bash
orkestra health --monitor
```
- Real-time dashboard
- Updates every 5 seconds
- Live workload tracking
- Press Ctrl+C to stop

### 6. Interactive Menu
```bash
orkestra health
```
Opens a full-featured menu with:
- All viewing options
- Quick access to API setup
- Specific agent testing
- Easy navigation

---

## 📊 What It Shows

### For Each Agent:

**🤖 Claude (Anthropic)**
- Configuration: API key status
- Status: Online/Rate Limited/Auth Failed/Error
- API Key: First 20 characters (masked)
- Workload: Active tasks count
- Completed: Total completed tasks

**💬 ChatGPT (OpenAI)**
- Same metrics as Claude

**✨ Gemini (Google)**
- Same metrics as Claude

**🚀 Grok (xAI)**
- Same metrics as Claude

**🐙 GitHub Copilot**
- Authentication status via GitHub CLI
- Logged-in user
- Workload and completed tasks

---

## 🎨 Visual Output Examples

### Summary View:
```
╔══════════════════════════════════════════════════════════════════╗
║  🏥 ORKESTRA AGENT HEALTH MONITOR                          ║
╚══════════════════════════════════════════════════════════════════╝

  Agent                Status               Workload        Completed 
  ────────────────────────────────────────────────────────────
  🤖 Claude          ✓ Configured     2 active   15
  💬 ChatGPT         ✓ Configured     3 active   22
  ✨ Gemini           ✓ Configured     1 active   8
  🚀 Grok            ✓ Configured     0 active   5
  🐙 GitHub Copilot  ✓ Authenticated  1 active   12
```

### Workload Distribution:
```
  Total Tasks:
    Pending:     5
    In Progress: 7
    Completed:   62

  Per Agent:

    claude          2 active, 15 completed (17 total)
    chatgpt         3 active, 22 completed (25 total)
    gemini          1 active, 8 completed (9 total)
    grok            0 active, 5 completed (5 total)
    copilot         1 active, 12 completed (13 total)
```

### Detailed Status:
```
🤖 Claude (Anthropic)
   Status: ✓ Online
   API Key: sk-ant-api03-vSFAvdL...
   Workload: 2 active tasks
   Completed: 15 tasks

💬 ChatGPT (OpenAI)
   Status: ✓ Online
   API Key: sk-proj-ZOSJPpu3lEk...
   Workload: 3 active tasks
   Completed: 22 tasks
```

---

## 🚀 Usage Examples

### Daily Standup
```bash
# Quick check before starting work
orkestra health --summary
```

### Troubleshooting
```bash
# When tasks aren't completing
orkestra health --detailed

# Test specific problematic agent
orkestra health --test claude
```

### Performance Monitoring
```bash
# See which agents are busiest
orkestra health --workload
```

### Real-time Monitoring
```bash
# During heavy workload
orkestra health --monitor
```

### Configuration Check
```bash
# After setting up API keys
./SCRIPTS/UTILS/setup-apis.sh
orkestra health --detailed
```

---

## 🔧 Integration Points

### In orkestra Command
```bash
orkestra health [options]
```
Fully integrated with the main Orkestra command.

### In start-orkestra.sh
The startup health check already verifies API keys.

### With Automation
Can be used to check agent availability before assigning tasks.

### Standalone
```bash
./SCRIPTS/MONITORING/agent-health.sh [options]
```
Can also be run directly.

---

## 📈 Status Indicators

### Configuration
- ✓ **Configured** - API key is set and looks valid
- ○ **Not Configured** - No API key found
- ○ **Not Setup** - Alternative wording for unconfigured

### Connection (Detailed Check)
- ✓ **Online** - API is accessible and responding
- ⚠ **Rate Limited** - Too many requests
- ✗ **Auth Failed** - Invalid API key
- ✗ **Error** - Connection or other error
- ? **Unknown** - Status not yet checked

### Authentication (GitHub)
- ✓ **Authenticated** - GitHub CLI is logged in
- ○ **Not Auth'd** - Not authenticated

---

## 🎯 Use Cases

1. **Pre-flight Check**: Verify all agents before starting work
2. **Troubleshooting**: Diagnose why tasks aren't being processed
3. **Performance Monitoring**: Track agent utilization
4. **Load Balancing**: See which agents are overloaded
5. **Configuration Validation**: Verify API keys after setup
6. **Real-time Monitoring**: Watch agents during operation
7. **Individual Diagnostics**: Deep dive into specific agent issues

---

## 🛠️ Technical Details

### API Tests Performed

**Anthropic Claude:**
- POST to `/v1/messages`
- Validates API key format
- Tests basic message completion

**OpenAI ChatGPT:**
- POST to `/v1/chat/completions`
- Uses minimal tokens
- Quick response test

**Google Gemini:**
- POST to `/v1beta/models/gemini-pro:generateContent`
- Validates API key parameter
- Basic generation test

**xAI Grok:**
- POST to `/v1/chat/completions` (OpenAI-compatible)
- Bearer token authentication
- Quick test completion

**GitHub:**
- Uses `gh auth status`
- No API calls needed
- Authentication verification

### Workload Tracking
Reads from: `CONFIG/TASK-QUEUES/task-queue.json`
- Counts tasks by status (`pending`, `in_progress`, `completed`)
- Groups by `assigned_to` field
- Real-time data from active queue

---

## 📚 Documentation

- **Main Guide**: `DOCS/GUIDES/agent-health-guide.md`
- **Quick Reference**: `DOCS/GUIDES/orkestra-quick-reference.md`
- **Script Location**: `SCRIPTS/MONITORING/agent-health.sh`

---

## ✅ Testing

All features tested and working:
- ✅ Summary view displays correctly
- ✅ Detailed check connects to APIs
- ✅ Specific agent testing works
- ✅ Workload distribution accurate
- ✅ Interactive menu navigates properly
- ✅ Integration with `orkestra` command
- ✅ All 5 agents (Claude, ChatGPT, Gemini, Grok, Copilot) supported
- ✅ Color-coded output for easy reading
- ✅ Error handling for missing API keys
- ✅ Graceful failure when agents unavailable

---

## 🎉 Benefits

1. **Visibility**: See all agent statuses at a glance
2. **Diagnostics**: Quickly identify configuration issues
3. **Performance**: Monitor workload distribution
4. **Reliability**: Verify agents before use
5. **Troubleshooting**: Detailed error information
6. **Real-time**: Live monitoring during operations
7. **User-friendly**: Interactive menu for easy navigation
8. **Integrated**: Seamless part of Orkestra workflow

---

## 🔮 Future Enhancements

Potential additions:
- Historical performance metrics
- Agent response time tracking
- Automatic failover suggestions
- Email/Slack alerts on agent failures
- Custom health check intervals
- Agent performance comparison charts
- API quota monitoring
- Cost tracking per agent

---

## 📞 Access

```bash
# Interactive menu (recommended for first-time users)
orkestra health

# Quick status (for scripts/automation)
orkestra health --summary

# Full diagnostics (for troubleshooting)
orkestra health --detailed

# Specific agent (for focused debugging)
orkestra health --test <agent>

# Workload view (for load balancing)
orkestra health --workload

# Real-time monitor (for active monitoring)
orkestra health --monitor
```

---

**Status**: ✅ Complete and Ready to Use  
**Date Added**: October 18, 2025  
**Version**: 1.0
