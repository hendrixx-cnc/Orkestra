#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# COPILOT DIRECT RESPONSE INJECTOR
# ═══════════════════════════════════════════════════════════════════════════
# This script allows GitHub Copilot to inject responses directly into question
# files without needing API calls, since Copilot is already in the conversation
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

QUESTIONS_DIR="/workspaces/Orkestra/SCRIPTS/DEMOCRACY/COMMITTEE/QUESTIONS"

inject_copilot_response() {
    local question_file="$1"
    local response="$2"
    local pass="${3:-1}"  # Default to Pass 1
    
    if [[ ! -f "$question_file" ]]; then
        echo "Error: Question file not found: $question_file"
        return 1
    fi
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local response_hash=$(echo -n "copilot|pass${pass}|${timestamp}|${response}" | sha256sum | awk '{print $1}')
    
    if [[ "$pass" == "1" ]]; then
        # Inject into Pass 1 section (after "## Pass 1: Initial Responses")
        local marker="## Pass 1: Initial Responses"
        local injection="

### 🚀 COPILOT - Code, Deployment, DevOps
**Timestamp**: $timestamp  
**Hash**: \`${response_hash}\`

$response

---
"
    else
        # Inject into Pass 2 section (after "## Pass 2: Refined Responses")
        local marker="## Pass 2: Refined Responses"
        local injection="

### 🚀 COPILOT - Refined Response
**Timestamp**: $timestamp  
**Hash**: \`${response_hash}\`

$response

---
"
    fi
    
    # Use awk to insert after marker
    awk -v marker="$marker" -v injection="$injection" '
        {print}
        $0 == marker {print injection}
    ' "$question_file" > "${question_file}.tmp" && mv "${question_file}.tmp" "$question_file"
    
    echo "✓ Copilot response injected into $question_file (Pass $pass)"
}

# Export function for use in other scripts
export -f inject_copilot_response

# If called directly with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]]; then
        echo "Usage: $0 <question_file> <response> [pass_number]"
        echo ""
        echo "Example:"
        echo "  $0 questions/question_123.md 'My detailed response here' 1"
        exit 1
    fi
    
    inject_copilot_response "$1" "$2" "${3:-1}"
fi
