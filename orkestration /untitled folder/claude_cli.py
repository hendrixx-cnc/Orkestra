#!/usr/bin/env python3
"""
Claude CLI Wrapper for The Quantum Self AI Team
Uses Anthropic Python SDK to interact with Claude
"""

import sys
import os
from anthropic import Anthropic

def main():
    # Check for API key
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("❌ Error: ANTHROPIC_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    
    # Get prompt from command line
    if len(sys.argv) < 2:
        print("Usage: claude_cli.py '<prompt>'", file=sys.stderr)
        sys.exit(1)
    
    prompt = " ".join(sys.argv[1:])
    
    try:
        # Initialize Anthropic client
        client = Anthropic(api_key=api_key)
        
        # Call Claude API (using Claude 3 Haiku - fast and cost-effective)
        message = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=4096,
            messages=[
                {"role": "user", "content": prompt}
            ]
        )
        
        # Print response
        print(message.content[0].text)
        
    except Exception as e:
        print(f"❌ Error calling Claude API: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
