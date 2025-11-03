"""
Orkestra Configuration Management
"""

import os
from pathlib import Path
from typing import Dict, Any, Optional
import json
from dotenv import load_dotenv


class OrkestraConfig:
    """Configuration manager for Orkestra projects"""
    
    def __init__(self, project_path: Path):
        self.project_path = Path(project_path)
        self.config_dir = self.project_path / "config"
        self.api_keys_file = self.config_dir / "api-keys.env"
        self._config: Dict[str, Any] = {}
        self._load_config()
    
    def _load_config(self):
        """Load configuration from files"""
        # Load API keys
        if self.api_keys_file.exists():
            load_dotenv(self.api_keys_file)
        
        # Load project config
        project_config_file = self.config_dir / "project.json"
        if project_config_file.exists():
            with open(project_config_file) as f:
                self._config = json.load(f)
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value"""
        # Check environment variables first
        env_value = os.getenv(key)
        if env_value is not None:
            return env_value
        
        # Check config dict
        return self._config.get(key, default)
    
    def set(self, key: str, value: Any):
        """Set configuration value"""
        self._config[key] = value
    
    def save(self):
        """Save configuration to file"""
        project_config_file = self.config_dir / "project.json"
        with open(project_config_file, 'w') as f:
            json.dump(self._config, f, indent=2)
    
    @property
    def api_keys(self) -> Dict[str, Optional[str]]:
        """Get all API keys"""
        return {
            'anthropic': os.getenv('ANTHROPIC_API_KEY'),
            'openai': os.getenv('OPENAI_API_KEY'),
            'google': os.getenv('GOOGLE_API_KEY'),
            'github': os.getenv('GITHUB_TOKEN'),
            'xai': os.getenv('XAI_API_KEY'),
        }
    
    def validate_api_keys(self) -> Dict[str, bool]:
        """Validate that API keys are set"""
        keys = self.api_keys
        return {
            name: bool(key and key != f"your-{name}-api-key-here")
            for name, key in keys.items()
        }
