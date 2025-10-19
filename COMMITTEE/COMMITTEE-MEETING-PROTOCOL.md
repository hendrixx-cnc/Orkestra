# COMMITTEE MEETING PROTOCOL

## How to Call and Run Committee Meetings

### 1. PREPARING A MEETING

**Create Meeting File**:
```bash
# Location: /workspaces/Orkestra/COMMITTEE/MEETINGS/
# Format: [topic]-[date].md

# Example:
/workspaces/Orkestra/COMMITTEE/MEETINGS/compression-optimization-2025-10-19.md
```

**Required Sections**:
- **Header**: Date, Topic, Status
- **Agenda**: Clear objectives for each phase
- **Files for Review**: Exact file paths committee can access
- **Questions**: Specific questions requiring committee input
- **Deliverables**: What the committee should produce
- **Meeting Notes**: Space for committee responses

### 2. MEETING FILE TEMPLATE

```markdown
# COMMITTEE MEETING: [Topic]

**Date**: YYYY-MM-DD
**Topic**: [Clear description]
**Status**: 🟢 ACTIVE / 🟡 IN PROGRESS / ✅ COMPLETE

---

## AGENDA

### Phase 1: [Name]
**Objective**: [Clear goal]
**Tasks**: 
- [Specific task 1]
- [Specific task 2]

---

## FILES FOR COMMITTEE REVIEW

**Documentation**:
```bash
/full/path/to/document1.md
/full/path/to/document2.md
```

**Source Code**:
```bash
/full/path/to/source1.py
/full/path/to/source2.py
```

**Test Data**:
```bash
/tmp/test_file1.txt
/tmp/test_file2.json
```

**Analysis Commands**:
```bash
# Command 1: Purpose
command_to_run

# Command 2: Purpose
another_command
```

---

## COMMITTEE QUESTIONS

**Q1**: [Specific question]
- Context: [Why this matters]
- Command: [How to gather data]

**Q2**: [Another question]
- Context: [Background]
- Expected output: [What format]

---

## DELIVERABLES

**Phase 1**:
- [ ] Item 1
- [ ] Item 2

**Final Output**:
- [ ] Summary document
- [ ] Updated files
- [ ] Test results

---

## MEETING NOTES

### Agent 1: [Role]
[Response here]

### Agent 2: [Role]
[Response here]

---

**Status**: [Current state]
**Next Action**: [What happens next]
```

### 3. ACTIVATING THE MEETING

**Option A: Notify in Chat**
```
The committee has a new meeting ready at:
/workspaces/Orkestra/COMMITTEE/MEETINGS/[meeting-file].md

Please review and provide your analysis.
```

**Option B: Create Task Queue Entry**
```json
{
  "id": "meeting-YYYYMMDD-HHmm",
  "type": "committee-meeting",
  "priority": "high",
  "meeting_file": "/workspaces/Orkestra/COMMITTEE/MEETINGS/[file].md",
  "status": "pending",
  "assigned_to": "committee"
}
```

**Option C: Use Orchestrator**
```bash
./SCRIPTS/CORE/orchestrator.sh notify-committee \
  --meeting "/workspaces/Orkestra/COMMITTEE/MEETINGS/[file].md"
```

### 4. COMMITTEE RESPONSE FORMAT

**Each Agent Should**:
1. Read all reference documents
2. Run provided analysis commands
3. Add response to "MEETING NOTES" section
4. Update status indicators
5. Sign off with timestamp

**Response Template**:
```markdown
### Agent [N]: [Role] - [Name]
**Timestamp**: YYYY-MM-DD HH:MM
**Status**: ✅ Complete / 🔄 In Progress / ⏸️ Blocked

**Analysis**:
[Findings from commands and document review]

**Recommendations**:
1. [Specific recommendation]
2. [Another recommendation]

**Vote** (if applicable):
- Option A: [Score/Rank]
- Option B: [Score/Rank]

**Next Steps**:
[What this agent will do next, if assigned]

---
```

### 5. CLOSING THE MEETING

**Update Meeting Status**:
```markdown
**Status**: ✅ COMPLETE
**Completion Date**: YYYY-MM-DD
**Outcome**: [Summary of decisions]
```

**Archive Meeting**:
```bash
# Create meeting summary
cat >> /workspaces/Orkestra/COMMITTEE/MEETINGS/SUMMARY.md << 'EOF'

## [Meeting Name] - [Date]
- **Topic**: [Topic]
- **Outcome**: [Result]
- **Next Steps**: [Actions]
- **File**: [path/to/meeting.md]

EOF
```

**Create Follow-up Tasks**:
- Update task queue with action items
- Assign specific agents to implementation
- Set deadlines and success criteria

### 6. MEETING TYPES

#### Type A: Analysis & Recommendation
- Committee reviews data
- Provides analysis
- Votes on options
- Recommends approach

#### Type B: Implementation Review
- Committee reviews proposed changes
- Validates approach
- Approves/rejects implementation
- Suggests improvements

#### Type C: Emergency Decision
- Fast-track review required
- Quick votes needed
- Minimal documentation
- Immediate action

#### Type D: Retrospective
- Review completed work
- Identify lessons learned
- Update processes
- Document best practices

### 7. BEST PRACTICES

**DO**:
- ✅ Provide exact file paths (not relative references)
- ✅ Include runnable commands for analysis
- ✅ Set clear objectives and deliverables
- ✅ Give sufficient context in reference docs
- ✅ Allow space for committee notes/responses
- ✅ Update status as meeting progresses

**DON'T**:
- ❌ Use vague questions ("What do you think?")
- ❌ Reference files without full paths
- ❌ Forget to include test data locations
- ❌ Skip verification commands
- ❌ Leave objectives unclear
- ❌ Forget to close/archive completed meetings

### 8. COMMITTEE ROLES

Define clear roles for efficiency:

- **Analysis Lead**: Runs data analysis, reports findings
- **Implementation Lead**: Reviews code feasibility, estimates complexity
- **Testing Lead**: Proposes test methodology, validates results
- **Strategy Lead**: Long-term perspective, architectural decisions
- **Documentation Lead**: Updates docs, maintains clarity

### 9. ESCALATION PROCESS

**If Committee is Blocked**:
1. Update status to ⏸️ BLOCKED
2. Document blocking issue
3. Tag specific expertise needed
4. Set timeout for resolution
5. Escalate to human if timeout exceeded

**Timeout Defaults**:
- Analysis: 2 hours
- Implementation: 4 hours
- Testing: 1 hour
- Decision: 30 minutes

### 10. EXAMPLE WORKFLOW

```bash
# 1. Human calls meeting
cat > /workspaces/Orkestra/COMMITTEE/MEETINGS/new-meeting.md << 'EOF'
[Meeting content]
EOF

# 2. Notify committee (multiple options)
echo "Meeting ready: COMMITTEE/MEETINGS/new-meeting.md"

# 3. Committee reviews files
cat /path/to/referenced/file1.md
cat /path/to/referenced/file2.py

# 4. Committee runs analysis commands
command1 | tee analysis-output.txt
command2 | tee -a analysis-output.txt

# 5. Committee adds responses to meeting file
vim COMMITTEE/MEETINGS/new-meeting.md
# (Add notes in MEETING NOTES section)

# 6. Update status
sed -i 's/Status.*ACTIVE/Status: ✅ COMPLETE/' COMMITTEE/MEETINGS/new-meeting.md

# 7. Create follow-up tasks
./SCRIPTS/create-tasks-from-meeting.sh COMMITTEE/MEETINGS/new-meeting.md
```

---

## QUICK REFERENCE

**Call a meeting**: Create file in `COMMITTEE/MEETINGS/`
**File paths**: Always use absolute paths starting with `/workspaces/Orkestra/`
**Commands**: Make them copy-pasteable and runnable
**Status updates**: Use emoji for quick visibility (🟢🟡🔴✅⏸️)
**Responses**: Committee adds to "MEETING NOTES" section
**Close meeting**: Update status, archive, create tasks

---

**Document Version**: 1.0
**Last Updated**: 2025-10-19
**Maintained by**: Orkestra Orchestration System
