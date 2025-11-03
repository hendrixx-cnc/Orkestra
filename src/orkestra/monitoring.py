"""
Orkestra Monitoring System

Monitors system health, agent performance, and task progress.
Replaces bash scripts from SCRIPTS/MONITORING/.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import json
import time
import subprocess
from enum import Enum

from .tasks import TaskQueue, TaskStatus


class HealthStatus(Enum):
    """Health status levels"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    CRITICAL = "critical"


class MonitoringLevel(Enum):
    """Monitoring detail levels"""
    MINIMAL = "minimal"
    STANDARD = "standard"
    DETAILED = "detailed"
    VERBOSE = "verbose"


@dataclass
class AgentHealth:
    """Health metrics for an AI agent"""
    agent_name: str
    status: HealthStatus
    last_active: datetime
    total_tasks: int
    successful_tasks: int
    failed_tasks: int
    average_response_time: float
    error_rate: float
    availability: float
    last_error: Optional[str] = None
    consecutive_failures: int = 0


@dataclass
class SystemMetrics:
    """Overall system health metrics"""
    timestamp: datetime
    overall_status: HealthStatus
    active_agents: int
    total_agents: int
    tasks_completed: int
    tasks_failed: int
    tasks_pending: int
    tasks_in_progress: int
    average_task_time: Optional[float]
    system_uptime: float
    error_rate: float
    throughput: float  # tasks per hour
    
    
@dataclass
class PerformanceMetrics:
    """Performance tracking for an agent or system"""
    start_time: datetime
    end_time: Optional[datetime] = None
    operations: int = 0
    successes: int = 0
    failures: int = 0
    total_time: float = 0.0
    
    @property
    def success_rate(self) -> float:
        """Calculate success rate percentage"""
        if self.operations == 0:
            return 0.0
        return (self.successes / self.operations) * 100
    
    @property
    def failure_rate(self) -> float:
        """Calculate failure rate percentage"""
        if self.operations == 0:
            return 0.0
        return (self.failures / self.operations) * 100
    
    @property
    def average_time(self) -> float:
        """Calculate average operation time"""
        if self.operations == 0:
            return 0.0
        return self.total_time / self.operations


class HealthMonitor:
    """
    Monitor system and agent health
    
    Tracks:
    - Agent availability and response times
    - Task completion rates
    - Error rates and patterns
    - System resource usage
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.health_dir = self.project_root / "orkestra" / "logs" / "health"
        self.health_dir.mkdir(parents=True, exist_ok=True)
        
        self.agent_health: Dict[str, AgentHealth] = {}
        self.system_start_time = datetime.now()
        
    def check_agent_health(self, agent_name: str) -> AgentHealth:
        """
        Check health of a specific agent
        
        Args:
            agent_name: Name of agent to check
            
        Returns:
            AgentHealth object with current metrics
        """
        # Load agent's task history
        queue = TaskQueue(self.project_root)
        agent_tasks = queue.list_tasks(assigned_to=agent_name)
        
        if not agent_tasks:
            return AgentHealth(
                agent_name=agent_name,
                status=HealthStatus.HEALTHY,
                last_active=datetime.now(),
                total_tasks=0,
                successful_tasks=0,
                failed_tasks=0,
                average_response_time=0.0,
                error_rate=0.0,
                availability=100.0
            )
        
        # Calculate metrics
        total = len(agent_tasks)
        completed = sum(1 for t in agent_tasks if t.status == TaskStatus.COMPLETED)
        failed = sum(1 for t in agent_tasks if t.status == TaskStatus.FAILED)
        
        # Get most recent task time
        recent_tasks = sorted(agent_tasks, key=lambda t: t.updated_at, reverse=True)
        last_active = datetime.fromisoformat(recent_tasks[0].updated_at)
        
        # Calculate response time
        response_times = []
        for task in agent_tasks:
            if task.completed_at:
                created = datetime.fromisoformat(task.created_at)
                completed_time = datetime.fromisoformat(task.completed_at)
                response_times.append((completed_time - created).total_seconds())
        
        avg_response = sum(response_times) / len(response_times) if response_times else 0.0
        error_rate = (failed / total * 100) if total > 0 else 0.0
        
        # Determine status
        if error_rate > 50:
            status = HealthStatus.CRITICAL
        elif error_rate > 30:
            status = HealthStatus.UNHEALTHY
        elif error_rate > 10:
            status = HealthStatus.DEGRADED
        else:
            status = HealthStatus.HEALTHY
        
        # Check for consecutive failures
        consecutive_failures = 0
        for task in recent_tasks:
            if task.status == TaskStatus.FAILED:
                consecutive_failures += 1
            else:
                break
        
        health = AgentHealth(
            agent_name=agent_name,
            status=status,
            last_active=last_active,
            total_tasks=total,
            successful_tasks=completed,
            failed_tasks=failed,
            average_response_time=avg_response,
            error_rate=error_rate,
            availability=100.0 - error_rate,
            consecutive_failures=consecutive_failures
        )
        
        self.agent_health[agent_name] = health
        self._save_agent_health(health)
        
        return health
    
    def check_system_health(self) -> SystemMetrics:
        """
        Check overall system health
        
        Returns:
            SystemMetrics with current system state
        """
        queue = TaskQueue(self.project_root)
        stats = queue.get_statistics()
        
        # Check all agents
        agents = ["claude", "chatgpt", "gemini", "copilot", "grok"]
        active_agents = 0
        
        for agent in agents:
            health = self.check_agent_health(agent)
            if health.status in [HealthStatus.HEALTHY, HealthStatus.DEGRADED]:
                active_agents += 1
        
        # Calculate system metrics
        total_tasks = stats['total']
        completed = stats['by_status'].get('completed', 0)
        failed = stats['by_status'].get('failed', 0)
        pending = stats['by_status'].get('pending', 0)
        in_progress = stats['by_status'].get('in_progress', 0)
        
        error_rate = (failed / total_tasks * 100) if total_tasks > 0 else 0.0
        
        # Calculate uptime
        uptime = (datetime.now() - self.system_start_time).total_seconds()
        
        # Calculate throughput (tasks per hour)
        hours = uptime / 3600
        throughput = completed / hours if hours > 0 else 0.0
        
        # Determine overall status
        if active_agents == 0:
            overall_status = HealthStatus.CRITICAL
        elif error_rate > 30:
            overall_status = HealthStatus.UNHEALTHY
        elif error_rate > 10 or active_agents < len(agents) * 0.6:
            overall_status = HealthStatus.DEGRADED
        else:
            overall_status = HealthStatus.HEALTHY
        
        metrics = SystemMetrics(
            timestamp=datetime.now(),
            overall_status=overall_status,
            active_agents=active_agents,
            total_agents=len(agents),
            tasks_completed=completed,
            tasks_failed=failed,
            tasks_pending=pending,
            tasks_in_progress=in_progress,
            average_task_time=None,  # TODO: Calculate from task history
            system_uptime=uptime,
            error_rate=error_rate,
            throughput=throughput
        )
        
        self._save_system_metrics(metrics)
        
        return metrics
    
    def get_health_report(self, level: MonitoringLevel = MonitoringLevel.STANDARD) -> str:
        """
        Generate health report
        
        Args:
            level: Detail level for report
            
        Returns:
            Formatted health report string
        """
        metrics = self.check_system_health()
        
        report = []
        report.append("=" * 70)
        report.append("ORKESTRA SYSTEM HEALTH REPORT")
        report.append("=" * 70)
        report.append(f"Timestamp: {metrics.timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Overall Status: {metrics.overall_status.value.upper()}")
        report.append("")
        
        # System overview
        report.append("SYSTEM OVERVIEW:")
        report.append(f"  Active Agents: {metrics.active_agents}/{metrics.total_agents}")
        report.append(f"  System Uptime: {metrics.system_uptime/3600:.2f} hours")
        report.append(f"  Error Rate: {metrics.error_rate:.2f}%")
        report.append(f"  Throughput: {metrics.throughput:.2f} tasks/hour")
        report.append("")
        
        # Task statistics
        report.append("TASK STATISTICS:")
        report.append(f"  Completed: {metrics.tasks_completed}")
        report.append(f"  In Progress: {metrics.tasks_in_progress}")
        report.append(f"  Pending: {metrics.tasks_pending}")
        report.append(f"  Failed: {metrics.tasks_failed}")
        report.append("")
        
        if level in [MonitoringLevel.DETAILED, MonitoringLevel.VERBOSE]:
            # Agent details
            report.append("AGENT HEALTH:")
            for agent_name in ["claude", "chatgpt", "gemini", "copilot", "grok"]:
                health = self.agent_health.get(agent_name)
                if health:
                    status_icon = self._get_status_icon(health.status)
                    report.append(f"  {status_icon} {agent_name.upper()}")
                    report.append(f"      Status: {health.status.value}")
                    report.append(f"      Tasks: {health.successful_tasks}/{health.total_tasks}")
                    report.append(f"      Error Rate: {health.error_rate:.2f}%")
                    report.append(f"      Avg Response: {health.average_response_time:.2f}s")
                    
                    if health.consecutive_failures > 0:
                        report.append(f"      ⚠️  Consecutive Failures: {health.consecutive_failures}")
                    report.append("")
        
        if level == MonitoringLevel.VERBOSE:
            # Recent errors
            report.append("RECENT ERRORS:")
            for agent_name, health in self.agent_health.items():
                if health.last_error:
                    report.append(f"  [{agent_name}] {health.last_error}")
            report.append("")
        
        report.append("=" * 70)
        
        return "\n".join(report)
    
    def _get_status_icon(self, status: HealthStatus) -> str:
        """Get emoji icon for status"""
        icons = {
            HealthStatus.HEALTHY: "✅",
            HealthStatus.DEGRADED: "⚠️",
            HealthStatus.UNHEALTHY: "🔴",
            HealthStatus.CRITICAL: "💀"
        }
        return icons.get(status, "❓")
    
    def _save_agent_health(self, health: AgentHealth):
        """Save agent health to JSON"""
        file_path = self.health_dir / f"{health.agent_name}_health.json"
        
        data = {
            "agent_name": health.agent_name,
            "status": health.status.value,
            "last_active": health.last_active.isoformat(),
            "total_tasks": health.total_tasks,
            "successful_tasks": health.successful_tasks,
            "failed_tasks": health.failed_tasks,
            "average_response_time": health.average_response_time,
            "error_rate": health.error_rate,
            "availability": health.availability,
            "consecutive_failures": health.consecutive_failures,
            "last_error": health.last_error
        }
        
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)
    
    def _save_system_metrics(self, metrics: SystemMetrics):
        """Save system metrics to JSON"""
        file_path = self.health_dir / "system_metrics.json"
        
        data = {
            "timestamp": metrics.timestamp.isoformat(),
            "overall_status": metrics.overall_status.value,
            "active_agents": metrics.active_agents,
            "total_agents": metrics.total_agents,
            "tasks_completed": metrics.tasks_completed,
            "tasks_failed": metrics.tasks_failed,
            "tasks_pending": metrics.tasks_pending,
            "tasks_in_progress": metrics.tasks_in_progress,
            "system_uptime": metrics.system_uptime,
            "error_rate": metrics.error_rate,
            "throughput": metrics.throughput
        }
        
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=2)


class ProgressTracker:
    """
    Track project progress and milestones
    
    Features:
    - Task completion tracking
    - Milestone detection
    - Progress visualization
    - Trend analysis
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.progress_dir = self.project_root / "orkestra" / "logs" / "progress"
        self.progress_dir.mkdir(parents=True, exist_ok=True)
        
    def get_progress(self) -> Dict[str, any]:
        """
        Get current project progress
        
        Returns:
            Dict with progress metrics
        """
        queue = TaskQueue(self.project_root)
        stats = queue.get_statistics()
        
        total = stats['total']
        completed = stats['by_status'].get('completed', 0)
        
        progress = {
            'completion_percentage': stats['completion_rate'],
            'total_tasks': total,
            'completed_tasks': completed,
            'remaining_tasks': total - completed,
            'by_category': stats['by_category'],
            'by_priority': stats['by_priority'],
            'by_status': stats['by_status']
        }
        
        return progress
    
    def get_progress_report(self) -> str:
        """
        Generate formatted progress report
        
        Returns:
            Formatted progress report string
        """
        progress = self.get_progress()
        
        report = []
        report.append("=" * 70)
        report.append("PROJECT PROGRESS REPORT")
        report.append("=" * 70)
        report.append(f"Overall Completion: {progress['completion_percentage']:.1f}%")
        report.append(f"Completed: {progress['completed_tasks']}/{progress['total_tasks']} tasks")
        report.append("")
        
        # Progress bar
        bar_length = 50
        filled = int(bar_length * progress['completion_percentage'] / 100)
        bar = "█" * filled + "░" * (bar_length - filled)
        report.append(f"[{bar}] {progress['completion_percentage']:.1f}%")
        report.append("")
        
        # By status
        report.append("BY STATUS:")
        for status, count in progress['by_status'].items():
            report.append(f"  {status}: {count}")
        report.append("")
        
        # By priority
        report.append("BY PRIORITY:")
        for priority, count in progress['by_priority'].items():
            report.append(f"  {priority}: {count}")
        report.append("")
        
        # By category
        if progress['by_category']:
            report.append("BY CATEGORY:")
            for category, count in progress['by_category'].items():
                report.append(f"  {category}: {count}")
            report.append("")
        
        report.append("=" * 70)
        
        return "\n".join(report)
    
    def detect_milestones(self) -> List[str]:
        """
        Detect achieved milestones
        
        Returns:
            List of milestone messages
        """
        progress = self.get_progress()
        milestones = []
        
        completion = progress['completion_percentage']
        
        milestone_thresholds = [25, 50, 75, 90, 100]
        for threshold in milestone_thresholds:
            if completion >= threshold:
                milestones.append(f"✨ {threshold}% Complete!")
        
        return milestones


class ResilienceMonitor:
    """
    Monitor system resilience and recovery
    
    Tracks:
    - Failure recovery
    - Retry success rates
    - System stability
    - Degradation patterns
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.resilience_dir = self.project_root / "orkestra" / "logs" / "resilience"
        self.resilience_dir.mkdir(parents=True, exist_ok=True)
        
    def track_recovery(self, incident_type: str, recovered: bool, time_to_recovery: float):
        """
        Track a recovery incident
        
        Args:
            incident_type: Type of failure
            recovered: Whether recovery was successful
            time_to_recovery: Time taken to recover in seconds
        """
        incident = {
            'timestamp': datetime.now().isoformat(),
            'type': incident_type,
            'recovered': recovered,
            'time_to_recovery': time_to_recovery
        }
        
        # Append to log
        log_file = self.resilience_dir / "recovery_log.jsonl"
        with open(log_file, 'a') as f:
            f.write(json.dumps(incident) + '\n')
    
    def get_resilience_metrics(self) -> Dict[str, any]:
        """
        Get resilience metrics
        
        Returns:
            Dict with resilience statistics
        """
        log_file = self.resilience_dir / "recovery_log.jsonl"
        
        if not log_file.exists():
            return {
                'total_incidents': 0,
                'successful_recoveries': 0,
                'recovery_rate': 0.0,
                'average_recovery_time': 0.0
            }
        
        incidents = []
        with open(log_file) as f:
            for line in f:
                incidents.append(json.loads(line))
        
        total = len(incidents)
        successful = sum(1 for i in incidents if i['recovered'])
        recovery_times = [i['time_to_recovery'] for i in incidents if i['recovered']]
        
        return {
            'total_incidents': total,
            'successful_recoveries': successful,
            'recovery_rate': (successful / total * 100) if total > 0 else 0.0,
            'average_recovery_time': sum(recovery_times) / len(recovery_times) if recovery_times else 0.0
        }
