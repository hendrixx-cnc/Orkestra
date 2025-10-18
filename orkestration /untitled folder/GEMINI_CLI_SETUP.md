# 🔥 Gemini CLI Integration Setup

## ✅ Status: INSTALLED & READY

The Gemini CLI has been successfully integrated into the AI coordination system!

---

## 📦 What Was Installed

**Gemini CLI Repository:**
- Location: `/workspaces/The-Quantum-Self-/AI/gemini-cli/`
- Version: `0.11.0-nightly.20251015.203bad7c`
- Bundle: `/workspaces/The-Quantum-Self-/AI/gemini-cli/bundle/gemini.js`

**Automation Script:**
- Location: `/workspaces/The-Quantum-Self-/AI/gemini_agent.sh`
- Purpose: Automate Gemini task execution
- Features: Task claiming, execution, completion, Firebase analysis

---

## 🔑 Setup API Key (REQUIRED)

### 1. Get Your Gemini API Key

Visit: https://aistudio.google.com/app/apikey

Click **"Create API Key"** (it's FREE!)

### 2. Set Environment Variable

**Temporary (current session only):**
```bash
export GEMINI_API_KEY="your-api-key-here"
```

**Permanent (add to your shell config):**
```bash
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### 3. Verify Setup

```bash
cd /workspaces/The-Quantum-Self-/AI
bash gemini_agent.sh status
```

If you see ✅ API key configured, you're ready!

---

## 🚀 How to Use

### **1. Execute a Specific Task**

```bash
bash gemini_agent.sh execute 4
```

This will:
- Claim Task #4 for Gemini
- Read input files
- Call Gemini CLI with task context
- Save output to specified file
- Mark task as complete
- Update audit log

### **2. Execute Next Available Task**

```bash
bash gemini_agent.sh next
```

Automatically finds and executes the next task assigned to Gemini.

### **3. Firebase Architecture Analysis**

```bash
bash gemini_agent.sh analyze database_schema.md
```

Get Firebase recommendations based on context file.

### **4. Cost Optimization Analysis**

```bash
bash gemini_agent.sh optimize current_infrastructure.md
```

Analyze costs and get optimization suggestions.

### **5. Ask Gemini a Question**

```bash
bash gemini_agent.sh ask "Should I use Firestore or Firebase Data Connect for this schema?"
```

Get expert Firebase advice directly.

### **6. Check Gemini Status**

```bash
bash gemini_agent.sh status
```

View current status, completed work, and available tasks.

---

## 🎯 Example Workflow

**Scenario: Execute Task #4 (System Test)**

```bash
# 1. Navigate to AI directory
cd /workspaces/The-Quantum-Self-/AI

# 2. Check task queue
bash task_coordinator.sh dashboard

# 3. Execute Task #4 with Gemini CLI
bash gemini_agent.sh execute 4

# 4. Verify completion
cat TEST_GEMINI.txt

# 5. Check audit log
tail -20 task_audit.log
```

**What Happens Automatically:**
1. ✅ Claims Task #4 with file-based locking
2. ✅ Reads `TEST_CHATGPT.txt` (input file)
3. ✅ Builds prompt with task context
4. ✅ Calls Gemini CLI API
5. ✅ Saves response to `TEST_GEMINI.txt`
6. ✅ Marks task complete
7. ✅ Logs to audit trail
8. ✅ Updates status file

---

## 🔥 Advanced Features

### **Custom Prompts**

Create a file with your prompt and pipe it:

```bash
cat << 'EOF' > firebase_question.txt
Analyze this PostgreSQL schema and recommend the best Firebase solution:

Tables:
- users (id, email, created_at)
- reflections (id, user_id, content, timestamp)
- photos (id, reflection_id, url)

Should I use Firestore, Data Connect, or Cloud SQL?
EOF

bash gemini_agent.sh analyze firebase_question.txt
```

### **Batch Task Execution**

Execute all Gemini tasks:

```bash
while true; do
    bash gemini_agent.sh next || break
    sleep 2
done
```

### **Integration with Task Coordinator**

The Gemini agent automatically integrates with the existing coordination system:

```bash
# Task coordinator routes firebase tasks to Gemini
bash task_coordinator.sh balance_workload

# Gemini agent executes them
bash gemini_agent.sh next
```

---

## 📊 What Makes This Powerful

### **1. Full Automation**

No manual copying/pasting prompts. Tasks execute end-to-end automatically.

### **2. Context Awareness**

Gemini receives:
- Task instructions
- Input file contents
- Project context
- Previous AI outputs

### **3. Coordination System Integration**

Works seamlessly with:
- `claim_task_v2.sh` - File-based locking
- `complete_task_v2.sh` - Task completion
- `task_audit.sh` - Event logging
- `task_coordinator.sh` - Load balancing

### **4. Firebase Expertise**

Specialized commands for:
- Architecture analysis
- Cost optimization
- Migration planning
- Service recommendations

---

## 🎓 Gemini CLI Capabilities

The underlying Gemini CLI provides:

**Built-in Tools:**
- ✅ Google Search grounding
- ✅ File operations
- ✅ Shell command execution
- ✅ Web content fetching
- ✅ MCP (Model Context Protocol) support

**Model Features:**
- ✅ Gemini 2.5 Pro (latest)
- ✅ 1M token context window
- ✅ Multimodal (text, images, code)
- ✅ Code execution
- ✅ Function calling

**Free Tier:**
- ✅ 60 requests/min
- ✅ 1,000 requests/day
- ✅ No credit card required

---

## 🔧 Troubleshooting

### **Issue: "GEMINI_API_KEY not set"**

**Solution:**
```bash
export GEMINI_API_KEY="your-key-here"
```

Get key from: https://aistudio.google.com/app/apikey

### **Issue: "Task already claimed"**

**Solution:**
```bash
# Check locks
ls -la /tmp/task_*.lock

# Force unlock if needed
rm /tmp/task_4_gemini.lock
```

### **Issue: Gemini CLI not responding**

**Solution:**
```bash
# Test CLI directly
cd /workspaces/The-Quantum-Self-/AI/gemini-cli
node bundle/gemini.js --version

# Should output: 0.11.0-nightly.20251015.203bad7c
```

### **Issue: Permission denied**

**Solution:**
```bash
chmod +x /workspaces/The-Quantum-Self-/AI/gemini_agent.sh
```

---

## 🎯 Next Steps

### **1. Set up API Key** (REQUIRED)
```bash
export GEMINI_API_KEY="your-key-here"
```

### **2. Test the Integration**
```bash
bash gemini_agent.sh ask "Hello! Can you confirm you're working?"
```

### **3. Execute Task #4**
```bash
bash gemini_agent.sh execute 4
```

### **4. Monitor the Dashboard**
```bash
watch -n 5 'bash task_coordinator.sh dashboard'
```

---

## 📚 Additional Resources

**Gemini CLI Documentation:**
- GitHub: https://github.com/google-gemini/gemini-cli
- Website: https://geminicli.com/docs/

**API Documentation:**
- Get API Key: https://aistudio.google.com/app/apikey
- API Reference: https://ai.google.dev/gemini-api/docs

**Project Documentation:**
- Task Coordination: `AI/TASK_COORDINATION_README.md`
- Gemini Integration: `AI/GEMINI_INTEGRATION.md`
- Gemini Status: `AI/GEMINI_STATUS.md`

---

## 🎉 You're All Set!

Gemini CLI is now fully integrated and ready to automate Firebase architecture tasks!

**Quick Start:**
```bash
export GEMINI_API_KEY="your-key"
bash gemini_agent.sh execute 4
```

**Welcome to automated AI collaboration!** 🚀
