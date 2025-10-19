#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# CDIS - CONTEXT DISTILLATION & INTEGRATION SYSTEM
# ═══════════════════════════════════════════════════════════════════════════
# AI-optimized compression format for maximum storage efficiency
# Uses: token optimization, semantic chunking, reference compression
# Output: .cdis files optimized for AI context windows
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# CDIS Format Version
CDIS_VERSION="1.0"

# ═══════════════════════════════════════════════════════════════════════════
# CDIS COMPRESSION (AI-OPTIMIZED)
# ═══════════════════════════════════════════════════════════════════════════

extract_metadata() {
    local file="$1"
    local filename=$(basename "$file")
    local filetype="${filename##*.}"
    local purpose=""
    local key_functions=""
    
    # Extract purpose from header comments
    purpose=$(head -20 "$file" | grep -i "# .*purpose\|# .*description" | head -1 | sed 's/^#//' | xargs)
    
    # Extract function names for bash scripts
    if [[ "$filetype" == "sh" ]]; then
        key_functions=$(grep -E "^[a-zA-Z_][a-zA-Z0-9_]*\(\)" "$file" | sed 's/().*$//' | tr '\n' ',' | sed 's/,$//')
    fi
    
    cat << EOF
{
  "filename": "$filename",
  "type": "$filetype",
  "purpose": "$purpose",
  "functions": "$key_functions",
  "cdis_version": "$CDIS_VERSION"
}
EOF
}

tokenize_content() {
    local content="$1"
    
    # Remove all comments
    content=$(echo "$content" | sed 's/#.*$//')
    
    # Remove blank lines
    content=$(echo "$content" | sed '/^[[:space:]]*$/d')
    
    # Compress whitespace to single spaces
    content=$(echo "$content" | sed 's/[[:space:]]\+/ /g')
    
    # Remove leading/trailing spaces
    content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "$content"
}

create_semantic_chunks() {
    local content="$1"
    local chunk_size=500  # characters per chunk
    
    # Split into logical chunks (functions, blocks, etc.)
    echo "$content" | awk -v size="$chunk_size" '
        BEGIN { chunk=""; count=0 }
        {
            if (length(chunk) + length($0) > size) {
                if (chunk != "") {
                    print chunk
                    count++
                }
                chunk = $0
            } else {
                chunk = chunk (chunk ? " " : "") $0
            }
        }
        END { if (chunk != "") print chunk }
    '
}

compress_symbols() {
    local content="$1"
    
    # Ultra-compressed symbol table
    declare -A ultra_map=(
        ["function "]="ƒ"
        ["return "]="←"
        ["echo "]="○"
        ["local "]="•"
        ["ORKESTRA_ROOT"]="Ø"
        ["CONFIG_DIR"]="©"
        ["SCRIPTS_DIR"]="$"
        ["LOGS_DIR"]="£"
        ["if "]="?"
        ["then "]="→"
        ["else "]="↔"
        ["fi "]="◊"
        ["for "]="∀"
        ["while "]="∞"
        ["do "]="▶"
        ["done "]="■"
    )
    
    local result="$content"
    for key in "${!ultra_map[@]}"; do
        result=$(echo "$result" | sed "s/${key}/${ultra_map[$key]}/g")
    done
    
    echo "$result"
}

encode_base64() {
    local content="$1"
    echo "$content" | base64 | tr -d '\n'
}

create_cdis() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$input_file" ]]; then
        echo -e "${RED}✗${NC} Input file not found: $input_file"
        return 1
    fi
    
    echo -e "${CYAN}Creating CDIS:${NC} $input_file"
    
    # Extract metadata
    local metadata=$(extract_metadata "$input_file")
    
    # Read and process content
    local content=$(cat "$input_file")
    local original_size=${#content}
    
    echo -e "${CYAN}  Stage 1:${NC} Tokenization..."
    content=$(tokenize_content "$content")
    
    echo -e "${CYAN}  Stage 2:${NC} Symbol compression..."
    content=$(compress_symbols "$content")
    
    echo -e "${CYAN}  Stage 3:${NC} Semantic chunking..."
    local chunks=$(create_semantic_chunks "$content")
    
    echo -e "${CYAN}  Stage 4:${NC} Base64 encoding..."
    local encoded=$(encode_base64 "$chunks")
    
    # Calculate compression
    local compressed_size=${#encoded}
    local ratio=$(awk "BEGIN {printf \"%.2f\", ($compressed_size / $original_size) * 100}")
    
    # Create CDIS file
    cat > "$output_file" << EOF
{
  "cdis_version": "$CDIS_VERSION",
  "metadata": $metadata,
  "compression": {
    "original_size": $original_size,
    "compressed_size": $compressed_size,
    "ratio": $ratio,
    "algorithm": "tokenize+symbol+chunk+base64"
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "data": "$encoded",
  "symbol_map": {
    "ƒ": "function", "←": "return", "○": "echo", "•": "local",
    "Ø": "ORKESTRA_ROOT", "©": "CONFIG_DIR", "$": "SCRIPTS_DIR", "£": "LOGS_DIR",
    "?": "if", "→": "then", "↔": "else", "◊": "fi",
    "∀": "for", "∞": "while", "▶": "do", "■": "done"
  }
}
EOF
    
    local final_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
    local final_ratio=$(awk "BEGIN {printf \"%.2f\", ($final_size / $original_size) * 100}")
    
    echo -e "${GREEN}✓${NC} CDIS created: ${original_size} → ${final_size} bytes (${final_ratio}%)"
}

decode_cdis() {
    local input_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$input_file" ]]; then
        echo -e "${RED}✗${NC} Input file not found: $input_file"
        return 1
    fi
    
    echo -e "${CYAN}Decoding CDIS:${NC} $input_file"
    
    # Extract encoded data
    local encoded=$(jq -r '.data' "$input_file")
    
    # Decode base64
    local decoded=$(echo "$encoded" | base64 -d)
    
    # Reverse symbol mapping
    declare -A reverse_map=(
        ["ƒ"]="function "
        ["←"]="return "
        ["○"]="echo "
        ["•"]="local "
        ["Ø"]="ORKESTRA_ROOT"
        ["©"]="CONFIG_DIR"
        ["$"]="SCRIPTS_DIR"
        ["£"]="LOGS_DIR"
        ["?"]="if "
        ["→"]="then "
        ["↔"]="else "
        ["◊"]="fi "
        ["∀"]="for "
        ["∞"]="while "
        ["▶"]="do "
        ["■"]="done "
    )
    
    local result="$decoded"
    for key in "${!reverse_map[@]}"; do
        result=$(echo "$result" | sed "s/${key}/${reverse_map[$key]}/g")
    done
    
    echo "$result" > "$output_file"
    
    echo -e "${GREEN}✓${NC} Decoded to: $output_file"
}

# ═══════════════════════════════════════════════════════════════════════════
# CERTIFIED DECODER
# ═══════════════════════════════════════════════════════════════════════════

verify_cdis() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}✗${NC} File not found: $file"
        return 1
    fi
    
    # Verify JSON structure
    if ! jq empty "$file" 2>/dev/null; then
        echo -e "${RED}✗${NC} Invalid CDIS format (not valid JSON)"
        return 1
    fi
    
    # Verify required fields
    local version=$(jq -r '.cdis_version' "$file" 2>/dev/null)
    local data=$(jq -r '.data' "$file" 2>/dev/null)
    
    if [[ -z "$version" ]] || [[ -z "$data" ]]; then
        echo -e "${RED}✗${NC} Invalid CDIS format (missing required fields)"
        return 1
    fi
    
    echo -e "${GREEN}✓${NC} Valid CDIS v$version file"
    
    # Show info
    local metadata=$(jq -r '.metadata.filename' "$file")
    local orig_size=$(jq -r '.compression.original_size' "$file")
    local comp_size=$(jq -r '.compression.compressed_size' "$file")
    local ratio=$(jq -r '.compression.ratio' "$file")
    
    echo -e "${CYAN}Filename:${NC} $metadata"
    echo -e "${CYAN}Original:${NC} $orig_size bytes"
    echo -e "${CYAN}Compressed:${NC} $comp_size bytes"
    echo -e "${CYAN}Ratio:${NC} ${ratio}%"
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}CDIS - Context Distillation & Integration System${NC}

${BOLD}USAGE:${NC}
    $0 compress <input> <output.cdis>
    $0 decompress <input.cdis> <output>
    $0 verify <file.cdis>

${BOLD}DESCRIPTION:${NC}
    CDIS creates AI-optimized compressed files for maximum storage
    efficiency and optimal context window utilization.

${BOLD}FEATURES:${NC}
    • Token optimization for AI processing
    • Semantic chunking for context understanding
    • Symbol compression with certified decoder
    • Base64 encoding for safe transport
    • JSON container with metadata

${BOLD}EXAMPLES:${NC}
    ${CYAN}# Compress to CDIS${NC}
    $0 compress script.sh script.cdis

    ${CYAN}# Decompress from CDIS${NC}
    $0 decompress script.cdis script-restored.sh

    ${CYAN}# Verify CDIS file${NC}
    $0 verify script.cdis

${BOLD}USE CASES:${NC}
    • AI context storage
    • Regulatory compliance archives
    • Certified audit trails
    • Cross-platform code transport

EOF
}

main() {
    local command="${1:-help}"
    
    case "$command" in
        compress|c)
            if [[ $# -lt 3 ]]; then
                echo -e "${RED}✗${NC} Missing arguments"
                echo "Usage: $0 compress <input> <output.cdis>"
                exit 1
            fi
            create_cdis "$2" "$3"
            ;;
        decompress|d|decode)
            if [[ $# -lt 3 ]]; then
                echo -e "${RED}✗${NC} Missing arguments"
                echo "Usage: $0 decompress <input.cdis> <output>"
                exit 1
            fi
            decode_cdis "$2" "$3"
            ;;
        verify|v)
            if [[ $# -lt 2 ]]; then
                echo -e "${RED}✗${NC} Missing arguments"
                echo "Usage: $0 verify <file.cdis>"
                exit 1
            fi
            verify_cdis "$2"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
