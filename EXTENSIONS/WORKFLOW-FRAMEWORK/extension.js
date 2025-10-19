const vscode = require('vscode');
const fs = require('fs');
const fsp = fs.promises;
const path = require('path');

const CONFIG_SECTION = 'workflowFramework';
const DEFAULT_CONFIG_PATH = 'workflow.config.json';

/**
 * @typedef {import('vscode').ExtensionContext} ExtensionContext
 */

/**
 * Global state for the extension runtime.
 */
const state = {
    config: null,
    workspaceRoot: null,
    watchers: [],
    interval: null,
    providers: {
        task: null,
        queue: null,
        status: null
    }
};

/**
 * @param {ExtensionContext} context
 */
async function activate(context) {
    state.workspaceRoot = resolveWorkspaceRoot();

    if (!state.workspaceRoot) {
        vscode.window.showErrorMessage('Workflow Framework: No workspace folder detected. Open a folder before using this extension.');
        return;
    }

    await reloadConfig(context, { showErrors: true });

    // Status bar item for quick refresh
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.text = '$(organization) Workflow';
    statusBarItem.command = 'workflowFramework.refresh';
    statusBarItem.tooltip = 'Refresh workflow panels';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);

    // Tree data providers
    state.providers.task = new CurrentTaskProvider(() => state.config, state.workspaceRoot);
    state.providers.queue = new QueueProvider(() => state.config, state.workspaceRoot);
    state.providers.status = new StatusProvider(() => state.config, state.workspaceRoot);

    vscode.window.registerTreeDataProvider('workflowCurrentTaskView', state.providers.task);
    vscode.window.registerTreeDataProvider('workflowQueueView', state.providers.queue);
    vscode.window.registerTreeDataProvider('workflowStatusView', state.providers.status);

    // Commands
    context.subscriptions.push(
        vscode.commands.registerCommand('workflowFramework.refresh', async () => {
            await reloadConfig(context, { showErrors: false });
        }),
        vscode.commands.registerCommand('workflowFramework.openCurrentTask', async () => {
            const cfg = state.config?.currentTask;
            if (!cfg?.path) {
                vscode.window.showWarningMessage('Workflow Framework: currentTask.path is not configured.');
                return;
            }
            await openDoc(resolvePath(cfg.path));
        }),
        vscode.commands.registerCommand('workflowFramework.openTaskQueue', async () => {
            const cfg = state.config?.taskQueue;
            if (!cfg?.path) {
                vscode.window.showWarningMessage('Workflow Framework: taskQueue.path is not configured.');
                return;
            }
            await openDoc(resolvePath(cfg.path));
        }),
        vscode.commands.registerCommand('workflowFramework.runCommand', async () => {
            const commands = state.config?.commands || [];
            if (commands.length === 0) {
                vscode.window.showInformationMessage('Workflow Framework: No commands configured.');
                return;
            }

            const picked = await vscode.window.showQuickPick(
                commands.map((cmd, idx) => ({
                    label: cmd.label || `Command ${idx + 1}`,
                    description: cmd.command,
                    detail: cmd.cwd ? `cwd: ${cmd.cwd}` : '',
                    cmd
                })),
                { placeHolder: 'Select a workflow command to execute' }
            );

            if (picked?.cmd) {
                runTerminalCommand(picked.cmd);
            }
        })
    );

    // Auto-refresh interval
    scheduleRefresh(context);
}

/**
 * @param {ExtensionContext} context
 * @param {{showErrors: boolean}} options
 */
async function reloadConfig(context, { showErrors }) {
    const config = await loadConfig({ showErrors });
    if (!config) {
        return;
    }

    state.config = config;

    refreshProviders();
    resetWatchers(context);
}

/**
 * Reads configuration from disk based on user settings.
 * @param {{showErrors: boolean}} options
 * @returns {Promise<Object|null>}
 */
async function loadConfig({ showErrors }) {
    const settings = vscode.workspace.getConfiguration(CONFIG_SECTION);
    const configPathSetting = settings.get('configPath') || DEFAULT_CONFIG_PATH;
    const absPath = resolvePath(configPathSetting);

    try {
        const raw = await fsp.readFile(absPath, 'utf8');
        const parsed = JSON.parse(raw);
        return parsed;
    } catch (err) {
        if (showErrors) {
            vscode.window.showErrorMessage(`Workflow Framework: Unable to load config from ${absPath}: ${err.message}`);
        }
        return null;
    }
}

/**
 * Ensures tree providers refresh after config changes.
 */
function refreshProviders() {
    state.providers.task?.refresh();
    state.providers.queue?.refresh();
    state.providers.status?.refresh();
}

/**
 * Clears any file watchers/intervals and registers new ones.
 * @param {ExtensionContext} context
 */
function resetWatchers(context) {
    // Dispose old watchers
    state.watchers.forEach(w => w.dispose());
    state.watchers = [];

    // Clear interval
    if (state.interval) {
        clearInterval(state.interval);
        state.interval = null;
    }

    const filesToWatch = new Set();
    const configSetting = vscode.workspace.getConfiguration(CONFIG_SECTION).get('configPath') || DEFAULT_CONFIG_PATH;
    filesToWatch.add(resolvePath(configSetting));

    if (state.config?.currentTask?.path) {
        filesToWatch.add(resolvePath(state.config.currentTask.path));
    }

    if (state.config?.taskQueue?.path) {
        filesToWatch.add(resolvePath(state.config.taskQueue.path));
    }

    (state.config?.statuses || []).forEach(status => {
        if (status.path) {
            filesToWatch.add(resolvePath(status.path));
        }
    });

    filesToWatch.forEach(filePath => {
        const watcher = createWatcher(filePath, async () => {
            await reloadConfig(context, { showErrors: false });
        });
        if (watcher) {
            state.watchers.push(watcher);
        }
    });

    scheduleRefresh(context);
}

/**
 * Schedules periodic refreshes based on configuration.
 * @param {ExtensionContext} context
 */
function scheduleRefresh(context) {
    const seconds = vscode.workspace.getConfiguration(CONFIG_SECTION).get('autoRefreshInterval') || 15;
    if (state.interval) {
        clearInterval(state.interval);
        state.interval = null;
    }

    if (seconds <= 0) {
        return;
    }

    state.interval = setInterval(async () => {
        await reloadConfig(context, { showErrors: false });
    }, seconds * 1000);
}

/**
 * Creates a file watcher for the given path if it is inside the workspace.
 * @param {string} filePath
 * @param {() => void} onChange
 * @returns {vscode.FileSystemWatcher | null}
 */
function createWatcher(filePath, onChange) {
    if (!filePath || !state.workspaceRoot) {
        return null;
    }

    if (!filePath.startsWith(state.workspaceRoot)) {
        // Outside of workspace; skip watching
        return null;
    }

    const relative = path.relative(state.workspaceRoot, filePath);
    const pattern = new vscode.RelativePattern(state.workspaceRoot, relative);
    const watcher = vscode.workspace.createFileSystemWatcher(pattern);

    watcher.onDidChange(onChange);
    watcher.onDidCreate(onChange);
    watcher.onDidDelete(onChange);

    return watcher;
}

/**
 * Open a document in VS Code.
 * @param {string} absolutePath
 */
async function openDoc(absolutePath) {
    try {
        const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(absolutePath));
        await vscode.window.showTextDocument(doc, { preview: false });
    } catch (err) {
        vscode.window.showErrorMessage(`Workflow Framework: Unable to open ${absolutePath}: ${err.message}`);
    }
}

/**
 * Launches a command in an integrated terminal.
 * @param {{command: string, cwd?: string}} cmd
 */
function runTerminalCommand(cmd) {
    const terminal = vscode.window.createTerminal(cmd.label || 'Workflow Command');
    terminal.show();

    if (cmd.cwd) {
        const resolvedCwd = resolvePath(cmd.cwd);
        terminal.sendText(`cd "${resolvedCwd}"`);
    }

    terminal.sendText(cmd.command);
}

/**
 * Resolve a path relative to workspace root if necessary.
 * @param {string} inputPath
 * @returns {string}
 */
function resolvePath(inputPath) {
    if (!inputPath) {
        return '';
    }

    if (path.isAbsolute(inputPath)) {
        return inputPath;
    }

    if (!state.workspaceRoot) {
        return inputPath;
    }

    return path.join(state.workspaceRoot, inputPath);
}

/**
 * Determine the workspace root path.
 * @returns {string | null}
 */
function resolveWorkspaceRoot() {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
        return null;
    }

    return folders[0].uri.fsPath;
}

/**
 * Template helper for queue items.
 * @param {string} template
 * @param {Record<string, any>} values
 * @returns {string}
 */
function renderTemplate(template, values) {
    return template.replace(/{{\s*([^}]+)\s*}}/g, (_, key) => {
        const value = values[key.trim()];
        return value !== undefined ? String(value) : '';
    });
}

/**
 * Utility to get nested value from object using dot notation path.
 * @param {any} obj
 * @param {string} pathString
 * @returns {any}
 */
function getByPath(obj, pathString) {
    if (!pathString) return obj;
    return pathString.split('.').reduce((acc, segment) => {
        if (acc === undefined || acc === null) return undefined;
        if (Array.isArray(acc)) {
            const index = Number(segment);
            return Number.isNaN(index) ? undefined : acc[index];
        }
        return acc[segment];
    }, obj);
}

/**
 * Reads a file, returning null on error.
 * @param {string} absolutePath
 * @returns {Promise<string|null>}
 */
async function readFileSafe(absolutePath) {
    try {
        return await fsp.readFile(absolutePath, 'utf8');
    } catch (err) {
        return null;
    }
}

class CurrentTaskProvider {
    /**
     * @param {() => any} getConfig
     * @param {string} workspaceRoot
     */
    constructor(getConfig, workspaceRoot) {
        this.getConfig = getConfig;
        this.workspaceRoot = workspaceRoot;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    /**
     * @returns {Promise<vscode.TreeItem[]>}
     */
    async getChildren() {
        const config = this.getConfig();
        if (!config?.currentTask?.path) {
            return [new vscode.TreeItem('Configure currentTask.path to display details.')];
        }

        const absolutePath = resolvePath(config.currentTask.path);
        const content = await readFileSafe(absolutePath);
        if (content === null) {
            return [new vscode.TreeItem(`Unable to read ${config.currentTask.path}`)];
        }

        const items = [];

        const fields = Array.isArray(config.currentTask.fields) ? config.currentTask.fields : [];
        if (fields.length > 0) {
            fields.forEach(field => {
                const value = extractWithRegex(content, field.regex);
                const item = new vscode.TreeItem(`${field.label || 'Field'}: ${value || '—'}`);
                items.push(item);
            });
        } else {
            const preview = content.split('\n').slice(0, 5).join(' ');
            items.push(new vscode.TreeItem(preview || '(file is empty)'));
        }

        const openItem = new vscode.TreeItem('Open current task…');
        openItem.command = {
            command: 'workflowFramework.openCurrentTask',
            title: 'Open Current Task'
        };
        items.push(openItem);

        return items;
    }

    getTreeItem(element) {
        return element;
    }
}

class QueueProvider {
    /**
     * @param {() => any} getConfig
     * @param {string} workspaceRoot
     */
    constructor(getConfig, workspaceRoot) {
        this.getConfig = getConfig;
        this.workspaceRoot = workspaceRoot;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    async getChildren() {
        const config = this.getConfig();
        const queueCfg = config?.taskQueue;

        if (!queueCfg?.path) {
            return [new vscode.TreeItem('Configure taskQueue.path to display queue items.')];
        }

        const absolutePath = resolvePath(queueCfg.path);
        const content = await readFileSafe(absolutePath);
        if (content === null) {
            return [new vscode.TreeItem(`Unable to read ${queueCfg.path}`)];
        }

        const type = queueCfg.type || 'json';
        const limit = queueCfg.limit || 5;
        const items = [];

        if (type === 'json') {
            try {
                const parsed = JSON.parse(content);
                const list = Array.isArray(parsed)
                    ? parsed
                    : Array.isArray(getByPath(parsed, queueCfg.list || 'queue'))
                        ? getByPath(parsed, queueCfg.list || 'queue')
                        : [];

                const statusField = queueCfg.statusField || 'status';
                const statusIcons = queueCfg.statusIcons || {};
                const template = queueCfg.template || '{{status}}';

                list.slice(0, limit).forEach(task => {
                    const values = { ...task };
                    const status = task?.[statusField];
                    values.statusIcon = statusIcons[status] || '';
                    const label = renderTemplate(template, values);
                    const item = new vscode.TreeItem(label || JSON.stringify(task));

                    if (queueCfg.revealPath) {
                        const filePath = task?.[queueCfg.revealPath];
                        if (filePath) {
                            item.command = {
                                command: 'vscode.open',
                                title: 'Open Task File',
                                arguments: [vscode.Uri.file(resolvePath(filePath))]
                            };
                        }
                    }

                    items.push(item);
                });
            } catch (err) {
                return [new vscode.TreeItem(`Failed to parse ${queueCfg.path}: ${err.message}`)];
            }
        } else if (type === 'text') {
            const lines = content.split('\n').filter(Boolean).slice(0, limit);
            lines.forEach(line => items.push(new vscode.TreeItem(line)));
        } else {
            items.push(new vscode.TreeItem(`Unsupported queue type: ${type}`));
        }

        const viewAll = new vscode.TreeItem('Open task queue…');
        viewAll.command = {
            command: 'workflowFramework.openTaskQueue',
            title: 'Open Task Queue'
        };
        items.push(viewAll);

        return items;
    }

    getTreeItem(element) {
        return element;
    }
}

class StatusProvider {
    /**
     * @param {() => any} getConfig
     * @param {string} workspaceRoot
     */
    constructor(getConfig, workspaceRoot) {
        this.getConfig = getConfig;
        this.workspaceRoot = workspaceRoot;
        this._onDidChangeTreeData = new vscode.EventEmitter();
        this.onDidChangeTreeData = this._onDidChangeTreeData.event;
    }

    refresh() {
        this._onDidChangeTreeData.fire();
    }

    async getChildren() {
        const config = this.getConfig();
        const statuses = Array.isArray(config?.statuses) ? config.statuses : [];

        if (statuses.length === 0) {
            return [new vscode.TreeItem('Configure statuses[] to display live updates.')];
        }

        const items = [];

        for (const statusCfg of statuses) {
            if (!statusCfg.path) {
                items.push(new vscode.TreeItem(`${statusCfg.label || 'Status'}: missing path`));
                continue;
            }

            const absolutePath = resolvePath(statusCfg.path);
            const content = await readFileSafe(absolutePath);
            if (content === null) {
                items.push(new vscode.TreeItem(`${statusCfg.label || statusCfg.path}: unreadable`));
                continue;
            }

            const value = extractWithRegex(content, statusCfg.regex);
            const label = statusCfg.label || path.basename(statusCfg.path);
            const item = new vscode.TreeItem(`${label}: ${value || '—'}`);

            if (statusCfg.openOnClick !== false) {
                item.command = {
                    command: 'vscode.open',
                    title: 'Open Status File',
                    arguments: [vscode.Uri.file(absolutePath)]
                };
            }

            items.push(item);
        }

        return items;
    }

    getTreeItem(element) {
        return element;
    }
}

/**
 * Extracts information with regex, returning null when not found.
 * @param {string} content
 * @param {string} regex
 * @returns {string|null}
 */
function extractWithRegex(content, regex) {
    if (!regex) return null;
    try {
        const re = new RegExp(regex, 'i');
        const match = content.match(re);
        if (!match) return null;
        return match[1]?.trim() || null;
    } catch (err) {
        return null;
    }
}

function deactivate() {
    state.watchers.forEach(w => w.dispose());
    if (state.interval) {
        clearInterval(state.interval);
    }
}

module.exports = {
    activate,
    deactivate
};
