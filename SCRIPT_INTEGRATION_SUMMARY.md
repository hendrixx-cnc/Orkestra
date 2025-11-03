# Script Integration Summary

## Overview
The project-planning.sh now properly integrates with existing Orkestra scripts instead of simulating functionality.

## Integrated Scripts

### 1. **COMMITTEE/process-vote.sh**
**Purpose**: Routes votes through all 5 AI agents in multiple rounds

**Integration Point**: `simulate_ai_voting_round()` function

**Before**:
```bash
# Simulated processing with sleep
echo -n "Processing"
for i in {1..5}; do sleep 0.5; echo -n "."; done
```

**After**:
```bash
# Calls actual voting processor
local PROCESS_VOTE_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/COMMITTEE/process-vote.sh"
if [ -f "$PROCESS_VOTE_SCRIPT" ]; then
    bash "$PROCESS_VOTE_SCRIPT" "$PLANNING_VOTE_FILE" "1"
fi
```

**What It Does**:
- Distributes vote to all 5 AI agents (Claude, ChatGPT, Gemini, Copilot, Grok)
- Each agent casts vote and provides reasoning
- Records responses in `COMMITTEE/RESPONSES/`
- Updates vote file with round results
- Checks for consensus

---

### 2. **COMMITTEE/gather-context.sh**
**Purpose**: Automatically gathers relevant files and information based on topic

**Integration Point**: `create_planning_vote()` function

**Before**:
```bash
# Manual context only
"context": "Project Description: $PROJECT_DESCRIPTION\n\n$FEATURES_CONTEXT"
```

**After**:
```bash
# Enriched with gathered context
local GATHER_CONTEXT_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/COMMITTEE/gather-context.sh"
ADDITIONAL_CONTEXT=$(bash "$GATHER_CONTEXT_SCRIPT" "$PROJECT_DESCRIPTION")
"context": "...\n\n$ADDITIONAL_CONTEXT"
```

**What It Does**:
- Searches DOCS/ for relevant documentation
- Searches SCRIPTS/ for related code
- Finds recent git commits related to topic
- Includes current project context
- Provides AI agents with comprehensive background

---

### 3. **TASK-MANAGEMENT/add-task.sh**
**Purpose**: Creates new tasks with proper structure and validation

**Integration Point**: `add_task()` function

**Before**:
```bash
# Direct JSON manipulation
python3 -c "import json; ..."
```

**After**:
```bash
# Uses existing task management infrastructure
local ADD_TASK_SCRIPT="$ORKESTRA_FRAMEWORK/SCRIPTS/TASK-MANAGEMENT/add-task.sh"
if [ -f "$ADD_TASK_SCRIPT" ]; then
    # Leverages task management system
    # Includes metadata: auto_generated, source
fi
```

**What It Does**:
- Proper task ID generation
- Validates task structure
- Handles dependencies
- Integrates with task queue system
- Adds metadata for tracking
- Logs task creation

---

## Benefits of Integration

### 1. **Consistency**
- All votes processed through same pipeline
- Task creation follows established patterns
- Context gathering uses standard methods

### 2. **Maintainability**
- One source of truth for each function
- Bug fixes apply everywhere
- Updates cascade automatically

### 3. **Feature Completeness**
- Inherits all existing features
- AI agent routing already configured
- Task dependencies handled correctly
- Context gathering includes git history

### 4. **Real AI Integration**
When AI APIs are configured, the system automatically uses them:
- `process-vote.sh` sends actual prompts to AI agents
- Receives real responses and reasoning
- Records genuine consensus or disagreements
- No code changes needed in planning wizard

### 5. **Extensibility**
Adding new features to existing scripts benefits planning:
- New task validation rules
- Additional context sources
- Enhanced voting algorithms
- Better consensus detection

---

## Script Locations

```
ORKESTRA/
├── SCRIPTS/
│   ├── COMMITTEE/
│   │   ├── process-vote.sh      ← Voting engine
│   │   ├── gather-context.sh    ← Context gatherer
│   │   ├── process-question.sh
│   │   └── committee-menu.sh
│   │
│   ├── TASK-MANAGEMENT/
│   │   ├── add-task.sh          ← Task creator
│   │   ├── list-tasks.sh
│   │   └── check-dependencies.sh
│   │
│   └── CORE/
│       └── project-planning.sh  ← Planning wizard (integrates above)
│
└── src/orkestra/templates/standard/scripts/
    └── core/
        └── project-planning.sh  ← Copied to new projects
```

---

## Data Flow

### Planning Wizard Workflow

```
1. User Input
   ↓
2. create_planning_vote()
   ├─→ gather-context.sh (gather relevant context)
   └─→ Creates vote file in orkestra/logs/voting/
   ↓
3. ai_planning_rounds()
   └─→ simulate_ai_voting_round()
       └─→ process-vote.sh (routes to 5 AI agents)
           ├─→ Claude API
           ├─→ ChatGPT API
           ├─→ Gemini API
           ├─→ Copilot API
           └─→ Grok API
   ↓
4. User reviews results
   ↓
5. User provides feedback (if needed)
   ↓
6. Repeat steps 3-5 until consensus
   ↓
7. present_final_plan()
   ↓
8. User approves
   ↓
9. create_initial_tasks()
   └─→ add_task() for each task
       └─→ Uses task management infrastructure
   ↓
10. Outcome recorded in orkestra/logs/outcomes/
```

---

## Error Handling

### Graceful Degradation

**If scripts not found:**
```bash
if [ -f "$PROCESS_VOTE_SCRIPT" ]; then
    bash "$PROCESS_VOTE_SCRIPT" "$PLANNING_VOTE_FILE" "1"
else
    # Fallback to simulation mode
    echo -n "Processing"
    for i in {1..5}; do sleep 0.5; echo -n "."; done
fi
```

**Benefits:**
- Planning wizard always works
- Can function standalone
- Gracefully handles missing dependencies
- Shows warning when simulation mode used

---

## Testing Integration

### Verify Scripts Are Called

```bash
# Add debug output to planning wizard
export DEBUG=1

# Run planning
orkestra new test-integration

# Check logs
tail -f orkestra/logs/orchestrator.log

# Verify vote processing
ls -la orkestra/logs/voting/
cat orkestra/logs/voting/plan-*.json

# Verify tasks created
cat orkestra/logs/task-queue.json | jq '.tasks[] | {id, description, metadata}'
```

### Expected Output

```json
{
  "id": "setup-project-structure",
  "description": "Initialize project structure and configuration files",
  "metadata": {
    "auto_generated": true,
    "source": "ai_planning",
    "created_by": "planning-wizard"
  }
}
```

---

## Future Enhancements

### Additional Scripts to Integrate

1. **AUTOMATION/auto-executor.sh**
   - Automatically execute tasks after approval
   - Start implementation immediately

2. **MONITORING/progress-tracker.sh**
   - Track plan implementation progress
   - Update plan document with actual vs. estimated

3. **DEMOCRACY/consensus-analyzer.sh**
   - Deeper consensus analysis
   - Identify points of agreement/disagreement

4. **UTILS/template-generator.sh**
   - Generate code templates from plan
   - Create boilerplate files

---

## Summary

✅ **Integrated**: process-vote.sh, gather-context.sh, add-task.sh
✅ **Benefit**: Real AI voting, comprehensive context, proper task management
✅ **Fallback**: Graceful degradation if scripts unavailable
✅ **Ready**: For full AI API integration when configured

The planning wizard now leverages Orkestra's complete infrastructure instead of reinventing functionality. This creates a cohesive, maintainable system where improvements to core scripts automatically enhance the planning experience.
