#!/usr/bin/env python3
"""
Orkestra CLI - Command Line Interface for Orkestra Framework
"""

import click
import os
import sys
import json
import shutil
from pathlib import Path
from typing import Optional
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich import box

console = Console()

# Version
__version__ = "1.0.0"


@click.group(invoke_without_command=True)
@click.pass_context
@click.version_option(version=__version__, prog_name="orkestra")
def main(ctx):
    """
    🎼 Orkestra - Multi-AI Task Coordination Platform
    
    Orchestrate Claude, ChatGPT, Gemini, Copilot, and Grok to work together
    on complex tasks with democratic decision-making and self-healing capabilities.
    """
    # If no subcommand provided, auto-start the current/last project
    if ctx.invoked_subcommand is None:
        from pathlib import Path as PathLib
        from .core import OrkestraProject
        import os
        
        try:
            # Try to load current project from current directory
            try:
                project = OrkestraProject.load_current()
                console.print(f"[cyan]📂 Current project:[/cyan] {project.name}")
            except:
                # If not in a project directory, load from CONFIG/current-project.json
                repo_root = PathLib(__file__).resolve().parents[1]
                current_project_file = repo_root.parent / "CONFIG" / "current-project.json"
                
                if current_project_file.exists():
                    import json
                    with open(current_project_file) as f:
                        entry = json.load(f)
                        project_path = PathLib(entry.get('path', ''))
                        
                    if project_path.exists():
                        # Change to project directory
                        os.chdir(str(project_path))
                        console.print(f"[cyan]📂 Switched to:[/cyan] {entry.get('name')} at {project_path}")
                        project = OrkestraProject.load_current()
                    else:
                        console.print("[yellow]No recent project found. Use:[/yellow] orkestra new <project-name>")
                        return
                else:
                    console.print("[yellow]No project found. Create one with:[/yellow] orkestra new <project-name>")
                    return
            
            # Start the project
            console.print(Panel(
                f"[cyan]Starting Orkestra...[/cyan]\n\n"
                f"[bold]Project:[/bold] {project.name}\n"
                f"[bold]Location:[/bold] {project.path}",
                title="🎼 Orkestra",
                border_style="cyan"
            ))
            
            project.start(monitor=True, clean=False)
            
            console.print("\n[green]✓[/green] Orkestra started successfully!")
            
            # Check if menu script exists and launch it
            menu_script = project.path.parent.parent / "Orkestra" / "orkestra-menu.sh"
            if not menu_script.exists():
                # Try relative to framework
                from pathlib import Path as PathLib
                repo_root = PathLib(__file__).resolve().parents[2]
                menu_script = repo_root / "orkestra-menu.sh"
            
            if menu_script.exists():
                console.print("\n[cyan]Launching Orkestra menu...[/cyan]")
                import subprocess
                subprocess.run(["bash", str(menu_script)])
            else:
                # Show simple menu if shell script not found
                show_menu(project)
            
        except Exception as e:
            console.print(f"[red]✗[/red] Error: {str(e)}", style="red")
            console.print("\n[yellow]Available commands:[/yellow]")
            console.print("  orkestra new <project-name>  - Create a new project")
            console.print("  orkestra start               - Start current project")
            console.print("  orkestra --help              - Show all commands")


def show_menu(project):
    """Display interactive menu after starting Orkestra"""
    
    console.print("\n" + "="*80)
    
    menu_table = Table(title="🎼 Orkestra Control Menu", box=box.ROUNDED, show_header=False)
    menu_table.add_column("Option", style="cyan", no_wrap=True)
    menu_table.add_column("Description", style="white")
    
    menu_table.add_row("1", "View project status")
    menu_table.add_row("2", "View logs")
    menu_table.add_row("3", "View voting records")
    menu_table.add_row("4", "View outcomes")
    menu_table.add_row("5", "List tasks")
    menu_table.add_row("6", "Stop Orkestra")
    menu_table.add_row("q", "Quit menu (Orkestra keeps running)")
    
    console.print(menu_table)
    console.print("\n[cyan]Project:[/cyan]", project.name)
    console.print("[cyan]Location:[/cyan]", str(project.path))
    console.print("\n[yellow]Orchestrator is running in the background...[/yellow]")
    console.print("[dim]Press Ctrl+C to return to shell, or select an option:[/dim]\n")


@main.command()
@click.argument('project_name')
@click.option('--path', '-p', default=None, help='Custom path for project (default: current directory)')
@click.option('--template', '-t', default='standard', help='Project template to use')
@click.option('--skip-planning', is_flag=True, help='Skip the project planning wizard')
def new(project_name: str, path: Optional[str], template: str, skip_planning: bool):
    """
    Create a new Orkestra project
    
    Example:
        orkestra new my-ai-project
        orkestra new my-project --path /custom/path --template minimal
        orkestra new my-project --skip-planning
    """
    from .core import OrkestraProject
    from .planning import ProjectPlanner
    
    try:
        if path:
            project_path = Path(path) / project_name
        else:
            project_path = Path.cwd() / project_name

        project = OrkestraProject.create(project_name, project_path, template=template)

        # Check if this is first project (needs API key setup)
        from pathlib import Path as PathLib
        repo_root = PathLib(__file__).resolve().parents[1]
        global_api_keys = repo_root.parent / "CONFIG" / "api-keys.env"
        api_keys_exist = global_api_keys.exists()

        next_steps = f"  1. cd {project_path}\n"
        if not api_keys_exist:
            next_steps += f"  2. 🔑 Configure API keys (one-time setup):\n"
            next_steps += f"     Edit: {repo_root.parent}/CONFIG/api-keys.env\n"
            next_steps += f"     (Copy from api-keys.env.example)\n"
            next_steps += f"  3. Start planning: orkestra start (planning wizard will launch)\n"
        else:
            next_steps += f"  2. Start planning: orkestra start (planning wizard will launch)\n"
            next_steps += f"     (API keys already configured ✓)\n"

        console.print(Panel(
            f"[green]✓[/green] Project '{project_name}' created successfully!\n\n"
            f"[bold]Location:[/bold] {project_path}\n"
            f"[bold]Template:[/bold] {template}\n\n"
            f"[cyan]Next steps:[/cyan]\n{next_steps}",
            title="🎼 Orkestra Project Created",
            border_style="green"
        ))
        
        # Launch Python-based project planning wizard unless skipped
        if not skip_planning:
            console.print("\n[cyan]Launching Project Planning Wizard...[/cyan]\n")
            import time
            time.sleep(1)
            
            # Use Python planning module
            try:
                os.chdir(str(project_path))
                planner = ProjectPlanner(project_path, project_name)
                planner.run_planning_wizard()
            except Exception as e:
                console.print(f"[yellow]Planning wizard error: {e}[/yellow]")
                console.print("[yellow]You can access it later from the main menu.[/yellow]")

    except Exception as e:
        console.print(f"[red]✗[/red] Error creating project: {str(e)}", style="red")
        sys.exit(1)


@main.command()
@click.option('--monitor/--no-monitor', default=True, help='Enable monitoring dashboard')
@click.option('--clean', is_flag=True, help='Clean start (reset locks and clear stale tasks)')
def start(monitor: bool, clean: bool):
    """
    Start the Orkestra orchestration system
    
    Example:
        orkestra start
        orkestra start --no-monitor
        orkestra start --clean
    """
    from .core import OrkestraProject
    
    try:
        project = OrkestraProject.load_current()
        
        console.print(Panel(
            f"[cyan]Starting Orkestra...[/cyan]\n\n"
            f"[bold]Project:[/bold] {project.name}\n"
            f"[bold]Monitor:[/bold] {'Enabled' if monitor else 'Disabled'}\n"
            f"[bold]Clean Start:[/bold] {'Yes' if clean else 'No'}",
            title="🎼 Orkestra",
            border_style="cyan"
        ))
        
        project.start(monitor=monitor, clean=clean)
        
        console.print("\n[green]✓[/green] Orkestra started successfully!")
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error starting Orkestra: {str(e)}", style="red")
        sys.exit(1)


@main.command()
@click.argument('project_name')
def load(project_name: str):
    """
    Load an existing Orkestra project
    
    Example:
        orkestra load my-ai-project
    """
    from .core import OrkestraProject
    
    try:
        project = OrkestraProject.load(project_name)
        
        console.print(Panel(
            f"[green]✓[/green] Project '{project_name}' loaded successfully!\n\n"
            f"[bold]ID:[/bold] {project.config.get('id', 'N/A')}\n"
            f"[bold]Version:[/bold] {project.config.get('version', 'N/A')}\n"
            f"[bold]Created:[/bold] {project.config.get('created', 'N/A')}\n\n"
            f"[cyan]Next step:[/cyan] orkestra start",
            title="🎼 Project Loaded",
            border_style="green"
        ))
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error loading project: {str(e)}", style="red")
        sys.exit(1)


@main.command()
def list():
    """
    List all Orkestra projects
    
    Example:
        orkestra list
    """
    from .core import OrkestraProject
    
    try:
        projects = OrkestraProject.list_projects()
        
        if not projects:
            console.print("[yellow]No projects found.[/yellow]")
            console.print("\nCreate a new project with: [cyan]orkestra new <project-name>[/cyan]")
            return
        
        table = Table(title="🎼 Orkestra Projects", box=box.ROUNDED)
        table.add_column("Name", style="cyan", no_wrap=True)
        table.add_column("ID", style="magenta")
        table.add_column("Version", style="green")
        table.add_column("Created", style="blue")
        table.add_column("Status", style="yellow")
        
        for project in projects:
            table.add_row(
                project.get('name', 'N/A'),
                project.get('id', 'N/A'),
                project.get('version', 'N/A'),
                project.get('created', 'N/A'),
                project.get('status', 'inactive')
            )
        
        console.print(table)
        console.print("\n[cyan]Load a project:[/cyan] orkestra load <project-name>")
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error listing projects: {str(e)}", style="red")
        sys.exit(1)


@main.command()
def status():
    """
    Show current Orkestra system status
    
    Example:
        orkestra status
    """
    from .core import OrkestraProject
    
    try:
        project = OrkestraProject.load_current()
        status_info = project.get_status()
        
        table = Table(title=f"🎼 Orkestra Status - {project.name}", box=box.ROUNDED)
        table.add_column("Component", style="cyan", no_wrap=True)
        table.add_column("Status", style="green")
        table.add_column("Details", style="blue")
        
        for component, info in status_info.items():
            status_emoji = "✓" if info.get('running') else "✗"
            status_text = f"[green]{status_emoji}[/green]" if info.get('running') else f"[red]{status_emoji}[/red]"
            table.add_row(
                component,
                status_text,
                info.get('details', 'N/A')
            )
        
        console.print(table)
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error getting status: {str(e)}", style="red")
        sys.exit(1)


@main.command()
def stop():
    """
    Stop the running Orkestra system
    
    Example:
        orkestra stop
    """
    from .core import OrkestraProject
    
    try:
        project = OrkestraProject.load_current()
        project.stop()
        
        console.print("[green]✓[/green] Orkestra stopped successfully!")
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error stopping Orkestra: {str(e)}", style="red")
        sys.exit(1)


@main.command()
@click.option('--force', is_flag=True, help='Force reset without confirmation')
def reset(force: bool):
    """
    Reset Orkestra system to clean state
    
    Example:
        orkestra reset
        orkestra reset --force
    """
    if not force:
        confirm = click.confirm('⚠️  This will reset locks, clear stale tasks, and stop all processes. Continue?')
        if not confirm:
            console.print("[yellow]Reset cancelled.[/yellow]")
            return
    
    from .core import OrkestraProject
    
    try:
        project = OrkestraProject.load_current()
        project.reset()
        
        console.print("[green]✓[/green] Orkestra reset successfully!")
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error resetting Orkestra: {str(e)}", style="red")
        sys.exit(1)


@main.command()
def config():
    """
    Open configuration editor
    
    Example:
        orkestra config
    """
    from pathlib import Path as PathLib
    
    try:
        # Use global API keys location
        repo_root = PathLib(__file__).resolve().parents[1]
        global_config_dir = repo_root.parent / "CONFIG"
        config_path = global_config_dir / "api-keys.env"
        example_path = global_config_dir / "api-keys.env.example"
        
        console.print(f"[cyan]Global API keys location (shared by all projects):[/cyan]\n")
        console.print(f"  {config_path}\n")
        
        if not config_path.exists() and example_path.exists():
            console.print(f"[yellow]⚠ API keys not yet configured.[/yellow]\n")
            console.print(f"[cyan]Copy example file:[/cyan]")
            console.print(f"  cp {example_path} {config_path}\n")
            console.print(f"[cyan]Then edit with your keys:[/cyan]")
            console.print(f"  nano {config_path}")
            console.print(f"  # or use your preferred editor\n")
        else:
            console.print(f"[yellow]Edit this file with your preferred editor.[/yellow]")
        
    except Exception as e:
        console.print(f"[red]✗[/red] Error accessing config: {str(e)}", style="red")
        sys.exit(1)


if __name__ == "__main__":
    main()
