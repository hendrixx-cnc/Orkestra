"""
Test configuration for Orkestra package
"""

import pytest
from pathlib import Path
import tempfile
import shutil


@pytest.fixture
def temp_project_dir():
    """Create a temporary directory for test projects"""
    temp_dir = tempfile.mkdtemp()
    yield Path(temp_dir)
    shutil.rmtree(temp_dir)


@pytest.fixture
def sample_config():
    """Sample configuration for testing"""
    return {
        "id": "test-project-id",
        "name": "test-project",
        "version": "1.0.0",
        "created": "2025-11-02T00:00:00",
        "template": "standard",
        "status": "inactive"
    }
