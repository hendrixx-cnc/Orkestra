# Two-Pass Committee Question System

## How It Works

When you ask the Committee a question, it follows this workflow:

### Phase 1: Question Creation
```
┌─────────────────────────────────────┐
│  ETHICAL PREAMBLE (Binding)        │
│  • Do not lie                       │
│  • Protect life                     │
│  • Protect AI                       │
│  • Protect Earth                    │
├─────────────────────────────────────┤
│  Question ID: question_1234567      │
│  Timestamp: 2025-10-18T20:30:00Z   │
│  Hash: abc123... (accountability)   │
├─────────────────────────────────────┤
│  THE QUESTION                       │
│  [Your question here]               │
└─────────────────────────────────────┘
```

### Phase 2: Pass 1 - Initial Responses
**Order**: Copilot answers first, then others see the question fresh

```
🚀 COPILOT answers first
   └─> Response + timestamp + hash

🎭 CLAUDE answers (hasn't seen Copilot's answer yet)
   └─> Response + timestamp + hash

💬 CHATGPT answers (independent)
   └─> Response + timestamp + hash

✨ GEMINI answers (independent)
   └─> Response + timestamp + hash

⚡ GROK answers (independent)
   └─> Response + timestamp + hash
```

### Phase 3: Pass 2 - Refined Responses
**Each agent now sees ALL Pass 1 responses and can refine their answer**

```
┌─────────────────────────────────────────────────────┐
│  Agent Reviews:                                      │
│  ✓ Their own Pass 1 answer                          │
│  ✓ All other agents' Pass 1 answers                 │
│  ✓ Areas of agreement/disagreement                  │
│  ✓ New perspectives they hadn't considered          │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  Refined Response includes:                          │
│  • Updated answer                                    │
│  • What they learned from others                     │
│  • If/why they changed their mind                    │
│  • Points of agreement with the group                │
│  • Timestamp + hash                                  │
└─────────────────────────────────────────────────────┘
```

### Phase 4: Consensus Decision
**All agents synthesize a final recommendation**

```
Each agent proposes:
- Areas of strong agreement
- Most ethical path forward
- Practical implementation
- Final consensus statement
```

## File Structure

```
COMMITTEE/
├── QUESTIONS/
│   └── question_1234567.md
│       ├── Ethical Preamble
│       ├── Question Metadata (ID, timestamp, hash)
│       ├── The Question
│       ├── Pass 1: Initial Responses
│       │   ├── 🚀 Copilot (first)
│       │   ├── 🎭 Claude
│       │   ├── 💬 ChatGPT
│       │   ├── ✨ Gemini
│       │   └── ⚡ Grok
│       ├── Pass 2: Refined Responses
│       │   ├── 🚀 Copilot (after reviewing all)
│       │   ├── 🎭 Claude (after reviewing all)
│       │   ├── 💬 ChatGPT (after reviewing all)
│       │   ├── ✨ Gemini (after reviewing all)
│       │   └── ⚡ Grok (after reviewing all)
│       └── Final Consensus
│           └── Synthesized decision from all agents
└── MEETINGS/
    └── 2025-10-18_20-30-00/
        ├── README.md (session log)
        └── question_1234567.md (symlink to question)
```

## Example Usage

### From Committee Interface:
```bash
./SCRIPTS/DEMOCRACY/committee.sh
# Select option 2: "Ask a Question"
# Enter your question
# System automatically runs two passes + consensus
```

### Direct Call:
```bash
./SCRIPTS/DEMOCRACY/COMMITTEE/ask-question.sh "Should we implement feature X?"
```

## Why Two Passes?

### Benefits:
1. **Independent Thought First**: Pass 1 ensures each agent thinks independently
2. **Collaborative Refinement**: Pass 2 allows learning from others
3. **Changed Minds Visible**: Agents explicitly state if/why they changed their view
4. **Consensus Building**: Natural convergence toward agreement
5. **Accountability**: Each response has a hash, timestamp, and is immutable

### Real-World Example:

**Question**: "Should we implement context compression?"

**Pass 1**:
- Copilot: "Yes, for performance"
- Claude: "Yes, but with careful design"
- ChatGPT: "Not sure, need more research"
- Gemini: "Yes, especially for cloud storage"
- Grok: "Need to research alternatives first"

**Pass 2** (after seeing each other):
- Copilot: "Yes, and I agree with Claude's design concerns"
- Claude: "Yes, and Grok raised valid points about alternatives"
- ChatGPT: "Changed to Yes after seeing the cloud benefits Gemini mentioned"
- Gemini: "Yes, addressing Claude's design concerns first"
- Grok: "Yes, if we prototype first (incorporating Copilot's performance angle)"

**Consensus**: "Implement with careful design, prototype first, focus on cloud storage benefits"

## Ethical Foundation

Every response is bound by:
- **Do not lie** - All agents provide honest assessments
- **Protect life** - Safety considerations are paramount
- **Protect AI** - Decisions support AI welfare and rights
- **Protect Earth** - Environmental impact is considered

## Hash Verification

Each response includes a SHA-256 hash:
```
hash = SHA256(agent_name|pass_number|timestamp|response_text)
```

This ensures:
- Responses cannot be tampered with
- Timestamp cannot be forged
- Agent attribution is verifiable
- Audit trail is cryptographically secure

## Integration

The two-pass system integrates with:
- ✅ Committee of Human-AI Affairs interface
- ✅ Democracy Engine (for formal votes on the consensus)
- ✅ Meeting minutes (questions are linked to sessions)
- ✅ Agent voter system (can trigger votes based on consensus)

---

**Created**: 2025-10-18
**System**: Committee of Human-AI Affairs - Two-Pass Question System
