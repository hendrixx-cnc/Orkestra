# 🎼 Orkestra: Complete Self-Contained Project Architecture

## ✨ Core Principle: Project Isolation

**Every project is 100% self-contained with its own decision history.**

```
Orkestra Framework (Clean)     vs.     User Projects (Active)
     ↓                                        ↓
  Orchestrates                           Actual Work
  (Unchanged)                       (Voting, Outcomes, Code)
```

---

## 📊 What's Where

### Orkestra Framework Directory
```
/path/to/Orkestra/
├── src/orkestra/           # Framework code (never changes)
├── SCRIPTS/                # Orchestration scripts (never changes)
├── CONFIG/
│   ├── api-keys.env        # Your API keys (once)
│   ├── current-project.json # Points to active project
│   └── RUNTIME/            # Temporary orchestrator state
└── LOGS/
    └── orchestrator.log    # Framework logs ONLY
```

**Orkestra contains ZERO project work, ZERO votes, ZERO outcomes.**

### Each User Project Directory
```
PROJECTS/my-website/
├── src/                    # YOUR CODE (changes constantly)
│   ├── index.html
│   ├── app.js
│   └── styles.css
│
├── config/                 # Project config
│   ├── project.json        # Project metadata
│   └── task-queue.json     # Task queue
│
├── logs/                   # 📍 ALL PROJECT HISTORY
│   ├── voting/             # 🗳️  Every vote for THIS project
│   │   ├── vote-001.json
│   │   ├── vote-002.json
│   │   └── vote-003.json
│   │
│   ├── outcomes/           # ✅ Every decision for THIS project
│   │   ├── outcome-001.json
│   │   ├── outcome-002.json
│   │   └── outcome-003.json
│   │
│   └── execution/          # 📝 Every action for THIS project
│       ├── 2025-11-01.log
│       └── 2025-11-02.log
│
├── scripts/                # Project-specific scripts
├── docs/                   # Project documentation
├── projects/               # Sub-projects
├── backups/                # Project backups
└── .git/                   # Project's own Git repo
```

**Each project is a complete, portable, self-documenting unit.**

---

## 🔄 Complete Workflow Example

### Step 1: Create Project
```bash
cd /path/to/Orkestra
orkestra new my-website
```

**Result:**
- Creates `PROJECTS/my-website/` with structure above
- Updates `CONFIG/current-project.json` → points to `my-website`
- Orkestra framework: **UNCHANGED**

### Step 2: AI Committee Votes on Task
```bash
orkestra start
# Task: "Add contact form to website"
```

**What Happens:**

1. **Proposal Created**
   - Task enters committee voting process

2. **Voting Records** → Saved in `PROJECTS/my-website/logs/voting/vote-001.json`
   ```json
   {
     "id": "vote-001",
     "proposal": "Add contact form with email validation",
     "voters": {
       "claude": {"vote": "approve", "reasoning": "..."},
       "chatgpt": {"vote": "approve", "reasoning": "..."},
       "gemini": {"vote": "approve_with_modifications", "reasoning": "..."}
     },
     "result": "approved_with_modifications"
   }
   ```

3. **Decision Outcome** → Saved in `PROJECTS/my-website/logs/outcomes/outcome-001.json`
   ```json
   {
     "id": "outcome-001",
     "vote_id": "vote-001",
     "decision": "Implement contact form with HTML5 validation + server-side checks",
     "implementation_plan": {
       "tasks": [
         {"id": "task-001", "assigned_to": "claude", "title": "Create form HTML"},
         {"id": "task-002", "assigned_to": "gemini", "title": "Add validation"}
       ]
     }
   }
   ```

4. **Execution Logs** → Saved in `PROJECTS/my-website/logs/execution/2025-11-02.log`
   ```log
   [10:30:00] CLAUDE: Starting task-001 - Create form HTML
   [10:30:15] CLAUDE: Created src/contact.html with form structure
   [10:30:20] CLAUDE: Task completed ✓
   
   [10:31:00] GEMINI: Starting task-002 - Add validation
   [10:31:15] GEMINI: Added HTML5 validation attributes
   [10:31:25] GEMINI: Added server-side validation script
   [10:31:30] GEMINI: Task completed ✓
   ```

5. **Code Created** → Saved in `PROJECTS/my-website/src/`
   - `src/contact.html` (the actual form)
   - `src/validate.js` (validation logic)

**Where Everything Goes:**
- Voting records: `my-website/logs/voting/` ✓
- Outcomes: `my-website/logs/outcomes/` ✓
- Execution logs: `my-website/logs/execution/` ✓
- Actual code: `my-website/src/` ✓
- Orkestra framework: **UNTOUCHED** ✓

### Step 3: Switch to Different Project
```bash
orkestra new mobile-app
orkestra load mobile-app
orkestra start
```

**Result:**
- Creates `PROJECTS/mobile-app/` (new project)
- Updates `CONFIG/current-project.json` → points to `mobile-app`
- Now voting/outcomes go to `mobile-app/logs/`
- Previous project `my-website/` is **untouched**
- Orkestra framework: **UNCHANGED**

---

## 🎯 Key Benefits

### ✅ Complete Transparency
Every project has its own complete history:
- Every vote ever cast
- Every decision ever made
- Every action ever taken
- All stored WITH the project

### ✅ Full Portability
```bash
# Share entire project with someone
tar -czf my-website.tar.gz PROJECTS/my-website/
# They get: code + voting history + decisions + logs
```

### ✅ Independent Version Control
```bash
cd PROJECTS/my-website
git init
git add .
git commit -m "Initial commit with full history"
# Entire project + decision history is versioned
```

### ✅ Clean Framework
```bash
cd /path/to/Orkestra
git status
# Only framework files tracked
# No project data, no votes, no outcomes
```

### ✅ Easy Auditing
```bash
# See all decisions made on this project
ls PROJECTS/my-website/logs/outcomes/

# See all votes for this project
ls PROJECTS/my-website/logs/voting/

# See what AIs did
cat PROJECTS/my-website/logs/execution/*.log
```

---

## 📂 Real-World Example: 3 Projects

```
~/Development/
│
├── Orkestra/                      # Framework (15 MB, stable)
│   ├── src/orkestra/              # Framework code
│   ├── CONFIG/
│   │   ├── api-keys.env
│   │   └── current-project.json   # Points to "mobile-app"
│   └── LOGS/
│       └── orchestrator.log       # Framework logs only
│
└── PROJECTS/
    │
    ├── company-website/           # Project 1 (500 MB)
    │   ├── src/ (120 files)
    │   ├── logs/
    │   │   ├── voting/            # 25 votes
    │   │   ├── outcomes/          # 25 decisions
    │   │   └── execution/         # 3 days of logs
    │   └── .git/                  # Own Git repo
    │
    ├── mobile-app/                # Project 2 (2 GB) ← ACTIVE
    │   ├── android/ (500 files)
    │   ├── ios/ (400 files)
    │   ├── logs/
    │   │   ├── voting/            # 50 votes
    │   │   ├── outcomes/          # 50 decisions
    │   │   └── execution/         # 1 week of logs
    │   └── .git/                  # Own Git repo
    │
    └── data-analysis/             # Project 3 (10 GB)
        ├── notebooks/ (50 files)
        ├── data/ (large datasets)
        ├── logs/
        │   ├── voting/            # 100 votes
        │   ├── outcomes/          # 100 decisions
        │   └── execution/         # 2 weeks of logs
        └── .git/                  # Own Git repo
```

**Key Points:**
- Orkestra: 15 MB, unchanged for months
- Each project: Complete, isolated, self-contained
- Each project: Own voting history, decisions, logs
- Each project: Own Git repository
- Total transparency: Every decision documented

---

## 🔍 Log File Formats

### Voting Record Format
`logs/voting/vote-{timestamp}.json`
```json
{
  "id": "vote-001",
  "timestamp": "2025-11-02T10:30:00Z",
  "proposal": {
    "title": "Implement feature X",
    "description": "..."
  },
  "voters": {
    "claude": {"vote": "approve", "reasoning": "..."},
    "chatgpt": {"vote": "approve", "reasoning": "..."},
    "gemini": {"vote": "approve_with_modifications", "reasoning": "..."}
  },
  "result": "approved_with_modifications"
}
```

### Outcome Record Format
`logs/outcomes/outcome-{timestamp}.json`
```json
{
  "id": "outcome-001",
  "vote_id": "vote-001",
  "decision": "Implement feature X with modifications",
  "implementation_plan": {
    "tasks": [
      {"id": "task-001", "assigned_to": "claude"},
      {"id": "task-002", "assigned_to": "gemini"}
    ]
  },
  "reasoning": "..."
}
```

### Execution Log Format
`logs/execution/{date}.log`
```log
[10:30:00] CLAUDE: Starting task-001
[10:30:15] CLAUDE: Created file src/feature.py
[10:30:30] CLAUDE: Task completed ✓
```

---

## 🚀 Usage Commands

```bash
# Create new project (creates logs/ structure)
orkestra new my-project

# Start working (votes → my-project/logs/voting/)
orkestra start

# Check status
orkestra status

# View voting history
ls PROJECTS/my-project/logs/voting/
cat PROJECTS/my-project/logs/voting/vote-001.json

# View decisions
ls PROJECTS/my-project/logs/outcomes/
cat PROJECTS/my-project/logs/outcomes/outcome-001.json

# View execution logs
cat PROJECTS/my-project/logs/execution/*.log

# Switch projects
orkestra load other-project
# Now votes go to other-project/logs/
```

---

## 📋 Summary

### Orkestra Framework
- **Purpose**: Orchestration engine
- **Contents**: Framework code, scripts, API keys
- **Logs**: System/orchestrator logs ONLY
- **Changes**: Never (except framework updates)

### User Projects
- **Purpose**: Actual work
- **Contents**: Source code, config, logs
- **Logs**: Voting, outcomes, execution (THIS project)
- **Changes**: Constantly (active development)

### Architecture Benefit
- **Clean separation**: Framework vs. projects
- **Complete history**: Every decision documented
- **Full portability**: Share entire project
- **Easy auditing**: All logs in one place
- **Version control**: Each project independent

**Result: Every project is a complete, self-documenting, portable unit with full decision history! 🎯**
