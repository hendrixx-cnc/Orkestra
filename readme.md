# Orkestra

> AI orchestration system for managing multi-agent workflows

use with AURA Adaptive Response Universal Audit protocol 

cut bandwith of human to ai conversations by 30% subms latency 

](https://github.com/hendrixx-cnc/AURA)


Repository Structure

This repository follows a strict naming convention:
- **Folders**: UPPERCASE (e.g., `DOCS/`, `SCRIPTS/`)
- **Files**: lowercase-kebab-case (e.g., `readme.md`, `task-queue.json`)

```

Quick Start

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

Direct Script Access

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

Safety System

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

Task Management

**View task queue:**
```bash
cat CONFIG/TASK-QUEUES/task-queue.json
```

**Start task automation:**
```bash
./SCRIPTS/AUTOMATION/start-autonomy-system.sh
```
Key Documentation

- **Quick Start Guide**: `DOCS/GUIDES/quick-start-autopilot.md`
- **Launch Guide**: `DOCS/GUIDES/orkestra-launch-guide.md`
- **Task Management**: `DOCS/GUIDES/task-management-guide.md`
- **System Rules**: `DOCS/TECHNICAL/system-rules.md`
- **Naming Conventions**: `DOCS/TECHNICAL/naming-convention.md`


This system is designed to work with:
- GitHub Copilot (primary)
- Claude (Anthropic)
- ChatGPT (OpenAI)
- Gemini (Google)
- Grok (xAI)


Recent Changes

See `reorganization-plan.md` for details on the recent repository reorganization that created this clean structure.

Status

Current system status can be found in `orkestra-status.md`

Contributing

This is a personal project by Todd (hendrixx-cnc), but the AI collaboration system is designed to be extensible and could be adapted for other use cases.

License

© 2025 Todd Todd Hendricks - All Rights Reserved

---

**Last Updated**: October 18, 2025
**Repository**: github.com/hendrixx-cnc/Orkestra
