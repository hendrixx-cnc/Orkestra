# Autonomous 3-AI CLI System
**Built:** October 17, 2025
**Purpose:** Fully autonomous task execution with user prompts when needed

---

## 🎯 System Overview

This is a **fully autonomous multi-AI system** where 3 AI CLIs (Gemini, Claude, ChatGPT) work independently on tasks in a shared queue. **Any AI can do any task** - it's first-come-first-served. When an AI needs clarification, it **pauses and prompts you**, then resumes automatically after you answer.

### Key Features

✅ **Fully Autonomous** - AIs claim and execute tasks without human intervention
✅ **Any Task, Any AI** - No pre-assignment, AIs grab whatever's available
✅ **User Prompts** - AIs ask questions when they need clarification
✅ **Race Condition Safe** - Atomic locks prevent duplicate work
✅ **Dependency Aware** - Tasks only execute after dependencies complete
✅ **Status Monitoring** - Real-time view of all AI activity

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    USER (You)                            │
│  • Creates project plan (via Copilot)                   │
│  • Answers prompts when AIs need input                  │
│  • Commits completed work (via Copilot)                 │
└────────────────────┬─────────────────────────────────────┘
                     │
            ┌────────┴────────┐
            │  TASK_QUEUE     │
            │  (Shared)       │
            └────────┬────────┘
                     │
      ┌──────────────┼──────────────┐
      │              │              │
      ▼              ▼              ▼
┌──────────┐   ┌──────────┐  ┌──────────┐
│ GEMINI   │   │ CLAUDE   │  │ CHATGPT  │
│ DAEMON   │   │ DAEMON   │  │ DAEMON   │
│          │   │          │  │          │
│ Running  │   │ Running  │  │ Running  │
│ 24/7     │   │ 24/7     │  │ 24/7     │
└────┬─────┘   └────┬─────┘  └────┬─────┘
     │              │              │
     │   First-come-first-served  │
     │   Any AI grabs any task    │
     │                            │
     └────────────┬───────────────┘
                  │
         When blocked:
    Create USER_PROMPT.json
    Pause until answered
                  │
                  ▼
         ┌─────────────────┐
         │ user_prompts/   │
         │ (Waits for you) │
         └─────────────────┘
```

---

## 🚀 Quick Start

### 1. Start the AI Daemons

```bash
cd /workspaces/The-Quantum-Self-/AI

# Start all 3 AIs (in background)
./universal_daemon.sh Claude &
./universal_daemon.sh Gemini &
./universal_daemon.sh ChatGPT &
```

### 2. Add Tasks to Queue

Edit `TASK_QUEUE.json` and add tasks:

```json
{
  "id": 20,
  "title": "Your task here",
  "description": "What needs to be done",
  "status": "pending",
  "dependencies": [],
  "priority": "HIGH"
}
```

**No need to assign AI!** First available AI will grab it.

### 3. Monitor Status

```bash
# Check overall system status
./copilot_tool.sh status

# Check specific AI logs
tail -f logs/Claude_daemon.log
tail -f logs/Gemini_daemon.log
tail -f logs/ChatGPT_daemon.log
```

### 4. Answer Prompts When AIs Ask

When an AI needs input, you'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❓ Claude NEEDS YOUR INPUT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Task #18
Question: How should I refactor this code?
Context: Multiple approaches possible...

To answer: ./answer_prompt.sh Claude_prompt_1234567890 "your answer"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Answer it:

```bash
./answer_prompt.sh Claude_prompt_1234567890 "Use modular architecture approach"
```

AI automatically resumes work!

### 5. Commit Completed Work

```bash
# Check what was done
./copilot_tool.sh status

# Create commit
./copilot_tool.sh commit "AI team completed tasks 17-19"
```

---

## 📁 File Structure

```
AI/
├── universal_daemon.sh          # Core daemon (works for any AI)
├── copilot_tool.sh              # Status, commits, project planning
├── answer_prompt.sh             # Answer AI questions
├── TASK_QUEUE.json              # Shared task queue
│
├── locks/                       # Task locks (prevent race conditions)
│   └── task_17.lock/
│
├── status/                      # AI status files
│   ├── Claude.json
│   ├── Gemini.json
│   └── ChatGPT.json
│
├── user_prompts/                # Questions from AIs
│   ├── Claude_prompt_12345.json
│   └── ChatGPT_prompt_67890.json
│
└── logs/                        # Daemon logs
    ├── Claude_daemon.log
    ├── Gemini_daemon.log
    └── ChatGPT_daemon.log
```

---

## 🔧 How It Works

### Task Lifecycle

```
1. Task added to TASK_QUEUE.json
   ↓
2. First available AI sees it
   ↓
3. AI atomically claims it (locks/)
   ↓
4. AI executes task
   ↓
   • If needs user input → creates prompt, waits
   • If has input → continues execution
   ↓
5. AI marks task complete
   ↓
6. Dependent tasks automatically unlock
   ↓
7. Next AI grabs unlocked task
   ↓
   (Cycle repeats)
```

### Race Condition Prevention

When multiple AIs see the same task:

```bash
# Both Claude and Gemini try to claim Task #20

Claude: mkdir locks/task_20.lock  # SUCCESS ✅
Gemini: mkdir locks/task_20.lock  # FAILS ❌ (already exists)

# Claude wins, Gemini looks for another task
```

Atomic directory creation (`mkdir`) ensures only ONE AI claims each task.

### User Prompt Flow

```
1. AI encounters: "Need user to decide..."
   ↓
2. Creates user_prompts/AI_prompt_123.json
   {
     "question": "Which approach?",
     "status": "waiting"
   }
   ↓
3. AI status → "waiting_user"
   ↓
4. You run: ./answer_prompt.sh AI_prompt_123 "Approach A"
   ↓
5. Prompt status → "answered"
   ↓
6. AI reads answer, continues work
   ↓
7. Task completes
```

---

## 🛠️ Commands Reference

### Copilot Tool

```bash
# System status
./copilot_tool.sh status

# Create git commit
./copilot_tool.sh commit "message"

# Check daemon status
./copilot_tool.sh daemons

# Create project plan
./copilot_tool.sh plan
```

### Daemon Control

```bash
# Start daemons
./universal_daemon.sh Claude &
./universal_daemon.sh Gemini &
./universal_daemon.sh ChatGPT &

# Stop daemons
pkill -f "universal_daemon.sh Claude"
pkill -f "universal_daemon.sh Gemini"
pkill -f "universal_daemon.sh ChatGPT"

# Or stop all
pkill -f universal_daemon.sh
```

### User Prompts

```bash
# List waiting prompts
find user_prompts/ -name "*_prompt_*.json" | xargs jq 'select(.status == "waiting")'

# Answer prompt
./answer_prompt.sh <prompt_id> "your answer"
```

---

## 📊 Monitoring

### Real-Time Logs

```bash
# Watch all AI activity
tail -f logs/*.log

# Watch specific AI
tail -f logs/Claude_daemon.log

# Watch for user prompts
watch -n 2 'find user_prompts/ -name "*_prompt_*.json" | wc -l'
```

### Status Files

```bash
# Check AI states
cat status/Claude.json
{
  "ai": "Claude",
  "state": "executing",
  "detail": "Working on task #18",
  "updated_at": "2025-10-17T22:46:37+00:00"
}
```

**States:**
- `idle` - Waiting for tasks
- `executing` - Working on task
- `waiting_user` - Blocked on user prompt
- `stopped` - Daemon shut down

---

## 🎯 Use Cases

### 1. Full Project Execution

```bash
# Add 20 tasks to queue
# Start daemons
./universal_daemon.sh Claude &
./universal_daemon.sh Gemini &
./universal_daemon.sh ChatGPT &

# Go to lunch
# Come back, check status
./copilot_tool.sh status
# → 18/20 tasks complete, 2 waiting for your input

# Answer prompts
./answer_prompt.sh Claude_prompt_123 "Use approach A"
./answer_prompt.sh Gemini_prompt_456 "Firebase Firestore"

# 30 min later, all done
./copilot_tool.sh commit "AI team completed full project"
```

### 2. Overnight Batch Processing

```bash
# Friday 5pm: Add 50 tasks
# Start daemons
./universal_daemon.sh Claude &
./universal_daemon.sh Gemini &
./universal_daemon.sh ChatGPT &

# Go home
# Monday 9am: Check results
./copilot_tool.sh status
# → 47/50 complete, 3 had prompts you need to answer
```

### 3. Continuous Integration

```bash
# Have daemons always running
# Every git push → adds tasks to queue automatically
# AIs pick them up and execute
# You only get involved for clarifications
```

---

## ⚙️ Configuration

### Adjust Check Interval

Edit `universal_daemon.sh`:

```bash
CHECK_INTERVAL=10  # Check every 10 seconds (default)
CHECK_INTERVAL=5   # More responsive (higher CPU)
CHECK_INTERVAL=30  # Less frequent (lower CPU)
```

### Task Priority

Tasks with `"priority": "CRITICAL"` are sorted first (handled in `get_next_task()`).

### Logging Level

Set in each daemon:

```bash
# Verbose logging
LOG_LEVEL="DEBUG"

# Minimal logging
LOG_LEVEL="ERROR"
```

---

## 🐛 Troubleshooting

### Problem: Daemon Not Starting

```bash
# Check logs
tail -n 50 logs/Claude_daemon.log

# Common issues:
# - TASK_QUEUE.json invalid JSON
# - Permissions issues
# - API keys not set
```

### Problem: Task Stuck "In Progress"

```bash
# Check locks
ls -la locks/

# If stale lock (>2 hours old):
rm -rf locks/task_17.lock

# Task will become available again
```

### Problem: AI Waiting on Prompt Forever

```bash
# Check unanswered prompts
find user_prompts/ -name "*_prompt_*.json" | xargs jq 'select(.status == "waiting")'

# Answer them
./answer_prompt.sh <prompt_id> "answer"
```

### Problem: Race Condition (Rare)

If somehow two AIs claim same task:

```bash
# Check TASK_QUEUE.json
# Look for duplicate "in_progress" on same task

# Manual fix:
jq '.queue[X].status = "pending"' TASK_QUEUE.json > tmp && mv tmp TASK_QUEUE.json
```

---

## 🔒 Security Considerations

1. **API Keys** - Store in environment variables, never in code
2. **User Prompts** - May contain sensitive context, stored in `user_prompts/`
3. **Logs** - May contain task details, consider encryption for sensitive projects
4. **File Permissions** - Ensure only authorized users can access `AI/` directory

---

## 🚧 Current Limitations

1. **No actual AI API calls** - Daemons simulate work, need real API integration
2. **Simple task selection** - First available task, no intelligent prioritization
3. **No error recovery** - Failed tasks stay failed, need manual retry
4. **No web UI** - CLI only, could build dashboard
5. **Single machine** - Not distributed across multiple servers

---

## 🔮 Future Enhancements

- [ ] Real Claude, Gemini, ChatGPT API integration
- [ ] Web dashboard for monitoring
- [ ] Slack/Discord notifications for prompts
- [ ] Automatic retry on failures
- [ ] Load balancing across multiple machines
- [ ] Task priority queues
- [ ] Cost tracking per task
- [ ] Rollback on failed tasks

---

## 📝 Example Session

```bash
$ ./copilot_tool.sh status
╔══════════════════════════════════════════════════════════╗
║           COPILOT STATUS CHECK                           ║
╚══════════════════════════════════════════════════════════╝

📋 TASK QUEUE STATUS:
   Total: 19 tasks
   ✅ Completed: 17
   ⚙️  In Progress: 1
   ⏸️  Pending: 1

🤖 AI STATUS:
   Claude: executing - Working on task #18
   Gemini: idle - No tasks available
   ChatGPT: stopped - offline

❓ USER PROMPTS:
   ✅ No pending prompts

📦 GIT STATUS:
   Branch: main
   Modified files: 8
   Untracked files: 2
   💡 Tip: Run './copilot_tool.sh commit "message"' to commit

$ ./copilot_tool.sh commit "AI team refactored backend architecture"
✅ Commit created successfully
```

---

## 🤝 Contributing

This system is designed to be extended. To add new features:

1. Fork the `universal_daemon.sh`
2. Add your enhancement
3. Test with all 3 AIs
4. Submit PR with documentation

---

## 📜 License

Part of The Quantum Self project. Use as drop-in framework for any project.

---

**Questions?** Check logs, review task queue, or run `./copilot_tool.sh status`.

**Ready to go autonomous?** Start the daemons and let the AIs work! 🚀
