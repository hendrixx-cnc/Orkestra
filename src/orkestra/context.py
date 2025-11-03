"""
Context Management System for Orkestra
======================================

Maintains comprehensive project history and state for AI agents to recover from
disconnects, rate limits, or context switches. Each agent can update their
understanding and actions, creating a complete audit trail.

Features:
- Persistent project context across sessions
- Agent-specific understanding tracking
- Action history with timestamps
- Decision rationale recording
- Rate limit/disconnect recovery
- Context compression for long-running projects
"""

import json
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, List, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum
import subprocess


class ContextEventType(Enum):
    """Types of context events"""
    PROJECT_START = "project_start"
    PLANNING_PHASE = "planning_phase"
    TASK_STARTED = "task_started"
    TASK_COMPLETED = "task_completed"
    DECISION_MADE = "decision_made"
    AGENT_ACTION = "agent_action"
    VOTE_CREATED = "vote_created"
    VOTE_COMPLETED = "vote_completed"
    ERROR_OCCURRED = "error_occurred"
    MILESTONE_REACHED = "milestone_reached"
    CONTEXT_REFRESH = "context_refresh"
    RATE_LIMIT_HIT = "rate_limit_hit"
    DISCONNECT = "disconnect"
    RECONNECT = "reconnect"


class AgentRole(Enum):
    """Agent roles in the democracy"""
    CLAUDE = "claude"           # Architecture, Design, UX
    CHATGPT = "chatgpt"         # Content, Writing, Marketing
    GEMINI = "gemini"           # Cloud, Database, Firebase
    GROK = "grok"               # Innovation, Research, Analysis
    COPILOT = "copilot"         # Deployment, Code, DevOps


@dataclass
class AgentUnderstanding:
    """Represents an agent's understanding of the project state"""
    agent_name: str
    role: str
    last_updated: str
    current_understanding: str
    active_tasks: List[str]
    completed_tasks: List[str]
    pending_decisions: List[str]
    concerns: List[str]
    suggestions: List[str]
    confidence_level: float  # 0.0 to 1.0
    context_version: int


@dataclass
class ContextEvent:
    """A single event in the project history"""
    event_id: str
    timestamp: str
    event_type: ContextEventType
    agent_name: Optional[str]
    description: str
    details: Dict[str, Any]
    related_tasks: List[str]
    related_votes: List[str]
    impact_level: str  # "low", "medium", "high", "critical"


@dataclass
class ProjectContext:
    """Complete project context state"""
    project_name: str
    project_root: str
    context_version: int
    created_at: str
    last_updated: str
    
    # High-level state
    project_phase: str  # "planning", "development", "testing", "deployment", "maintenance"
    current_milestone: str
    completion_percentage: float
    
    # Agent understandings
    agent_states: Dict[str, AgentUnderstanding]
    
    # History
    events: List[ContextEvent]
    
    # Current state
    active_tasks: List[str]
    completed_tasks: List[str]
    blocked_tasks: List[str]
    
    # Decisions
    active_votes: List[str]
    completed_votes: List[str]
    key_decisions: List[Dict[str, Any]]
    
    # Recovery info
    last_checkpoint: str
    recovery_points: List[Dict[str, Any]]
    
    # Metadata
    metadata: Dict[str, Any] = field(default_factory=dict)


class ContextManager:
    """Manages project context and agent understanding"""
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.context_dir = self.project_root / "orkestra" / "context"
        self.context_file = self.context_dir / "project-context.json"
        self.events_dir = self.context_dir / "events"
        self.checkpoints_dir = self.context_dir / "checkpoints"
        self.agent_logs_dir = self.context_dir / "agent-logs"
        
        # Create directories
        self.context_dir.mkdir(parents=True, exist_ok=True)
        self.events_dir.mkdir(exist_ok=True)
        self.checkpoints_dir.mkdir(exist_ok=True)
        self.agent_logs_dir.mkdir(exist_ok=True)
        
        # Load or initialize context
        self.context = self._load_or_create_context()
    
    def _load_or_create_context(self) -> ProjectContext:
        """Load existing context or create new one"""
        if self.context_file.exists():
            with open(self.context_file, 'r') as f:
                data = json.load(f)
                return self._dict_to_context(data)
        else:
            # Create new context
            context = ProjectContext(
                project_name=self.project_root.name,
                project_root=str(self.project_root),
                context_version=1,
                created_at=self._timestamp(),
                last_updated=self._timestamp(),
                project_phase="planning",
                current_milestone="Project Initialization",
                completion_percentage=0.0,
                agent_states={},
                events=[],
                active_tasks=[],
                completed_tasks=[],
                blocked_tasks=[],
                active_votes=[],
                completed_votes=[],
                key_decisions=[],
                last_checkpoint=self._timestamp(),
                recovery_points=[]
            )
            self._save_context(context)
            return context
    
    def _dict_to_context(self, data: Dict) -> ProjectContext:
        """Convert dict to ProjectContext"""
        # Convert agent states
        agent_states = {}
        for name, state_dict in data.get('agent_states', {}).items():
            agent_states[name] = AgentUnderstanding(**state_dict)
        
        # Convert events
        events = []
        for event_dict in data.get('events', []):
            event_dict['event_type'] = ContextEventType(event_dict['event_type'])
            events.append(ContextEvent(**event_dict))
        
        data['agent_states'] = agent_states
        data['events'] = events
        
        return ProjectContext(**data)
    
    def _context_to_dict(self, context: ProjectContext) -> Dict:
        """Convert ProjectContext to dict"""
        data = asdict(context)
        
        # Convert enums to strings
        for event in data['events']:
            event['event_type'] = event['event_type'].value
        
        return data
    
    def _save_context(self, context: Optional[ProjectContext] = None):
        """Save context to disk"""
        if context is None:
            context = self.context
        
        context.last_updated = self._timestamp()
        context.context_version += 1
        
        data = self._context_to_dict(context)
        
        # Write atomically
        temp_file = self.context_file.with_suffix('.tmp')
        with open(temp_file, 'w') as f:
            json.dump(data, f, indent=2)
        temp_file.replace(self.context_file)
        
        self.context = context
    
    def _timestamp(self) -> str:
        """Generate ISO timestamp"""
        return datetime.now(timezone.utc).isoformat()
    
    def _generate_event_id(self) -> str:
        """Generate unique event ID"""
        data = f"{self._timestamp()}{self.context.context_version}"
        return f"event_{hashlib.md5(data.encode()).hexdigest()[:12]}"
    
    # ═══════════════════════════════════════════════════════════════════════
    # AGENT UNDERSTANDING MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════
    
    def update_agent_understanding(
        self,
        agent_name: str,
        understanding: str,
        active_tasks: Optional[List[str]] = None,
        completed_tasks: Optional[List[str]] = None,
        concerns: Optional[List[str]] = None,
        suggestions: Optional[List[str]] = None,
        confidence_level: float = 0.8
    ):
        """
        Update an agent's understanding of the project state.
        
        This is the primary method for agents to record their current
        understanding, which helps with recovery after disconnects.
        """
        # Get or create agent state
        if agent_name not in self.context.agent_states:
            agent_state = AgentUnderstanding(
                agent_name=agent_name,
                role=self._get_agent_role(agent_name),
                last_updated=self._timestamp(),
                current_understanding=understanding,
                active_tasks=active_tasks or [],
                completed_tasks=completed_tasks or [],
                pending_decisions=[],
                concerns=concerns or [],
                suggestions=suggestions or [],
                confidence_level=confidence_level,
                context_version=self.context.context_version
            )
        else:
            agent_state = self.context.agent_states[agent_name]
            agent_state.current_understanding = understanding
            agent_state.last_updated = self._timestamp()
            if active_tasks is not None:
                agent_state.active_tasks = active_tasks
            if completed_tasks is not None:
                agent_state.completed_tasks = completed_tasks
            if concerns is not None:
                agent_state.concerns = concerns
            if suggestions is not None:
                agent_state.suggestions = suggestions
            agent_state.confidence_level = confidence_level
            agent_state.context_version = self.context.context_version
        
        self.context.agent_states[agent_name] = agent_state
        
        # Log event
        self.log_event(
            event_type=ContextEventType.AGENT_ACTION,
            agent_name=agent_name,
            description=f"{agent_name} updated understanding",
            details={
                "understanding": understanding[:200],  # Truncate for overview
                "confidence": confidence_level,
                "active_tasks_count": len(agent_state.active_tasks),
                "concerns_count": len(agent_state.concerns)
            }
        )
        
        # Save agent's detailed log
        self._save_agent_log(agent_name, agent_state)
        
        self._save_context()
    
    def _get_agent_role(self, agent_name: str) -> str:
        """Get agent role from name"""
        role_map = {
            "claude": "Architecture, Design, UX",
            "chatgpt": "Content, Writing, Marketing",
            "gemini": "Cloud, Database, Firebase",
            "grok": "Innovation, Research, Analysis",
            "copilot": "Deployment, Code, DevOps"
        }
        return role_map.get(agent_name.lower(), "General Support")
    
    def _save_agent_log(self, agent_name: str, agent_state: AgentUnderstanding):
        """Save detailed agent log"""
        log_file = self.agent_logs_dir / f"{agent_name}-log.json"
        
        # Load existing log or create new
        if log_file.exists():
            with open(log_file, 'r') as f:
                log_data = json.load(f)
        else:
            log_data = {
                "agent_name": agent_name,
                "entries": []
            }
        
        # Add new entry
        log_data['entries'].append({
            "timestamp": agent_state.last_updated,
            "understanding": agent_state.current_understanding,
            "active_tasks": agent_state.active_tasks,
            "completed_tasks": agent_state.completed_tasks,
            "concerns": agent_state.concerns,
            "suggestions": agent_state.suggestions,
            "confidence": agent_state.confidence_level,
            "context_version": agent_state.context_version
        })
        
        # Keep last 100 entries
        log_data['entries'] = log_data['entries'][-100:]
        
        with open(log_file, 'w') as f:
            json.dump(log_data, f, indent=2)
    
    def get_agent_understanding(self, agent_name: str) -> Optional[AgentUnderstanding]:
        """Get an agent's current understanding"""
        return self.context.agent_states.get(agent_name)
    
    def get_all_agent_understandings(self) -> Dict[str, AgentUnderstanding]:
        """Get all agents' understandings"""
        return self.context.agent_states
    
    # ═══════════════════════════════════════════════════════════════════════
    # EVENT LOGGING
    # ═══════════════════════════════════════════════════════════════════════
    
    def log_event(
        self,
        event_type: ContextEventType,
        description: str,
        agent_name: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        related_tasks: Optional[List[str]] = None,
        related_votes: Optional[List[str]] = None,
        impact_level: str = "medium"
    ):
        """Log an event in the project history"""
        event = ContextEvent(
            event_id=self._generate_event_id(),
            timestamp=self._timestamp(),
            event_type=event_type,
            agent_name=agent_name,
            description=description,
            details=details or {},
            related_tasks=related_tasks or [],
            related_votes=related_votes or [],
            impact_level=impact_level
        )
        
        self.context.events.append(event)
        
        # Save event to separate file for easier access
        event_file = self.events_dir / f"{event.event_id}.json"
        with open(event_file, 'w') as f:
            event_dict = asdict(event)
            event_dict['event_type'] = event.event_type.value
            json.dump(event_dict, f, indent=2)
        
        # Keep only last 1000 events in memory
        if len(self.context.events) > 1000:
            self.context.events = self.context.events[-1000:]
        
        self._save_context()
    
    def get_recent_events(self, limit: int = 50) -> List[ContextEvent]:
        """Get recent events"""
        return self.context.events[-limit:]
    
    def get_events_by_agent(self, agent_name: str, limit: int = 50) -> List[ContextEvent]:
        """Get events for specific agent"""
        agent_events = [e for e in self.context.events if e.agent_name == agent_name]
        return agent_events[-limit:]
    
    def get_events_by_type(self, event_type: ContextEventType, limit: int = 50) -> List[ContextEvent]:
        """Get events of specific type"""
        type_events = [e for e in self.context.events if e.event_type == event_type]
        return type_events[-limit:]
    
    # ═══════════════════════════════════════════════════════════════════════
    # RECOVERY & CHECKPOINTS
    # ═══════════════════════════════════════════════════════════════════════
    
    def create_checkpoint(self, reason: str = "Manual checkpoint"):
        """Create a recovery checkpoint"""
        checkpoint_id = f"checkpoint_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        checkpoint_file = self.checkpoints_dir / f"{checkpoint_id}.json"
        
        # Save full context
        checkpoint_data = {
            "checkpoint_id": checkpoint_id,
            "timestamp": self._timestamp(),
            "reason": reason,
            "context": self._context_to_dict(self.context)
        }
        
        with open(checkpoint_file, 'w') as f:
            json.dump(checkpoint_data, f, indent=2)
        
        # Add to recovery points
        self.context.recovery_points.append({
            "checkpoint_id": checkpoint_id,
            "timestamp": checkpoint_data['timestamp'],
            "reason": reason,
            "context_version": self.context.context_version
        })
        
        # Keep last 20 recovery points
        self.context.recovery_points = self.context.recovery_points[-20:]
        
        self.context.last_checkpoint = checkpoint_data['timestamp']
        self._save_context()
        
        return checkpoint_id
    
    def load_checkpoint(self, checkpoint_id: str) -> bool:
        """Load a checkpoint to recover state"""
        checkpoint_file = self.checkpoints_dir / f"{checkpoint_id}.json"
        
        if not checkpoint_file.exists():
            return False
        
        with open(checkpoint_file, 'r') as f:
            checkpoint_data = json.load(f)
        
        # Restore context
        self.context = self._dict_to_context(checkpoint_data['context'])
        self._save_context()
        
        # Log recovery
        self.log_event(
            event_type=ContextEventType.RECONNECT,
            description=f"Recovered from checkpoint: {checkpoint_id}",
            details={"checkpoint_reason": checkpoint_data['reason']},
            impact_level="high"
        )
        
        return True
    
    def handle_disconnect(self, agent_name: str, reason: str = "Connection lost"):
        """Handle agent disconnect"""
        self.log_event(
            event_type=ContextEventType.DISCONNECT,
            agent_name=agent_name,
            description=f"{agent_name} disconnected: {reason}",
            impact_level="medium"
        )
        
        # Create automatic checkpoint
        self.create_checkpoint(f"Auto-checkpoint before {agent_name} disconnect")
    
    def handle_reconnect(self, agent_name: str) -> str:
        """Handle agent reconnect and return recovery summary"""
        self.log_event(
            event_type=ContextEventType.RECONNECT,
            agent_name=agent_name,
            description=f"{agent_name} reconnected",
            impact_level="low"
        )
        
        # Generate recovery summary
        return self.get_recovery_summary(agent_name)
    
    def handle_rate_limit(self, agent_name: str, retry_after: Optional[int] = None):
        """Handle rate limit hit"""
        self.log_event(
            event_type=ContextEventType.RATE_LIMIT_HIT,
            agent_name=agent_name,
            description=f"{agent_name} hit rate limit",
            details={"retry_after": retry_after},
            impact_level="low"
        )
        
        # Create checkpoint
        self.create_checkpoint(f"Rate limit checkpoint for {agent_name}")
    
    def get_recovery_summary(self, agent_name: Optional[str] = None) -> str:
        """
        Generate recovery summary for agent to get back up to speed.
        
        This is what agents read after disconnect/rate limit to understand
        exactly where they left off.
        """
        lines = []
        lines.append("=" * 80)
        lines.append("ORKESTRA CONTEXT RECOVERY SUMMARY")
        lines.append("=" * 80)
        lines.append(f"Generated: {self._timestamp()}")
        lines.append(f"Project: {self.context.project_name}")
        lines.append(f"Context Version: {self.context.context_version}")
        lines.append("")
        
        # Project state
        lines.append("PROJECT STATE:")
        lines.append(f"  Phase: {self.context.project_phase}")
        lines.append(f"  Milestone: {self.context.current_milestone}")
        lines.append(f"  Completion: {self.context.completion_percentage:.1f}%")
        lines.append(f"  Active Tasks: {len(self.context.active_tasks)}")
        lines.append(f"  Completed Tasks: {len(self.context.completed_tasks)}")
        lines.append(f"  Active Votes: {len(self.context.active_votes)}")
        lines.append("")
        
        # Recent events
        lines.append("RECENT EVENTS (last 10):")
        for event in self.context.events[-10:]:
            lines.append(f"  [{event.timestamp}] {event.event_type.value}")
            lines.append(f"    {event.description}")
            if event.agent_name:
                lines.append(f"    Agent: {event.agent_name}")
        lines.append("")
        
        # Agent-specific info
        if agent_name:
            agent_state = self.get_agent_understanding(agent_name)
            if agent_state:
                lines.append(f"YOUR LAST STATE ({agent_name}):")
                lines.append(f"  Last Update: {agent_state.last_updated}")
                lines.append(f"  Confidence: {agent_state.confidence_level:.1%}")
                lines.append(f"  Active Tasks: {len(agent_state.active_tasks)}")
                lines.append(f"  Understanding:")
                lines.append(f"    {agent_state.current_understanding}")
                if agent_state.concerns:
                    lines.append(f"  Concerns: {', '.join(agent_state.concerns)}")
                if agent_state.suggestions:
                    lines.append(f"  Suggestions: {', '.join(agent_state.suggestions)}")
                lines.append("")
        
        # All agents' status
        lines.append("ALL AGENTS STATUS:")
        for name, state in self.context.agent_states.items():
            lines.append(f"  {name}:")
            lines.append(f"    Last Active: {state.last_updated}")
            lines.append(f"    Confidence: {state.confidence_level:.1%}")
            lines.append(f"    Tasks: {len(state.active_tasks)} active, {len(state.completed_tasks)} done")
        lines.append("")
        
        # Active work
        if self.context.active_tasks:
            lines.append("ACTIVE TASKS:")
            for task_id in self.context.active_tasks[:10]:
                lines.append(f"  - {task_id}")
            lines.append("")
        
        # Pending votes
        if self.context.active_votes:
            lines.append("PENDING VOTES:")
            for vote_id in self.context.active_votes:
                lines.append(f"  - {vote_id}")
            lines.append("")
        
        # Key decisions
        if self.context.key_decisions:
            lines.append("RECENT KEY DECISIONS:")
            for decision in self.context.key_decisions[-5:]:
                lines.append(f"  - {decision.get('title', 'Untitled')}")
                lines.append(f"    Decision: {decision.get('decision', 'N/A')}")
                lines.append(f"    Timestamp: {decision.get('timestamp', 'N/A')}")
            lines.append("")
        
        lines.append("=" * 80)
        lines.append("END RECOVERY SUMMARY")
        lines.append("=" * 80)
        
        return "\n".join(lines)
    
    # ═══════════════════════════════════════════════════════════════════════
    # PROJECT STATE MANAGEMENT
    # ═══════════════════════════════════════════════════════════════════════
    
    def update_project_phase(self, phase: str):
        """Update project phase"""
        old_phase = self.context.project_phase
        self.context.project_phase = phase
        
        self.log_event(
            event_type=ContextEventType.MILESTONE_REACHED,
            description=f"Project phase changed: {old_phase} → {phase}",
            impact_level="high"
        )
        
        self._save_context()
    
    def update_milestone(self, milestone: str):
        """Update current milestone"""
        self.context.current_milestone = milestone
        
        self.log_event(
            event_type=ContextEventType.MILESTONE_REACHED,
            description=f"Milestone: {milestone}",
            impact_level="high"
        )
        
        self._save_context()
    
    def update_completion(self, percentage: float):
        """Update completion percentage"""
        self.context.completion_percentage = percentage
        self._save_context()
    
    def record_decision(self, title: str, decision: str, reasoning: str, 
                       vote_id: Optional[str] = None, agents_involved: Optional[List[str]] = None):
        """Record a key decision"""
        decision_record = {
            "title": title,
            "decision": decision,
            "reasoning": reasoning,
            "vote_id": vote_id,
            "agents_involved": agents_involved or [],
            "timestamp": self._timestamp()
        }
        
        self.context.key_decisions.append(decision_record)
        
        self.log_event(
            event_type=ContextEventType.DECISION_MADE,
            description=f"Decision: {title}",
            details=decision_record,
            related_votes=[vote_id] if vote_id else [],
            impact_level="high"
        )
        
        self._save_context()
    
    # ═══════════════════════════════════════════════════════════════════════
    # TASK TRACKING
    # ═══════════════════════════════════════════════════════════════════════
    
    def task_started(self, task_id: str, agent_name: str):
        """Record task start"""
        if task_id not in self.context.active_tasks:
            self.context.active_tasks.append(task_id)
        
        self.log_event(
            event_type=ContextEventType.TASK_STARTED,
            agent_name=agent_name,
            description=f"Task started: {task_id}",
            related_tasks=[task_id],
            impact_level="low"
        )
        
        self._save_context()
    
    def task_completed(self, task_id: str, agent_name: str):
        """Record task completion"""
        if task_id in self.context.active_tasks:
            self.context.active_tasks.remove(task_id)
        
        if task_id not in self.context.completed_tasks:
            self.context.completed_tasks.append(task_id)
        
        self.log_event(
            event_type=ContextEventType.TASK_COMPLETED,
            agent_name=agent_name,
            description=f"Task completed: {task_id}",
            related_tasks=[task_id],
            impact_level="medium"
        )
        
        # Update completion percentage
        total_tasks = len(self.context.active_tasks) + len(self.context.completed_tasks)
        if total_tasks > 0:
            self.context.completion_percentage = (
                len(self.context.completed_tasks) / total_tasks * 100
            )
        
        self._save_context()
    
    def task_blocked(self, task_id: str, reason: str):
        """Record task blocking"""
        if task_id not in self.context.blocked_tasks:
            self.context.blocked_tasks.append(task_id)
        
        if task_id in self.context.active_tasks:
            self.context.active_tasks.remove(task_id)
        
        self.log_event(
            event_type=ContextEventType.ERROR_OCCURRED,
            description=f"Task blocked: {task_id} - {reason}",
            related_tasks=[task_id],
            details={"reason": reason},
            impact_level="medium"
        )
        
        self._save_context()
    
    # ═══════════════════════════════════════════════════════════════════════
    # UTILITY METHODS
    # ═══════════════════════════════════════════════════════════════════════
    
    def get_context_summary(self) -> Dict[str, Any]:
        """Get brief context summary"""
        return {
            "project_name": self.context.project_name,
            "phase": self.context.project_phase,
            "milestone": self.context.current_milestone,
            "completion": self.context.completion_percentage,
            "context_version": self.context.context_version,
            "last_updated": self.context.last_updated,
            "active_agents": len(self.context.agent_states),
            "active_tasks": len(self.context.active_tasks),
            "completed_tasks": len(self.context.completed_tasks),
            "total_events": len(self.context.events)
        }
    
    def export_context(self, output_file: Path):
        """Export full context to file"""
        data = self._context_to_dict(self.context)
        with open(output_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def compress_old_events(self, days: int = 7):
        """Compress events older than N days"""
        cutoff = datetime.now(timezone.utc).timestamp() - (days * 86400)
        
        recent_events = []
        compressed_summary = {
            "compressed_at": self._timestamp(),
            "events_compressed": 0,
            "summary": {}
        }
        
        for event in self.context.events:
            event_time = datetime.fromisoformat(event.timestamp.replace('Z', '+00:00'))
            if event_time.timestamp() > cutoff:
                recent_events.append(event)
            else:
                compressed_summary['events_compressed'] += 1
        
        # Save compressed archive
        archive_file = self.context_dir / f"archived_events_{datetime.now().strftime('%Y%m%d')}.json"
        with open(archive_file, 'w') as f:
            json.dump(compressed_summary, f, indent=2)
        
        self.context.events = recent_events
        self._save_context()
