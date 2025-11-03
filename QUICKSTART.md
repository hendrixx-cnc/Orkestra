# Quick Installation & Publishing Guide

## For Users - Installing Orkestra

```bash
# Install from PyPI (once published)
pip install orkestra-ai

# Verify installation
orkestra --version

# Create your first project
orkestra new my-ai-project
cd my-ai-project

# Configure API keys
cp config/api-keys.env.example config/api-keys.env
# Edit config/api-keys.env with your actual keys

# Start Orkestra
orkestra start
```

## For Developers - Publishing to PyPI

### One-Time Setup

1. **Install build tools:**
   ```bash
   pip install --upgrade build twine
   ```

2. **Update your email in:**
   - `setup.py` (line 22)
   - `pyproject.toml` (line 11)

3. **Create PyPI account:**
   - Register at https://pypi.org
   - Generate API token at https://pypi.org/manage/account/token/

### Publishing Steps

```bash
# 1. Clean previous builds
rm -rf build/ dist/ *.egg-info

# 2. Build the package
python -m build

# 3. Test on TestPyPI (optional but recommended)
python -m twine upload --repository testpypi dist/*

# 4. Upload to PyPI
python -m twine upload dist/*
# Username: __token__
# Password: [your-pypi-token]

# 5. Test installation
pip install orkestra-ai
orkestra --version
```

### Quick Test Before Publishing

```bash
# Install in development mode
pip install -e .

# Test CLI
orkestra --version
orkestra --help

# Create test project
orkestra new test-project

# Run tests
pytest
```

## Package Structure Overview

```
Orkestra/
├── src/orkestra/              # Main package
│   ├── __init__.py           # Package init
│   ├── cli.py                # CLI commands
│   ├── core.py               # Core logic
│   ├── config.py             # Configuration
│   └── templates/            # Project templates
│       └── standard/         # Standard template
│           └── scripts/      # Shell scripts
├── tests/                    # Test suite
├── setup.py                  # Setup script
├── pyproject.toml            # Build config
├── MANIFEST.in               # Package data
├── README_PYPI.md            # PyPI README
├── CHANGELOG.md              # Version history
└── LICENSE                   # Apache 2.0

# Files NOT included in package (via .gitignore):
├── config/api-keys.env       # User secrets
├── logs/                     # Runtime logs
└── *.pyc                     # Compiled Python
```

## Common Commands

### Package Management
- `python -m build` - Build package
- `twine check dist/*` - Validate package
- `twine upload dist/*` - Upload to PyPI

### Development
- `pip install -e .` - Install in dev mode
- `pip install -e ".[dev]"` - Install with dev dependencies
- `pytest` - Run tests
- `black src/` - Format code
- `flake8 src/` - Check style

### CLI Usage
- `orkestra new <name>` - Create project
- `orkestra start` - Start system
- `orkestra status` - Check status
- `orkestra list` - List projects
- `orkestra stop` - Stop system

## Troubleshooting

**Import errors after installation?**
```bash
pip install -e .  # Reinstall in development mode
```

**Package build fails?**
```bash
pip install --upgrade setuptools wheel build
```

**Tests fail?**
```bash
pip install -e ".[dev]"  # Install test dependencies
pytest -v  # Run with verbose output
```

**Version already exists on PyPI?**
- Update version in `setup.py` and `pyproject.toml`
- Rebuild: `python -m build`

## Next Steps

1. **Customize** - Update email addresses in setup files
2. **Build** - Run `python -m build`
3. **Test** - Upload to TestPyPI first
4. **Publish** - Upload to PyPI
5. **Verify** - Install and test: `pip install orkestra-ai`
6. **Document** - Update README with any changes
7. **Release** - Create GitHub release with tag

For detailed instructions, see:
- `PUBLISHING.md` - Complete publishing guide
- `CONTRIBUTING.md` - Development guidelines
- `README_PYPI.md` - User documentation
