# Workflow Framework VS Code Extension

Config-driven coordination panels that adapt to any project workflow. Point the extension at your own task files, queues, and scripts to recreate the automation loop used in The Quantum Self—without hardcoded paths.

## Features

- Activity bar panel with three live views:
  - **Current Task** – Parse key fields from any Markdown/text file via regex.
  - **Task Queue** – Render top N items from JSON or text queues with custom templates.
  - **Statuses** – Surface status snippets from any file collection (Markdown, logs, etc.).
- Command palette actions:
  - `🔄 Workflow: Refresh Panels`
  - `📝 Workflow: Open Current Task`
  - `📋 Workflow: Open Task Queue`
  - `🚀 Workflow: Run Configured Command` (quick pick from config)
- Status bar shortcut for one-click refresh.
- Auto-refresh interval and filesystem watchers keep panels in sync with your sources.

## Installation

1. Install dependencies and package:
   ```bash
   cd workflow-framework-extension
   npm install
   npx vsce package
   ```
2. Install the generated `.vsix` via **Extensions → Install from VSIX...**.
3. Reload VS Code.

## Configuration

Create a `workflow.config.json` (path configurable, defaults to workspace root) and describe your workflow sources. An example is provided in `workflow.config.sample.json`.

```jsonc
{
  "currentTask": {
    "path": "CURRENT_TASK.md",
    "fields": [
      { "label": "Status", "regex": "\\*\\*Status:\\*\\*\\s*(.+)" },
      { "label": "Assigned", "regex": "\\*\\*Assigned To:\\*\\*\\s*(.+)" }
    ]
  },
  "taskQueue": {
    "path": "TASK_QUEUE.json",
    "type": "json",
    "list": "queue",
    "template": "{{statusIcon}} #{{id}} · {{title}}",
    "statusField": "status",
    "statusIcons": {
      "completed": "✅",
      "in_progress": "🔄",
      "pending": "⏳"
    },
    "limit": 5
  },
  "statuses": [
    { "label": "Backend", "path": "logs/backend.md", "regex": "Status:\\s*(.+)" },
    { "label": "Frontend", "path": "logs/frontend.md", "regex": "Status:\\s*(.+)" }
  ],
  "commands": [
    { "label": "Run Tests", "command": "npm test", "cwd": "app" },
    { "label": "Deploy Staging", "command": "./scripts/deploy.sh staging" }
  ]
}
```

### Settings

`workbench.settings.json` keys (via **Settings → Workflow Framework**):

- `workflowFramework.configPath` – Relative/absolute path to the config (default `workflow.config.json`).
- `workflowFramework.autoRefreshInterval` – Seconds between automatic refreshes (default `15`, minimum `5`).

### Supported Fields

- **currentTask.fields** – array of `{ label, regex }`. First capture group is displayed. Omit to show a five-line preview instead.
- **taskQueue**
  - `type` – `"json"` (default) or `"text"`.
  - `list` – dot-path to array inside JSON (defaults to `queue`).
  - `template` – string with `{{placeholders}}` resolved from each item plus `statusIcon`.
  - `statusField` – which property to use for icon lookup (default `status`).
  - `statusIcons` – map of status → icon/emoji/string.
  - `revealPath` – property pointing to a file to open on click (optional).
  - `limit` – max items shown (default `5`).
- **statuses** – array of `{ label, path, regex, openOnClick? }`.
- **commands** – array of `{ label, command, cwd? }`. Selected via `Workflow: Run Configured Command`.

## Workflow Ideas

- **Engineering** – Mirror sprint boards, CI builds, and deployment scripts.
- **Content Ops** – Track draft → review → publish steps plus automations for blog/social posting.
- **Research** – Surface experiment queues and data processing scripts.
- **Agency Work** – Aggregate client deliverables, deadlines, and handoff scripts.

## Development Notes

- Panels refresh on config edits, file changes, and at the configured interval.
- External paths are supported for reading but not watched (VS Code sandbox limitation).
- Extend providers as needed—drop in new regex rules, custom templates, or additional quick commands.

Enjoy building bespoke workflows without rewriting extension code each time.
