# Publishing Orkestra to PyPI

This guide walks you through publishing the Orkestra package to PyPI.

## Prerequisites

1. **PyPI Account**: Create accounts on:
   - PyPI: https://pypi.org/account/register/
   - TestPyPI: https://test.pypi.org/account/register/

2. **Install Build Tools**:
   ```bash
   pip install --upgrade pip
   pip install --upgrade build twine
   ```

3. **Configure API Token** (Recommended):
   - Go to https://pypi.org/manage/account/token/
   - Create a new API token
   - Save it securely

## Step 1: Prepare the Package

1. **Update Version** (if needed):
   Edit `setup.py` and `pyproject.toml` to update the version number.

2. **Update Email**:
   Replace `contact@example.com` with your actual email in:
   - `setup.py`
   - `pyproject.toml`

3. **Review Files**:
   - `README_PYPI.md` - Main README for PyPI
   - `LICENSE` - Apache 2.0 license
   - `CHANGELOG.md` - Version history

## Step 2: Build the Package

```bash
# Clean previous builds
rm -rf build/ dist/ *.egg-info

# Build the distribution packages
python -m build
```

This creates:
- `dist/orkestra-ai-1.0.0.tar.gz` - Source distribution
- `dist/orkestra_ai-1.0.0-py3-none-any.whl` - Wheel distribution

## Step 3: Test on TestPyPI (Recommended)

Upload to TestPyPI first to verify everything works:

```bash
# Upload to TestPyPI
python -m twine upload --repository testpypi dist/*

# Test installation from TestPyPI
pip install --index-url https://test.pypi.org/simple/ --no-deps orkestra-ai

# Test the CLI
orkestra --version
```

## Step 4: Upload to PyPI

Once tested, upload to the real PyPI:

```bash
# Upload to PyPI
python -m twine upload dist/*
```

You'll be prompted for:
- Username: `__token__`
- Password: Your PyPI API token (starts with `pypi-`)

## Step 5: Verify Installation

```bash
# Install from PyPI
pip install orkestra-ai

# Test the installation
orkestra --version
orkestra --help
```

## Step 6: Create a GitHub Release

1. Go to https://github.com/hendrixx-cnc/Orkestra/releases
2. Click "Draft a new release"
3. Tag: `v1.0.0`
4. Title: `Orkestra v1.0.0 - Initial Release`
5. Description: Copy from CHANGELOG.md
6. Attach the distribution files from `dist/`
7. Publish release

## Configuration for Automated Publishing

### Using GitHub Actions

Create `.github/workflows/publish.yml`:

```yaml
name: Publish to PyPI

on:
  release:
    types: [published]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.x'
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install build twine
    - name: Build package
      run: python -m build
    - name: Publish to PyPI
      env:
        TWINE_USERNAME: __token__
        TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
      run: twine upload dist/*
```

Add your PyPI token to GitHub Secrets as `PYPI_API_TOKEN`.

## Troubleshooting

### "File already exists" Error

If you get this error, the version already exists on PyPI:
1. Update the version number in `setup.py` and `pyproject.toml`
2. Rebuild: `python -m build`
3. Upload again

### Import Errors in Tests

Install the package in development mode:
```bash
pip install -e .
```

### Missing Dependencies

Install all dev dependencies:
```bash
pip install -e ".[dev]"
```

## Post-Publication Checklist

- [ ] Package appears on PyPI: https://pypi.org/project/orkestra-ai/
- [ ] Installation works: `pip install orkestra-ai`
- [ ] CLI works: `orkestra --version`
- [ ] GitHub release created
- [ ] Documentation updated
- [ ] Announcement posted (if desired)

## Updating the Package

For future updates:

1. Make your changes
2. Update version in `setup.py` and `pyproject.toml`
3. Update `CHANGELOG.md`
4. Rebuild and upload:
   ```bash
   rm -rf dist/ build/
   python -m build
   python -m twine upload dist/*
   ```
5. Create GitHub release

## Resources

- PyPI Documentation: https://packaging.python.org/
- Twine Documentation: https://twine.readthedocs.io/
- setuptools Documentation: https://setuptools.pypa.io/
