#!/usr/bin/env python3
"""
Committee Module for Orkestra
==============================

Manages democratic voting system with 5 AI agents (Claude, ChatGPT, Gemini, 
Copilot, Grok). Provides consensus-building and decision-making capabilities.

Integrated with:
- ContextManager for complete history tracking
- DemocracyEngine for advanced voting mechanisms
"""

import json
import hashlib
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List, Any, Callable
from dataclasses import dataclass, field
import os

from .context import ContextManager, ContextEventType
from .democracy import DemocracyEngine, VoteType, ConsensusLevel

import json
import hashlib
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
import os


@dataclass
class Agent:
    """Represents an AI agent in the committee"""
    id: str
    name: str
    status: str = "active"
    
    
@dataclass
class VoteOption:
    """Represents a voting option"""
    id: str
    text: str
    votes: List[Dict[str, str]] = None
    
    def __post_init__(self):
        if self.votes is None:
            self.votes = []


@dataclass
class Vote:
    """Represents a committee vote"""
    vote_id: str
    project: str
    timestamp: str
    status: str
    topic: str
    context: str
    options: List[VoteOption]
    rounds: Dict[str, Any]
    agents_required: List[str]
    vote_type: str = "standard"
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for JSON serialization"""
        data = asdict(self)
        data['options'] = [asdict(opt) for opt in self.options]
        return data
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'Vote':
        """Create Vote from dictionary"""
        options = [VoteOption(**opt) for opt in data.get('options', [])]
        data['options'] = options
        return cls(**data)


class Committee:
    """
    Manages democratic decision-making among AI agents.
    
    Integrates with ContextManager for recovery and DemocracyEngine for voting.
    """
    
    AGENTS = [
        Agent("claude", "Architecture, Design, UX", "active"),
        Agent("chatgpt", "Content, Writing, Marketing", "active"),
        Agent("gemini", "Cloud, Database, Firebase", "active"),
        Agent("copilot", "Deployment, Code, DevOps", "active"),
        Agent("grok", "Innovation, Research, Analysis", "active"),
    ]
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.voting_dir = self.project_root / "orkestra" / "logs" / "voting"
        self.outcomes_dir = self.project_root / "orkestra" / "logs" / "outcomes"
        self.voting_dir.mkdir(parents=True, exist_ok=True)
        self.outcomes_dir.mkdir(parents=True, exist_ok=True)
        
        # Initialize integrated systems
        self.context = ContextManager(self.project_root)
        self.democracy = DemocracyEngine(self.project_root, self.context)
    
    def create_vote(
        self,
        topic: str,
        options: List[str],
        context: str = "",
        vote_type: str = "standard",
        num_rounds: int = 3,
        project_name: Optional[str] = None
    ) -> Vote:
        """Create a new vote
        
        Args:
            topic: The question or topic to vote on
            options: List of voting options
            context: Additional context for the vote
            vote_type: Type of vote (standard, planning, approval)
            num_rounds: Number of voting rounds
            project_name: Optional project name
            
        Returns:
            Vote object
        """
        # Generate vote ID
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        vote_hash = hashlib.sha256(f"{topic}-{timestamp}".encode()).hexdigest()[:8]
        vote_id = f"vote-{timestamp}-{vote_hash}"
        
        # Create vote options
        vote_options = [
            VoteOption(id=f"option_{i+1}", text=opt)
            for i, opt in enumerate(options)
        ]
        
        # Create vote
        vote = Vote(
            vote_id=vote_id,
            project=project_name or self.project_root.name,
            timestamp=datetime.utcnow().isoformat() + "Z",
            status="active",
            topic=topic,
            context=context,
            options=vote_options,
            rounds={
                "total": num_rounds,
                "current": 1,
                "results": []
            },
            agents_required=[agent.id for agent in self.AGENTS],
            vote_type=vote_type
        )
        
        # Save vote
        vote_file = self.votes_dir / f"{vote_id}.json"
        with open(vote_file, 'w') as f:
            json.dump(vote.to_dict(), f, indent=2)
        
        return vote
    
    def process_vote(
        self,
        vote: Vote,
        user_feedback: Optional[str] = None
    ) -> Dict[str, Any]:
        """Process a voting round
        
        Args:
            vote: Vote object to process
            user_feedback: Optional user feedback to incorporate
            
        Returns:
            Dictionary with round results
        """
        current_round = vote.rounds["current"]
        
        # Gather context for this round
        context = self.gather_context(vote.topic, vote.context)
        if user_feedback:
            context += f"\n\nUser Feedback: {user_feedback}"
        
        # Process vote through each agent
        round_results = {
            "round": current_round,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "user_feedback": user_feedback or "",
            "proposals": []
        }
        
        for agent in self.AGENTS:
            # Call agent to vote
            agent_vote = self._call_agent(agent, vote, context)
            round_results["proposals"].append(agent_vote)
        
        # Check consensus
        consensus = self._check_consensus(round_results["proposals"])
        round_results["consensus"] = consensus
        
        # Update vote
        vote.rounds["results"].append(round_results)
        vote.rounds["current"] += 1
        
        # Save updated vote
        self._save_vote(vote)
        
        return round_results
    
    def _call_agent(
        self,
        agent: Agent,
        vote: Vote,
        context: str
    ) -> Dict[str, str]:
        """Call an AI agent to vote
        
        Args:
            agent: Agent to call
            vote: Vote object
            context: Context for the vote
            
        Returns:
            Dictionary with agent's vote and reasoning
        """
        # TODO: Implement actual AI API calls when configured
        # For now, return simulated response
        
        # Check if API keys are configured
        api_configured = self._check_agent_api(agent.id)
        
        if api_configured:
            # Call actual agent API
            try:
                response = self._call_agent_api(agent, vote, context)
                return response
            except Exception as e:
                print(f"Warning: {agent.name} API call failed: {e}")
        
        # Simulated response
        return {
            "agent": agent.id,
            "vote": vote.options[0].id,  # Vote for first option
            "reasoning": f"{agent.name}: Comprehensive approach with solid foundation"
        }
    
    def _check_agent_api(self, agent_id: str) -> bool:
        """Check if agent API is configured
        
        Args:
            agent_id: ID of the agent
            
        Returns:
            True if API is configured
        """
        # Check for API keys in environment or config
        api_key_map = {
            "claude": "ANTHROPIC_API_KEY",
            "chatgpt": "OPENAI_API_KEY",
            "gemini": "GOOGLE_API_KEY",
            "copilot": "GITHUB_TOKEN",
            "grok": "XAI_API_KEY"
        }
        
        env_key = api_key_map.get(agent_id)
        if env_key:
            return bool(os.getenv(env_key))
        
        return False
    
    def _call_agent_api(
        self,
        agent: Agent,
        vote: Vote,
        context: str
    ) -> Dict[str, str]:
        """Call actual agent API
        
        Args:
            agent: Agent to call
            vote: Vote object
            context: Context for the vote
            
        Returns:
            Dictionary with agent's vote and reasoning
        """
        # TODO: Implement actual API calls to each agent
        # This will be expanded when API integrations are added
        raise NotImplementedError(f"API integration for {agent.name} not yet implemented")
    
    def _check_consensus(self, proposals: List[Dict]) -> str:
        """Check if proposals reached consensus
        
        Args:
            proposals: List of agent proposals
            
        Returns:
            Consensus level: unanimous, strong, split
        """
        if not proposals:
            return "none"
        
        # Count votes
        vote_counts = {}
        for proposal in proposals:
            vote = proposal.get("vote")
            vote_counts[vote] = vote_counts.get(vote, 0) + 1
        
        # Check consensus
        total_votes = len(proposals)
        max_votes = max(vote_counts.values())
        
        if max_votes == total_votes:
            return "unanimous"
        elif max_votes >= total_votes * 0.8:
            return "strong"
        else:
            return "split"
    
    def _save_vote(self, vote: Vote):
        """Save vote to file
        
        Args:
            vote: Vote object to save
        """
        vote_file = self.votes_dir / f"{vote.vote_id}.json"
        with open(vote_file, 'w') as f:
            json.dump(vote.to_dict(), f, indent=2)
    
    def gather_context(self, topic: str, additional_context: str = "") -> str:
        """Gather relevant context from the workspace
        
        Args:
            topic: Topic to gather context for
            additional_context: Additional context to include
            
        Returns:
            Gathered context string
        """
        context_parts = []
        
        # Add provided context
        if additional_context:
            context_parts.append(additional_context)
        
        # Search docs directory
        docs_dir = self.project_root / "orkestra" / "docs"
        if docs_dir.exists():
            relevant_docs = self._search_directory(docs_dir, topic)
            if relevant_docs:
                context_parts.append(f"Relevant Documentation:\n{relevant_docs}")
        
        # Search for related files in project
        relevant_files = self._search_directory(self.project_root, topic, max_results=5)
        if relevant_files:
            context_parts.append(f"Related Files:\n{relevant_files}")
        
        # Get recent git history if available
        if (self.project_root / ".git").exists():
            git_history = self._get_git_history(topic)
            if git_history:
                context_parts.append(f"Recent Commits:\n{git_history}")
        
        return "\n\n".join(context_parts)
    
    def _search_directory(
        self,
        directory: Path,
        query: str,
        max_results: int = 10
    ) -> str:
        """Search directory for files containing query
        
        Args:
            directory: Directory to search
            query: Search query
            max_results: Maximum number of results
            
        Returns:
            String with search results
        """
        results = []
        
        try:
            # Use grep for fast searching
            result = subprocess.run(
                ["grep", "-ril", query, str(directory)],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0:
                files = result.stdout.strip().split('\n')[:max_results]
                for file_path in files:
                    if file_path:
                        # Make path relative
                        try:
                            rel_path = Path(file_path).relative_to(self.project_root)
                            results.append(f"  - {rel_path}")
                        except ValueError:
                            results.append(f"  - {file_path}")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        return "\n".join(results) if results else ""
    
    def _get_git_history(self, topic: str, max_commits: int = 5) -> str:
        """Get recent git commits related to topic
        
        Args:
            topic: Topic to search for
            max_commits: Maximum number of commits
            
        Returns:
            String with git history
        """
        try:
            result = subprocess.run(
                ["git", "log", "--all", "--oneline", f"--grep={topic}", f"-n{max_commits}"],
                cwd=str(self.project_root),
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip()
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        return ""
    
    def create_outcome(
        self,
        vote: Vote,
        decision: str,
        implementation_notes: List[str]
    ) -> Dict[str, Any]:
        """Create outcome record from vote
        
        Args:
            vote: Vote that was completed
            decision: Final decision made
            implementation_notes: Notes for implementation
            
        Returns:
            Outcome dictionary
        """
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        outcome_hash = hashlib.sha256(f"{vote.vote_id}-outcome".encode()).hexdigest()[:8]
        outcome_id = f"outcome-{timestamp}-{outcome_hash}"
        
        # Calculate final vote counts
        final_round = vote.rounds["results"][-1] if vote.rounds["results"] else {}
        vote_counts = {}
        for proposal in final_round.get("proposals", []):
            vote_id = proposal.get("vote")
            vote_counts[vote_id] = vote_counts.get(vote_id, 0) + 1
        
        outcome = {
            "outcome_id": outcome_id,
            "vote_id": vote.vote_id,
            "project": vote.project,
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "decision": decision,
            "final_vote_count": vote_counts,
            "consensus_level": final_round.get("consensus", "unknown"),
            "planning_rounds": len(vote.rounds["results"]),
            "implementation_notes": implementation_notes
        }
        
        # Save outcome
        outcome_file = self.outcomes_dir / f"{outcome_id}.json"
        with open(outcome_file, 'w') as f:
            json.dump(outcome, f, indent=2)
        
        return outcome
    
    def list_votes(self, status: Optional[str] = None) -> List[Vote]:
        """List all votes
        
        Args:
            status: Optional filter by status (active, completed, cancelled)
            
        Returns:
            List of Vote objects
        """
        votes = []
        
        for vote_file in self.votes_dir.glob("vote-*.json"):
            try:
                with open(vote_file) as f:
                    vote_data = json.load(f)
                    vote = Vote.from_dict(vote_data)
                    
                    if status is None or vote.status == status:
                        votes.append(vote)
            except Exception as e:
                print(f"Warning: Could not load vote {vote_file}: {e}")
        
        return sorted(votes, key=lambda v: v.timestamp, reverse=True)
    
    def get_vote(self, vote_id: str) -> Optional[Vote]:
        """Get a specific vote
        
        Args:
            vote_id: ID of the vote
            
        Returns:
            Vote object or None
        """
        vote_file = self.votes_dir / f"{vote_id}.json"
        
        if not vote_file.exists():
            return None
        
        try:
            with open(vote_file) as f:
                vote_data = json.load(f)
                return Vote.from_dict(vote_data)
        except Exception as e:
            print(f"Error loading vote: {e}")
            return None
