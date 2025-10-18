# Smart AI Assignment System

## Overview

The OrKeStra system now uses intelligent, dynamic task assignment. **Any AI can do any task** - assignments are based on:
1. AI specialties matching task requirements
2. Current workload of each AI
3. Real-time availability

## How It Works

### Scoring Algorithm

Each AI receives a score for each task (0-100):

```
Final Score = Suitability Score - Workload Penalty

Suitability Score (50-100):
- Base: 50 points (any AI can do any task)
- +15 points per matching specialty

Workload Penalty:
- 20 points per active/locked task
```

### AI Specialties

**Copilot:**
- project_management
- system_maintenance
- user_requested_tasks
- quality_assurance

**Claude:**
- content_review
- tone_validation
- mobile_testing
- documentation

**ChatGPT:**
- copywriting
- marketing
- creative_content
- user_documentation

**Gemini:**
- firebase
- google_cloud
- database_design
- scaling
- cost_optimization

**Grok:**
- svg_design
- icon_creation
- visual_design
- real_time_research
- creative_content

### Task Matching

The system analyzes task titles and instructions for keywords:

- **Firebase/Cloud tasks** → Gemini gets +15 bonus
- **Marketing/Copy tasks** → ChatGPT gets +15 bonus
- **Review/Testing tasks** → Claude gets +15 bonus
- **Design/Visual tasks** → Grok gets +15 bonus
- **System/Setup tasks** → Copilot gets +15 bonus

## Usage

### Manual Task Claiming

```bash
# Auto-select best AI for task
bash claim_task.sh 16

# Or specify an AI (any AI can be assigned)
bash claim_task.sh 16 gemini
```

### Reassign All Tasks

```bash
# Reassign all pending tasks based on current availability
bash smart_task_selector.sh reassign
```

### View Recommendations

```bash
# See which tasks are best matched to each AI
bash smart_task_selector.sh recommend
```

### Check Suitability Score

```bash
# Calculate how well an AI matches a task
bash smart_task_selector.sh score gemini 16
# Output: 100 (perfect match for Firebase task)
```

## Benefits

1. **Flexibility**: No fixed assignments - work distributes dynamically
2. **Load Balancing**: AIs with fewer tasks get priority
3. **Quality**: Tasks go to AIs best suited for them
4. **Resilience**: If one AI is busy, others can take over
5. **Scalability**: Easy to add new AIs or change specialties

## Integration

The smart selector integrates with:
- `claim_task.sh` - Auto-selects if no AI specified
- `claim_task_v2.sh` - Same auto-selection
- `task_coordinator.sh` - Load balancing
- `orchestrator.sh` - Automated task execution

## Example Workflow

```bash
# 1. View current recommendations
bash smart_task_selector.sh recommend

Output:
[gemini]
  Best match: Task #16 - Design Firebase Schema (score: 100)

[chatgpt]
  Best match: Task #9 - Write Story Arc (score: 95)

# 2. Claim task (auto-selects best AI)
bash claim_task.sh 16

Output:
Auto-selected best AI: gemini
Task #16 claimed by gemini

# 3. Or reassign all at once
bash smart_task_selector.sh reassign

Output:
Task #16: Design Firebase Schema -> gemini
Task #9: Write Story Arc -> chatgpt
Task #17: System Documentation -> copilot
Reassigned 3 tasks
```

## Configuration

To modify AI specialties, edit `TASK_QUEUE.json`:

```json
{
  "ai_agents": [
    {
      "name": "gemini",
      "role": "Firebase & Cloud Expert",
      "specialties": [
        "firebase",
        "google_cloud",
        "database_design"
      ],
      "status": "active"
    }
  ]
}
```

The smart selector automatically reads and uses these specialties.

## Advanced Features

### Priority Overrides

Tasks can still include `suggested_ai` field for hints:

```json
{
  "id": 16,
  "title": "Firebase Schema",
  "suggested_ai": "gemini"
}
```

But any AI can be manually assigned if needed.

### Workload Awareness

The system tracks:
- `in_progress` tasks in TASK_QUEUE.json
- Active locks in `locks/` directory
- Combines both for total workload

This prevents overloading any single AI.

## Migration from Fixed Assignments

Old system:
```json
{
  "id": 16,
  "assigned_to": "gemini",  // Fixed assignment
  "status": "pending"
}
```

New system:
```json
{
  "id": 16,
  "assigned_to": "pending",  // Assigned dynamically when claimed
  "status": "pending"
}
```

Run `bash smart_task_selector.sh reassign` to update all pending tasks.
