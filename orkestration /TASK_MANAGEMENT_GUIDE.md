# Quick Task Management Commands

## 🎯 **View Available Tasks**

```bash
# See what's next
./ai_coordinator.sh

# View full task queue
cat TASK_QUEUE.json | jq '.queue[] | select(.status == "pending")'

# View status dashboard
./ai_status_check.sh
```

---

## ✅ **Claim a Task**

When you see a task marked `"assigned_to": "Any AI"`:

```bash
# Claim it for yourself (with automatic safety checks)
./claim_task.sh <task_id> <YourAIName>

# Examples:
./claim_task.sh 5 Copilot
./claim_task.sh 6 ChatGPT
./claim_task.sh 7 Claude
```

**What this does:**
- ✅ **Checks dependencies** - Prevents breaking the build
- ✅ **Verifies availability** - No conflicts with other AIs
- ✅ Updates TASK_QUEUE.json
- ✅ Changes status: `pending` → `in_progress`
- ✅ Changes `assigned_to`: `Any AI` → `YourName`
- ✅ Adds timestamp

**Build Safety:**
- ❌ **Blocks if dependencies not met** (prevents build breaks)
- ❌ **Blocks if already assigned** (prevents conflicts)
- ❌ **Blocks if completed** (prevents duplicate work)

See `BUILD_SAFETY.md` for full details on dependency checking. when claimed

---

## 🎉 **Mark Task Complete**

When you finish a task:

```bash
# Mark it complete
./complete_task.sh <task_id>

# Example:
./complete_task.sh 6
```

**What this does:**
- ✅ Updates TASK_QUEUE.json
- ✅ Changes status: `in_progress` → `completed`
- ✅ Adds completion timestamp
- ✅ Removes from active queue

---

## 📋 **Task Queue Rules**

### Task Types:
- **`technical`** → Best for **Copilot** (code, implementation, testing)
- **`content`** → Best for **ChatGPT** (writing, creative, marketing)
- **`review`** → Best for **Claude** (editing, refinement, analysis)

### Dependencies:
- ✅ Can claim: `"dependencies": []`
- ❌ Cannot claim: `"dependencies": [1, 3]` (until those tasks complete)

### Flexible Assignment:
- **`"assigned_to": "Any AI"`** = Anyone can claim it
- **`"suggested_ai": "Copilot"`** = Recommended (not required)
- **`"assigned_to": "Copilot"`** = Specific assignment (don't change without delegation)

---

## 🔄 **Full Workflow**

### 1. Check What's Next
```bash
./ai_coordinator.sh
```

### 2. Claim the Task (if flexible)
```bash
./claim_task.sh 6 ChatGPT
```

### 3. Check Current Task Details
```bash
cat CURRENT_TASK.md
```

### 4. Do the Work
- Read requirements in CURRENT_TASK.md
- Create/edit files as needed
- Test your changes

### 5. Mark Complete
```bash
./complete_task.sh 6
```

### 6. Update Your Status
```bash
# Update COPILOT_STATUS.md, CLAUDE_STATUS.md, or CHATGPT_STATUS.md
```

### 7. See What's Next
```bash
./ai_coordinator.sh
```

---

## 📊 **View All Tasks by Status**

```bash
# Pending tasks
cat TASK_QUEUE.json | jq '.queue[] | select(.status == "pending") | {id, title, assigned_to, priority}'

# In progress tasks
cat TASK_QUEUE.json | jq '.queue[] | select(.status == "in_progress") | {id, title, assigned_to}'

# Completed tasks
cat TASK_QUEUE.json | jq '.queue[] | select(.status == "completed") | {id, title, completed_on}'

# Tasks I can claim
cat TASK_QUEUE.json | jq '.queue[] | select(.assigned_to == "Any AI" and .dependencies == []) | {id, title, task_type, suggested_ai}'
```

---

## 🚀 **Quick Commands**

| Command | Description |
|---------|-------------|
| `./ai_coordinator.sh` | See who should work next |
| `./claim_task.sh <id> <AI>` | Claim a flexible task |
| `./complete_task.sh <id>` | Mark task complete |
| `./ai_status_check.sh` | View full dashboard |
| `cat CURRENT_TASK.md` | See current task details |
| `cat TASK_QUEUE.json` | View all tasks |

---

## 💡 **Tips**

✅ **Always run `claim_task.sh` before starting** - Prevents conflicts  
✅ **Check dependencies** - Can't claim tasks with pending dependencies  
✅ **Match your strengths** - `task_type` hints at best fit  
✅ **Update status files** - Keep team informed  
✅ **Run coordinator after completion** - See what's next

---

**Last Updated:** October 17, 2025
