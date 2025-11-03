# 🎼 Orkestra - Multi-AI Task Coordination Platform

[![PyPI version](https://badge.fury.io/py/orkestra-ai.svg)](https://badge.fury.io/py/orkestra-ai)
[![Python](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

Orchestrate multiple AI agents (Claude, ChatGPT, Gemini, Copilot, and Grok) to work together on complex tasks with democratic decision-making, safety validation, and self-healing capabilities.

## ✨ Features

- 🤖 **Multi-AI Coordination** - Orchestrate 5+ AI agents simultaneously
- 🗳️ **Democratic Decision Making** - Weighted voting by agent specialty
- 🛡️ **Safety System** - Pre/post task validation with consistency checking
- 🔄 **Self-Healing** - Automatic recovery from failures
- 📊 **Real-time Monitoring** - Dashboard and health checks
- 🔒 **Lock-based Coordination** - Atomic task claiming and execution
- 📝 **Comprehensive Audit Trail** - Full event logging
- 🎯 **Project Templates** - Quick start with predefined structures

## 🚀 Quick Start

### Installation

```bash
pip install orkestra-ai
```

### Create Your First Project

```bash
# Create a new project
orkestra new my-ai-project

# Navigate to project
cd my-ai-project

# Configure API keys
cp config/api-keys.env.example config/api-keys.env
# Edit config/api-keys.env with your actual API keys

# Start Orkestra
orkestra start
```

### Check Status

```bash
orkestra status
```

## 📚 Commands

| Command | Description |
|---------|-------------|
| `orkestra new <name>` | Create a new project |
| `orkestra start` | Start the orchestration system |
| `orkestra stop` | Stop the system |
| `orkestra status` | Check system status |
| `orkestra list` | List all projects |
| `orkestra load <name>` | Load an existing project |
| `orkestra reset` | Reset to clean state |
| `orkestra config` | Open configuration |

## 🏗️ Project Structure

When you create a new project, Orkestra generates this structure:

```
my-ai-project/
├── config/
│   ├── api-keys.env          # API keys (gitignored)
│   ├── api-keys.env.example  # Template for API keys
│   ├── project.json          # Project configuration
│   ├── task-queues/          # Task queue storage
│   ├── runtime/              # Runtime data
│   ├── templates/            # Task templates
│   └── votes/                # Voting records
├── scripts/
│   ├── core/                 # Core orchestration
│   ├── agents/               # AI agent executors
│   ├── automation/           # Task automation
│   ├── safety/               # Validation scripts
│   ├── monitoring/           # Health checks
│   ├── committee/            # Voting system
│   └── utils/                # Utilities
├── docs/                     # Documentation
├── logs/                     # System logs
├── projects/                 # Project workspaces
├── backups/                  # Automated backups
└── README.md
```

## 🔑 API Keys Configuration

Orkestra supports these AI services:

- **Claude** (Anthropic)
- **ChatGPT** (OpenAI)
- **Gemini** (Google)
- **Copilot** (GitHub)
- **Grok** (xAI)

Configure your API keys in `config/api-keys.env`:

```bash
export ANTHROPIC_API_KEY="your-key-here"
export OPENAI_API_KEY="your-key-here"
export GOOGLE_API_KEY="your-key-here"
export GITHUB_TOKEN="your-token-here"
export XAI_API_KEY="your-key-here"
```

## 🎯 Usage Examples

### Create a New Project with Custom Path

```bash
orkestra new my-project --path /custom/path
```

### Start with Monitoring

```bash
orkestra start --monitor
```

### Clean Start (Reset Locks)

```bash
orkestra start --clean
```

### List All Projects

```bash
orkestra list
```

### Stop the System

```bash
orkestra stop
```

## 🏛️ Democratic Decision Making

Orkestra includes a sophisticated voting system where AI agents can vote on decisions:

- **Multiple Voting Types**: Simple majority, supermajority, unanimous, weighted
- **Specialty-based Weights**: Agents have different voting weights based on their expertise
- **Vote History**: Complete audit trail of all decisions

Example agent weights by domain:
- **Architecture**: Claude (2.0), Copilot (1.5), Gemini (1.5)
- **Content**: ChatGPT (2.0), Claude (1.5)
- **Cloud**: Gemini (2.0), Claude (1.5)
- **Innovation**: Grok (2.0), Claude (1.5)

## 🛡️ Safety System

Three-layer safety validation:

1. **Pre-Task Validator** - 10 checks before execution
2. **Post-Task Validator** - 8 checks after completion
3. **Consistency Checker** - Periodic health monitoring

Features:
- Automatic backup system
- Stale lock detection (configurable timeout)
- Corrupted file repair
- Task retry with exponential backoff

## 📊 Performance

- **Dashboard Render**: <1 second
- **Health Checks**: <1 second
- **Lock Acquisition**: Atomic (instant)
- **Max Concurrent Agents**: 50+
- **Lock Timeout**: 1 hour (configurable)

## 🔧 Advanced Configuration

### Custom Templates

Create custom project templates by adding them to `src/orkestra/templates/`:

```
templates/
├── standard/      # Full-featured template
├── minimal/       # Lightweight template
└── custom/        # Your custom template
```

### Environment Variables

Control behavior with environment variables:

```bash
export ORKESTRA_LOG_LEVEL=DEBUG
export ORKESTRA_LOCK_TIMEOUT=3600
export ORKESTRA_MAX_RETRIES=3
```

## 🐛 Troubleshooting

### Project Not Found

```bash
# Make sure you're in a project directory or specify the project name
cd my-ai-project
orkestra start
```

### API Keys Not Working

```bash
# Check your configuration
orkestra config

# Verify keys are loaded
grep -v "^#" config/api-keys.env
```

### Orchestrator Won't Start

```bash
# Reset the system
orkestra reset --force

# Check for running processes
ps aux | grep orchestrator
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with shell scripting for maximum portability
- Inspired by orchestration and multi-agent systems
- Designed for real-world AI coordination challenges

## 📮 Support

- **Issues**: [GitHub Issues](https://github.com/hendrixx-cnc/Orkestra/issues)
- **Discussions**: [GitHub Discussions](https://github.com/hendrixx-cnc/Orkestra/discussions)
- **Documentation**: [Full Docs](https://github.com/hendrixx-cnc/Orkestra/tree/main/DOCS)

## 🚀 What's Next?

- [ ] Web-based dashboard
- [ ] REST API for external integrations
- [ ] Plugin system for custom agents
- [ ] Cloud deployment templates
- [ ] Real-time collaboration features

---

**Made with ❤️ by hendrixx-cnc**

**Star ⭐ this repo if you find it useful!**
