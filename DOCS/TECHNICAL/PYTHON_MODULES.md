# Python Modules Documentation

## Overview
This document describes the Python modules that form the core of Orkestra's functionality, replacing the original bash scripts with type-safe, programmatic APIs.

## Architecture

```
src/orkestra/
├── __init__.py          # Package initialization
├── cli.py               # Command-line interface
├── config.py            # Configuration management
├── core.py              # Core project management
├── committee.py         # Democratic voting system (NEW)
├── tasks.py             # Task queue management (NEW)
└── planning.py          # Project planning wizard (NEW)
```

## Module: committee.py

### Purpose
Manages democratic AI voting system with 5 agents (Claude, ChatGPT, Gemini, Copilot, Grok). Replaces bash scripts in `SCRIPTS/COMMITTEE/`.

### Key Classes

#### Committee
Main orchestrator for democratic voting and consensus building.

```python
from orkestra.committee import Committee

# Initialize
committee = Committee(project_root="/path/to/project")

# Create a vote
vote_id = committee.create_vote(
    topic="Choose architecture pattern",
    options=["MVC", "Clean Architecture", "Hexagonal"],
    context="Building a web application"
)

# Process vote (runs through all 5 AI agents)
result = committee.process_vote(vote_id)

# Check result
print(f"Decision: {result['decision']}")
print(f"Consensus: {result['consensus_level']}")  # unanimous/strong/split
```

#### Vote (Dataclass)
Represents a voting session.

```python
@dataclass
class Vote:
    vote_id: str                    # Unique identifier
    topic: str                      # Question to vote on
    options: List[VoteOption]       # Available choices
    context: str                    # Background information
    rounds: List[dict]              # History of voting rounds
    agents_required: List[str]      # Which agents participate
    created_at: str                 # ISO timestamp
    updated_at: str                 # ISO timestamp
```

#### VoteOption (Dataclass)
Represents a voting choice.

```python
@dataclass
class VoteOption:
    id: str                         # Unique option ID
    description: str                # Option text
    votes: List[str]                # Agent IDs that voted for this
    reasoning: Dict[str, str]       # Agent reasoning
```

### Key Methods

#### create_vote()
```python
def create_vote(
    topic: str,
    options: List[str],
    context: str = "",
    agents: Optional[List[str]] = None
) -> str:
    """
    Create a new voting session.
    
    Args:
        topic: The question/decision to vote on
        options: List of available choices
        context: Background info for decision
        agents: Specific agents to include (default: all 5)
        
    Returns:
        vote_id: Unique identifier for tracking
    """
```

#### process_vote()
```python
def process_vote(
    vote_id: str,
    max_rounds: int = 5,
    user_feedback_callback: Optional[Callable] = None
) -> dict:
    """
    Execute voting rounds until consensus.
    
    Args:
        vote_id: The vote to process
        max_rounds: Maximum voting iterations
        user_feedback_callback: Optional function to collect user input
        
    Returns:
        dict with keys:
        - decision: Final choice
        - consensus_level: unanimous/strong/split
        - rounds: Number of rounds taken
        - reasoning: Aggregated agent explanations
    """
```

#### gather_context()
```python
def gather_context(query: str, max_results: int = 10) -> str:
    """
    Search workspace for relevant information.
    
    Uses:
    - Git history (commits, branches, tags)
    - Grep search across codebase
    - README and documentation files
    
    Args:
        query: Search terms
        max_results: Max items to return
        
    Returns:
        Formatted context string
    """
```

### File Locations
- Votes: `orkestra/logs/voting/{vote_id}.json`
- Outcomes: `orkestra/logs/outcomes/{vote_id}-outcome.json`

### Agent Integration
Currently uses stub methods. Future integration points:

```python
# Claude (Anthropic)
def _call_claude(self, prompt: str) -> str:
    # TODO: Implement Anthropic API
    # API Key from CONFIG/api-keys.env
    pass

# ChatGPT (OpenAI)
def _call_chatgpt(self, prompt: str) -> str:
    # TODO: Implement OpenAI API
    pass

# Gemini (Google)
def _call_gemini(self, prompt: str) -> str:
    # TODO: Implement Google AI API
    pass

# Copilot (GitHub)
def _call_copilot(self, prompt: str) -> str:
    # TODO: Implement GitHub Copilot API
    pass

# Grok (xAI)
def _call_grok(self, prompt: str) -> str:
    # TODO: Implement xAI API
    pass
```

---

## Module: tasks.py

### Purpose
Manages task queue with dependencies, priorities, and lifecycle tracking. Replaces bash scripts in `SCRIPTS/TASK-MANAGEMENT/`.

### Key Classes

#### TaskQueue
Main task management system.

```python
from orkestra.tasks import TaskQueue, TaskPriority, TaskStatus

# Initialize
queue = TaskQueue(project_root="/path/to/project")

# Add task
task_id = queue.add_task(
    description="Implement user authentication",
    priority=TaskPriority.HIGH,
    category="security",
    dependencies=["setup-database"],
    metadata={"estimate": "4 hours"}
)

# Update task
queue.update_task(
    task_id,
    status=TaskStatus.IN_PROGRESS,
    assigned_to="claude"
)

# Get next task to work on
next_task = queue.get_next_task()
if next_task:
    print(f"Next: {next_task.description}")
```

#### Task (Dataclass)
Represents a work item.

```python
@dataclass
class Task:
    id: str                         # Unique identifier
    description: str                # What needs to be done
    priority: TaskPriority          # LOW/MEDIUM/HIGH/CRITICAL
    category: str                   # Group tasks by type
    status: TaskStatus              # Current state
    dependencies: List[str]         # Task IDs that must complete first
    assigned_to: Optional[str]      # Agent working on it
    metadata: dict                  # Custom fields
    created_at: str                 # ISO timestamp
    updated_at: str                 # ISO timestamp
    completed_at: Optional[str]     # ISO timestamp when done
```

#### Enums
```python
class TaskStatus(Enum):
    PENDING = "pending"             # Not started
    IN_PROGRESS = "in_progress"     # Being worked on
    COMPLETED = "completed"         # Finished
    FAILED = "failed"               # Error occurred
    BLOCKED = "blocked"             # Waiting on something
    CANCELLED = "cancelled"         # No longer needed

class TaskPriority(Enum):
    LOW = "low"                     # Can wait
    MEDIUM = "medium"               # Normal priority
    HIGH = "high"                   # Important
    CRITICAL = "critical"           # Urgent
```

### Key Methods

#### add_task()
```python
def add_task(
    description: str,
    priority: TaskPriority = TaskPriority.MEDIUM,
    category: str = "general",
    dependencies: Optional[List[str]] = None,
    assigned_to: Optional[str] = None,
    metadata: Optional[dict] = None
) -> str:
    """
    Add a new task to the queue.
    
    Args:
        description: What needs to be done
        priority: Importance level
        category: Task grouping
        dependencies: Tasks that must complete first
        assigned_to: Agent responsible
        metadata: Custom key-value data
        
    Returns:
        task_id: Unique identifier
    """
```

#### get_next_task()
```python
def get_next_task(
    category: Optional[str] = None,
    assigned_to: Optional[str] = None
) -> Optional[Task]:
    """
    Find the highest priority task that's ready to work on.
    
    Logic:
    1. Filter by status=PENDING
    2. Check dependencies are met
    3. Filter by category if specified
    4. Filter by assigned_to if specified
    5. Sort by priority (CRITICAL > HIGH > MEDIUM > LOW)
    6. Return first match
    
    Args:
        category: Only return tasks in this category
        assigned_to: Only return tasks for this agent
        
    Returns:
        Task object or None if nothing available
    """
```

#### check_dependencies()
```python
def check_dependencies(task_id: str) -> bool:
    """
    Verify all dependencies are completed.
    
    Args:
        task_id: Task to check
        
    Returns:
        True if all dependencies done, False otherwise
    """
```

#### get_statistics()
```python
def get_statistics(self) -> dict:
    """
    Get queue analytics.
    
    Returns:
        dict with keys:
        - total: Total tasks
        - by_status: Count per status
        - by_priority: Count per priority
        - by_category: Count per category
        - completion_rate: Percentage done
    """
```

### File Locations
- Task Queue: `orkestra/task-queue.json`

---

## Module: planning.py

### Purpose
Interactive project planning wizard with AI-driven democratic planning rounds. Replaces `SCRIPTS/CORE/project-planning.sh`.

### Key Classes

#### ProjectPlanner
Orchestrates the planning workflow.

```python
from orkestra.planning import ProjectPlanner

# Initialize
planner = ProjectPlanner(
    project_root="/path/to/project",
    project_name="my-project"
)

# Run interactive wizard
planner.run_planning_wizard()
```

### Wizard Flow

#### Step 1: Collect Project Info
```python
def _collect_project_info(self) -> dict:
    """
    Interactive prompts for:
    - Project description (what to build)
    - Involvement level (1=minimal, 2=moderate, 3=maximum)
    - Features list (comma-separated)
    
    Returns project_info dict
    """
```

#### Step 2: AI Planning Rounds
```python
def _ai_planning_rounds(self, project_info: dict) -> dict:
    """
    Democratic voting process:
    1. Create vote with 5 AI agents
    2. Each agent proposes plan components:
       - Architecture decisions
       - Technology choices
       - Implementation phases
       - Testing strategy
    3. Show user the round results
    4. Collect user feedback (based on involvement level)
    5. Incorporate feedback into next round
    6. Repeat until unanimous consensus (max 5 rounds)
    
    Returns final_plan dict
    """
```

#### Step 3: Present Final Plan
```python
def _present_final_plan(self, plan: dict) -> str:
    """
    Display comprehensive plan with Rich table:
    - Architecture overview
    - Technology stack
    - Implementation phases
    - Testing approach
    - Deployment strategy
    
    Prompt user: Approve / Modify / Reject
    
    Returns user_decision
    """
```

#### Step 4: Generate Tasks
```python
def _generate_tasks(self, plan: dict, project_info: dict):
    """
    Create 4-phase task breakdown:
    
    Phase 1 - Foundation (4 tasks):
    - Set up project structure
    - Configure development environment
    - Initialize version control
    - Set up testing framework
    
    Phase 2 - Core Features (N tasks):
    - One task per requested feature
    - Dependencies between related features
    
    Phase 3 - Integration & Testing (4 tasks):
    - Integration testing
    - End-to-end testing
    - Performance testing
    - Security review
    
    Phase 4 - Deployment (4 tasks):
    - Documentation
    - CI/CD pipeline
    - Production deployment
    - Monitoring setup
    
    All tasks added to TaskQueue with proper dependencies
    """
```

### UI Components
Uses Rich library for terminal UI:
- `Console`: Main output
- `Panel`: Bordered boxes
- `Prompt`: User input
- `Table`: Structured data display

### Integration
- Uses `Committee` for voting
- Uses `TaskQueue` for task creation
- Records outcomes to `orkestra/logs/outcomes/`

---

## Migration from Bash

### Bash Scripts Replaced

#### SCRIPTS/COMMITTEE/
- `process-vote.sh` → `committee.py::process_vote()`
- `gather-context.sh` → `committee.py::gather_context()`
- `process-question.sh` → Future Q&A module
- `committee-menu.sh` → CLI integration

#### SCRIPTS/TASK-MANAGEMENT/
- `add-task.sh` → `tasks.py::add_task()`
- `list-tasks.sh` → `tasks.py::list_tasks()`
- `check-dependencies.sh` → `tasks.py::check_dependencies()`

#### SCRIPTS/CORE/
- `project-planning.sh` → `planning.py::run_planning_wizard()`

### Compatibility
JSON file formats remain identical for seamless transition:

**Vote Format:**
```json
{
  "vote_id": "vote_abc123",
  "topic": "Choose architecture",
  "options": [
    {"id": "option_1", "description": "MVC", "votes": [], "reasoning": {}}
  ],
  "context": "Web application project",
  "rounds": [],
  "agents_required": ["claude", "chatgpt", "gemini", "copilot", "grok"],
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z"
}
```

**Task Format:**
```json
{
  "id": "task_xyz789",
  "description": "Implement user auth",
  "priority": "high",
  "category": "security",
  "status": "pending",
  "dependencies": ["task_abc123"],
  "assigned_to": null,
  "metadata": {"estimate": "4 hours"},
  "created_at": "2024-01-15T11:00:00Z",
  "updated_at": "2024-01-15T11:00:00Z",
  "completed_at": null
}
```

---

## Usage Examples

### Example 1: Create Project with Planning
```bash
# Command line
orkestra new my-web-app

# Automatically launches planning wizard:
# 1. Describe your project: "E-commerce platform with user auth and payment"
# 2. Involvement level: 2 (moderate)
# 3. Features: "user-auth, payment-integration, product-catalog, shopping-cart"
# 4. AI agents vote on architecture plan
# 5. User reviews each round
# 6. Final plan presented for approval
# 7. Tasks automatically generated
```

### Example 2: Programmatic Task Management
```python
from orkestra.tasks import TaskQueue, TaskPriority, TaskStatus

queue = TaskQueue("/path/to/project")

# Add tasks with dependencies
setup_id = queue.add_task(
    "Set up project structure",
    priority=TaskPriority.HIGH,
    category="foundation"
)

db_id = queue.add_task(
    "Configure database",
    priority=TaskPriority.HIGH,
    category="foundation",
    dependencies=[setup_id]
)

auth_id = queue.add_task(
    "Implement authentication",
    priority=TaskPriority.CRITICAL,
    category="security",
    dependencies=[db_id]
)

# Process tasks in order
while True:
    task = queue.get_next_task()
    if not task:
        break
    
    print(f"Working on: {task.description}")
    queue.update_task(task.id, status=TaskStatus.IN_PROGRESS)
    
    # ... do work ...
    
    queue.update_task(task.id, status=TaskStatus.COMPLETED)

# Check progress
stats = queue.get_statistics()
print(f"Completion: {stats['completion_rate']}%")
```

### Example 3: Democratic Decision Making
```python
from orkestra.committee import Committee

committee = Committee("/path/to/project")

# Gather relevant context
context = committee.gather_context("authentication best practices")

# Create vote
vote_id = committee.create_vote(
    topic="Choose authentication method",
    options=[
        "JWT with refresh tokens",
        "Session-based with Redis",
        "OAuth2 with external provider"
    ],
    context=context
)

# Process with user feedback
def collect_feedback():
    return input("Your thoughts on current proposals: ")

result = committee.process_vote(
    vote_id,
    max_rounds=5,
    user_feedback_callback=collect_feedback
)

print(f"Decision: {result['decision']}")
print(f"Consensus: {result['consensus_level']}")
print(f"Reasoning: {result['reasoning']}")
```

---

## Testing

### Unit Tests
```bash
# Test committee module
python -m pytest tests/test_committee.py

# Test tasks module
python -m pytest tests/test_tasks.py

# Test planning module
python -m pytest tests/test_planning.py
```

### Integration Tests
```bash
# Full workflow test
orkestra new test-project --skip-planning
cd test-project
python -c "
from orkestra.planning import ProjectPlanner
planner = ProjectPlanner('.', 'test-project')
# Mock user inputs...
planner.run_planning_wizard()
"
```

---

## Future Enhancements

### Priority 1: AI API Integration
Implement actual API calls in `committee.py`:
- Anthropic SDK for Claude
- OpenAI SDK for ChatGPT
- Google AI SDK for Gemini
- GitHub Copilot API
- xAI SDK for Grok

### Priority 2: Convert Remaining Scripts
- `SCRIPTS/AGENTS/` → Individual agent wrappers
- `SCRIPTS/AUTOMATION/` → Workflow automation
- `SCRIPTS/DEMOCRACY/` → Consensus algorithms
- `SCRIPTS/MONITORING/` → Progress tracking
- `SCRIPTS/SAFETY/` → Safety checks
- `SCRIPTS/UTILS/` → Utility functions

### Priority 3: Advanced Features
- Task templates for common patterns
- Plan templates for project types
- Machine learning for decision optimization
- Real-time collaboration for multi-user
- Web dashboard for visualization

---

## Troubleshooting

### Import Errors
```python
# If modules not found:
# 1. Ensure in project root
cd /Users/hendrixx./Desktop/Orkestra

# 2. Install in development mode
pip install -e .

# 3. Verify installation
python -c "from orkestra.committee import Committee; print('OK')"
```

### Rich Library Issues
```bash
# Lint errors about Rich imports are false positives
# Rich is in requirements, verify:
pip list | grep rich

# Should show: rich 10.x.x or higher

# Reinstall if needed:
pip install --upgrade rich
```

### JSON File Corruption
```python
# Backup task queue before operations:
import shutil
shutil.copy(
    "orkestra/task-queue.json",
    "orkestra/task-queue.backup.json"
)

# Validate JSON:
import json
with open("orkestra/task-queue.json") as f:
    data = json.load(f)  # Raises error if invalid
```

---

## API Reference

See individual module docstrings for complete API documentation:
```bash
# View module docs
python -c "from orkestra import committee; help(committee.Committee)"
python -c "from orkestra import tasks; help(tasks.TaskQueue)"
python -c "from orkestra import planning; help(planning.ProjectPlanner)"
```
