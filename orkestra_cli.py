#!/usr/bin/env python3
"""
Orkestra CLI - Main Entry Point

Usage:
    python orkestra_cli.py start           # Start the orchestrator
    python orkestra_cli.py status          # Show system status
    python orkestra_cli.py agents          # List available agents
    python orkestra_cli.py tasks           # Show task queue
    python orkestra_cli.py health          # Health check
    python orkestra_cli.py init            # Initialize system
"""

import sys
import asyncio
from pathlib import Path
from rich.console import Console
from rich.table import Table
from rich.panel import Panel

# Add src to path
sys.path.insert(0, str(Path(__file__).parent))

from src.orkestra import (
    SystemStartup,
    Orchestrator,
    TaskQueue,
    AgentManager,
    HealthMonitor
)

console = Console()


def cmd_start(project_root: Path):
    """Start the orchestrator"""
    console.print("[cyan]Starting Orkestra...[/cyan]")
    
    startup = SystemStartup(project_root)
    orchestrator = startup.initialize()
    
    try:
        asyncio.run(orchestrator.start())
    except KeyboardInterrupt:
        console.print("\n[yellow]Shutting down gracefully...[/yellow]")
        asyncio.run(orchestrator.stop())


def cmd_status(project_root: Path):
    """Show system status"""
    startup = SystemStartup(project_root)
    orchestrator = startup.initialize()
    
    orchestrator.print_status()


def cmd_agents(project_root: Path):
    """List available agents"""
    manager = AgentManager(project_root)
    
    table = Table(title="Available AI Agents")
    table.add_column("Agent", style="cyan")
    table.add_column("Model", style="yellow")
    table.add_column("Status", style="green")
    
    for agent_name in manager.get_available_agents():
        agent = manager.agents[agent_name]
        status = "✅ Ready" if agent.test_connection() else "❌ Not Available"
        table.add_row(agent_name, agent.config.model, status)
    
    console.print(table)


def cmd_tasks(project_root: Path):
    """Show task queue"""
    queue = TaskQueue(project_root)
    tasks = queue.list_tasks()
    
    if not tasks:
        console.print("[yellow]No tasks in queue[/yellow]")
        return
    
    table = Table(title=f"Task Queue ({len(tasks)} tasks)")
    table.add_column("ID", style="cyan")
    table.add_column("Title", style="yellow")
    table.add_column("Status", style="green")
    table.add_column("Assigned To", style="magenta")
    table.add_column("Priority", style="red")
    
    for task in tasks:
        status_emoji = {
            'pending': '⏳',
            'in_progress': '🔄',
            'completed': '✅',
            'failed': '❌'
        }.get(task.status, '❓')
        
        table.add_row(
            str(task.id),
            task.title[:50],
            f"{status_emoji} {task.status}",
            task.assigned_to or "-",
            str(task.priority)
        )
    
    console.print(table)


def cmd_health(project_root: Path):
    """Health check"""
    monitor = HealthMonitor(project_root)
    report = monitor.get_health_report(detail_level="full")
    
    # Overall status
    status_color = {
        'HEALTHY': 'green',
        'DEGRADED': 'yellow',
        'UNHEALTHY': 'red',
        'CRITICAL': 'red bold'
    }.get(report['overall_status'], 'white')
    
    console.print(Panel.fit(
        f"[{status_color}]{report['overall_status']}[/{status_color}]",
        title="System Health"
    ))
    
    # Metrics
    metrics = report['metrics']
    table = Table(show_header=False)
    table.add_column("Metric", style="cyan")
    table.add_column("Value", style="yellow")
    
    table.add_row("Active Agents", str(metrics.get('active_agents', 0)))
    table.add_row("Total Tasks", str(metrics.get('total_tasks', 0)))
    table.add_row("Completed Tasks", str(metrics.get('completed_tasks', 0)))
    table.add_row("Failed Tasks", str(metrics.get('failed_tasks', 0)))
    table.add_row("Uptime", f"{metrics.get('uptime_hours', 0):.1f} hours")
    
    console.print(table)


def cmd_init(project_root: Path):
    """Initialize system"""
    console.print("[cyan]Initializing Orkestra...[/cyan]")
    
    startup = SystemStartup(project_root)
    
    # Check requirements
    if not startup.check_requirements():
        console.print("[red]Requirements check failed. Please install dependencies:[/red]")
        console.print("[yellow]pip install -r requirements.txt[/yellow]")
        return
    
    # Create directories
    startup.ensure_directories()
    console.print("[green]✅ Directories created[/green]")
    
    # Load/save config
    config = startup.load_config()
    startup.save_config(config)
    console.print("[green]✅ Configuration saved[/green]")
    
    console.print("\n[green]Initialization complete![/green]")
    console.print("\n[cyan]Next steps:[/cyan]")
    console.print("1. Set API keys in environment variables")
    console.print("2. Run: python orkestra_cli.py agents (to test connections)")
    console.print("3. Run: python orkestra_cli.py start (to start system)")


def show_help():
    """Show help message"""
    console.print(Panel.fit(
        """[bold cyan]Orkestra CLI[/bold cyan]

[yellow]Commands:[/yellow]
  start     Start the orchestrator
  status    Show system status
  agents    List available agents
  tasks     Show task queue
  health    Health check
  init      Initialize system
  help      Show this message

[yellow]Examples:[/yellow]
  python orkestra_cli.py start
  python orkestra_cli.py status
  python orkestra_cli.py agents
""",
        title="Help",
        border_style="cyan"
    ))


def main():
    """Main CLI entry point"""
    project_root = Path(__file__).parent
    
    if len(sys.argv) < 2:
        show_help()
        return
    
    command = sys.argv[1].lower()
    
    commands = {
        'start': cmd_start,
        'status': cmd_status,
        'agents': cmd_agents,
        'tasks': cmd_tasks,
        'health': cmd_health,
        'init': cmd_init,
        'help': lambda _: show_help()
    }
    
    if command in commands:
        try:
            commands[command](project_root)
        except Exception as e:
            console.print(f"[red]Error: {e}[/red]")
            import traceback
            traceback.print_exc()
    else:
        console.print(f"[red]Unknown command: {command}[/red]")
        show_help()


if __name__ == "__main__":
    main()
