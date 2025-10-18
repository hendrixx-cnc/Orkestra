# OrKeStra Project Memory - Critical Information

## CURRENT STATUS (October 18, 2025)
- **Project**: The Quantum Self (personal development app/workbook)
- **AI System**: OrKeStra (multi-AI orchestration platform)
- **Location**: /workspaces/The-Quantum-Self-/AI/
- **Tasks**: 25 total in TASK_QUEUE.json

## IMMEDIATE ISSUES TO FIX
1. **Task #14 stuck "in_progress"** - needs reset
2. **Case sensitivity bug** in claim_task_v2.sh (chatgpt vs ChatGPT)
3. **Cache/memory slowdown** - system running slowly
4. **Apple Watch task** at /workspaces/quantum-workbook-standalone/APPLE_WATCH_APP_TASK_LIST.md

## AI AGENTS (4-AI System)
- **Claude**: Content & UX, reviews ChatGPT's work
- **ChatGPT**: Content creation, reviews Grok's work  
- **Grok**: Design & research, reviews Gemini's work
- **Gemini**: Firebase/cloud, reviews Claude's work
- **Copilot/Human**: Project management (excluded from peer review)

## COMPLETED WORK
- ✅ Task #21: Grok created 3 core SVG icons (atom, molecule, electron-cloud)
- ✅ Safety system with pre/post validation
- ✅ Peer review round-robin system
- ✅ Path consistency fixes (9 scripts corrected)

## KEY FILES
- `/AI/TASK_QUEUE.json` - Single source of truth
- `/AI/orchestrator.sh` - Main conductor
- `/AI/validation/*.sh` - Safety systems
- `/AI/SYSTEM_RULES.md` - Complete rulebook
- `/AI/dashboard.html` - Visual progress tracker

## API KEYS NEEDED
- OPENAI_API_KEY (ChatGPT)
- ANTHROPIC_API_KEY (Claude) 
- XAI_API_KEY (Grok)
- GEMINI_API_KEY (Gemini)

## COMMANDS TO START
```bash
cd /workspaces/The-Quantum-Self-/AI
bash validation/consistency_checker.sh  # Check health
bash orchestrator.sh dashboard          # View status
bash chatgpt_auto_executor.sh once      # Test single AI
bash orchestrator.sh automate all       # Start all AIs
```

## RESET COMMANDS (If Stuck)
```bash
# Reset stuck task
jq '.queue = [.queue[] | if .id == 14 then .status = "pending" else . end]' TASK_QUEUE.json > /tmp/reset.json && mv /tmp/reset.json TASK_QUEUE.json

# Clean locks
bash task_lock.sh clean

# Stop all processes
pkill -f "auto_executor\|orchestrator"
```

## APPLE WATCH TASK
- New task location: /workspaces/quantum-workbook-standalone/APPLE_WATCH_APP_TASK_LIST.md
- Assign to appropriate AI based on content

## NEXT FEATURES TO BUILD
1. Exponential backoff & circuit breakers
2. Auto-failover between AIs  
3. AI collaboration protocol
4. Visual workflow builder planning

## PROJECT VISION
- Personal development app using quantum physics metaphors
- 7 modules: observation, superposition, collapse, quantum eraser, retrocausality, entanglement, decoherence
- QR code integration, journal prompts, social features
- Color scheme: Purple (#5B21B6), Cyan (#0891B2), Gold (#F59E0B)

## CRITICAL RULES
- All scripts use /AI/TASK_QUEUE.json (not ../TASK_QUEUE.json)
- Case-insensitive AI name matching
- Pre-validate every task execution
- Round-robin peer review (4 AIs in circle)
- Never infinite loop on failures

*Save this file as project memory reference*
*Created: October 18, 2025*