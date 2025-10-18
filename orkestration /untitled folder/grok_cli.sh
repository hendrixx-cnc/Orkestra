#!/bin/bash
# Grok CLI Wrapper - Direct API Integration
# Usage: bash grok_cli.sh "Your prompt here"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for API key
if [ -z "${XAI_API_KEY:-}" ]; then
    echo "❌ Error: XAI_API_KEY environment variable not set" >&2
    echo "   Set it with: export XAI_API_KEY='your-key-here'" >&2
    exit 1
fi

# Get prompt from arguments or stdin
PROMPT="${1:-}"
if [ -z "$PROMPT" ]; then
    echo "Usage: $0 \"Your prompt here\"" >&2
    exit 1
fi

# Call Grok API
RESPONSE=$(curl -s -X POST "https://api.x.ai/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $XAI_API_KEY" \
  -d "{
    \"messages\": [
      {
        \"role\": \"user\",
        \"content\": $(echo "$PROMPT" | jq -Rs .)
      }
    ],
    \"model\": \"grok-2-latest\",
    \"stream\": false,
    \"temperature\": 0.7
  }")

# Extract and print the response
echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null || {
    echo "❌ Error calling Grok API:" >&2
    echo "$RESPONSE" | jq -r '.error // .message // .' >&2
    exit 1
}
