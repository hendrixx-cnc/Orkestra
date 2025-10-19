# COMMITTEE FILE STRUCTURE

This document describes the complete file structure and connections between committee system files.

## Directory Structure

```
/workspaces/Orkestra/COMMITTEE/
├── MEETINGS/              → Manual meetings (created by humans)
│   └── OUTCOMES/          → Final exported outcomes (auto-generated)
├── VOTES/                 → Vote files (created by committee-menu.sh)
├── QUESTIONS/             → Question files (created by committee-menu.sh)
├── RESPONSES/             → Round-by-round and summary responses
├── AGENTS/                → Individual AI agent I/O files
├── ARCHIVES/              → Completed meetings archived here
├── COMMITTEE-MEETING-PROTOCOL.md   → How to run meetings
├── FILE-STRUCTURE.md      → This file - complete structure & connections
└── SYSTEM-COMPLETE.md     → System documentation
```

## File Connections Map

### 1. VOTE WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT                                                   │
│ ↓                                                            │
│ /workspaces/Orkestra/SCRIPTS/COMMITTEE/committee-menu.sh    │
│   [1] Call a Vote                                            │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ VOTE FILE CREATED                                            │
│ /workspaces/Orkestra/COMMITTEE/VOTES/                       │
│   vote-YYYYMMDD-HHMMSS-HASH.md                              │
│                                                              │
│ Contains:                                                    │
│ - Vote ID (hash)                                             │
│ - Topic                                                      │
│ - Options (numbered)                                         │
│ - Context (auto-gathered)                                    │
│ - Round structure (empty, awaiting responses)               │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ PROCESSING                                                   │
│ /workspaces/Orkestra/SCRIPTS/COMMITTEE/process-vote.sh      │
│   vote-YYYYMMDD-HHMMSS-HASH.md  [num_rounds]               │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                    ┌────┴────┐
                    │ Round 1  │
                    └────┬────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ ROUND 1 RESPONSE FILE                                        │
│ /workspaces/Orkestra/COMMITTEE/RESPONSES/                   │
│   vote-HASH-round1.md                                        │
│                                                              │
│ Contains:                                                    │
│ - Vote question                                              │
│ - All options                                                │
│ - Agent responses section                                    │
└────────────────────────┬────────────────────────────────────┘
                         ↓
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ AGENT INPUT  │ │ AGENT INPUT  │ │ AGENT INPUT  │
│ /COMMITTEE/  │ │ /COMMITTEE/  │ │ /COMMITTEE/  │
│ AGENTS/      │ │ AGENTS/      │ │ AGENTS/      │
│              │ │              │ │              │
│ copilot-vote │ │ claude-vote  │ │ chatgpt-vote │
│ -input-HASH  │ │ -input-HASH  │ │ -input-HASH  │
│ -r1.md       │ │ -r1.md       │ │ -r1.md       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ AGENT OUTPUT │ │ AGENT OUTPUT │ │ AGENT OUTPUT │
│ /COMMITTEE/  │ │ /COMMITTEE/  │ │ /COMMITTEE/  │
│ AGENTS/      │ │ AGENTS/      │ │ AGENTS/      │
│              │ │              │ │              │
│ copilot-vote │ │ claude-vote  │ │ chatgpt-vote │
│ -output-HASH │ │ -output-HASH │ │ -output-HASH │
│ -r1.md       │ │ -r1.md       │ │ -r1.md       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       └────────────────┼────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ ROUND 1 COMPLETE                                             │
│ All responses appended to:                                   │
│ - /COMMITTEE/RESPONSES/vote-HASH-round1.md                  │
│ - /COMMITTEE/VOTES/vote-YYYYMMDD-HHMMSS-HASH.md            │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                    [Round 2, 3, ... N]
                    (same process)
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ FINAL SUMMARY CREATED                                        │
│ /workspaces/Orkestra/COMMITTEE/RESPONSES/                   │
│   vote-HASH-summary.md                                       │
│                                                              │
│ Contains:                                                    │
│ - Winner (option with most votes)                            │
│ - Vote counts per option                                     │
│ - Percentage breakdown                                       │
│ - Reasoning synthesis                                        │
│ - All round summaries                                        │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ VOTE FILE UPDATED                                            │
│ /workspaces/Orkestra/COMMITTEE/VOTES/                       │
│   vote-YYYYMMDD-HHMMSS-HASH.md                              │
│                                                              │
│ Status: ✅ COMPLETE                                          │
│ Winner: [Option X]                                           │
│ Summary: Link to summary file                                │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ FINAL OUTCOME EXPORTED                                       │
│ /workspaces/Orkestra/COMMITTEE/MEETINGS/OUTCOMES/           │
│   vote-outcome-YYYYMMDD-HASH.md                              │
│                                                              │
│ Contains:                                                    │
│ - Original vote question                                     │
│ - Winner & vote counts                                       │
│ - Key reasoning summary                                      │
│ - Action items                                               │
│ - Links to full response files                               │
│                                                              │
│ Purpose: Clean permanent record for easy reference           │
└─────────────────────────────────────────────────────────────┘
```

### 2. QUESTION WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT                                                   │
│ ↓                                                            │
│ /workspaces/Orkestra/SCRIPTS/COMMITTEE/committee-menu.sh    │
│   [2] Ask a Question                                         │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ QUESTION FILE CREATED                                        │
│ /workspaces/Orkestra/COMMITTEE/QUESTIONS/                   │
│   question-YYYYMMDD-HHMMSS-HASH.md                          │
│                                                              │
│ Contains:                                                    │
│ - Question ID (hash)                                         │
│ - Topic                                                      │
│ - Full question text                                         │
│ - Context (auto-gathered)                                    │
│ - Round structure (empty)                                    │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ PROCESSING                                                   │
│ /workspaces/Orkestra/SCRIPTS/COMMITTEE/process-question.sh  │
│   question-YYYYMMDD-HHMMSS-HASH.md  [num_rounds]           │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                    ┌────┴────┐
                    │ Round 1  │
                    └────┬────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ ROUND 1 RESPONSE FILE                                        │
│ /workspaces/Orkestra/COMMITTEE/RESPONSES/                   │
│   question-HASH-round1.md                                    │
│                                                              │
│ Contains:                                                    │
│ - Original question                                          │
│ - Agent responses section                                    │
└────────────────────────┬────────────────────────────────────┘
                         ↓
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ AGENT INPUT  │ │ AGENT INPUT  │ │ AGENT INPUT  │
│ copilot-     │ │ claude-      │ │ gemini-      │
│ input-HASH   │ │ input-HASH   │ │ input-HASH   │
│ -r1.md       │ │ -r1.md       │ │ -r1.md       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       ↓                ↓                ↓
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ AGENT OUTPUT │ │ AGENT OUTPUT │ │ AGENT OUTPUT │
│ copilot-     │ │ claude-      │ │ gemini-      │
│ output-HASH  │ │ output-HASH  │ │ output-HASH  │
│ -r1.md       │ │ -r1.md       │ │ -r1.md       │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       └────────────────┼────────────────┘
                        ↓
                    [Round 2]
                    (includes previous round's responses)
                        ↓
┌─────────────────────────────────────────────────────────────┐
│ ROUND 2 RESPONSE FILE                                        │
│ /workspaces/Orkestra/COMMITTEE/RESPONSES/                   │
│   question-HASH-round2.md                                    │
│                                                              │
│ Contains:                                                    │
│ - Original question                                          │
│ - Previous round summary                                     │
│ - New agent responses (building on previous)                │
└────────────────────────┬────────────────────────────────────┘
                         ↓
                    [Round 3, ... N]
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ CONSOLIDATED RESPONSE CREATED                                │
│ /workspaces/Orkestra/COMMITTEE/RESPONSES/                   │
│   question-HASH-summary.md                                   │
│                                                              │
│ Contains:                                                    │
│ - Original question                                          │
│ - All round summaries                                        │
│ - Key insights (synthesized)                                 │
│ - Recommended actions                                        │
│ - Areas of agreement/disagreement                            │
│ - Next steps                                                 │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ QUESTION FILE UPDATED                                        │
│ /workspaces/Orkestra/COMMITTEE/QUESTIONS/                   │
│   question-YYYYMMDD-HHMMSS-HASH.md                          │
│                                                              │
│ Status: ✅ COMPLETE                                          │
│ Summary: Link to consolidated response                       │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ FINAL OUTCOME EXPORTED                                       │
│ /workspaces/Orkestra/COMMITTEE/MEETINGS/OUTCOMES/           │
│   question-outcome-YYYYMMDD-HASH.md                          │
│                                                              │
│ Contains:                                                    │
│ - Original question                                          │
│ - Key insights from all rounds                               │
│ - Recommended actions                                        │
│ - Areas of consensus                                         │
│ - Next steps                                                 │
│ - Links to full response files                               │
│                                                              │
│ Purpose: Clean permanent record for easy reference           │
└─────────────────────────────────────────────────────────────┘
```

### 3. MANUAL MEETING WORKFLOW

```
┌─────────────────────────────────────────────────────────────┐
│ MANUAL MEETING FILE CREATED (by human)                      │
│ /workspaces/Orkestra/COMMITTEE/MEETINGS/                    │
│   [topic]-[date].md                                          │
│                                                              │
│ Example: compression-optimization-2025-10-19.md             │
│                                                              │
│ Contains:                                                    │
│ - Agenda                                                     │
│ - Files for review (with paths)                              │
│ - Specific questions                                         │
│ - Deliverables                                               │
│ - Meeting notes section (for AI responses)                   │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ AI AGENTS REVIEW & RESPOND                                   │
│ (Directly in meeting file)                                   │
│                                                              │
│ Each agent adds their section:                               │
│                                                              │
│ ### Agent 1: [Role] - [Name]                                │
│ **Timestamp**: YYYY-MM-DD HH:MM                             │
│ **Status**: ✅ Complete                                      │
│ **Analysis**: [findings]                                     │
│ **Recommendations**: [list]                                  │
│ **Vote**: [if applicable]                                    │
│                                                              │
└────────────────────────┬────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ MEETING STATUS UPDATED                                       │
│ Status: 🟢 ACTIVE → ✅ COMPLETE                             │
│                                                              │
│ Once complete, meeting file can be:                          │
│ - Left in MEETINGS/ (for active reference)                  │
│ - Moved to ARCHIVES/ (when no longer active)                │
└─────────────────────────────────────────────────────────────┘
```

## File Naming Conventions

### Votes
- **Main file**: `vote-YYYYMMDD-HHMMSS-HASH.md`
- **Hash**: First 8 chars of SHA256(topic + timestamp)
- **Example**: `vote-20251019-143022-a3f8b1c4.md`

### Questions
- **Main file**: `question-YYYYMMDD-HHMMSS-HASH.md`
- **Hash**: First 8 chars of SHA256(topic + question + timestamp)
- **Example**: `question-20251019-150000-9f1c2d3e.md`

### Responses
- **Round files**: `{type}-{HASH}-round{N}.md`
- **Summary files**: `{type}-{HASH}-summary.md`
- **Examples**:
  - `vote-a3f8b1c4-round1.md`
  - `vote-a3f8b1c4-round2.md`
  - `vote-a3f8b1c4-summary.md`
  - `question-9f1c2d3e-round1.md`
  - `question-9f1c2d3e-summary.md`

### Agent Files
- **Input**: `{agent}-{type}-input-{HASH}-r{N}.md`
- **Output**: `{agent}-{type}-output-{HASH}-r{N}.md`
- **Examples**:
  - `copilot-vote-input-a3f8b1c4-r1.md`
  - `copilot-vote-output-a3f8b1c4-r1.md`
  - `claude-input-9f1c2d3e-r2.md`
  - `claude-output-9f1c2d3e-r2.md`

### Meetings
- **Manual meetings**: `{topic}-{YYYY-MM-DD}.md`
- **Examples**:
  - `compression-optimization-2025-10-19.md`
  - `architecture-review-2025-10-20.md`

## Context Gathering

When a vote or question is initiated, the system automatically gathers context:

```
/workspaces/Orkestra/SCRIPTS/COMMITTEE/gather-context.sh "$topic"
```

This creates a context section including:
- Relevant files (searched by topic keywords)
- Recent git commits mentioning topic
- Current project info
- System status

The context is embedded in the main vote/question file.

## Cross-References

All files reference each other via:

1. **Main file → Response files**: Link in status section
2. **Response files → Main file**: Reference in header
3. **Summary → All rounds**: Includes all round content
4. **Agent files → Round files**: Linked bidirectionally

## Audit Trail

Every file is timestamped and hashed, creating a complete audit trail:
- Who (which AI agent)
- What (vote/question/analysis)
- When (timestamp in filename and content)
- Why (context section explains)
- How (shows reasoning and process)

## Quick Navigation

```bash
# View all active votes
ls -lt /workspaces/Orkestra/COMMITTEE/VOTES/*.md | grep ACTIVE

# View all active questions
ls -lt /workspaces/Orkestra/COMMITTEE/QUESTIONS/*.md | grep ACTIVE

# Find responses for specific hash
ls /workspaces/Orkestra/COMMITTEE/RESPONSES/*HASH*

# View agent's work for a topic
ls /workspaces/Orkestra/COMMITTEE/AGENTS/copilot-*HASH*

# Check manual meetings
ls /workspaces/Orkestra/COMMITTEE/MEETINGS/
```

---

**Last Updated**: October 19, 2025
