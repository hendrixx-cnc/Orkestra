# Meeting Outcomes

This directory contains final outcomes exported from committee votes and questions.

## Purpose

After a vote or question completes all rounds and generates a summary, the final outcome is exported here for permanent record keeping.

## File Format

**Vote Outcomes**:
```
vote-outcome-YYYYMMDD-HASH.md
```

**Question Outcomes**:
```
question-outcome-YYYYMMDD-HASH.md
```

## What's Included

Each outcome file contains:
- **Original question/vote**: What was asked
- **Round summaries**: Key points from each iteration
- **Final decision/answer**: Consolidated result
- **Action items**: What to do next
- **Participants**: Which AI agents participated
- **Timestamp**: When it completed
- **Links**: References to full response files

## Difference from Other Files

- **VOTES/** & **QUESTIONS/**: Working files with full structure
- **RESPONSES/**: Round-by-round and summary files
- **AGENTS/**: Individual AI input/output
- **OUTCOMES/**: Clean, final results for easy reference

## Usage

```bash
# View all outcomes
ls -lt /workspaces/Orkestra/COMMITTEE/MEETINGS/OUTCOMES/

# Read a specific outcome
cat /workspaces/Orkestra/COMMITTEE/MEETINGS/OUTCOMES/vote-outcome-20251019-a3f8b1c4.md

# Search outcomes
grep -r "compression" /workspaces/Orkestra/COMMITTEE/MEETINGS/OUTCOMES/
```

## Export Process

Outcomes are automatically exported when:
1. All rounds complete (Round N finishes)
2. Summary is generated
3. Status changes to ✅ COMPLETE
4. Export script copies key information to this directory

This creates a clean audit trail of all committee decisions.

---

**Last Updated**: October 19, 2025
