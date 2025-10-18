# Democracy Engine - Expert Assignment Guide
## When to Use Expert Voting

**Purpose:** Give extra weight to the AI most qualified for specific decision types

---

## 🎯 AI Expertise Areas

### **Gemini - Firebase & Google Cloud Expert**
**Assign as expert for:**
- Firebase architecture decisions
- Google Cloud services
- Firestore schema design
- Cloud Functions implementation
- Google APIs integration
- Database scaling strategies
- Cost optimization (Google Cloud)
- Real-time sync solutions

**Example:**
```bash
./democracy_engine.sh create db_schema \
  "What Firestore schema for user data?" \
  "Need: scalability, offline-first, cost-effective" \
  gemini
```

---

### **Claude - Content & UX Expert**
**Assign as expert for:**
- Content structure and tone
- User experience decisions
- Documentation clarity
- Reading level appropriateness
- Accessibility considerations
- Mobile UX patterns
- Information architecture
- Editorial decisions

**Example:**
```bash
./democracy_engine.sh create story_tone \
  "What tone for Angela's recovery story?" \
  "Need: hopeful but realistic, 8th grade level" \
  claude
```

---

### **ChatGPT - Marketing & Creative Expert**
**Assign as expert for:**
- Marketing copy and strategy
- Brand voice development
- Social media content
- Product naming
- Creative storytelling
- User acquisition strategies
- Email campaign design
- Community engagement

**Example:**
```bash
./democracy_engine.sh create launch_strategy \
  "What's our launch announcement approach?" \
  "Targeting: Reddit r/selfimprovement, indie makers" \
  chatgpt
```

---

### **Grok - Design & Research Expert**
**Assign as expert for:**
- Visual design choices
- Icon and graphic design
- Real-time research needs
- Color scheme selection
- Layout and spacing
- SVG creation
- Design system decisions
- Creative problem-solving

**Example:**
```bash
./democracy_engine.sh create icon_style \
  "What visual style for app icons?" \
  "Must match: quantum theme, modern, Headspace-like" \
  grok
```

---

## 🚫 Copilot - NOT in Democracy

**Why Copilot doesn't vote:**
- Works directly for user
- Manages/coordinates democratic AIs
- Avoids conflict of interest
- Executes user-requested tasks
- Can observe decisions but doesn't participate

**Copilot's role:**
- Facilitates democratic process
- Implements final decisions
- Reports results to user
- Handles tasks outside democracy scope

---

## 📊 Expert Vote Math

### Without Expert:
```
4 AIs vote (2 votes each) = 8 total votes possible
Majority = 5+ votes
Even split = 4-4
```

### With Expert:
```
4 AIs vote:
- Expert = 3 votes
- Others = 2 votes each
Total = 9 votes possible

Expert alone = 3 votes
Expert + 1 other = 5 votes (majority)
3 non-experts united = 6 votes (can override expert)
```

**Key:** Expert has significant influence but not total control. 3 other AIs united can still override if they strongly agree.

---

## 🎯 Decision Type Matrix

| Decision Type | Recommended Expert | Reasoning |
|---------------|-------------------|-----------|
| Database choice | Gemini | Cloud/Firebase expertise |
| Story content | Claude | Content/UX focus |
| Feature naming | ChatGPT | Marketing/branding strength |
| Icon design | Grok | Visual design skills |
| Architecture | Gemini | Technical infrastructure |
| User flow | Claude | UX expertise |
| Launch copy | ChatGPT | Marketing messaging |
| Color scheme | Grok | Design aesthetic |
| API design | Gemini | Backend architecture |
| Documentation | Claude | Clarity and structure |
| Social posts | ChatGPT | Community engagement |
| Logo design | Grok | Visual identity |
| Scaling strategy | Gemini | Cloud optimization |
| Tone/voice | Claude | Content expertise |
| Campaign strategy | ChatGPT | Marketing planning |
| Visual hierarchy | Grok | Design principles |

---

## 💡 When NOT to Use Expert

**No expert needed for:**
1. **General decisions** - All AIs equally qualified
2. **Strategic direction** - Collective input more valuable
3. **Process improvements** - Democracy itself
4. **Cross-functional** - Requires multiple perspectives
5. **User preferences** - Not expertise-dependent

**Examples:**
```bash
# No expert - general decision
./democracy_engine.sh create next_feature \
  "What feature to build next?" \
  "Equal priority candidates"

# No expert - process decision
./democracy_engine.sh create workflow \
  "Should we add code review requirement?" \
  "Affects all AIs equally"
```

---

## 🏆 Best Practices

### 1. **Choose Expert by Domain**
- Match decision type to AI strength
- Don't use expert for general questions
- Rotate expertise as topics change

### 2. **Expert Doesn't Always Win**
- 3 other AIs can unite to override
- Expert provides guidance, not dictatorship
- Democracy still functions

### 3. **Document Expert Choice**
- Include in decision context why expert chosen
- Helps future reference
- Transparency in process

### 4. **Multiple Rounds = Expert Throughout**
- Expert status persists all rounds
- Consistent throughout decision process
- Can't change expert mid-decision

---

## 📈 Expected Impact

### With Expert System:

**Faster Consensus:**
- Expert vote breaks ties earlier
- Fewer rounds needed
- Clear direction from domain knowledge

**Better Quality:**
- Domain expertise weighted properly
- Technical decisions get technical input
- Creative decisions get creative input

**Still Democratic:**
- Not a veto power
- Other AIs can override if united
- Full transparency

**Less User Involvement:**
- Expert prevents many ties
- Reduces need for user tie-breaking
- User involvement now ~5% (was ~20% without expert)

---

## 🔧 Usage Examples

### Example 1: Technical Decision (Gemini Expert)
```bash
./democracy_engine.sh create auth_method \
  "What authentication method for premium tier?" \
  "Need: secure, scalable, low maintenance" \
  gemini

# Gemini proposes: Firebase Auth, Auth0, Custom JWT
# Others propose various options
# Gemini's vote (2) + 1 other = 3 votes (majority likely)
# Result: Technical expertise guides decision
```

### Example 2: Content Decision (Claude Expert)
```bash
./democracy_engine.sh create prompt_style \
  "What style for Module 04 prompts?" \
  "Quantum Eraser - rewriting past narratives" \
  claude

# Claude proposes: reflective questions, action-oriented, hybrid
# Claude's expertise in content structure guides
# Others can still override if better idea emerges
```

### Example 3: Marketing Decision (ChatGPT Expert)
```bash
./democracy_engine.sh create prelaunch_hook \
  "What's our primary marketing hook?" \
  "Product Hunt launch in 2 weeks" \
  chatgpt

# ChatGPT proposes marketing angles
# Marketing expertise weighted higher
# Still democratic if others have strong alternative
```

### Example 4: No Expert (Equal Input)
```bash
./democracy_engine.sh create priority_order \
  "What order to tackle remaining tasks?" \
  "Tasks 9-25 pending, 2 weeks timeline"

# No expert - all perspectives equally valid
# Pure democracy
# Collective intelligence determines priority
```

---

## 🎓 Learning from Decisions

Track which experts led to best outcomes:

```bash
# Create decision log analysis
cd decisions/results/
grep '"expert": "gemini"' *.json | wc -l  # Gemini expert decisions
grep '"expert": "claude"' *.json | wc -l  # Claude expert decisions
grep '"expert": "chatgpt"' *.json | wc -l # ChatGPT expert decisions
grep '"expert": "grok"' *.json | wc -l    # Grok expert decisions
grep '"expert": "none"' *.json | wc -l    # No expert decisions

# Analyze outcomes over time
# Refine expert assignments based on results
```

---

## Summary

**The Expert System:**
- ✅ Weights domain expertise appropriately
- ✅ Maintains democratic process (not veto)
- ✅ Reduces user tie-breaking to ~5%
- ✅ Faster, better decisions
- ✅ Transparent and auditable
- ✅ Copilot excluded (works for user)

**Use expert when domain expertise matters. Use pure democracy when all perspectives equal.**
