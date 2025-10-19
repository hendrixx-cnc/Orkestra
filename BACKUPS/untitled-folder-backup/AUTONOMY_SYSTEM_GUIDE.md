# 🎮 Autonomy-Based AI System

## Overview

This system gives you **fine-grained control** over how much independence each AI has for different task types. AIs only work autonomously within their configured limits and **consult you when they need approval**.

---

## 🎯 Key Principles

1. **Dependencies Only** - The ONLY reason a task can't be worked on is unmet dependencies
2. **First-Come-First-Serve** - No priority conflicts, simple queue order
3. **Configurable Autonomy** - Set 0-100% independence per task type
4. **User Consultation** - AIs show work and iterate based on your feedback
5. **Idle Productivity** - AIs do error/consistency checks when waiting
6. **Clean Resumption** - System pauses for your input, resumes seamlessly

---

## ⚙️ Autonomy Configuration

Edit `/AI/autonomy_config.json`:

```json
{
  "autonomy_levels": {
    "art_assets": 0,      // ← AI shows you every iteration
    "content": 0,         // ← AI shows you before completion
    "sound": 0,           // ← Reserved for future
    "video": 0,           // ← Reserved for future
    "documentation": 100, // ← AI completes independently
    "error_checking": 100, // ← AI does automatically
    "code": 50,           // ← AI may ask for decisions
    "testing": 75         // ← AI mostly independent
  }
}
```

### Autonomy Levels Explained:

| Level | Behavior |
|-------|----------|
| **0-49%** | AI completes work, shows you, waits for approval before marking done |
| **50-74%** | AI completes and marks done, but makes available for your review |
| **75-99%** | AI works mostly independently, rare consultation |
| **100%** | AI fully autonomous, no consultation needed |

---

## 🚀 Usage

### Start with Autonomy Control
```bash
cd /workspaces/The-Quantum-Self-/AI

# Run all AIs with autonomy awareness
bash autonomy_executor.sh gemini continuous 10 &
bash autonomy_executor.sh claude continuous 10 &
bash autonomy_executor.sh chatgpt continuous 10 &
bash autonomy_executor.sh grok continuous 10 &
```

### What Happens:

1. **High Autonomy Tasks (100%)** - Execute immediately
2. **Low Autonomy Tasks (0-49%)** - AI generates → Shows you → Waits
3. **No Available Tasks** - AI performs idle tasks:
   - Error checking
   - Inconsistency detection
   - Documentation review
4. **AIs wait** for your feedback when needed

---

## 💬 Responding to AI Work

When an AI shows you work for approval:

```bash
# Approve - mark complete
bash respond_to_approval.sh 21 approve

# Request changes - AI will iterate
bash respond_to_approval.sh 21 iterate "Make the icon more rounded"

# Skip for now - will ask again later
bash respond_to_approval.sh 21 skip

# Reject - reset to pending
bash respond_to_approval.sh 21 reject
```

---

## 📋 Example Workflow

### Art Asset Task (0% Autonomy):

```
AI: "I'm working on Task #21: Create Core App Icons"
AI: Generates SVG icons
AI: 📄 Shows you the output file
AI: ⏸️  Pauses, waiting for your decision

You view the file, decide you want changes:
$ bash respond_to_approval.sh 21 iterate "Make atom more circular"

AI: Reads your feedback
AI: Generates revised version (Iteration 2)
AI: 📄 Shows you again
AI: ⏸️  Pauses

You're happy:
$ bash respond_to_approval.sh 21 approve

AI: ✓ Task marked complete
AI: Moves to next task
```

### Documentation Task (100% Autonomy):

```
AI: "I'm working on Task #17: Write AI System Documentation"
AI: ✓ Fully autonomous - executing without consultation
AI: Generates documentation
AI: ✓ Task completed
AI: Moves to next task
(You never needed to be involved)
```

### No Tasks Available:

```
AI: "No tasks available"
AI: 🔍 Running error checks...
AI: 🔍 Running inconsistency checks...
AI: 📖 Reviewing documentation...
AI: ⏸️  Waiting for new tasks or user input...
```

---

## 🎯 Task Type Mapping

Tasks are automatically categorized by title patterns:

| Pattern | Type | Default Autonomy |
|---------|------|------------------|
| "Create.*Icon" | art_assets | 0% |
| "Create.*Logo" | art_assets | 0% |
| "Write.*Story" | content | 0% |
| "Generate.*Copy" | content | 0% |
| ".*Documentation" | documentation | 100% |
| "Review.*Quality" | error_checking | 100% |
| "Optimize.*" | code | 50% |
| "Create.*Guide" | content | 0% |

---

## 📊 Checking Pending Approvals

```bash
# List all tasks waiting for your response
ls -lh AI/user_approvals/

# View details of a specific approval request
cat AI/user_approvals/task_21_iter_1.json
```

---

## 🔄 Iteration Example

```bash
# Iteration 1
AI generates icon → Shows you → You request changes

# Iteration 2
AI revises based on feedback → Shows you → You request more changes

# Iteration 3
AI refines further → Shows you → You approve

Task complete!
```

---

## ⚡ Quick Commands

```bash
# View autonomy config
cat AI/autonomy_config.json

# Edit autonomy levels
nano AI/autonomy_config.json

# Start single AI with autonomy
bash autonomy_executor.sh gemini continuous 5

# Check what's waiting for approval
ls AI/user_approvals/*.json

# Approve task
bash respond_to_approval.sh <task_id> approve

# Request iteration
bash respond_to_approval.sh <task_id> iterate "Your feedback here"

# View task queue
jq '.queue[] | {id, title, status, assigned_to}' AI/TASK_QUEUE.json
```

---

## 🎨 Typical Configuration for Your Project

```json
{
  "autonomy_levels": {
    "art_assets": 0,      // Icons, logos - show me every iteration
    "content": 25,        // Stories, copy - show me before final
    "sound": 0,           // Future sound tasks
    "video": 0,           // Future video tasks
    "documentation": 100, // Docs - fully autonomous
    "error_checking": 100,// Checks - fully autonomous
    "code": 60,           // Code - mostly autonomous
    "testing": 80         // Tests - highly autonomous
  }
}
```

This means:
- **Art**: You see every iteration before approval
- **Content**: AI writes, shows you, gets approval
- **Documentation**: AI handles completely
- **Code**: AI implements, may occasionally consult

---

## 🚦 System Behavior

### When Dependencies Are Met:
✅ Task is available for AI to work on

### When Dependencies Are NOT Met:
⏸️ Task skipped, AI tries next task

### When Autonomy < 50%:
⏸️ AI completes, shows you, waits for approval

### When Autonomy 50-99%:
✓ AI completes, you can request changes later

### When Autonomy = 100%:
✓ AI completes without consultation

### When No Tasks Available:
🔍 AI performs error checking, consistency checks, documentation review

---

## 💡 Pro Tips

1. **Start Conservative**: Set low autonomy (0-25%) initially
2. **Increase Gradually**: As you trust AI output, raise levels
3. **Per-Project Tuning**: Adjust based on project phase
4. **Review Logs**: Check approval history to see patterns
5. **Idle Time is Productive**: AIs maintain code quality when waiting

---

## 🎯 Benefits

✅ **No wasted work** - Dependencies checked first  
✅ **No conflicts** - First-come-first-serve queue  
✅ **Your control** - Set autonomy per task type  
✅ **Clean iterations** - AI refines based on feedback  
✅ **Productive idle time** - Error/consistency checks  
✅ **Pausable execution** - System waits for your input  
✅ **Clear communication** - AIs show work when needed  

---

## 📝 Summary

**Old System**: Priority-based, could cause conflicts  
**New System**: FCFS + Dependency checking + Configurable autonomy

**Key Change**: Only dependencies block tasks, everything else is configurable

**Your Control**: 0-100% autonomy per task type

**Result**: AIs work autonomously within YOUR defined limits, consult when needed, stay productive during idle time

---

## 🚀 Get Started

```bash
cd /workspaces/The-Quantum-Self-/AI

# 1. Review/edit autonomy config
nano autonomy_config.json

# 2. Start AIs
bash autonomy_executor.sh gemini continuous 10 &
bash autonomy_executor.sh claude continuous 10 &

# 3. Watch for approval requests
# (They'll be saved to AI/user_approvals/)

# 4. Respond as needed
bash respond_to_approval.sh <task_id> [approve|iterate|skip|reject]
```

**The system is ready!** AIs will work within their autonomy limits and consult you when needed. 🎉
