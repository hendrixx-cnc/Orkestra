#!/usr/bin/env python3
"""
Orkestra Task Management System
Handles task creation, queuing, execution, and tracking
"""

import json
import hashlib
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class TaskStatus(Enum):
    """Task status enumeration"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    BLOCKED = "blocked"
    CANCELLED = "cancelled"


class TaskPriority(Enum):
    """Task priority enumeration"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class Task:
    """Represents a task in the queue"""
    id: str
    description: str
    priority: str
    category: str
    status: str = "pending"
    created_at: int = field(default_factory=lambda: int(datetime.now().timestamp()))
    assigned_to: Optional[str] = None
    dependencies: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    completed_at: Optional[int] = None
    started_at: Optional[int] = None
    error_message: Optional[str] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        return asdict(self)
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Task':
        """Create Task from dictionary"""
        return cls(**data)
    
    def is_ready(self, completed_tasks: List[str]) -> bool:
        """Check if task is ready to execute
        
        Args:
            completed_tasks: List of completed task IDs
            
        Returns:
            True if all dependencies are met
        """
        if self.status != TaskStatus.PENDING.value:
            return False
        
        return all(dep in completed_tasks for dep in self.dependencies)


class TaskQueue:
    """Manages task queue and execution"""
    
    def __init__(self, project_root: Path):
        """Initialize task queue
        
        Args:
            project_root: Root directory of the project
        """
        self.project_root = Path(project_root)
        self.logs_dir = self.project_root / "orkestra" / "logs"
        self.queue_file = self.logs_dir / "task-queue.json"
        self.execution_log = self.logs_dir / "execution" / "task-execution.log"
        
        # Create directories
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        (self.logs_dir / "execution").mkdir(exist_ok=True)
        
        # Initialize queue if doesn't exist
        if not self.queue_file.exists():
            self._save_queue({"tasks": []})
    
    def add_task(
        self,
        task_id: str,
        description: str,
        priority: str = "medium",
        category: str = "general",
        dependencies: Optional[List[str]] = None,
        assigned_to: Optional[str] = None,
        metadata: Optional[Dict] = None
    ) -> Task:
        """Add a task to the queue
        
        Args:
            task_id: Unique task identifier
            description: Task description
            priority: Task priority (low, medium, high, critical)
            category: Task category
            dependencies: List of task IDs that must complete first
            assigned_to: Agent or user assigned to task
            metadata: Additional metadata
            
        Returns:
            Created Task object
        """
        # Validate priority
        if priority not in [p.value for p in TaskPriority]:
            raise ValueError(f"Invalid priority: {priority}")
        
        # Create task
        task = Task(
            id=task_id,
            description=description,
            priority=priority,
            category=category,
            dependencies=dependencies or [],
            assigned_to=assigned_to,
            metadata=metadata or {}
        )
        
        # Load queue
        queue_data = self._load_queue()
        
        # Check for duplicate ID
        existing_ids = {t["id"] for t in queue_data["tasks"]}
        if task_id in existing_ids:
            raise ValueError(f"Task with ID '{task_id}' already exists")
        
        # Add task
        queue_data["tasks"].append(task.to_dict())
        
        # Save queue
        self._save_queue(queue_data)
        
        # Log task creation
        self._log_execution(f"Task created: {task_id} - {description}")
        
        return task
    
    def get_task(self, task_id: str) -> Optional[Task]:
        """Get a task by ID
        
        Args:
            task_id: Task identifier
            
        Returns:
            Task object or None
        """
        queue_data = self._load_queue()
        
        for task_data in queue_data["tasks"]:
            if task_data["id"] == task_id:
                return Task.from_dict(task_data)
        
        return None
    
    def update_task(
        self,
        task_id: str,
        status: Optional[str] = None,
        assigned_to: Optional[str] = None,
        error_message: Optional[str] = None
    ) -> Optional[Task]:
        """Update a task
        
        Args:
            task_id: Task identifier
            status: New status
            assigned_to: New assignment
            error_message: Error message if failed
            
        Returns:
            Updated Task object or None
        """
        queue_data = self._load_queue()
        task_found = False
        updated_task = None
        
        for i, task_data in enumerate(queue_data["tasks"]):
            if task_data["id"] == task_id:
                task_found = True
                
                # Update status
                if status:
                    old_status = task_data["status"]
                    task_data["status"] = status
                    
                    # Update timestamps
                    if status == TaskStatus.IN_PROGRESS.value and not task_data.get("started_at"):
                        task_data["started_at"] = int(datetime.now().timestamp())
                    elif status == TaskStatus.COMPLETED.value:
                        task_data["completed_at"] = int(datetime.now().timestamp())
                    
                    self._log_execution(f"Task {task_id} status: {old_status} → {status}")
                
                # Update assignment
                if assigned_to is not None:
                    task_data["assigned_to"] = assigned_to
                    self._log_execution(f"Task {task_id} assigned to: {assigned_to}")
                
                # Update error
                if error_message:
                    task_data["error_message"] = error_message
                    self._log_execution(f"Task {task_id} error: {error_message}")
                
                queue_data["tasks"][i] = task_data
                updated_task = Task.from_dict(task_data)
                break
        
        if task_found:
            self._save_queue(queue_data)
        
        return updated_task
    
    def list_tasks(
        self,
        status: Optional[str] = None,
        category: Optional[str] = None,
        priority: Optional[str] = None
    ) -> List[Task]:
        """List tasks with optional filtering
        
        Args:
            status: Filter by status
            category: Filter by category
            priority: Filter by priority
            
        Returns:
            List of Task objects
        """
        queue_data = self._load_queue()
        tasks = [Task.from_dict(t) for t in queue_data["tasks"]]
        
        # Apply filters
        if status:
            tasks = [t for t in tasks if t.status == status]
        if category:
            tasks = [t for t in tasks if t.category == category]
        if priority:
            tasks = [t for t in tasks if t.priority == priority]
        
        return tasks
    
    def get_next_task(self) -> Optional[Task]:
        """Get the next ready task to execute
        
        Returns:
            Task object or None
        """
        queue_data = self._load_queue()
        
        # Get completed task IDs
        completed_ids = [
            t["id"] for t in queue_data["tasks"]
            if t["status"] == TaskStatus.COMPLETED.value
        ]
        
        # Priority order
        priority_order = {
            TaskPriority.CRITICAL.value: 0,
            TaskPriority.HIGH.value: 1,
            TaskPriority.MEDIUM.value: 2,
            TaskPriority.LOW.value: 3
        }
        
        # Find ready tasks
        ready_tasks = []
        for task_data in queue_data["tasks"]:
            task = Task.from_dict(task_data)
            if task.is_ready(completed_ids):
                ready_tasks.append(task)
        
        if not ready_tasks:
            return None
        
        # Sort by priority and creation time
        ready_tasks.sort(
            key=lambda t: (priority_order.get(t.priority, 99), t.created_at)
        )
        
        return ready_tasks[0]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get queue statistics
        
        Returns:
            Dictionary with statistics
        """
        queue_data = self._load_queue()
        tasks = [Task.from_dict(t) for t in queue_data["tasks"]]
        
        stats = {
            "total": len(tasks),
            "by_status": {},
            "by_priority": {},
            "by_category": {},
            "blocked": 0,
            "ready": 0
        }
        
        # Count by status
        for status in TaskStatus:
            count = sum(1 for t in tasks if t.status == status.value)
            stats["by_status"][status.value] = count
        
        # Count by priority
        for priority in TaskPriority:
            count = sum(1 for t in tasks if t.priority == priority.value)
            stats["by_priority"][priority.value] = count
        
        # Count by category
        categories = set(t.category for t in tasks)
        for category in categories:
            count = sum(1 for t in tasks if t.category == category)
            stats["by_category"][category] = count
        
        # Count ready tasks
        completed_ids = [t.id for t in tasks if t.status == TaskStatus.COMPLETED.value]
        stats["ready"] = sum(1 for t in tasks if t.is_ready(completed_ids))
        
        # Count blocked tasks
        stats["blocked"] = sum(1 for t in tasks if t.status == TaskStatus.BLOCKED.value)
        
        return stats
    
    def check_dependencies(self, task_id: str) -> Dict[str, Any]:
        """Check task dependencies
        
        Args:
            task_id: Task identifier
            
        Returns:
            Dictionary with dependency information
        """
        task = self.get_task(task_id)
        if not task:
            return {"error": "Task not found"}
        
        queue_data = self._load_queue()
        
        # Get dependency status
        dep_info = {
            "task_id": task_id,
            "dependencies": [],
            "all_met": True,
            "missing": [],
            "blocked_by": []
        }
        
        for dep_id in task.dependencies:
            # Find dependency task
            dep_task = None
            for t in queue_data["tasks"]:
                if t["id"] == dep_id:
                    dep_task = Task.from_dict(t)
                    break
            
            if not dep_task:
                dep_info["missing"].append(dep_id)
                dep_info["all_met"] = False
            else:
                dep_status = {
                    "id": dep_id,
                    "status": dep_task.status,
                    "completed": dep_task.status == TaskStatus.COMPLETED.value
                }
                dep_info["dependencies"].append(dep_status)
                
                if dep_task.status != TaskStatus.COMPLETED.value:
                    dep_info["all_met"] = False
                    dep_info["blocked_by"].append(dep_id)
        
        return dep_info
    
    def clear_completed(self) -> int:
        """Remove completed tasks from queue
        
        Returns:
            Number of tasks removed
        """
        queue_data = self._load_queue()
        original_count = len(queue_data["tasks"])
        
        # Keep only non-completed tasks
        queue_data["tasks"] = [
            t for t in queue_data["tasks"]
            if t["status"] != TaskStatus.COMPLETED.value
        ]
        
        removed_count = original_count - len(queue_data["tasks"])
        
        if removed_count > 0:
            self._save_queue(queue_data)
            self._log_execution(f"Cleared {removed_count} completed tasks")
        
        return removed_count
    
    def _load_queue(self) -> Dict:
        """Load task queue from file
        
        Returns:
            Queue data dictionary
        """
        try:
            with open(self.queue_file) as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {"tasks": []}
    
    def _save_queue(self, queue_data: Dict):
        """Save task queue to file
        
        Args:
            queue_data: Queue data dictionary
        """
        with open(self.queue_file, 'w') as f:
            json.dump(queue_data, f, indent=2)
    
    def _log_execution(self, message: str):
        """Log execution message
        
        Args:
            message: Message to log
        """
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}\n"
        
        with open(self.execution_log, 'a') as f:
            f.write(log_message)
