"""
Tests for Orkestra CLI
"""

import pytest
from click.testing import CliRunner
from orkestra.cli import main


def test_cli_version():
    """Test CLI version command"""
    runner = CliRunner()
    result = runner.invoke(main, ['--version'])
    assert result.exit_code == 0
    assert '1.0.0' in result.output


def test_cli_help():
    """Test CLI help command"""
    runner = CliRunner()
    result = runner.invoke(main, ['--help'])
    assert result.exit_code == 0
    assert 'Orkestra' in result.output
    assert 'Multi-AI' in result.output


def test_new_project_command(temp_project_dir):
    """Test new project command"""
    runner = CliRunner()
    with runner.isolated_filesystem(temp_dir=temp_project_dir):
        result = runner.invoke(main, ['new', 'test-project'])
        assert result.exit_code == 0
        assert 'created successfully' in result.output


def test_list_command(temp_project_dir):
    """Test list command"""
    runner = CliRunner()
    result = runner.invoke(main, ['list'])
    # Should not error even if no projects exist
    assert result.exit_code == 0


def test_invalid_command():
    """Test invalid command"""
    runner = CliRunner()
    result = runner.invoke(main, ['invalid-command'])
    assert result.exit_code != 0
