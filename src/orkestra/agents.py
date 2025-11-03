"""
Orkestra AI Agents

Individual AI agent implementations with API integration.
Replaces bash scripts from SCRIPTS/AGENTS/.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
import json
import os
import asyncio
import logging


@dataclass
class AgentConfig:
    """Configuration for an AI agent"""
    name: str
    api_key: str
    model: str
    temperature: float = 0.7
    max_tokens: int = 4000
    timeout: int = 60
    rate_limit_per_minute: int = 50
    
    @classmethod
    def from_env(cls, agent_name: str) -> 'AgentConfig':
        """
        Load agent config from environment variables
        
        Args:
            agent_name: Name of agent (claude, chatgpt, etc.)
            
        Returns:
            AgentConfig instance
        """
        env_prefix = agent_name.upper()
        
        return cls(
            name=agent_name,
            api_key=os.getenv(f"{env_prefix}_API_KEY", ""),
            model=os.getenv(f"{env_prefix}_MODEL", cls._default_model(agent_name)),
            temperature=float(os.getenv(f"{env_prefix}_TEMPERATURE", "0.7")),
            max_tokens=int(os.getenv(f"{env_prefix}_MAX_TOKENS", "4000")),
            timeout=int(os.getenv(f"{env_prefix}_TIMEOUT", "60")),
            rate_limit_per_minute=int(os.getenv(f"{env_prefix}_RATE_LIMIT", "50"))
        )
    
    @staticmethod
    def _default_model(agent_name: str) -> str:
        """Get default model for agent"""
        defaults = {
            'claude': 'claude-3-5-sonnet-20241022',
            'chatgpt': 'gpt-4o',
            'gemini': 'gemini-1.5-pro',
            'copilot': 'gpt-4',
            'grok': 'grok-beta'
        }
        return defaults.get(agent_name, 'default')


@dataclass
class AgentResponse:
    """Response from an AI agent"""
    agent_name: str
    content: str
    timestamp: datetime
    model: str
    tokens_used: int
    duration: float
    success: bool
    error: Optional[str] = None
    metadata: Dict[str, Any] = None
    
    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class Agent(ABC):
    """Base class for AI agents"""
    
    def __init__(self, config: AgentConfig):
        self.config = config
        self.logger = logging.getLogger(f"orkestra.agent.{config.name}")
        self.call_count = 0
        self.last_call_time: Optional[datetime] = None
        
    @abstractmethod
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """
        Make API call to agent
        
        Args:
            prompt: User prompt
            context: Additional context
            system: System instructions
            
        Returns:
            AgentResponse with result
        """
        pass
    
    @abstractmethod
    def test_connection(self) -> bool:
        """
        Test if API connection works
        
        Returns:
            True if connection successful
        """
        pass
    
    def _log_call(self, prompt: str, response: AgentResponse):
        """Log API call details"""
        self.call_count += 1
        self.last_call_time = datetime.now()
        
        self.logger.info(
            f"Call #{self.call_count} completed in {response.duration:.2f}s, "
            f"tokens: {response.tokens_used}, success: {response.success}"
        )
    
    def _rate_limit_check(self):
        """Check if we're within rate limits"""
        if self.last_call_time:
            time_since_last = (datetime.now() - self.last_call_time).total_seconds()
            min_interval = 60 / self.config.rate_limit_per_minute
            
            if time_since_last < min_interval:
                sleep_time = min_interval - time_since_last
                self.logger.debug(f"Rate limiting: sleeping {sleep_time:.2f}s")
                import time
                time.sleep(sleep_time)


class ClaudeAgent(Agent):
    """Anthropic Claude agent"""
    
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """Call Claude API"""
        start_time = datetime.now()
        
        try:
            import anthropic
            
            self._rate_limit_check()
            
            client = anthropic.Anthropic(api_key=self.config.api_key)
            
            # Combine context and prompt
            full_prompt = f"{context}\n\n{prompt}" if context else prompt
            system_msg = system or "You are a helpful AI assistant working as part of the Orkestra multi-AI system."
            
            message = await asyncio.to_thread(
                client.messages.create,
                model=self.config.model,
                max_tokens=self.config.max_tokens,
                temperature=self.config.temperature,
                system=system_msg,
                messages=[{"role": "user", "content": full_prompt}]
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            response = AgentResponse(
                agent_name=self.config.name,
                content=message.content[0].text,
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=message.usage.input_tokens + message.usage.output_tokens,
                duration=duration,
                success=True,
                metadata={
                    'input_tokens': message.usage.input_tokens,
                    'output_tokens': message.usage.output_tokens,
                    'stop_reason': message.stop_reason
                }
            )
            
            self._log_call(prompt, response)
            return response
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"Claude API error: {e}")
            
            return AgentResponse(
                agent_name=self.config.name,
                content="",
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=0,
                duration=duration,
                success=False,
                error=str(e)
            )
    
    def test_connection(self) -> bool:
        """Test Claude API connection"""
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=self.config.api_key)
            
            # Simple test message
            message = client.messages.create(
                model=self.config.model,
                max_tokens=10,
                messages=[{"role": "user", "content": "test"}]
            )
            
            return True
        except Exception as e:
            self.logger.error(f"Claude connection test failed: {e}")
            return False


class ChatGPTAgent(Agent):
    """OpenAI ChatGPT agent"""
    
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """Call ChatGPT API"""
        start_time = datetime.now()
        
        try:
            import openai
            
            self._rate_limit_check()
            
            client = openai.OpenAI(api_key=self.config.api_key)
            
            # Build messages
            messages = []
            system_msg = system or "You are a helpful AI assistant working as part of the Orkestra multi-AI system."
            messages.append({"role": "system", "content": system_msg})
            
            if context:
                messages.append({"role": "system", "content": f"Context: {context}"})
            
            messages.append({"role": "user", "content": prompt})
            
            response = await asyncio.to_thread(
                client.chat.completions.create,
                model=self.config.model,
                messages=messages,
                temperature=self.config.temperature,
                max_tokens=self.config.max_tokens
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            agent_response = AgentResponse(
                agent_name=self.config.name,
                content=response.choices[0].message.content,
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=response.usage.total_tokens,
                duration=duration,
                success=True,
                metadata={
                    'prompt_tokens': response.usage.prompt_tokens,
                    'completion_tokens': response.usage.completion_tokens,
                    'finish_reason': response.choices[0].finish_reason
                }
            )
            
            self._log_call(prompt, agent_response)
            return agent_response
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"ChatGPT API error: {e}")
            
            return AgentResponse(
                agent_name=self.config.name,
                content="",
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=0,
                duration=duration,
                success=False,
                error=str(e)
            )
    
    def test_connection(self) -> bool:
        """Test ChatGPT API connection"""
        try:
            import openai
            client = openai.OpenAI(api_key=self.config.api_key)
            
            response = client.chat.completions.create(
                model=self.config.model,
                messages=[{"role": "user", "content": "test"}],
                max_tokens=10
            )
            
            return True
        except Exception as e:
            self.logger.error(f"ChatGPT connection test failed: {e}")
            return False


class GeminiAgent(Agent):
    """Google Gemini agent"""
    
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """Call Gemini API"""
        start_time = datetime.now()
        
        try:
            import google.generativeai as genai
            
            self._rate_limit_check()
            
            genai.configure(api_key=self.config.api_key)
            model = genai.GenerativeModel(self.config.model)
            
            # Combine context and prompt
            full_prompt = f"{context}\n\n{prompt}" if context else prompt
            if system:
                full_prompt = f"{system}\n\n{full_prompt}"
            
            response = await asyncio.to_thread(
                model.generate_content,
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=self.config.temperature,
                    max_output_tokens=self.config.max_tokens
                )
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            agent_response = AgentResponse(
                agent_name=self.config.name,
                content=response.text,
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=response.usage_metadata.total_token_count if hasattr(response, 'usage_metadata') else 0,
                duration=duration,
                success=True,
                metadata={
                    'prompt_tokens': response.usage_metadata.prompt_token_count if hasattr(response, 'usage_metadata') else 0,
                    'candidates_count': len(response.candidates) if hasattr(response, 'candidates') else 0
                }
            )
            
            self._log_call(prompt, agent_response)
            return agent_response
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"Gemini API error: {e}")
            
            return AgentResponse(
                agent_name=self.config.name,
                content="",
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=0,
                duration=duration,
                success=False,
                error=str(e)
            )
    
    def test_connection(self) -> bool:
        """Test Gemini API connection"""
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.config.api_key)
            
            model = genai.GenerativeModel(self.config.model)
            response = model.generate_content("test")
            
            return True
        except Exception as e:
            self.logger.error(f"Gemini connection test failed: {e}")
            return False


class CopilotAgent(Agent):
    """GitHub Copilot agent (uses OpenAI endpoint)"""
    
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """Call Copilot API"""
        # Copilot uses similar interface to ChatGPT
        # This is a placeholder - actual GitHub Copilot API may differ
        start_time = datetime.now()
        
        try:
            # For now, fallback to ChatGPT-style API
            import openai
            
            self._rate_limit_check()
            
            client = openai.OpenAI(api_key=self.config.api_key)
            
            messages = []
            system_msg = system or "You are GitHub Copilot, an AI coding assistant working as part of the Orkestra multi-AI system."
            messages.append({"role": "system", "content": system_msg})
            
            if context:
                messages.append({"role": "system", "content": f"Context: {context}"})
            
            messages.append({"role": "user", "content": prompt})
            
            response = await asyncio.to_thread(
                client.chat.completions.create,
                model=self.config.model,
                messages=messages,
                temperature=self.config.temperature,
                max_tokens=self.config.max_tokens
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            agent_response = AgentResponse(
                agent_name=self.config.name,
                content=response.choices[0].message.content,
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=response.usage.total_tokens,
                duration=duration,
                success=True,
                metadata={
                    'prompt_tokens': response.usage.prompt_tokens,
                    'completion_tokens': response.usage.completion_tokens
                }
            )
            
            self._log_call(prompt, agent_response)
            return agent_response
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"Copilot API error: {e}")
            
            return AgentResponse(
                agent_name=self.config.name,
                content="",
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=0,
                duration=duration,
                success=False,
                error=str(e)
            )
    
    def test_connection(self) -> bool:
        """Test Copilot API connection"""
        try:
            import openai
            client = openai.OpenAI(api_key=self.config.api_key)
            
            response = client.chat.completions.create(
                model=self.config.model,
                messages=[{"role": "user", "content": "test"}],
                max_tokens=10
            )
            
            return True
        except Exception as e:
            self.logger.error(f"Copilot connection test failed: {e}")
            return False


class GrokAgent(Agent):
    """xAI Grok agent"""
    
    async def call(self, prompt: str, context: str = "", system: str = "") -> AgentResponse:
        """Call Grok API"""
        start_time = datetime.now()
        
        try:
            # Grok API (placeholder - actual API may differ)
            # Using OpenAI-compatible interface for now
            import openai
            
            self._rate_limit_check()
            
            # xAI uses OpenAI-compatible API
            client = openai.OpenAI(
                api_key=self.config.api_key,
                base_url="https://api.x.ai/v1"
            )
            
            messages = []
            system_msg = system or "You are Grok, a rebellious AI assistant working as part of the Orkestra multi-AI system."
            messages.append({"role": "system", "content": system_msg})
            
            if context:
                messages.append({"role": "system", "content": f"Context: {context}"})
            
            messages.append({"role": "user", "content": prompt})
            
            response = await asyncio.to_thread(
                client.chat.completions.create,
                model=self.config.model,
                messages=messages,
                temperature=self.config.temperature,
                max_tokens=self.config.max_tokens
            )
            
            duration = (datetime.now() - start_time).total_seconds()
            
            agent_response = AgentResponse(
                agent_name=self.config.name,
                content=response.choices[0].message.content,
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=response.usage.total_tokens if hasattr(response.usage, 'total_tokens') else 0,
                duration=duration,
                success=True,
                metadata={
                    'prompt_tokens': getattr(response.usage, 'prompt_tokens', 0),
                    'completion_tokens': getattr(response.usage, 'completion_tokens', 0)
                }
            )
            
            self._log_call(prompt, agent_response)
            return agent_response
            
        except Exception as e:
            duration = (datetime.now() - start_time).total_seconds()
            self.logger.error(f"Grok API error: {e}")
            
            return AgentResponse(
                agent_name=self.config.name,
                content="",
                timestamp=datetime.now(),
                model=self.config.model,
                tokens_used=0,
                duration=duration,
                success=False,
                error=str(e)
            )
    
    def test_connection(self) -> bool:
        """Test Grok API connection"""
        try:
            import openai
            client = openai.OpenAI(
                api_key=self.config.api_key,
                base_url="https://api.x.ai/v1"
            )
            
            response = client.chat.completions.create(
                model=self.config.model,
                messages=[{"role": "user", "content": "test"}],
                max_tokens=10
            )
            
            return True
        except Exception as e:
            self.logger.error(f"Grok connection test failed: {e}")
            return False


class AgentManager:
    """
    Manages all AI agents
    
    Features:
    - Load agents from configuration
    - Route calls to appropriate agent
    - Track agent health and usage
    - Handle failover
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.agents: Dict[str, Agent] = {}
        self.logger = logging.getLogger("orkestra.agents")
        
        self._load_agents()
    
    def _load_agents(self):
        """Load all agent configurations"""
        agent_classes = {
            'claude': ClaudeAgent,
            'chatgpt': ChatGPTAgent,
            'gemini': GeminiAgent,
            'copilot': CopilotAgent,
            'grok': GrokAgent
        }
        
        for agent_name, agent_class in agent_classes.items():
            try:
                config = AgentConfig.from_env(agent_name)
                if config.api_key:
                    self.agents[agent_name] = agent_class(config)
                    self.logger.info(f"Loaded agent: {agent_name}")
                else:
                    self.logger.warning(f"No API key for {agent_name}, skipping")
            except Exception as e:
                self.logger.error(f"Failed to load {agent_name}: {e}")
    
    async def call_agent(
        self,
        agent_name: str,
        prompt: str,
        context: str = "",
        system: str = ""
    ) -> AgentResponse:
        """
        Call a specific agent
        
        Args:
            agent_name: Name of agent to call
            prompt: User prompt
            context: Additional context
            system: System instructions
            
        Returns:
            AgentResponse with result
        """
        if agent_name not in self.agents:
            return AgentResponse(
                agent_name=agent_name,
                content="",
                timestamp=datetime.now(),
                model="",
                tokens_used=0,
                duration=0.0,
                success=False,
                error=f"Agent '{agent_name}' not available"
            )
        
        agent = self.agents[agent_name]
        return await agent.call(prompt, context, system)
    
    async def call_all_agents(
        self,
        prompt: str,
        context: str = "",
        system: str = ""
    ) -> Dict[str, AgentResponse]:
        """
        Call all available agents in parallel
        
        Args:
            prompt: User prompt
            context: Additional context
            system: System instructions
            
        Returns:
            Dict mapping agent names to responses
        """
        tasks = {}
        for agent_name in self.agents:
            tasks[agent_name] = self.call_agent(agent_name, prompt, context, system)
        
        results = {}
        for agent_name, task in tasks.items():
            results[agent_name] = await task
        
        return results
    
    def test_all_connections(self) -> Dict[str, bool]:
        """
        Test all agent connections
        
        Returns:
            Dict mapping agent names to connection status
        """
        results = {}
        for agent_name, agent in self.agents.items():
            self.logger.info(f"Testing {agent_name}...")
            results[agent_name] = agent.test_connection()
        
        return results
    
    def get_agent_stats(self) -> Dict[str, Dict[str, Any]]:
        """
        Get statistics for all agents
        
        Returns:
            Dict with agent statistics
        """
        stats = {}
        for agent_name, agent in self.agents.items():
            stats[agent_name] = {
                'call_count': agent.call_count,
                'last_call': agent.last_call_time.isoformat() if agent.last_call_time else None,
                'model': agent.config.model,
                'available': True
            }
        
        return stats
    
    def get_available_agents(self) -> List[str]:
        """
        Get list of available agent names
        
        Returns:
            List of agent names
        """
        return list(self.agents.keys())


class AgentNotifications:
    """
    Manage agent notifications and alerts
    
    Tracks important events and notifies appropriate agents.
    """
    
    def __init__(self, project_root: Path):
        self.project_root = Path(project_root)
        self.notifications_dir = self.project_root / "orkestra" / "logs" / "notifications"
        self.notifications_dir.mkdir(parents=True, exist_ok=True)
    
    def send_notification(
        self,
        agent_name: str,
        title: str,
        message: str,
        priority: str = "normal"
    ):
        """
        Send notification to agent
        
        Args:
            agent_name: Target agent
            title: Notification title
            message: Notification message
            priority: Priority level (low, normal, high, urgent)
        """
        notification_file = self.notifications_dir / f"{agent_name}_notifications.json"
        
        # Load existing notifications
        if notification_file.exists():
            with open(notification_file) as f:
                notifications = json.load(f)
        else:
            notifications = []
        
        # Add new notification
        notifications.append({
            'timestamp': datetime.now().isoformat(),
            'title': title,
            'message': message,
            'priority': priority,
            'read': False
        })
        
        # Save
        with open(notification_file, 'w') as f:
            json.dump(notifications, f, indent=2)
    
    def get_unread_notifications(self, agent_name: str) -> List[Dict]:
        """
        Get unread notifications for agent
        
        Args:
            agent_name: Agent name
            
        Returns:
            List of unread notifications
        """
        notification_file = self.notifications_dir / f"{agent_name}_notifications.json"
        
        if not notification_file.exists():
            return []
        
        with open(notification_file) as f:
            notifications = json.load(f)
        
        return [n for n in notifications if not n.get('read', False)]
    
    def mark_as_read(self, agent_name: str, notification_index: int):
        """
        Mark notification as read
        
        Args:
            agent_name: Agent name
            notification_index: Index of notification to mark
        """
        notification_file = self.notifications_dir / f"{agent_name}_notifications.json"
        
        if not notification_file.exists():
            return
        
        with open(notification_file) as f:
            notifications = json.load(f)
        
        if 0 <= notification_index < len(notifications):
            notifications[notification_index]['read'] = True
            
            with open(notification_file, 'w') as f:
                json.dump(notifications, f, indent=2)
