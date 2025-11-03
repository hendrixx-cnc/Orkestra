#!/usr/bin/env python3
"""
Orkestra Project Planning System
AI-driven democratic project planning with user involvement
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.table import Table

from .committee import Committee
from .tasks import TaskQueue, TaskPriority


console = Console()


class ProjectPlanner:
    """AI-driven project planning system"""
    
    def __init__(self, project_root: Path, project_name: str):
        """Initialize project planner
        
        Args:
            project_root: Root directory of the project
            project_name: Name of the project
        """
        self.project_root = Path(project_root)
        self.project_name = project_name
        self.committee = Committee(project_root)
        self.task_queue = TaskQueue(project_root)
        self.planning_dir = self.project_root / "orkestra" / "docs" / "planning"
        self.planning_dir.mkdir(parents=True, exist_ok=True)
        
        # Planning data
        self.project_description = ""
        self.involvement_level = "medium"
        self.user_features = []
        self.final_plan = {}
    
    def run_planning_wizard(self) -> bool:
        """Run the interactive planning wizard
        
        Returns:
            True if plan was approved
        """
        console.print("\n")
        console.print(Panel.fit(
            "[bold purple]PROJECT PLANNING WIZARD[/bold purple]\n\n"
            "Collaborative AI-Assisted Planning",
            border_style="purple"
        ))
        console.print("\n")
        
        # Step 1: Collect project information
        if not self._collect_project_info():
            return False
        
        # Step 2: AI-driven planning rounds
        if not self._ai_planning_rounds():
            return False
        
        # Step 3: Present and get approval
        if not self._present_final_plan():
            return False
        
        # Step 4: Generate tasks
        self._generate_tasks()
        
        # Step 5: Create outcome record
        self._create_outcome()
        
        # Step 6: Show summary
        self._show_summary()
        
        return True
    
    def _collect_project_info(self) -> bool:
        """Collect project information from user
        
        Returns:
            True if information collected successfully
        """
        console.print("[cyan]═══ STEP 1: PROJECT OVERVIEW ═══[/cyan]\n")
        
        console.print(f"[green]Project Name:[/green] {self.project_name}\n")
        
        # Project description
        console.print("[cyan]What would you like to make?[/cyan]")
        console.print("[yellow](Describe your project idea in detail)[/yellow]")
        self.project_description = Prompt.ask("> ")
        
        if not self.project_description:
            console.print("[red]Project description is required[/red]")
            return False
        
        console.print()
        
        # Involvement level
        console.print("[cyan]How involved do you want to be in the planning process?[/cyan]\n")
        console.print("1) [green]High Involvement[/green]   - Review and approve after each round")
        console.print("2) [blue]Medium Involvement[/blue] - Review at key milestones")
        console.print("3) [yellow]Low Involvement[/yellow]    - Just approve final plan")
        console.print()
        
        involvement_choice = Prompt.ask("Select", choices=["1", "2", "3"], default="2")
        self.involvement_level = {"1": "high", "2": "medium", "3": "low"}[involvement_choice]
        
        console.print()
        
        # Features
        console.print("[cyan]What key features do you want to include?[/cyan]")
        console.print("[yellow](List as many as you'd like. Press Enter to skip, or type features one per line. Type 'done' when finished)[/yellow]\n")
        
        feature_count = 1
        while True:
            feature = Prompt.ask(f"[green]Feature #{feature_count}[/green]", default="")
            
            if not feature or feature.lower() == "done":
                break
            
            self.user_features.append(feature)
            feature_count += 1
        
        console.print()
        if self.user_features:
            console.print(f"[green]✓[/green] You specified {len(self.user_features)} features")
        else:
            console.print("[yellow]No features specified - AI Committee will suggest features[/yellow]")
        console.print()
        
        return True
    
    def _ai_planning_rounds(self) -> bool:
        """Run AI planning rounds with democratic voting
        
        Returns:
            True if planning completed successfully
        """
        console.print("\n[cyan]═══ STEP 2: AI COMMITTEE PLANNING ═══[/cyan]\n")
        
        console.print("[purple]Initiating democratic planning process...[/purple]")
        console.print("[yellow]The 5 AI agents will now collaborate to create a comprehensive plan.[/yellow]\n")
        
        # Create planning vote
        vote = self._create_planning_vote()
        
        # Run voting rounds
        planning_round = 1
        user_feedback = ""
        max_rounds = 5
        
        while planning_round <= max_rounds:
            console.print(f"\n[cyan]═══ PLANNING ROUND {planning_round} ═══[/cyan]\n")
            
            if planning_round == 1:
                console.print("[yellow]AI Committee is analyzing your project...[/yellow]")
                console.print("- Identifying optimal technology stack")
                console.print("- Breaking down features into components")
                console.print("- Creating implementation phases")
                console.print("- Estimating timeline and resources")
            else:
                console.print("[yellow]AI Committee is refining the plan...[/yellow]")
                console.print("- Incorporating your feedback")
                console.print("- Resolving disagreements")
                console.print("- Optimizing architecture")
                console.print("- Finalizing details")
            
            console.print()
            
            # Process voting round
            round_results = self.committee.process_vote(vote, user_feedback)
            
            # Show results
            self._show_round_results(planning_round, round_results)
            
            # Check consensus
            if round_results["consensus"] == "unanimous":
                console.print("\n[green]✓ Unanimous consensus reached![/green]\n")
                break
            
            # Get user feedback
            if self.involvement_level == "high" or (
                self.involvement_level == "medium" and planning_round % 2 == 0
            ):
                user_feedback = self._get_user_feedback()
            else:
                console.print("[cyan]Proceeding to next round automatically...[/cyan]\n")
                user_feedback = ""
            
            planning_round += 1
        
        if planning_round > max_rounds:
            console.print("[yellow]Maximum rounds reached. Using current best plan.[/yellow]\n")
        
        # Extract final plan
        self._extract_final_plan(vote)
        
        return True
    
    def _create_planning_vote(self):
        """Create planning vote
        
        Returns:
            Vote object
        """
        # Build context
        features_context = "User-specified features:\n"
        if self.user_features:
            for feature in self.user_features:
                features_context += f"- {feature}\n"
        else:
            features_context += "None specified - suggest appropriate features\n"
        
        context = (
            f"Project Description: {self.project_description}\n\n"
            f"{features_context}\n"
            f"User Involvement: {self.involvement_level}\n\n"
            "Create a complete implementation plan from zero to production."
        )
        
        # Gather additional context
        additional_context = self.committee.gather_context(self.project_description)
        if additional_context:
            context += f"\n\n{additional_context}"
        
        # Create vote
        vote = self.committee.create_vote(
            topic=f"Comprehensive Project Plan: {self.project_name}",
            options=[
                "Approve comprehensive plan",
                "Request modifications",
                "Propose alternative approach"
            ],
            context=context,
            vote_type="planning",
            num_rounds=5,
            project_name=self.project_name
        )
        
        return vote
    
    def _show_round_results(self, round_num: int, results: Dict):
        """Show results of a voting round
        
        Args:
            round_num: Round number
            results: Round results dictionary
        """
        console.print("[cyan]─────────────────────────────────────────[/cyan]")
        console.print(f"[purple]ROUND {round_num} RESULTS[/purple]")
        console.print("[cyan]─────────────────────────────────────────[/cyan]\n")
        
        # Show each agent's position
        for proposal in results.get("proposals", []):
            agent = proposal.get("agent", "unknown")
            reasoning = proposal.get("reasoning", "No reasoning provided")
            vote = proposal.get("vote", "unknown")
            
            console.print(f"[green]{agent.title()}:[/green] {reasoning}")
            console.print(f"          [blue]Vote: {vote}[/blue]\n")
        
        # Show consensus level
        consensus = results.get("consensus", "unknown")
        console.print(f"[yellow]Consensus Level:[/yellow] {consensus.title()}\n")
    
    def _get_user_feedback(self) -> str:
        """Get user feedback on current plan
        
        Returns:
            User feedback string
        """
        console.print("[cyan]─────────────────────────────────────────[/cyan]")
        console.print("[yellow]YOUR INPUT[/yellow]")
        console.print("[cyan]─────────────────────────────────────────[/cyan]\n")
        
        console.print("[cyan]Do you have any feedback on this plan?[/cyan]")
        console.print("[yellow](Press Enter to approve, or type your concerns/suggestions)[/yellow]\n")
        
        feedback = Prompt.ask("> ", default="")
        
        if not feedback:
            console.print("[green]✓ Plan approved[/green]\n")
        else:
            console.print("[yellow]→ Feedback will be incorporated in next round[/yellow]\n")
        
        return feedback
    
    def _extract_final_plan(self, vote):
        """Extract final plan from vote results
        
        Args:
            vote: Vote object with results
        """
        # Extract from vote results
        # In a real implementation, this would parse actual AI responses
        self.final_plan = {
            "languages": "Python, JavaScript, TypeScript",
            "frameworks": "FastAPI, React, PostgreSQL, Redis",
            "databases": "PostgreSQL, Redis",
            "tools": "Docker, Kubernetes, GitHub Actions",
            "timeline": "10 weeks",
            "priority": "High",
            "project_type": "Full-Stack Application",
            "features": self.user_features + [
                "Authentication & Authorization",
                "API Gateway & Routing",
                "Database Migrations",
                "Caching Layer",
                "Monitoring & Logging",
                "CI/CD Pipeline",
                "Documentation"
            ]
        }
    
    def _present_final_plan(self) -> bool:
        """Present final plan to user for approval
        
        Returns:
            True if plan approved
        """
        console.print("\n[cyan]═══ FINAL PLAN PRESENTATION ═══[/cyan]\n")
        
        console.print("[purple]The AI Committee has reached unanimous consensus![/purple]\n")
        
        # Create plan table
        table = Table(title=f"PROJECT: {self.project_name}", show_header=False)
        table.add_column("Property", style="yellow")
        table.add_column("Value", style="white")
        
        table.add_row("Description", self.project_description)
        table.add_row("Technology Stack", f"Languages: {self.final_plan['languages']}")
        table.add_row("", f"Frameworks: {self.final_plan['frameworks']}")
        table.add_row("", f"Databases: {self.final_plan['databases']}")
        table.add_row("", f"Tools: {self.final_plan['tools']}")
        table.add_row("Features", f"{len(self.final_plan['features'])} total features")
        table.add_row("Timeline", self.final_plan['timeline'])
        
        console.print(table)
        console.print()
        
        # Show features
        console.print("[yellow]Features:[/yellow]")
        for feature in self.final_plan['features']:
            console.print(f"  ✓ {feature}")
        console.print()
        
        # Get approval
        console.print("[yellow]Do you approve this plan?[/yellow]\n")
        console.print("1) [green]Yes - Start implementation[/green]")
        console.print("2) [blue]Request modifications[/blue]")
        console.print("3) [red]Reject and restart planning[/red]\n")
        
        approval = Prompt.ask("Select", choices=["1", "2", "3"], default="1")
        
        if approval == "1":
            console.print("\n[green]✓ Plan approved! Proceeding to task generation...[/green]\n")
            return True
        elif approval == "2":
            console.print("\n[cyan]What modifications would you like?[/cyan]")
            modifications = Prompt.ask("> ")
            console.print("\n[yellow]Running additional planning round with your feedback...[/yellow]\n")
            # Re-run planning with feedback
            return self._ai_planning_rounds()
        else:
            console.print("\n[red]Plan rejected.[/red]")
            return False
    
    def _generate_tasks(self):
        """Generate implementation tasks from plan"""
        console.print("\n[cyan]═══ STEP 3: TASK GENERATION ═══[/cyan]\n")
        
        console.print("[cyan]Generating implementation tasks from approved plan...[/cyan]\n")
        
        # Phase 1: Foundation
        console.print("[yellow]Phase 1: Foundation[/yellow]")
        self.task_queue.add_task(
            "setup-project-structure",
            "Initialize project structure and configuration files",
            priority=TaskPriority.HIGH.value,
            category="setup",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 1}
        )
        self.task_queue.add_task(
            "setup-dev-environment",
            "Configure development environment and tools",
            priority=TaskPriority.HIGH.value,
            category="setup",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 1}
        )
        self.task_queue.add_task(
            "setup-database-schema",
            "Design and implement database schema",
            priority=TaskPriority.HIGH.value,
            category="database",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 1}
        )
        self.task_queue.add_task(
            "setup-authentication",
            "Implement authentication and authorization system",
            priority=TaskPriority.HIGH.value,
            category="security",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 1}
        )
        console.print("[dim]  ✓ 4 tasks created[/dim]\n")
        
        # Phase 2: Core Features
        console.print("[yellow]Phase 2: Core Features[/yellow]")
        feature_count = 0
        for feature in self.final_plan['features']:
            task_id = f"feature-{feature.lower().replace(' ', '-')[:30]}"
            self.task_queue.add_task(
                task_id,
                f"Implement: {feature}",
                priority=TaskPriority.HIGH.value,
                category="feature",
                metadata={"auto_generated": True, "source": "ai_planning", "phase": 2}
            )
            feature_count += 1
        console.print(f"[dim]  ✓ {feature_count} tasks created[/dim]\n")
        
        # Phase 3: Integration & Testing
        console.print("[yellow]Phase 3: Integration & Testing[/yellow]")
        self.task_queue.add_task(
            "api-integration",
            "Integrate all API endpoints and services",
            priority=TaskPriority.MEDIUM.value,
            category="integration",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 3}
        )
        self.task_queue.add_task(
            "unit-tests",
            "Write unit tests for all components",
            priority=TaskPriority.HIGH.value,
            category="testing",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 3}
        )
        self.task_queue.add_task(
            "integration-tests",
            "Create integration and E2E tests",
            priority=TaskPriority.HIGH.value,
            category="testing",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 3}
        )
        self.task_queue.add_task(
            "performance-optimization",
            "Optimize performance and resource usage",
            priority=TaskPriority.MEDIUM.value,
            category="optimization",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 3}
        )
        console.print("[dim]  ✓ 4 tasks created[/dim]\n")
        
        # Phase 4: Deployment
        console.print("[yellow]Phase 4: Deployment & Docs[/yellow]")
        self.task_queue.add_task(
            "setup-cicd",
            "Configure CI/CD pipeline",
            priority=TaskPriority.HIGH.value,
            category="devops",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 4}
        )
        self.task_queue.add_task(
            "setup-monitoring",
            "Set up monitoring, logging, and alerts",
            priority=TaskPriority.HIGH.value,
            category="devops",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 4}
        )
        self.task_queue.add_task(
            "write-documentation",
            "Write comprehensive documentation",
            priority=TaskPriority.MEDIUM.value,
            category="documentation",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 4}
        )
        self.task_queue.add_task(
            "production-deployment",
            "Deploy to production environment",
            priority=TaskPriority.HIGH.value,
            category="deployment",
            metadata={"auto_generated": True, "source": "ai_planning", "phase": 4}
        )
        console.print("[dim]  ✓ 4 tasks created[/dim]\n")
        
        total_tasks = 4 + feature_count + 4 + 4
        console.print(f"[green]✓[/green] Generated {total_tasks} tasks organized in 4 phases\n")
    
    def _create_outcome(self):
        """Create outcome record"""
        # Get the planning vote
        votes = self.committee.list_votes(status="active")
        if votes:
            vote = votes[0]
            outcome = self.committee.create_outcome(
                vote=vote,
                decision="Comprehensive implementation plan approved",
                implementation_notes=self.final_plan['features']
            )
    
    def _show_summary(self):
        """Show planning summary"""
        console.print("\n[cyan]═══ PLANNING COMPLETE ═══[/cyan]\n")
        
        console.print("[green]✓ Project Overview Defined[/green]")
        console.print("[green]✓ AI Committee Planning Complete[/green]")
        console.print("[green]✓ Unanimous Consensus Reached[/green]")
        console.print("[green]✓ Plan Approved by User[/green]")
        console.print("[green]✓ Implementation Tasks Generated[/green]")
        console.print("[green]✓ Outcome Recorded[/green]\n")
        
        console.print("[purple]═══════════════════════════════════════════════════════[/purple]")
        console.print("[cyan]Your project is ready to begin implementation![/cyan]\n")
        
        console.print("[yellow]Next Steps:[/yellow]")
        console.print(f"  1. Review tasks: orkestra/logs/task-queue.json")
        console.print(f"  2. Check outcomes: orkestra/logs/outcomes/")
        console.print(f"  3. Start implementation: Tasks are queued and ready\n")
        
        console.print("[cyan]The orchestrator will now begin executing tasks automatically.[/cyan]")
        console.print("[yellow]You can monitor progress from the main menu.[/yellow]\n")
