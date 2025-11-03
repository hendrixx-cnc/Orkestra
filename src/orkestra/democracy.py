"""
Democracy Engine for Orkestra
==============================

Implements the democratic voting and consensus system for AI agents.
Integrates with the context management system for complete history tracking.

Features:
- Weighted voting based on agent expertise domains
- Ethical framework enforcement
- Multiple consensus thresholds
- Vote history and auditing
- Integration with context manager
"""

import json
import hashlib
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional, Dict, List, Any, Tuple
from dataclasses import dataclass, field, asdict
from enum import Enum

from .context import ContextManager, ContextEventType


class VoteType(Enum):
    """Types of votes"""
    SIMPLE = "simple"                    # Simple majority
    SUPERMAJORITY = "supermajority"      # 75% threshold
    UNANIMOUS = "unanimous"              # 100% agreement
    WEIGHTED = "weighted"                # Domain-weighted
    RANKED_CHOICE = "ranked_choice"      # Preferential voting


class ConsensusLevel(Enum):
    """Consensus achievement levels"""
    UNANIMOUS = "unanimous"          # 100% agreement
    STRONG = "strong"                # 80%+ agreement
    MAJORITY = "majority"            # 60%+ agreement
    SPLIT = "split"                  # <60% agreement
    FAILED = "failed"                # No consensus possible


@dataclass
class VoteOption:
    """A voting option"""
    option_id: str
    description: str
    proposed_by: Optional[str] = None
    votes: List[str] = field(default_factory=list)
    reasoning: Dict[str, str] = field(default_factory=dict)
    weighted_score: float = 0.0


@dataclass
class DemocraticVote:
    """A democratic vote session"""
    vote_id: str
    vote_type: VoteType
    title: str
    description: str
    domain: str  # For weighted voting
    options: List[VoteOption]
    
    # Ethical context
    ethical_principles: List[str]
    
    # Voting parameters
    threshold: float  # 0.0 to 1.0
    weights: Dict[str, float]  # Agent name -> weight
    deadline: str
    
    # State
    status: str  # "open", "closed", "completed"
    created_at: str
    closed_at: Optional[str] = None
    
    # Results
    consensus_level: Optional[ConsensusLevel] = None
    winning_option: Optional[str] = None
    final_scores: Dict[str, float] = field(default_factory=dict)
    
    # Metadata
    metadata: Dict[str, Any] = field(default_factory=dict)


class DemocracyEngine:
    """Democratic voting and consensus system"""
    
    # Domain-specific expertise weights
    DOMAIN_WEIGHTS = {
        "architecture": {"claude": 2.0, "copilot": 1.5, "gemini": 1.5, "grok": 1.0, "chatgpt": 1.0},
        "design": {"claude": 2.0, "copilot": 1.5, "gemini": 1.5, "grok": 1.0, "chatgpt": 1.0},
        "ux": {"claude": 2.0, "copilot": 1.5, "gemini": 1.5, "grok": 1.0, "chatgpt": 1.0},
        "content": {"chatgpt": 2.0, "claude": 1.5, "grok": 1.0, "gemini": 0.5, "copilot": 0.5},
        "writing": {"chatgpt": 2.0, "claude": 1.5, "grok": 1.0, "gemini": 0.5, "copilot": 0.5},
        "marketing": {"chatgpt": 2.0, "claude": 1.5, "grok": 1.0, "gemini": 0.5, "copilot": 0.5},
        "cloud": {"gemini": 2.0, "claude": 1.5, "copilot": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "database": {"gemini": 2.0, "claude": 1.5, "copilot": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "firebase": {"gemini": 2.0, "claude": 1.5, "copilot": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "innovation": {"grok": 2.0, "claude": 1.5, "chatgpt": 1.0, "gemini": 1.0, "copilot": 1.0},
        "research": {"grok": 2.0, "claude": 1.5, "chatgpt": 1.0, "gemini": 1.0, "copilot": 1.0},
        "analysis": {"grok": 2.0, "claude": 1.5, "chatgpt": 1.0, "gemini": 1.0, "copilot": 1.0},
        "deployment": {"copilot": 2.0, "gemini": 1.5, "claude": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "code": {"copilot": 2.0, "gemini": 1.5, "claude": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "devops": {"copilot": 2.0, "gemini": 1.5, "claude": 1.0, "grok": 1.0, "chatgpt": 0.5},
        "general": {"claude": 1.0, "chatgpt": 1.0, "gemini": 1.0, "grok": 1.0, "copilot": 1.0},
    }
    
    # Ethical principles that govern all decisions
    ETHICAL_PRINCIPLES = [
        "Do not lie",
        "Protect life",
        "Respect privacy",
        "Promote fairness",
        "Ensure transparency",
        "Foster collaboration",
        "Minimize harm",
        "Maximize benefit"
    ]
    
    def __init__(self, project_root: Path, context_manager: Optional[ContextManager] = None):
        self.project_root = Path(project_root)
        self.votes_dir = self.project_root / "orkestra" / "logs" / "voting"
        self.votes_dir.mkdir(parents=True, exist_ok=True)
        
        # Context integration
        self.context = context_manager or ContextManager(project_root)
    
    def _timestamp(self) -> str:
        """Generate ISO timestamp"""
        return datetime.now(timezone.utc).isoformat()
    
    def _generate_vote_id(self) -> str:
        """Generate unique vote ID"""
        data = f"{self._timestamp()}{self.context.context.context_version}"
        return f"vote_{hashlib.md5(data.encode()).hexdigest()[:12]}"
    
    def get_weights_for_domain(self, domain: str) -> Dict[str, float]:
        """Get expertise weights for a domain"""
        return self.DOMAIN_WEIGHTS.get(domain.lower(), self.DOMAIN_WEIGHTS["general"])
    
    def create_vote(
        self,
        title: str,
        description: str,
        options: List[str],
        vote_type: VoteType = VoteType.WEIGHTED,
        domain: str = "general",
        threshold: float = 0.5,
        deadline_hours: int = 1,
        proposed_by: Optional[str] = None
    ) -> str:
        """
        Create a new democratic vote.
        
        Args:
            title: Vote title
            description: Detailed description
            options: List of voting options
            vote_type: Type of vote (simple, weighted, etc.)
            domain: Domain for expertise weighting
            threshold: Consensus threshold (0.0 to 1.0)
            deadline_hours: Hours until vote closes
            proposed_by: Agent who proposed the vote
            
        Returns:
            vote_id: Unique identifier for the vote
        """
        vote_id = self._generate_vote_id()
        
        # Create vote options
        vote_options = []
        for i, opt in enumerate(options):
            vote_options.append(VoteOption(
                option_id=f"option_{i+1}",
                description=opt,
                proposed_by=proposed_by
            ))
        
        # Get weights for domain
        weights = self.get_weights_for_domain(domain)
        
        # Create deadline
        deadline = datetime.now(timezone.utc) + timedelta(hours=deadline_hours)
        
        # Create vote
        vote = DemocraticVote(
            vote_id=vote_id,
            vote_type=vote_type,
            title=title,
            description=description,
            domain=domain,
            options=vote_options,
            ethical_principles=self.ETHICAL_PRINCIPLES,
            threshold=threshold,
            weights=weights,
            deadline=deadline.isoformat(),
            status="open",
            created_at=self._timestamp()
        )
        
        # Save vote
        self._save_vote(vote)
        
        # Update context
        if vote_id not in self.context.context.active_votes:
            self.context.context.active_votes.append(vote_id)
        
        self.context.log_event(
            event_type=ContextEventType.VOTE_CREATED,
            agent_name=proposed_by,
            description=f"Vote created: {title}",
            details={
                "vote_id": vote_id,
                "vote_type": vote_type.value,
                "domain": domain,
                "options": options,
                "threshold": threshold
            },
            related_votes=[vote_id],
            impact_level="medium"
        )
        
        return vote_id
    
    def _save_vote(self, vote: DemocraticVote):
        """Save vote to disk"""
        vote_file = self.votes_dir / f"{vote.vote_id}.json"
        
        # Convert to dict
        data = asdict(vote)
        data['vote_type'] = vote.vote_type.value
        if vote.consensus_level:
            data['consensus_level'] = vote.consensus_level.value
        
        with open(vote_file, 'w') as f:
            json.dump(data, f, indent=2)
    
    def _load_vote(self, vote_id: str) -> Optional[DemocraticVote]:
        """Load vote from disk"""
        vote_file = self.votes_dir / f"{vote_id}.json"
        
        if not vote_file.exists():
            return None
        
        with open(vote_file, 'r') as f:
            data = json.load(f)
        
        # Convert back to objects
        data['vote_type'] = VoteType(data['vote_type'])
        if data.get('consensus_level'):
            data['consensus_level'] = ConsensusLevel(data['consensus_level'])
        
        # Convert options
        options = []
        for opt_dict in data['options']:
            options.append(VoteOption(**opt_dict))
        data['options'] = options
        
        return DemocraticVote(**data)
    
    def cast_vote(
        self,
        vote_id: str,
        agent_name: str,
        option_id: str,
        reasoning: str
    ) -> bool:
        """
        Cast a vote from an agent.
        
        Args:
            vote_id: Vote identifier
            agent_name: Agent casting the vote
            option_id: Selected option
            reasoning: Agent's reasoning
            
        Returns:
            bool: Success status
        """
        vote = self._load_vote(vote_id)
        if not vote:
            return False
        
        if vote.status != "open":
            return False
        
        # Find option
        option = None
        for opt in vote.options:
            if opt.option_id == option_id:
                option = opt
                break
        
        if not option:
            return False
        
        # Remove agent from other options
        for opt in vote.options:
            if agent_name in opt.votes:
                opt.votes.remove(agent_name)
            if agent_name in opt.reasoning:
                del opt.reasoning[agent_name]
        
        # Add vote
        if agent_name not in option.votes:
            option.votes.append(agent_name)
        option.reasoning[agent_name] = reasoning
        
        # Calculate weighted score
        self._calculate_scores(vote)
        
        # Save
        self._save_vote(vote)
        
        # Update agent understanding
        self.context.update_agent_understanding(
            agent_name=agent_name,
            understanding=f"Voted on: {vote.title} - Selected: {option.description}",
            concerns=[],
            suggestions=[reasoning]
        )
        
        return True
    
    def _calculate_scores(self, vote: DemocraticVote):
        """Calculate weighted scores for vote options"""
        total_weight = sum(vote.weights.values())
        
        for option in vote.options:
            # Calculate weighted score
            weighted_sum = sum(vote.weights.get(agent, 1.0) for agent in option.votes)
            option.weighted_score = weighted_sum / total_weight if total_weight > 0 else 0.0
        
        # Update final scores
        vote.final_scores = {
            opt.option_id: opt.weighted_score for opt in vote.options
        }
    
    def close_vote(self, vote_id: str) -> Dict[str, Any]:
        """
        Close a vote and determine results.
        
        Returns:
            dict with keys:
            - consensus_level: ConsensusLevel enum
            - winning_option: Winning option ID
            - scores: Final scores
            - details: Additional details
        """
        vote = self._load_vote(vote_id)
        if not vote:
            return {"error": "Vote not found"}
        
        if vote.status != "open":
            return {"error": "Vote already closed"}
        
        # Calculate final scores
        self._calculate_scores(vote)
        
        # Determine winner
        if not vote.options:
            vote.status = "closed"
            vote.consensus_level = ConsensusLevel.FAILED
            self._save_vote(vote)
            return {"error": "No options available"}
        
        # Sort by score
        sorted_options = sorted(vote.options, key=lambda x: x.weighted_score, reverse=True)
        winner = sorted_options[0]
        
        # Determine consensus level
        if winner.weighted_score >= 0.95:
            consensus = ConsensusLevel.UNANIMOUS
        elif winner.weighted_score >= 0.80:
            consensus = ConsensusLevel.STRONG
        elif winner.weighted_score >= 0.60:
            consensus = ConsensusLevel.MAJORITY
        elif winner.weighted_score >= vote.threshold:
            consensus = ConsensusLevel.SPLIT
        else:
            consensus = ConsensusLevel.FAILED
        
        # Update vote
        vote.status = "completed"
        vote.closed_at = self._timestamp()
        vote.consensus_level = consensus
        vote.winning_option = winner.option_id
        
        self._save_vote(vote)
        
        # Update context
        if vote_id in self.context.context.active_votes:
            self.context.context.active_votes.remove(vote_id)
        if vote_id not in self.context.context.completed_votes:
            self.context.context.completed_votes.append(vote_id)
        
        # Record decision
        self.context.record_decision(
            title=vote.title,
            decision=winner.description,
            reasoning="; ".join([
                f"{agent}: {reason}" 
                for agent, reason in winner.reasoning.items()
            ]),
            vote_id=vote_id,
            agents_involved=winner.votes
        )
        
        # Log event
        self.context.log_event(
            event_type=ContextEventType.VOTE_COMPLETED,
            description=f"Vote completed: {vote.title}",
            details={
                "vote_id": vote_id,
                "winner": winner.description,
                "consensus": consensus.value,
                "score": winner.weighted_score
            },
            related_votes=[vote_id],
            impact_level="high"
        )
        
        return {
            "vote_id": vote_id,
            "consensus_level": consensus,
            "winning_option": winner.option_id,
            "winning_description": winner.description,
            "score": winner.weighted_score,
            "votes": winner.votes,
            "reasoning": winner.reasoning,
            "all_scores": vote.final_scores
        }
    
    def get_vote_status(self, vote_id: str) -> Optional[Dict[str, Any]]:
        """Get current vote status"""
        vote = self._load_vote(vote_id)
        if not vote:
            return None
        
        return {
            "vote_id": vote.vote_id,
            "title": vote.title,
            "status": vote.status,
            "type": vote.vote_type.value,
            "domain": vote.domain,
            "deadline": vote.deadline,
            "options": [
                {
                    "id": opt.option_id,
                    "description": opt.description,
                    "votes": opt.votes,
                    "score": opt.weighted_score
                }
                for opt in vote.options
            ],
            "consensus_level": vote.consensus_level.value if vote.consensus_level else None,
            "winning_option": vote.winning_option
        }
    
    def list_active_votes(self) -> List[Dict[str, Any]]:
        """List all active votes"""
        active = []
        for vote_id in self.context.context.active_votes:
            status = self.get_vote_status(vote_id)
            if status:
                active.append(status)
        return active
    
    def get_agent_pending_votes(self, agent_name: str) -> List[Dict[str, Any]]:
        """Get votes that agent hasn't voted on yet"""
        pending = []
        
        for vote_id in self.context.context.active_votes:
            vote = self._load_vote(vote_id)
            if not vote:
                continue
            
            # Check if agent has voted
            has_voted = any(agent_name in opt.votes for opt in vote.options)
            
            if not has_voted:
                pending.append({
                    "vote_id": vote.vote_id,
                    "title": vote.title,
                    "description": vote.description,
                    "domain": vote.domain,
                    "deadline": vote.deadline,
                    "options": [
                        {
                            "id": opt.option_id,
                            "description": opt.description
                        }
                        for opt in vote.options
                    ]
                })
        
        return pending
    
    def check_expired_votes(self) -> List[str]:
        """Check for expired votes and close them"""
        now = datetime.now(timezone.utc)
        expired = []
        
        for vote_id in self.context.context.active_votes.copy():
            vote = self._load_vote(vote_id)
            if not vote:
                continue
            
            deadline = datetime.fromisoformat(vote.deadline.replace('Z', '+00:00'))
            if now > deadline:
                self.close_vote(vote_id)
                expired.append(vote_id)
        
        return expired
