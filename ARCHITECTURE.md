# 🎼 Orkestra Architecture - Project Separation

## 📁 Core Concept: Separation of Concerns

**Orkestra is a FRAMEWORK, not a workspace.**

- ✅ **Orkestra Directory** = Framework + Orchestration + Logs
- ✅ **Project Directories** = Actual work/code the AIs are building

---

## 🏗️ Directory Structure Explained

### Orkestra Installation (Framework - Never Modified)

```
/path/to/Orkestra/                    ← FRAMEWORK (Clean, Git-tracked)
│
├── src/orkestra/                     ← Python package (Framework code)
│   ├── cli.py                        ← CLI commands
│   ├── core.py                       ← Project management
│   └── templates/                    ← Project templates
│
├── CONFIG/                           ← Framework configuration
│   ├── api-keys.env                  ← Your API keys (gitignored)
│   ├── current-project.json          ← Pointer to active project
│   └── RUNTIME/                      ← Orchestrator runtime data
│
├── LOGS/                             ← Framework logs only
│   ├── orchestrator.log              ← System orchestration logs
│   └── monitor.log                   ← Health monitoring logs
│
├── SCRIPTS/                          ← Orchestration scripts
│   ├── CORE/                         ← orchestrator.sh, etc.
│   ├── AGENTS/                       ← AI agent executors
│   ├── COMMITTEE/                    ← Voting system
│   └── SAFETY/                       ← Validation scripts
│
└── PROJECTS/                         ← Container for ALL user projects
    ├── my-website/                   ← Actual project #1
    ├── mobile-app/                   ← Actual project #2
    └── data-analysis/                ← Actual project #3
```

---

## 🎯 When You Run: `orkestra new my-website`

### What Gets Created (SEPARATE from Orkestra):

```
PROJECTS/my-website/                  ← NEW PROJECT (Actual work happens here)
│
├── src/                              ← Your actual source code
│   ├── index.html                    ← The website you're building
│   ├── styles.css
│   └── app.js
│
├── config/                           ← Project-specific config
│   ├── project.json                  ← Project metadata
│   └── task-queue.json               ← Tasks for THIS project
│
├── logs/                             ← Project-specific logs
│   ├── voting/                       ← Democracy voting records (THIS project)
│   │   ├── vote-001.json             ← Individual votes
│   │   └── vote-002.json
│   ├── outcomes/                     ← Decision outcomes (THIS project)
│   │   ├── outcome-001.json          ← What was decided
│   │   └── outcome-002.json
│   └── execution/                    ← Task execution logs (THIS project)
│       └── task-execution.log        ← What AIs did on THIS project
│
├── .git/                             ← Separate Git repo for THIS project
│
└── README.md                         ← Project documentation
```

### What DOESN'T Change:

```
Orkestra/                             ← UNTOUCHED!
├── src/orkestra/                     ← Framework code (unchanged)
├── SCRIPTS/                          ← Orchestration scripts (unchanged)
└── ...                               ← Everything else (unchanged)
```

---

## 📊 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    ORKESTRA FRAMEWORK                            │
│                  (Clean, Git-tracked, Stable)                    │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │ Orchestrator   │  │ Voting System  │  │ Agent Scripts  │   │
│  │ (coordinates)  │  │ (democracy)    │  │ (executors)    │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
│           │                   │                    │            │
│           └───────────────────┴────────────────────┘            │
│                           │                                      │
└───────────────────────────┼──────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   current-project.json   │  ← Points to active project
              └─────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Project #1     │ │  Project #2     │ │  Project #3     │
│  "my-website"   │ │  "mobile-app"   │ │  "data-tool"    │
├─────────────────┤ ├─────────────────┤ ├─────────────────┤
│ • Source code   │ │ • Source code   │ │ • Source code   │
│ • Task queue    │ │ • Task queue    │ │ • Task queue    │
│ • Logs          │ │ • Logs          │ │ • Logs          │
│ • Git repo      │ │ • Git repo      │ │ • Git repo      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
  (Actual work)      (Actual work)      (Actual work)
```

---

## 🔄 How It Works

### 1. **Create Project**
```bash
orkestra new my-website
```
- Creates: `PROJECTS/my-website/` with empty structure
- Updates: `CONFIG/current-project.json` to point to it
- Orkestra framework: **UNCHANGED**

### 2. **AIs Work on Project**
```bash
orkestra start
```
- Orchestrator reads: `CONFIG/current-project.json`
- AIs modify files in: `PROJECTS/my-website/src/`
- Logs go to: `PROJECTS/my-website/logs/`
- Votes stored in: `PROJECTS/my-website/logs/voting/` (project-specific voting)
- Outcomes stored in: `PROJECTS/my-website/logs/outcomes/` (project-specific decisions)
- Orkestra framework: **UNCHANGED**

### 3. **Switch Projects**
```bash
orkestra load mobile-app
```
- Updates: `CONFIG/current-project.json` → points to `mobile-app`
- AIs now work on: `PROJECTS/mobile-app/`
- Previous project: `my-website` untouched
- Orkestra framework: **UNCHANGED**

---

## 📝 What Goes Where

### Framework Directory (Orkestra/):

| Directory | Contents | Changes? |
|-----------|----------|----------|
| `src/orkestra/` | Framework Python code | Never (unless upgrading) |
| `SCRIPTS/` | Orchestration scripts | Never (unless upgrading) |
| `CONFIG/` | Framework configuration | Once (API keys, settings) |
| `CONFIG/RUNTIME/` | Orchestrator state | Yes (temporary runtime) |
| `LOGS/` | System logs only | Yes (orchestration logs) |

### Project Directory (PROJECTS/my-website/):

| Directory | Contents | Changes? |
|-----------|----------|----------|
| `src/` | **YOUR ACTUAL CODE** | Yes (constantly!) |
| `config/task-queue.json` | Project tasks | Yes (task updates) |
| `logs/voting/` | **Democracy voting records** | Yes (every vote) |
| `logs/outcomes/` | **Decision outcomes** | Yes (every decision) |
| `logs/execution/` | **Task execution logs** | Yes (what AIs did) |
| `.git/` | Project version control | Yes (Git commits) |
| `README.md` | Project documentation | Yes (project docs) |

---

## 🎯 Key Benefits

### ✅ **Clean Separation**
- Framework stays clean and updateable
- Projects are isolated and portable
- Can Git version each project independently

### ✅ **Multiple Projects**
- Work on multiple projects simultaneously
- Easy project switching
- No conflicts between projects

### ✅ **Easy Updates**
- Update Orkestra framework without touching projects
- `pip install --upgrade orkestra-ai`
- Projects continue working unchanged

### ✅ **Portable**
- Move project folder anywhere
- Share project folder with others
- Backup projects independently

---

## 💡 Example Workflow

### Day 1: Build a Website
```bash
orkestra new company-website
cd PROJECTS/company-website
orkestra start
# AIs build: src/index.html, src/app.js, etc.
```

### Day 2: Build a Mobile App
```bash
orkestra new mobile-app
cd PROJECTS/mobile-app
orkestra start
# AIs build: src/MainActivity.java, etc.
```

### Day 3: Continue Website
```bash
orkestra load company-website
orkestra start
# AIs continue working on website
```

---

## 📂 Real-World Example

### After a Month of Work:

```
~/Development/
│
├── Orkestra/                         ← FRAMEWORK (15 MB, stable)
│   ├── src/orkestra/                 ← Clean framework code
│   ├── SCRIPTS/                      ← Orchestration scripts
│   ├── CONFIG/
│   │   ├── api-keys.env              ← Your keys
│   │   ├── current-project.json      ← Points to "ecommerce"
│   │   └── RUNTIME/                  ← 10 KB runtime state
│   └── LOGS/
│       └── orchestrator.log          ← 2 MB of system logs (framework only)
│
└── PROJECTS/                         ← All your actual work
    │
    ├── company-website/              ← Project #1 (500 MB)
    │   ├── src/                      ← 100+ HTML/CSS/JS files
    │   ├── logs/
    │   │   ├── voting/               ← 25 voting records (THIS project)
    │   │   ├── outcomes/             ← 25 decision outcomes
    │   │   └── execution/            ← Execution logs
    │   ├── .git/                     ← Git history
    │   └── README.md
    │
    ├── mobile-app/                   ← Project #2 (2 GB)
    │   ├── android/                  ← Android source
    │   ├── ios/                      ← iOS source
    │   ├── logs/
    │   │   ├── voting/               ← 50 voting records (THIS project)
    │   │   ├── outcomes/             ← 50 decision outcomes
    │   │   └── execution/            ← Execution logs
    │   ├── .git/                     ← Git history
    │   └── README.md
    │
    └── data-analysis/                ← Project #3 (10 GB)
        ├── notebooks/                ← Jupyter notebooks
        ├── data/                     ← Dataset files
        ├── models/                   ← ML models
        ├── logs/
        │   ├── voting/               ← 100 voting records (THIS project)
        │   ├── outcomes/             ← 100 decision outcomes
        │   └── execution/            ← Execution logs
        ├── .git/                     ← Git history
        └── README.md
```

---

## 🔒 What's in Version Control

### Orkestra Repository (Main Repo):
```bash
git status
# Tracked:
#   - src/orkestra/ (framework)
#   - SCRIPTS/ (orchestration)
#   - README.md, setup.py, etc.
#
# Ignored (.gitignore):
#   - CONFIG/api-keys.env (your secrets)
#   - CONFIG/RUNTIME/ (temporary runtime state)
#   - LOGS/ (framework logs only)
#   - PROJECTS/ (user projects - separate repos!)
#   - venv/ (virtual environment)
```

### Each Project (Separate Repo):
```bash
cd PROJECTS/company-website
git status
# This is a SEPARATE Git repository
# Tracks only THIS project's files
```

---

## 🎓 Summary

**Think of it like this:**

- **Orkestra** = Your IDE (VS Code, IntelliJ) → Doesn't change
- **Projects** = Your actual code repositories → Changes constantly

OR

- **Orkestra** = Your operating system → Stable
- **Projects** = Your applications → Active development

The framework orchestrates, the projects contain the actual work!

---

## 🚀 Updated Project Creation

When users run `orkestra new`, they get a clean workspace for THEIR project, completely separate from the Orkestra framework. The framework just coordinates the AIs to work in that space.

This is the **correct architecture** for a framework! ✨
