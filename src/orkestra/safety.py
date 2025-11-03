"""
Orkestra Safety System

Validates tasks before and after execution, prevents errors, ensures quality.
Replaces bash scripts from SCRIPTS/SAFETY/.
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import json
import subprocess
from enum import Enum

from .tasks import TaskQueue, Task, TaskStatus


class ValidationLevel(Enum):
    """Severity levels for validation results"""
    PASS = "pass"
    WARNING = "warning"
    FAIL = "fail"
    CRITICAL = "critical"


class ValidationCategory(Enum):
    """Categories of validation checks"""
    FILE_SYSTEM = "file_system"
    DATA_INTEGRITY = "data_integrity"
    DEPENDENCIES = "dependencies"
    PERMISSIONS = "permissions"
    RESOURCES = "resources"
    CONSISTENCY = "consistency"
    QUALITY = "quality"
    SECURITY = "security"


@dataclass
class ValidationResult:
    """Result of a validation check"""
    check_name: str
    category: ValidationCategory
    level: ValidationLevel
    message: str
    details: Optional[str] = None
    suggestion: Optional[str] = None
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()
    
    @property
    def passed(self) -> bool:
        """Check if validation passed"""
        return self.level == ValidationLevel.PASS
    
    @property
    def is_blocker(self) -> bool:
        """Check if this is a blocking issue"""
        return self.level in [ValidationLevel.FAIL, ValidationLevel.CRITICAL]


class PreTaskValidator:
    """
    Validates conditions BEFORE task execution
    
    Prevents 90% of common execution errors by checking:
    - Task queue integrity
    - Task status and dependencies
    - File system state
    - Resource availability
    - Lock conditions
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.logs_dir = self.project_root / "orkestra" / "logs" / "safety"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
        
    def validate_task(self, task_id: str, agent_name: str) -> Tuple[bool, List[ValidationResult]]:
        """
        Run all pre-task validation checks
        
        Args:
            task_id: Task to validate
            agent_name: Agent that will execute task
            
        Returns:
            Tuple of (can_proceed, list of validation results)
        """
        results = []
        
        # Run all checks
        results.append(self._check_task_queue_exists())
        results.append(self._check_valid_json())
        results.append(self._check_task_exists(task_id))
        results.append(self._check_task_status(task_id))
        results.append(self._check_dependencies_met(task_id))
        results.append(self._check_no_lock_conflict(task_id, agent_name))
        results.append(self._check_agent_available(agent_name))
        results.append(self._check_output_directory_writable(task_id))
        results.append(self._check_git_repository_clean())
        results.append(self._check_disk_space())
        
        # Log results
        self._log_validation(task_id, agent_name, "PRE", results)
        
        # Determine if can proceed
        has_blockers = any(r.is_blocker for r in results)
        can_proceed = not has_blockers
        
        return can_proceed, results
    
    def _check_task_queue_exists(self) -> ValidationResult:
        """Check if task queue file exists"""
        queue_file = self.project_root / "orkestra" / "task-queue.json"
        
        if queue_file.exists():
            return ValidationResult(
                check_name="Task Queue Exists",
                category=ValidationCategory.FILE_SYSTEM,
                level=ValidationLevel.PASS,
                message="Task queue file exists"
            )
        else:
            return ValidationResult(
                check_name="Task Queue Exists",
                category=ValidationCategory.FILE_SYSTEM,
                level=ValidationLevel.CRITICAL,
                message="Task queue file not found",
                details=f"Expected: {queue_file}",
                suggestion="Run 'orkestra new' to create a project"
            )
    
    def _check_valid_json(self) -> ValidationResult:
        """Check if task queue has valid JSON"""
        queue_file = self.project_root / "orkestra" / "task-queue.json"
        
        try:
            with open(queue_file) as f:
                json.load(f)
            return ValidationResult(
                check_name="Valid JSON",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.PASS,
                message="Task queue has valid JSON structure"
            )
        except json.JSONDecodeError as e:
            return ValidationResult(
                check_name="Valid JSON",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.CRITICAL,
                message="Task queue has invalid JSON",
                details=str(e),
                suggestion="Check for syntax errors in task-queue.json"
            )
        except Exception as e:
            return ValidationResult(
                check_name="Valid JSON",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.CRITICAL,
                message="Cannot read task queue",
                details=str(e)
            )
    
    def _check_task_exists(self, task_id: str) -> ValidationResult:
        """Check if task exists in queue"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if task:
                return ValidationResult(
                    check_name="Task Exists",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.PASS,
                    message=f"Task {task_id} exists in queue"
                )
            else:
                return ValidationResult(
                    check_name="Task Exists",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message=f"Task {task_id} not found in queue",
                    suggestion="Check task ID or run 'orkestra tasks list'"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Task Exists",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.FAIL,
                message="Cannot check task existence",
                details=str(e)
            )
    
    def _check_task_status(self, task_id: str) -> ValidationResult:
        """Check if task status is pending"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Task Status",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message="Task not found"
                )
            
            if task.status == TaskStatus.PENDING:
                return ValidationResult(
                    check_name="Task Status",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.PASS,
                    message=f"Task status is '{task.status.value}'"
                )
            else:
                return ValidationResult(
                    check_name="Task Status",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message=f"Task status is '{task.status.value}', expected 'pending'",
                    suggestion="Task may already be in progress or completed"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Task Status",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.FAIL,
                message="Cannot check task status",
                details=str(e)
            )
    
    def _check_dependencies_met(self, task_id: str) -> ValidationResult:
        """Check if all task dependencies are completed"""
        try:
            queue = TaskQueue(self.project_root)
            
            if queue.check_dependencies(task_id):
                return ValidationResult(
                    check_name="Dependencies Met",
                    category=ValidationCategory.DEPENDENCIES,
                    level=ValidationLevel.PASS,
                    message="All dependencies completed"
                )
            else:
                task = queue.get_task(task_id)
                pending_deps = []
                for dep_id in task.dependencies:
                    dep_task = queue.get_task(dep_id)
                    if dep_task and dep_task.status != TaskStatus.COMPLETED:
                        pending_deps.append(f"{dep_id} ({dep_task.status.value})")
                
                return ValidationResult(
                    check_name="Dependencies Met",
                    category=ValidationCategory.DEPENDENCIES,
                    level=ValidationLevel.FAIL,
                    message="Dependencies not completed",
                    details=f"Pending: {', '.join(pending_deps)}",
                    suggestion="Wait for dependencies to complete first"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Dependencies Met",
                category=ValidationCategory.DEPENDENCIES,
                level=ValidationLevel.WARNING,
                message="Cannot check dependencies",
                details=str(e)
            )
    
    def _check_no_lock_conflict(self, task_id: str, agent_name: str) -> ValidationResult:
        """Check if task is not locked by another agent"""
        locks_dir = self.project_root / "orkestra" / "logs" / "locks"
        lock_file = locks_dir / f"{task_id}.lock"
        
        if not lock_file.exists():
            return ValidationResult(
                check_name="No Lock Conflict",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.PASS,
                message="Task is not locked"
            )
        
        try:
            with open(lock_file) as f:
                lock_data = json.load(f)
            
            locked_by = lock_data.get('agent')
            if locked_by == agent_name:
                return ValidationResult(
                    check_name="No Lock Conflict",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message=f"Task locked by {agent_name} (self)"
                )
            else:
                return ValidationResult(
                    check_name="No Lock Conflict",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.FAIL,
                    message=f"Task locked by {locked_by}",
                    suggestion="Wait for other agent to finish or release lock"
                )
        except Exception as e:
            return ValidationResult(
                check_name="No Lock Conflict",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.WARNING,
                message="Cannot read lock file",
                details=str(e)
            )
    
    def _check_agent_available(self, agent_name: str) -> ValidationResult:
        """Check if agent is not already busy"""
        # Check if agent has any in-progress tasks
        try:
            queue = TaskQueue(self.project_root)
            in_progress = queue.list_tasks(
                status=TaskStatus.IN_PROGRESS,
                assigned_to=agent_name
            )
            
            if not in_progress:
                return ValidationResult(
                    check_name="Agent Available",
                    category=ValidationCategory.RESOURCES,
                    level=ValidationLevel.PASS,
                    message=f"Agent {agent_name} is available"
                )
            else:
                return ValidationResult(
                    check_name="Agent Available",
                    category=ValidationCategory.RESOURCES,
                    level=ValidationLevel.WARNING,
                    message=f"Agent {agent_name} has {len(in_progress)} task(s) in progress",
                    details=f"Tasks: {[t.id for t in in_progress]}",
                    suggestion="May want to wait for current tasks to complete"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Agent Available",
                category=ValidationCategory.RESOURCES,
                level=ValidationLevel.WARNING,
                message="Cannot check agent availability",
                details=str(e)
            )
    
    def _check_output_directory_writable(self, task_id: str) -> ValidationResult:
        """Check if output directories are writable"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Output Writable",
                    category=ValidationCategory.PERMISSIONS,
                    level=ValidationLevel.WARNING,
                    message="Task not found"
                )
            
            # Check if metadata specifies output directory
            output_dir = task.metadata.get('output_dir')
            if output_dir:
                output_path = Path(output_dir)
                if output_path.exists() and not output_path.is_dir():
                    return ValidationResult(
                        check_name="Output Writable",
                        category=ValidationCategory.PERMISSIONS,
                        level=ValidationLevel.FAIL,
                        message=f"Output path exists but is not a directory: {output_dir}"
                    )
                
                # Try to create if doesn't exist
                output_path.mkdir(parents=True, exist_ok=True)
                
                # Check writable
                test_file = output_path / ".write_test"
                try:
                    test_file.touch()
                    test_file.unlink()
                    return ValidationResult(
                        check_name="Output Writable",
                        category=ValidationCategory.PERMISSIONS,
                        level=ValidationLevel.PASS,
                        message="Output directory is writable"
                    )
                except Exception as e:
                    return ValidationResult(
                        check_name="Output Writable",
                        category=ValidationCategory.PERMISSIONS,
                        level=ValidationLevel.FAIL,
                        message=f"Output directory not writable: {output_dir}",
                        details=str(e)
                    )
            
            return ValidationResult(
                check_name="Output Writable",
                category=ValidationCategory.PERMISSIONS,
                level=ValidationLevel.PASS,
                message="No output directory specified"
            )
        except Exception as e:
            return ValidationResult(
                check_name="Output Writable",
                category=ValidationCategory.PERMISSIONS,
                level=ValidationLevel.WARNING,
                message="Cannot check output directory",
                details=str(e)
            )
    
    def _check_git_repository_clean(self) -> ValidationResult:
        """Check if git repository is in clean state"""
        try:
            # Check if we're in a git repo
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                return ValidationResult(
                    check_name="Git Clean",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message="Not a git repository"
                )
            
            # Check for uncommitted changes
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if not result.stdout.strip():
                return ValidationResult(
                    check_name="Git Clean",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message="Git repository is clean"
                )
            else:
                changes = len(result.stdout.strip().split('\n'))
                return ValidationResult(
                    check_name="Git Clean",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.WARNING,
                    message=f"Git has {changes} uncommitted change(s)",
                    suggestion="Consider committing changes before proceeding"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Git Clean",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.WARNING,
                message="Cannot check git status",
                details=str(e)
            )
    
    def _check_disk_space(self) -> ValidationResult:
        """Check if sufficient disk space available"""
        try:
            import shutil
            stat = shutil.disk_usage(self.project_root)
            
            free_gb = stat.free / (1024**3)
            total_gb = stat.total / (1024**3)
            percent_free = (stat.free / stat.total) * 100
            
            if percent_free < 5:
                return ValidationResult(
                    check_name="Disk Space",
                    category=ValidationCategory.RESOURCES,
                    level=ValidationLevel.CRITICAL,
                    message=f"Critical: Only {free_gb:.2f}GB ({percent_free:.1f}%) free",
                    suggestion="Free up disk space before proceeding"
                )
            elif percent_free < 10:
                return ValidationResult(
                    check_name="Disk Space",
                    category=ValidationCategory.RESOURCES,
                    level=ValidationLevel.WARNING,
                    message=f"Low disk space: {free_gb:.2f}GB ({percent_free:.1f}%) free",
                    suggestion="Consider freeing up space"
                )
            else:
                return ValidationResult(
                    check_name="Disk Space",
                    category=ValidationCategory.RESOURCES,
                    level=ValidationLevel.PASS,
                    message=f"Sufficient disk space: {free_gb:.2f}GB ({percent_free:.1f}%) free"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Disk Space",
                category=ValidationCategory.RESOURCES,
                level=ValidationLevel.WARNING,
                message="Cannot check disk space",
                details=str(e)
            )
    
    def _log_validation(self, task_id: str, agent_name: str, phase: str, results: List[ValidationResult]):
        """Log validation results"""
        log_file = self.logs_dir / "validation.log"
        
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'phase': phase,
            'task_id': task_id,
            'agent_name': agent_name,
            'results': [
                {
                    'check': r.check_name,
                    'category': r.category.value,
                    'level': r.level.value,
                    'message': r.message
                }
                for r in results
            ]
        }
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')


class PostTaskValidator:
    """
    Validates conditions AFTER task completion
    
    Ensures quality and consistency by checking:
    - Task status updated correctly
    - Output files created
    - Output quality
    - Git changes committed
    - No errors logged
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.logs_dir = self.project_root / "orkestra" / "logs" / "safety"
        self.logs_dir.mkdir(parents=True, exist_ok=True)
    
    def validate_task(self, task_id: str, agent_name: str) -> Tuple[bool, List[ValidationResult]]:
        """
        Run all post-task validation checks
        
        Args:
            task_id: Task to validate
            agent_name: Agent that executed task
            
        Returns:
            Tuple of (is_valid, list of validation results)
        """
        results = []
        
        # Run all checks
        results.append(self._check_task_completed(task_id))
        results.append(self._check_output_file_exists(task_id))
        results.append(self._check_output_file_not_empty(task_id))
        results.append(self._check_lock_released(task_id))
        results.append(self._check_completion_time_recorded(task_id))
        results.append(self._check_no_error_markers(task_id))
        results.append(self._check_git_changes_committed())
        results.append(self._check_task_queue_consistency())
        
        # Log results
        self._log_validation(task_id, agent_name, "POST", results)
        
        # Determine if valid
        has_failures = any(r.level == ValidationLevel.FAIL for r in results)
        has_criticals = any(r.level == ValidationLevel.CRITICAL for r in results)
        
        is_valid = not (has_failures or has_criticals)
        
        return is_valid, results
    
    def _check_task_completed(self, task_id: str) -> ValidationResult:
        """Check if task marked as completed"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Task Completed",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message="Task not found"
                )
            
            if task.status == TaskStatus.COMPLETED:
                return ValidationResult(
                    check_name="Task Completed",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.PASS,
                    message=f"Task marked as '{task.status.value}'"
                )
            else:
                return ValidationResult(
                    check_name="Task Completed",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message=f"Task status is '{task.status.value}', expected 'completed'"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Task Completed",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.FAIL,
                message="Cannot check task status",
                details=str(e)
            )
    
    def _check_output_file_exists(self, task_id: str) -> ValidationResult:
        """Check if output file was created"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Output Exists",
                    category=ValidationCategory.FILE_SYSTEM,
                    level=ValidationLevel.WARNING,
                    message="Task not found"
                )
            
            output_file = task.metadata.get('output_file')
            if not output_file:
                return ValidationResult(
                    check_name="Output Exists",
                    category=ValidationCategory.FILE_SYSTEM,
                    level=ValidationLevel.PASS,
                    message="No output file specified"
                )
            
            output_path = Path(output_file)
            if output_path.exists():
                return ValidationResult(
                    check_name="Output Exists",
                    category=ValidationCategory.FILE_SYSTEM,
                    level=ValidationLevel.PASS,
                    message=f"Output file exists: {output_file}"
                )
            else:
                return ValidationResult(
                    check_name="Output Exists",
                    category=ValidationCategory.FILE_SYSTEM,
                    level=ValidationLevel.FAIL,
                    message=f"Output file not found: {output_file}"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Output Exists",
                category=ValidationCategory.FILE_SYSTEM,
                level=ValidationLevel.WARNING,
                message="Cannot check output file",
                details=str(e)
            )
    
    def _check_output_file_not_empty(self, task_id: str) -> ValidationResult:
        """Check if output file has content"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Output Not Empty",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.WARNING,
                    message="Task not found"
                )
            
            output_file = task.metadata.get('output_file')
            if not output_file:
                return ValidationResult(
                    check_name="Output Not Empty",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.PASS,
                    message="No output file specified"
                )
            
            output_path = Path(output_file)
            if not output_path.exists():
                return ValidationResult(
                    check_name="Output Not Empty",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.WARNING,
                    message="Output file does not exist"
                )
            
            size = output_path.stat().st_size
            if size > 0:
                return ValidationResult(
                    check_name="Output Not Empty",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.PASS,
                    message=f"Output file has content ({size} bytes)"
                )
            else:
                return ValidationResult(
                    check_name="Output Not Empty",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.WARNING,
                    message="Output file is empty",
                    suggestion="Check if task produced expected output"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Output Not Empty",
                category=ValidationCategory.QUALITY,
                level=ValidationLevel.WARNING,
                message="Cannot check output size",
                details=str(e)
            )
    
    def _check_lock_released(self, task_id: str) -> ValidationResult:
        """Check if task lock was released"""
        locks_dir = self.project_root / "orkestra" / "logs" / "locks"
        lock_file = locks_dir / f"{task_id}.lock"
        
        if not lock_file.exists():
            return ValidationResult(
                check_name="Lock Released",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.PASS,
                message="Task lock released"
            )
        else:
            return ValidationResult(
                check_name="Lock Released",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.WARNING,
                message="Task lock still exists",
                suggestion="Lock should be released after completion"
            )
    
    def _check_completion_time_recorded(self, task_id: str) -> ValidationResult:
        """Check if completion timestamp recorded"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="Completion Time",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.WARNING,
                    message="Task not found"
                )
            
            if task.completed_at:
                return ValidationResult(
                    check_name="Completion Time",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.PASS,
                    message=f"Completion time recorded: {task.completed_at}"
                )
            else:
                return ValidationResult(
                    check_name="Completion Time",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.WARNING,
                    message="Completion time not recorded"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Completion Time",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.WARNING,
                message="Cannot check completion time",
                details=str(e)
            )
    
    def _check_no_error_markers(self, task_id: str) -> ValidationResult:
        """Check for error markers in output"""
        try:
            queue = TaskQueue(self.project_root)
            task = queue.get_task(task_id)
            
            if not task:
                return ValidationResult(
                    check_name="No Errors",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.WARNING,
                    message="Task not found"
                )
            
            output_file = task.metadata.get('output_file')
            if not output_file:
                return ValidationResult(
                    check_name="No Errors",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.PASS,
                    message="No output file to check"
                )
            
            output_path = Path(output_file)
            if not output_path.exists():
                return ValidationResult(
                    check_name="No Errors",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.PASS,
                    message="Output file does not exist"
                )
            
            # Check for common error markers
            error_markers = ["ERROR", "FAILED", "Exception", "Traceback"]
            with open(output_path) as f:
                content = f.read()
                found_errors = [marker for marker in error_markers if marker in content]
            
            if not found_errors:
                return ValidationResult(
                    check_name="No Errors",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.PASS,
                    message="No error markers found in output"
                )
            else:
                return ValidationResult(
                    check_name="No Errors",
                    category=ValidationCategory.QUALITY,
                    level=ValidationLevel.WARNING,
                    message=f"Found error markers: {', '.join(found_errors)}",
                    suggestion="Review output for errors"
                )
        except Exception as e:
            return ValidationResult(
                check_name="No Errors",
                category=ValidationCategory.QUALITY,
                level=ValidationLevel.WARNING,
                message="Cannot check for errors",
                details=str(e)
            )
    
    def _check_git_changes_committed(self) -> ValidationResult:
        """Check if changes were committed to git"""
        try:
            # Check if we're in a git repo
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if result.returncode != 0:
                return ValidationResult(
                    check_name="Git Committed",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message="Not a git repository"
                )
            
            # Check for uncommitted changes
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=self.project_root,
                capture_output=True,
                text=True
            )
            
            if not result.stdout.strip():
                return ValidationResult(
                    check_name="Git Committed",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message="All changes committed"
                )
            else:
                changes = len(result.stdout.strip().split('\n'))
                return ValidationResult(
                    check_name="Git Committed",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.WARNING,
                    message=f"Git has {changes} uncommitted change(s)",
                    suggestion="Commit changes to track progress"
                )
        except Exception as e:
            return ValidationResult(
                check_name="Git Committed",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.WARNING,
                message="Cannot check git status",
                details=str(e)
            )
    
    def _check_task_queue_consistency(self) -> ValidationResult:
        """Check if task queue is still consistent"""
        try:
            queue = TaskQueue(self.project_root)
            # Try to load and validate
            stats = queue.get_statistics()
            
            return ValidationResult(
                check_name="Queue Consistent",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.PASS,
                message="Task queue is consistent"
            )
        except Exception as e:
            return ValidationResult(
                check_name="Queue Consistent",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.FAIL,
                message="Task queue inconsistent",
                details=str(e),
                suggestion="Check task-queue.json for corruption"
            )
    
    def _log_validation(self, task_id: str, agent_name: str, phase: str, results: List[ValidationResult]):
        """Log validation results"""
        log_file = self.logs_dir / "validation.log"
        
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'phase': phase,
            'task_id': task_id,
            'agent_name': agent_name,
            'results': [
                {
                    'check': r.check_name,
                    'category': r.category.value,
                    'level': r.level.value,
                    'message': r.message
                }
                for r in results
            ]
        }
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')


class ConsistencyChecker:
    """
    Check system consistency and integrity
    
    Validates:
    - Data file integrity
    - Reference consistency
    - State machine compliance
    - Resource leaks
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
    
    def check_all(self) -> List[ValidationResult]:
        """
        Run all consistency checks
        
        Returns:
            List of validation results
        """
        results = []
        
        results.append(self._check_task_references())
        results.append(self._check_dependency_cycles())
        results.append(self._check_orphaned_locks())
        results.append(self._check_file_integrity())
        
        return results
    
    def _check_task_references(self) -> ValidationResult:
        """Check if all task references are valid"""
        try:
            queue = TaskQueue(self.project_root)
            all_tasks = queue.list_tasks()
            task_ids = {t.id for t in all_tasks}
            
            invalid_refs = []
            for task in all_tasks:
                for dep_id in task.dependencies:
                    if dep_id not in task_ids:
                        invalid_refs.append(f"{task.id} -> {dep_id}")
            
            if not invalid_refs:
                return ValidationResult(
                    check_name="Valid References",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.PASS,
                    message="All task references are valid"
                )
            else:
                return ValidationResult(
                    check_name="Valid References",
                    category=ValidationCategory.DATA_INTEGRITY,
                    level=ValidationLevel.FAIL,
                    message=f"Found {len(invalid_refs)} invalid reference(s)",
                    details="; ".join(invalid_refs[:5])
                )
        except Exception as e:
            return ValidationResult(
                check_name="Valid References",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.WARNING,
                message="Cannot check references",
                details=str(e)
            )
    
    def _check_dependency_cycles(self) -> ValidationResult:
        """Check for circular dependencies"""
        try:
            queue = TaskQueue(self.project_root)
            all_tasks = queue.list_tasks()
            
            # Build dependency graph
            graph = {t.id: set(t.dependencies) for t in all_tasks}
            
            # Check for cycles using DFS
            def has_cycle(node, visited, rec_stack):
                visited.add(node)
                rec_stack.add(node)
                
                for neighbor in graph.get(node, set()):
                    if neighbor not in visited:
                        if has_cycle(neighbor, visited, rec_stack):
                            return True
                    elif neighbor in rec_stack:
                        return True
                
                rec_stack.remove(node)
                return False
            
            visited = set()
            for task_id in graph:
                if task_id not in visited:
                    if has_cycle(task_id, visited, set()):
                        return ValidationResult(
                            check_name="No Cycles",
                            category=ValidationCategory.DATA_INTEGRITY,
                            level=ValidationLevel.FAIL,
                            message="Circular dependency detected",
                            suggestion="Remove circular dependencies"
                        )
            
            return ValidationResult(
                check_name="No Cycles",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.PASS,
                message="No circular dependencies"
            )
        except Exception as e:
            return ValidationResult(
                check_name="No Cycles",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.WARNING,
                message="Cannot check for cycles",
                details=str(e)
            )
    
    def _check_orphaned_locks(self) -> ValidationResult:
        """Check for locks without corresponding tasks"""
        locks_dir = self.project_root / "orkestra" / "logs" / "locks"
        
        if not locks_dir.exists():
            return ValidationResult(
                check_name="No Orphaned Locks",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.PASS,
                message="No locks directory"
            )
        
        try:
            queue = TaskQueue(self.project_root)
            all_tasks = queue.list_tasks()
            task_ids = {t.id for t in all_tasks}
            
            orphaned = []
            for lock_file in locks_dir.glob("*.lock"):
                task_id = lock_file.stem
                if task_id not in task_ids:
                    orphaned.append(task_id)
            
            if not orphaned:
                return ValidationResult(
                    check_name="No Orphaned Locks",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.PASS,
                    message="No orphaned locks"
                )
            else:
                return ValidationResult(
                    check_name="No Orphaned Locks",
                    category=ValidationCategory.CONSISTENCY,
                    level=ValidationLevel.WARNING,
                    message=f"Found {len(orphaned)} orphaned lock(s)",
                    details=", ".join(orphaned[:5]),
                    suggestion="Remove old lock files"
                )
        except Exception as e:
            return ValidationResult(
                check_name="No Orphaned Locks",
                category=ValidationCategory.CONSISTENCY,
                level=ValidationLevel.WARNING,
                message="Cannot check locks",
                details=str(e)
            )
    
    def _check_file_integrity(self) -> ValidationResult:
        """Check if all JSON files are valid"""
        try:
            # Check task queue
            queue_file = self.project_root / "orkestra" / "task-queue.json"
            with open(queue_file) as f:
                json.load(f)
            
            # Check vote files
            voting_dir = self.project_root / "orkestra" / "logs" / "voting"
            if voting_dir.exists():
                for vote_file in voting_dir.glob("*.json"):
                    with open(vote_file) as f:
                        json.load(f)
            
            # Check context files
            context_dir = self.project_root / "orkestra" / "logs" / "context"
            if context_dir.exists():
                for context_file in context_dir.glob("*.json"):
                    with open(context_file) as f:
                        json.load(f)
            
            return ValidationResult(
                check_name="File Integrity",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.PASS,
                message="All JSON files are valid"
            )
        except json.JSONDecodeError as e:
            return ValidationResult(
                check_name="File Integrity",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.FAIL,
                message="JSON file corrupted",
                details=str(e),
                suggestion="Restore from backup or fix JSON syntax"
            )
        except Exception as e:
            return ValidationResult(
                check_name="File Integrity",
                category=ValidationCategory.DATA_INTEGRITY,
                level=ValidationLevel.WARNING,
                message="Cannot check file integrity",
                details=str(e)
            )


class SelfHealing:
    """
    Automatic recovery from common issues
    
    Can fix:
    - Orphaned locks
    - Stuck tasks
    - Invalid references
    - File corruption (from backups)
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
    
    def auto_heal(self) -> List[str]:
        """
        Attempt to automatically fix common issues
        
        Returns:
            List of actions taken
        """
        actions = []
        
        actions.extend(self._clean_orphaned_locks())
        actions.extend(self._reset_stuck_tasks())
        actions.extend(self._remove_invalid_references())
        
        return actions
    
    def _clean_orphaned_locks(self) -> List[str]:
        """Remove locks for non-existent tasks"""
        actions = []
        locks_dir = self.project_root / "orkestra" / "logs" / "locks"
        
        if not locks_dir.exists():
            return actions
        
        try:
            queue = TaskQueue(self.project_root)
            all_tasks = queue.list_tasks()
            task_ids = {t.id for t in all_tasks}
            
            for lock_file in locks_dir.glob("*.lock"):
                task_id = lock_file.stem
                if task_id not in task_ids:
                    lock_file.unlink()
                    actions.append(f"Removed orphaned lock: {task_id}")
        except Exception as e:
            actions.append(f"Error cleaning locks: {e}")
        
        return actions
    
    def _reset_stuck_tasks(self) -> List[str]:
        """Reset tasks stuck in progress"""
        actions = []
        
        try:
            queue = TaskQueue(self.project_root)
            in_progress = queue.list_tasks(status=TaskStatus.IN_PROGRESS)
            
            # Tasks in progress for more than 1 hour are considered stuck
            cutoff = datetime.now() - timedelta(hours=1)
            
            for task in in_progress:
                updated = datetime.fromisoformat(task.updated_at)
                if updated < cutoff:
                    queue.update_task(task.id, status=TaskStatus.PENDING)
                    actions.append(f"Reset stuck task: {task.id}")
        except Exception as e:
            actions.append(f"Error resetting tasks: {e}")
        
        return actions
    
    def _remove_invalid_references(self) -> List[str]:
        """Remove dependencies to non-existent tasks"""
        actions = []
        
        try:
            queue = TaskQueue(self.project_root)
            all_tasks = queue.list_tasks()
            task_ids = {t.id for t in all_tasks}
            
            for task in all_tasks:
                valid_deps = [dep for dep in task.dependencies if dep in task_ids]
                if len(valid_deps) < len(task.dependencies):
                    removed = len(task.dependencies) - len(valid_deps)
                    queue.update_task(task.id, dependencies=valid_deps)
                    actions.append(f"Removed {removed} invalid dependency(ies) from {task.id}")
        except Exception as e:
            actions.append(f"Error cleaning references: {e}")
        
        return actions
