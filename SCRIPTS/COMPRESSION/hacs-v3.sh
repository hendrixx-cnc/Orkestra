#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# HACS V3 - HUMAN-AUDITABLE COMPRESSION SYSTEM (Complete Implementation)
# ═══════════════════════════════════════════════════════════════════════════
# Implements the HACS algorithm from patent specification
# Features: Multi-level dictionaries, case preservation, lossless compression
# Target: 10:1 compression ratio with human-readable intermediate format
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORKESTRA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Dictionaries directory
DICT_DIR="$ORKESTRA_ROOT/CONFIG/COMPRESSION/DICTIONARIES"
mkdir -p "$DICT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
PHRASE_THRESHOLD=0.01    # 1%
WORD_THRESHOLD=0.001     # 0.1%
TARGET_RATIO=10

# ═══════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# ═══════════════════════════════════════════════════════════════════════════
# COMPRESSION WORKFLOW
# ═══════════════════════════════════════════════════════════════════════════

compress_hacs() {
    local input_file="$1"
    local output_prefix="$2"
    
    if [[ ! -f "$input_file" ]]; then
        log_error "Input file not found: $input_file"
        return 1
    fi
    
    local basename=$(basename "$input_file" .txt)
    local entity_dict="${output_prefix}_entities.json"
    local phrase_dict="${output_prefix}_phrases.json"
    local word_dict="${output_prefix}_words.json"
    local encoded_file="${output_prefix}_encoded.json"
    
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HACS V3 - Human-Auditable Compression System${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Step 1: Build dictionaries
    echo -e "${CYAN}Step 1/2: Building Multi-Level Dictionaries${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "Building Entity Dictionary..."
    python3 "$LIB_DIR/build_entity_dict.py" "$input_file" > "$entity_dict"
    if [ $? -eq 0 ]; then
        local entity_count=$(jq '.count' "$entity_dict")
        log_success "Entity dictionary: $entity_count entities"
    else
        log_error "Failed to build entity dictionary"
        return 1
    fi
    
    log_info "Building Phrase Dictionary (threshold=$PHRASE_THRESHOLD)..."
    python3 "$LIB_DIR/build_phrase_dict.py" "$input_file" "$PHRASE_THRESHOLD" > "$phrase_dict"
    if [ $? -eq 0 ]; then
        local phrase_count=$(jq '.count' "$phrase_dict")
        log_success "Phrase dictionary: $phrase_count phrases"
    else
        log_error "Failed to build phrase dictionary"
        return 1
    fi
    
    log_info "Building Word Dictionary (threshold=$WORD_THRESHOLD)..."
    python3 "$LIB_DIR/build_word_dict.py" "$input_file" "$WORD_THRESHOLD" > "$word_dict"
    if [ $? -eq 0 ]; then
        local word_count=$(jq '.count' "$word_dict")
        log_success "Word dictionary: $word_count words"
    else
        log_error "Failed to build word dictionary"
        return 1
    fi
    
    echo ""
    
    # Step 2: Encode
    echo -e "${CYAN}Step 2/2: Encoding with Longest-Match-First${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    log_info "Encoding input..."
    python3 "$LIB_DIR/hacs_encode.py" "$input_file" "$entity_dict" "$phrase_dict" "$word_dict" > "$encoded_file"
    
    if [ $? -eq 0 ]; then
        local ratio=$(jq '.compression_ratio' "$encoded_file")
        local tokens=$(jq '.token_count' "$encoded_file")
        log_success "Encoding complete: $tokens tokens, ${ratio}:1 compression"
    else
        log_error "Failed to encode input"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  HACS Compression Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Display results
    echo "Output files:"
    echo "  • Entity Dictionary:  $entity_dict"
    echo "  • Phrase Dictionary:  $phrase_dict"
    echo "  • Word Dictionary:    $word_dict"
    echo "  • Encoded Stream:     $encoded_file"
    echo ""
    
    # Statistics
    local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file")
    local ratio=$(jq '.compression_ratio' "$encoded_file")
    local tokens=$(jq '.token_count' "$encoded_file")
    local entities=$(jq '.dictionary_stats.entities' "$encoded_file")
    local phrases=$(jq '.dictionary_stats.phrases' "$encoded_file")
    local words=$(jq '.dictionary_stats.words' "$encoded_file")
    
    echo "Statistics:"
    echo "  • Original size:      $(numfmt --to=iec --format="%.2f" $original_size 2>/dev/null || echo "$original_size bytes")"
    echo "  • Compression ratio:  ${ratio}:1"
    echo "  • Token count:        $tokens"
    echo "  • Dictionary sizes:   E=$entities, P=$phrases, W=$words"
    echo "  • Target ratio:       ${TARGET_RATIO}:1"
    
    if (( $(echo "$ratio >= $TARGET_RATIO" | bc -l 2>/dev/null || echo "0") )); then
        echo -e "  • Status:             ${GREEN}✓ Target achieved!${NC}"
    else
        echo -e "  • Status:             ${YELLOW}⚠ Below target (${ratio}/${TARGET_RATIO})${NC}"
    fi
    
    echo ""
}

decompress_hacs() {
    local encoded_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$encoded_file" ]]; then
        log_error "Encoded file not found: $encoded_file"
        return 1
    fi
    
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  HACS Decompression${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    log_info "Decoding token stream..."
    python3 "$LIB_DIR/hacs_decode.py" "$encoded_file" > "$output_file"
    
    if [ $? -eq 0 ]; then
        local size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
        log_success "Decompression complete: $size bytes"
        echo ""
        echo "Output file: $output_file"
    else
        log_error "Failed to decode"
        return 1
    fi
    
    echo ""
}

verify_lossless() {
    local original_file="$1"
    local decoded_file="$2"
    
    echo ""
    echo -e "${CYAN}Verifying Lossless Compression...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if diff -q "$original_file" "$decoded_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Perfect match! Lossless compression verified.${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Files differ! Compression is NOT lossless.${NC}"
        echo ""
        echo "Running detailed diff:"
        diff "$original_file" "$decoded_file" | head -20
        echo ""
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    compress <input_file> <output_prefix>
        Compress input file using HACS algorithm
        
    decompress <encoded_file> <output_file>
        Decompress HACS-encoded file
        
    test <input_file> <temp_prefix>
        Round-trip test: compress → decompress → verify
        
    help
        Show this help message

Examples:
    # Compress a text file
    $0 compress document.txt /tmp/compressed
    
    # Decompress
    $0 decompress /tmp/compressed_encoded.json /tmp/restored.txt
    
    # Test round-trip
    $0 test document.txt /tmp/test

EOF
}

main() {
    case "${1:-help}" in
        compress)
            if [[ $# -lt 3 ]]; then
                log_error "Missing arguments"
                show_usage
                exit 1
            fi
            compress_hacs "$2" "$3"
            ;;
        decompress)
            if [[ $# -lt 3 ]]; then
                log_error "Missing arguments"
                show_usage
                exit 1
            fi
            decompress_hacs "$2" "$3"
            ;;
        test)
            if [[ $# -lt 3 ]]; then
                log_error "Missing arguments"
                show_usage
                exit 1
            fi
            local input="$2"
            local prefix="$3"
            local encoded="${prefix}_encoded.json"
            local decoded="${prefix}_decoded.txt"
            
            compress_hacs "$input" "$prefix" || exit 1
            decompress_hacs "$encoded" "$decoded" || exit 1
            verify_lossless "$input" "$decoded" || exit 1
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            log_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
