# Orkestra Quick Reference

## 🎯 Main Command: `orkestra`

The `orkestra` command is your main interface to the Orkestra system.

### Commands Overview

| Command | Description | Example |
|---------|-------------|---------|
| `orkestra new` | Create new project (resets system) | `orkestra new` |
| `orkestra load` | Load existing project from list | `orkestra load` |
| `orkestra start` | Start Orkestra with current project | `orkestra start` |
| `orkestra list` | Show all saved projects | `orkestra list` |
| `orkestra save` | Save current project state | `orkestra save` |
| `orkestra reset` | Reset system to clean state | `orkestra reset` |
| `orkestra current` | Show current project info | `orkestra current` |
| `orkestra health` | Monitor AI agent health status | `orkestra health` |
| `orkestra help` | Show help message | `orkestra help` |

---

## 🏥 Agent Health Monitoring

### Interactive Health Menu
```bash
orkestra health
```

This opens an interactive menu with options:
1. **Quick Status Overview** - See all agents at a glance
2. **Detailed Health Check** - Test API connections
3. **Test Specific Agent** - Deep dive into one agent
4. **Configure API Keys** - Quick access to setup
5. **View Workload Distribution** - See task assignments
6. **Auto-refresh Monitor** - Real-time monitoring

### Command-Line Options
```bash
# Quick summary
orkestra health --summary

# Detailed check with API tests
orkestra health --detailed

# Test specific agent
orkestra health --test claude
orkestra health --test chatgpt
orkestra health --test gemini
orkestra health --test grok
orkestra health --test copilot

# Show workload distribution
orkestra health --workload

# Auto-refresh monitor (updates every 5s)
orkestra health --monitor
```

### What It Shows
- **API Status**: Whether each agent is configured and accessible
- **Workload**: How many tasks each agent is currently handling
- **Completed Tasks**: Total tasks completed by each agent
- **Connection Status**: Real-time API connectivity tests
- **Authentication**: GitHub Copilot auth status

### Example Output
```
Agent Status Overview

  Agent                Status               Workload        Completed 
  ────────────────────────────────────────────────────────────
  🤖 Claude          ✓ Configured     2 active   15
  💬 ChatGPT         ✓ Configured     3 active   22
  ✨ Gemini           ✓ Configured     1 active   8
  🚀 Grok            ✓ Configured     0 active   5
  🐙 GitHub Copilot  ✓ Authenticated  1 active   12
```

---

## 📋 Typical Workflow

### 1. Create a New Project
```bash
orkestra new
```
This will:
- Ask for project name and description
- Reset the Orkestra system
- Create a new project directory
- Start Orkestra with the new project

### 2. Work on Your Project
Use Orkestra normally:
- Add tasks to the queue
- Run automation
- Monitor progress

### 3. Save Your Progress
```bash
orkestra save
```
Creates a snapshot of:
- Task queue state
- System logs
- Project configuration

### 4. Switch Projects
```bash
orkestra load
```
Shows a numbered list of all projects:
```
Available Projects:

  #  Name                      Created              Last Accessed
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1   Quantum Self App          2025-10-18 10:30     2025-10-18 15:45
  2   Marketing Campaign        2025-10-15 09:15     2025-10-17 14:20
  3   Documentation Update      2025-10-10 16:00     2025-10-12 11:30

Select project number (or 'q' to quit): 
```

### 5. Resume Work
```bash
orkestra start
```
Starts Orkestra with your current project.

---

## 🔄 System Management

### Reset Everything
```bash
orkestra reset
```
This will:
- Stop all running services
- Clear all locks
- Clear runtime files
- Reset task queue
- Clear current project (but keep saved projects)

### Start Options
```bash
# Normal start
orkestra start

# Clean start (clear locks)
orkestra start --clean

# Health check only
orkestra start --check

# With monitoring
orkestra start --monitor
```

---

## 📁 Project Structure

Each project is stored in `PROJECTS/` with this structure:

```
PROJECTS/
└── your-project-id/
    ├── project.json          # Project metadata
    ├── docs/                 # Project documentation
    ├── data/                 # Project data
    ├── config/               # Project-specific config
    ├── notes/                # Project notes
    └── snapshots/            # Saved states
        └── 20251018-153045/  # Timestamp
            ├── task-queue.json
            └── *.log
```

---

## 🎨 Project Examples

### Example 1: Web App Development
```bash
$ orkestra new
Project name: Quantum Self Web App
Description (optional): Main journaling application

✓ Project created: Quantum Self Web App
ℹ  Starting Orkestra with new project...
```

### Example 2: Loading Existing Project
```bash
$ orkestra load

Available Projects:

  #  Name                      Created              Last Accessed
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1   Quantum Self Web App      2025-10-18 10:30     2025-10-18 15:45
  2   API Documentation         2025-10-15 09:15     2025-10-17 14:20

Select project number (or 'q' to quit): 1

ℹ  Loading project: Quantum Self Web App
✓ Project loaded: Quantum Self Web App
ℹ  Starting Orkestra with loaded project...
```

### Example 3: Project Info
```bash
$ orkestra current

Current Project:

  Name:        Quantum Self Web App
  ID:          quantum-self-web-app
  Description: Main journaling application
  Created:     2025-10-18T10:30:00-07:00
```

---

## 🛠️ Advanced Usage

### CLI Installation
Install AI agent CLIs:
```bash
./SCRIPTS/UTILS/install-clis.sh
```

### Manual Script Access
```bash
# Start orchestrator directly
./SCRIPTS/CORE/orchestrator.sh

# Run automation manually
./SCRIPTS/AUTOMATION/orkestra-automation.sh --once

# Monitor system
./SCRIPTS/MONITORING/monitor.sh
```

### View Logs
```bash
# Orchestrator logs
tail -f LOGS/orchestrator.log

# Automation logs
tail -f LOGS/automation-*.log

# All logs
ls -lh LOGS/
```

### Check Status
```bash
# System status
cat orkestra-status.md

# Running processes
ps aux | grep -E "orchestrator|monitor|automation"

# PID files
ls -lh CONFIG/RUNTIME/*.pid
```

---

## 📊 Status & Monitoring

### Check Current State
```bash
# Current project
orkestra current

# All projects
orkestra list

# System status
cat orkestra-status.md
```

### Monitor Active Services
```bash
# Check if running
pgrep -f orchestrator.sh
pgrep -f monitor.sh
pgrep -f orkestra-automation.sh

# View PIDs
cat CONFIG/RUNTIME/orchestrator.pid
cat CONFIG/RUNTIME/monitor.pid
cat CONFIG/RUNTIME/automation.pid
```

### Stop Services
```bash
# Stop all
pkill -f "orchestrator.sh|monitor.sh|orkestra-automation.sh"

# Stop individually
kill $(cat CONFIG/RUNTIME/orchestrator.pid)
kill $(cat CONFIG/RUNTIME/monitor.pid)
kill $(cat CONFIG/RUNTIME/automation.pid)
```

---

## 🔑 API Keys Setup

Edit your API keys:
```bash
# Edit the template
nano ~/.config/orkestra/api-keys.env

# Add your keys:
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GEMINI_API_KEY="AI..."

# Load them
source ~/.config/orkestra/api-keys.env

# Auto-load on shell start
echo "source ~/.config/orkestra/api-keys.env" >> ~/.bashrc
```

---

## 🎯 Tips & Best Practices

1. **Always save before switching projects**
   ```bash
   orkestra save
   orkestra load
   ```

2. **Use descriptive project names**
   - Good: "Quantum Self MVP"
   - Bad: "test" or "project1"

3. **Reset when things get messy**
   ```bash
   orkestra reset
   orkestra start --clean
   ```

4. **Check current project before starting**
   ```bash
   orkestra current
   orkestra start
   ```

5. **List projects frequently**
   ```bash
   orkestra list
   ```

---

## 🆘 Troubleshooting

### "No active project" error
```bash
# Create a new project
orkestra new

# Or load existing one
orkestra load
```

### Services won't start
```bash
# Reset and try again
orkestra reset
orkestra start --clean
```

### Can't find orkestra command
```bash
# Recreate symlink
ln -sf /workspaces/Orkestra/orkestra ~/.local/bin/orkestra

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### Project not in list
```bash
# Check projects directory
ls -la PROJECTS/

# Check index file
cat PROJECTS/projects-index.json
```

---

**Quick Help**: `orkestra help`  
**Documentation**: `DOCS/`  
**Support**: Create an issue on GitHub
