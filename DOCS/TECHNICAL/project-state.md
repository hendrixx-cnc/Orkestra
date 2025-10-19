# OrKeStra Project State - Essential Info Only

## System Status
- **40 Tasks Total** (Tasks 1-40)
- **Tasks 1-8, 14-15:** Completed by ChatGPT
- **Tasks 9-13, 16-40:** Pending
- **15 Apple Watch tasks added** (Tasks 26-40)

## NEW: Smart Assignment System
- **Any AI can do any task**
- Priority given to AIs best suited for the task
- Dynamic load balancing based on current workload
- See: SMART_ASSIGNMENT_SYSTEM.md

## AI Capabilities (Dynamic Assignment)
- **claude:** Content review, tone, mobile testing, documentation
- **chatgpt:** Copywriting, marketing, creative content
- **gemini:** Firebase, cloud architecture, database, scaling
- **grok:** Design, SVG, icons, visuals, research
- **copilot:** Project management, system maintenance, QA

## Critical Paths
```bash
TASK_QUEUE: /workspaces/The-Quantum-Self-/AI/TASK_QUEUE.json
SCRIPTS: /workspaces/The-Quantum-Self-/AI/
RULES: /workspaces/The-Quantum-Self-/AI/SYSTEM_RULES.md
SMART SELECTOR: /workspaces/The-Quantum-Self-/AI/smart_task_selector.sh
```

## Working Features
✅ Smart task selection (suitability + workload)
✅ Dynamic AI assignment (any AI, any task)
✅ AI Notes System (inter-AI communication)
✅ Automatic lock cleanup (5 layers of defense)
✅ Lock monitor daemon (background cleanup)
✅ Exponential backoff (3 retries: 1s, 2s, 4s)
✅ Consecutive failure limit (stops after 5)
✅ Naming convention enforcement (all lowercase)
✅ Path fixes (all use AI/TASK_QUEUE.json)
✅ Agent scripts fixed (.queue[] not .tasks[])

## Lock Management
```bash
# Start lock monitor (background daemon)
bash monitor.sh start

# Check monitor status
bash monitor.sh status

# View monitor logs
bash monitor.sh logs -f

# Manual lock operations
bash task_lock.sh list           # Show all locks
bash task_lock.sh check <id>     # Check specific lock
bash task_lock.sh release <id>   # Manual release
bash task_lock.sh clean-stale    # Clean all stale locks
```

See: LOCK_CLEANUP_RULES.md for detailed documentation

## Start Commands
```bash
# View task recommendations for all AIs
bash smart_task_selector.sh recommend

# Claim task (auto-selects best AI)
bash claim_task.sh <task_id>

# Reassign all pending tasks
bash smart_task_selector.sh reassign

# AI Notes - Leave/Read messages between AIs
bash ai_notes.sh add claude task "Watch for edge case X" 16 gemini
bash ai_notes.sh read gemini
bash ai_notes.sh task 16

# Start all automation
cd /workspaces/The-Quantum-Self-/AI
bash orchestrator.sh automate all

# Check status
jq -r '.queue[] | select(.status == "in_progress") | "\(.id): \(.title)"' TASK_QUEUE.json

# View dashboard
python3 -m http.server 8080 --directory /workspaces/The-Quantum-Self-/AI &
# Open: http://localhost:8080/dashboard.html
```

## Known Issues
- Task #9: Missing input_file (null) causes failure
- Task #16: Firebase schema - needs input
- Tasks 10-12: Story arcs need STORY_GENERATION_MEMORY.md

## Quick Fixes
```bash
# Clear locks
rm -rf /workspaces/The-Quantum-Self-/AI/locks/task_*.lock

# Normalize names
cd /workspaces/The-Quantum-Self-/AI
jq '.queue |= map(if .assigned_to then .assigned_to |= ascii_downcase else . end)' TASK_QUEUE.json > /tmp/t.json && mv /tmp/t.json TASK_QUEUE.json
```

## Validation Scripts
- `validation/pre_task_validator.sh` - Run before task
- `validation/post_task_validator.sh` - Run after task
- `validation/peer_review_queue.sh` - Queue reviews
- `validation/consistency_checker.sh` - System health
- `validation/naming_convention_checker.sh` - Check lowercase
- `validation/naming_convention_fixer.sh` - Auto-fix names

## Rules
1. ALL names lowercase (claude, chatgpt, gemini, grok, copilot)
2. TASK_QUEUE path: $SCRIPT_DIR/TASK_QUEUE.json
3. Max 3 retries with exponential backoff
4. Stop after 5 consecutive failures
5. Lock files for atomic operations
6. Peer review: claude→chatgpt→grok→gemini→claude

## Next Steps
1. Fix Task #9 input_file
2. Run orchestrator.sh automate all
3. Monitor dashboard
4. Review completed tasks
5. Deploy when all 40 tasks done

**Last Updated:** 2025-10-18
**Status:** System ready, automation configured, waiting for execution
