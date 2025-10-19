# ═══════════════════════════════════════════════════════════════════════════
# ORKESTRA DEPENDENCY RULES
# ═══════════════════════════════════════════════════════════════════════════
# Defines rules for task dependencies and execution order
# Ensures tasks execute in correct sequence with all prerequisites met
# ═══════════════════════════════════════════════════════════════════════════

## 📋 Dependency Types

### 1. **Hard Dependencies (Blocking)**
Tasks that MUST complete before this task can start.
- Status: `completed` required
- Blocking: Task cannot start if any hard dependency is not completed
- Example: "Deploy API" depends on "Write API Code"

### 2. **Soft Dependencies (Non-blocking)**
Tasks that SHOULD complete first, but not strictly required.
- Status: `completed` preferred, but task can proceed
- Non-blocking: Task can start with warning if soft dependency incomplete
- Example: "Write API Docs" depends on "Write API Code" (can start in parallel)

### 3. **Conditional Dependencies**
Dependencies that only apply under certain conditions.
- Condition-based: Applies only if specific criteria met
- Example: "Deploy to Production" depends on "Run Tests" only if tests exist

### 4. **Circular Dependencies (INVALID)**
Tasks that depend on each other in a cycle.
- Status: ERROR - must be resolved
- Detection: Automatic during validation
- Resolution: Break cycle by removing or reordering dependencies

---

## 🔍 Dependency Validation Rules

### Rule 1: Dependency Must Exist
```json
{
  "rule": "dependency_exists",
  "check": "All task IDs in dependencies array must exist in queue",
  "action": "Fail validation if dependency task not found"
}
```

### Rule 2: No Self-Dependencies
```json
{
  "rule": "no_self_dependency",
  "check": "Task cannot depend on itself",
  "action": "Fail validation if task_id in own dependencies array"
}
```

### Rule 3: No Circular Dependencies
```json
{
  "rule": "no_circular_dependencies",
  "check": "Traverse dependency graph, detect cycles",
  "action": "Fail validation and report cycle path"
}
```

### Rule 4: Dependency Status Check
```json
{
  "rule": "dependency_status",
  "check": "Dependencies must be completed before task can start",
  "action": "Block task execution until dependencies complete"
}
```

### Rule 5: Dependency Chain Validation
```json
{
  "rule": "chain_validation",
  "check": "Ensure entire dependency chain is valid",
  "action": "Validate from leaf nodes to root"
}
```

---

## 🎯 Execution Order Rules

### Priority-Based Ordering
```yaml
1. Critical priority tasks first
2. High priority tasks second
3. Medium priority tasks third
4. Low priority tasks last
```

### Dependency-Based Ordering
```yaml
1. Tasks with no dependencies (leaf nodes)
2. Tasks whose dependencies are completed
3. Tasks waiting on in-progress dependencies
4. Blocked tasks (dependencies failed/blocked)
```

### Combined Priority + Dependencies
```
Order = (Priority Weight × 100) + (Dependency Depth × 10) + Queue Position
```

**Priority Weights:**
- Critical: 4
- High: 3
- Medium: 2
- Low: 1

**Dependency Depth:**
- Number of tasks that depend on this task (downstream count)

---

## 🔄 Dependency Resolution Algorithm

```
FUNCTION resolve_dependencies(task_id):
    1. Get task from queue
    2. Get all dependencies
    3. FOR EACH dependency:
        a. Check if dependency exists
        b. Check dependency status
        c. If status != completed:
            - If hard dependency: BLOCK task
            - If soft dependency: WARN and ALLOW
        d. If dependency has dependencies:
            - Recursively resolve (depth-first)
    4. Build execution order list
    5. Return order
```

---

## 📊 Dependency Graph Structure

```json
{
  "graph": {
    "task_0001": {
      "dependencies": [],
      "dependents": ["task_0002", "task_0003"],
      "depth": 0,
      "can_execute": true
    },
    "task_0002": {
      "dependencies": ["task_0001"],
      "dependents": ["task_0004"],
      "depth": 1,
      "can_execute": false
    },
    "task_0003": {
      "dependencies": ["task_0001"],
      "dependents": [],
      "depth": 1,
      "can_execute": false
    },
    "task_0004": {
      "dependencies": ["task_0002"],
      "dependents": [],
      "depth": 2,
      "can_execute": false
    }
  }
}
```

---

## 🚨 Error Handling

### Missing Dependency
```yaml
Error: DEPENDENCY_NOT_FOUND
Message: "Task task_0005 depends on task_0099 which does not exist"
Action: Remove invalid dependency or create missing task
Resolution: Auto-remove if --auto-fix enabled
```

### Circular Dependency
```yaml
Error: CIRCULAR_DEPENDENCY
Message: "Circular dependency detected: task_0001 → task_0002 → task_0003 → task_0001"
Action: Break cycle by removing one dependency
Resolution: Requires manual intervention
```

### Failed Dependency
```yaml
Error: DEPENDENCY_FAILED
Message: "Cannot execute task_0002 because dependency task_0001 failed"
Action: Mark task as blocked, queue for retry when dependency fixed
Resolution: Fix failed dependency first
```

### Blocked Dependency Chain
```yaml
Error: DEPENDENCY_BLOCKED
Message: "Task task_0005 blocked by upstream dependency task_0001"
Action: Wait for upstream task to unblock
Resolution: Automatic when upstream unblocks
```

---

## 🛠️ Dependency Commands

### Check Dependencies
```bash
# Check if task can execute
./check-dependencies.sh task_0001

# Show dependency tree
./check-dependencies.sh task_0001 --tree

# Validate all dependencies
./check-dependencies.sh --validate-all
```

### Add Dependency
```bash
# Add hard dependency
./manage-dependencies.sh add task_0002 task_0001

# Add soft dependency
./manage-dependencies.sh add task_0002 task_0001 --soft

# Add conditional dependency
./manage-dependencies.sh add task_0002 task_0001 --condition "tests_exist"
```

### Remove Dependency
```bash
# Remove specific dependency
./manage-dependencies.sh remove task_0002 task_0001

# Remove all dependencies
./manage-dependencies.sh remove task_0002 --all
```

### Visualize Graph
```bash
# Show ASCII dependency graph
./visualize-dependencies.sh

# Export DOT format for graphviz
./visualize-dependencies.sh --format dot > deps.dot
dot -Tpng deps.dot -o deps.png
```

---

## 📈 Execution Examples

### Example 1: Simple Chain
```
task_0001 (Write Code)
    ↓
task_0002 (Write Tests) [depends: task_0001]
    ↓
task_0003 (Deploy) [depends: task_0002]

Execution Order: task_0001 → task_0002 → task_0003
```

### Example 2: Parallel Execution
```
task_0001 (Setup Database)
    ↓
    ├─→ task_0002 (Write API) [depends: task_0001]
    └─→ task_0003 (Write Frontend) [depends: task_0001]
    
task_0002 and task_0003 can execute in parallel after task_0001
```

### Example 3: Diamond Dependencies
```
         task_0001
        ↙         ↘
   task_0002    task_0003
        ↘         ↙
         task_0004

task_0004 depends on both task_0002 AND task_0003
Must wait for both to complete
```

### Example 4: Complex Workflow
```
task_0001 (Setup)
    ↓
task_0002 (Backend) [depends: task_0001]
    ↓
    ├─→ task_0003 (API Tests) [depends: task_0002]
    ├─→ task_0004 (Integration Tests) [depends: task_0002]
    └─→ task_0005 (API Docs) [depends: task_0002, soft]

task_0006 (Frontend) [depends: task_0001]
    ↓
task_0007 (UI Tests) [depends: task_0006]

task_0008 (Deploy) [depends: task_0003, task_0004, task_0006]

Execution:
1. task_0001
2. task_0002, task_0006 (parallel)
3. task_0003, task_0004, task_0005, task_0007 (parallel after deps)
4. task_0008 (after task_0003, task_0004, task_0006 complete)
```

---

## 🎓 Best Practices

### ✅ DO:
- Keep dependency chains short (max 5 levels deep)
- Use meaningful task IDs
- Document why dependencies exist
- Review dependency graph regularly
- Allow parallel execution when possible
- Use soft dependencies for documentation tasks

### ❌ DON'T:
- Create circular dependencies
- Make tasks depend on themselves
- Create overly complex dependency chains
- Use dependencies when not necessary
- Forget to validate before execution
- Ignore dependency warnings

---

## 🔧 Integration with Democracy Engine

Dependency resolution integrates with democracy engine:

1. **Dependency Conflicts**: When dependencies conflict, agents vote on resolution
2. **Execution Order**: Agents vote on optimal execution order for parallel tasks
3. **Blocking Decisions**: Agents vote whether to proceed when soft dependencies incomplete
4. **Retry Strategy**: Agents vote on how to handle failed dependencies

---

## 📚 Related Documentation

- [Democracy Engine](./democracy-engine.md) - Agent voting and consensus
- [Task Template](../TEMPLATES/task-template.json) - Task structure
- [Task Management](./task-management-guide.md) - Creating and managing tasks
- [Automation System](./automation-system.md) - Automatic task execution

---

*Last Updated: October 18, 2025*  
*Version: 1.0.0*
