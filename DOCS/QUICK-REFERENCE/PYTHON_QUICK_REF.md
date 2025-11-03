# Python Modules Quick Reference

## Quick Start

```bash
# Create new project (uses Python planning wizard)
orkestra new my-project

# Or skip planning wizard
orkestra new my-project --skip-planning
```

## Import Reference

```python
# Committee (Democratic Voting)
from orkestra.committee import Committee, Vote, VoteOption

# Tasks (Task Management)
from orkestra.tasks import TaskQueue, Task, TaskStatus, TaskPriority

# Planning (Project Planning)
from orkestra.planning import ProjectPlanner
```

---

## Committee Module

### Create Vote
```python
committee = Committee("/path/to/project")

vote_id = committee.create_vote(
    topic="Choose database",
    options=["PostgreSQL", "MongoDB", "SQLite"],
    context="Need persistence for web app"
)
```

### Process Vote
```python
result = committee.process_vote(vote_id, max_rounds=5)

print(result['decision'])        # "PostgreSQL"
print(result['consensus_level']) # "unanimous"
print(result['rounds'])          # 3
```

### With User Feedback
```python
def get_feedback():
    return input("Your thoughts: ")

result = committee.process_vote(
    vote_id,
    user_feedback_callback=get_feedback
)
```

### Gather Context
```python
context = committee.gather_context(
    query="authentication security",
    max_results=10
)
```

---

## Tasks Module

### Add Task
```python
queue = TaskQueue("/path/to/project")

task_id = queue.add_task(
    description="Implement user login",
    priority=TaskPriority.HIGH,
    category="auth",
    dependencies=["setup-database"],
    metadata={"estimate": "4h"}
)
```

### Update Task
```python
queue.update_task(
    task_id,
    status=TaskStatus.IN_PROGRESS,
    assigned_to="claude"
)
```

### Get Next Task
```python
# Get highest priority ready task
task = queue.get_next_task()

# Filter by category
task = queue.get_next_task(category="auth")

# Filter by assignee
task = queue.get_next_task(assigned_to="claude")
```

### Check Dependencies
```python
if queue.check_dependencies(task_id):
    print("Ready to start")
else:
    print("Waiting on dependencies")
```

### Get Statistics
```python
stats = queue.get_statistics()

print(f"Total: {stats['total']}")
print(f"Completed: {stats['by_status']['completed']}")
print(f"High Priority: {stats['by_priority']['high']}")
print(f"Completion Rate: {stats['completion_rate']}%")
```

### List Tasks
```python
# All tasks
all_tasks = queue.list_tasks()

# By status
pending = queue.list_tasks(status=TaskStatus.PENDING)

# By priority
critical = queue.list_tasks(priority=TaskPriority.CRITICAL)

# By category
auth_tasks = queue.list_tasks(category="auth")
```

---

## Planning Module

### Run Planning Wizard
```python
planner = ProjectPlanner("/path/to/project", "my-project")
planner.run_planning_wizard()
```

### Programmatic Planning
```python
# Step 1: Collect info
project_info = {
    "description": "E-commerce platform",
    "involvement": 2,  # 1=minimal, 2=moderate, 3=maximum
    "features": ["user-auth", "payment", "cart", "search"]
}

# Step 2: Run AI rounds
plan = planner._ai_planning_rounds(project_info)

# Step 3: Generate tasks
planner._generate_tasks(plan, project_info)
```

---

## Common Patterns

### Task Workflow
```python
queue = TaskQueue(".")

# Add tasks with dependencies
setup = queue.add_task("Setup project", priority=TaskPriority.HIGH)
db = queue.add_task("Configure DB", dependencies=[setup])
auth = queue.add_task("Implement auth", dependencies=[db])

# Process queue
while True:
    task = queue.get_next_task()
    if not task:
        break
    
    print(f"Working on: {task.description}")
    queue.update_task(task.id, status=TaskStatus.IN_PROGRESS)
    
    # ... do work ...
    
    queue.update_task(task.id, status=TaskStatus.COMPLETED)
```

### Democratic Decision
```python
committee = Committee(".")

# Create vote with context
context = committee.gather_context("authentication methods")
vote_id = committee.create_vote(
    topic="Choose auth method",
    options=["JWT", "Sessions", "OAuth2"],
    context=context
)

# Process until consensus
result = committee.process_vote(vote_id)

# Record outcome
committee.create_outcome(
    vote_id,
    result['decision'],
    result['reasoning']
)
```

### Complete Project Setup
```python
# 1. Create project structure
planner = ProjectPlanner(".", "my-project")

# 2. Run planning (includes voting)
planner.run_planning_wizard()
# User interaction:
# - Describes project
# - Chooses involvement level
# - Lists features
# - Reviews AI voting rounds
# - Approves final plan

# 3. Tasks automatically created and ready
queue = TaskQueue(".")
first_task = queue.get_next_task()
print(f"Start with: {first_task.description}")
```

---

## Data Classes

### Vote
```python
@dataclass
class Vote:
    vote_id: str                    # "vote_abc123"
    topic: str                      # "Choose database"
    options: List[VoteOption]       # Available choices
    context: str                    # Background info
    rounds: List[dict]              # Voting history
    agents_required: List[str]      # ["claude", "chatgpt", ...]
    created_at: str                 # ISO timestamp
    updated_at: str                 # ISO timestamp
```

### Task
```python
@dataclass
class Task:
    id: str                         # "task_xyz789"
    description: str                # "Implement feature X"
    priority: TaskPriority          # CRITICAL/HIGH/MEDIUM/LOW
    category: str                   # "auth", "payment", etc.
    status: TaskStatus              # PENDING/IN_PROGRESS/etc.
    dependencies: List[str]         # ["task_abc", "task_def"]
    assigned_to: Optional[str]      # "claude" or None
    metadata: dict                  # Custom fields
    created_at: str                 # ISO timestamp
    updated_at: str                 # ISO timestamp
    completed_at: Optional[str]     # ISO timestamp or None
```

---

## Enums

### TaskStatus
```python
TaskStatus.PENDING       # Not started
TaskStatus.IN_PROGRESS   # Being worked on
TaskStatus.COMPLETED     # Finished
TaskStatus.FAILED        # Error occurred
TaskStatus.BLOCKED       # Waiting on something
TaskStatus.CANCELLED     # No longer needed
```

### TaskPriority
```python
TaskPriority.CRITICAL    # Urgent, must do now
TaskPriority.HIGH        # Important, do soon
TaskPriority.MEDIUM      # Normal priority
TaskPriority.LOW         # Can wait
```

---

## File Locations

```
project-root/
├── orkestra/
│   ├── logs/
│   │   ├── voting/
│   │   │   └── vote_abc123.json
│   │   └── outcomes/
│   │       └── vote_abc123-outcome.json
│   └── task-queue.json
```

---

## Error Handling

### Graceful Degradation
```python
try:
    task_id = queue.add_task("Description")
except Exception as e:
    logger.error(f"Failed to add task: {e}")
    # Fallback behavior
```

### Validation
```python
# Tasks validates automatically
try:
    queue.add_task("", priority=TaskPriority.HIGH)
except ValueError as e:
    print(e)  # "Description cannot be empty"
```

---

## Integration Examples

### With Git
```python
import subprocess

# Get current branch
branch = subprocess.run(
    ["git", "rev-parse", "--abbrev-ref", "HEAD"],
    capture_output=True,
    text=True
).stdout.strip()

# Create feature task
queue.add_task(
    f"Implement feature on {branch}",
    metadata={"branch": branch}
)
```

### With CI/CD
```python
# Check if ready for deployment
stats = queue.get_statistics()
if stats['completion_rate'] == 100:
    print("✅ All tasks complete, ready to deploy")
else:
    pending = stats['by_status']['pending']
    print(f"⚠️ {pending} tasks remaining")
```

---

## Testing Tips

### Unit Tests
```python
def test_add_task():
    queue = TaskQueue("/tmp/test")
    task_id = queue.add_task("Test task")
    task = queue.get_task(task_id)
    assert task is not None
    assert task.description == "Test task"
```

### Mock Committee
```python
from unittest.mock import MagicMock

committee = Committee(".")
committee._call_claude = MagicMock(return_value="Option A")
committee._call_chatgpt = MagicMock(return_value="Option A")
# ... etc
```

---

## Performance Tips

### Batch Operations
```python
# Bad: Many small operations
for desc in descriptions:
    queue.add_task(desc)

# Good: Add all, then save once
for desc in descriptions:
    # Implementation detail: queue batches writes
    queue.add_task(desc)
```

### Filter Early
```python
# Bad: Load all, filter in Python
all_tasks = queue.list_tasks()
auth_tasks = [t for t in all_tasks if t.category == "auth"]

# Good: Filter in query
auth_tasks = queue.list_tasks(category="auth")
```

---

## Debugging

### Enable Logging
```python
import logging
logging.basicConfig(level=logging.DEBUG)

# Now see detailed operations
committee = Committee(".")
committee.process_vote(vote_id)  # Logs each step
```

### Inspect Vote
```python
vote = committee.get_vote(vote_id)
print(f"Rounds: {len(vote.rounds)}")
print(f"Options: {[o.description for o in vote.options]}")
for round_num, round_data in enumerate(vote.rounds, 1):
    print(f"Round {round_num}: {round_data}")
```

### Inspect Task
```python
task = queue.get_task(task_id)
print(f"Status: {task.status}")
print(f"Dependencies: {task.dependencies}")
print(f"Ready: {queue.check_dependencies(task_id)}")
```

---

## Migration from Bash

### Bash Command → Python Equivalent

```bash
# Bash
./SCRIPTS/COMMITTEE/process-vote.sh vote_123
```
```python
# Python
committee = Committee(".")
result = committee.process_vote("vote_123")
```

```bash
# Bash
./SCRIPTS/TASK-MANAGEMENT/add-task.sh "Description" "high"
```
```python
# Python
queue = TaskQueue(".")
queue.add_task("Description", priority=TaskPriority.HIGH)
```

```bash
# Bash
./SCRIPTS/CORE/project-planning.sh
```
```python
# Python
planner = ProjectPlanner(".", "project-name")
planner.run_planning_wizard()
```

---

## FAQ

**Q: Do I need to install dependencies?**
```bash
pip install -e .  # Installs orkestra package with all deps
```

**Q: Where are files stored?**
- Votes: `orkestra/logs/voting/{vote_id}.json`
- Tasks: `orkestra/task-queue.json`
- Outcomes: `orkestra/logs/outcomes/{vote_id}-outcome.json`

**Q: Can I use bash and Python together?**
Yes, they share the same JSON file formats.

**Q: How do I add custom metadata to tasks?**
```python
queue.add_task(
    "Task description",
    metadata={
        "custom_field": "value",
        "estimate": "4h",
        "tags": ["important", "backend"]
    }
)
```

**Q: How do I cancel a task?**
```python
queue.update_task(task_id, status=TaskStatus.CANCELLED)
```

**Q: How do I see all failed tasks?**
```python
failed = queue.list_tasks(status=TaskStatus.FAILED)
for task in failed:
    print(f"Failed: {task.description}")
```

---

## Cheat Sheet

```python
# COMMITTEE
committee = Committee(".")
vote_id = committee.create_vote(topic, options, context)
result = committee.process_vote(vote_id)
context = committee.gather_context(query)

# TASKS
queue = TaskQueue(".")
task_id = queue.add_task(desc, priority=TaskPriority.HIGH)
queue.update_task(task_id, status=TaskStatus.COMPLETED)
task = queue.get_next_task(category="auth")
ready = queue.check_dependencies(task_id)
stats = queue.get_statistics()

# PLANNING
planner = ProjectPlanner(".", "project-name")
planner.run_planning_wizard()

# ENUMS
TaskStatus.PENDING | IN_PROGRESS | COMPLETED | FAILED | BLOCKED | CANCELLED
TaskPriority.CRITICAL | HIGH | MEDIUM | LOW
```

---

For complete documentation, see `DOCS/TECHNICAL/PYTHON_MODULES.md`
