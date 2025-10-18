const vscode = require('vscode');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// Base path to The Quantum Self workspace
const WORKSPACE_ROOT = '/workspaces/The-Quantum-Self-';

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
    console.log('Quantum AI Automation extension is now active!');

    // Status bar item
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.text = '$(robot) AI Automation';
    statusBarItem.command = 'quantum.aiCoordinator';
    statusBarItem.tooltip = 'Click to see which AI to ping next';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);

    // Register commands
    
    // 0. Check CURRENT_TASK.md and Execute (NEW!)
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.checkAndExecute', async () => {
            try {
                const taskFile = path.join(WORKSPACE_ROOT, 'CURRENT_TASK.md');
                const content = fs.readFileSync(taskFile, 'utf8');
                
                // Parse assigned AI
                const assignedMatch = content.match(/\*\*Assigned To:\*\* (.+)/);
                const statusMatch = content.match(/\*\*Status:\*\* (.+)/);
                const titleMatch = content.match(/## Task Description\s+\*\*(.+?)\*\*/);
                
                if (!assignedMatch || !statusMatch) {
                    vscode.window.showErrorMessage('Could not parse CURRENT_TASK.md');
                    return;
                }
                
                const assignedTo = assignedMatch[1].trim();
                const status = statusMatch[1].trim();
                const title = titleMatch ? titleMatch[1] : 'Current Task';
                
                // Show task info
                const panel = vscode.window.createWebviewPanel(
                    'quantumTask',
                    '✨ Execute Task',
                    vscode.ViewColumn.One,
                    { enableScripts: true }
                );
                
                panel.webview.html = getTaskWebview(title, assignedTo, status, content);
                
                // If assigned to Copilot and status is IN PROGRESS
                if (assignedTo.toLowerCase().includes('copilot') && status.includes('IN PROGRESS')) {
                    const action = await vscode.window.showInformationMessage(
                        `Task: ${title} is assigned to Copilot (you!)`,
                        'Execute Now', 'View Details', 'Cancel'
                    );
                    
                    if (action === 'Execute Now') {
                        vscode.window.showInformationMessage('🚀 Copilot is executing the task...');
                        // Copilot (you) will see this and can start working
                    } else if (action === 'View Details') {
                        const doc = await vscode.workspace.openTextDocument(taskFile);
                        await vscode.window.showTextDocument(doc);
                    }
                } else if (status.includes('COMPLETED')) {
                    vscode.window.showInformationMessage(
                        '✅ Task already completed! Run AI Coordinator to see what\'s next.',
                        'Run Coordinator'
                    ).then(selection => {
                        if (selection === 'Run Coordinator') {
                            vscode.commands.executeCommand('quantum.aiCoordinator');
                        }
                    });
                } else {
                    vscode.window.showInformationMessage(
                        `Task is assigned to ${assignedTo}. Tell them: "Check CURRENT_TASK.md and execute"`,
                        'Copy Command', 'View Task'
                    ).then(selection => {
                        if (selection === 'Copy Command') {
                            vscode.env.clipboard.writeText('Check CURRENT_TASK.md and execute');
                            vscode.window.showInformationMessage('✅ Copied to clipboard!');
                        } else if (selection === 'View Task') {
                            vscode.workspace.openTextDocument(taskFile)
                                .then(doc => vscode.window.showTextDocument(doc));
                        }
                    });
                }
                
            } catch (err) {
                vscode.window.showErrorMessage('Error reading CURRENT_TASK.md: ' + err.message);
            }
        })
    );
    
    // 1. AI Coordinator - Who's Next?
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.aiCoordinator', async () => {
            const terminal = vscode.window.createTerminal('AI Coordinator');
            terminal.show();
            terminal.sendText(`${WORKSPACE_ROOT}/ai_coordinator.sh`);
        })
    );

    // 2. Status Dashboard
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.statusDashboard', async () => {
            const terminal = vscode.window.createTerminal('AI Status Dashboard');
            terminal.show();
            terminal.sendText(`${WORKSPACE_ROOT}/ai_status_check.sh`);
        })
    );

    // 3. View Current Task
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.viewCurrentTask', async () => {
            const taskFile = path.join(WORKSPACE_ROOT, 'CURRENT_TASK.md');
            const doc = await vscode.workspace.openTextDocument(taskFile);
            await vscode.window.showTextDocument(doc, { preview: false });
        })
    );

    // 4. View Task Queue
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.viewTaskQueue', async () => {
            const queueFile = path.join(WORKSPACE_ROOT, 'TASK_QUEUE.json');
            const doc = await vscode.workspace.openTextDocument(queueFile);
            await vscode.window.showTextDocument(doc, { preview: false });
        })
    );

    // 5. Mark Task Complete
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.markComplete', async () => {
            const result = await vscode.window.showInformationMessage(
                'Mark current task as complete?',
                'Yes', 'No'
            );
            
            if (result === 'Yes') {
                // Open CURRENT_TASK.md and let user edit
                const taskFile = path.join(WORKSPACE_ROOT, 'CURRENT_TASK.md');
                const doc = await vscode.workspace.openTextDocument(taskFile);
                await vscode.window.showTextDocument(doc);
                
                vscode.window.showInformationMessage(
                    'Update Status to COMPLETED and assign Next AI. Then save the file.',
                    'Run Coordinator'
                ).then(selection => {
                    if (selection === 'Run Coordinator') {
                        vscode.commands.executeCommand('quantum.aiCoordinator');
                    }
                });
            }
        })
    );

    // 6. Build Website
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.buildWebsite', async () => {
            const terminal = vscode.window.createTerminal('Website Build');
            terminal.show();
            terminal.sendText(`cd ${WORKSPACE_ROOT}/2_The-Quantum-World && npm run build`);
        })
    );

    // 7. Update Logs
    context.subscriptions.push(
        vscode.commands.registerCommand('quantum.updateLogs', async () => {
            const title = await vscode.window.showInputBox({
                prompt: 'Task Title',
                placeHolder: 'e.g., Email Verification'
            });
            
            if (title) {
                const details = await vscode.window.showInputBox({
                    prompt: 'Brief details',
                    placeHolder: 'e.g., Implemented SendGrid integration'
                });
                
                if (details) {
                    const terminal = vscode.window.createTerminal('Update Logs');
                    terminal.show();
                    terminal.sendText(`${WORKSPACE_ROOT}/auto_update_logs.sh "${title}" "${details}"`);
                }
            }
        })
    );

    // Tree data providers for sidebar views
    const taskProvider = new TaskTreeDataProvider();
    const queueProvider = new QueueTreeDataProvider();
    const statusProvider = new StatusTreeDataProvider();

    vscode.window.registerTreeDataProvider('quantumTaskView', taskProvider);
    vscode.window.registerTreeDataProvider('quantumQueueView', queueProvider);
    vscode.window.registerTreeDataProvider('quantumStatusView', statusProvider);

    // Refresh views every 10 seconds
    setInterval(() => {
        taskProvider.refresh();
        queueProvider.refresh();
        statusProvider.refresh();
    }, 10000);
}

// Tree data provider for Current Task
class TaskTreeDataProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element) {
        return element;
    }

    getChildren() {
        try {
            const taskFile = path.join(WORKSPACE_ROOT, 'CURRENT_TASK.md');
            const content = fs.readFileSync(taskFile, 'utf8');
            
            // Parse status, assigned to, priority
            const statusMatch = content.match(/\*\*Status:\*\* (.+)/);
            const assignedMatch = content.match(/\*\*Assigned To:\*\* (.+)/);
            const priorityMatch = content.match(/\*\*Priority:\*\* (.+)/);
            
            const items = [];
            
            if (statusMatch) {
                items.push(new vscode.TreeItem(`Status: ${statusMatch[1]}`));
            }
            if (assignedMatch) {
                items.push(new vscode.TreeItem(`Assigned: ${assignedMatch[1]}`));
            }
            if (priorityMatch) {
                items.push(new vscode.TreeItem(`Priority: ${priorityMatch[1]}`));
            }
            
            // Add open task button
            const openItem = new vscode.TreeItem('📝 Open Full Task');
            openItem.command = {
                command: 'quantum.viewCurrentTask',
                title: 'Open Task'
            };
            items.push(openItem);
            
            return items;
        } catch (err) {
            return [new vscode.TreeItem('Error loading task')];
        }
    }
}

// Tree data provider for Task Queue
class QueueTreeDataProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element) {
        return element;
    }

    getChildren() {
        try {
            const queueFile = path.join(WORKSPACE_ROOT, 'TASK_QUEUE.json');
            const content = fs.readFileSync(queueFile, 'utf8');
            const queue = JSON.parse(content);
            
            const items = queue.queue.slice(0, 5).map(task => {
                const icon = task.status === 'completed' ? '✅' : 
                             task.status === 'pending' ? '🔄' : '⏳';
                return new vscode.TreeItem(`${icon} #${task.id}: ${task.title}`);
            });
            
            // Add view all button
            const viewAll = new vscode.TreeItem('📋 View All Tasks');
            viewAll.command = {
                command: 'quantum.viewTaskQueue',
                title: 'View Queue'
            };
            items.push(viewAll);
            
            return items;
        } catch (err) {
            return [new vscode.TreeItem('Error loading queue')];
        }
    }
}

// Tree data provider for AI Status
class StatusTreeDataProvider {
    constructor() {
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element) {
        return element;
    }

    getChildren() {
        const items = [
            new vscode.TreeItem('🟦 Copilot: Ready'),
            new vscode.TreeItem('🟧 Claude: Ready'),
            new vscode.TreeItem('🟩 ChatGPT: Ready')
        ];
        
        // Add coordinator button
        const coordinator = new vscode.TreeItem('🎯 Who\'s Next?');
        coordinator.command = {
            command: 'quantum.aiCoordinator',
            title: 'Run Coordinator'
        };
        items.push(coordinator);
        
        return items;
    }
}

function deactivate() {}

// Webview HTML for task display
function getTaskWebview(title, assignedTo, status, content) {
    return `<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Current Task</title>
        <style>
            body {
                padding: 20px;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 20px;
                border-radius: 8px;
                margin-bottom: 20px;
            }
            .status {
                display: inline-block;
                padding: 5px 12px;
                border-radius: 20px;
                background: rgba(255,255,255,0.2);
                margin-top: 10px;
            }
            .assigned {
                margin-top: 10px;
                font-size: 14px;
                opacity: 0.9;
            }
            .content {
                background: var(--vscode-editor-background);
                border: 1px solid var(--vscode-panel-border);
                border-radius: 8px;
                padding: 20px;
                max-height: 500px;
                overflow-y: auto;
            }
            pre {
                background: var(--vscode-textCodeBlock-background);
                padding: 10px;
                border-radius: 4px;
                overflow-x: auto;
            }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>✨ ${title}</h1>
            <div class="status">Status: ${status}</div>
            <div class="assigned">📍 Assigned to: ${assignedTo}</div>
        </div>
        <div class="content">
            <pre>${content.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</pre>
        </div>
    </body>
    </html>`;
}

module.exports = {
    activate,
    deactivate
};
