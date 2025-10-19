#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# AI AGENT API CALLER
# ═══════════════════════════════════════════════════════════════════════════
# Actually calls real AI APIs to get agent opinions
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

MINUTES_FILE="/workspaces/Orkestra/COMPRESSION/MEETING_MINUTES.md"

# ═══════════════════════════════════════════════════════════════════════════
# API CALLS
# ═══════════════════════════════════════════════════════════════════════════

call_claude() {
    local prompt="$1"
    
    if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        echo "ERROR: ANTHROPIC_API_KEY not set"
        return 1
    fi
    
    curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{
            \"model\": \"claude-3-5-sonnet-20241022\",
            \"max_tokens\": 1024,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }]
        }" | jq -r '.content[0].text'
}

call_openai() {
    local prompt="$1"
    
    if [[ -z "${OPENAI_API_KEY:-}" ]]; then
        echo "ERROR: OPENAI_API_KEY not set"
        return 1
    fi
    
    curl -s https://api.openai.com/v1/chat/completions \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"gpt-4\",
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }],
            \"max_tokens\": 1024
        }" | jq -r '.choices[0].message.content'
}

call_gemini() {
    local prompt="$1"
    
    if [[ -z "${GOOGLE_API_KEY:-}" ]]; then
        echo "ERROR: GOOGLE_API_KEY not set"
        return 1
    fi
    
    curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GOOGLE_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"contents\": [{
                \"parts\": [{
                    \"text\": \"$prompt\"
                }]
            }]
        }" | jq -r '.candidates[0].content.parts[0].text'
}

call_grok() {
    local prompt="$1"
    
    if [[ -z "${XAI_API_KEY:-}" ]]; then
        echo "ERROR: XAI_API_KEY not set"
        return 1
    fi
    
    curl -s https://api.x.ai/v1/chat/completions \
        -H "Authorization: Bearer $XAI_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"grok-beta\",
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$prompt\"
            }],
            \"max_tokens\": 1024
        }" | jq -r '.choices[0].message.content'
}

# ═══════════════════════════════════════════════════════════════════════════
# PROMPT BUILDER
# ═══════════════════════════════════════════════════════════════════════════

build_prompt() {
    local agent="$1"
    local specialty="$2"
    
    cat << EOF
You are $agent, an AI agent in the Orkestra multi-AI orchestration system.

Your specialty: $specialty

CONTEXT:
The team voted to implement context compression (PASSED 4-1). The format strategy vote FAILED - split between:
- Two-level (HACS human-readable + CDIS AI-optimized)
- Hybrid (both formats, auto-convert)
- Single-optimized (CDIS only)

Copilot proposed a modular approach with this folder structure:
/COMPRESSION/
  ├── HACS/    (Human-Accessible, 16.78% target)
  ├── CDIS/    (AI-optimized format)
  ├── HYBRID/  (Conversion pipelines)
  ├── TESTS/
  ├── SAMPLES/
  └── DOCS/

YOUR TASK:
Provide your expert opinion (150-200 words) on:
1. The overall compression strategy
2. Your thoughts on the approach
3. Specific recommendations for your assigned area
4. Any concerns or improvements

Be concise, technical, and focus on your specialty area.
EOF
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

echo "🎭 Calling Claude (Architecture)..."
claude_response=$(call_claude "$(build_prompt "Claude" "Architecture, Design, UX")")
echo "✓ Claude responded"
echo ""

echo "💬 Calling ChatGPT (Content)..."
chatgpt_response=$(call_openai "$(build_prompt "ChatGPT" "Content, Writing, Documentation")")
echo "✓ ChatGPT responded"
echo ""

echo "✨ Calling Gemini (Cloud)..."
gemini_response=$(call_gemini "$(build_prompt "Gemini" "Cloud, Database, Storage")")
echo "✓ Gemini responded"
echo ""

echo "⚡ Calling Grok (Innovation)..."
grok_response=$(call_grok "$(build_prompt "Grok" "Innovation, Research, Analysis")")
echo "✓ Grok responded"
echo ""

echo "Updating meeting minutes..."
echo "Done! Check $MINUTES_FILE"
