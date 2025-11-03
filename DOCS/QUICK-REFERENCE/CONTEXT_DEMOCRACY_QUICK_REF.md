# Context & Democracy Quick Reference

## Quick Start

```python
from orkestra.committee import Committee

# Initialize (creates context + democracy automatically)
committee = Committee("/path/to/project")
```

---

## Context Management

### Update Your Understanding (After Every Action!)

```python
committee.context.update_agent_understanding(
    agent_name="claude",  # Your name
    understanding="What I'm currently doing and what I've learned",
    active_tasks=["task_id_1", "task_id_2"],
    completed_tasks=["task_id_0"],
    concerns=["Any worries or blockers"],
    suggestions=["Ideas for improvement"],
    confidence_level=0.85  # How confident you are (0.0-1.0)
)
```

### After Disconnect/Rate Limit

```python
# Get complete recovery summary
summary = committee.context.handle_reconnect("claude")
print(summary)  # Read this to know exactly where you left off
```

### Create Checkpoint (Before Risky Operations)

```python
checkpoint_id = committee.context.create_checkpoint("Before database migration")

# If something goes wrong:
committee.context.load_checkpoint(checkpoint_id)
```

---

## Democratic Voting

### Create Vote

```python
vote_id = committee.democracy.create_vote(
    title="Choose database",
    description="Select database for user management",
    options=["PostgreSQL", "MongoDB", "MySQL"],
    domain="database",  # Uses expertise weights
    proposed_by="claude"
)
```

### Cast Vote

```python
committee.democracy.cast_vote(
    vote_id=vote_id,
    agent_name="gemini",
    option_id="option_1",  # First option
    reasoning="PostgreSQL provides ACID and excellent JSON support"
)
```

### Check Your Pending Votes

```python
pending = committee.democracy.get_agent_pending_votes("claude")
for vote in pending:
    print(f"Need to vote on: {vote['title']}")
```

### Close Vote

```python
result = committee.democracy.close_vote(vote_id)
print(f"Winner: {result['winning_description']}")
print(f"Consensus: {result['consensus_level'].value}")
```

---

## Task Tracking

```python
# Start task
committee.context.task_started("task_auth", "claude")

# Complete task
committee.context.task_completed("task_auth", "claude")

# Block task
committee.context.task_blocked("task_deploy", "Missing API keys")
```

---

## Event Logging

```python
from orkestra.context import ContextEventType

# Log important events
committee.context.log_event(
    event_type=ContextEventType.MILESTONE_REACHED,
    agent_name="claude",
    description="Authentication system complete",
    impact_level="high"
)
```

---

## Recovery Scenarios

### Scenario 1: Rate Limit Hit

```python
# When rate limit occurs
committee.context.handle_rate_limit("claude", retry_after=60)

# Wait for retry_after seconds...

# Resume work
summary = committee.context.handle_reconnect("claude")
# Continue where you left off
```

### Scenario 2: Context Switch

```python
# Before switching to another task
committee.context.update_agent_understanding(
    "claude",
    "Pausing auth work at 75% complete. Need to help with deployment.",
    confidence_level=0.75
)

# Work on other task...

# Later, check where you were
state = committee.context.get_agent_understanding("claude")
print(state.current_understanding)
```

### Scenario 3: Error Recovery

```python
try:
    # Risky operation
    deploy_to_production()
except Exception as e:
    # Log error
    committee.context.log_event(
        ContextEventType.ERROR_OCCURRED,
        agent_name="copilot",
        description=f"Deployment failed: {e}",
        impact_level="critical"
    )
    
    # Create checkpoint for retry
    checkpoint_id = committee.context.create_checkpoint("Before retry")
```

---

## Domain Expertise Weights

| Domain | Claude | ChatGPT | Gemini | Copilot | Grok |
|--------|--------|---------|--------|---------|------|
| architecture | 2.0 | 1.0 | 1.5 | 1.5 | 1.0 |
| content | 1.5 | 2.0 | 0.5 | 0.5 | 1.0 |
| cloud | 1.5 | 0.5 | 2.0 | 1.0 | 1.0 |
| database | 1.5 | 0.5 | 2.0 | 1.0 | 1.0 |
| innovation | 1.5 | 1.0 | 1.0 | 1.0 | 2.0 |
| research | 1.5 | 1.0 | 1.0 | 1.0 | 2.0 |
| code | 1.0 | 0.5 | 1.5 | 2.0 | 1.0 |
| deployment | 1.0 | 0.5 | 1.5 | 2.0 | 1.0 |

---

## Event Types

```python
ContextEventType.PROJECT_START
ContextEventType.PLANNING_PHASE
ContextEventType.TASK_STARTED
ContextEventType.TASK_COMPLETED
ContextEventType.DECISION_MADE
ContextEventType.AGENT_ACTION
ContextEventType.VOTE_CREATED
ContextEventType.VOTE_COMPLETED
ContextEventType.ERROR_OCCURRED
ContextEventType.MILESTONE_REACHED
ContextEventType.RATE_LIMIT_HIT
ContextEventType.DISCONNECT
ContextEventType.RECONNECT
```

---

## Consensus Levels

- **UNANIMOUS** (95%+): Everyone agrees
- **STRONG** (80-94%): Very high agreement
- **MAJORITY** (60-79%): Clear preference
- **SPLIT** (threshold-59%): Divided
- **FAILED** (<threshold): No consensus

---

## Complete Workflow Example

```python
from orkestra.committee import Committee
from orkestra.context import ContextEventType

# Initialize
committee = Committee(".")

# 1. Start working
committee.context.update_agent_understanding(
    "claude",
    "Researching authentication approaches",
    active_tasks=["task_auth_research"],
    confidence_level=0.6
)

# 2. Create vote for decision
vote_id = committee.democracy.create_vote(
    title="Choose auth method",
    description="Select authentication approach",
    options=["JWT", "Sessions", "OAuth2"],
    domain="architecture",
    proposed_by="claude"
)

# 3. Vote
committee.democracy.cast_vote(
    vote_id, "claude", "option_1",
    "JWT is stateless and scales well"
)

# Other agents vote...

# 4. Close vote
result = committee.democracy.close_vote(vote_id)

# 5. Update with decision
committee.context.update_agent_understanding(
    "claude",
    f"Decision: {result['winning_description']}. Implementing JWT auth.",
    active_tasks=["task_auth_implement"],
    completed_tasks=["task_auth_research"],
    confidence_level=0.9
)

# 6. Rate limit!
committee.context.handle_rate_limit("claude", 60)

# 7. Reconnect
summary = committee.context.handle_reconnect("claude")
# You know: Decision was JWT, now implementing, 90% confident

# 8. Complete
committee.context.task_completed("task_auth_implement", "claude")
```

---

## File Locations

```
orkestra/
├── context/
│   ├── project-context.json      # Main state
│   ├── events/                   # Event history
│   ├── checkpoints/              # Recovery points
│   └── agent-logs/              # Detailed logs
│       ├── claude-log.json
│       ├── chatgpt-log.json
│       ├── gemini-log.json
│       ├── copilot-log.json
│       └── grok-log.json
└── logs/
    ├── voting/                  # Vote records
    └── outcomes/                # Decisions
```

---

## Best Practices

✅ **DO:**
- Update understanding after every action
- Use checkpoints before risky operations
- Vote with detailed reasoning
- Check pending votes regularly
- Read recovery summary after reconnect

❌ **DON'T:**
- Skip understanding updates
- Ignore pending votes
- Vote without reasoning
- Forget to log important events
- Continue without recovery summary

---

## Troubleshooting

### Can't find my last state
```python
state = committee.context.get_agent_understanding("claude")
print(state.current_understanding)
```

### Vote not appearing
```python
status = committee.democracy.get_vote_status(vote_id)
print(status)
```

### Lost track of tasks
```python
summary = committee.context.get_recovery_summary("claude")
print(summary)
```

---

For full documentation: `DOCS/TECHNICAL/CONTEXT_AND_DEMOCRACY.md`
