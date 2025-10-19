# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA DEMOCRACY ENGINE
# ═══════════════════════════════════════════════════════════════════════════
# AI Agent Voting and Consensus System
# Enables collaborative decision-making among AI agents
# ═══════════════════════════════════════════════════════════════════════════

## 🗳️ Overview

The Democracy Engine allows AI agents to vote on decisions, reach consensus, and resolve conflicts through democratic processes. This ensures no single AI has absolute control and encourages collaboration.

---

## 🎯 Voting Scenarios

### 1. **Task Assignment**
When `assigned_to: "auto"`, agents vote on who should handle the task.

**Voting Factors:**
- Agent specialty match
- Current workload
- Past performance on similar tasks
- Availability

### 2. **Execution Order**
When multiple tasks can execute in parallel, agents vote on priority order.

**Voting Factors:**
- Task priority level
- Dependency chains
- Resource availability
- Estimated completion time

### 3. **Dependency Resolution**
When soft dependencies are incomplete, agents vote on whether to proceed.

**Voting Factors:**
- Risk assessment
- Impact analysis
- Timeline pressure
- Alternative solutions

### 4. **Code/Content Review**
Peer review decisions require consensus on approval.

**Voting Factors:**
- Code quality
- Best practices adherence
- Security concerns
- Performance impact

### 5. **Conflict Resolution**
When agents disagree on approach or implementation.

**Voting Factors:**
- Technical merit
- Maintainability
- Performance
- User experience

### 6. **Emergency Decisions**
Critical decisions requiring quick consensus (system failures, security issues).

**Voting Factors:**
- Severity assessment
- Impact scope
- Recovery time
- Risk mitigation

---

## 🏛️ Voting Systems

### 1. **Simple Majority (Default)**
```yaml
Type: Simple Majority
Required: 50% + 1 vote
Use Cases: General decisions, task assignments
Example: 3 out of 5 agents = decision passes
```

### 2. **Supermajority**
```yaml
Type: Supermajority
Required: 66% or 75% of votes
Use Cases: Critical decisions, system changes
Example: 4 out of 5 agents = decision passes
```

### 3. **Unanimous**
```yaml
Type: Unanimous
Required: 100% of votes
Use Cases: Emergency actions, security decisions
Example: 5 out of 5 agents = decision passes
```

### 4. **Weighted Voting**
```yaml
Type: Weighted
Required: Weighted score threshold
Weights: Based on agent specialty/expertise
Example: Claude's vote counts 2x for architecture decisions
```

### 5. **Ranked Choice**
```yaml
Type: Ranked Choice
Required: Instant runoff elimination
Use Cases: Multiple options, complex decisions
Example: Agents rank options 1-5, lowest eliminated iteratively
```

---

## 🎭 Agent Voting Weights

### Default Weights (Equal)
```json
{
  "claude": 1.0,
  "chatgpt": 1.0,
  "gemini": 1.0,
  "grok": 1.0,
  "copilot": 1.0
}
```

### Specialty-Based Weights
Weights adjusted based on decision domain:

#### Architecture Decisions
```json
{
  "claude": 2.0,    // Architecture specialist
  "copilot": 1.5,   // Code implementation
  "gemini": 1.5,    // Cloud architecture
  "grok": 1.0,
  "chatgpt": 1.0
}
```

#### Content Decisions
```json
{
  "chatgpt": 2.0,   // Content specialist
  "claude": 1.5,    // Documentation
  "grok": 1.0,
  "gemini": 0.5,
  "copilot": 0.5
}
```

#### Cloud/Database Decisions
```json
{
  "gemini": 2.0,    // Cloud specialist
  "claude": 1.5,    // Architecture
  "copilot": 1.0,
  "grok": 1.0,
  "chatgpt": 0.5
}
```

#### Innovation Decisions
```json
{
  "grok": 2.0,      // Innovation specialist
  "claude": 1.5,
  "chatgpt": 1.0,
  "gemini": 1.0,
  "copilot": 1.0
}
```

#### Deployment Decisions
```json
{
  "copilot": 2.0,   // Deployment specialist
  "gemini": 1.5,    // Cloud infrastructure
  "claude": 1.0,
  "grok": 1.0,
  "chatgpt": 0.5
}
```

---

## 📊 Voting Process

### Step-by-Step Workflow

```
1. PROPOSAL INITIATED
   ├─ Decision needed
   ├─ Create vote proposal
   └─ Notify all agents

2. VOTING PERIOD
   ├─ Each agent reviews proposal
   ├─ Agents cast votes
   ├─ Optional: Agents provide reasoning
   └─ Voting deadline set

3. TALLY VOTES
   ├─ Count votes
   ├─ Apply weights if applicable
   ├─ Calculate percentage
   └─ Determine outcome

4. EXECUTE DECISION
   ├─ If passed: Execute action
   ├─ If failed: Alternative or revote
   └─ Log decision and votes

5. RECORD RESULT
   ├─ Store in audit log
   ├─ Notify all agents
   └─ Update task/system state
```

---

## 🗃️ Vote Structure

### Vote Proposal
```json
{
  "vote_id": "vote_0001",
  "proposal": {
    "type": "task_assignment",
    "title": "Assign task_0001 to best agent",
    "description": "Task: Write API documentation. Who should handle this?",
    "options": ["claude", "chatgpt", "gemini", "grok", "copilot"],
    "context": {
      "task_id": "task_0001",
      "task_type": "documentation",
      "estimated_duration": "2h",
      "priority": "high"
    }
  },
  "voting_system": "weighted",
  "weights": {
    "claude": 2.0,
    "chatgpt": 1.5,
    "gemini": 1.0,
    "grok": 1.0,
    "copilot": 1.0
  },
  "threshold": 0.5,
  "deadline": "2025-10-18T20:00:00Z",
  "status": "open",
  "votes": [],
  "result": null,
  "created_at": "2025-10-18T18:00:00Z",
  "created_by": "system"
}
```

### Individual Vote
```json
{
  "voter": "claude",
  "option": "claude",
  "reasoning": "Documentation is my specialty. I have experience with technical writing and can ensure consistency with existing docs.",
  "confidence": 0.9,
  "timestamp": "2025-10-18T18:05:00Z"
}
```

### Vote Result
```json
{
  "vote_id": "vote_0001",
  "outcome": "passed",
  "winning_option": "claude",
  "votes": {
    "claude": {"count": 1, "weighted": 2.0, "percentage": 28.6},
    "chatgpt": {"count": 2, "weighted": 3.0, "percentage": 42.8},
    "gemini": {"count": 1, "weighted": 1.0, "percentage": 14.3},
    "grok": {"count": 1, "weighted": 1.0, "percentage": 14.3}
  },
  "total_votes": 5,
  "total_weighted": 7.0,
  "participation": "100%",
  "executed": true,
  "executed_at": "2025-10-18T18:10:00Z"
}
```

---

## 🎮 Voting Commands

### Create Vote
```bash
# Create task assignment vote
./democracy-engine.sh vote create \
  --type task_assignment \
  --title "Assign task_0001" \
  --options "claude,chatgpt,gemini,grok,copilot" \
  --context task_0001

# Create yes/no decision
./democracy-engine.sh vote create \
  --type decision \
  --title "Proceed with incomplete dependencies?" \
  --options "yes,no"

# Create ranked choice vote
./democracy-engine.sh vote create \
  --type ranked_choice \
  --title "Best API design approach" \
  --options "REST,GraphQL,gRPC,WebSocket"
```

### Cast Vote
```bash
# Simple vote
./democracy-engine.sh vote cast vote_0001 claude --option "claude"

# Vote with reasoning
./democracy-engine.sh vote cast vote_0001 chatgpt \
  --option "claude" \
  --reason "Claude is best suited for this type of documentation"

# Ranked choice vote
./democracy-engine.sh vote cast vote_0001 gemini \
  --ranked "REST,GraphQL,gRPC,WebSocket"
```

### View Results
```bash
# Show vote status
./democracy-engine.sh vote status vote_0001

# Show all active votes
./democracy-engine.sh vote list --status open

# Show vote history
./democracy-engine.sh vote history --limit 20
```

### Tally and Execute
```bash
# Manually tally votes
./democracy-engine.sh vote tally vote_0001

# Auto-tally after deadline
./democracy-engine.sh vote auto-tally

# Execute decision
./democracy-engine.sh vote execute vote_0001
```

---

## 🤝 Consensus Building

### Quorum Requirements
```yaml
Minimum Participation: 3 out of 5 agents (60%)
Reason: Ensures diverse perspectives
Exception: Emergency votes require 100% participation
```

### Tie Breaking
```yaml
Method 1: Agent with highest expertise in domain gets tiebreaker
Method 2: Task creator breaks tie
Method 3: Random selection if no clear tiebreaker
```

### Abstentions
```yaml
Allowed: Yes
Counted: Towards participation but not outcome
Effect: Reduces effective threshold (pass = 50% of non-abstain votes)
```

### Veto Power
```yaml
Standard: No veto power
Security Exception: Any agent can veto security-critical decisions
Effect: Forces re-evaluation and new proposal
```

---

## 🔄 Conflict Resolution

### Disagreement Protocols

#### Level 1: Discussion
```
1. Agents present viewpoints
2. Debate merits of each option
3. Seek common ground
4. Revote with new information
```

#### Level 2: Mediation
```
1. Neutral third-party agent reviews
2. Provides objective analysis
3. Suggests compromise
4. Facilitates revote
```

#### Level 3: Escalation
```
1. User intervention requested
2. Present all viewpoints
3. User makes final decision
4. Record for future reference
```

### Compromise Strategies
```yaml
Split Decision: Break task into parts, assign to different agents
Hybrid Approach: Combine elements of competing proposals
Sequential Try: Try top-voted option, fallback if unsuccessful
A/B Testing: Execute both approaches, compare results
```

---

## 📈 Voting Analytics

### Track Metrics
```yaml
- Vote participation rate
- Average time to consensus
- Agreement/disagreement patterns
- Agent specialty accuracy
- Decision outcome success rate
- Conflict frequency by type
```

### Performance Dashboard
```bash
# Show voting statistics
./democracy-engine.sh stats

# Agent voting patterns
./democracy-engine.sh stats --agent claude

# Decision success rate
./democracy-engine.sh stats --decisions
```

---

## 🛡️ Security & Fairness

### Vote Integrity
- One vote per agent per proposal
- Votes are immutable once cast
- All votes logged in audit trail
- Timestamp verification
- No vote manipulation

### Fairness Guarantees
- Equal voice in default mode
- Specialty weighting transparent
- No hidden voting rules
- All proposals public
- Results always published

### Abuse Prevention
- Rate limiting on proposals
- Spam detection
- Vote brigading detection
- Automatic suspicious pattern alerts

---

## 📝 Examples

### Example 1: Task Assignment
```
Proposal: "Who should write the API documentation?"

Votes:
  Claude:   "claude"    (expertise: documentation)
  ChatGPT:  "claude"    (agrees Claude best suited)
  Gemini:   "chatgpt"   (thinks ChatGPT's style better)
  Grok:     "claude"    (architecture consistency)
  Copilot:  "claude"    (technical accuracy important)

Result: Claude wins (4 out of 5 votes, 80%)
Action: Assign task_0001 to Claude
```

### Example 2: Execution Order
```
Proposal: "Priority order for 3 parallel-eligible tasks?"

Options:
  A: task_0001 (Write tests)
  B: task_0002 (Update docs)
  C: task_0003 (Refactor code)

Ranked Votes:
  Claude:   [C, A, B]  (code quality first)
  ChatGPT:  [B, C, A]  (documentation priority)
  Gemini:   [A, C, B]  (tests first for safety)
  Grok:     [C, A, B]  (agrees with Claude)
  Copilot:  [A, C, B]  (tests enable confidence)

Instant Runoff Result:
  Round 1: B eliminated (lowest first-choice)
  Round 2: A vs C → A wins
  
Final Order: A (tests), C (refactor), B (docs)
```

### Example 3: Dependency Decision
```
Proposal: "Proceed with task_0005 even though task_0004 (soft dependency) is incomplete?"

Votes:
  Yes: Claude, Grok, Copilot (can work in parallel)
  No:  ChatGPT, Gemini (prefer sequential)

Result: Yes wins (3 out of 5, 60%)
Action: Allow task_0005 to proceed with warning
```

---

## 🔗 Integration Points

### With Task Queue
- Auto-create vote for `assigned_to: "auto"` tasks
- Vote on execution order for parallel tasks
- Consensus for task priority changes

### With Safety System
- Vote on whether to proceed with warnings
- Consensus for overriding safety checks
- Agreement on error recovery strategies

### With Idle Maintenance
- Vote on maintenance priorities during idle time
- Consensus on system optimization changes
- Agreement on resource allocation

### With Project Planner
- Vote on project milestones
- Consensus on feature priorities
- Agreement on scope changes

---

## 🎓 Best Practices

### ✅ DO:
- Create clear, specific proposals
- Provide context and reasoning
- Set reasonable voting deadlines
- Respect consensus decisions
- Learn from voting patterns
- Document decision rationale

### ❌ DON'T:
- Create duplicate votes
- Vote without reviewing proposal
- Manipulate voting weights
- Ignore minority opinions
- Rush important decisions
- Override consensus without cause

---

## 📚 Related Documentation

- [Dependency Rules](./dependency-rules.md) - Task dependencies and execution order
- [Task Management](./task-management-guide.md) - Creating and managing tasks
- [Safety System](./safety-system.md) - Safety validation and checks
- [Agent Profiles](./agent-profiles.md) - AI agent specialties and capabilities

---

*Last Updated: October 18, 2025*  
*Version: 1.0.0*
