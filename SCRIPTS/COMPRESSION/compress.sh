#!/usr/bin/env bash
#
# HACS-CDIS Compression Pipeline
# Compresses files using hierarchical dictionaries + pattern detection + entropy coding
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
Usage: $(basename "$0") [OPTIONS] <input_file>

Compress a file using the HACS-CDIS algorithm.

OPTIONS:
    -o, --output FILE    Output file (default: input_file.hc)
    -v, --verbose        Verbose output
    -k, --keep-temp      Keep temporary files
    -h, --help           Show this help message

EXAMPLES:
    # Compress a file
    $(basename "$0") readme.md

    # Compress with custom output
    $(basename "$0") -o compressed.hc readme.md

    # Verbose mode
    $(basename "$0") -v readme.md

STAGES:
    1. HACS: Build dictionaries (entities, phrases, words)
    2. HACS: Encode with longest-match-first
    3. CDIS: Detect recurring token patterns
    4. CDIS: Huffman entropy encoding
    5. Output: Compressed binary file

COMPRESSION RATIO:
    Typical: 10-20:1 for structured text
    Best case: 50-100:1 for highly repetitive files
EOF
    exit 0
}

log() {
    echo -e "${BLUE}[COMPRESS]${NC} $*" >&2
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
    OUTPUT_FILE="${INPUT_FILE}.hc"
fi

# Create temp directory
TEMP_DIR=$(mktemp -d)
trap 'if [[ "$KEEP_TEMP" != true ]]; then rm -rf "$TEMP_DIR"; fi' EXIT

log "Starting compression pipeline"
log "Input: $INPUT_FILE ($(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE") bytes)"
log "Output: $OUTPUT_FILE"
log "Temp dir: $TEMP_DIR"

ORIGINAL_SIZE=$(stat -f%z "$INPUT_FILE" 2>/dev/null || stat -c%s "$INPUT_FILE")

# ==============================================================================
# STAGE 1: HACS Dictionary Building
# ==============================================================================
log_stage "Stage 1/4: Building HACS dictionaries"

ENTITY_DICT="$TEMP_DIR/entities.json"
PHRASE_DICT="$TEMP_DIR/phrases.json"
WORD_DICT="$TEMP_DIR/words.json"

if [[ "$VERBOSE" == true ]]; then
    python3 "$LIB_DIR/build_entity_dict.py" "$INPUT_FILE" "$ENTITY_DICT"
    python3 "$LIB_DIR/build_phrase_dict.py" "$INPUT_FILE" "$PHRASE_DICT"
    python3 "$LIB_DIR/build_word_dict.py" "$INPUT_FILE" "$WORD_DICT"
else
    python3 "$LIB_DIR/build_entity_dict.py" "$INPUT_FILE" "$ENTITY_DICT" 2>/dev/null
    python3 "$LIB_DIR/build_phrase_dict.py" "$INPUT_FILE" "$PHRASE_DICT" 2>/dev/null
    python3 "$LIB_DIR/build_word_dict.py" "$INPUT_FILE" "$WORD_DICT" 2>/dev/null
fi

ENTITY_COUNT=$(jq '.count' "$ENTITY_DICT")
PHRASE_COUNT=$(jq '.count' "$PHRASE_DICT")
WORD_COUNT=$(jq '.count' "$WORD_DICT")

log_success "Entities: $ENTITY_COUNT, Phrases: $PHRASE_COUNT, Words: $WORD_COUNT"

# ==============================================================================
# STAGE 2: HACS Encoding
# ==============================================================================
log_stage "Stage 2/4: HACS token encoding"

HACS_OUTPUT="$TEMP_DIR/hacs_encoded.json"

if [[ "$VERBOSE" == true ]]; then
    python3 "$LIB_DIR/hacs_encode.py" \
        "$INPUT_FILE" \
        "$ENTITY_DICT" \
        "$PHRASE_DICT" \
        "$WORD_DICT" \
        "$HACS_OUTPUT"
else
    python3 "$LIB_DIR/hacs_encode.py" \
        "$INPUT_FILE" \
        "$ENTITY_DICT" \
        "$PHRASE_DICT" \
        "$WORD_DICT" \
        "$HACS_OUTPUT" 2>/dev/null
fi

HACS_SIZE=$(stat -f%z "$HACS_OUTPUT" 2>/dev/null || stat -c%s "$HACS_OUTPUT")
HACS_TOKENS=$(jq '.tokens | length' "$HACS_OUTPUT")

log_success "Encoded to $HACS_TOKENS tokens ($HACS_SIZE bytes JSON)"

# ==============================================================================
# STAGE 3: CDIS Pattern Detection
# ==============================================================================
log_stage "Stage 3/4: CDIS pattern detection"

CDIS_PATTERNS="$TEMP_DIR/cdis_patterns.json"

if [[ "$VERBOSE" == true ]]; then
    python3 "$LIB_DIR/cdis_detect_patterns.py" "$HACS_OUTPUT" > "$CDIS_PATTERNS"
else
    python3 "$LIB_DIR/cdis_detect_patterns.py" "$HACS_OUTPUT" > "$CDIS_PATTERNS" 2>/dev/null
fi

PATTERN_COUNT=$(jq '.pattern_count' "$CDIS_PATTERNS")
SUBSTITUTED_TOKENS=$(jq '.substituted_tokens | length' "$CDIS_PATTERNS")

log_success "Found $PATTERN_COUNT patterns, reduced to $SUBSTITUTED_TOKENS tokens"

# ==============================================================================
# STAGE 4: CDIS Entropy Encoding
# ==============================================================================
log_stage "Stage 4/4: Huffman entropy encoding"

COMPRESSED_OUTPUT="$TEMP_DIR/compressed.json"

if [[ "$VERBOSE" == true ]]; then
    python3 "$LIB_DIR/cdis_entropy_encode_v2.py" "$CDIS_PATTERNS" > "$COMPRESSED_OUTPUT"
else
    python3 "$LIB_DIR/cdis_entropy_encode_v2.py" "$CDIS_PATTERNS" 2>/dev/null > "$COMPRESSED_OUTPUT"
fi

COMPRESSED_SIZE=$(jq '.entropy_size' "$COMPRESSED_OUTPUT")
TOTAL_RATIO=$(jq '.total_ratio' "$COMPRESSED_OUTPUT")

log_success "Compressed to $COMPRESSED_SIZE bytes"

# ==============================================================================
# Save compressed file
# ==============================================================================
cp "$COMPRESSED_OUTPUT" "$OUTPUT_FILE"

# ==============================================================================
# Final report
# ==============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}COMPRESSION COMPLETE${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
printf "  Original size:      %'10d bytes\n" "$ORIGINAL_SIZE"
printf "  Compressed size:    %'10d bytes\n" "$COMPRESSED_SIZE"
printf "  Compression ratio:  %10.2f:1\n" "$TOTAL_RATIO"
printf "  Space saved:        %10d%%\n" $(( 100 - (COMPRESSED_SIZE * 100 / ORIGINAL_SIZE) ))
echo ""
printf "  Output file:        %s\n" "$OUTPUT_FILE"
echo ""

if [[ "$KEEP_TEMP" == true ]]; then
    echo "  Temp files kept in: $TEMP_DIR"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
