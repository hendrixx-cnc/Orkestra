"""
Orkestra Core Module - Project Management
"""

import os
import json
import shutil
import subprocess
from pathlib import Path
from typing import Optional, Dict, Any, List
from datetime import datetime
import uuid


class OrkestraProject:
    """Main class for managing Orkestra projects"""
    
    def __init__(self, name: str, path: Path, config: Dict[str, Any]):
        self.name = name
        self.path = Path(path)
        self.config = config
        
    @classmethod
    def create(cls, name: str, path: Path, template: str = "standard") -> "OrkestraProject":
        """
        Create a new Orkestra project
        
        Args:
            name: Project name
            path: Project directory path
            template: Template to use (standard, minimal, advanced)
            
        Returns:
            OrkestraProject instance
        """
        path = Path(path)
        
        if path.exists():
            raise ValueError(f"Project directory already exists: {path}")
        
        # Create project structure
        path.mkdir(parents=True, exist_ok=True)
        
        # Create directories - all Orkestra files in orkestra/ folder
        directories = [
            "orkestra/config",
            "orkestra/config/task-queues",
            "orkestra/config/runtime",
            "orkestra/config/templates",
            "orkestra/scripts/agents",
            "orkestra/scripts/core",
            "orkestra/scripts/automation",
            "orkestra/scripts/safety",
            "orkestra/scripts/monitoring",
            "orkestra/scripts/committee",
            "orkestra/scripts/utils",
            "orkestra/docs",
            "orkestra/logs",
            "orkestra/logs/voting",        # Voting records stored IN project
            "orkestra/logs/outcomes",      # Decision outcomes stored IN project
            "orkestra/logs/execution",     # Task execution logs IN project
            "orkestra/backups",
        ]
        
        for dir_name in directories:
            (path / dir_name).mkdir(parents=True, exist_ok=True)
        
        # Copy templates from package
        cls._copy_templates(path, template)
        
        # Create project configuration
        config = {
            "id": str(uuid.uuid4()),
            "name": name,
            "version": "1.0.0",
            "created": datetime.now().isoformat(),
            "template": template,
            "status": "inactive"
        }
        
        config_file = path / "orkestra" / "config" / "project.json"
        with open(config_file, 'w') as f:
            json.dump(config, f, indent=2)
        
        # Check if global API keys exist, if not create example
        try:
            repo_root = Path(__file__).resolve().parents[2]
            global_config_dir = repo_root / "CONFIG"
            global_config_dir.mkdir(parents=True, exist_ok=True)
            global_api_keys_file = global_config_dir / "api-keys.env"
            
            # Only create example if no API keys exist yet
            if not global_api_keys_file.exists():
                api_keys_template = """# Orkestra Global API Keys Configuration
# These keys are shared across ALL Orkestra projects
# Set up once and use everywhere!

export ANTHROPIC_API_KEY="your-anthropic-api-key-here"
export OPENAI_API_KEY="your-openai-api-key-here"
export GOOGLE_API_KEY="your-google-api-key-here"
export GITHUB_TOKEN="your-github-token-here"
export XAI_API_KEY="your-xai-grok-api-key-here"
"""
                example_file = global_config_dir / "api-keys.env.example"
                with open(example_file, 'w') as f:
                    f.write(api_keys_template)
        except Exception:
            # Non-fatal if we can't create global config
            pass
        
        # Create empty task queue
        task_queue = {"tasks": [], "version": "1.0.0"}
        with open(path / "orkestra" / "config" / "task-queues" / "task-queue.json", 'w') as f:
            json.dump(task_queue, f, indent=2)
        
        # Create minimal readme
        readme_content = f"""# {name}

> Your project description goes here

## Getting Started

Add your project documentation here.

---

*Created with [Orkestra](https://github.com/hendrixx-cnc/Orkestra) - Multi-AI Task Coordination Platform*
"""
        with open(path / "readme.md", 'w') as f:
            f.write(readme_content)

        # Create changelog
        changelog_content = f"""# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Project initialized with Orkestra

---

**Project Created**: {config['created']}  
**Orkestra Version**: {config['version']}
"""
        with open(path / "changelog.md", 'w') as f:
            f.write(changelog_content)

        # Create .gitignore to protect API keys in config folder
        gitignore_content = """orkestra/config/
"""
        with open(path / ".gitignore", 'w') as f:
            f.write(gitignore_content)

        # Initialize a git repository in the project root so the project is self-contained
        try:
            subprocess.run(["git", "init"], cwd=str(path), check=True, capture_output=True)
            # Add .gitignore first
            subprocess.run(["git", "add", ".gitignore"], cwd=str(path), check=False, capture_output=True)
            subprocess.run(["git", "commit", "-m", "Initial commit: Add .gitignore"], cwd=str(path), check=False, capture_output=True)
        except Exception:
            # It's non-fatal if git isn't available; continue without failing
            pass

        # Create initial voting/outcome log files inside the project (these are audit logs)
        initial_vote = {
            "vote_id": "initial",
            "project": name,
            "timestamp": datetime.now().isoformat(),
            "ballot": [],
            "notes": "Initial vote placeholder"
        }

        initial_outcome = {
            "outcome_id": "initial",
            "project": name,
            "timestamp": datetime.now().isoformat(),
            "decision": "none",
            "notes": "Initial outcome placeholder"
        }

        with open(path / "orkestra" / "logs" / "voting" / f"vote-initial.json", 'w') as f:
            json.dump(initial_vote, f, indent=2)

        with open(path / "orkestra" / "logs" / "outcomes" / f"outcome-initial.json", 'w') as f:
            json.dump(initial_outcome, f, indent=2)

        # Update global Orkestra CONFIG/current-project.json to point to this new project
        try:
            repo_root = Path(__file__).resolve().parents[2]
            config_dir = repo_root / "CONFIG"
            config_dir.mkdir(parents=True, exist_ok=True)
            current_project_file = config_dir / "current-project.json"
            current_project_entry = {"name": name, "path": str(path)}
            with open(current_project_file, 'w') as f:
                json.dump(current_project_entry, f, indent=2)
        except Exception:
            # Non-fatal if we cannot write to repo CONFIG
            pass
        
        return cls(name, path, config)
    
    @classmethod
    def load(cls, name: str) -> "OrkestraProject":
        """Load an existing project"""
        # Try to find project in current directory
        current_dir = Path.cwd()
        # If the 'name' looks like a path, load directly from it
        candidate = Path(name)
        if candidate.exists():
            project_path = candidate
        else:
            project_path = current_dir / name
        
        if not project_path.exists():
            # Try in projects directory
            projects_dir = current_dir / "projects"
            project_path = projects_dir / name
            
        if not project_path.exists():
            # Try looking at repo CONFIG/current-project.json for an absolute path
            try:
                repo_root = Path(__file__).resolve().parents[2]
                current_project_file = repo_root / "CONFIG" / "current-project.json"
                if current_project_file.exists():
                    with open(current_project_file) as f:
                        entry = json.load(f)
                        entry_path = Path(entry.get('path', ''))
                        if entry_path.exists():
                            project_path = entry_path
            except Exception:
                pass

        if not project_path.exists():
            raise ValueError(f"Project not found: {name}")
        
        config_file = project_path / "orkestra" / "config" / "project.json"
        if not config_file.exists():
            raise ValueError(f"Invalid project: missing config file")
        
        with open(config_file) as f:
            config = json.load(f)
        
        return cls(name, project_path, config)
    
    @classmethod
    def load_current(cls) -> "OrkestraProject":
        """Load the current project from current directory"""
        current_dir = Path.cwd()
        config_file = current_dir / "orkestra" / "config" / "project.json"
        
        if not config_file.exists():
            raise ValueError("No Orkestra project found in current directory")
        
        with open(config_file) as f:
            config = json.load(f)
        
        return cls(config['name'], current_dir, config)
    
    @staticmethod
    def list_projects() -> List[Dict[str, Any]]:
        """List all available projects"""
        projects = []
        
        # Check current directory
        current_dir = Path.cwd()
        projects_dir = current_dir / "projects"
        
        if projects_dir.exists():
            for project_dir in projects_dir.iterdir():
                if project_dir.is_dir():
                    config_file = project_dir / "orkestra" / "config" / "project.json"
                    if config_file.exists():
                        with open(config_file) as f:
                            projects.append(json.load(f))
        
        return projects
    
    @staticmethod
    def _copy_templates(path: Path, template: str):
        """Copy template files to project"""
        # Get package directory
        package_dir = Path(__file__).parent
        templates_dir = package_dir / "templates" / template
        
        if not templates_dir.exists():
            # Use standard template as fallback
            templates_dir = package_dir / "templates" / "standard"
        
        if templates_dir.exists():
            # Copy shell scripts
            scripts_src = templates_dir / "scripts"
            if scripts_src.exists():
                shutil.copytree(scripts_src, path / "orkestra" / "scripts", dirs_exist_ok=True)
                # Make scripts executable
                for script in (path / "orkestra" / "scripts").rglob("*.sh"):
                    script.chmod(0o755)
    
    def start(self, monitor: bool = True, clean: bool = False):
        """Start the Orkestra system"""
        if clean:
            self.reset()
        
        # Start orchestrator
        orchestrator_script = self.path / "orkestra" / "scripts" / "core" / "orchestrator.sh"
        if orchestrator_script.exists():
            subprocess.Popen([str(orchestrator_script)], cwd=self.path)
        
        # Update status
        self.config['status'] = 'running'
        self._save_config()
    
    def stop(self):
        """Stop the Orkestra system"""
        # Kill orchestrator processes
        subprocess.run(["pkill", "-f", "orchestrator.sh"], check=False)
        subprocess.run(["pkill", "-f", "monitor.sh"], check=False)
        
        # Update status
        self.config['status'] = 'inactive'
        self._save_config()
    
    def reset(self):
        """Reset system to clean state"""
        # Clear locks
        locks_dir = self.path / "orkestra" / "config" / "locks"
        if locks_dir.exists():
            shutil.rmtree(locks_dir)
            locks_dir.mkdir()
        
        # Clear runtime
        runtime_dir = self.path / "orkestra" / "config" / "runtime"
        if runtime_dir.exists():
            for file in runtime_dir.iterdir():
                if file.is_file():
                    file.unlink()
    
    def get_status(self) -> Dict[str, Any]:
        """Get current system status"""
        status = {}
        
        # Check orchestrator
        result = subprocess.run(
            ["pgrep", "-f", "orchestrator.sh"],
            capture_output=True,
            text=True
        )
        status['orchestrator'] = {
            'running': result.returncode == 0,
            'details': f"PID: {result.stdout.strip()}" if result.returncode == 0 else "Not running"
        }
        
        # Check monitor
        result = subprocess.run(
            ["pgrep", "-f", "monitor.sh"],
            capture_output=True,
            text=True
        )
        status['monitor'] = {
            'running': result.returncode == 0,
            'details': f"PID: {result.stdout.strip()}" if result.returncode == 0 else "Not running"
        }
        
        # Check task queue
        task_queue_file = self.path / "orkestra" / "config" / "task-queues" / "task-queue.json"
        if task_queue_file.exists():
            with open(task_queue_file) as f:
                task_queue = json.load(f)
                task_count = len(task_queue.get('tasks', []))
                status['task_queue'] = {
                    'running': True,
                    'details': f"{task_count} tasks"
                }
        
        return status
    
    def _save_config(self):
        """Save project configuration"""
        config_file = self.path / "orkestra" / "config" / "project.json"
        with open(config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
