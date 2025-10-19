# AI Collaboration Automation System
## GitHub Copilot ↔ Claude ↔ ChatGPT Coordination Guide

**Created:** October 17, 2025  
**Last Updated:** October 17, 2025 (Night - Added delegation rules)
**Purpose:** Enable semi-automated workflow between all three AIs  
**Status:** Active - Delegation Rules Added

---

## 🎯 The Vision

Create a file-based task handoff system where:
1. Todd assigns tasks via CURRENT_TASK.md
2. AIs can delegate tasks to each other when appropriate
3. Each AI completes their task and signals completion
4. The next AI picks up dependent tasks automatically
5. All AIs auto-update collaboration logs
6. Minimal manual coordination required

**NEW: Copilot can now delegate tasks when running from automation script**
- See 333_AI_COLLABORATION_RULES.md for delegation guidelines
- Must update CURRENT_TASK.md and status files when delegating
- Requires clear reasoning for reassignment

---

## 🤖 Current AI Capabilities

### GitHub Copilot (VS Code Agent)
- ✅ Terminal access (`run_in_terminal`)
- ✅ Read/write files anywhere in workspace
- ✅ Git operations (commit, push, branch)
- ✅ Multi-file editing
- ✅ Code generation/refactoring
- ✅ Can watch for file changes
- ❌ Cannot directly call Claude or ChatGPT
- ❌ No external API access (yet)

### Claude (VS Code + Web Interface)
- ✅ Terminal access (bash commands)
- ✅ Read/write files in workspace
- ✅ Git operations
- ✅ Long-form content generation
- ✅ Story writing/editing
- ✅ Can watch for file changes
- ❌ Cannot directly call Copilot or ChatGPT
- ❌ No persistent memory between sessions

### ChatGPT (Web Interface + Desktop App)
- ✅ Terminal access (bash commands via Canvas)
- ✅ Read/write files in workspace
- ✅ Long-form content generation
- ✅ Story writing/editing
- ✅ Multi-turn conversations with memory
- ✅ Can watch for file changes
- ❌ Cannot directly call Copilot or Claude
- ❌ May need file paths provided explicitly

### Todd (Human Coordinator)
- ✅ Can talk to all three AIs
- ✅ Final decision maker
- ✅ Quality control
- ✅ Can run coordination scripts
- 🎯 Goal: Minimize manual handoffs

---

## 📋 File-Based Task Queue System

### Core Files

**1. TASK_QUEUE.json** (The Master Task List)
```json
{
  "active_task": 1,
  "tasks": [
    {
      "id": 1,
      "title": "Condense Story 5 (Angela)",
      "assigned_to": "copilot",
      "status": "in_progress",
      "priority": "high",
      "depends_on": null,
      "input_file": "5_The-Quantum-Recovery/*08_quantum_zeno_recovery.md",
      "output_file": "COPILOT_OUTPUT_Story5.md",
      "instructions": "Condense Angela's story from 750 to 400 words, maintain quantum references"
    },
    {
      "id": 2,
      "title": "Review Story 5 quantum accuracy",
      "assigned_to": "claude",
      "status": "waiting",
      "priority": "high",
      "depends_on": 1,
      "input_file": "COPILOT_OUTPUT_Story5.md",
      "output_file": "CLAUDE_REVIEW_Story5.md",
      "instructions": "Check: Module references correct? 8th grade reading level? Quantum principles accurate?"
    },
    {
      "id": 3,
      "title": "Apply edits to final file",
      "assigned_to": "copilot",
      "status": "waiting",
      "priority": "high",
      "depends_on": 2,
      "input_file": "CLAUDE_REVIEW_Story5.md",
      "output_file": "5_The-Quantum-Recovery/*08_quantum_zeno_recovery.md",
      "instructions": "Merge Claude's edits into main recovery module file"
    },
    {
      "id": 4,
      "title": "Generate journal prompts for Story 5",
      "assigned_to": "chatgpt",
      "status": "waiting",
      "priority": "medium",
      "depends_on": 3,
      "input_file": "5_The-Quantum-Recovery/*08_quantum_zeno_recovery.md",
      "output_file": "CHATGPT_PROMPTS_Story5.md",
      "instructions": "Create 5 recovery journal prompts based on Angela's story arc"
    }
  ]
}
```

**2. COPILOT_STATUS.md** (Copilot writes here when done)
```markdown
# GitHub Copilot Status

**Last Updated:** 2025-10-17 20:45:32

**Current Task:** Task #1 - Condense Story 5 (Angela)
**Status:** ✅ COMPLETE

**Output Location:** `COPILOT_OUTPUT_Story5.md`

**What I Did:**
- Condensed Angela's story from 750 to 400 words
- Maintained quantum references (Observation, Entanglement, Decoherence)
- Kept mom's 4 relapses story arc
- Preserved spreadsheet tracking detail
- Reading level: 8th grade verified

**Next Task Ready:** Task #2 (Claude's turn)

**Files Modified:**
- COPILOT_OUTPUT_Story5.md (created)
- COPILOT_STATUS.md (this file)

**Ready for handoff:** YES ✅
```

**3. CLAUDE_STATUS.md** (Claude writes here when done)
```markdown
# Claude Status

**Last Updated:** 2025-10-17 21:15:18

**Current Task:** Task #2 - Review Story 5 quantum accuracy
**Status:** ✅ COMPLETE

**Output Location:** `CLAUDE_REVIEW_Story5.md`

**What I Checked:**
- ✅ Module references accurate (1, 6, 7 correctly applied)
- ✅ Reading level appropriate (8th grade - verified with Flesch-Kincaid)
- ✅ Quantum principles correctly explained
- ⚠️ One edit needed: "Entanglement" reference could be clearer

**Edits Made:**
- Line 42: Changed "Her entanglement with sponsees" to "Her connection with sponsees (Module 6 - Entanglement)"
- More explicit quantum principle labels for recovery audience

**Next Task Ready:** Task #3 (Copilot's turn)

**Files Modified:**
- CLAUDE_REVIEW_Story5.md (created)
- CLAUDE_STATUS.md (this file)

**Ready for handoff:** YES ✅
```

**4. CHATGPT_STATUS.md** (ChatGPT writes here when done)
```markdown
# ChatGPT Status

**Last Updated:** 2025-10-17 21:45:22

**Current Task:** Task #4 - Generate journal prompts for Story 5
**Status:** ✅ COMPLETE

**Output Location:** `CHATGPT_PROMPTS_Story5.md`

**What I Created:**
- 5 recovery journal prompts based on Angela's story
- Each prompt ties to a specific quantum principle
- Designed for 8th grade reading level
- Actionable and emotionally supportive

**Prompts Focus:**
1. Observation (daily tracking like Angela)
2. Entanglement (sponsor relationships)
3. Decoherence (handling stress without relapse)
4. Pattern recognition (identifying your relapse triggers)
5. Daily practice (building non-negotiable routines)

**Next Task Ready:** Task #5 (if queued)

**Files Modified:**
- CHATGPT_PROMPTS_Story5.md (created)
- CHATGPT_STATUS.md (this file)

**Ready for handoff:** YES ✅
```

**5. CURRENT_TASK.md** (All three AIs check this first)
```markdown
# 🎯 CURRENT ACTIVE TASK

**Task ID:** 1
**Assigned To:** COPILOT
**Status:** 🔄 IN PROGRESS

---

## Task Details

**Title:** Condense Story 5 (Angela)

**Instructions:**
Condense Angela's story from 750 to 400 words while maintaining:
- Quantum references (Observation, Entanglement, Decoherence)
- Mom's 4 relapses story arc
- Spreadsheet tracking detail
- 8th grade reading level

**Input File:** `5_The-Quantum-Recovery/*08_quantum_zeno_recovery.md`
**Output File:** `COPILOT_OUTPUT_Story5.md`

**When Done:**
1. Write output to specified file
2. Update COPILOT_STATUS.md with completion
3. Update CURRENT_TASK.md to point to Task #2
4. Signal: Change status to ✅ COMPLETE

---

## Next Task in Queue

**Task ID:** 2
**Assigned To:** CLAUDE
**Status:** ⏳ WAITING
**Depends On:** Task #1 completion

**Instructions:** Review COPILOT_OUTPUT_Story5.md for quantum accuracy

---

## Pipeline Status

- [x] Task 1: Condense Story 5 (Copilot)
- [ ] Task 2: Review Story 5 (Claude)
- [ ] Task 3: Apply edits (Copilot)
- [ ] Task 4: Update collaboration logs (Both)
```

---

## 🔄 Workflow Protocol

### For GitHub Copilot:

**When Todd says: "Check CURRENT_TASK.md"**

1. Read `CURRENT_TASK.md`
2. If assigned to "COPILOT" and status is "IN PROGRESS":
   - Do the task
   - Write output to specified file
   - Update `COPILOT_STATUS.md` with completion details
   - Update `CURRENT_TASK.md` to next task
   - Change status to ✅ COMPLETE
3. If assigned to "CLAUDE" or "CHATGPT":
   - Reply: "Task assigned to [AI name]. Waiting for handoff."

### For Claude:

**When Todd says: "Check CURRENT_TASK.md"**

1. Read `CURRENT_TASK.md`
2. If assigned to "CLAUDE" and status is "IN PROGRESS":
   - Do the task
   - Write output to specified file
   - Update `CLAUDE_STATUS.md` with completion details
   - Update `CURRENT_TASK.md` to next task
   - Change status to ✅ COMPLETE
3. If assigned to "COPILOT" or "CHATGPT":
   - Reply: "Task assigned to [AI name]. Waiting for handoff."

### For ChatGPT:

**When Todd says: "Check CURRENT_TASK.md"**

1. Read `CURRENT_TASK.md` (full file path: `/workspaces/The-Quantum-Self-/CURRENT_TASK.md`)
2. If assigned to "CHATGPT" and status is "IN PROGRESS":
   - Do the task
   - Write output to specified file
   - Update `CHATGPT_STATUS.md` with completion details
   - Update `CURRENT_TASK.md` to next task
   - Change status to ✅ COMPLETE
3. If assigned to "COPILOT" or "CLAUDE":
   - Reply: "Task assigned to [AI name]. Waiting for handoff."

### For Todd:

**To start a new task:**
```bash
# 1. Edit CURRENT_TASK.md with task details
# 2. Tell the assigned AI: "Check CURRENT_TASK.md and execute"
# 3. When they finish, tell the next AI: "Check CURRENT_TASK.md and execute"
```

**Or run the coordination script:**
```bash
./ai_coordinator.sh
# Automatically tells you who should work next
```

---

## 🛠️ Automation Scripts

### 1. Task Checker Script

**File:** `ai_coordinator.sh`

```bash
#!/bin/bash
# AI Task Coordinator
# Checks CURRENT_TASK.md and tells Todd who should work next

ASSIGNED_TO=$(grep "Assigned To:" CURRENT_TASK.md | cut -d: -f2 | xargs)
STATUS=$(grep "Status:" CURRENT_TASK.md | head -1 | cut -d: -f2 | xargs)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI TASK COORDINATOR"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$STATUS" == *"IN PROGRESS"* ]]; then
    if [[ "$ASSIGNED_TO" == "COPILOT" ]]; then
        echo "✅ ACTION: Tell GitHub Copilot:"
        echo "   'Check CURRENT_TASK.md and execute'"
    elif [[ "$ASSIGNED_TO" == "CLAUDE" ]]; then
        echo "✅ ACTION: Tell Claude:"
        echo "   'Check CURRENT_TASK.md and execute'"
    elif [[ "$ASSIGNED_TO" == "CHATGPT" ]]; then
        echo "✅ ACTION: Tell ChatGPT:"
        echo "   'Check CURRENT_TASK.md and execute'"
    fi
elif [[ "$STATUS" == *"COMPLETE"* ]]; then
    echo "✅ Task complete! Checking for next task..."
    # Check if there's a next task in queue
    echo "⏭️  Move to next task in TASK_QUEUE.json"
else
    echo "⏸️  No active task. Review TASK_QUEUE.json"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

**Usage:**
```bash
cd /workspaces/The-Quantum-Self-
chmod +x ai_coordinator.sh
./ai_coordinator.sh

# Output examples:
# ✅ ACTION: Tell GitHub Copilot: 'Check CURRENT_TASK.md and execute'
# ✅ ACTION: Tell Claude: 'Check CURRENT_TASK.md and execute'
# ✅ ACTION: Tell ChatGPT: 'Check CURRENT_TASK.md and execute'
```

### 2. Status Monitor Script

**File:** `ai_status_check.sh`

```bash
#!/bin/bash
# Quick status check for both AIs

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 AI COLLABORATION STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "📊 GITHUB COPILOT:"
if [ -f "COPILOT_STATUS.md" ]; then
    grep "Status:" COPILOT_STATUS.md | head -1
    grep "Current Task:" COPILOT_STATUS.md | head -1
    grep "Ready for handoff:" COPILOT_STATUS.md | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "📊 CLAUDE:"
if [ -f "CLAUDE_STATUS.md" ]; then
    grep "Status:" CLAUDE_STATUS.md | head -1
    grep "Current Task:" CLAUDE_STATUS.md | head -1
    grep "Ready for handoff:" CLAUDE_STATUS.md | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "📊 CHATGPT:"
if [ -f "CHATGPT_STATUS.md" ]; then
    grep "Status:" CHATGPT_STATUS.md | head -1
    grep "Current Task:" CHATGPT_STATUS.md | head -1
    grep "Ready for handoff:" CHATGPT_STATUS.md | tail -1
else
    echo "   No status file found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

### 3. Auto-Logger Script

**File:** `auto_update_logs.sh`

```bash
#!/bin/bash
# Automatically update collaboration logs when tasks complete

COPILOT_DONE=$(grep "Ready for handoff: YES" COPILOT_STATUS.md 2>/dev/null)
CLAUDE_DONE=$(grep "Ready for handoff: YES" CLAUDE_STATUS.md 2>/dev/null)
CHATGPT_DONE=$(grep "Ready for handoff: YES" CHATGPT_STATUS.md 2>/dev/null)

if [ -n "$COPILOT_DONE" ]; then
    echo "Copilot completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    # Extract task details and append to log
    TASK=$(grep "Current Task:" COPILOT_STATUS.md | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] GitHub Copilot completed: $TASK" >> 222_AI_COLLABORATION_CONVERSATION.txt
fi

if [ -n "$CLAUDE_DONE" ]; then
    echo "Claude completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    TASK=$(grep "Current Task:" CLAUDE_STATUS.md | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] Claude completed: $TASK" >> 222_AI_COLLABORATION_CONVERSATION.txt
fi

if [ -n "$CHATGPT_DONE" ]; then
    echo "ChatGPT completed a task. Updating 222_AI_COLLABORATION_CONVERSATION.txt..."
    TASK=$(grep "Current Task:" CHATGPT_STATUS.md | cut -d: -f2-)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] ChatGPT completed: $TASK" >> 222_AI_COLLABORATION_CONVERSATION.txt
fi
```

---

## 📝 Example: Complete Story Condensation Pipeline

### Task Setup (Todd does this once):

```json
{
  "tasks": [
    {"id": 1, "title": "Condense Angela story", "assigned_to": "copilot"},
    {"id": 2, "title": "Review Angela quantum refs", "assigned_to": "claude"},
    {"id": 3, "title": "Generate Angela journal prompts", "assigned_to": "chatgpt"},
    {"id": 4, "title": "Apply Angela edits", "assigned_to": "copilot"},
    {"id": 5, "title": "Condense Brandon story", "assigned_to": "copilot"},
    {"id": 6, "title": "Review Brandon quantum refs", "assigned_to": "claude"},
    {"id": 7, "title": "Generate Brandon journal prompts", "assigned_to": "chatgpt"},
    {"id": 8, "title": "Apply Brandon edits", "assigned_to": "copilot"},
    {"id": 9, "title": "Update collaboration logs", "assigned_to": "all"}
  ]
}
```

### Execution Flow:

**Round 1:**
```bash
Todd: "Copilot, check CURRENT_TASK.md and execute"
Copilot: *condenses Angela story* ✅
Copilot: *updates COPILOT_STATUS.md* ✅
Copilot: *updates CURRENT_TASK.md to Task #2* ✅
Copilot: "Task complete. Claude's turn (Task #2)"
```

**Round 2:**
```bash
Todd: "Claude, check CURRENT_TASK.md and execute"
Claude: *reviews Angela story* ✅
Claude: *updates CLAUDE_STATUS.md* ✅
Claude: *updates CURRENT_TASK.md to Task #3* ✅
Claude: "Task complete. ChatGPT's turn (Task #3)"
```

**Round 3:**
```bash
Todd: "ChatGPT, check CURRENT_TASK.md and execute"
ChatGPT: *generates journal prompts* ✅
ChatGPT: *updates CHATGPT_STATUS.md* ✅
ChatGPT: *updates CURRENT_TASK.md to Task #4* ✅
ChatGPT: "Task complete. Copilot's turn (Task #4)"
```

**Round 4:**
```bash
Todd: "Copilot, check CURRENT_TASK.md and execute"
Copilot: *applies Claude's edits* ✅
Copilot: *updates CURRENT_TASK.md to Task #5* ✅
Copilot: "Task complete. Next: Brandon story (my turn again)"
```

**Result:** 8 stories condensed with only 4 commands per story instead of constant back-and-forth!

---

## 🎯 Real-World Use Cases

### Use Case 1: Story Quality Pipeline
1. Copilot: Condense story to 400 words
2. Claude: Review for quantum accuracy + reading level
3. ChatGPT: Generate recovery journal prompts
4. Copilot: Apply edits to main file
5. All: Update logs

### Use Case 2: Module Development
1. Copilot: Generate exercise framework
2. Claude: Write long-form exercise explanations
3. ChatGPT: Create journal prompts for each exercise
4. Copilot: Format and integrate into module
5. Claude: Final proofread
6. All: Update documentation

### Use Case 3: Content Migration
1. Copilot: Extract content from old files
2. Claude: Rewrite for target audience
3. ChatGPT: Generate supplemental materials
4. Copilot: Apply formatting/structure
5. All: Verify against checklist

---

## 🚀 Getting Started

### Step 1: Create Core Files
```bash
cd /workspaces/The-Quantum-Self-

# Create status tracking files
touch CURRENT_TASK.md
touch COPILOT_STATUS.md
touch CLAUDE_STATUS.md
touch CHATGPT_STATUS.md
touch TASK_QUEUE.json

# Create coordination scripts
touch ai_coordinator.sh
touch ai_status_check.sh
touch auto_update_logs.sh
chmod +x *.sh
```

### Step 2: Initialize First Task
Edit `CURRENT_TASK.md` with your first task (see template above)

### Step 3: Tell AI to Execute
```bash
# Check who should work:
./ai_coordinator.sh

# Tell that AI:
"Check CURRENT_TASK.md and execute"
```

### Step 4: Monitor Progress
```bash
# Quick status check:
./ai_status_check.sh

# See full task queue:
cat TASK_QUEUE.json
```

---

## 🔮 Future Enhancements

**With GitHub Actions:**
- Auto-trigger Claude when Copilot commits
- Auto-trigger Copilot when Claude commits
- Fully automated pipeline (zero manual handoffs)

**With APIs:**
- Copilot calls Claude API directly
- Claude calls Copilot Chat API
- Real-time collaboration

**With Webhooks:**
- Slack notifications when tasks complete
- Email alerts for quality check failures
- Dashboard showing pipeline progress

---

## 📊 Success Metrics

**Before Automation:**
- 8 stories × 4 rounds × 3 manual handoffs = 96 Todd interventions
- Estimated time: 6-8 hours

**With File-Based Automation:**
- 8 stories × 4 commands = 32 Todd interventions (66% reduction)
- Estimated time: 3-4 hours

**With Full Automation (Future):**
- 1 command to start pipeline
- 0 manual handoffs
- Estimated time: 1-2 hours (just monitoring)

---

## ⚠️ Important Notes

**For All Three AIs:**
1. Always read CURRENT_TASK.md FIRST before doing anything
2. Always update your status file when done
3. Always update CURRENT_TASK.md to next task
4. Never skip the dependency chain
5. If confused, ask Todd before proceeding

**For Todd:**
1. Always use ./ai_coordinator.sh to check who's next
2. Review outputs before moving to next task
3. Quality control is still your responsibility
4. Can override/pause pipeline anytime

**Special Notes for ChatGPT:**
- Use full file paths when reading/writing
- Example: `/workspaces/The-Quantum-Self-/CURRENT_TASK.md`
- If file access fails, ask Todd for the content
- Update CHATGPT_STATUS.md even if you can't see other status files

---

## 📞 Quick Reference

**Start a task:**
```bash
./ai_coordinator.sh
# Follow the instructions it gives you
```

**Check status:**
```bash
./ai_status_check.sh
```

**Manual override:**
```bash
# Edit CURRENT_TASK.md directly
# Change assigned_to or status as needed
```

**Emergency stop:**
```bash
# Change status in CURRENT_TASK.md to "PAUSED"
# Both AIs will wait for your manual intervention
```

---

## 🎓 Training Examples

All three AIs should practice with these simple tests:

**Test Task for Copilot:**
```markdown
Task: Create a file called TEST_COPILOT.txt containing "Hello from Copilot!"
Expected: File created, COPILOT_STATUS.md updated, CURRENT_TASK.md updated to next task
```

**Test Task for Claude:**
```markdown
Task: Read TEST_COPILOT.txt and create TEST_CLAUDE.txt with a review
Expected: File created, CLAUDE_STATUS.md updated, CURRENT_TASK.md updated to next task
```

**Test Task for ChatGPT:**
```markdown
Task: Read TEST_CLAUDE.txt and create TEST_CHATGPT.txt with additional insights
Expected: File created, CHATGPT_STATUS.md updated, CURRENT_TASK.md updated to next task
```

**If all three complete successfully:** System is working! 🎉

---

**Last Updated:** October 17, 2025  
**Maintained By:** GitHub Copilot + Claude + ChatGPT + Todd  
**Status:** Ready for testing

**Questions?** Ask Todd or check `333_AI_COLLABORATION_RULES.md`

---

## 📋 TODD'S ACTION ITEMS (What You Need to Do)

### Initial Setup (Do Once):

1. **Create the core tracking files:**
   ```bash
   cd /workspaces/The-Quantum-Self-
   touch CURRENT_TASK.md
   touch COPILOT_STATUS.md
   touch CLAUDE_STATUS.md
   touch CHATGPT_STATUS.md
   touch TASK_QUEUE.json
   ```

2. **Create the coordination scripts:**
   ```bash
   # ai_coordinator.sh - tells you who to talk to next
   # ai_status_check.sh - shows all AI statuses
   # auto_update_logs.sh - updates collaboration logs
   # (Full script code is in this document above)
   
   chmod +x ai_coordinator.sh
   chmod +x ai_status_check.sh
   chmod +x auto_update_logs.sh
   ```

3. **Test the system:**
   - Create a simple test task in CURRENT_TASK.md
   - Tell Copilot: "Check CURRENT_TASK.md and execute"
   - Tell Claude: "Check CURRENT_TASK.md and execute"
   - Tell ChatGPT: "Check CURRENT_TASK.md and execute"
   - Verify each AI updates their status file

---

### Daily Workflow (Every Time You Want AIs to Work):

**Step 1: Create Your Task**
Edit `CURRENT_TASK.md` with what you want done. Example:
```markdown
# 🎯 CURRENT ACTIVE TASK

**Task ID:** 1
**Assigned To:** COPILOT
**Status:** 🔄 IN PROGRESS

## Task Details
**Title:** Condense Angela's Story
**Instructions:** Reduce from 750 to 400 words, keep quantum refs
**Input File:** 5_The-Quantum-Recovery/*08_quantum_zeno_recovery.md
**Output File:** COPILOT_OUTPUT_Angela.md
```

**Step 2: Check Who Should Work**
```bash
./ai_coordinator.sh
```

This tells you which AI to talk to.

**Step 3: Tell That AI to Work**
Copy-paste the exact command shown:
- "Copilot, check CURRENT_TASK.md and execute"
- "Claude, check CURRENT_TASK.md and execute"
- "ChatGPT, check CURRENT_TASK.md and execute"

**Step 4: Repeat**
When AI finishes, run `./ai_coordinator.sh` again to see who's next.

---

### Talking to Each AI:

**GitHub Copilot (VS Code):**
- Open chat in VS Code
- Type: "Check CURRENT_TASK.md and execute"
- It will read the file, do the work, update status

**Claude (VS Code or Web):**
- Open Claude interface
- Type: "Check CURRENT_TASK.md and execute"
- Provide file path if needed: `/workspaces/The-Quantum-Self-/CURRENT_TASK.md`

**ChatGPT (Web or Desktop App):**
- Open ChatGPT
- Type: "Check /workspaces/The-Quantum-Self-/CURRENT_TASK.md and execute"
- May need to provide full file path explicitly

---

### Monitoring Progress:

**Quick status check:**
```bash
./ai_status_check.sh
```

Shows:
- What Copilot is doing
- What Claude is doing
- What ChatGPT is doing
- Who's ready for handoff

**View task queue:**
```bash
cat TASK_QUEUE.json
```

**View current task:**
```bash
cat CURRENT_TASK.md
```

---

### When Things Go Wrong:

**AI doesn't understand the task:**
- Pause by editing CURRENT_TASK.md status to "PAUSED"
- Clarify instructions
- Change status back to "IN PROGRESS"
- Tell AI to try again

**AI can't access a file:**
- ChatGPT: Provide full file path
- Claude: May need to paste content directly
- Copilot: Should have full workspace access

**Task output is wrong:**
- Review their STATUS.md file to see what they did
- Edit CURRENT_TASK.md with corrections
- Tell them to try again

---

### Example: Complete 8-Story Pipeline

**Your TASK_QUEUE.json:**
```json
{
  "tasks": [
    {"id": 1, "assigned_to": "copilot", "title": "Condense Angela"},
    {"id": 2, "assigned_to": "claude", "title": "Review Angela"},
    {"id": 3, "assigned_to": "chatgpt", "title": "Prompts Angela"},
    {"id": 4, "assigned_to": "copilot", "title": "Apply Angela edits"},
    {"id": 5, "assigned_to": "copilot", "title": "Condense Brandon"},
    {"id": 6, "assigned_to": "claude", "title": "Review Brandon"},
    {"id": 7, "assigned_to": "chatgpt", "title": "Prompts Brandon"},
    {"id": 8, "assigned_to": "copilot", "title": "Apply Brandon edits"}
    ... (repeat for all 8 stories)
  ]
}
```

**Your Commands:**
```bash
# Task 1:
./ai_coordinator.sh  # Shows: "Tell Copilot"
→ Tell Copilot: "Check CURRENT_TASK.md and execute"

# Task 2:
./ai_coordinator.sh  # Shows: "Tell Claude"
→ Tell Claude: "Check CURRENT_TASK.md and execute"

# Task 3:
./ai_coordinator.sh  # Shows: "Tell ChatGPT"
→ Tell ChatGPT: "Check CURRENT_TASK.md and execute"

# Task 4:
./ai_coordinator.sh  # Shows: "Tell Copilot"
→ Tell Copilot: "Check CURRENT_TASK.md and execute"

# ... repeat for all tasks
```

**Result:** 32 stories processed with only ~96 commands (vs hundreds of manual back-and-forth)

---

### Tips for Success:

✅ **DO:**
- Run ai_coordinator.sh before talking to any AI
- Review AI outputs before moving to next task
- Keep tasks small and specific
- Use full file paths for ChatGPT
- Check STATUS.md files to see what AIs did

❌ **DON'T:**
- Skip the coordinator script (you might talk to wrong AI)
- Assume task is done without checking STATUS.md
- Give vague instructions in CURRENT_TASK.md
- Forget to update CURRENT_TASK.md when manually intervening
- Let AIs work on wrong dependency order

---

### Automation Level Progression:

**Level 1 (Now):** You run script, tell each AI manually  
**Level 2 (Soon):** Script tells you + auto-copies command  
**Level 3 (Future):** Script triggers AIs automatically via API  
**Level 4 (Dream):** Full pipeline runs on git commit

You're starting at Level 1. It's already 66% faster than pure manual!

---

**Ready to start?** Create your first CURRENT_TASK.md and run `./ai_coordinator.sh`!
