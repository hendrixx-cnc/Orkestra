# {{ project_name }}

> An Orkestra-managed AI collaboration project

## 📁 Project Structure

```
{{ project_name }}/
├── src/                    # Your actual source code goes here
├── config/                 # Project configuration
│   ├── project.json        # Project metadata
│   └── task-queue.json     # Task queue for AI agents
├── logs/                   # All project logs (tracked in project repo)
│   ├── voting/             # Democracy voting records
│   │   └── vote-*.json     # Individual votes and ballots
│   ├── outcomes/           # Decision outcomes
│   │   └── outcome-*.json  # What was decided and why
│   └── execution/          # Execution logs
│       └── *.log           # What the AIs did
├── scripts/                # Project-specific scripts
├── docs/                   # Project documentation
├── projects/               # Sub-projects or workspaces
└── backups/                # Automatic backups
```

## 🎯 What Goes Where

### `src/` - Your Source Code
This is where your actual project code lives. The AI agents will create and modify files here based on tasks.

### `config/` - Configuration
- **project.json**: Project metadata (name, version, creation date)
- **task-queue.json**: Queue of tasks for AI agents to work on

### `logs/` - Complete Project History
All decision-making and execution history for THIS project:

#### `logs/voting/`
- Democracy voting records
- Each vote saved as `vote-{timestamp}.json`
- Includes: proposal, voter responses, timestamps
- **This stays with the project** - full transparency

#### `logs/outcomes/`
- What was decided after voting
- Saved as `outcome-{timestamp}.json`
- Includes: decision, reasoning, implementation plan
- **This stays with the project** - full audit trail

#### `logs/execution/`
- What the AI agents actually did
- Task execution logs, errors, successes
- **This stays with the project** - complete history

## 🔄 How It Works

1. **Task Added**: A task is added to `config/task-queue.json`
2. **Vote Happens**: AIs vote on approach → saved to `logs/voting/`
3. **Decision Made**: Outcome recorded → saved to `logs/outcomes/`
4. **Work Done**: AIs execute → logs to `logs/execution/`
5. **Code Created**: Results appear in `src/`

## 📊 Understanding Logs

### Voting Records (`logs/voting/vote-*.json`)
```json
{
  "id": "vote-001",
  "timestamp": "2025-11-02T10:30:00",
  "proposal": "Implement user authentication",
  "votes": {
    "claude": {"choice": "approve", "reasoning": "..."},
    "chatgpt": {"choice": "approve", "reasoning": "..."},
    "gemini": {"choice": "modify", "reasoning": "..."}
  },
  "result": "approved_with_modifications"
}
```

### Outcome Records (`logs/outcomes/outcome-*.json`)
```json
{
  "id": "outcome-001",
  "vote_id": "vote-001",
  "timestamp": "2025-11-02T10:35:00",
  "decision": "Implement JWT-based authentication",
  "reasoning": "Consensus reached with Gemini's security suggestions",
  "implementation_plan": [
    "Create auth module",
    "Add JWT library",
    "Implement login/logout endpoints"
  ],
  "assigned_to": "claude"
}
```

## 🚀 Usage

### Start working on this project:
```bash
orkestra load {{ project_name }}
orkestra start
```

### Check status:
```bash
orkestra status
```

### View voting history:
```bash
ls -la logs/voting/
cat logs/voting/vote-001.json
```

### View decisions:
```bash
ls -la logs/outcomes/
cat logs/outcomes/outcome-001.json
```

## 🔒 Version Control

This project should have its own Git repository:

```bash
git init
git add .
git commit -m "Initial commit"
```

**Everything in this directory** (including voting records and outcomes) is part of YOUR project, not the Orkestra framework.

## 📝 Notes

- The Orkestra framework stays clean and unchanged
- All project work, votes, decisions, and logs stay here
- You can share this entire directory with others
- Full transparency: every decision is recorded
- Complete audit trail: every action is logged

---

**Created by**: Orkestra AI Orchestration System  
**Template**: Standard  
**Date**: {{ creation_date }}
