# 🗳️ Complete Orkestra Voting Process Demo

## Overview
This document demonstrates the complete process of calling a vote in Orkestra, from initiation to final outcome.

---

## Step 1: Start Orkestra and Access Menu

```bash
# From anywhere
$ orkestra

📂 Switched to: my-project at /path/to/my-project
🎼 Starting Orkestra...
✓ Orkestra started successfully!

Launching Orkestra menu...

╔════════════════════════════════════════════════════════════╗
║                    O R K E S T R A                         ║
║            Democratic AI Coordination System               ║
╚════════════════════════════════════════════════════════════╝

Current Project: my-project
Location: /path/to/my-project

═══ MAIN MENU ═══

1) Committee System    (Vote/Question/Collaboration)
2) Task Management     (Queue/Status/Assign)
3) Project Browser     (View/Switch/Create)
4) AI Status           (Check all AI systems)
5) Documentation       (Guides/Quick Ref)
6) System Info         (Version/Status)
7) Exit

Select option [1-7]: 1  ← Select Committee System
```

---

## Step 2: Access Committee Menu

```
╔════════════════════════════════════════════════════════════╗
║                  COMMITTEE SYSTEM                          ║
║              Democratic AI Collaboration                   ║
╚════════════════════════════════════════════════════════════╝

Committee Options:

  1) Call a Vote
  2) Ask a Question
  3) View Active Items
  4) View Results
  5) Exit

Select option [1-5]: 1  ← Call a Vote
```

---

## Step 3: Define Vote Parameters

```
=== CALL A VOTE ===

Vote topic: Should we implement JWT authentication or OAuth2?
Number of options (2-10): 2
Number of rounds (1-10): 3
```

---

## Step 4: Enter Vote Options

```
Enter options (one per line):
  Option 1: JWT (JSON Web Tokens) with refresh tokens
  Option 2: OAuth2 with third-party providers (Google, GitHub)

Gathering relevant context...
✓ Context gathered from project files and documentation
```

---

## Step 5: Vote File Created

The system automatically creates a vote file in the project:

**Location**: `my-project/orkestra/logs/voting/vote-20251102-235945-a3f8d1e2.json`

```json
{
  "vote_id": "vote-20251102-235945-a3f8d1e2",
  "project": "my-project",
  "timestamp": "2025-11-02T23:59:45.123456",
  "status": "active",
  "topic": "Should we implement JWT authentication or OAuth2?",
  "options": [
    {
      "id": 1,
      "description": "JWT (JSON Web Tokens) with refresh tokens",
      "votes": []
    },
    {
      "id": 2,
      "description": "OAuth2 with third-party providers (Google, GitHub)",
      "votes": []
    }
  ],
  "rounds": 3,
  "current_round": 1,
  "context": "Project needs secure authentication. Current stack: Node.js/Express API. Frontend: React. Requirements: Mobile app support, scalability.",
  "agents_required": ["claude", "chatgpt", "gemini", "copilot", "grok"],
  "ballot": []
}
```

---

## Step 6: Committee Process Starts

```
✅ Vote created!

File: my-project/orkestra/logs/voting/vote-20251102-235945-a3f8d1e2.json
Hash: a3f8d1e2

Start committee process now? [y/N]: y  ← Start immediately

🎼 Committee Process Initiated
════════════════════════════════════════════════════════════

Notifying AI agents...
  ✓ Claude notified
  ✓ ChatGPT notified
  ✓ Gemini notified
  ✓ Copilot notified
  ✓ Grok notified

Round 1 of 3 starting...
```

---

## Step 7: Round 1 - Initial Votes

Each AI agent independently reviews the vote and casts their vote:

```
Round 1 Results:
════════════════════════════════════════════════════════════

Claude: Option 1 (JWT)
Reasoning: "JWT is simpler to implement, provides stateless authentication,
           and works well with mobile apps. Better control over token lifecycle."

ChatGPT: Option 2 (OAuth2)
Reasoning: "OAuth2 provides better security with third-party authentication,
           reduces password management burden, and is industry standard."

Gemini: Option 1 (JWT)
Reasoning: "For this project size and requirements, JWT offers better performance
           and simpler deployment. OAuth2 adds unnecessary complexity."

Copilot: Option 2 (OAuth2)
Reasoning: "OAuth2 is more secure long-term, provides social login options
           that users expect, and scales better with microservices."

Grok: Option 1 (JWT)
Reasoning: "JWT gives you full control, no external dependencies, works
           offline, and is perfect for mobile-first architecture."

Current Tally:
  Option 1 (JWT): 3 votes
  Option 2 (OAuth2): 2 votes

Round 1 complete. Starting Round 2...
```

---

## Step 8: Round 2 - Discussion & Revote

Agents see each other's reasoning and can change votes:

```
Round 2 Results:
════════════════════════════════════════════════════════════

Claude: Option 1 (JWT) [UNCHANGED]
Update: "After reviewing other arguments, JWT still best fits our needs."

ChatGPT: Option 1 (JWT) [CHANGED from Option 2]
Update: "Good points about complexity. Given our mobile-first requirement
        and team size, JWT is more pragmatic. We can add OAuth later."

Gemini: Option 1 (JWT) [UNCHANGED]
Update: "Maintaining vote. Performance and control are critical here."

Copilot: Option 2 (OAuth2) [UNCHANGED]
Update: "Security concerns remain. OAuth2 is worth the initial complexity."

Grok: Option 1 (JWT) [UNCHANGED]
Update: "JWT advantages are clear for this use case."

Current Tally:
  Option 1 (JWT): 4 votes
  Option 2 (OAuth2): 1 vote

Strong consensus emerging. Starting Round 3 (final)...
```

---

## Step 9: Round 3 - Final Vote

```
Round 3 Results (FINAL):
════════════════════════════════════════════════════════════

Claude: Option 1 (JWT) [UNCHANGED]
ChatGPT: Option 1 (JWT) [UNCHANGED]
Gemini: Option 1 (JWT) [UNCHANGED]
Copilot: Option 1 (JWT) [CHANGED from Option 2]
  Final note: "Consensus is clear. JWT is the right choice for now.
               We'll document a migration path to OAuth2 if needed later."
Grok: Option 1 (JWT) [UNCHANGED]

FINAL TALLY:
════════════════════════════════════════════════════════════
  Option 1 (JWT): 5 votes (100%)
  Option 2 (OAuth2): 0 votes (0%)

✅ VOTE DECIDED: Option 1 (JWT) WINS
```

---

## Step 10: Outcome Recorded

The system automatically creates an outcome file:

**Location**: `my-project/orkestra/logs/outcomes/outcome-20251102-235945-a3f8d1e2.json`

```json
{
  "outcome_id": "outcome-20251102-235945-a3f8d1e2",
  "vote_id": "vote-20251102-235945-a3f8d1e2",
  "project": "my-project",
  "timestamp": "2025-11-03T00:05:12.987654",
  "decision": "option_1",
  "decision_text": "JWT (JSON Web Tokens) with refresh tokens",
  "final_vote_count": {
    "option_1": 5,
    "option_2": 0
  },
  "consensus_level": "unanimous",
  "total_rounds": 3,
  "vote_changes": [
    {
      "agent": "chatgpt",
      "round": 2,
      "from": "option_2",
      "to": "option_1"
    },
    {
      "agent": "copilot",
      "round": 3,
      "from": "option_2",
      "to": "option_1"
    }
  ],
  "implementation_notes": [
    "Implement JWT with refresh tokens",
    "Add token rotation for security",
    "Document migration path to OAuth2 if needed",
    "Ensure mobile app compatibility",
    "Set appropriate token expiration times"
  ],
  "decided_by": "committee_vote",
  "status": "completed"
}
```

---

## Step 11: Implementation Action Items

The system can optionally create tasks in the task queue:

```
📋 Creating implementation tasks...

✓ Task created: Implement JWT authentication middleware
✓ Task created: Create token refresh endpoint
✓ Task created: Add JWT configuration to environment
✓ Task created: Update API documentation
✓ Task created: Write JWT integration tests

Tasks added to: my-project/orkestra/config/task-queues/task-queue.json
```

---

## Step 12: View Results in Menu

```
╔════════════════════════════════════════════════════════════╗
║                  COMMITTEE SYSTEM                          ║
╚════════════════════════════════════════════════════════════╝

Committee Options:

  1) Call a Vote
  2) Ask a Question
  3) View Active Items
  4) View Results  ← Select this
  5) Exit

Select option [1-5]: 4
```

```
=== RECENT VOTES ===

1. 🟢 COMPLETED - Should we implement JWT authentication or OAuth2?
   Decision: JWT (JSON Web Tokens) with refresh tokens
   Result: Unanimous (5-0)
   Date: 2025-11-02 23:59:45
   
2. 🟡 ACTIVE - Database migration strategy
   Status: Round 2 of 3 in progress
   Current: PostgreSQL (3 votes) vs MySQL (2 votes)
   
3. 🟢 COMPLETED - Choose frontend framework
   Decision: React with TypeScript
   Result: Strong consensus (4-1)
   Date: 2025-11-01 14:22:10

Select a vote to view details or press Enter to go back:
```

---

## Summary of Files Created

After a complete vote, you'll have:

```
my-project/
└── orkestra/
    ├── logs/
    │   ├── voting/
    │   │   └── vote-20251102-235945-a3f8d1e2.json
    │   └── outcomes/
    │       └── outcome-20251102-235945-a3f8d1e2.json
    └── config/
        └── task-queues/
            └── task-queue.json  (updated with new tasks)
```

---

## Key Features Demonstrated

✅ **Democratic Decision Making** - All 5 AI agents get equal vote  
✅ **Multi-Round Deliberation** - Agents can change votes after discussion  
✅ **Full Transparency** - Every vote and reason is recorded  
✅ **Context Awareness** - System gathers relevant project context  
✅ **Audit Trail** - Complete history in version-controlled logs  
✅ **Action Items** - Automatic task creation from decisions  
✅ **Git Integration** - All outcomes tracked in project repository  

---

## Alternative: Quick Vote via CLI

You can also call votes programmatically:

```bash
# Direct vote call
orkestra vote \
  --topic "Authentication method" \
  --options "JWT,OAuth2" \
  --rounds 3

# One-liner for urgent decisions
orkestra vote --quick "Should we merge PR #123?" --options "yes,no"
```

---

## Notes

- **Minimum 2 options, maximum 10**
- **Minimum 1 round, maximum 10**
- **All votes stored in project's orkestra/logs/voting/**
- **All outcomes stored in project's orkestra/logs/outcomes/**
- **Agents can change votes in later rounds**
- **Consensus threshold: 80% for "strong", 100% for "unanimous"**
- **Failed votes (no consensus after max rounds) are recorded as "no_decision"**

---

*This is the complete democratic AI decision-making process in Orkestra!* 🎼
