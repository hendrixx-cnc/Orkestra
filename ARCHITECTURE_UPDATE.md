# 🎯 Orkestra Architecture Update - Project Isolation

## What Changed

### ❌ Before (Mixed Architecture)
```
Orkestra/
├── CONFIG/
│   └── VOTES/              ← Votes stored in framework (BAD)
└── LOGS/                   ← All logs mixed together (BAD)

PROJECTS/my-website/
├── src/                    ← Only code here
└── logs/                   ← Generic logs
```

**Problem:** Framework gets polluted with project data. Can't share projects independently.

---

### ✅ After (Clean Separation)
```
Orkestra/                   ← FRAMEWORK ONLY (Clean!)
├── CONFIG/
│   ├── api-keys.env
│   └── current-project.json
└── LOGS/
    └── orchestrator.log    ← Framework logs ONLY

PROJECTS/my-website/        ← COMPLETE PROJECT (Portable!)
├── src/
├── logs/
│   ├── voting/             ← THIS project's votes
│   ├── outcomes/           ← THIS project's decisions
│   └── execution/          ← THIS project's actions
└── .git/
```

**Benefit:** Each project is self-contained with full history. Framework stays clean.

---

## Key Changes

### 1. Voting Records → Projects
- **Before:** `Orkestra/CONFIG/VOTES/`
- **After:** `PROJECTS/project-name/logs/voting/`
- **Why:** Each project owns its voting history

### 2. Outcome Records → Projects
- **Before:** Not clearly separated
- **After:** `PROJECTS/project-name/logs/outcomes/`
- **Why:** Full audit trail stays with project

### 3. Execution Logs → Projects
- **Before:** Mixed in `Orkestra/LOGS/`
- **After:** `PROJECTS/project-name/logs/execution/`
- **Why:** Complete project history

---

## Benefits

### ✅ Portability
```bash
# Share entire project with colleague
tar -czf my-website.tar.gz PROJECTS/my-website/
# They get: code + votes + decisions + logs
```

### ✅ Version Control
```bash
cd PROJECTS/my-website
git init
# Track code + voting history + decisions together
```

### ✅ Clean Framework
```bash
cd Orkestra
git status
# Only framework code, no project data
```

### ✅ Transparency
```bash
# See all decisions made on this project
ls PROJECTS/my-website/logs/outcomes/

# See all votes
ls PROJECTS/my-website/logs/voting/
```

---

## Migration

### Existing Projects
If you have old projects without the new structure:

```bash
cd PROJECTS/old-project
mkdir -p logs/voting logs/outcomes logs/execution
mv logs/*.log logs/execution/
```

### New Projects
All new projects created with `orkestra new` automatically get the correct structure.

---

## Example: Complete Project

```
PROJECTS/my-website/
├── src/                           # Your code
│   ├── index.html
│   ├── app.js
│   └── styles.css
│
├── logs/                          # Complete history
│   ├── voting/                    # Every vote
│   │   ├── vote-001.json          # "Should we add contact form?"
│   │   ├── vote-002.json          # "Should we use React?"
│   │   └── vote-003.json          # "Should we add analytics?"
│   │
│   ├── outcomes/                  # Every decision
│   │   ├── outcome-001.json       # "Yes, add contact form"
│   │   ├── outcome-002.json       # "No, keep vanilla JS"
│   │   └── outcome-003.json       # "Yes, add Google Analytics"
│   │
│   └── execution/                 # Every action
│       ├── 2025-11-01.log         # Claude created contact.html
│       └── 2025-11-02.log         # Gemini added analytics script
│
├── config/
│   ├── project.json
│   └── task-queue.json
│
├── .git/                          # Own Git repo
└── README.md                      # Project documentation
```

**This is a complete, portable, self-documenting unit!**

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| Voting records | Framework directory | Project directory |
| Outcome records | Mixed/unclear | Project directory |
| Execution logs | Framework directory | Project directory |
| Portability | Difficult | Easy |
| Version control | Complex | Simple |
| Framework cleanliness | Polluted | Clean |
| Project independence | Low | High |
| Audit trail | Scattered | Complete |

**Result: Orkestra stays clean. Projects are self-contained. Everyone wins! 🎉**
