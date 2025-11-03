# Bash to Python Conversion Roadmap

## Overview
This document outlines the plan for converting all remaining bash scripts to Python modules, completing the migration started with `committee.py`, `tasks.py`, and `planning.py`.

## Conversion Status

### ✅ Completed (Phase 1)
- **SCRIPTS/COMMITTEE/** → `src/orkestra/committee.py`
  - `process-vote.sh` → `Committee.process_vote()`
  - `gather-context.sh` → `Committee.gather_context()`
  - Democratic voting with 5 AI agents
  - Consensus checking algorithms
  - Vote persistence to JSON

- **SCRIPTS/TASK-MANAGEMENT/** → `src/orkestra/tasks.py`
  - `add-task.sh` → `TaskQueue.add_task()`
  - `list-tasks.sh` → `TaskQueue.list_tasks()`
  - `check-dependencies.sh` → `TaskQueue.check_dependencies()`
  - Task lifecycle management
  - Priority and dependency handling
  - Queue statistics and analytics

- **SCRIPTS/CORE/project-planning.sh** → `src/orkestra/planning.py`
  - Interactive wizard with Rich UI
  - AI planning rounds with user feedback
  - Plan approval workflow
  - Automatic task generation

### 🔄 In Progress (Phase 2)

#### SCRIPTS/AGENTS/
**Purpose:** Individual AI agent wrappers for API calls

**Target Module:** `src/orkestra/agents.py`

**Bash Scripts to Convert:**
- `claude-agent.sh` (Anthropic API wrapper)
- `chatgpt-agent.sh` (OpenAI API wrapper)
- `gemini-agent.sh` (Google AI API wrapper)
- `copilot-agent.sh` (GitHub Copilot API wrapper)
- `grok-agent.sh` (xAI API wrapper)

**Python Implementation:**
```python
# src/orkestra/agents.py

from abc import ABC, abstractmethod
from typing import Optional, Dict, Any
import os
from dataclasses import dataclass

@dataclass
class AgentConfig:
    """Configuration for an AI agent"""
    name: str
    api_key: str
    model: str
    temperature: float = 0.7
    max_tokens: int = 4000

class Agent(ABC):
    """Base class for AI agents"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
    
    @abstractmethod
    async def call(self, prompt: str, context: str = "") -> str:
        """Make API call to agent"""
        pass
    
    @abstractmethod
    def test_connection(self) -> bool:
        """Verify API credentials work"""
        pass

class ClaudeAgent(Agent):
    """Anthropic Claude integration"""
    
    async def call(self, prompt: str, context: str = "") -> str:
        import anthropic
        client = anthropic.Anthropic(api_key=self.config.api_key)
        
        message = client.messages.create(
            model=self.config.model,
            max_tokens=self.config.max_tokens,
            temperature=self.config.temperature,
            system=context,
            messages=[{"role": "user", "content": prompt}]
        )
        return message.content[0].text

class ChatGPTAgent(Agent):
    """OpenAI ChatGPT integration"""
    
    async def call(self, prompt: str, context: str = "") -> str:
        import openai
        client = openai.OpenAI(api_key=self.config.api_key)
        
        messages = []
        if context:
            messages.append({"role": "system", "content": context})
        messages.append({"role": "user", "content": prompt})
        
        response = client.chat.completions.create(
            model=self.config.model,
            messages=messages,
            temperature=self.config.temperature,
            max_tokens=self.config.max_tokens
        )
        return response.choices[0].message.content

class GeminiAgent(Agent):
    """Google Gemini integration"""
    
    async def call(self, prompt: str, context: str = "") -> str:
        import google.generativeai as genai
        genai.configure(api_key=self.config.api_key)
        
        model = genai.GenerativeModel(self.config.model)
        full_prompt = f"{context}\n\n{prompt}" if context else prompt
        
        response = model.generate_content(full_prompt)
        return response.text

class CopilotAgent(Agent):
    """GitHub Copilot integration"""
    
    async def call(self, prompt: str, context: str = "") -> str:
        # TODO: Implement GitHub Copilot API
        # Note: May require special access
        pass

class GrokAgent(Agent):
    """xAI Grok integration"""
    
    async def call(self, prompt: str, context: str = "") -> str:
        # TODO: Implement xAI API
        # Note: API may be in beta
        pass
```

**Conversion Priority:** HIGH
**Estimated Effort:** 3-4 hours
**Dependencies:** 
- `anthropic` library
- `openai` library
- `google-generativeai` library
- API keys in `CONFIG/api-keys.env`

---

#### SCRIPTS/AUTOMATION/
**Purpose:** Workflow automation and task execution

**Target Module:** `src/orkestra/automation.py`

**Bash Scripts to Convert:**
- `auto-executor.sh` - Automatic task execution
- `workflow-engine.sh` - Workflow orchestration
- `task-processor.sh` - Task processing logic

**Python Implementation:**
```python
# src/orkestra/automation.py

from typing import Optional, Callable, Dict, Any
from dataclasses import dataclass
import asyncio
from .tasks import TaskQueue, Task, TaskStatus
from .agents import Agent

@dataclass
class WorkflowConfig:
    """Configuration for workflow execution"""
    max_parallel_tasks: int = 3
    retry_attempts: int = 3
    timeout_seconds: int = 300

class TaskExecutor:
    """Executes tasks with AI agents"""
    
    def __init__(self, queue: TaskQueue, agents: Dict[str, Agent]):
        self.queue = queue
        self.agents = agents
    
    async def execute_task(self, task: Task) -> bool:
        """Execute a single task"""
        pass
    
    async def process_queue(self, config: WorkflowConfig):
        """Process task queue with parallel execution"""
        pass

class WorkflowEngine:
    """Orchestrates multi-step workflows"""
    
    def __init__(self, executor: TaskExecutor):
        self.executor = executor
    
    async def run_workflow(self, workflow_id: str):
        """Execute a predefined workflow"""
        pass
```

**Conversion Priority:** HIGH
**Estimated Effort:** 4-5 hours
**Dependencies:** `asyncio`, `tasks.py`, `agents.py`

---

#### SCRIPTS/MONITORING/
**Purpose:** Progress tracking and status reporting

**Target Module:** `src/orkestra/monitoring.py`

**Bash Scripts to Convert:**
- `status-check.sh` - Check system status
- `progress-tracker.sh` - Track task progress
- `report-generator.sh` - Generate status reports

**Python Implementation:**
```python
# src/orkestra/monitoring.py

from typing import Dict, List, Optional
from dataclasses import dataclass
from datetime import datetime, timedelta
from .tasks import TaskQueue

@dataclass
class ProjectMetrics:
    """Project health metrics"""
    total_tasks: int
    completed_tasks: int
    in_progress_tasks: int
    blocked_tasks: int
    failed_tasks: int
    completion_rate: float
    average_task_time: Optional[timedelta]
    
class ProgressTracker:
    """Track project progress"""
    
    def __init__(self, queue: TaskQueue):
        self.queue = queue
    
    def get_metrics(self) -> ProjectMetrics:
        """Calculate current project metrics"""
        pass
    
    def generate_report(self) -> str:
        """Generate status report"""
        pass
    
    def check_blockers(self) -> List[str]:
        """Find blocked or failing tasks"""
        pass
```

**Conversion Priority:** MEDIUM
**Estimated Effort:** 2-3 hours
**Dependencies:** `tasks.py`

---

### 📋 Pending (Phase 3)

#### SCRIPTS/DEMOCRACY/
**Purpose:** Advanced consensus algorithms

**Target Module:** `src/orkestra/democracy.py`

**Bash Scripts:**
- `consensus-builder.sh`
- `voting-algorithms.sh`
- `delegation-system.sh`

**Python Implementation:**
```python
# src/orkestra/democracy.py

from typing import List, Dict, Optional
from enum import Enum
from dataclasses import dataclass

class ConsensusMethod(Enum):
    UNANIMOUS = "unanimous"      # All must agree
    SUPERMAJORITY = "supermajority"  # 75%+
    MAJORITY = "majority"        # 50%+
    PLURALITY = "plurality"      # Most votes wins

@dataclass
class VotingRule:
    """Rules for voting process"""
    method: ConsensusMethod
    min_participation: float = 0.8
    allow_abstention: bool = True
    weight_by_expertise: bool = False

class ConsensusBuilder:
    """Advanced consensus mechanisms"""
    
    def calculate_consensus(
        self,
        votes: Dict[str, str],
        rules: VotingRule
    ) -> tuple[str, float]:
        """
        Calculate consensus decision
        Returns: (decision, confidence_score)
        """
        pass
```

**Conversion Priority:** MEDIUM
**Estimated Effort:** 3-4 hours

---

#### SCRIPTS/SAFETY/
**Purpose:** Safety checks and validation

**Target Module:** `src/orkestra/safety.py`

**Bash Scripts:**
- `validate-changes.sh`
- `security-check.sh`
- `rollback-system.sh`

**Python Implementation:**
```python
# src/orkestra/safety.py

from typing import List, Dict, Optional
from dataclasses import dataclass
from pathlib import Path

@dataclass
class SafetyCheck:
    """Result of a safety validation"""
    passed: bool
    severity: str  # "critical", "warning", "info"
    message: str
    suggestion: Optional[str] = None

class SafetyValidator:
    """Validate changes before execution"""
    
    def validate_task(self, task_id: str) -> List[SafetyCheck]:
        """Run safety checks on task"""
        pass
    
    def validate_file_changes(self, files: List[Path]) -> List[SafetyCheck]:
        """Check file modifications"""
        pass
    
    def can_proceed(self, checks: List[SafetyCheck]) -> bool:
        """Determine if safe to proceed"""
        return all(c.passed or c.severity != "critical" for c in checks)
```

**Conversion Priority:** HIGH
**Estimated Effort:** 2-3 hours

---

#### SCRIPTS/UTILS/
**Purpose:** Utility functions and helpers

**Target Module:** `src/orkestra/utils.py`

**Bash Scripts:**
- `file-operations.sh`
- `git-helpers.sh`
- `json-tools.sh`
- `logging.sh`

**Python Implementation:**
```python
# src/orkestra/utils.py

from pathlib import Path
from typing import Any, Dict, Optional
import json
import subprocess
import logging

class FileOperations:
    """File system utilities"""
    
    @staticmethod
    def safe_read(path: Path) -> Optional[str]:
        """Read file with error handling"""
        pass
    
    @staticmethod
    def atomic_write(path: Path, content: str):
        """Write file atomically"""
        pass

class GitHelpers:
    """Git operations"""
    
    @staticmethod
    def get_current_branch(repo_path: Path) -> str:
        """Get active git branch"""
        pass
    
    @staticmethod
    def get_recent_commits(repo_path: Path, limit: int = 10) -> List[Dict]:
        """Get commit history"""
        pass

class JSONTools:
    """JSON manipulation"""
    
    @staticmethod
    def merge_json(base: Dict, updates: Dict) -> Dict:
        """Deep merge JSON objects"""
        pass
    
    @staticmethod
    def validate_schema(data: Dict, schema: Dict) -> bool:
        """Validate JSON against schema"""
        pass
```

**Conversion Priority:** LOW
**Estimated Effort:** 2-3 hours

---

#### SCRIPTS/MAINTENANCE/
**Purpose:** System maintenance tasks

**Target Module:** `src/orkestra/maintenance.py`

**Bash Scripts:**
- `cleanup.sh`
- `backup.sh`
- `optimize.sh`

**Python Implementation:**
```python
# src/orkestra/maintenance.py

from pathlib import Path
from datetime import datetime, timedelta
import shutil

class Maintenance:
    """System maintenance operations"""
    
    def cleanup_old_logs(self, days: int = 30):
        """Remove logs older than N days"""
        pass
    
    def backup_data(self, backup_dir: Path):
        """Create backup of critical data"""
        pass
    
    def optimize_storage(self):
        """Clean up unnecessary files"""
        pass
```

**Conversion Priority:** LOW
**Estimated Effort:** 1-2 hours

---

#### SCRIPTS/COMPRESSION/
**Purpose:** File compression and archiving

**Target Module:** `src/orkestra/compression.py`

**Bash Scripts:**
- `compress-logs.sh`
- `archive-completed.sh`

**Python Implementation:**
```python
# src/orkestra/compression.py

from pathlib import Path
import gzip
import tarfile

class Compression:
    """File compression utilities"""
    
    @staticmethod
    def compress_logs(log_dir: Path):
        """Compress old log files"""
        pass
    
    @staticmethod
    def create_archive(files: List[Path], output: Path):
        """Create tar.gz archive"""
        pass
```

**Conversion Priority:** LOW
**Estimated Effort:** 1 hour

---

## Conversion Guidelines

### Code Style
- Use dataclasses for structured data
- Use enums for constants
- Type hints on all public methods
- Docstrings in Google style
- Follow PEP 8

### Error Handling
```python
# Bad (bash way)
try:
    result = risky_operation()
except:
    pass

# Good (Python way)
try:
    result = risky_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
    raise  # Or handle appropriately
```

### Async Operations
```python
# Use async for I/O-bound operations
async def call_api(endpoint: str) -> Dict:
    async with aiohttp.ClientSession() as session:
        async with session.get(endpoint) as response:
            return await response.json()

# Use concurrent.futures for CPU-bound
from concurrent.futures import ThreadPoolExecutor

with ThreadPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(process_task, tasks))
```

### Testing
Every module should have corresponding tests:
```
tests/
├── test_committee.py
├── test_tasks.py
├── test_planning.py
├── test_agents.py
├── test_automation.py
├── test_monitoring.py
└── ...
```

### Documentation
Each module needs:
1. Module docstring with overview
2. Class docstrings
3. Method docstrings with Args/Returns
4. Usage examples in docstring
5. Entry in PYTHON_MODULES.md

---

## Timeline

### Week 1 (Current)
- ✅ committee.py (completed)
- ✅ tasks.py (completed)
- ✅ planning.py (completed)
- ✅ CLI integration (completed)

### Week 2
- 🔄 agents.py (in progress)
  - Implement Claude agent
  - Implement ChatGPT agent
  - Implement Gemini agent
  - Add API key management
- 🔄 automation.py (in progress)
  - Task executor
  - Workflow engine

### Week 3
- monitoring.py
- safety.py
- democracy.py (advanced features)

### Week 4
- utils.py
- maintenance.py
- compression.py
- Complete testing
- Update documentation

---

## Testing Strategy

### Unit Tests
```python
# Test each module in isolation
pytest tests/test_committee.py -v
pytest tests/test_tasks.py -v
pytest tests/test_planning.py -v
```

### Integration Tests
```python
# Test modules working together
pytest tests/integration/ -v
```

### End-to-End Tests
```bash
# Full workflow tests
./tests/e2e/test_project_creation.sh
./tests/e2e/test_planning_workflow.sh
./tests/e2e/test_task_execution.sh
```

### Performance Tests
```python
# Benchmark critical operations
pytest tests/performance/ -v --benchmark
```

---

## Migration Strategy

### Parallel Operation
During conversion, both bash and Python versions coexist:
- Bash scripts remain in `SCRIPTS/`
- Python modules in `src/orkestra/`
- CLI can use either (flag: `--use-python`)

### Gradual Cutover
1. Python module created and tested
2. CLI updated to prefer Python version
3. Bash script marked deprecated
4. After 2 weeks, bash script moved to `ARCHIVE/`

### Rollback Plan
If Python version has issues:
```bash
# Revert to bash version
orkestra config set use_bash_scripts true

# Or for specific component
orkestra config set use_bash_planning true
```

---

## Dependencies to Add

### Phase 2 Requirements
```txt
# API clients
anthropic>=0.18.0
openai>=1.0.0
google-generativeai>=0.3.0

# Async support
aiohttp>=3.9.0
asyncio-extras>=1.3.0

# Progress bars
tqdm>=4.66.0

# Testing
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-benchmark>=4.0.0
pytest-mock>=3.12.0
```

### Update setup.py
```python
install_requires=[
    'click>=8.0.0',
    'rich>=10.0.0',
    'anthropic>=0.18.0',
    'openai>=1.0.0',
    'google-generativeai>=0.3.0',
    'aiohttp>=3.9.0',
    'tqdm>=4.66.0',
]
```

---

## Success Metrics

### Code Quality
- ✅ 100% type hint coverage
- ✅ 90%+ test coverage
- ✅ All docstrings complete
- ✅ Zero linting errors

### Performance
- ✅ Task processing 2x faster than bash
- ✅ Startup time < 1 second
- ✅ Memory usage < 100MB

### Functionality
- ✅ All bash features replicated
- ✅ New features added (async, better error handling)
- ✅ Backward compatible (JSON files)

---

## Questions & Decisions

### Q: Keep bash scripts as fallback?
**Decision:** Yes, keep in `SCRIPTS/` for 1 month after Python proven stable, then move to `ARCHIVE/old-bash-scripts/`.

### Q: Async by default or optional?
**Decision:** Async for API calls (agents), synchronous for file operations (simpler).

### Q: Single large module or many small ones?
**Decision:** Moderate granularity - one module per major concept (agents, automation, etc.).

### Q: Maintain CLI compatibility?
**Decision:** Yes, all existing CLI commands work identically, just faster.

---

## Resources

- **Python Module Docs:** `DOCS/TECHNICAL/PYTHON_MODULES.md`
- **Original Bash Scripts:** `SCRIPTS/*/`
- **Test Examples:** `tests/`
- **Anthropic Docs:** https://docs.anthropic.com/
- **OpenAI Docs:** https://platform.openai.com/docs
- **Google AI Docs:** https://ai.google.dev/docs

---

## Next Steps

1. **Implement agents.py** (highest priority)
   - Start with Claude (most commonly used)
   - Add error handling and retries
   - Test with actual API keys

2. **Update committee.py** to use agents.py
   - Replace stub methods
   - Add proper API error handling
   - Test voting with real AI responses

3. **Implement automation.py**
   - Task executor with agents
   - Parallel task processing
   - Workflow orchestration

4. **Add monitoring.py**
   - Real-time progress tracking
   - Status dashboards
   - Alert system for issues

5. **Document everything**
   - Update PYTHON_MODULES.md
   - Add usage examples
   - Create migration guide

---

## Conclusion

Converting to Python provides:
- ✅ **Type Safety:** Catch errors at development time
- ✅ **Better Testing:** Unit tests, mocks, fixtures
- ✅ **IDE Support:** Autocomplete, refactoring
- ✅ **Maintainability:** Clear structure, documentation
- ✅ **Performance:** Faster startup, better concurrency
- ✅ **Extensibility:** Easy to add features

The migration is 30% complete with core functionality (voting, tasks, planning) already in Python. The remaining work focuses on AI integrations and advanced features.
