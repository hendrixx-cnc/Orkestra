# Old VS Code Extensions - ARCHIVED

**Date Archived**: October 19, 2025

## Contents

This directory contains old VS Code extensions from "The Quantum Self" project that are no longer needed in Orkestra.

### Extensions Archived

1. **AI-AUTOMATION** (`quantum-ai-automation`)
   - Original purpose: AI task coordination for The Quantum Self project
   - Hardcoded workspace: `/workspaces/The-Quantum-Self-`
   - Size: ~406 lines + node_modules
   - Replaced by: Orkestra Committee System

2. **WORKFLOW-FRAMEWORK** (`workflow-framework`)
   - Original purpose: Config-driven coordination panels
   - Size: ~595 lines + node_modules
   - Replaced by: Orkestra Menu System + Committee System

## Why Archived?

- ❌ Hardcoded to old project paths
- ❌ Referenced "The Quantum Self" instead of "Orkestra"
- ❌ Large node_modules directories (thousands of files)
- ❌ Functionality superseded by new committee system
- ❌ Not integrated with Orkestra architecture

## Replacement Systems

The functionality of these extensions has been replaced with better, integrated systems:

### Committee System
- **Location**: `/workspaces/Orkestra/SCRIPTS/COMMITTEE/`
- **Features**:
  - Interactive voting system
  - Question/answer workflows
  - Multi-round AI collaboration
  - Timestamped and hashed tracking
  - Automatic context gathering
  - Response consolidation

### Orkestra Menu
- **Location**: `/workspaces/Orkestra/orkestra-menu.sh`
- **Features**:
  - Central navigation hub
  - Committee access
  - Task management
  - Project browser
  - System status

### Democracy Engine
- **Location**: `/workspaces/Orkestra/SCRIPTS/DEMOCRACY/`
- **Features**:
  - Democratic decision-making
  - Agent voting
  - Question routing
  - Response aggregation

## If You Need to Reference

These files are kept for historical reference only. Do not attempt to use them as they:
- Will not work with current Orkestra structure
- Reference non-existent paths
- Are incompatible with new architecture
- Contain outdated assumptions

## Restoration (Not Recommended)

If you absolutely need to restore these:
```bash
# Don't do this unless you have a very good reason
mv /workspaces/Orkestra/ARCHIVE/old-extensions/* /workspaces/Orkestra/EXTENSIONS/
```

But seriously, use the new committee system instead. It's better.

---

**Migration Complete**: October 19, 2025
**Status**: Archived and replaced with superior systems
