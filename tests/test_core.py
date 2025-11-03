"""
Tests for Orkestra core functionality
"""

import pytest
from pathlib import Path
from orkestra.core import OrkestraProject


def test_create_project(temp_project_dir):
    """Test creating a new project"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    
    assert project.name == project_name
    assert project.path == project_path
    assert project_path.exists()
    assert (project_path / "config").exists()
    assert (project_path / "scripts").exists()
    assert (project_path / "README.md").exists()


def test_project_config(temp_project_dir):
    """Test project configuration"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    
    assert project.config['name'] == project_name
    assert 'id' in project.config
    assert 'version' in project.config
    assert 'created' in project.config


def test_load_project(temp_project_dir):
    """Test loading an existing project"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    # Create project
    OrkestraProject.create(project_name, project_path)
    
    # Load it
    loaded_project = OrkestraProject.load(project_name)
    
    assert loaded_project.name == project_name
    assert loaded_project.path.name == project_name


def test_project_structure(temp_project_dir):
    """Test that all required directories are created"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    
    required_dirs = [
        "config",
        "config/task-queues",
        "scripts/core",
        "scripts/agents",
        "logs",
        "projects",
    ]
    
    for dir_name in required_dirs:
        assert (project_path / dir_name).exists(), f"Missing directory: {dir_name}"


def test_api_keys_template(temp_project_dir):
    """Test that API keys template is created"""
    project_name = "test-project"
    project_path = temp_project_dir / project_name
    
    project = OrkestraProject.create(project_name, project_path)
    
    api_keys_example = project_path / "config" / "api-keys.env.example"
    assert api_keys_example.exists()
    
    content = api_keys_example.read_text()
    assert "ANTHROPIC_API_KEY" in content
    assert "OPENAI_API_KEY" in content
    assert "GOOGLE_API_KEY" in content
