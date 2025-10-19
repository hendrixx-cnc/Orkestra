# Orkestra

> AI orchestration system for managing multi-agent workflows and the Quantum Self product ecosystem

## 📋 Repository Structure

This repository follows a strict naming convention:
- **Folders**: UPPERCASE (e.g., `DOCS/`, `SCRIPTS/`)
- **Files**: lowercase-kebab-case (e.g., `readme.md`, `task-queue.json`)

### Directory Organization

```
/workspaces/Orkestra/
├── readme.md                    # This file
├── orkestra-status.md          # Current system status
├── reorganization-plan.md      # Organization guidelines
│
├── DOCS/                       # All documentation
│   ├── PRODUCT/               # Product documentation & roadmaps
│   ├── TECHNICAL/             # Technical specifications & architecture
│   ├── AI-SYSTEM/             # AI collaboration documentation
│   ├── GUIDES/                # How-to guides and tutorials
│   └── ARCHIVE/               # Deprecated/historical documents
│
├── SCRIPTS/                    # All executable scripts
│   ├── CORE/                  # Core orchestration (startup, orchestrator)
│   ├── AI/                    # AI agent scripts
│   ├── AUTOMATION/            # Task automation & daemons
│   ├── UTILS/                 # Utility scripts (migration, push, reset)
│   └── MONITORING/            # System monitoring & resilience
│
├── CONFIG/                     # Configuration files
│   ├── TASK-QUEUES/           # Task queue JSON files
│   ├── LOCKS/                 # Lock files for coordination
│   └── RUNTIME/               # Runtime files (PIDs, temp files)
│
├── EXTENSIONS/                 # VS Code extensions
│   ├── AI-AUTOMATION/         # AI automation extension
│   └── WORKFLOW-FRAMEWORK/    # Workflow framework extension
│
├── BACKUPS/                    # Backup files and folders
│   ├── orkestra_backup_*/     # Timestamped backups
│   └── untitled-folder-backup/ # Previous unorganized files
│
├── LOGS/                       # System logs (orchestrator, monitor, automation)
│
└── PROJECTS/                   # Actual project workspaces
    └── workspaces/            # The Quantum Self and other projects
```

## 🚀 Quick Start

### Using the Orkestra Command

Orkestra now has a unified command-line interface:

**Create a new project:**
```bash
orkestra new
```

**Load an existing project:**
```bash
orkestra load
```

**Start Orkestra:**
```bash
orkestra start
```

**List all projects:**
```bash
orkestra list
```

**Reset system:**
```bash
orkestra reset
```

### Direct Script Access

You can also run scripts directly:

**Start the orchestration system:**
```bash
./SCRIPTS/CORE/startup.sh
```

**Run the main orchestrator:**
```bash
./SCRIPTS/CORE/orchestrator.sh
```

**Start orkestra:**
```bash
./SCRIPTS/CORE/orkestra-start.sh
```

### Safety System

**Pre-Task Validator**: Validates before task execution (10 checks)
```bash
./SCRIPTS/SAFETY/pre-task-validator.sh <task_id> <ai_name>
```

**Post-Task Validator**: Validates after task completion (8 checks)
```bash
./SCRIPTS/SAFETY/post-task-validator.sh <task_id> <ai_name>
```

**Consistency Checker**: Periodic system health monitoring (10 checks)
```bash
./SCRIPTS/SAFETY/consistency-checker.sh
```

### Monitoring

**Monitor system health:**
```bash
./SCRIPTS/MONITORING/monitor.sh
```

**Check resilience system:**
```bash
./SCRIPTS/MONITORING/orkestra-resilience.sh
```

### Task Management

**View task queue:**
```bash
cat CONFIG/TASK-QUEUES/task-queue.json
```

**Start task automation:**
```bash
./SCRIPTS/AUTOMATION/start-autonomy-system.sh
```

## 📚 Key Documentation

- **Product Overview**: `DOCS/PRODUCT/master-product-ecosystem.md`
- **Quick Start Guide**: `DOCS/GUIDES/quick-start-autopilot.md`
- **Launch Guide**: `DOCS/GUIDES/orkestra-launch-guide.md`
- **Task Management**: `DOCS/GUIDES/task-management-guide.md`
- **System Rules**: `DOCS/TECHNICAL/system-rules.md`
- **Naming Conventions**: `DOCS/TECHNICAL/naming-convention.md`

## 🎯 What is Orkestra?

Orkestra is a multi-AI orchestration system that coordinates multiple AI agents (Claude, GPT, Gemini, Grok, Copilot) to work together on complex tasks. It includes:

- **Task Queue System**: Manages and distributes tasks across AI agents
- **Lock Mechanism**: Prevents conflicts when multiple AIs work simultaneously
- **Democracy Engine**: Allows AIs to vote on decisions
- **Automation Scripts**: Runs tasks autonomously with human oversight
- **Monitoring & Resilience**: Ensures system stability and recovery

## 🛠️ Main Components

### Core Orchestration
- `orchestrator.sh` - Main orchestration logic
- `startup.sh` - System initialization
- `orkestra-start.sh` - Quick start script

### Automation
- `task-coordinator.sh` - Coordinates task distribution
- `universal-daemon.sh` - Universal background task runner
- `smart-task-selector.sh` - Intelligently assigns tasks to AIs

### Utilities
- `reset-orkestra.sh` - Reset system to clean state
- `push-orkestra-to-github.sh` - Push changes to repository
- `migrate-orkestra-with-hacs.sh` - Migration tools

## 🤖 AI Integration

This system is designed to work with:
- GitHub Copilot (primary)
- Claude (Anthropic)
- ChatGPT (OpenAI)
- Gemini (Google)
- Grok (xAI)

## 📦 The Quantum Self Project

The main product being developed is **The Quantum Self** - a journaling app based on quantum psychology principles. See `DOCS/PRODUCT/master-product-ecosystem.md` for full details.

## 🔄 Recent Changes

See `reorganization-plan.md` for details on the recent repository reorganization that created this clean structure.

## 📝 Status

Current system status can be found in `orkestra-status.md`

## 🤝 Contributing

This is a personal project by Todd (hendrixx-cnc), but the AI collaboration system is designed to be extensible and could be adapted for other use cases.

## 📄 License

© 2025 Todd / Elara Solace - All Rights Reserved

---

**Last Updated**: October 18, 2025
**Repository**: github.com/hendrixx-cnc/Orkestra
