# Context Management & Democracy Integration

## Overview

The Context Management and Democracy systems work together to provide:
1. **Complete project history** for AI agents to recover from disconnects/rate limits
2. **Democratic decision-making** with weighted voting based on expertise
3. **Continuous understanding updates** from each AI agent
4. **Automatic checkpoints** for state recovery

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      AI Agents Layer                         │
│  Claude | ChatGPT | Gemini | Copilot | Grok                │
│     ↓        ↓        ↓        ↓        ↓                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   Committee Module                           │
│  • create_vote()                                            │
│  • process_vote()                                           │
│  • gather_context()                                         │
└─────────────────────────────────────────────────────────────┘
         ↓                              ↓
┌──────────────────────┐    ┌──────────────────────┐
│  DemocracyEngine     │    │  ContextManager      │
│  • Weighted voting   │    │  • Agent states      │
│  • Ethical framework │    │  • Event logging     │
│  • Consensus levels  │    │  • Checkpoints       │
│  • Domain expertise  │    │  • Recovery          │
└──────────────────────┘    └──────────────────────┘
         ↓                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Persistent Storage                        │
│  orkestra/                                                   │
│  ├── context/                                               │
│  │   ├── project-context.json      (Main context)          │
│  │   ├── events/                   (Event history)         │
│  │   ├── checkpoints/              (Recovery points)       │
│  │   └── agent-logs/               (Agent-specific logs)   │
│  └── logs/                                                  │
│      ├── voting/                   (Vote records)           │
│      └── outcomes/                 (Decision records)       │
└─────────────────────────────────────────────────────────────┘
```

---

## Context Manager

### Purpose
Maintains complete project history so AI agents can:
- Recover exactly where they left off after disconnect
- Resume work after rate limits
- Understand project state when switching contexts
- Collaborate with full knowledge of each other's work

### Key Features

#### 1. Agent Understanding Tracking
Each agent maintains their understanding of the project:

```python
from orkestra.context import ContextManager

context = ContextManager("/path/to/project")

# Agent updates their understanding
context.update_agent_understanding(
    agent_name="claude",
    understanding="Working on authentication system. Completed database schema, now implementing JWT tokens.",
    active_tasks=["task_auth_jwt", "task_auth_validation"],
    completed_tasks=["task_auth_schema", "task_auth_models"],
    concerns=["Need to verify token expiration strategy"],
    suggestions=["Consider refresh token rotation"],
    confidence_level=0.85
)
```

#### 2. Event Logging
All significant events are logged automatically:

```python
# Events are logged automatically through various operations
context.log_event(
    event_type=ContextEventType.TASK_STARTED,
    agent_name="copilot",
    description="Started deployment setup task",
    related_tasks=["task_deploy_config"],
    impact_level="medium"
)
```

#### 3. Recovery After Disconnect

```python
# When agent reconnects
summary = context.handle_reconnect("claude")
print(summary)
```

**Output:**
```
================================================================================
ORKESTRA CONTEXT RECOVERY SUMMARY
================================================================================
Generated: 2024-11-03T15:30:00Z
Project: my-web-app
Context Version: 47

PROJECT STATE:
  Phase: development
  Milestone: Core Features Implementation
  Completion: 45.2%
  Active Tasks: 8
  Completed Tasks: 15
  Active Votes: 2

RECENT EVENTS (last 10):
  [2024-11-03T15:25:00Z] task_completed
    Task completed: task_auth_schema
    Agent: claude
  [2024-11-03T15:20:00Z] vote_created
    Vote created: Choose caching strategy
  ...

YOUR LAST STATE (claude):
  Last Update: 2024-11-03T15:25:00Z
  Confidence: 85%
  Active Tasks: 2
  Understanding:
    Working on authentication system. Completed database schema, now implementing JWT tokens.
  Concerns: Need to verify token expiration strategy
  Suggestions: Consider refresh token rotation

ALL AGENTS STATUS:
  claude:
    Last Active: 2024-11-03T15:25:00Z
    Confidence: 85%
    Tasks: 2 active, 4 done
  chatgpt:
    Last Active: 2024-11-03T15:22:00Z
    Confidence: 90%
    Tasks: 1 active, 3 done
  ...
```

#### 4. Automatic Checkpoints

```python
# Checkpoints created automatically before critical events
context.handle_disconnect("claude", "Rate limit hit")
# → Creates checkpoint automatically

# Or create manual checkpoint
checkpoint_id = context.create_checkpoint("Before major refactor")

# Load checkpoint if needed
context.load_checkpoint(checkpoint_id)
```

### File Structure

```
orkestra/context/
├── project-context.json         # Main context state
├── events/                       # Individual event records
│   ├── event_abc123.json
│   ├── event_def456.json
│   └── ...
├── checkpoints/                  # Recovery checkpoints
│   ├── checkpoint_20241103_143000.json
│   └── ...
└── agent-logs/                   # Agent-specific detailed logs
    ├── claude-log.json
    ├── chatgpt-log.json
    ├── gemini-log.json
    ├── copilot-log.json
    └── grok-log.json
```

---

## Democracy Engine

### Purpose
Implements democratic decision-making with:
- **Domain-specific expertise weighting**
- **Ethical framework enforcement**
- **Multiple consensus levels**
- **Complete vote auditing**

### Expertise Domains

Each agent has weighted expertise in different domains:

| Domain | Claude | ChatGPT | Gemini | Copilot | Grok |
|--------|--------|---------|--------|---------|------|
| Architecture | 2.0 | 1.0 | 1.5 | 1.5 | 1.0 |
| Content | 1.5 | 2.0 | 0.5 | 0.5 | 1.0 |
| Cloud | 1.5 | 0.5 | 2.0 | 1.0 | 1.0 |
| Innovation | 1.5 | 1.0 | 1.0 | 1.0 | 2.0 |
| Code | 1.0 | 0.5 | 1.5 | 2.0 | 1.0 |

### Ethical Framework

All votes are governed by ethical principles:
1. Do not lie
2. Protect life
3. Respect privacy
4. Promote fairness
5. Ensure transparency
6. Foster collaboration
7. Minimize harm
8. Maximize benefit

### Creating Votes

```python
from orkestra.democracy import DemocracyEngine, VoteType

democracy = DemocracyEngine("/path/to/project")

# Create weighted vote based on domain
vote_id = democracy.create_vote(
    title="Choose database system",
    description="Select database for user authentication and session management",
    options=["PostgreSQL", "MongoDB", "Redis + PostgreSQL"],
    vote_type=VoteType.WEIGHTED,
    domain="database",  # Gives Gemini 2.0x weight
    threshold=0.6,
    deadline_hours=2,
    proposed_by="claude"
)
```

### Casting Votes

```python
# Each agent casts their vote
democracy.cast_vote(
    vote_id=vote_id,
    agent_name="gemini",
    option_id="option_1",  # PostgreSQL
    reasoning="PostgreSQL provides ACID compliance, mature replication, and excellent JSON support for flexibility"
)

democracy.cast_vote(
    vote_id=vote_id,
    agent_name="claude",
    option_id="option_1",
    reasoning="PostgreSQL is proven, well-documented, and has excellent community support"
)

# Other agents vote...
```

### Closing Votes

```python
# Close vote and get results
result = democracy.close_vote(vote_id)

print(f"Decision: {result['winning_description']}")
print(f"Consensus: {result['consensus_level'].value}")
print(f"Score: {result['score']:.2%}")
print(f"Voted for: {', '.join(result['votes'])}")
```

**Output:**
```
Decision: PostgreSQL
Consensus: strong
Score: 87%
Voted for: gemini, claude, copilot, chatgpt
```

### Consensus Levels

- **UNANIMOUS** (95%+): Complete agreement
- **STRONG** (80-94%): Very high agreement
- **MAJORITY** (60-79%): Clear preference
- **SPLIT** (threshold-59%): Divided opinion
- **FAILED** (<threshold): No consensus

---

## Integration Example

### Complete Workflow

```python
from orkestra.context import ContextManager
from orkestra.democracy import DemocracyEngine, VoteType
from orkestra.committee import Committee

# Initialize (automatically creates context and democracy)
committee = Committee("/path/to/project")

# Agent 1: Claude starts work
committee.context.update_agent_understanding(
    agent_name="claude",
    understanding="Analyzing architecture requirements for authentication system",
    active_tasks=["task_auth_research"],
    confidence_level=0.7
)

# Create vote for important decision
vote_id = committee.democracy.create_vote(
    title="Choose authentication approach",
    description="Select authentication method for web application",
    options=[
        "JWT with refresh tokens",
        "Session-based with Redis",
        "OAuth2 with external provider"
    ],
    domain="architecture",
    proposed_by="claude"
)

# Agents vote
committee.democracy.cast_vote(
    vote_id, "claude", "option_1",
    "JWT provides stateless auth, scales well, and modern best practice"
)

committee.democracy.cast_vote(
    vote_id, "gemini", "option_1",
    "JWT integrates well with cloud services and Firebase"
)

committee.democracy.cast_vote(
    vote_id, "copilot", "option_1",
    "JWT is standard in modern deployments and CI/CD friendly"
)

# Close vote
result = committee.democracy.close_vote(vote_id)

# Agent updates understanding with decision
committee.context.update_agent_understanding(
    agent_name="claude",
    understanding="Decision made: Implementing JWT authentication. Starting with token generation logic.",
    active_tasks=["task_auth_jwt_generation"],
    completed_tasks=["task_auth_research"],
    confidence_level=0.9
)

# Simulate disconnect
committee.context.handle_disconnect("claude", "Rate limit exceeded")

# ... time passes ...

# Agent reconnects
recovery_summary = committee.context.handle_reconnect("claude")
print(recovery_summary)
# Claude now knows exactly where they left off!

# Continue work...
```

---

## API Reference

### ContextManager

#### Core Methods

```python
# Update agent's understanding
update_agent_understanding(
    agent_name: str,
    understanding: str,
    active_tasks: Optional[List[str]] = None,
    completed_tasks: Optional[List[str]] = None,
    concerns: Optional[List[str]] = None,
    suggestions: Optional[List[str]] = None,
    confidence_level: float = 0.8
)

# Log events
log_event(
    event_type: ContextEventType,
    description: str,
    agent_name: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None,
    impact_level: str = "medium"
)

# Recovery
create_checkpoint(reason: str = "Manual checkpoint") -> str
load_checkpoint(checkpoint_id: str) -> bool
handle_disconnect(agent_name: str, reason: str)
handle_reconnect(agent_name: str) -> str  # Returns recovery summary
handle_rate_limit(agent_name: str, retry_after: Optional[int] = None)

# Get context
get_recovery_summary(agent_name: Optional[str] = None) -> str
get_agent_understanding(agent_name: str) -> Optional[AgentUnderstanding]
get_recent_events(limit: int = 50) -> List[ContextEvent]

# Project state
update_project_phase(phase: str)
update_milestone(milestone: str)
update_completion(percentage: float)
record_decision(title: str, decision: str, reasoning: str)

# Task tracking
task_started(task_id: str, agent_name: str)
task_completed(task_id: str, agent_name: str)
task_blocked(task_id: str, reason: str)
```

#### Event Types

```python
class ContextEventType(Enum):
    PROJECT_START = "project_start"
    PLANNING_PHASE = "planning_phase"
    TASK_STARTED = "task_started"
    TASK_COMPLETED = "task_completed"
    DECISION_MADE = "decision_made"
    AGENT_ACTION = "agent_action"
    VOTE_CREATED = "vote_created"
    VOTE_COMPLETED = "vote_completed"
    ERROR_OCCURRED = "error_occurred"
    MILESTONE_REACHED = "milestone_reached"
    CONTEXT_REFRESH = "context_refresh"
    RATE_LIMIT_HIT = "rate_limit_hit"
    DISCONNECT = "disconnect"
    RECONNECT = "reconnect"
```

### DemocracyEngine

#### Core Methods

```python
# Create vote
create_vote(
    title: str,
    description: str,
    options: List[str],
    vote_type: VoteType = VoteType.WEIGHTED,
    domain: str = "general",
    threshold: float = 0.5,
    deadline_hours: int = 1,
    proposed_by: Optional[str] = None
) -> str  # Returns vote_id

# Cast vote
cast_vote(
    vote_id: str,
    agent_name: str,
    option_id: str,
    reasoning: str
) -> bool

# Close vote
close_vote(vote_id: str) -> Dict[str, Any]

# Query votes
get_vote_status(vote_id: str) -> Optional[Dict[str, Any]]
list_active_votes() -> List[Dict[str, Any]]
get_agent_pending_votes(agent_name: str) -> List[Dict[str, Any]]
check_expired_votes() -> List[str]

# Utilities
get_weights_for_domain(domain: str) -> Dict[str, float]
```

#### Vote Types

```python
class VoteType(Enum):
    SIMPLE = "simple"              # Simple majority
    SUPERMAJORITY = "supermajority"  # 75% threshold
    UNANIMOUS = "unanimous"        # 100% agreement
    WEIGHTED = "weighted"          # Domain-weighted
    RANKED_CHOICE = "ranked_choice"  # Preferential voting
```

---

## Usage Patterns

### Pattern 1: Long-Running Task with Checkpoints

```python
context = ContextManager(".")

# Start task
context.task_started("task_complex_feature", "claude")
context.update_agent_understanding(
    "claude",
    "Starting complex feature implementation. Estimated 4 hours.",
    active_tasks=["task_complex_feature"]
)

# Work for a while...
context.create_checkpoint("Midpoint of complex feature")

# More work...
context.update_agent_understanding(
    "claude",
    "Complex feature 75% complete. Implementing final integration.",
    confidence_level=0.85
)

# Rate limit hit!
context.handle_rate_limit("claude", retry_after=60)

# Wait...

# Resume
summary = context.handle_reconnect("claude")
# Claude knows: 75% done, working on final integration

# Complete
context.task_completed("task_complex_feature", "claude")
```

### Pattern 2: Multi-Agent Collaboration

```python
democracy = DemocracyEngine(".")

# Agent 1 proposes decision
vote_id = democracy.create_vote(
    title="API design approach",
    description="Choose REST API design pattern",
    options=["RESTful with HATEOAS", "GraphQL", "gRPC"],
    domain="architecture",
    proposed_by="claude"
)

# All agents vote over time
democracy.cast_vote(vote_id, "claude", "option_1", "HATEOAS provides discoverability")
democracy.cast_vote(vote_id, "copilot", "option_1", "RESTful is standard and well-supported")
democracy.cast_vote(vote_id, "gemini", "option_2", "GraphQL reduces over-fetching")
democracy.cast_vote(vote_id, "chatgpt", "option_1", "REST is widely understood")
democracy.cast_vote(vote_id, "grok", "option_2", "GraphQL enables flexible queries")

# Close and get consensus
result = democracy.close_vote(vote_id)
# Result: STRONG consensus for RESTful (65% weighted score)
```

### Pattern 3: Error Recovery

```python
context = ContextManager(".")

try:
    # Agent working
    context.update_agent_understanding("gemini", "Deploying to Firebase...")
    
    # Deployment code...
    
except Exception as e:
    # Error occurred
    context.log_event(
        ContextEventType.ERROR_OCCURRED,
        agent_name="gemini",
        description=f"Deployment failed: {e}",
        impact_level="high"
    )
    
    # Create recovery checkpoint
    checkpoint_id = context.create_checkpoint("Before retry")
    
    # Retry logic...
```

---

## Best Practices

### For AI Agents

1. **Update Understanding Frequently**
   ```python
   # After every significant action
   context.update_agent_understanding(
       agent_name="your_name",
       understanding="Current state description",
       confidence_level=0.8  # How confident you are
   )
   ```

2. **Log Important Events**
   ```python
   # When you complete milestones
   context.log_event(
       ContextEventType.MILESTONE_REACHED,
       agent_name="your_name",
       description="Completed authentication module",
       impact_level="high"
   )
   ```

3. **Vote with Reasoning**
   ```python
   # Always explain your vote
   democracy.cast_vote(
       vote_id,
       "your_name",
       "option_1",
       "Detailed reasoning explaining why this is the best choice"
   )
   ```

4. **Check for Pending Votes**
   ```python
   # Regularly check if you need to vote
   pending = democracy.get_agent_pending_votes("your_name")
   for vote in pending:
       # Review and cast vote
       pass
   ```

5. **Use Recovery Summary After Reconnect**
   ```python
   # First thing after reconnect
   summary = context.handle_reconnect("your_name")
   print(summary)  # Read this to get back up to speed
   ```

### For System Integrators

1. **Initialize Early**
   ```python
   # Set up at project start
   committee = Committee("/path/to/project")
   # This initializes both context and democracy
   ```

2. **Create Checkpoints Before Risky Operations**
   ```python
   committee.context.create_checkpoint("Before database migration")
   # Do risky operation
   ```

3. **Monitor Vote Deadlines**
   ```python
   # Periodic check
   expired = committee.democracy.check_expired_votes()
   for vote_id in expired:
       print(f"Vote {vote_id} auto-closed due to deadline")
   ```

4. **Compress Old Events**
   ```python
   # Periodically archive old events
   committee.context.compress_old_events(days=30)
   ```

---

## Configuration

### Domain Weights

Customize expertise weights in `democracy.py`:

```python
DOMAIN_WEIGHTS = {
    "your_custom_domain": {
        "claude": 1.5,
        "chatgpt": 1.0,
        "gemini": 2.0,
        "grok": 1.0,
        "copilot": 1.5
    }
}
```

### Ethical Principles

Customize ethical framework in `democracy.py`:

```python
ETHICAL_PRINCIPLES = [
    "Your custom principle 1",
    "Your custom principle 2",
    # ...
]
```

---

## Troubleshooting

### Context Not Loading

```python
# Check if context file exists
from pathlib import Path
context_file = Path("orkestra/context/project-context.json")
if not context_file.exists():
    print("Context not initialized")
    # Will be created automatically on first use
```

### Agent Understanding Not Updated

```python
# Verify agent name matches
committee.context.get_agent_understanding("claude")  # Check exact spelling
```

### Votes Not Closing

```python
# Check vote status
status = committee.democracy.get_vote_status(vote_id)
print(status['status'])  # Should be "open"

# Manually close if needed
result = committee.democracy.close_vote(vote_id)
```

---

## Performance Notes

- Context saves are atomic (temp file + rename)
- Events limited to 1000 in memory (older ones archived)
- Agent logs keep last 100 entries
- Checkpoints keep last 20
- JSON files use UTF-8 encoding
- All timestamps are UTC ISO 8601

---

## Security Considerations

- All files stored in `orkestra/` directory (project-local)
- No sensitive data in context by default
- Agent API keys managed separately (not in context)
- Vote reasoning is recorded (full audit trail)
- Checkpoints can be used for rollback

---

## Future Enhancements

- [ ] Encryption for sensitive context data
- [ ] Real-time context synchronization
- [ ] Web dashboard for vote visualization
- [ ] Machine learning for consensus prediction
- [ ] Automatic conflict resolution
- [ ] Context diff between checkpoints
- [ ] Export context to external systems

---

For complete API documentation, see:
- `src/orkestra/context.py` - Context management implementation
- `src/orkestra/democracy.py` - Democracy engine implementation
- `src/orkestra/committee.py` - Integrated committee system
