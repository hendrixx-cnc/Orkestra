#!/bin/bash
# ANSWER USER PROMPT
# Allows user to answer AI prompts when they need clarification

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USER_PROMPTS_DIR="$SCRIPT_DIR/user_prompts"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <prompt_id> \"<answer>\""
    echo ""
    echo "Available prompts:"
    find "$USER_PROMPTS_DIR" -name "*_prompt_*.json" -type f | while read prompt_file; do
        local status=$(jq -r '.status' "$prompt_file")
        if [ "$status" = "waiting" ]; then
            local id=$(jq -r '.id' "$prompt_file")
            local ai=$(jq -r '.ai' "$prompt_file")
            local question=$(jq -r '.question' "$prompt_file")
            echo "  $id ($ai): $question"
        fi
    done
    exit 1
fi

PROMPT_ID="$1"
ANSWER="$2"

PROMPT_FILE="$USER_PROMPTS_DIR/${PROMPT_ID}.json"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "❌ Error: Prompt $PROMPT_ID not found"
    exit 1
fi

# Update prompt with answer
TMP_FILE=$(mktemp)
jq --arg answer "$ANSWER" \
   '. + {answer: $answer, status: "answered", answered_at: "'$(date -Iseconds)'"}' \
   "$PROMPT_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$PROMPT_FILE"

echo "✅ Answer recorded for prompt $PROMPT_ID"
echo ""
echo "The AI daemon will resume work automatically."
