#!/usr/bin/env python3
"""
HACS Pipeline - Sequential AI Processing
Each AI processes the output from the previous AI
"""

import json
import sys
from pathlib import Path
from datetime import datetime

class HACSpipeline:
    """Sequential HACS processing pipeline"""
    
    def __init__(self):
        self.stages = [
            {
                'id': 1,
                'ai': 'copilot',
                'focus': 'Code optimization and structure',
                'input_file': 'original.txt',
                'output_file': 'stage1_copilot.hacs'
            },
            {
                'id': 2,
                'ai': 'claude',
                'focus': 'Content refinement and clarity',
                'input_file': 'stage1_copilot.hacs',
                'output_file': 'stage2_claude.hacs'
            },
            {
                'id': 3,
                'ai': 'chatgpt',
                'focus': 'Redundancy removal and compression',
                'input_file': 'stage2_claude.hacs',
                'output_file': 'stage3_chatgpt.hacs'
            },
            {
                'id': 4,
                'ai': 'gemini',
                'focus': 'Pattern recognition and summary',
                'input_file': 'stage3_chatgpt.hacs',
                'output_file': 'stage4_gemini.hacs'
            },
            {
                'id': 5,
                'ai': 'grok',
                'focus': 'Final validation and democratic vote',
                'input_file': 'stage4_gemini.hacs',
                'output_file': 'final_result.hacs'
            }
        ]
        
        self.pipeline_dir = Path('/workspaces/The-Quantum-Self-/AI/hacs_pipeline')
        self.pipeline_dir.mkdir(exist_ok=True)
    
    def create_tasks(self):
        """Create 5 sequential task files for the AI pipeline"""
        
        for stage in self.stages:
            task = {
                'task_id': f"HACS_STAGE_{stage['id']}",
                'assigned_to': stage['ai'],
                'stage': stage['id'],
                'total_stages': 5,
                'description': f"Stage {stage['id']}: {stage['focus']}",
                'input_file': str(self.pipeline_dir / stage['input_file']),
                'output_file': str(self.pipeline_dir / stage['output_file']),
                'instructions': self._generate_instructions(stage),
                'status': 'pending' if stage['id'] > 1 else 'ready',
                'depends_on': f"HACS_STAGE_{stage['id']-1}" if stage['id'] > 1 else None,
                'created': datetime.now().isoformat()
            }
            
            # Save task file
            task_file = self.pipeline_dir / f"task_stage{stage['id']}_{stage['ai']}.json"
            with open(task_file, 'w') as f:
                json.dump(task, f, indent=2)
            
            print(f"✅ Created: {task_file.name}")
            print(f"   AI: {stage['ai']}")
            print(f"   Input: {stage['input_file']}")
            print(f"   Output: {stage['output_file']}")
            print(f"   Status: {task['status']}")
            print()
    
    def _generate_instructions(self, stage):
        """Generate specific instructions for each AI"""
        
        base = f"""
# HACS Pipeline - Stage {stage['id']} of 5

**Your Role:** {stage['ai']} - {stage['focus']}

## Input
Read from: `{stage['input_file']}`

## Your Task
1. Apply HACS compression algorithm:
   - Calculate weights: 0.4×U + 0.3×C + 0.2×R + 0.1×M
   - Classify: KEEP (≥0.8), SUMMARIZE (0.4-0.8), REMOVE (<0.4)
   - Focus on: {stage['focus']}

2. Process the content with your strengths:
"""
        
        if stage['ai'] == 'copilot':
            base += """   - Remove code duplicates
   - Optimize structure
   - Keep critical logic"""
        
        elif stage['ai'] == 'claude':
            base += """   - Improve clarity
   - Refine summaries
   - Enhance readability"""
        
        elif stage['ai'] == 'chatgpt':
            base += """   - Remove redundancy
   - Compress verbose sections
   - Maintain meaning"""
        
        elif stage['ai'] == 'gemini':
            base += """   - Find patterns
   - Create smart summaries
   - Optimize further"""
        
        elif stage['ai'] == 'grok':
            base += """   - Final validation
   - Quality check
   - Democratic voting"""
        
        base += f"""

## Output
Write to: `{stage['output_file']}`

Format:
```json
{{
  "stage": {stage['id']},
  "ai": "{stage['ai']}",
  "input_size": <bytes>,
  "output_size": <bytes>,
  "compression_ratio": <ratio>,
  "actions": {{
    "kept": <count>,
    "summarized": <count>,
    "removed": <count>
  }},
  "content": "..."
}}
```

## Next Stage
Your output becomes input for: {self.stages[stage['id']]['ai'] if stage['id'] < 5 else 'END OF PIPELINE'}

## Success Criteria
- Compression ratio improves from input
- Critical information preserved
- Output is valid for next stage
"""
        
        return base
    
    def create_readme(self):
        """Create README for the pipeline"""
        
        readme = """# HACS Sequential Pipeline

## How It Works

This pipeline passes content through 5 AI agents sequentially:

```
Original File
    ↓
Stage 1: Copilot (code optimization)
    ↓
Stage 2: Claude (content refinement)
    ↓
Stage 3: ChatGPT (redundancy removal)
    ↓
Stage 4: Gemini (pattern recognition)
    ↓
Stage 5: Grok (final validation)
    ↓
Final Compressed Result
```

## Running the Pipeline

### Manual Execution

Each AI picks up their task in sequence:

```bash
# Stage 1 (Copilot goes first)
cat task_stage1_copilot.json
# Execute task, create stage1_copilot.hacs

# Stage 2 (Claude waits for Stage 1)
cat task_stage2_claude.json
# Execute task, create stage2_claude.hacs

# And so on...
```

### Automated Execution

```bash
python hacs_pipeline.py run
```

## Task Status

Check which stage is ready:

```bash
python hacs_pipeline.py status
```

## Files

- `task_stage1_copilot.json` - Copilot's task
- `task_stage2_claude.json` - Claude's task  
- `task_stage3_chatgpt.json` - ChatGPT's task
- `task_stage4_gemini.json` - Gemini's task
- `task_stage5_grok.json` - Grok's task

## Pipeline State

- `original.txt` - Input file (you provide this)
- `stage1_copilot.hacs` - After Copilot
- `stage2_claude.hacs` - After Claude
- `stage3_chatgpt.hacs` - After ChatGPT
- `stage4_gemini.hacs` - After Gemini
- `final_result.hacs` - Final output

## Success Metrics

Track compression through the pipeline:

```
Original: 10,000 bytes (100%)
Stage 1:   8,000 bytes (80%)
Stage 2:   6,000 bytes (60%)
Stage 3:   4,000 bytes (40%)
Stage 4:   3,000 bytes (30%)
Stage 5:   2,500 bytes (25%)
```

Goal: 10x compression with information preservation
"""
        
        readme_file = self.pipeline_dir / 'README.md'
        with open(readme_file, 'w') as f:
            f.write(readme)
        
        print(f"✅ Created: {readme_file.name}")
    
    def check_status(self):
        """Check which stage is currently ready"""
        
        print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 HACS PIPELINE STATUS")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        for stage in self.stages:
            task_file = self.pipeline_dir / f"task_stage{stage['id']}_{stage['ai']}.json"
            output_file = self.pipeline_dir / stage['output_file']
            
            if output_file.exists():
                status = "✅ COMPLETE"
            elif task_file.exists() and stage['id'] == 1:
                status = "🟢 READY (Start here!)"
            elif task_file.exists():
                prev_output = self.pipeline_dir / self.stages[stage['id']-2]['output_file']
                if prev_output.exists():
                    status = "🟢 READY"
                else:
                    status = "⏳ WAITING"
            else:
                status = "❌ NOT CREATED"
            
            print(f"Stage {stage['id']}: {stage['ai']:8} - {status}")
            print(f"         Input:  {stage['input_file']}")
            print(f"         Output: {stage['output_file']}")
            print()

def main():
    pipeline = HACSpipeline()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == 'create':
            print("Creating HACS pipeline tasks...\n")
            pipeline.create_tasks()
            pipeline.create_readme()
            print("\n✅ Pipeline created!")
            print(f"📁 Location: {pipeline.pipeline_dir}")
            print("\n🚀 Next: Put your file at hacs_pipeline/original.txt")
            print("   Then each AI processes in sequence")
        
        elif command == 'status':
            pipeline.check_status()
        
        else:
            print("Usage: python hacs_pipeline.py [create|status]")
    
    else:
        print("HACS Sequential Pipeline")
        print("\nCommands:")
        print("  create  - Create pipeline tasks")
        print("  status  - Check pipeline status")

if __name__ == '__main__':
    main()
