"""
Orkestra Main Orchestrator

Core system coordination and startup logic.
Replaces bash scripts from SCRIPTS/CORE/.
"""

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import asyncio
import logging
import sys
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.progress import Progress


@dataclass
class SystemConfig:
    """System configuration"""
    project_root: Path
    auto_assign: bool = True
    auto_recovery: bool = True
    enable_democracy: bool = True
    consensus_method: str = "majority"
    health_check_interval: int = 300  # 5 minutes
    recovery_check_interval: int = 600  # 10 minutes
    max_concurrent_tasks: int = 5


class Orchestrator:
    """
    Main system orchestrator
    
    Coordinates all subsystems:
    - Agents
    - Tasks
    - Democracy/Voting
    - Monitoring
    - Safety validation
    - Context tracking
    """
    
    def __init__(self, config: SystemConfig):
        self.config = config
        self.logger = logging.getLogger("orkestra.orchestrator")
        self.console = Console()
        self.running = False
        
        # Initialize subsystems
        self._init_subsystems()
    
    def _init_subsystems(self):
        """Initialize all subsystems"""
        try:
            from . import agents, tasks, committee, context, democracy
            from . import monitoring, safety, automation
            
            self.logger.info("Initializing subsystems...")
            
            # Core systems
            self.agent_manager = agents.AgentManager(self.config.project_root)
            self.task_queue = tasks.TaskQueue(self.config.project_root)
            self.committee = committee.Committee(self.config.project_root)
            
            # Advanced systems
            self.context_manager = context.ContextManager(self.config.project_root)
            self.democracy_engine = democracy.DemocracyEngine(self.config.project_root)
            
            # Monitoring and safety
            self.health_monitor = monitoring.HealthMonitor(self.config.project_root)
            self.pre_validator = safety.PreTaskValidator(self.config.project_root)
            self.post_validator = safety.PostTaskValidator(self.config.project_root)
            
            # Automation
            self.coordinator = automation.TaskCoordinator(self.config.project_root)
            self.task_selector = automation.SmartTaskSelector(self.config.project_root)
            self.recovery_system = automation.RecoverySystem(self.config.project_root)
            self.audit_logger = automation.AuditLogger(self.config.project_root)
            
            self.logger.info("✅ All subsystems initialized")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize subsystems: {e}")
            raise
    
    async def start(self):
        """Start the orchestrator"""
        self.running = True
        
        self.console.print(Panel.fit(
            "[bold cyan]🎭 Orkestra Multi-AI Orchestration System[/bold cyan]\n"
            f"[yellow]Project:[/yellow] {self.config.project_root}\n"
            f"[yellow]Agents:[/yellow] {len(self.agent_manager.get_available_agents())}\n"
            f"[yellow]Democracy:[/yellow] {'Enabled' if self.config.enable_democracy else 'Disabled'}",
            title="Starting System",
            border_style="cyan"
        ))
        
        # Create initial context
        self.context_manager.create_context()
        
        # Test agent connections
        await self._test_connections()
        
        # Clean stale locks
        self.coordinator.lock_manager.clean_stale_locks()
        
        # Start background tasks
        tasks = [
            asyncio.create_task(self._task_assignment_loop()),
            asyncio.create_task(self._health_check_loop()),
            asyncio.create_task(self._recovery_loop())
        ]
        
        try:
            await asyncio.gather(*tasks)
        except asyncio.CancelledError:
            self.logger.info("Orchestrator stopped")
        except Exception as e:
            self.logger.error(f"Orchestrator error: {e}")
        finally:
            self.running = False
    
    async def stop(self):
        """Stop the orchestrator"""
        self.logger.info("Stopping orchestrator...")
        self.running = False
        
        # Save final context snapshot
        self.context_manager.snapshot()
    
    async def _test_connections(self):
        """Test all agent connections"""
        self.console.print("\n[yellow]Testing agent connections...[/yellow]")
        
        with Progress() as progress:
            task = progress.add_task(
                "[cyan]Testing...",
                total=len(self.agent_manager.agents)
            )
            
            for agent_name in self.agent_manager.agents:
                agent = self.agent_manager.agents[agent_name]
                status = "✅" if agent.test_connection() else "❌"
                self.console.print(f"  {status} {agent_name}")
                progress.advance(task)
    
    async def _task_assignment_loop(self):
        """Background task assignment loop"""
        while self.running:
            try:
                # Get ready tasks
                ready_tasks = self.coordinator.get_ready_tasks()
                
                if ready_tasks:
                    self.logger.info(f"Found {len(ready_tasks)} ready tasks")
                    
                    for task in ready_tasks[:self.config.max_concurrent_tasks]:
                        await self._assign_and_execute_task(task.id)
                
                await asyncio.sleep(30)  # Check every 30 seconds
                
            except Exception as e:
                self.logger.error(f"Task assignment loop error: {e}")
                await asyncio.sleep(60)
    
    async def _health_check_loop(self):
        """Background health monitoring loop"""
        while self.running:
            try:
                # Check system health
                health_report = self.health_monitor.get_health_report()
                
                if health_report['overall_status'] in ['DEGRADED', 'CRITICAL']:
                    self.logger.warning(
                        f"System health: {health_report['overall_status']}"
                    )
                
                await asyncio.sleep(self.config.health_check_interval)
                
            except Exception as e:
                self.logger.error(f"Health check loop error: {e}")
                await asyncio.sleep(300)
    
    async def _recovery_loop(self):
        """Background recovery loop"""
        while self.running:
            try:
                # Recover stuck tasks
                recovered = self.recovery_system.recover_stuck_tasks(self.coordinator)
                
                if recovered > 0:
                    self.logger.info(f"Recovered {recovered} stuck tasks")
                
                await asyncio.sleep(self.config.recovery_check_interval)
                
            except Exception as e:
                self.logger.error(f"Recovery loop error: {e}")
                await asyncio.sleep(600)
    
    async def _assign_and_execute_task(self, task_id: int):
        """
        Assign and execute a task
        
        Args:
            task_id: Task ID
        """
        try:
            # Pre-task validation
            validation = self.pre_validator.validate_all(task_id)
            if not validation['passed']:
                self.logger.error(f"Pre-task validation failed for Task #{task_id}")
                return
            
            # Select best agent
            agent_name = self.task_selector.select_best_agent(
                task_id,
                self.coordinator
            )
            
            # Assign task
            if not self.coordinator.assign_task(task_id, agent_name):
                self.logger.error(f"Failed to assign Task #{task_id}")
                return
            
            # Log audit event
            self.audit_logger.log_event(
                event_type="task_assigned",
                task_id=task_id,
                agent_name=agent_name,
                details={'validation': validation}
            )
            
            # Execute task
            await self._execute_task(task_id, agent_name)
            
            # Post-task validation
            post_validation = self.post_validator.validate_all(task_id)
            
            if post_validation['passed']:
                self.coordinator.complete_task(task_id)
                
                self.audit_logger.log_event(
                    event_type="task_completed",
                    task_id=task_id,
                    agent_name=agent_name,
                    details={'validation': post_validation}
                )
            else:
                self.logger.error(f"Post-task validation failed for Task #{task_id}")
                self.recovery_system.recover_failed_task(task_id, self.coordinator)
            
        except Exception as e:
            self.logger.error(f"Error executing Task #{task_id}: {e}")
            self.recovery_system.recover_failed_task(task_id, self.coordinator)
    
    async def _execute_task(self, task_id: int, agent_name: str):
        """
        Execute a task with an agent
        
        Args:
            task_id: Task ID
            agent_name: Agent name
        """
        task = self.task_queue.get_task(task_id)
        if not task:
            return
        
        # Get context
        context = self.context_manager.get_summary()
        
        # Build prompt
        prompt = f"""
Task #{task_id}: {task.title}

Instructions:
{task.instructions}

Context:
{context}

Please complete this task and provide the result.
"""
        
        # Call agent
        response = await self.agent_manager.call_agent(
            agent_name=agent_name,
            prompt=prompt,
            context=context
        )
        
        if response.success:
            # Update context
            self.context_manager.update_agent_context(
                agent_name=agent_name,
                current_task=f"Task #{task_id}",
                last_action=f"Completed: {task.title}",
                understanding=response.content[:500]  # Truncate
            )
            
            # Record task completion
            self.context_manager.record_task(
                task_id=task_id,
                agent_name=agent_name,
                result=response.content
            )
            
            # Update task with result
            self.task_queue.update_task(
                task_id,
                result=response.content,
                status="completed"
            )
            
            self.logger.info(
                f"✅ Task #{task_id} completed by {agent_name} "
                f"({response.tokens_used} tokens, {response.duration:.2f}s)"
            )
        else:
            self.logger.error(
                f"❌ Task #{task_id} failed: {response.error}"
            )
            self.task_queue.update_task(
                task_id,
                status="failed",
                result=f"Error: {response.error}"
            )
    
    def get_status(self) -> Dict[str, Any]:
        """
        Get system status
        
        Returns:
            Dict with system status
        """
        return {
            'running': self.running,
            'agents': self.agent_manager.get_agent_stats(),
            'tasks': {
                'total': len(self.task_queue.list_tasks()),
                'pending': len([t for t in self.task_queue.list_tasks() if t.status == 'pending']),
                'in_progress': len([t for t in self.task_queue.list_tasks() if t.status == 'in_progress']),
                'completed': len([t for t in self.task_queue.list_tasks() if t.status == 'completed'])
            },
            'health': self.health_monitor.get_health_report(),
            'locks': len(self.coordinator.lock_manager.get_all_locks())
        }
    
    def print_status(self):
        """Print system status to console"""
        status = self.get_status()
        
        # Create status table
        table = Table(title="Orkestra System Status", show_header=True)
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="yellow")
        
        # System status
        table.add_row("Running", "✅ Yes" if status['running'] else "❌ No")
        table.add_row("Active Agents", str(len(status['agents'])))
        
        # Task statistics
        tasks = status['tasks']
        table.add_row("Total Tasks", str(tasks['total']))
        table.add_row("Pending", str(tasks['pending']))
        table.add_row("In Progress", str(tasks['in_progress']))
        table.add_row("Completed", str(tasks['completed']))
        
        # Health
        health = status['health']
        table.add_row("System Health", health['overall_status'])
        
        # Locks
        table.add_row("Active Locks", str(status['locks']))
        
        self.console.print(table)
        
        # Agent details
        if status['agents']:
            agent_table = Table(title="Agent Statistics", show_header=True)
            agent_table.add_column("Agent", style="cyan")
            agent_table.add_column("Calls", style="yellow")
            agent_table.add_column("Last Call", style="green")
            
            for agent_name, stats in status['agents'].items():
                agent_table.add_row(
                    agent_name,
                    str(stats['call_count']),
                    stats['last_call'] or "Never"
                )
            
            self.console.print(agent_table)


class SystemStartup:
    """
    System startup and initialization
    
    Handles initial setup and configuration.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.console = Console()
        self.logger = logging.getLogger("orkestra.startup")
    
    def ensure_directories(self):
        """Create necessary directories"""
        dirs = [
            "orkestra",
            "orkestra/logs",
            "orkestra/logs/audit",
            "orkestra/logs/notifications",
            "orkestra/locks",
            "orkestra/daemons",
            "orkestra/backups"
        ]
        
        for dir_name in dirs:
            dir_path = self.project_root / dir_name
            dir_path.mkdir(parents=True, exist_ok=True)
            self.logger.debug(f"Ensured directory: {dir_path}")
    
    def load_config(self) -> SystemConfig:
        """
        Load system configuration
        
        Returns:
            SystemConfig instance
        """
        config_file = self.project_root / "orkestra" / "config.json"
        
        if config_file.exists():
            import json
            with open(config_file) as f:
                config_data = json.load(f)
            
            return SystemConfig(
                project_root=self.project_root,
                **config_data
            )
        else:
            # Default configuration
            return SystemConfig(project_root=self.project_root)
    
    def save_config(self, config: SystemConfig):
        """
        Save system configuration
        
        Args:
            config: SystemConfig to save
        """
        import json
        from dataclasses import asdict
        
        config_file = self.project_root / "orkestra" / "config.json"
        config_data = asdict(config)
        config_data['project_root'] = str(config_data['project_root'])
        
        with open(config_file, 'w') as f:
            json.dump(config_data, f, indent=2)
    
    def check_requirements(self) -> bool:
        """
        Check if all requirements are met
        
        Returns:
            True if requirements met
        """
        self.console.print("[yellow]Checking requirements...[/yellow]")
        
        # Check Python version
        if sys.version_info < (3, 11):
            self.console.print("[red]❌ Python 3.11+ required[/red]")
            return False
        self.console.print("[green]✅ Python version OK[/green]")
        
        # Check required packages
        required_packages = [
            'rich', 'anthropic', 'openai',
            'google.generativeai', 'psutil'
        ]
        
        missing = []
        for package in required_packages:
            try:
                __import__(package)
                self.console.print(f"[green]✅ {package}[/green]")
            except ImportError:
                self.console.print(f"[red]❌ {package}[/red]")
                missing.append(package)
        
        if missing:
            self.console.print(
                f"\n[red]Missing packages:[/red] {', '.join(missing)}\n"
                "[yellow]Install with:[/yellow] pip install -r requirements.txt"
            )
            return False
        
        return True
    
    def initialize(self) -> Orchestrator:
        """
        Initialize the system
        
        Returns:
            Initialized Orchestrator
        """
        self.console.print(Panel.fit(
            "[bold cyan]🎭 Orkestra Initialization[/bold cyan]",
            border_style="cyan"
        ))
        
        # Check requirements
        if not self.check_requirements():
            raise RuntimeError("Requirements not met")
        
        # Ensure directories
        self.ensure_directories()
        self.console.print("[green]✅ Directories created[/green]")
        
        # Load configuration
        config = self.load_config()
        self.console.print("[green]✅ Configuration loaded[/green]")
        
        # Create orchestrator
        orchestrator = Orchestrator(config)
        self.console.print("[green]✅ Orchestrator initialized[/green]")
        
        return orchestrator


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Orkestra Multi-AI Orchestration")
    parser.add_argument(
        '--project-root',
        type=Path,
        default=Path.cwd(),
        help='Project root directory'
    )
    parser.add_argument(
        '--status',
        action='store_true',
        help='Show system status and exit'
    )
    
    args = parser.parse_args()
    
    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(args.project_root / "orkestra" / "logs" / "orkestra.log"),
            logging.StreamHandler()
        ]
    )
    
    # Initialize system
    startup = SystemStartup(args.project_root)
    orchestrator = startup.initialize()
    
    if args.status:
        # Just show status
        orchestrator.print_status()
        return
    
    # Start orchestrator
    try:
        asyncio.run(orchestrator.start())
    except KeyboardInterrupt:
        print("\n\nShutting down gracefully...")
        asyncio.run(orchestrator.stop())


if __name__ == "__main__":
    main()
