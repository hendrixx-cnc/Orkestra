#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# ORKESTRA MIGRATION SCRIPT
# ═══════════════════════════════════════════════════════════════════════════════
# Purpose: Migrate all Orkestra components to dedicated repository
# Target: https://github.com/hendrixx-cnc/Orkestra
# Date: October 18, 2025
# ═══════════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_ROOT="/workspaces/The-Quantum-Self-"
NEW_REPO_URL="https://github.com/hendrixx-cnc/Orkestra.git"
MIGRATION_DIR="/tmp/orkestra_migration"
TARGET_REPO="${MIGRATION_DIR}/Orkestra"

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}   🎼 ORKESTRA MIGRATION TO NEW REPOSITORY${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1: Prepare Migration Directory
# ═══════════════════════════════════════════════════════════════════════════════

echo -e "${CYAN}[1/7] Preparing migration environment...${NC}"

# Clean up any previous migration
if [ -d "$MIGRATION_DIR" ]; then
    echo "  Cleaning up previous migration directory..."
    rm -rf "$MIGRATION_DIR"
fi

mkdir -p "$MIGRATION_DIR"
echo -e "${GREEN}  ✓ Migration directory created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2: Clone New Repository
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[2/7] Cloning new Orkestra repository...${NC}"

cd "$MIGRATION_DIR"
if git clone "$NEW_REPO_URL" 2>/dev/null; then
    echo -e "${GREEN}  ✓ Repository cloned successfully${NC}"
else
    echo -e "${YELLOW}  ⚠ Repository might be empty or you may need to authenticate${NC}"
    echo "  Creating new repository structure..."
    mkdir -p "$TARGET_REPO"
    cd "$TARGET_REPO"
    git init
    git remote add origin "$NEW_REPO_URL"
fi

cd "$TARGET_REPO"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 3: Create Directory Structure
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[3/7] Creating Orkestra directory structure...${NC}"

# Core directories
mkdir -p core/{orchestration,coordination,automation}
mkdir -p agents/{claude,chatgpt,gemini,grok,copilot}
mkdir -p tasks/{queue,management,recovery}
mkdir -p monitoring/{status,logs,dashboard}
mkdir -p utils/{locks,events,validation}
mkdir -p docs/{guides,api,examples}
mkdir -p config
mkdir -p scripts
mkdir -p .github/workflows

echo -e "${GREEN}  ✓ Directory structure created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 4: Copy Core Orkestra Files
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[4/7] Copying Orkestra core files...${NC}"

# Core orchestration scripts
if [ -f "$WORKSPACE_ROOT/AI/orchestrator.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/orchestrator.sh" core/orchestration/
    echo "  ✓ orchestrator.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/orkestra_start.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/orkestra_start.sh" core/orchestration/
    echo "  ✓ orkestra_start.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/orkestra_autopilot.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/orkestra_autopilot.sh" core/automation/
    echo "  ✓ orkestra_autopilot.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/orkestra_resilience.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/orkestra_resilience.sh" core/automation/
    echo "  ✓ orkestra_resilience.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/reset_orkestra.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/reset_orkestra.sh" scripts/
    echo "  ✓ reset_orkestra.sh"
fi

# Coordination scripts
if [ -f "$WORKSPACE_ROOT/AI/ai_coordinator.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/ai_coordinator.sh" core/coordination/
    echo "  ✓ ai_coordinator.sh"
fi

if [ -f "$WORKSPACE_ROOT/ai_coordinator.sh" ]; then
    cp "$WORKSPACE_ROOT/ai_coordinator.sh" core/coordination/ai_coordinator_root.sh
    echo "  ✓ ai_coordinator.sh (root)"
fi

if [ -f "$WORKSPACE_ROOT/AI/task_coordinator.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/task_coordinator.sh" core/coordination/
    echo "  ✓ task_coordinator.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/gemini_orchestrator.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/gemini_orchestrator.sh" core/orchestration/
    echo "  ✓ gemini_orchestrator.sh"
fi

# Task management
if [ -f "$WORKSPACE_ROOT/AI/claim_task.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/claim_task.sh" tasks/management/
    echo "  ✓ claim_task.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/claim_task_v2.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/claim_task_v2.sh" tasks/management/
    echo "  ✓ claim_task_v2.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/complete_task.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/complete_task.sh" tasks/management/
    echo "  ✓ complete_task.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/complete_task_v2.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/complete_task_v2.sh" tasks/management/
    echo "  ✓ complete_task_v2.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/task_lock.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/task_lock.sh" tasks/management/
    echo "  ✓ task_lock.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/task_recovery.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/task_recovery.sh" tasks/recovery/
    echo "  ✓ task_recovery.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/task_audit.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/task_audit.sh" tasks/management/
    echo "  ✓ task_audit.sh"
fi

# Task selectors
if [ -f "$WORKSPACE_ROOT/AI/fcfs_task_selector.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/fcfs_task_selector.sh" tasks/queue/
    echo "  ✓ fcfs_task_selector.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/smart_task_selector.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/smart_task_selector.sh" tasks/queue/
    echo "  ✓ smart_task_selector.sh"
fi

# Agent scripts
if [ -f "$WORKSPACE_ROOT/AI/claude_agent.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/claude_agent.sh" agents/claude/
    echo "  ✓ claude_agent.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/chatgpt_agent.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/chatgpt_agent.sh" agents/chatgpt/
    echo "  ✓ chatgpt_agent.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/gemini_agent.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/gemini_agent.sh" agents/gemini/
    echo "  ✓ gemini_agent.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/grok_agent.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/grok_agent.sh" agents/grok/
    echo "  ✓ grok_agent.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/copilot_tool.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/copilot_tool.sh" agents/copilot/
    echo "  ✓ copilot_tool.sh"
fi

# Auto-executors
if [ -f "$WORKSPACE_ROOT/AI/claude_auto_executor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/claude_auto_executor.sh" agents/claude/
    echo "  ✓ claude_auto_executor.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/chatgpt_auto_executor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/chatgpt_auto_executor.sh" agents/chatgpt/
    echo "  ✓ chatgpt_auto_executor.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/gemini_auto_executor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/gemini_auto_executor.sh" agents/gemini/
    echo "  ✓ gemini_auto_executor.sh"
fi

# Monitoring and status
if [ -f "$WORKSPACE_ROOT/AI/ai_status_check.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/ai_status_check.sh" monitoring/status/
    echo "  ✓ ai_status_check.sh"
fi

if [ -f "$WORKSPACE_ROOT/ai_status_check.sh" ]; then
    cp "$WORKSPACE_ROOT/ai_status_check.sh" monitoring/status/ai_status_check_root.sh
    echo "  ✓ ai_status_check.sh (root)"
fi

if [ -f "$WORKSPACE_ROOT/AI/monitor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/monitor.sh" monitoring/
    echo "  ✓ monitor.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/lock_monitor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/lock_monitor.sh" utils/locks/
    echo "  ✓ lock_monitor.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/dashboard.html" ]; then
    cp "$WORKSPACE_ROOT/AI/dashboard.html" monitoring/dashboard/
    echo "  ✓ dashboard.html"
fi

# Utilities
if [ -f "$WORKSPACE_ROOT/AI/event_bus.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/event_bus.sh" utils/events/
    echo "  ✓ event_bus.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/consistency_check.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/consistency_check.sh" utils/validation/
    echo "  ✓ consistency_check.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/error_check.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/error_check.sh" utils/validation/
    echo "  ✓ error_check.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/resilience_system.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/resilience_system.sh" core/automation/
    echo "  ✓ resilience_system.sh"
fi

# Automation
if [ -f "$WORKSPACE_ROOT/AI/autonomy_executor.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/autonomy_executor.sh" core/automation/
    echo "  ✓ autonomy_executor.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/start_autonomy_system.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/start_autonomy_system.sh" core/automation/
    echo "  ✓ start_autonomy_system.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/auto_executor_with_recovery.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/auto_executor_with_recovery.sh" core/automation/
    echo "  ✓ auto_executor_with_recovery.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/democracy_engine.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/democracy_engine.sh" core/coordination/
    echo "  ✓ democracy_engine.sh"
fi

if [ -f "$WORKSPACE_ROOT/auto_update_logs.sh" ]; then
    cp "$WORKSPACE_ROOT/auto_update_logs.sh" scripts/
    echo "  ✓ auto_update_logs.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/auto_update_logs.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/auto_update_logs.sh" scripts/auto_update_logs_ai.sh
    echo "  ✓ auto_update_logs.sh (AI)"
fi

# Daemons
if [ -f "$WORKSPACE_ROOT/AI/command_daemon.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/command_daemon.sh" core/automation/
    echo "  ✓ command_daemon.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/universal_daemon.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/universal_daemon.sh" core/automation/
    echo "  ✓ universal_daemon.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/claude_daemon.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/claude_daemon.sh" agents/claude/
    echo "  ✓ claude_daemon.sh"
fi

# AI Notes system
if [ -f "$WORKSPACE_ROOT/AI/ai_notes.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/ai_notes.sh" utils/
    echo "  ✓ ai_notes.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/ai_notes_helper.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/ai_notes_helper.sh" utils/
    echo "  ✓ ai_notes_helper.sh"
fi

if [ -f "$WORKSPACE_ROOT/AI/clear_ai_notes.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/clear_ai_notes.sh" utils/
    echo "  ✓ clear_ai_notes.sh"
fi

# Menu system
if [ -f "$WORKSPACE_ROOT/ai_menu.sh" ]; then
    cp "$WORKSPACE_ROOT/ai_menu.sh" scripts/
    echo "  ✓ ai_menu.sh"
fi

# Startup
if [ -f "$WORKSPACE_ROOT/AI/startup.sh" ]; then
    cp "$WORKSPACE_ROOT/AI/startup.sh" scripts/
    echo "  ✓ startup.sh"
fi

# Config files
if [ -f "$WORKSPACE_ROOT/AI/autonomy_config.json" ]; then
    cp "$WORKSPACE_ROOT/AI/autonomy_config.json" config/
    echo "  ✓ autonomy_config.json"
fi

echo -e "${GREEN}  ✓ Core files copied${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 5: Copy Documentation
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[5/7] Copying documentation...${NC}"

# Main documentation files
DOC_FILES=(
    "ORKESTRA_LAUNCH_GUIDE.md"
    "ORKESTRA_STATUS.md"
    "555_AI_AUTOMATION_SYSTEM.md"
    "333_AI_COLLABORATION_RULES.md"
    "TASK_MANAGEMENT_GUIDE.md"
    "AI_COORDINATION_SYSTEM_EFFECTIVENESS_REPORT.md"
    "AI_COORDINATION_BEST_CASE_SCENARIO.md"
    "AI_COORDINATION_CORRECTED_ASSESSMENT.md"
    "AI_COORDINATION_MARKET_ASSESSMENT.md"
    "AUTO_PILOT_IMPLEMENTATION_SUMMARY.md"
    "ORCHESTRATION_SESSION_REPORT.md"
    "SESSION_SUMMARY_ENHANCED_COORDINATION.md"
    "STRATEGY_SESSION_OCT_18_2025.md"
)

for file in "${DOC_FILES[@]}"; do
    if [ -f "$WORKSPACE_ROOT/$file" ]; then
        cp "$WORKSPACE_ROOT/$file" docs/
        echo "  ✓ $file"
    fi
done

# AI directory documentation
AI_DOC_FILES=(
    "README_ENHANCED_SYSTEM.md"
    "AUTO_PILOT_GUIDE.md"
    "AUTO_PILOT_VISUAL_GUIDE.md"
    "AUTONOMY_SYSTEM_GUIDE.md"
    "DEMOCRACY_ENGINE_GUIDE.md"
    "DEMOCRACY_ENGINE_SUMMARY.md"
    "EXPERT_ASSIGNMENT_GUIDE.md"
    "SMART_ASSIGNMENT_SYSTEM.md"
    "SAFETY_SYSTEM_SUMMARY.md"
    "LOCK_CLEANUP_RULES.md"
    "LOCK_CLEANUP_QUICKREF.md"
    "QUICK_START_AUTOPILOT.md"
    "COMPLETE_DOCUMENTATION.md"
    "PROJECT_STATE.md"
    "SYSTEM_STATUS.md"
    "ORCHESTRATOR_IMPROVEMENT_OPPORTUNITIES.md"
    "ADVANCED_FEATURES_DEEP_DIVE.md"
)

for file in "${AI_DOC_FILES[@]}"; do
    if [ -f "$WORKSPACE_ROOT/AI/$file" ]; then
        cp "$WORKSPACE_ROOT/AI/$file" docs/guides/
        echo "  ✓ AI/$file"
    fi
done

# Copy AI notes guide
if [ -f "$WORKSPACE_ROOT/AI/AI_NOTES_GUIDE.md" ]; then
    cp "$WORKSPACE_ROOT/AI/AI_NOTES_GUIDE.md" docs/guides/
    echo "  ✓ AI_NOTES_GUIDE.md"
fi

if [ -f "$WORKSPACE_ROOT/AI/AI_NOTES_QUICKREF.md" ]; then
    cp "$WORKSPACE_ROOT/AI/AI_NOTES_QUICKREF.md" docs/guides/
    echo "  ✓ AI_NOTES_QUICKREF.md"
fi

echo -e "${GREEN}  ✓ Documentation copied${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 6: Create Configuration Templates
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[6/7] Creating configuration templates...${NC}"

# Sample task queue
cat > config/TASK_QUEUE_TEMPLATE.json << 'EOF'
{
  "metadata": {
    "version": "2.0",
    "created": "2025-10-18",
    "last_updated": "2025-10-18"
  },
  "active_task": null,
  "queue": []
}
EOF
echo "  ✓ TASK_QUEUE_TEMPLATE.json"

# Sample AI status
cat > config/AI_STATUS_TEMPLATE.md << 'EOF'
# AI Agent Status

**Last Updated:** [AUTO-GENERATED]  
**Status:** Available  
**Current Task:** None  

## Task History
- Ready to receive tasks from OrKeStra.

## Notes
- Status is auto-updated by the system
EOF
echo "  ✓ AI_STATUS_TEMPLATE.md"

echo -e "${GREEN}  ✓ Configuration templates created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 7: Create Main README
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}[7/7] Creating comprehensive README...${NC}"

cat > README.md << 'EOFREADME'
# 🎼 OrKeStra - Multi-AI Orchestration System

**Version:** 2.0  
**Date:** October 18, 2025  
**Author:** Todd James Hendricks  
**License:** Proprietary - © 2025 OrKeStra Systems

---

## 📖 Overview

**OrKeStra** is a sophisticated multi-AI orchestration system that coordinates multiple AI agents (Claude, ChatGPT, Gemini, Grok, GitHub Copilot) to work collaboratively on complex software development tasks.

### What Makes OrKeStra Unique

- **Multi-AI Coordination**: Seamlessly orchestrates 5+ AI agents simultaneously
- **Intelligent Task Distribution**: Smart algorithms assign tasks based on AI capabilities
- **Resilience & Recovery**: Automatic error handling and task recovery
- **Lock-Based Concurrency**: Prevents race conditions in multi-agent scenarios
- **Democracy Engine**: Consensus-based decision making for critical choices
- **Autonomous Operation**: Can run in autopilot mode with minimal human intervention

---

## 🏗️ Architecture

```
OrKeStra/
├── core/                      # Core orchestration logic
│   ├── orchestration/         # Main orchestrators
│   ├── coordination/          # AI coordination
│   └── automation/            # Autopilot & resilience
├── agents/                    # AI agent interfaces
│   ├── claude/
│   ├── chatgpt/
│   ├── gemini/
│   ├── grok/
│   └── copilot/
├── tasks/                     # Task management
│   ├── queue/                 # Task queue & selectors
│   ├── management/            # Claim/complete logic
│   └── recovery/              # Error recovery
├── monitoring/                # System monitoring
│   ├── status/                # Status checks
│   ├── logs/                  # Log management
│   └── dashboard/             # Web dashboard
├── utils/                     # Utilities
│   ├── locks/                 # Lock management
│   ├── events/                # Event bus
│   └── validation/            # Validators
├── config/                    # Configuration files
├── docs/                      # Documentation
└── scripts/                   # Utility scripts
```

---

## 🚀 Quick Start

### Prerequisites

- Bash shell (Linux/macOS/WSL)
- Git
- Access to AI platforms (Claude, ChatGPT, etc.)
- jq (JSON processor)

### Installation

```bash
# Clone the repository
git clone https://github.com/hendrixx-cnc/Orkestra.git
cd Orkestra

# Make scripts executable
find . -name "*.sh" -exec chmod +x {} \;

# Initialize configuration
cp config/TASK_QUEUE_TEMPLATE.json TASK_QUEUE.json

# Create status files for each AI
for ai in CLAUDE CHATGPT GEMINI GROK COPILOT; do
    cp config/AI_STATUS_TEMPLATE.md "${ai}_STATUS.md"
done
```

### Basic Usage

**1. Start OrKeStra:**
```bash
./core/orchestration/orkestra_start.sh
```

**2. Add tasks to the queue:**
Edit `TASK_QUEUE.json` with your tasks:
```json
{
  "queue": [
    {
      "id": 1,
      "title": "Review code structure",
      "assigned_to": "claude",
      "status": "pending",
      "priority": "high",
      "description": "Review the codebase structure and suggest improvements"
    }
  ]
}
```

**3. Run in autopilot mode:**
```bash
./core/automation/orkestra_autopilot.sh
```

**4. Monitor status:**
```bash
./monitoring/status/ai_status_check.sh
```

---

## 📚 Core Components

### Orchestration

- **`orchestrator.sh`**: Main orchestration engine
- **`orkestra_start.sh`**: System startup script
- **`gemini_orchestrator.sh`**: Gemini-specific orchestrator

### Task Management

- **`claim_task.sh`**: AI agents claim tasks from the queue
- **`complete_task.sh`**: Mark tasks as complete
- **`task_recovery.sh`**: Recover failed tasks
- **`smart_task_selector.sh`**: Intelligent task assignment

### Agents

Each AI has its own agent interface:
- Claude: Advanced reasoning, code review
- ChatGPT: Content generation, documentation
- Gemini: Data analysis, research
- Grok: Creative solutions, ideation
- Copilot: Code implementation, refactoring

### Automation

- **`orkestra_autopilot.sh`**: Fully autonomous operation
- **`orkestra_resilience.sh`**: Self-healing capabilities
- **`autonomy_executor.sh`**: Execute tasks autonomously

### Monitoring

- **`ai_status_check.sh`**: Check AI agent status
- **`lock_monitor.sh`**: Monitor task locks
- **`dashboard.html`**: Web-based monitoring dashboard

---

## 🎯 Key Features

### 1. **Intelligent Task Distribution**

OrKeStra uses multiple algorithms to assign tasks:
- **FCFS (First Come First Served)**: Simple queue processing
- **Smart Selector**: Capability-based assignment
- **Democracy Engine**: Consensus-based selection

### 2. **Resilience & Recovery**

- Automatic task retry with exponential backoff
- Dead-lock detection and resolution
- Self-healing capabilities
- Comprehensive error logging

### 3. **Lock-Based Concurrency**

Prevents race conditions when multiple AIs work simultaneously:
```bash
# Automatic lock acquisition
./tasks/management/claim_task.sh <ai_name>

# Lock monitoring
./utils/locks/lock_monitor.sh
```

### 4. **Event-Driven Architecture**

Real-time event bus for system-wide notifications:
```bash
# Emit event
./utils/events/event_bus.sh emit "task.completed" '{"id": 123}'

# Listen for events
./utils/events/event_bus.sh listen "task.*"
```

### 5. **Autopilot Mode**

Fully autonomous operation:
```bash
./core/automation/orkestra_autopilot.sh

# System will:
# - Assign tasks automatically
# - Execute them with appropriate AIs
# - Handle errors and retries
# - Report completion status
```

---

## 📖 Documentation

- **[Quick Start Guide](docs/guides/QUICK_START_AUTOPILOT.md)**: Get started in 5 minutes
- **[Autopilot Guide](docs/guides/AUTO_PILOT_GUIDE.md)**: Run OrKeStra autonomously
- **[Task Management](docs/TASK_MANAGEMENT_GUIDE.md)**: Managing tasks and queues
- **[Safety Systems](docs/guides/SAFETY_SYSTEM_SUMMARY.md)**: Built-in safety measures
- **[Democracy Engine](docs/guides/DEMOCRACY_ENGINE_GUIDE.md)**: Consensus decision-making
- **[Advanced Features](docs/guides/ADVANCED_FEATURES_DEEP_DIVE.md)**: Deep dive into features
- **[API Reference](docs/guides/COMPLETE_DOCUMENTATION.md)**: Full API documentation

---

## 🔒 Security & Safety

OrKeStra includes multiple safety layers:

1. **Task Validation**: All tasks validated before execution
2. **Lock Mechanisms**: Prevent concurrent modification
3. **Approval System**: Human approval for critical operations
4. **Audit Logging**: Complete audit trail of all operations
5. **Rollback Capability**: Revert changes if needed

---

## 🛠️ Configuration

### Task Queue Format

```json
{
  "metadata": {
    "version": "2.0",
    "created": "2025-10-18",
    "last_updated": "2025-10-18"
  },
  "active_task": 1,
  "queue": [
    {
      "id": 1,
      "title": "Task title",
      "assigned_to": "claude",
      "status": "in_progress",
      "priority": "high",
      "depends_on": null,
      "description": "Detailed task description",
      "files": ["file1.js", "file2.js"],
      "created_at": "2025-10-18T10:00:00Z"
    }
  ]
}
```

### AI Status Format

```markdown
# AI Agent Status

**Last Updated:** 2025-10-18 10:30:00  
**Status:** Available | Busy | Error  
**Current Task:** Task ID or None  

## Task History
- [Timestamp] Completed task: Task title
- [Timestamp] Started task: Another task

## Notes
- Any relevant notes about the AI's state
```

---

## 📊 Use Cases

### 1. **Codebase Modernization**

Coordinate multiple AIs to refactor legacy code:
- Claude: Analyze architecture
- Copilot: Implement changes
- ChatGPT: Update documentation
- Gemini: Validate changes

### 2. **Content Creation Pipeline**

Automated content generation workflow:
- Grok: Generate creative ideas
- ChatGPT: Write first draft
- Claude: Review and edit
- Gemini: Fact-check

### 3. **Development Workflow**

Complete software development cycle:
- Requirements analysis (Claude)
- Code implementation (Copilot)
- Testing strategy (Gemini)
- Documentation (ChatGPT)
- Code review (Claude)

---

## 🔄 Workflow Example

```bash
# 1. Initialize OrKeStra
./core/orchestration/orkestra_start.sh

# 2. Add task to queue
cat >> TASK_QUEUE.json << EOF
{
  "queue": [{
    "id": 1,
    "title": "Refactor authentication module",
    "assigned_to": "auto",
    "priority": "high",
    "description": "Modernize auth system to use JWT"
  }]
}
EOF

# 3. Run autopilot
./core/automation/orkestra_autopilot.sh

# 4. Monitor progress
watch -n 5 './monitoring/status/ai_status_check.sh'

# 5. Check results
cat CLAUDE_STATUS.md COPILOT_STATUS.md
```

---

## 🐛 Troubleshooting

### Reset OrKeStra

If the system gets into a bad state:
```bash
./scripts/reset_orkestra.sh
```

This will:
- Clear all locks
- Reset AI status files
- Create backup of current state
- Initialize clean queue

### Check System Health

```bash
# Status check
./monitoring/status/ai_status_check.sh

# Lock status
./utils/locks/lock_monitor.sh

# Error logs
tail -f monitoring/logs/errors.log
```

### Common Issues

**Problem**: Tasks stuck in "in_progress"  
**Solution**: Run `./scripts/reset_orkestra.sh`

**Problem**: AI not picking up tasks  
**Solution**: Check AI status file and ensure it's set to "Available"

**Problem**: Lock conflicts  
**Solution**: Clear stale locks with `./utils/locks/lock_monitor.sh --cleanup`

---

## 🤝 Contributing

OrKeStra is proprietary software. For licensing inquiries:

**Email:** licensing@orkestra.ai  
**Website:** https://orkestra.ai (coming soon)

---

## 📜 License

**Proprietary Software**  
© 2025 OrKeStra Systems  
All Rights Reserved

Commercial use requires a license. Contact: licensing@orkestra.ai

---

## 🎯 Roadmap

- [ ] Web-based dashboard UI
- [ ] REST API for external integrations
- [ ] Docker containerization
- [ ] Kubernetes orchestration
- [ ] SaaS platform launch
- [ ] Enterprise features (teams, permissions)
- [ ] AI agent marketplace

---

## 📧 Contact

**Author:** Todd James Hendricks  
**Company:** OrKeStra Systems  
**Email:** todd@orkestra.ai  
**GitHub:** https://github.com/hendrixx-cnc/Orkestra

---

## 🙏 Acknowledgments

Built with love for the AI orchestration community.

Special thanks to all AI assistants who helped build this system:
- Claude (Anthropic)
- ChatGPT (OpenAI)
- Gemini (Google)
- Grok (xAI)
- GitHub Copilot (Microsoft/GitHub)

---

**OrKeStra** - *Where AI Agents Work in Harmony* 🎼
EOFREADME

echo -e "${GREEN}  ✓ README.md created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Create .gitignore
# ═══════════════════════════════════════════════════════════════════════════════

cat > .gitignore << 'EOFGITIGNORE'
# Logs
*.log
logs/
monitoring/logs/*.log

# Lock files
locks/
*.lock
*.pid

# Status files (may contain sensitive info)
*_STATUS.md

# Task queues (may contain proprietary tasks)
TASK_QUEUE.json

# Backups
*_backup/
*.backup

# AI Notes
AI_NOTES.json

# Temporary files
*.tmp
*.temp
/tmp/

# OS files
.DS_Store
Thumbs.db

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Environment files
.env
.env.local
*.key

# Node modules (if any)
node_modules/

# Python cache (if any)
__pycache__/
*.pyc
*.pyo
EOFGITIGNORE

echo -e "${GREEN}  ✓ .gitignore created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Create LICENSE
# ═══════════════════════════════════════════════════════════════════════════════

cat > LICENSE << 'EOFLICENSE'
PROPRIETARY LICENSE

Copyright (c) 2025 Todd James Hendricks / OrKeStra Systems
All Rights Reserved.

This software and associated documentation files (the "Software") are the
proprietary property of Todd James Hendricks and OrKeStra Systems.

RESTRICTIONS:

1. The Software may not be copied, modified, merged, published, distributed,
   sublicensed, or sold without explicit written permission from the copyright
   holder.

2. Commercial use of the Software requires a valid license agreement.

3. The Software is provided "AS IS", without warranty of any kind, express or
   implied, including but not limited to the warranties of merchantability,
   fitness for a particular purpose and noninfringement.

4. In no event shall the authors or copyright holders be liable for any claim,
   damages or other liability, whether in an action of contract, tort or
   otherwise, arising from, out of or in connection with the Software or the
   use or other dealings in the Software.

For licensing inquiries, contact:
Email: licensing@orkestra.ai
Website: https://orkestra.ai

Todd James Hendricks
OrKeStra Systems
October 18, 2025
EOFLICENSE

echo -e "${GREEN}  ✓ LICENSE created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Make all scripts executable
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}Making all scripts executable...${NC}"
find . -name "*.sh" -exec chmod +x {} \;
echo -e "${GREEN}  ✓ Scripts are now executable${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Create initial commit
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}Creating initial commit...${NC}"

git add .
git commit -m "Initial OrKeStra migration - Multi-AI orchestration system

- Core orchestration and coordination scripts
- AI agent interfaces (Claude, ChatGPT, Gemini, Grok, Copilot)
- Task management and queue system
- Monitoring and status dashboard
- Resilience and recovery systems
- Comprehensive documentation
- Configuration templates

Version: 2.0
Date: October 18, 2025
Author: Todd James Hendricks
License: Proprietary - OrKeStra Systems"

echo -e "${GREEN}  ✓ Initial commit created${NC}"

# ═══════════════════════════════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   ✅ MIGRATION COMPLETE!${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Migration Summary:${NC}"
echo -e "  Repository: ${YELLOW}$TARGET_REPO${NC}"
echo -e "  Files migrated: ${GREEN}$(find . -type f | wc -l)${NC}"
echo -e "  Scripts: ${GREEN}$(find . -name '*.sh' | wc -l)${NC}"
echo -e "  Documentation: ${GREEN}$(find docs/ -type f | wc -l)${NC}"
echo ""
echo -e "${CYAN}Next Steps:${NC}"
echo ""
echo -e "  ${YELLOW}1.${NC} Review the migrated files:"
echo -e "     ${BLUE}cd $TARGET_REPO${NC}"
echo -e "     ${BLUE}tree -L 2${NC}"
echo ""
echo -e "  ${YELLOW}2.${NC} Test the system:"
echo -e "     ${BLUE}./scripts/reset_orkestra.sh${NC}"
echo -e "     ${BLUE}./core/orchestration/orkestra_start.sh${NC}"
echo ""
echo -e "  ${YELLOW}3.${NC} Push to GitHub:"
echo -e "     ${BLUE}git push -u origin main${NC}"
echo ""
echo -e "  ${YELLOW}4.${NC} Set up repository:"
echo -e "     - Add description: 'Multi-AI orchestration system'"
echo -e "     - Add topics: ai, orchestration, automation, devops"
echo -e "     - Enable Issues and Wiki"
echo ""
echo -e "${GREEN}🎼 OrKeStra is ready to harmonize your AI agents!${NC}"
echo ""
