"""
Orkestra Automation System

Task coordination, locking, recovery, and autonomy features.
Replaces bash scripts from SCRIPTS/AUTOMATION/.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from enum import Enum
import json
import logging
import asyncio
import time
import psutil


@dataclass
class Lock:
    """Task lock information"""
    task_id: int
    owner: str
    acquired_at: datetime
    pid: int
    timeout: int = 3600  # 1 hour default


class LockManager:
    """
    Atomic task locking system
    
    Provides file-based locks with timeout and staleness detection.
    """
    
    def __init__(self, project_root: Path, timeout: int = 3600):
        self.project_root = Path(project_root)
        self.lock_dir = self.project_root / "orkestra" / "locks"
        self.lock_dir.mkdir(parents=True, exist_ok=True)
        self.timeout = timeout
        self.logger = logging.getLogger("orkestra.lock")
    
    def acquire_lock(
        self,
        task_id: int,
        agent_name: str,
        max_attempts: int = 3
    ) -> bool:
        """
        Acquire lock atomically for a task
        
        Args:
            task_id: Task ID
            agent_name: Name of agent requesting lock
            max_attempts: Maximum retry attempts
            
        Returns:
            True if lock acquired
        """
        lock_dir = self.lock_dir / f"task_{task_id}.lock"
        
        for attempt in range(max_attempts):
            try:
                # Use mkdir for atomic lock creation
                lock_dir.mkdir(parents=False, exist_ok=False)
                
                # Lock acquired, write metadata
                (lock_dir / "owner").write_text(agent_name)
                (lock_dir / "timestamp").write_text(str(int(time.time())))
                (lock_dir / "pid").write_text(str(psutil.Process().pid))
                
                self.logger.info(f"✅ Lock acquired for Task #{task_id} by {agent_name}")
                return True
                
            except FileExistsError:
                # Lock exists, check if stale
                if self._is_stale_lock(lock_dir):
                    self.logger.warning(f"Stale lock detected for Task #{task_id}, breaking...")
                    self.release_lock(task_id, "TIMEOUT")
                    continue
                
                # Lock held by another agent
                owner = self._get_lock_owner(lock_dir)
                self.logger.info(
                    f"⏳ Task #{task_id} locked by {owner}, "
                    f"waiting... (attempt {attempt + 1}/{max_attempts})"
                )
                time.sleep(2)
        
        self.logger.error(f"❌ Failed to acquire lock for Task #{task_id}")
        return False
    
    def release_lock(self, task_id: int, reason: str = "COMPLETE") -> bool:
        """
        Release lock for a task
        
        Args:
            task_id: Task ID
            reason: Reason for release
            
        Returns:
            True if lock released
        """
        lock_dir = self.lock_dir / f"task_{task_id}.lock"
        
        if not lock_dir.exists():
            self.logger.warning(f"⚠️  No lock found for Task #{task_id}")
            return False
        
        try:
            # Log release reason
            (lock_dir / "release_reason").write_text(
                f"{reason} at {datetime.now().isoformat()}"
            )
            
            # Remove lock directory
            import shutil
            shutil.rmtree(lock_dir)
            
            self.logger.info(f"🔓 Lock released for Task #{task_id} (reason: {reason})")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to release lock for Task #{task_id}: {e}")
            return False
    
    def check_lock(self, task_id: int) -> Optional[Lock]:
        """
        Check if task is locked
        
        Args:
            task_id: Task ID
            
        Returns:
            Lock info if locked, None otherwise
        """
        lock_dir = self.lock_dir / f"task_{task_id}.lock"
        
        if not lock_dir.exists():
            return None
        
        try:
            owner = (lock_dir / "owner").read_text().strip()
            timestamp = int((lock_dir / "timestamp").read_text().strip())
            pid = int((lock_dir / "pid").read_text().strip())
            
            return Lock(
                task_id=task_id,
                owner=owner,
                acquired_at=datetime.fromtimestamp(timestamp),
                pid=pid,
                timeout=self.timeout
            )
        except Exception as e:
            self.logger.error(f"Failed to read lock for Task #{task_id}: {e}")
            return None
    
    def _is_stale_lock(self, lock_dir: Path) -> bool:
        """Check if lock is stale (timed out)"""
        try:
            timestamp_file = lock_dir / "timestamp"
            if not timestamp_file.exists():
                return True
            
            lock_time = int(timestamp_file.read_text().strip())
            age = int(time.time()) - lock_time
            
            return age > self.timeout
        except Exception:
            return True
    
    def _get_lock_owner(self, lock_dir: Path) -> str:
        """Get owner of lock"""
        try:
            return (lock_dir / "owner").read_text().strip()
        except Exception:
            return "unknown"
    
    def clean_stale_locks(self) -> int:
        """
        Clean all stale locks
        
        Returns:
            Number of locks cleaned
        """
        cleaned = 0
        
        for lock_dir in self.lock_dir.glob("task_*.lock"):
            if self._is_stale_lock(lock_dir):
                try:
                    task_id = int(lock_dir.name.split('_')[1].split('.')[0])
                    if self.release_lock(task_id, "STALE"):
                        cleaned += 1
                except Exception as e:
                    self.logger.error(f"Failed to clean lock {lock_dir}: {e}")
        
        if cleaned > 0:
            self.logger.info(f"🧹 Cleaned {cleaned} stale locks")
        
        return cleaned
    
    def get_all_locks(self) -> Dict[int, Lock]:
        """
        Get all current locks
        
        Returns:
            Dict mapping task IDs to Lock objects
        """
        locks = {}
        
        for lock_dir in self.lock_dir.glob("task_*.lock"):
            try:
                task_id = int(lock_dir.name.split('_')[1].split('.')[0])
                lock = self.check_lock(task_id)
                if lock:
                    locks[task_id] = lock
            except Exception as e:
                self.logger.error(f"Failed to read lock {lock_dir}: {e}")
        
        return locks


@dataclass
class AgentWorkload:
    """Agent workload information"""
    agent_name: str
    active_tasks: int = 0
    locked_tasks: int = 0
    total_completed: int = 0
    success_rate: float = 0.0
    
    @property
    def total_workload(self) -> int:
        return self.active_tasks + self.locked_tasks


class TaskCoordinator:
    """
    Intelligent task coordination system
    
    Features:
    - Automatic dependency resolution
    - Load balancing
    - Work distribution
    - Smart agent selection
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.task_queue_path = self.project_root / "orkestra" / "TASK_QUEUE.json"
        self.lock_manager = LockManager(project_root)
        self.logger = logging.getLogger("orkestra.coordinator")
        
        # Import tasks module
        try:
            from . import tasks
            self.task_queue = tasks.TaskQueue(project_root)
        except ImportError:
            self.logger.error("Failed to import tasks module")
            self.task_queue = None
    
    def get_agent_workload(self, agent_name: str) -> AgentWorkload:
        """
        Calculate agent's current workload
        
        Args:
            agent_name: Name of agent
            
        Returns:
            AgentWorkload object
        """
        if not self.task_queue:
            return AgentWorkload(agent_name=agent_name)
        
        # Count active tasks
        all_tasks = self.task_queue.list_tasks()
        active = sum(
            1 for t in all_tasks
            if t.status == "in_progress" and t.assigned_to == agent_name
        )
        
        # Count locked tasks
        locks = self.lock_manager.get_all_locks()
        locked = sum(1 for lock in locks.values() if lock.owner == agent_name)
        
        # Count completed tasks
        completed = sum(
            1 for t in all_tasks
            if t.status == "completed" and t.assigned_to == agent_name
        )
        
        # Calculate success rate
        total_assigned = sum(
            1 for t in all_tasks
            if t.assigned_to == agent_name and t.status in ["completed", "failed"]
        )
        success_rate = completed / total_assigned if total_assigned > 0 else 1.0
        
        return AgentWorkload(
            agent_name=agent_name,
            active_tasks=active,
            locked_tasks=locked,
            total_completed=completed,
            success_rate=success_rate
        )
    
    def select_agent_by_load(
        self,
        task_type: str,
        capable_agents: Optional[List[str]] = None
    ) -> str:
        """
        Select least loaded capable agent
        
        Args:
            task_type: Type of task
            capable_agents: List of capable agents (None for all)
            
        Returns:
            Name of best agent
        """
        if capable_agents is None:
            # Default capable agents by task type
            type_mapping = {
                'technical': ['copilot', 'claude'],
                'content': ['claude', 'chatgpt'],
                'creative': ['chatgpt', 'claude'],
                'firebase': ['gemini', 'copilot'],
                'cloud': ['gemini', 'copilot'],
                'architecture': ['gemini', 'copilot']
            }
            capable_agents = type_mapping.get(
                task_type.lower(),
                ['copilot', 'claude', 'chatgpt', 'gemini', 'grok']
            )
        
        # Find agent with lowest workload
        min_load = float('inf')
        best_agent = capable_agents[0] if capable_agents else 'claude'
        
        for agent in capable_agents:
            workload = self.get_agent_workload(agent)
            load = workload.total_workload
            
            # Prefer agents with better success rates
            adjusted_load = load / max(workload.success_rate, 0.1)
            
            if adjusted_load < min_load:
                min_load = adjusted_load
                best_agent = agent
        
        self.logger.info(f"Selected {best_agent} for {task_type} task (load: {min_load:.1f})")
        return best_agent
    
    def dependencies_met(self, task_id: int) -> bool:
        """
        Check if all task dependencies are completed
        
        Args:
            task_id: Task ID
            
        Returns:
            True if all dependencies met
        """
        if not self.task_queue:
            return True
        
        task = self.task_queue.get_task(task_id)
        if not task or not task.dependencies:
            return True
        
        for dep_id in task.dependencies:
            dep_task = self.task_queue.get_task(dep_id)
            if not dep_task or dep_task.status != "completed":
                return False
        
        return True
    
    def get_ready_tasks(self) -> List:
        """
        Get all tasks ready for execution
        
        Returns:
            List of tasks with dependencies met
        """
        if not self.task_queue:
            return []
        
        all_tasks = self.task_queue.list_tasks()
        ready = []
        
        for task in all_tasks:
            if task.status == "pending" and self.dependencies_met(task.id):
                ready.append(task)
        
        return ready
    
    def assign_task(self, task_id: int, agent_name: str) -> bool:
        """
        Assign task to agent with lock
        
        Args:
            task_id: Task ID
            agent_name: Agent name
            
        Returns:
            True if assigned successfully
        """
        if not self.task_queue:
            return False
        
        # Acquire lock
        if not self.lock_manager.acquire_lock(task_id, agent_name):
            return False
        
        # Update task
        try:
            self.task_queue.update_task(
                task_id,
                status="in_progress",
                assigned_to=agent_name
            )
            return True
        except Exception as e:
            self.logger.error(f"Failed to assign task {task_id}: {e}")
            self.lock_manager.release_lock(task_id, "ERROR")
            return False
    
    def complete_task(self, task_id: int, result: str = "") -> bool:
        """
        Mark task as completed and release lock
        
        Args:
            task_id: Task ID
            result: Task result/output
            
        Returns:
            True if completed successfully
        """
        if not self.task_queue:
            return False
        
        try:
            self.task_queue.update_task(
                task_id,
                status="completed",
                result=result
            )
            self.lock_manager.release_lock(task_id, "COMPLETE")
            return True
        except Exception as e:
            self.logger.error(f"Failed to complete task {task_id}: {e}")
            return False


class SmartTaskSelector:
    """
    Intelligent task selection based on agent capabilities
    
    Any agent can do any task, but priority given to best-suited agents.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.logger = logging.getLogger("orkestra.selector")
        
        # Agent specialties
        self.agent_specialties = {
            'gemini': [
                'firebase', 'google_cloud', 'database_design',
                'scaling', 'cost_optimization'
            ],
            'chatgpt': [
                'copywriting', 'marketing', 'creative_content',
                'content_review', 'tone_validation'
            ],
            'claude': [
                'documentation', 'code_review', 'architecture',
                'testing', 'debugging'
            ],
            'copilot': [
                'coding', 'refactoring', 'api_design',
                'system_maintenance', 'deployment'
            ],
            'grok': [
                'research', 'analysis', 'problem_solving',
                'innovation', 'creative_solutions'
            ]
        }
        
        # Keyword mappings for task types
        self.task_keywords = {
            'firebase': ['firebase', 'firestore', 'cloud', 'database', 'scaling', 'migration'],
            'copywriting': ['copy', 'marketing', 'landing', 'newsletter', 'content', 'write'],
            'documentation': ['review', 'test', 'documentation', 'mobile', 'ux', 'tone'],
            'design': ['design', 'svg', 'icon', 'visual', 'graphic', 'ui'],
            'system': ['setup', 'config', 'system', 'environment', 'deploy'],
            'coding': ['code', 'function', 'api', 'implement', 'refactor', 'bug']
        }
    
    def calculate_suitability_score(
        self,
        agent_name: str,
        task_title: str,
        task_instructions: str = ""
    ) -> int:
        """
        Calculate how suitable an agent is for a task (0-100)
        
        Args:
            agent_name: Name of agent
            task_title: Task title
            task_instructions: Task instructions
            
        Returns:
            Suitability score (0-100)
        """
        score = 50  # Base score - any agent can do any task
        
        task_text = f"{task_title} {task_instructions}".lower()
        specialties = self.agent_specialties.get(agent_name.lower(), [])
        
        # Boost score based on specialty matches
        for specialty in specialties:
            # Check if specialty keywords match task
            keywords = self.task_keywords.get(specialty, [specialty])
            
            for keyword in keywords:
                if keyword in task_text:
                    score += 15
                    break
        
        # Cap at 100
        return min(score, 100)
    
    def get_workload_penalty(self, agent_name: str, coordinator: TaskCoordinator) -> int:
        """
        Calculate workload penalty for agent (0-100)
        
        Args:
            agent_name: Name of agent
            coordinator: TaskCoordinator instance
            
        Returns:
            Penalty score (higher = busier)
        """
        workload = coordinator.get_agent_workload(agent_name)
        
        # Each task adds 20 penalty points
        penalty = workload.total_workload * 20
        
        # Reduce penalty for agents with high success rates
        penalty = int(penalty * (1.0 - workload.success_rate * 0.3))
        
        return min(penalty, 100)
    
    def select_best_agent(
        self,
        task_id: int,
        coordinator: TaskCoordinator,
        available_agents: Optional[List[str]] = None
    ) -> str:
        """
        Select best agent for a task
        
        Args:
            task_id: Task ID
            coordinator: TaskCoordinator instance
            available_agents: List of available agents
            
        Returns:
            Name of best agent
        """
        if not coordinator.task_queue:
            return 'claude'  # Default
        
        task = coordinator.task_queue.get_task(task_id)
        if not task:
            return 'claude'
        
        if available_agents is None:
            available_agents = list(self.agent_specialties.keys())
        
        best_agent = available_agents[0]
        best_score = -1
        
        for agent in available_agents:
            # Calculate suitability score
            suitability = self.calculate_suitability_score(
                agent,
                task.title,
                task.instructions
            )
            
            # Calculate workload penalty
            penalty = self.get_workload_penalty(agent, coordinator)
            
            # Final score: suitability - penalty
            final_score = suitability - penalty
            
            self.logger.debug(
                f"{agent}: suitability={suitability}, penalty={penalty}, "
                f"final={final_score}"
            )
            
            if final_score > best_score:
                best_score = final_score
                best_agent = agent
        
        self.logger.info(
            f"Selected {best_agent} for Task #{task_id} '{task.title}' "
            f"(score: {best_score})"
        )
        
        return best_agent


class RecoverySystem:
    """
    Task recovery and resilience system
    
    Handles failed tasks, retries, and graceful degradation.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.logger = logging.getLogger("orkestra.recovery")
        self.max_retries = 3
        self.retry_delay = 60  # seconds
    
    def recover_failed_task(
        self,
        task_id: int,
        coordinator: TaskCoordinator
    ) -> bool:
        """
        Attempt to recover a failed task
        
        Args:
            task_id: Task ID
            coordinator: TaskCoordinator instance
            
        Returns:
            True if recovery initiated
        """
        if not coordinator.task_queue:
            return False
        
        task = coordinator.task_queue.get_task(task_id)
        if not task:
            return False
        
        # Check retry count
        retry_count = task.metadata.get('retry_count', 0)
        
        if retry_count >= self.max_retries:
            self.logger.error(
                f"Task #{task_id} exceeded max retries ({self.max_retries})"
            )
            return False
        
        # Reset task to pending
        coordinator.task_queue.update_task(
            task_id,
            status="pending",
            assigned_to=None,
            metadata={'retry_count': retry_count + 1}
        )
        
        # Release any locks
        coordinator.lock_manager.release_lock(task_id, "RECOVERY")
        
        self.logger.info(
            f"Task #{task_id} queued for recovery (attempt {retry_count + 1})"
        )
        
        return True
    
    def recover_stuck_tasks(self, coordinator: TaskCoordinator) -> int:
        """
        Find and recover stuck tasks
        
        Args:
            coordinator: TaskCoordinator instance
            
        Returns:
            Number of tasks recovered
        """
        if not coordinator.task_queue:
            return 0
        
        recovered = 0
        all_tasks = coordinator.task_queue.list_tasks()
        
        for task in all_tasks:
            if task.status == "in_progress":
                # Check if lock is stale
                lock = coordinator.lock_manager.check_lock(task.id)
                
                if not lock:
                    # Task marked in progress but no lock
                    self.logger.warning(
                        f"Task #{task.id} in progress but not locked, recovering..."
                    )
                    if self.recover_failed_task(task.id, coordinator):
                        recovered += 1
        
        if recovered > 0:
            self.logger.info(f"Recovered {recovered} stuck tasks")
        
        return recovered


class DaemonManager:
    """
    Background daemon management
    
    Manages long-running background processes.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.daemon_dir = self.project_root / "orkestra" / "daemons"
        self.daemon_dir.mkdir(parents=True, exist_ok=True)
        self.logger = logging.getLogger("orkestra.daemon")
        self.daemons: Dict[str, asyncio.Task] = {}
    
    async def start_daemon(
        self,
        name: str,
        coro,
        restart_on_failure: bool = True
    ):
        """
        Start a background daemon
        
        Args:
            name: Daemon name
            coro: Coroutine to run
            restart_on_failure: Restart if daemon fails
        """
        if name in self.daemons:
            self.logger.warning(f"Daemon '{name}' already running")
            return
        
        async def daemon_wrapper():
            while True:
                try:
                    await coro()
                except Exception as e:
                    self.logger.error(f"Daemon '{name}' failed: {e}")
                    
                    if not restart_on_failure:
                        break
                    
                    self.logger.info(f"Restarting daemon '{name}' in 10s...")
                    await asyncio.sleep(10)
        
        task = asyncio.create_task(daemon_wrapper())
        self.daemons[name] = task
        
        self.logger.info(f"Started daemon: {name}")
    
    async def stop_daemon(self, name: str):
        """Stop a daemon"""
        if name not in self.daemons:
            return
        
        self.daemons[name].cancel()
        try:
            await self.daemons[name]
        except asyncio.CancelledError:
            pass
        
        del self.daemons[name]
        self.logger.info(f"Stopped daemon: {name}")
    
    def get_daemon_status(self, name: str) -> str:
        """Get daemon status"""
        if name not in self.daemons:
            return "stopped"
        
        task = self.daemons[name]
        if task.done():
            if task.exception():
                return "failed"
            return "completed"
        
        return "running"


class AuditLogger:
    """
    Task audit logging system
    
    Maintains detailed audit trail of all task operations.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.audit_dir = self.project_root / "orkestra" / "logs" / "audit"
        self.audit_dir.mkdir(parents=True, exist_ok=True)
        self.logger = logging.getLogger("orkestra.audit")
    
    def log_event(
        self,
        event_type: str,
        task_id: Optional[int],
        agent_name: Optional[str],
        details: Dict
    ):
        """
        Log an audit event
        
        Args:
            event_type: Type of event
            task_id: Related task ID
            agent_name: Related agent name
            details: Event details
        """
        timestamp = datetime.now()
        
        event = {
            'timestamp': timestamp.isoformat(),
            'event_type': event_type,
            'task_id': task_id,
            'agent_name': agent_name,
            'details': details
        }
        
        # Write to daily log file
        log_file = self.audit_dir / f"audit_{timestamp.strftime('%Y%m%d')}.jsonl"
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(event) + '\n')
        
        self.logger.debug(f"Audit: {event_type} - Task #{task_id} - {agent_name}")
    
    def get_events(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[str] = None,
        task_id: Optional[int] = None
    ) -> List[Dict]:
        """
        Query audit events
        
        Args:
            start_date: Start date filter
            end_date: End date filter
            event_type: Event type filter
            task_id: Task ID filter
            
        Returns:
            List of matching events
        """
        events = []
        
        for log_file in sorted(self.audit_dir.glob("audit_*.jsonl")):
            with open(log_file) as f:
                for line in f:
                    try:
                        event = json.loads(line)
                        
                        # Apply filters
                        event_time = datetime.fromisoformat(event['timestamp'])
                        
                        if start_date and event_time < start_date:
                            continue
                        if end_date and event_time > end_date:
                            continue
                        if event_type and event['event_type'] != event_type:
                            continue
                        if task_id is not None and event['task_id'] != task_id:
                            continue
                        
                        events.append(event)
                    except Exception as e:
                        self.logger.error(f"Failed to parse audit event: {e}")
        
        return events
