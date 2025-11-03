# Contributing to Orkestra

First off, thank you for considering contributing to Orkestra! It's people like you that make Orkestra such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inspiring community for all.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* Use a clear and descriptive title
* Describe the exact steps which reproduce the problem
* Provide specific examples to demonstrate the steps
* Describe the behavior you observed after following the steps
* Explain which behavior you expected to see instead and why
* Include screenshots if possible
* Include your environment details (OS, Python version, Orkestra version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* Use a clear and descriptive title
* Provide a step-by-step description of the suggested enhancement
* Provide specific examples to demonstrate the steps
* Describe the current behavior and explain which behavior you expected to see instead
* Explain why this enhancement would be useful

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Python style guide (PEP 8)
* Include thoughtful comments in your code
* Write tests for your changes
* Document new code
* End all files with a newline

## Development Process

### Setting Up Development Environment

1. **Fork and Clone**
   ```bash
   git clone https://github.com/YOUR-USERNAME/Orkestra.git
   cd Orkestra
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install Development Dependencies**
   ```bash
   pip install -e ".[dev]"
   ```

4. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=orkestra --cov-report=html

# Run specific test
pytest tests/test_core.py -k test_create_project
```

### Code Style

We use several tools to maintain code quality:

```bash
# Format code with Black
black src/orkestra

# Check style with flake8
flake8 src/orkestra

# Type checking with mypy
mypy src/orkestra
```

### Making Changes

1. Make your changes in your feature branch
2. Add or update tests as needed
3. Update documentation if needed
4. Ensure all tests pass
5. Commit your changes with a clear commit message

### Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Example:
```
Add support for custom AI agents

- Implement plugin system for custom agents
- Add documentation for agent plugins
- Add tests for plugin loading

Fixes #123
```

### Submitting Changes

1. Push your changes to your fork
2. Submit a pull request to the main repository
3. Wait for review and address any feedback

## Project Structure

```
Orkestra/
├── src/orkestra/          # Main package source
│   ├── __init__.py       # Package initialization
│   ├── cli.py            # CLI commands
│   ├── core.py           # Core functionality
│   ├── config.py         # Configuration management
│   └── templates/        # Project templates
├── tests/                # Test suite
├── docs/                 # Documentation
├── setup.py              # Package setup
└── pyproject.toml        # Build configuration
```

## Documentation

* Update the README.md if you change functionality
* Add docstrings to new functions and classes
* Update type hints
* Add examples for new features

## Testing Guidelines

* Write unit tests for new features
* Maintain or improve code coverage
* Test edge cases
* Test error handling
* Use descriptive test names

Example test:
```python
def test_create_project_with_custom_template():
    """Test creating a project with a custom template"""
    project = OrkestraProject.create(
        "test-project",
        Path("/tmp/test"),
        template="custom"
    )
    assert project.config['template'] == "custom"
```

## Questions?

Feel free to:
* Open an issue with the "question" label
* Start a discussion on GitHub Discussions
* Contact the maintainers

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

## Recognition

Contributors will be recognized in:
* The project README
* Release notes
* The contributors page on GitHub

Thank you for contributing to Orkestra! 🎼
