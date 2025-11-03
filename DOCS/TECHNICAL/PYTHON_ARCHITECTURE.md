# Orkestra Python Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        User Interface                            │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  CLI Commands   │  │  Rich Terminal  │  │  Interactive    │ │
│  │  orkestra new   │  │  UI Components  │  │  Prompts        │ │
│  │  orkestra start │  │  Panels/Tables  │  │  User Feedback  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                     Python Core Modules                          │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    planning.py                            │  │
│  │  ┌────────────────────────────────────────────────────┐  │  │
│  │  │  ProjectPlanner                                     │  │  │
│  │  │  • run_planning_wizard()                           │  │  │
│  │  │  • _collect_project_info()                         │  │  │
│  │  │  • _ai_planning_rounds()                          │  │  │
│  │  │  • _present_final_plan()                          │  │  │
│  │  │  • _generate_tasks()                              │  │  │
│  │  └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                   │
│  ┌──────────────────────────┐  ┌──────────────────────────┐   │
│  │    committee.py          │  │       tasks.py           │   │
│  │  ┌────────────────────┐  │  │  ┌────────────────────┐  │   │
│  │  │  Committee         │  │  │  │  TaskQueue         │  │   │
│  │  │  • create_vote()   │  │  │  │  • add_task()      │  │   │
│  │  │  • process_vote()  │  │  │  │  • get_next_task() │  │   │
│  │  │  • gather_context()│  │  │  │  • update_task()   │  │   │
│  │  │                    │  │  │  │  • check_deps()    │  │   │
│  │  │  Vote, VoteOption  │  │  │  │  • get_stats()     │  │   │
│  │  │  Agent dataclasses │  │  │  │  Task dataclass    │  │   │
│  │  └────────────────────┘  │  │  └────────────────────┘  │   │
│  └──────────────────────────┘  └──────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    AI Agents Layer (Future)                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐│
│  │  Claude  │ │ ChatGPT  │ │  Gemini  │ │ Copilot  │ │ Grok ││
│  │Anthropic │ │  OpenAI  │ │  Google  │ │  GitHub  │ │ xAI  ││
│  │   API    │ │   API    │ │   API    │ │   API    │ │ API  ││
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────┘│
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Data Persistence                            │
│  ┌───────────────────┐  ┌───────────────────┐  ┌────────────┐ │
│  │  Votes            │  │  Tasks            │  │  Outcomes  │ │
│  │  orkestra/logs/   │  │  orkestra/        │  │  orkestra/ │ │
│  │  voting/          │  │  task-queue.json  │  │  logs/     │ │
│  │  {vote_id}.json   │  │                   │  │  outcomes/ │ │
│  └───────────────────┘  └───────────────────┘  └────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Relationships

### planning.py orchestrates committee.py and tasks.py

```
ProjectPlanner.run_planning_wizard()
    │
    ├─→ Committee.create_vote()
    │       └─→ Vote stored to JSON
    │
    ├─→ Committee.process_vote()
    │       ├─→ Call 5 AI agents
    │       ├─→ Check consensus
    │       └─→ User feedback loop
    │
    ├─→ Committee.create_outcome()
    │       └─→ Outcome stored to JSON
    │
    └─→ TaskQueue.add_task() × N
            └─→ Tasks stored to JSON
```

---

## Data Flow

### 1. Project Creation Flow

```
User: orkestra new my-project
    ↓
CLI: cli.py::new()
    ↓
Core: OrkestraProject.create()
    ↓
Planning: ProjectPlanner.run_planning_wizard()
    ↓
    ├─→ Collect user input
    │   ├─→ Project description
    │   ├─→ Involvement level (1-3)
    │   └─→ Features list
    │
    ├─→ Create planning vote
    │   └─→ Committee.create_vote()
    │       └─→ JSON: orkestra/logs/voting/{vote_id}.json
    │
    ├─→ AI planning rounds
    │   └─→ Committee.process_vote()
    │       ├─→ Round 1: Initial proposals
    │       ├─→ User feedback
    │       ├─→ Round 2: Refined proposals
    │       ├─→ User feedback
    │       └─→ ... until consensus
    │
    ├─→ Present final plan
    │   └─→ User approves/modifies/rejects
    │
    ├─→ Generate tasks
    │   └─→ TaskQueue.add_task() × N
    │       ├─→ Phase 1: Foundation (4 tasks)
    │       ├─→ Phase 2: Core Features (N tasks)
    │       ├─→ Phase 3: Integration (4 tasks)
    │       └─→ Phase 4: Deployment (4 tasks)
    │
    └─→ JSON: orkestra/task-queue.json
```

### 2. Task Execution Flow (Future)

```
Worker: Get next task
    ↓
TaskQueue.get_next_task()
    ├─→ Filter: status=PENDING
    ├─→ Check: dependencies met
    ├─→ Sort: by priority
    └─→ Return: highest priority ready task
    ↓
Update: status=IN_PROGRESS
    ↓
Execute: AI agent processes task
    ↓
Update: status=COMPLETED
    ↓
Move to next task
```

### 3. Democratic Voting Flow

```
Decision needed
    ↓
Committee.create_vote(topic, options, context)
    ↓
Vote record created
    ├─→ vote_id: unique identifier
    ├─→ options: List[VoteOption]
    ├─→ rounds: []
    └─→ agents_required: [claude, chatgpt, gemini, copilot, grok]
    ↓
Committee.process_vote(vote_id)
    ↓
Round 1:
    ├─→ Call each agent with context
    ├─→ Collect votes and reasoning
    ├─→ Check consensus
    ├─→ If not unanimous: continue
    │
Round 2:
    ├─→ Include previous round results
    ├─→ Optional: collect user feedback
    ├─→ Call each agent again
    ├─→ Check consensus
    ├─→ If not unanimous: continue
    │
Round N (max 5):
    ├─→ Final voting round
    ├─→ Determine consensus level:
    │   ├─→ unanimous (100% agree)
    │   ├─→ strong (80%+ agree)
    │   └─→ split (<80% agree)
    └─→ Return decision
    ↓
Committee.create_outcome(vote_id, decision, reasoning)
    └─→ JSON: orkestra/logs/outcomes/{vote_id}-outcome.json
```

---

## File Structure

```
/Users/hendrixx./Desktop/Orkestra/
│
├── src/orkestra/                    # Python package
│   ├── __init__.py
│   ├── cli.py                       # Command-line interface
│   ├── config.py                    # Configuration management
│   ├── core.py                      # Core project management
│   ├── committee.py                 # ✨ NEW: Democratic voting
│   ├── tasks.py                     # ✨ NEW: Task management
│   ├── planning.py                  # ✨ NEW: Project planning
│   └── templates/                   # Project templates
│
├── SCRIPTS/                         # Bash scripts (being replaced)
│   ├── AGENTS/                      # → agents.py (future)
│   ├── AUTOMATION/                  # → automation.py (future)
│   ├── COMMITTEE/                   # → committee.py ✅
│   ├── CORE/                        # → planning.py ✅
│   ├── DEMOCRACY/                   # → democracy.py (future)
│   ├── MAINTENANCE/                 # → maintenance.py (future)
│   ├── MONITORING/                  # → monitoring.py (future)
│   ├── SAFETY/                      # → safety.py (future)
│   ├── TASK-MANAGEMENT/             # → tasks.py ✅
│   └── UTILS/                       # → utils.py (future)
│
├── DOCS/
│   ├── TECHNICAL/
│   │   ├── PYTHON_MODULES.md        # ✨ Complete API reference
│   │   ├── BASH_TO_PYTHON_ROADMAP.md # ✨ Conversion plan
│   │   └── PYTHON_MIGRATION_SUMMARY.md # ✨ Status update
│   └── QUICK-REFERENCE/
│       └── PYTHON_QUICK_REF.md      # ✨ Cheat sheet
│
├── orkestra/                        # Project data directory
│   ├── logs/
│   │   ├── voting/                  # Vote records
│   │   │   └── vote_*.json
│   │   └── outcomes/                # Decision outcomes
│   │       └── vote_*-outcome.json
│   └── task-queue.json              # Task queue
│
└── PYTHON_INTEGRATION_COMPLETE.md   # ✨ This summary
```

---

## Class Hierarchy

### committee.py Classes

```python
@dataclass
class Agent:
    name: str                        # "claude", "chatgpt", etc.
    description: str                 # Agent capabilities
    status: str                      # "active", "inactive"

@dataclass
class VoteOption:
    id: str                          # "option_1", "option_2", etc.
    description: str                 # Option text
    votes: List[str]                 # Agent IDs that voted for this
    reasoning: Dict[str, str]        # {agent_id: reasoning}

@dataclass
class Vote:
    vote_id: str                     # Unique identifier
    topic: str                       # Question/decision
    options: List[VoteOption]        # Available choices
    context: str                     # Background information
    rounds: List[dict]               # Voting history
    agents_required: List[str]       # Which agents participate
    created_at: str                  # ISO timestamp
    updated_at: str                  # ISO timestamp

class Committee:
    AGENTS: List[Agent]              # 5 AI agents
    
    def create_vote(...)             # Create voting session
    def process_vote(...)            # Execute voting rounds
    def gather_context(...)          # Search for information
    def create_outcome(...)          # Record decision
    def list_votes(...)              # List all votes
    def get_vote(...)                # Get specific vote
    
    # Internal methods
    def _call_agent(...)             # Call individual agent
    def _check_consensus(...)        # Determine agreement level
    def _call_claude(...)            # Claude API stub
    def _call_chatgpt(...)           # ChatGPT API stub
    def _call_gemini(...)            # Gemini API stub
    def _call_copilot(...)           # Copilot API stub
    def _call_grok(...)              # Grok API stub
```

### tasks.py Classes

```python
class TaskStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"

class TaskPriority(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

@dataclass
class Task:
    id: str                          # Unique identifier
    description: str                 # What to do
    priority: TaskPriority           # Importance
    category: str                    # Grouping
    status: TaskStatus               # Current state
    dependencies: List[str]          # Required tasks
    assigned_to: Optional[str]       # Agent working on it
    metadata: dict                   # Custom fields
    created_at: str                  # ISO timestamp
    updated_at: str                  # ISO timestamp
    completed_at: Optional[str]      # ISO timestamp

class TaskQueue:
    def add_task(...)                # Create task
    def update_task(...)             # Modify task
    def get_task(...)                # Retrieve task
    def get_next_task(...)           # Find ready task
    def list_tasks(...)              # List tasks
    def check_dependencies(...)      # Validate deps
    def get_statistics(...)          # Queue analytics
    def clear_completed(...)         # Cleanup
    
    # Internal methods
    def _load_queue(...)             # Read JSON
    def _save_queue(...)             # Write JSON
    def _generate_task_id(...)       # Create unique ID
    def is_ready(...)                # Check if task can start
```

### planning.py Classes

```python
class ProjectPlanner:
    def __init__(
        project_root: Path,
        project_name: str
    )
    
    def run_planning_wizard(...)     # Main entry point
    
    # Internal workflow methods
    def _collect_project_info(...)   # User input
    def _ai_planning_rounds(...)     # Voting process
    def _create_planning_vote(...)   # Initialize vote
    def _show_round_results(...)     # Display votes
    def _get_user_feedback(...)      # Collect input
    def _present_final_plan(...)     # Show plan
    def _generate_tasks(...)         # Create task breakdown
    def _create_outcome(...)         # Record plan
```

---

## API Examples

### Creating a Vote

```python
from orkestra.committee import Committee

committee = Committee("/path/to/project")

# Simple vote
vote_id = committee.create_vote(
    topic="Choose database",
    options=["PostgreSQL", "MongoDB", "SQLite"]
)

# Vote with context
vote_id = committee.create_vote(
    topic="Choose database",
    options=["PostgreSQL", "MongoDB", "SQLite"],
    context="Need ACID compliance and JSON support"
)

# Vote with specific agents
vote_id = committee.create_vote(
    topic="Choose database",
    options=["PostgreSQL", "MongoDB", "SQLite"],
    agents=["claude", "chatgpt", "gemini"]  # Only 3 agents
)
```

### Processing a Vote

```python
# Simple processing
result = committee.process_vote(vote_id)

# With max rounds limit
result = committee.process_vote(vote_id, max_rounds=3)

# With user feedback
def collect_feedback():
    return input("Your thoughts: ")

result = committee.process_vote(
    vote_id,
    max_rounds=5,
    user_feedback_callback=collect_feedback
)

# Check result
print(f"Decision: {result['decision']}")
print(f"Consensus: {result['consensus_level']}")
print(f"Rounds: {result['rounds']}")
print(f"Reasoning: {result['reasoning']}")
```

### Managing Tasks

```python
from orkestra.tasks import TaskQueue, TaskPriority, TaskStatus

queue = TaskQueue("/path/to/project")

# Add tasks
setup_id = queue.add_task(
    "Set up project",
    priority=TaskPriority.HIGH
)

db_id = queue.add_task(
    "Configure database",
    priority=TaskPriority.HIGH,
    dependencies=[setup_id]
)

# Get next ready task
task = queue.get_next_task()
if task:
    print(f"Working on: {task.description}")
    queue.update_task(task.id, status=TaskStatus.IN_PROGRESS)
    
    # ... do work ...
    
    queue.update_task(task.id, status=TaskStatus.COMPLETED)

# Check progress
stats = queue.get_statistics()
print(f"Completion: {stats['completion_rate']}%")
```

### Running Planning Wizard

```python
from orkestra.planning import ProjectPlanner

planner = ProjectPlanner("/path/to/project", "my-project")

# Interactive wizard
planner.run_planning_wizard()
# → Prompts user for info
# → Creates vote with AI agents
# → Runs voting rounds
# → Generates tasks automatically
```

---

## Integration Points

### CLI → Modules

```python
# cli.py
@main.command()
def new(project_name: str):
    project = OrkestraProject.create(project_name, path)
    planner = ProjectPlanner(path, project_name)
    planner.run_planning_wizard()
```

### Planning → Committee

```python
# planning.py
class ProjectPlanner:
    def _ai_planning_rounds(self, project_info: dict):
        committee = Committee(self.project_root)
        vote_id = committee.create_vote(topic, options, context)
        result = committee.process_vote(vote_id, max_rounds=5)
        return result
```

### Planning → Tasks

```python
# planning.py
class ProjectPlanner:
    def _generate_tasks(self, plan: dict, project_info: dict):
        queue = TaskQueue(self.project_root)
        
        # Foundation tasks
        for task in foundation_tasks:
            queue.add_task(task, priority=TaskPriority.HIGH)
        
        # Feature tasks
        for feature in project_info['features']:
            queue.add_task(f"Implement {feature}", ...)
```

---

## Testing Strategy

### Unit Tests

```python
# Test committee
def test_create_vote():
    committee = Committee("/tmp/test")
    vote_id = committee.create_vote("Topic", ["A", "B"])
    assert vote_id.startswith("vote_")

# Test tasks
def test_add_task():
    queue = TaskQueue("/tmp/test")
    task_id = queue.add_task("Test task")
    task = queue.get_task(task_id)
    assert task.description == "Test task"

# Test dependencies
def test_dependencies():
    queue = TaskQueue("/tmp/test")
    task1 = queue.add_task("Task 1")
    task2 = queue.add_task("Task 2", dependencies=[task1])
    
    assert not queue.check_dependencies(task2)
    queue.update_task(task1, status=TaskStatus.COMPLETED)
    assert queue.check_dependencies(task2)
```

### Integration Tests

```python
# Test full workflow
def test_planning_workflow():
    planner = ProjectPlanner("/tmp/test", "test")
    
    # Mock user inputs
    with mock_inputs(["Description", "2", "feature1,feature2"]):
        planner.run_planning_wizard()
    
    # Verify tasks created
    queue = TaskQueue("/tmp/test")
    stats = queue.get_statistics()
    assert stats['total'] > 0
```

---

## Performance Characteristics

### Committee Module
- **create_vote():** O(1) - Simple data structure creation
- **process_vote():** O(n × m) where n=rounds, m=agents
- **gather_context():** O(k) where k=search results

### Tasks Module
- **add_task():** O(1) - Append to list
- **get_next_task():** O(n log n) - Sort by priority
- **check_dependencies():** O(d) where d=dependency count
- **get_statistics():** O(n) - Single pass through tasks

### Planning Module
- **run_planning_wizard():** Dominated by AI calls (network I/O)
- **_generate_tasks():** O(f) where f=features count

---

## Memory Usage

- **Vote object:** ~1KB per vote
- **Task object:** ~500 bytes per task
- **Task queue:** ~50KB for 100 tasks
- **Total typical project:** <1MB

---

## Concurrency Model

### Current (Synchronous)
```python
# Blocking calls
result = committee.process_vote(vote_id)
task = queue.get_next_task()
```

### Future (Async)
```python
# Non-blocking with asyncio
result = await committee.process_vote(vote_id)
tasks = await asyncio.gather(*[
    agent.call(prompt) for agent in agents
])
```

---

## Error Handling

### Committee Errors
- `VoteNotFoundError`: Vote ID doesn't exist
- `InvalidVoteError`: Malformed vote data
- `ConsensusFailureError`: No consensus after max rounds
- `AgentError`: AI agent call failed

### Task Errors
- `TaskNotFoundError`: Task ID doesn't exist
- `DependencyError`: Dependency not satisfied
- `InvalidStatusError`: Invalid status transition
- `InvalidPriorityError`: Invalid priority value

### Planning Errors
- `PlanningAbortedError`: User rejected plan
- `InvalidInputError`: User provided invalid data
- `VotingError`: Voting process failed

---

## Security Considerations

### Input Validation
- All user inputs sanitized
- Task descriptions length-limited
- Dependencies validated to prevent cycles
- Priority and status validated against enums

### File Operations
- Atomic writes to prevent corruption
- JSON validation before parsing
- Path traversal prevention
- Proper file permissions

### API Keys
- Never logged or displayed
- Read from secure config
- Environment variable support
- Key rotation supported

---

*Architecture documentation for Orkestra Python modules*
*Last updated: 2024*
*Version: 1.0 (30% migration complete)*
