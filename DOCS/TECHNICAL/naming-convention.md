# Naming Convention Rule - All Lowercase

## 📜 Rule Summary
**ALL AI names, identifiers, and file references MUST be lowercase. NO EXCEPTIONS.**

## 🎯 Purpose
Prevent case-sensitivity bugs where "Claude" ≠ "claude" causes:
- Tasks not being claimed
- Infinite loops searching for assignments
- Mismatched comparisons
- Failed automation

## ✅ Correct Format
```json
"assigned_to": "claude"
"assigned_to": "chatgpt"  
"assigned_to": "gemini"
"assigned_to": "grok"
"assigned_to": "copilot"
```

## ❌ Incorrect Format (FORBIDDEN)
```json
"assigned_to": "Claude"     // WRONG
"assigned_to": "ChatGPT"    // WRONG
"assigned_to": "Gemini"     // WRONG
"assigned_to": "Grok"       // WRONG
"assigned_to": "Copilot"    // WRONG
```

## 🔧 Tools

### Check Compliance
```bash
cd /workspaces/The-Quantum-Self-/AI
bash validation/naming_convention_checker.sh
```

### Auto-Fix Violations
```bash
cd /workspaces/The-Quantum-Self-/AI
bash validation/naming_convention_fixer.sh
```

## 🤖 Automated Enforcement
The naming convention is automatically checked and fixed by:

1. **consistency_checker.sh** - Runs Check #11 for naming violations
2. **naming_convention_fixer.sh** - Auto-fixes any violations found
3. **Pre-Task Validation** - Scripts normalize names before comparison

## 📋 What Gets Checked
1. ✅ `assigned_to` field in all tasks
2. ✅ `ai_agents[].name` array
3. ✅ `review_rotation` keys and values
4. ✅ Log file names
5. ✅ Status file names

## 🛡️ Enforcement Points
- Pre-commit hooks (future)
- Consistency checker (runs automatically)
- Agent scripts (normalize before comparison)
- Task creation (validate on insert)

## 📖 Reference
See `SYSTEM_RULES.md` Section: "🔤 NAMING CONVENTION RULES (MANDATORY)"

---

**Last Updated:** 2025-10-18  
**Status:** ✅ Enforced & Automated
