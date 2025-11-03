# 🎭 Orkestra - Multi-AI Orchestration System

A powerful framework for coordinating multiple AI agents (Claude, ChatGPT, Gemini, Copilot, and Grok) to work together on complex projects with democratic decision-making, automatic recovery, and comprehensive safety validation.

## ✨ Features

### 🤖 Multi-AI Coordination
- **5 AI Agents**: Claude, ChatGPT, Gemini, Copilot, and Grok
- **Smart Task Selection**: Automatic agent selection based on task type and workload
- **Load Balancing**: Distributes work evenly across available agents
- **Parallel Execution**: Multiple agents can work simultaneously

### 🗳️ Democratic Decision Making
- **6 Consensus Methods**: Unanimous, Supermajority (75%+), Majority (50%+), Plurality, Ranked Choice, Weighted
- **Voting System**: All major decisions go through democratic vote
- **Deadlock Detection**: Automatically identifies and resolves stuck decisions
- **Compromise Suggestions**: AI-powered conflict resolution

### 🔄 Resilience & Recovery
- **Context Snapshots**: Automatic state preservation every 10 minutes
- **Agent Recovery**: AI agents can resume exactly where they left off after disconnects
- **Task Recovery**: Failed tasks automatically retry with exponential backoff
- **Lock Management**: Prevents task conflicts with atomic file-based locking
- **Stale Lock Cleanup**: Automatically removes abandoned locks

### 🛡️ Safety & Validation
- **Pre-Task Validation**: 10 checks before task execution
  - Task queue integrity
  - Dependency resolution
  - Lock conflict detection
  - Disk space verification
  - Git repository status
- **Post-Task Validation**: 8 checks after task completion
  - Output file verification
  - Lock release confirmation
  - Git commit verification
  - Queue consistency
- **Self-Healing**: Automatically fixes common issues

### 📊 Monitoring & Health
- **Agent Health Tracking**: Response times, error rates, success rates
- **System Metrics**: Overall health, throughput, uptime
- **Progress Tracking**: Milestone detection and completion rates
- **Resilience Monitoring**: Tracks failure recovery patterns

### 📝 Comprehensive Logging
- **Audit Trail**: Every action logged with timestamp and details
- **Context History**: Full history of agent actions and decisions
- **Task Logs**: Complete record of task execution
- **Notification System**: Per-agent notification management

## 🚀 Quick Start

### Installation

1. **Clone the repository**:
```bash
cd /Users/hendrixx./Desktop/Orkestra
```

2. **Install dependencies**:
```bash
pip install -r requirements.txt
```

3. **Set up API keys**:
```bash
# Create .env file
cat > CONFIG/api-keys.env << EOF
CLAUDE_API_KEY=your_claude_key
CHATGPT_API_KEY=your_openai_key
GEMINI_API_KEY=your_gemini_key
COPILOT_API_KEY=your_github_key
GROK_API_KEY=your_xai_key
EOF

# Load environment
source CONFIG/api-keys.env
```

### Basic Usage

#### Start the System

```python
from pathlib import Path
from src.orkestra import SystemStartup, Orchestrator
import asyncio

# Initialize
project_root = Path("/Users/hendrixx./Desktop/Orkestra")
startup = SystemStartup(project_root)
orchestrator = startup.initialize()

# Start orchestrator
asyncio.run(orchestrator.start())
```

#### Create and Assign Tasks

```python
from src.orkestra import TaskQueue

# Create task queue
queue = TaskQueue(project_root)

# Add a task
task_id = queue.add_task(
    title="Implement user authentication",
    instructions="Create a secure authentication system with JWT tokens",
    priority=1,
    task_type="technical"
)

# Task will be automatically assigned to best agent
```

#### Check System Status

```python
# Print comprehensive status
orchestrator.print_status()

# Get status data
status = orchestrator.get_status()
print(f"Running: {status['running']}")
print(f"Active Agents: {len(status['agents'])}")
print(f"Pending Tasks: {status['tasks']['pending']}")
```

#### Use Democracy for Important Decisions

```python
from src.orkestra import Committee, Vote, VoteType

committee = Committee(project_root)

# Call a vote
vote_id = committee.call_vote(
    title="Should we migrate to new database?",
    description="Considering migration from SQLite to PostgreSQL",
    vote_type=VoteType.YES_NO,
    required_voters=["claude", "chatgpt", "gemini"]
)

# Agents cast votes (can be automated)
committee.cast_vote(vote_id, "claude", "yes")
committee.cast_vote(vote_id, "chatgpt", "yes")
committee.cast_vote(vote_id, "gemini", "no")

# Check result
result = committee.get_vote_result(vote_id)
print(f"Decision: {result}")
```

## 📚 Module Overview

### Core Modules

#### `agents.py` - AI Agent Management
- Individual agent wrappers for each AI
- API integration and rate limiting
- Agent health monitoring
- Notification system

#### `tasks.py` - Task Management
- Task queue with JSON persistence
- Priority-based scheduling
- Dependency tracking
- Status management

#### `committee.py` - Democratic Voting
- Multi-option voting system
- Vote tracking and results
- Quorum requirements
- Vote history

#### `planning.py` - Project Planning
- Interactive project setup
- Phase planning
- Milestone tracking
- Deliverable management

### Advanced Modules

#### `context.py` - Context Management
- Session tracking
- Agent state preservation
- Decision history
- Snapshot/restore for recovery

#### `democracy.py` - Advanced Consensus
- 6 voting algorithms
- Ranked choice voting
- Weighted voting by expertise
- Deadlock detection and resolution

#### `monitoring.py` - Health & Progress
- Real-time health monitoring
- Agent performance tracking
- System metrics
- Progress milestone detection

#### `safety.py` - Validation & Quality
- Pre-task validation (10 checks)
- Post-task validation (8 checks)
- Consistency checking
- Self-healing capabilities

#### `utils.py` - Common Utilities
- Atomic file operations
- Git integration
- JSON tools
- Logging helpers
- String formatters
- System helpers

### Automation Modules

#### `automation.py` - Task Automation
- **TaskCoordinator**: Intelligent work distribution
- **LockManager**: Atomic task locking
- **SmartTaskSelector**: Capability-based agent selection
- **RecoverySystem**: Automatic failure recovery
- **DaemonManager**: Background process management
- **AuditLogger**: Comprehensive audit trails

#### `orchestrator.py` - Main Coordinator
- **Orchestrator**: Central system coordinator
- **SystemStartup**: Initialization and setup
- Background task loops
- Health monitoring
- Recovery operations

## 🎯 Use Cases

### 1. Large Development Projects
```python
# Create a complex project
planner = ProjectPlanner(project_root)
project = planner.create_project(
    name="E-commerce Platform",
    description="Full-stack e-commerce with payment integration"
)

# Tasks are automatically created and distributed
# Agents collaborate with democratic decision-making
```

### 2. Code Review and Quality Assurance
```python
# Multiple agents review code
task_id = queue.add_task(
    title="Review authentication module",
    instructions="Check for security vulnerabilities and best practices",
    task_type="code_review"
)

# 3 different agents review the code
# Democratic vote determines if code passes
```

### 3. Content Creation
```python
# Collaborative content creation
task_id = queue.add_task(
    title="Write product documentation",
    instructions="Create comprehensive docs for API",
    task_type="content"
)

# ChatGPT writes initial draft
# Claude reviews and improves
# Gemini adds technical details
```

### 4. Research and Analysis
```python
# Parallel research by multiple agents
task_id = queue.add_task(
    title="Research blockchain scaling solutions",
    instructions="Compare Layer 2 solutions",
    task_type="research"
)

# Each agent researches different solutions
# Results are combined and synthesized
```

## 🔧 Configuration

### System Configuration (`orkestra/config.json`)
```json
{
  "auto_assign": true,
  "auto_recovery": true,
  "enable_democracy": true,
  "consensus_method": "majority",
  "health_check_interval": 300,
  "recovery_check_interval": 600,
  "max_concurrent_tasks": 5
}
```

### Agent Configuration (Environment Variables)
```bash
# Claude
CLAUDE_API_KEY=sk-ant-...
CLAUDE_MODEL=claude-3-5-sonnet-20241022
CLAUDE_TEMPERATURE=0.7
CLAUDE_MAX_TOKENS=4000

# ChatGPT
CHATGPT_API_KEY=sk-...
CHATGPT_MODEL=gpt-4o
CHATGPT_TEMPERATURE=0.7

# Gemini
GEMINI_API_KEY=AI...
GEMINI_MODEL=gemini-1.5-pro

# Copilot
COPILOT_API_KEY=ghp_...
COPILOT_MODEL=gpt-4

# Grok
GROK_API_KEY=xai-...
GROK_MODEL=grok-beta
```

## 📊 Architecture

```
┌─────────────────────────────────────────────────┐
│           Orchestrator (Main Coordinator)        │
├─────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ AgentManager │  │   TaskCoordinator       │ │
│  │              │  │                         │ │
│  │ - Claude     │  │ - Smart Task Selection  │ │
│  │ - ChatGPT    │  │ - Load Balancing        │ │
│  │ - Gemini     │  │ - Dependency Resolution │ │
│  │ - Copilot    │  │ - Lock Management       │ │
│  │ - Grok       │  │                         │ │
│  └──────────────┘  └─────────────────────────┘ │
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Democracy    │  │   Context Manager       │ │
│  │              │  │                         │ │
│  │ - Voting     │  │ - State Tracking        │ │
│  │ - Consensus  │  │ - Recovery Snapshots    │ │
│  │ - Resolution │  │ - Agent History         │ │
│  └──────────────┘  └─────────────────────────┘ │
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ Monitoring   │  │   Safety & Validation   │ │
│  │              │  │                         │ │
│  │ - Health     │  │ - Pre-Task Checks       │ │
│  │ - Progress   │  │ - Post-Task Checks      │ │
│  │ - Metrics    │  │ - Self-Healing          │ │
│  └──────────────┘  └─────────────────────────┘ │
│                                                  │
└─────────────────────────────────────────────────┘
```

## 🛠️ Advanced Features

### Custom Consensus Methods
```python
from src.orkestra import DemocracyEngine, VotingRule, ConsensusMethod

democracy = DemocracyEngine(project_root)

# Create custom voting rule
rule = VotingRule(
    method=ConsensusMethod.SUPERMAJORITY,
    min_participation=0.8,  # 80% must vote
    quorum=0.6,             # 60% needed for decision
    weight_by_expertise=True
)

# Use for important decisions
result = democracy.calculate_consensus(vote_id, rule)
```

### Manual Task Assignment
```python
coordinator = TaskCoordinator(project_root)

# Manually assign to specific agent
coordinator.assign_task(task_id=5, agent_name="claude")
```

### Custom Health Checks
```python
monitor = HealthMonitor(project_root)

# Get detailed health report
report = monitor.get_health_report(detail_level="full")

# Check specific agent
agent_health = monitor.check_agent_health("claude")
print(f"Status: {agent_health.status}")
print(f"Success Rate: {agent_health.success_rate}%")
```

### Recovery from Snapshot
```python
context_mgr = ContextManager(project_root)

# List available snapshots
snapshots = context_mgr.context.snapshots

# Restore from specific snapshot
context_mgr.restore_from_snapshot(snapshot_id="snapshot_20240115_143000")
```

## 📈 Performance Tips

1. **Use Appropriate Consensus Methods**:
   - `UNANIMOUS`: Critical decisions only (slow)
   - `MAJORITY`: Most common use case (balanced)
   - `PLURALITY`: Quick decisions (fast)

2. **Optimize Agent Selection**:
   - Let SmartTaskSelector choose agents
   - Specialization improves quality and speed

3. **Enable Auto-Recovery**:
   - Reduces manual intervention
   - Improves system resilience

4. **Regular Health Checks**:
   - Monitor agent performance
   - Replace degraded agents

5. **Use Context Snapshots**:
   - Frequent snapshots enable quick recovery
   - Default: every 10 minutes

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 📄 License

Apache 2.0 - See LICENSE file for details

## 🙏 Acknowledgments

- Anthropic (Claude)
- OpenAI (ChatGPT)
- Google (Gemini)
- GitHub (Copilot)
- xAI (Grok)

---

**Built with ❤️ by hendrixx-cnc**

For questions or support, check the documentation in `DOCS/` or open an issue.
