# 🤖 Gemini Full Automation Integration Guide

## ✅ Integration Complete!

Gemini CLI is now **fully integrated** into the AI coordination system with multiple layers of automation.

---

## 🎯 Integration Levels

### **Level 1: Manual Execution** (Basic)
Use `gemini_agent.sh` to manually execute specific tasks:

```bash
# Execute a specific task
bash AI/gemini_agent.sh execute 4

# Ask a question
bash AI/gemini_agent.sh ask "Should I use Firestore?"

# Analyze architecture
bash AI/gemini_agent.sh analyze FIREBASE_DATABASE_RECOMMENDATION.md
```

### **Level 2: Auto-Executor** (Automated)
Use `gemini_auto_executor.sh` for automatic task processing:

```bash
# Execute one available task
bash AI/gemini_auto_executor.sh once

# Execute ALL available Gemini tasks
bash AI/gemini_auto_executor.sh all

# Continuous monitoring (runs forever)
bash AI/gemini_auto_executor.sh watch
```

### **Level 3: Orchestrator Integration** (Fully Integrated)
Gemini is now part of the main orchestrator:

```bash
# Run orchestrator menu (includes Gemini option)
bash AI/orchestrator.sh

# Auto-heal includes Gemini execution
bash AI/orchestrator.sh heal

# Direct Gemini commands from orchestrator
bash AI/orchestrator.sh gemini once
bash AI/orchestrator.sh gemini all
bash AI/orchestrator.sh gemini watch
bash AI/orchestrator.sh gemini status
```

---

## 🔄 How It Works

### **Automatic Flow:**

```
┌─────────────────────────────────────────────────────────┐
│  1. Task added to TASK_QUEUE.json                      │
│     assigned_to: "gemini"                              │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  2. Orchestrator's auto_heal() runs                    │
│     - Checks if GEMINI_API_KEY is set                  │
│     - Calls gemini_auto_executor.sh all                │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  3. Auto-executor finds Gemini tasks                   │
│     - Queries TASK_QUEUE.json                          │
│     - Checks dependencies are satisfied                │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  4. Gemini agent executes task                         │
│     - Claims with file lock (prevents conflicts)       │
│     - Reads input files                                │
│     - Builds context-aware prompt                      │
│     - Calls Gemini CLI API                             │
│     - Saves output                                     │
│     - Marks complete                                   │
│     - Logs to audit trail                              │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 Usage Examples

### **Example 1: One-Time Execution**

```bash
# Check what tasks Gemini has
bash AI/task_coordinator.sh dashboard

# Execute the next Gemini task
bash AI/gemini_auto_executor.sh once

# Check the result
cat AI/TEST_GEMINI.txt  # (or whatever output file)
```

### **Example 2: Batch Execution**

```bash
# Execute ALL Gemini tasks in queue
bash AI/gemini_auto_executor.sh all

# This will:
# - Execute Task #4 (if available)
# - Execute any Firebase analysis tasks
# - Execute cost optimization tasks
# - Stop when no more tasks available
```

### **Example 3: Background Monitoring**

```bash
# Start in watch mode (background process)
nohup bash AI/gemini_auto_executor.sh watch > gemini_watch.log 2>&1 &

# Check status
tail -f AI/logs/gemini_auto_executor.log

# Stop it
pkill -f gemini_auto_executor
```

### **Example 4: Orchestrator Integration**

```bash
# Start orchestrator menu
bash AI/orchestrator.sh

# Select option "🤖 Gemini Automation" (type: gemini or g)
# Then choose:
#   1. Execute one task
#   2. Execute all tasks
#   3. Start watch mode
#   4. Check status
```

### **Example 5: Auto-Heal Trigger**

```bash
# Run auto-heal (includes Gemini execution)
bash AI/orchestrator.sh heal

# This will:
# 1. Clean stale locks
# 2. Retry failed tasks
# 3. Auto-execute all Gemini tasks ✨ NEW!
```

---

## 📊 Integration Points

### **1. File-Based Locking**
Gemini uses the same `task_lock.sh` as other AIs:
- Prevents task conflicts
- 1-hour timeout
- Atomic operations
- Auto-cleanup

### **2. Audit Logging**
All Gemini actions logged to `task_audit.log`:
- Task claims
- Task completions
- Errors
- Timestamps

### **3. Task Queue**
Gemini reads from same `TASK_QUEUE.json`:
- Respects dependencies
- Status tracking
- Priority ordering
- Load balancing

### **4. Recovery System**
Failed Gemini tasks use `task_recovery.sh`:
- Exponential backoff
- Retry limits
- Error categorization

---

## 🎛️ Configuration

### **Environment Variables**

Required:
```bash
export GEMINI_API_KEY="your-key-here"
```

Optional:
```bash
# Monitor interval (default: 60s)
export MONITOR_INTERVAL=30

# Max task age before considered stale (default: 2 hours)
export MAX_STALE_TIME=7200
```

### **Task Routing**

Tasks automatically route to Gemini if:
- `assigned_to: "gemini"` in TASK_QUEUE.json
- Task contains keywords: `firebase`, `cloud`, `architecture`

### **Log Files**

```bash
AI/logs/gemini_auto_executor.log  # Auto-executor activity
AI/task_audit.log                 # All task events
AI/recovery/failed_tasks.json     # Failed task tracking
```

---

## 🔧 Troubleshooting

### **Issue: "No tasks available for Gemini"**

**Cause:** No tasks with `assigned_to: "gemini"` in queue

**Solution:**
```bash
# Check task queue
jq '.tasks[] | select(.assigned_to == "gemini")' AI/TASK_QUEUE.json

# Or view dashboard
bash AI/task_coordinator.sh dashboard
```

### **Issue: "GEMINI_API_KEY not set"**

**Cause:** API key not in environment

**Solution:**
```bash
export GEMINI_API_KEY="your-key-here"
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.bashrc
```

### **Issue: Task stuck in "in_progress"**

**Cause:** Lock not released (crash or timeout)

**Solution:**
```bash
# Clean stale locks
bash AI/task_lock.sh clean

# Or use orchestrator
bash AI/orchestrator.sh heal
```

### **Issue: Task failed**

**Cause:** API error, file not found, etc.

**Solution:**
```bash
# Check logs
tail -50 AI/logs/gemini_auto_executor.log

# Retry manually
bash AI/gemini_agent.sh execute <task_id>

# Or use recovery system
bash AI/task_recovery.sh retry <task_id> manual
```

---

## 📈 Monitoring

### **Real-Time Dashboard**

```bash
# Watch mode (updates every 5 seconds)
watch -n 5 'bash AI/task_coordinator.sh dashboard'
```

### **Check Gemini Status**

```bash
# View Gemini's current status
bash AI/gemini_agent.sh status

# Or
cat AI/GEMINI_STATUS.md
```

### **View Logs**

```bash
# Recent auto-executor activity
tail -50 AI/logs/gemini_auto_executor.log

# Recent audit events
bash AI/task_audit.sh query recent 20

# Filter by Gemini
bash AI/task_audit.sh query ai gemini
```

---

## 🎯 Best Practices

### **1. Use Auto-Executor for Batch Tasks**

✅ **Good:**
```bash
# Let it handle all tasks
bash AI/gemini_auto_executor.sh all
```

❌ **Avoid:**
```bash
# Manual loop (unnecessary)
for task in 4 5 6; do
    bash AI/gemini_agent.sh execute $task
done
```

### **2. Use Watch Mode for Continuous Integration**

✅ **Good:**
```bash
# Background daemon
nohup bash AI/gemini_auto_executor.sh watch &
```

❌ **Avoid:**
```bash
# Cron job every minute (overkill)
* * * * * bash AI/gemini_auto_executor.sh once
```

### **3. Let Orchestrator Handle Auto-Heal**

✅ **Good:**
```bash
# Orchestrator handles everything
bash AI/orchestrator.sh heal
```

❌ **Avoid:**
```bash
# Manual coordination
bash AI/task_lock.sh clean
bash AI/task_recovery.sh retry auto
bash AI/gemini_auto_executor.sh all
```

---

## 🔥 Advanced Features

### **Conditional Execution**

Only run Gemini if tasks are available:

```bash
if jq -e '.tasks[] | select(.assigned_to == "gemini" and .status == "waiting")' AI/TASK_QUEUE.json > /dev/null; then
    bash AI/gemini_auto_executor.sh all
else
    echo "No Gemini tasks"
fi
```

### **Parallel Execution with Other AIs**

```bash
# Run Gemini in background
bash AI/gemini_auto_executor.sh all &
GEMINI_PID=$!

# Do other work
# ... manual Copilot work ...

# Wait for Gemini to finish
wait $GEMINI_PID
```

### **Custom Task Filters**

Modify `gemini_auto_executor.sh` to filter by priority:

```bash
# Only execute high-priority tasks
jq -r '.tasks[] | select(.assigned_to == "gemini" and .status == "waiting" and .priority == "high") | .id'
```

---

## 📚 File Structure

```
AI/
├── gemini_agent.sh              # Manual execution
├── gemini_auto_executor.sh      # Automatic execution
├── orchestrator.sh              # Main orchestrator (includes Gemini)
├── task_coordinator.sh          # Load balancing
├── task_lock.sh                 # Locking mechanism
├── task_audit.sh                # Event logging
├── task_recovery.sh             # Failure recovery
├── TASK_QUEUE.json              # Task definitions
├── GEMINI_STATUS.md             # Gemini status
├── GEMINI_INTEGRATION.md        # Integration docs
├── GEMINI_CLI_SETUP.md          # CLI setup guide
└── logs/
    └── gemini_auto_executor.log # Execution logs
```

---

## 🎉 Summary

**You now have 4 ways to run Gemini tasks:**

1. **Manual:** `bash AI/gemini_agent.sh execute <task_id>`
2. **Auto-Once:** `bash AI/gemini_auto_executor.sh once`
3. **Auto-All:** `bash AI/gemini_auto_executor.sh all`
4. **Orchestrator:** `bash AI/orchestrator.sh heal` (automatic)

**Gemini is fully integrated into:**
- ✅ Task coordination system
- ✅ File-based locking
- ✅ Audit logging
- ✅ Recovery system
- ✅ Orchestrator auto-heal
- ✅ Load balancing
- ✅ Dashboard monitoring

**The system is now FULLY AUTONOMOUS for Gemini tasks!** 🚀

---

## 🚀 Quick Start

```bash
# Set API key (one-time setup)
export GEMINI_API_KEY="your-key-here"
echo 'export GEMINI_API_KEY="your-key-here"' >> ~/.bashrc

# Run orchestrator with Gemini integration
bash AI/orchestrator.sh

# Or execute all Gemini tasks immediately
bash AI/orchestrator.sh gemini all

# Or start background monitoring
bash AI/orchestrator.sh gemini watch
```

**That's it! Gemini is now fully automated!** 🔥
