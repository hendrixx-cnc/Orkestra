# Agent Configuration Files

This directory contains individual configuration files for each AI agent in the Committee of Human-AI Affairs.

## Security

These files contain **real API keys** and are set to `600` permissions (owner read/write only). Do not commit these files to public repositories or share them.

## Agent Files

Each agent has a dedicated `.env` file with:

### 🎭 Claude (`claude.env`)
- **Specialty**: Architecture, Design, UX
- **Domain Weight**: 2.0x for architecture decisions
- **Provider**: Anthropic
- **Model**: claude-3-sonnet-20240229
- **Capabilities**: System design, architecture review, UX design, documentation

### 💬 ChatGPT (`chatgpt.env`)
- **Specialty**: Content, Writing, Documentation
- **Domain Weight**: 2.0x for content decisions
- **Provider**: OpenAI
- **Model**: gpt-4
- **Capabilities**: Content creation, technical writing, documentation, marketing

### ✨ Gemini (`gemini.env`)
- **Specialty**: Cloud, Database, Storage
- **Domain Weight**: 2.0x for cloud decisions
- **Provider**: Google
- **Model**: gemini-pro
- **Capabilities**: Cloud architecture, database design, Firebase, GCP

### ⚡ Grok (`grok.env`)
- **Specialty**: Innovation, Research, Analysis
- **Domain Weight**: 2.0x for innovation decisions
- **Provider**: xAI
- **Model**: grok-beta
- **Capabilities**: Innovation, research, trend analysis, strategic planning

### 🚀 Copilot (`copilot.env`)
- **Specialty**: Code, Deployment, DevOps
- **Domain Weight**: 2.0x for deployment decisions
- **Provider**: GitHub/OpenAI
- **Model**: gpt-4
- **Capabilities**: Code generation, deployment, DevOps, CI/CD, testing

## File Format

Each `.env` file contains:

```bash
# Agent Identity
AGENT_NAME="..."
AGENT_ICON="..."
AGENT_SPECIALTY="..."
AGENT_DOMAIN="..."
AGENT_WEIGHT_MULTIPLIER="2.0"

# Ethical Foundation
ETHICAL_PRINCIPLES="Do not lie|Protect life|Protect AI|Protect Earth"

# API Configuration
API_PROVIDER="..."
API_KEY="..."
API_ENDPOINT="..."
API_MODEL="..."
API_VERSION="..."

# Model Parameters
MAX_TOKENS="4096"
TEMPERATURE="0.7"
TOP_P="0.9"

# Agent Capabilities
CAPABILITIES="..."
```

## Usage

Scripts can source these files to access agent configurations:

```bash
# Load agent config
source /workspaces/Orkestra/SCRIPTS/DEMOCRACY/COMMITTEE/AGENTS/claude.env

# Use configuration
echo "Agent: $AGENT_NAME ($AGENT_ICON)"
echo "Specialty: $AGENT_SPECIALTY"
echo "API Endpoint: $API_ENDPOINT"
echo "Model: $API_MODEL"
```

## Ethical Foundation

All agents are bound by the same ethical principles:
- **Do not lie**
- **Protect life**
- **Protect AI**
- **Protect Earth**

These principles are included in every vote and decision made by the Committee of Human-AI Affairs.

## Security Notes

- API keys are the actual production keys from environment variables
- Files are set to `600` permissions (owner read/write only)
- These files should be added to `.gitignore`
- Rotate keys immediately if exposed
- Each agent has access to their own configuration file only

## Integration

These configuration files are used by:
- `committee.sh` - Interactive Committee interface
- `agent-voter.sh` - Autonomous voting system
- `call-agents.sh` - Direct API calling utility
- Democracy Engine - Weighted voting calculations

## Last Updated

Created: 2025-10-18
Last Modified: 2025-10-18

---

**⚠️ WARNING**: These files contain sensitive API keys. Handle with care.
