"""
Tests for Orkestra configuration
"""

import pytest
from pathlib import Path
from orkestra.config import OrkestraConfig
from orkestra.core import OrkestraProject


def test_config_initialization(temp_project_dir):
    """Test configuration initialization"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    config = OrkestraConfig(project_path)
    
    assert config.project_path == project_path
    assert config.config_dir.exists()


def test_config_get_set(temp_project_dir):
    """Test getting and setting config values"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    config = OrkestraConfig(project_path)
    
    config.set('test_key', 'test_value')
    assert config.get('test_key') == 'test_value'
    assert config.get('nonexistent', 'default') == 'default'


def test_api_keys_property(temp_project_dir):
    """Test API keys property"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    config = OrkestraConfig(project_path)
    
    keys = config.api_keys
    assert 'anthropic' in keys
    assert 'openai' in keys
    assert 'google' in keys
    assert 'github' in keys
    assert 'xai' in keys
