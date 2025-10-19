# 🗳️ Democracy Engine & Dependencies Quick Reference

## 🚀 Quick Start

### Dependency Checking
```bash
# Check if task can execute
./SCRIPTS/TASK-MANAGEMENT/check-dependencies.sh check task_0001

# Show dependency tree
./SCRIPTS/TASK-MANAGEMENT/check-dependencies.sh tree task_0001

# Get execution order
./SCRIPTS/TASK-MANAGEMENT/check-dependencies.sh order

# Validate all dependencies
./SCRIPTS/TASK-MANAGEMENT/check-dependencies.sh validate-all
```

### Voting & Consensus
```bash
# Create a vote
./SCRIPTS/DEMOCRACY/democracy-engine.sh create task_assignment \
  "Who should handle task_0001?" \
  "claude,chatgpt,gemini,grok,copilot" \
  documentation

# Cast a vote
./SCRIPTS/DEMOCRACY/democracy-engine.sh cast vote_1729273200 claude claude \
  "Documentation is my specialty"

# Tally votes
./SCRIPTS/DEMOCRACY/democracy-engine.sh tally vote_1729273200

# View results
./SCRIPTS/DEMOCRACY/democracy-engine.sh show vote_1729273200

# List all votes
./SCRIPTS/DEMOCRACY/democracy-engine.sh list open
```

---

## 📊 Dependency Rules

### Validation Checks
- ✅ Dependency exists in queue
- ✅ No self-dependencies
- ✅ No circular dependencies
- ✅ Dependency status check
- ✅ Full chain validation

### Execution Order
```
Priority: Critical > High > Medium > Low
+ Dependency Depth (tasks depending on this)
= Execution Order Score
```

### Common Commands
```bash
# Can task execute now?
./check-dependencies.sh can-execute task_0001

# Show what's blocking
./check-dependencies.sh check task_0001

# Visualize tree
./check-dependencies.sh tree task_0001
```

---

## 🗳️ Voting Systems

### 1. Simple Majority (Default)
- **Required:** 50% + 1
- **Use:** General decisions
- **Example:** 3 out of 5 = passes

### 2. Supermajority
- **Required:** 66% or 75%
- **Use:** Critical decisions
- **Example:** 4 out of 5 = passes

### 3. Weighted Voting
- **Based on:** Agent specialty
- **Use:** Domain-specific decisions
- **Example:** Claude's vote counts 2x for architecture

### 4. Unanimous
- **Required:** 100%
- **Use:** Emergency/security decisions
- **Example:** 5 out of 5 = passes

---

## 🎭 Agent Voting Weights

### By Domain

**Architecture/Design:**
- 🎭 Claude: 2.0
- 🚀 Copilot: 1.5
- ✨ Gemini: 1.5
- Others: 1.0

**Content/Writing:**
- 💬 ChatGPT: 2.0
- 🎭 Claude: 1.5
- Others: 1.0

**Cloud/Database:**
- ✨ Gemini: 2.0
- 🎭 Claude: 1.5
- Others: 1.0

**Innovation/Research:**
- ⚡ Grok: 2.0
- 🎭 Claude: 1.5
- Others: 1.0

**Deployment/Code:**
- 🚀 Copilot: 2.0
- ✨ Gemini: 1.5
- Others: 1.0

---

## 📝 Common Workflows

### Workflow 1: Task Assignment
```bash
# 1. Create vote
./democracy-engine.sh create task_assignment \
  "Assign task_0001: Write API docs" \
  "claude,chatgpt" \
  documentation

# 2. Agents cast votes
./democracy-engine.sh cast vote_XXX claude claude "My specialty"
./democracy-engine.sh cast vote_XXX chatgpt claude "Claude is best"

# 3. Tally results
./democracy-engine.sh tally vote_XXX

# 4. Winner assigned to task
```

### Workflow 2: Execution Order
```bash
# 1. Check dependencies
./check-dependencies.sh order

# 2. If multiple tasks can run parallel, create vote
./democracy-engine.sh create execution_order \
  "Priority for parallel tasks?" \
  "task_0001,task_0002,task_0003"

# 3. Agents rank preferences
./democracy-engine.sh cast vote_XXX claude "task_0001,task_0002,task_0003"

# 4. Execute in voted order
```

### Workflow 3: Dependency Decision
```bash
# 1. Check dependencies
./check-dependencies.sh check task_0005

# 2. If soft dependency incomplete, create vote
./democracy-engine.sh create decision \
  "Proceed with task_0005 despite incomplete dependency?" \
  "yes,no" \
  general \
  0.66

# 3. Agents vote
./democracy-engine.sh cast vote_XXX claude yes "Can work in parallel"
./democracy-engine.sh cast vote_XXX chatgpt no "Prefer sequential"

# 4. Execute based on result
```

---

## 🔍 Dependency States

| Symbol | Meaning |
|--------|---------|
| ✓ | Dependency completed |
| ⏳ | Dependency in progress (waiting) |
| ✗ | Dependency failed (blocking) |
| 🚫 | Dependency blocked (blocking) |
| ? | Unknown status |

---

## 📊 Vote States

| Symbol | Meaning |
|--------|---------|
| 🗳️ | Vote open (accepting votes) |
| ✓ | Vote closed (passed) |
| ✗ | Vote closed (failed) |
| ○ | Vote pending |

---

## 🎯 Best Practices

### Dependencies
✅ **DO:**
- Keep chains short (max 5 levels)
- Document why dependencies exist
- Use soft dependencies for docs
- Validate before execution

❌ **DON'T:**
- Create circular dependencies
- Depend on self
- Over-complicate chains
- Ignore warnings

### Voting
✅ **DO:**
- Provide clear proposals
- Include context and reasoning
- Set reasonable deadlines
- Respect consensus

❌ **DON'T:**
- Create duplicate votes
- Vote without reviewing
- Rush important decisions
- Override without cause

---

## 📈 Status Commands

```bash
# Dependency status
./check-dependencies.sh order              # Execution order
./check-dependencies.sh validate-all       # Full validation

# Voting status
./democracy-engine.sh list open            # Open votes
./democracy-engine.sh list closed          # Closed votes
./democracy-engine.sh stats                # Statistics
```

---

## 🔗 Integration Points

### Task Creation → Dependencies
When creating tasks with `add-task.sh`:
- Add dependencies interactively
- System validates automatically
- Execution order calculated

### Auto Assignment → Voting
When task has `assigned_to: "auto"`:
- System creates vote automatically
- Agents vote on best assignment
- Winner assigned to task

### Peer Review → Consensus
After task completion:
- Create review vote if needed
- Agents vote on approval
- Consensus required for merge

---

## 📚 Files & Locations

### Dependencies
- **Script:** `SCRIPTS/TASK-MANAGEMENT/check-dependencies.sh`
- **Docs:** `DOCS/TECHNICAL/dependency-rules.md`
- **Queue:** `CONFIG/TASK-QUEUES/task-queue.json`

### Democracy
- **Script:** `SCRIPTS/DEMOCRACY/democracy-engine.sh`
- **Docs:** `DOCS/TECHNICAL/democracy-engine.md`
- **Votes:** `CONFIG/VOTES/*.json`
- **Logs:** `LOGS/democracy-engine.log`

---

## 🆘 Troubleshooting

### Circular Dependency Error
```bash
# Find the cycle
./check-dependencies.sh check task_0001

# Fix: Remove one dependency from cycle
# Edit task-queue.json manually or recreate task
```

### Vote Not Counting
```bash
# Check vote is still open
./democracy-engine.sh show vote_XXX

# Check agent hasn't voted already
# Cast vote with correct syntax
```

### Blocked Task
```bash
# Find what's blocking
./check-dependencies.sh check task_XXX

# Complete blocking dependencies first
# Or create vote to proceed anyway
```

---

## 💡 Pro Tips

1. **Use `order` command** to see optimal execution sequence
2. **Create votes early** for controversial decisions
3. **Weight votes by specialty** for better outcomes
4. **Document reasoning** when voting (helps future decisions)
5. **Validate dependencies** before starting work
6. **Check vote stats** to see patterns and improve

---

*Quick Reference • Version 1.0.0 • October 18, 2025*
