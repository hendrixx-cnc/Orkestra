# 🍎 macOS Setup Guide for Orkestra

## The Issue: Externally-Managed Python Environment

macOS (with Homebrew Python) now uses externally-managed environments (PEP 668), which means you can't install packages system-wide. You need to use a **virtual environment**.

---

## ✅ Solution: Use Virtual Environment (Recommended)

### Step 1: Create Virtual Environment

```bash
cd /Users/hendrixx./Desktop/Orkestra
python3 -m venv venv
```

### Step 2: Activate Virtual Environment

```bash
source venv/bin/activate
```

Your prompt should now show `(venv)` at the beginning.

### Step 3: Install Orkestra in Development Mode

```bash
pip install -e .
```

### Step 4: Test It

```bash
orkestra --version
orkestra --help
```

---

## 🎯 Quick Start (All Steps Combined)

```bash
cd /Users/hendrixx./Desktop/Orkestra
python3 -m venv venv
source venv/bin/activate
pip install -e .
orkestra --version
```

---

## 🚀 Using Orkestra

**IMPORTANT:** You must activate the virtual environment before using `orkestra`:

```bash
# Always activate first
source /Users/hendrixx./Desktop/Orkestra/venv/bin/activate

# Now you can use orkestra
orkestra new my-project
cd my-project
orkestra start
```

---

## 💡 Aliases (Optional - Makes Life Easier)

Add to your `~/.zshrc`:

```bash
# Orkestra alias
alias orkestra-activate='source /Users/hendrixx./Desktop/Orkestra/venv/bin/activate'
```

Then reload: `source ~/.zshrc`

Now just type: `orkestra-activate` before using orkestra commands.

---

## 📦 Publishing to PyPI (macOS)

When ready to publish:

```bash
# Activate virtual environment
source venv/bin/activate

# Install build tools
pip install --upgrade build twine

# Build package
python -m build

# Upload to PyPI
python -m twine upload dist/*
```

---

## 🔧 Alternative: Use pipx (Global Installation)

If you want `orkestra` available globally without activating virtual environments:

```bash
# Install pipx
brew install pipx
pipx ensurepath

# Install orkestra globally
cd /Users/hendrixx./Desktop/Orkestra
pipx install -e .

# Now orkestra is available everywhere
orkestra --version
```

---

## ❌ What NOT to Do

Don't use `--break-system-packages` flag - it can break your Homebrew installation!

```bash
# ❌ DON'T DO THIS
pip install --break-system-packages orkestra-ai
```

---

## ✅ Current Status

- ✅ Python 3.13.7 installed via Homebrew
- ✅ Virtual environment created at `/Users/hendrixx./Desktop/Orkestra/venv`
- ✅ Orkestra installed in development mode
- ✅ All dependencies installed (click, rich, pyyaml, jinja2, python-dotenv)
- ✅ CLI working: `orkestra --version` returns `1.0.0`
- ✅ Project creation tested: `orkestra new test-project` works!

---

## 🎓 Understanding the Setup

### Why Virtual Environments?

1. **Isolation** - Each project has its own dependencies
2. **No Conflicts** - Won't break system Python
3. **Clean** - Easy to delete and recreate
4. **Best Practice** - Industry standard

### Where Is Everything?

```
/Users/hendrixx./Desktop/Orkestra/
├── venv/                    ← Virtual environment
│   ├── bin/
│   │   ├── activate         ← Activation script
│   │   ├── python           ← Python in venv
│   │   ├── pip              ← pip in venv
│   │   └── orkestra         ← orkestra CLI
│   └── lib/                 ← Installed packages
├── src/orkestra/            ← Your package source
└── setup.py                 ← Package configuration
```

---

## 📝 Daily Workflow

### Developing Orkestra

```bash
# 1. Activate environment
cd /Users/hendrixx./Desktop/Orkestra
source venv/bin/activate

# 2. Make changes to src/orkestra/*.py

# 3. Test immediately (no reinstall needed with -e flag)
orkestra new test-project

# 4. Deactivate when done
deactivate
```

### Using Orkestra to Create Projects

```bash
# 1. Activate
source /Users/hendrixx./Desktop/Orkestra/venv/bin/activate

# 2. Create project
orkestra new my-ai-project
cd my-ai-project

# 3. Configure
cp config/api-keys.env.example config/api-keys.env
# Edit config/api-keys.env

# 4. Start
orkestra start
```

---

## 🐛 Troubleshooting

### "orkestra: command not found"

**Solution:** Activate the virtual environment first:
```bash
source /Users/hendrixx./Desktop/Orkestra/venv/bin/activate
```

### "pip: command not found"

**Solution:** Use `python3 -m pip` instead:
```bash
python3 -m pip install -e .
```

Or activate virtual environment where pip is available.

### Want to start fresh?

```bash
# Remove virtual environment
rm -rf venv

# Recreate
python3 -m venv venv
source venv/bin/activate
pip install -e .
```

---

## ✨ You're All Set!

Your Orkestra package is working perfectly on macOS! 

**Next steps:**
1. Read `START_HERE.md` for publishing to PyPI
2. Try creating more test projects
3. Update your email in `setup.py` before publishing

**Current working commands:**
```bash
source venv/bin/activate     # Always do this first
orkestra --version           # ✅ Works!
orkestra new test-project    # ✅ Works!
orkestra --help              # ✅ Works!
```
