# Project Planning Guide

## Overview

The **Project Planning Wizard** is an interactive tool that helps you define and structure your project at the very beginning. It guides you through a comprehensive planning process and generates documentation, tasks, and optional AI committee review.

## When to Use

The planning wizard is automatically launched when you create a new Orkestra project:

```bash
orkestra new my-awesome-project
```

Skip it with the `--skip-planning` flag:

```bash
orkestra new my-project --skip-planning
```

You can also access it anytime from the main menu:

```
orkestra → Main Menu → Option 1: Project Planning
```

## Planning Process

### Step 1: Project Overview
- **Project Name**: Automatically detected from directory
- **Description**: Brief explanation of project goals
- **Type**: Select from:
  - Web Application
  - API/Backend Service
  - Mobile App
  - Desktop Application
  - Library/Package
  - Data Science/ML Project
  - DevOps/Infrastructure
  - Other (custom)

### Step 2: Technology Stack
- **Languages**: Programming languages you'll use (e.g., Python, JavaScript)
- **Frameworks**: Libraries and frameworks (e.g., React, Django, Flask)
- **Databases**: Data storage solutions (e.g., PostgreSQL, MongoDB)
- **Tools**: Development tools and services (e.g., Docker, AWS)

### Step 3: Key Features
Add as many features/components as needed. Type 'done' when finished.

Example:
- User authentication
- Payment processing
- Real-time notifications
- Admin dashboard

### Step 4: Timeline
- Select target completion timeframe
- Set priority level (High/Medium/Low)

### Step 5: Task Generation
The wizard automatically generates initial tasks:
- Project setup tasks
- Feature implementation tasks (one per feature)
- Testing tasks
- Documentation tasks

All tasks are added to `orkestra/logs/task-queue.json`

### Step 6: Committee Review (Optional)
Create a formal vote for the AI Committee to review and approve your plan.

## Generated Outputs

### 1. Project Plan Document
**Location**: `orkestra/docs/planning/project-plan-[timestamp].md`

Contains:
- Project overview and description
- Technology stack details
- Key features list
- Development milestones (4 phases)
- Success metrics
- Next steps

### 2. Task Queue
**Location**: `orkestra/logs/task-queue.json`

Initial tasks include:
- `project-setup`: Infrastructure and environment
- `configure-dependencies`: Install packages
- `feature-X`: One task per feature
- `unit-tests`: Testing tasks
- `documentation`: Docs creation

### 3. Committee Vote (Optional)
**Location**: `orkestra/logs/voting/vote-[timestamp]-[hash].json`

Vote options:
1. Approve plan as-is
2. Approve with minor modifications
3. Request major revisions

## Example Workflow

```bash
# Create new project
orkestra new ai-chatbot

# Planning wizard launches automatically
# Step 1: Describe your AI chatbot project
# Step 2: Choose Python, Flask, OpenAI API
# Step 3: List features:
#   - Natural language understanding
#   - Context retention
#   - Multiple conversation threads
#   - done
# Step 4: Select 1 month timeline, high priority
# Step 5: Generate tasks? → Yes
# Step 6: Call committee vote? → Yes

# Review generated plan
cat orkestra/docs/planning/project-plan-*.md

# Check tasks
cat orkestra/logs/task-queue.json

# Start working
orkestra start
```

## Tips

### Best Practices
1. **Be Specific**: Detailed descriptions help the AI committee understand your goals
2. **Break Down Features**: List discrete, implementable features rather than vague concepts
3. **Realistic Timeline**: Consider project complexity when setting deadlines
4. **Review Plan**: Always review the generated plan and adjust as needed

### Editing Plans
Plans are markdown files in `orkestra/docs/planning/` - edit them directly:

```bash
vim orkestra/docs/planning/project-plan-*.md
```

### Multiple Plans
Create multiple planning scenarios:
1. Access planning wizard from main menu (Option 1)
2. Generate alternative plans with different approaches
3. Call committee votes to compare options

### Integration with Committee
When you create a committee vote, all 5 AI agents will:
1. Review the project plan document
2. Consider technical feasibility
3. Suggest improvements
4. Vote on approval
5. Generate outcome with recommendations

Check vote results:
```
orkestra → Committee System → View Results
```

## File Structure

After planning, your project will have:

```
my-project/
├── orkestra/
│   ├── docs/
│   │   └── planning/
│   │       └── project-plan-20251102-143022.md
│   └── logs/
│       ├── task-queue.json
│       └── voting/
│           └── vote-20251102-143022-a3f8d1e2.json
├── readme.md
└── changelog.md
```

## Advanced Usage

### Skip Planning for Quick Tests
```bash
orkestra new test-project --skip-planning
```

### Custom Templates with Pre-Planning
Create project templates with pre-defined plans for common project types.

### Programmatic Planning
Import and use the planning functions in your own scripts:

```bash
# Source the planning functions
source orkestra/scripts/core/project-planning.sh

# Call specific functions
collect_project_info
generate_plan_document
```

## Troubleshooting

### Planning Script Not Found
```bash
# Check if script exists
ls orkestra/scripts/core/project-planning.sh

# Make it executable
chmod +x orkestra/scripts/core/project-planning.sh
```

### Tasks Not Created
Ensure `orkestra/logs/` directory exists:
```bash
mkdir -p orkestra/logs
```

### Committee Vote Fails
Check that:
1. `orkestra/logs/voting/` directory exists
2. Python 3 is available for JSON processing
3. Committee system scripts are in place

## Related Documentation

- [DEMO_VOTE_PROCESS.md](../DEMO_VOTE_PROCESS.md) - Complete voting workflow
- [QUICKSTART.md](../DOCS/GUIDES/QUICKSTART.md) - Getting started guide
- [Task Management](../DOCS/GUIDES/TASK_MANAGEMENT.md) - Task queue documentation

## Support

For issues or questions:
1. Check `orkestra/logs/orchestrator.log` for errors
2. Review generated plan file for completeness
3. Access main menu for manual planning option
4. Consult AI Committee for recommendations

---

**The Project Planning Wizard helps you start right by thinking through your project before you code.** 🎯
