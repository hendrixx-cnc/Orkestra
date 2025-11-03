"""
Orkestra - Multi-AI Task Coordination Platform

A powerful framework for orchestrating multiple AI agents (Claude, ChatGPT, 
Gemini, Copilot, and Grok) to work together on complex tasks with democratic 
decision-making, safety validation, and self-healing capabilities.
"""

__version__ = "1.0.0"
__author__ = "hendrixx-cnc"
__license__ = "Apache-2.0"

# Legacy exports
try:
    from .core import OrkestraProject
    from .config import OrkestraConfig
except ImportError:
    OrkestraProject = None
    OrkestraConfig = None

# Core modules
from .committee import Committee, Vote, VoteType
from .tasks import TaskQueue, Task, TaskStatus
from .planning import ProjectPlanner

# Context and recovery
from .context import ContextManager, ProjectContext, AgentUnderstanding

# Democracy and consensus
from .democracy import DemocracyEngine, VoteType, ConsensusLevel, DemocraticVote

# Monitoring and health
from .monitoring import HealthMonitor, ProgressTracker, HealthStatus

# Safety and validation
from .safety import PreTaskValidator, PostTaskValidator, ValidationLevel

# Utilities
from .utils import FileOperations, GitHelpers, JSONTools

# AI Agents
from .agents import (
    Agent,
    ClaudeAgent,
    ChatGPTAgent,
    GeminiAgent,
    CopilotAgent,
    GrokAgent,
    AgentManager,
    AgentConfig,
    AgentResponse
)

# Automation
from .automation import (
    TaskCoordinator,
    LockManager,
    SmartTaskSelector,
    RecoverySystem,
    DaemonManager,
    AuditLogger
)

# Main orchestrator
from .orchestrator import Orchestrator, SystemStartup, SystemConfig

__all__ = [
    # Legacy
    'OrkestraProject',
    'OrkestraConfig',
    
    # Core
    'Committee',
    'Vote',
    'VoteType',
    'TaskQueue',
    'Task',
    'TaskStatus',
    'ProjectPlanner',
    
    # Context
    'ContextManager',
    'ProjectContext',
    'AgentUnderstanding',
    
    # Democracy
    'DemocracyEngine',
    'VoteType',
    'ConsensusLevel',
    'DemocraticVote',
    
    # Monitoring
    'HealthMonitor',
    'ProgressTracker',
    'HealthStatus',
    
    # Safety
    'PreTaskValidator',
    'PostTaskValidator',
    'ValidationLevel',
    
    # Utils
    'FileOperations',
    'GitHelpers',
    'JSONTools',
    
    # Agents
    'Agent',
    'ClaudeAgent',
    'ChatGPTAgent',
    'GeminiAgent',
    'CopilotAgent',
    'GrokAgent',
    'AgentManager',
    'AgentConfig',
    'AgentResponse',
    
    # Automation
    'TaskCoordinator',
    'LockManager',
    'SmartTaskSelector',
    'RecoverySystem',
    'DaemonManager',
    'AuditLogger',
    
    # Orchestrator
    'Orchestrator',
    'SystemStartup',
    'SystemConfig',
    
    # Version
    '__version__',
]
