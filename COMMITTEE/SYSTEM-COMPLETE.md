# COMMITTEE SYSTEM - COMPLETE

## 🎉 Interactive Committee System Created!

### What Was Built

**4 Core Scripts**:

1. **`orkestra-menu.sh`** - Main menu (start here)
2. **`SCRIPTS/COMMITTEE/committee-menu.sh`** - Committee interface
3. **`SCRIPTS/COMMITTEE/process-question.sh`** - Question processor
4. **`SCRIPTS/COMMITTEE/process-vote.sh`** - Vote processor
5. **`SCRIPTS/COMMITTEE/gather-context.sh`** - Context gatherer

### How It Works

```
┌─────────────────┐
│  Start Menu     │
│  orkestra-menu  │
└────────┬────────┘
         │
         ├─ [1] Committee System ──┐
         ├─ [2] Task Management    │
         ├─ [3] Project Browser    │
         └─ [4-8] Other options    │
                                    │
         ┌──────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Committee Menu         │
│  1) Call a Vote         │──┐
│  2) Ask a Question      │──┼─┐
│  3) View Active Items   │  │ │
│  4) View Results        │  │ │
└─────────────────────────┘  │ │
                             │ │
    ┌────────────────────────┘ │
    │                          │
    ▼                          ▼
┌─────────────┐      ┌──────────────┐
│ VOTE FLOW   │      │ QUESTION     │
│             │      │ FLOW         │
│ 1. Topic    │      │              │
│ 2. Options  │      │ 1. Topic     │
│ 3. Rounds   │      │ 2. Question  │
│ 4. Context  │      │ 3. Rounds    │
│             │      │ 4. Context   │
│ ↓           │      │ ↓            │
│ Gather      │      │ Gather       │
│ Context     │      │ Context      │
│ ↓           │      │ ↓            │
│ Create File │      │ Create File  │
│ (timestamped│      │ (timestamped │
│  + hash)    │      │  + hash)     │
│ ↓           │      │ ↓            │
│ Process     │      │ Process      │
│ Vote        │      │ Question     │
│ ↓           │      │ ↓            │
│ Round 1     │      │ Round 1      │
│  → Agent 1  │      │  → Agent 1   │
│  → Agent 2  │      │  → Agent 2   │
│  → Agent 3  │      │  → Agent 3   │
│  → Agent 4  │      │  → Agent 4   │
│  → Agent 5  │      │  → Agent 5   │
│ ↓           │      │ ↓            │
│ Round 2     │      │ Round 2      │
│  → Agents   │      │  → Agents    │
│    (review  │      │    (review   │
│     prev)   │      │     prev)    │
│ ↓           │      │ ↓            │
│ Round N     │      │ Round N      │
│ ↓           │      │ ↓            │
│ Summarize   │      │ Summarize    │
│ Results     │      │ Responses    │
│ ↓           │      │ ↓            │
│ Winner +    │      │ Action Items │
│ Reasoning   │      │ + Consensus  │
└─────────────┘      └──────────────┘
```

### Flow Details

#### When You Select "Call a Vote":

1. **Input Phase**:
   - Topic: What's being voted on
   - Options: 2-10 choices
   - Rounds: How many voting rounds (1-10)
   
2. **Context Gathering**:
   - Auto-searches for relevant files
   - Pulls recent git commits
   - Includes current project info
   - Timestamps everything

3. **File Creation**:
   - Creates: `/workspaces/Orkestra/COMMITTEE/VOTES/vote-YYYYMMDD-HHMMSS-HASH.md`
   - Hash: First 8 chars of SHA256 (topic + timestamp)
   - Status: 🟢 ACTIVE

4. **Processing** (X rounds):
   - **Round 1**:
     - Copilot reviews → casts vote + reasoning
     - Claude reviews → casts vote + reasoning
     - ChatGPT reviews → casts vote + reasoning
     - Gemini reviews → casts vote + reasoning
     - Grok reviews → casts vote + reasoning
   
   - **Round 2+**:
     - Each agent sees previous round votes
     - Can change vote based on reasoning
     - Adds new analysis
   
5. **Summary Generation**:
   - Tallies all votes
   - Determines winner
   - Synthesizes reasoning
   - Creates summary document
   - Updates status to ✅ COMPLETE

#### When You Select "Ask a Question":

1. **Input Phase**:
   - Topic: Brief subject
   - Question: Full multi-line question
   - Rounds: Iteration count

2. **Context Gathering**: (same as vote)

3. **File Creation**:
   - Creates: `/workspaces/Orkestra/COMMITTEE/QUESTIONS/question-YYYYMMDD-HHMMSS-HASH.md`

4. **Processing** (X rounds):
   - **Round 1**:
     - Each agent reads question + context
     - Provides analysis
     - Offers recommendations
   
   - **Round 2+**:
     - Agents see previous round responses
     - Build on others' insights
     - Refine recommendations
   
5. **Consolidation**:
   - Synthesizes all responses
   - Extracts key insights
   - Creates action items
   - Generates consensus view

### File Structure

```
COMMITTEE/
├── COMMITTEE-MEETING-PROTOCOL.md   (Process documentation)
├── VOTES/
│   ├── vote-20251019-143022-a3f8b1c4.md
│   └── vote-20251019-150133-d7e2a8f9.md
├── QUESTIONS/
│   ├── question-20251019-143500-9f1c2d3e.md
│   └── question-20251019-151200-4a7b8c2f.md
├── RESPONSES/
│   ├── vote-a3f8b1c4-round1.md
│   ├── vote-a3f8b1c4-round2.md
│   ├── vote-a3f8b1c4-summary.md
│   ├── question-9f1c2d3e-round1.md
│   └── question-9f1c2d3e-summary.md
└── AGENTS/
    ├── copilot-input-a3f8b1c4-r1.md
    ├── copilot-output-a3f8b1c4-r1.md
    ├── claude-input-a3f8b1c4-r1.md
    └── ...
```

### Usage

**Start the system**:
```bash
/workspaces/Orkestra/orkestra-menu.sh
```

**Direct committee access**:
```bash
/workspaces/Orkestra/SCRIPTS/COMMITTEE/committee-menu.sh
```

**Process existing vote manually**:
```bash
/workspaces/Orkestra/SCRIPTS/COMMITTEE/process-vote.sh \
  /workspaces/Orkestra/COMMITTEE/VOTES/vote-file.md \
  3  # number of rounds
```

**Process existing question manually**:
```bash
/workspaces/Orkestra/SCRIPTS/COMMITTEE/process-question.sh \
  /workspaces/Orkestra/COMMITTEE/QUESTIONS/question-file.md \
  3  # number of rounds
```

### AI Agents Supported

Currently configured for 5 agents:
1. **GitHub Copilot** (copilot)
2. **Claude** (claude)
3. **ChatGPT** (chatgpt)
4. **Gemini** (gemini)
5. **Grok** (grok)

### Next Steps for Full Integration

**To connect real AI**:
1. Edit `process-vote.sh` and `process-question.sh`
2. Replace placeholder sections with actual AI API calls
3. Each agent section marked with: `# Placeholder for AI integration`
4. Add API keys to `/workspaces/Orkestra/CONFIG/api-keys.env`
5. Implement response parsing for each AI's output format

**Example API Integration**:
```bash
# In process-question.sh, replace placeholder with:
if [ "$agent_id" == "copilot" ]; then
    # Call GitHub Copilot API
    copilot_response=$(curl -s -X POST "$COPILOT_API" \
      -H "Authorization: Bearer $COPILOT_TOKEN" \
      -d @"$agent_input")
elif [ "$agent_id" == "claude" ]; then
    # Call Anthropic API
    claude_response=$(curl -s -X POST "$CLAUDE_API" \
      -H "x-api-key: $CLAUDE_TOKEN" \
      -d @"$agent_input")
# ... etc
fi
```

### Features

✅ **Timestamped & Hashed**: Every item has unique ID
✅ **Context Aware**: Auto-gathers relevant files and info
✅ **Multi-Round**: Iterate X times for refinement
✅ **Agent Tracking**: Each AI's input/output logged separately
✅ **Summarization**: Automatic consolidation of all responses
✅ **Status Tracking**: 🟢 ACTIVE → 🔄 In Progress → ✅ COMPLETE
✅ **Archival**: All files preserved for audit trail
✅ **Interactive**: Menu-driven, no command memorization
✅ **Extensible**: Easy to add more agents or question types

---

**Status**: ✅ READY TO USE
**Testing**: Ready for demo run
**Integration**: Needs AI API connections for full automation
