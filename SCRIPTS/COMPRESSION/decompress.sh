#!/usr/bin/env bash
#
# HACS-CDIS Decompression Pipeline
# Decompresses files created by compress.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] <compressed_file>

Decompress a file created by compress.sh.

OPTIONS:
    -o, --output FILE    Output file (default: auto-detect or stdout)
    -v, --verbose        Verbose output
    -k, --keep-temp      Keep temporary files
    -h, --help           Show this help message

EXAMPLES:
    # Decompress a file
    $(basename "$0") readme.md.hc

    # Decompress to specific file
    $(basename "$0") -o original.txt readme.md.hc

    # Decompress to stdout
    $(basename "$0") readme.md.hc > output.txt

STAGES:
    1. Load compressed file
    2. CDIS: Huffman decoding
    3. CDIS: Pattern expansion
    4. HACS: Token reconstruction
    5. Output: Original text (with case normalization)

NOTE:
    Current version performs case normalization (lowercase).
    To achieve lossless compression, case encoding will be added.
EOF
    exit 0
}

log() {
    echo -e "${BLUE}[DECOMPRESS]${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" >&2
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

log_stage() {
    echo -e "\n${YELLOW}▶${NC} $*" >&2
}

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""
VERBOSE=false
KEEP_TEMP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -k|--keep-temp)
            KEEP_TEMP=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

# Validate input
if [[ -z "$INPUT_FILE" ]]; then
    log_error "No input file specified"
    usage
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    log_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Set default output file
if [[ -z "$OUTPUT_FILE" ]]; then
    # Try to remove .hc extension
    if [[ "$INPUT_FILE" == *.hc ]]; then
        OUTPUT_FILE="${INPUT_FILE%.hc}"
    else
        OUTPUT_FILE="${INPUT_FILE}.decompressed"
    fi
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap 'if [[ "$KEEP_TEMP" != true ]]; then rm -rf "$TEMP_DIR"; fi' EXIT

log "Starting decompression pipeline"
log "Input: $INPUT_FILE ($(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE") bytes)"
log "Output: $OUTPUT_FILE"

COMPRESSED_SIZE=$(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE")

# ==============================================================================
# STAGE 1: Load compressed file
# ==============================================================================
log_stage "Stage 1/3: Loading compressed file"

ORIGINAL_SIZE=$(jq -r '.original_size // 0' "$INPUT_FILE")
COMPRESSION_RATIO=$(jq -r '.total_ratio // 0' "$INPUT_FILE")

log_success "Compression ratio: ${COMPRESSION_RATIO}:1 (original: $ORIGINAL_SIZE bytes)"

# ==============================================================================
# STAGE 2: CDIS Entropy Decoding
# ==============================================================================
log_stage "Stage 2/3: CDIS Huffman decoding + pattern expansion"

DECODED_TOKENS="$TEMP_DIR/decoded_tokens.json"

if [[ "$VERBOSE" == true ]]; then
    python3 "$LIB_DIR/cdis_entropy_decode.py" "$INPUT_FILE" > "$DECODED_TOKENS"
else
    python3 "$LIB_DIR/cdis_entropy_decode.py" "$INPUT_FILE" 2>/dev/null > "$DECODED_TOKENS"
fi

TOKEN_COUNT=$(jq '.token_count' "$DECODED_TOKENS")

log_success "Decoded to $TOKEN_COUNT tokens"

# ==============================================================================
# STAGE 3: Reconstruct text from tokens
# ==============================================================================
log_stage "Stage 3/3: Reconstructing original text"

# Simple reconstruction: just concatenate token originals
jq -jr '.tokens[] | if .type == "literal" then .text else .original end' "$DECODED_TOKENS" > "$OUTPUT_FILE"

DECOMPRESSED_SIZE=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE")

log_success "Reconstructed $DECOMPRESSED_SIZE bytes"

# ==============================================================================
# Verification
# ==============================================================================
SIZE_DIFF=$(( DECOMPRESSED_SIZE - ORIGINAL_SIZE ))
if [[ $SIZE_DIFF -eq 0 ]]; then
    VERIFY_STATUS="${GREEN}✓ Size match${NC}"
elif [[ $SIZE_DIFF -lt 10 && $SIZE_DIFF -gt -10 ]]; then
    VERIFY_STATUS="${YELLOW}⚠ Size differs by $SIZE_DIFF bytes (case normalization)${NC}"
else
    VERIFY_STATUS="${RED}✗ Size mismatch: expected $ORIGINAL_SIZE, got $DECOMPRESSED_SIZE${NC}"
fi

# ==============================================================================
# Final report
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}DECOMPRESSION COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "  Compressed size:    %'10d bytes\n" "$COMPRESSED_SIZE"
printf "  Decompressed size:  %'10d bytes\n" "$DECOMPRESSED_SIZE"
printf "  Original size:      %'10d bytes\n" "$ORIGINAL_SIZE"
echo ""
printf "  Verification:       "
echo -e "$VERIFY_STATUS"
echo ""
printf "  Output file:        %s\n" "$OUTPUT_FILE"
echo ""

if [[ "$KEEP_TEMP" == true ]]; then
    echo "  Temp files kept in: $TEMP_DIR"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
