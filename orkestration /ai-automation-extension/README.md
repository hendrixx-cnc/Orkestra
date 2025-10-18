# Quantum AI Automation - VS Code Extension

## Features

This extension provides a sidebar panel and commands for managing AI task coordination in The Quantum Self project.

### Sidebar Panel (🤖 AI Automation)

Click the robot icon in the Activity Bar to see:
- **Current Task** - Status, assigned AI, priority
- **Task Queue** - Next 5 tasks
- **AI Status** - Copilot, Claude, ChatGPT status

### Commands

Access via Command Palette (Cmd/Ctrl+Shift+P):

- `🎯 AI Coordinator - Who's Next?` - See which AI to ping
- `📊 AI Status Dashboard` - Full progress view
- `📝 View Current Task` - Open CURRENT_TASK.md
- `📋 View Task Queue` - Open TASK_QUEUE.json
- `✅ Mark Task Complete` - Update task status
- `🚀 Build Website` - Test production build
- `💾 Update Status Logs` - Add entry to 444

### Keyboard Shortcut

- **Cmd/Ctrl+Shift+A** - AI Coordinator (Who's Next?)

### Status Bar

Click the `$(robot) AI Automation` button in the status bar to run the coordinator.

## Installation

### From VSIX (Recommended):

1. Package the extension:
   ```bash
   cd ai-automation-extension
   npm install
   npx vsce package
   ```

2. Install in VS Code:
   - Open VS Code
   - Press Cmd/Ctrl+Shift+P
   - Type "Extensions: Install from VSIX"
   - Select `quantum-ai-automation-1.0.0.vsix`

### From Source:

1. Copy the `ai-automation-extension` folder to:
   - **Mac/Linux:** `~/.vscode/extensions/`
   - **Windows:** `%USERPROFILE%\.vscode\extensions\`

2. Reload VS Code

## Requirements

- The Quantum Self workspace at `/workspaces/The-Quantum-Self-/`
- Bash scripts (`ai_coordinator.sh`, etc.) must be executable

## Usage

1. Open The Quantum Self workspace
2. Click the robot icon (🤖) in the Activity Bar
3. See current task, queue, and AI status
4. Click "🎯 Who's Next?" to run coordinator
5. Or use Cmd/Ctrl+Shift+P and search "Quantum AI"

## Release Notes

### 1.0.0

Initial release:
- Sidebar panel with task/queue/status views
- 7 commands for AI coordination
- Status bar integration
- Keyboard shortcut (Cmd/Ctrl+Shift+A)
