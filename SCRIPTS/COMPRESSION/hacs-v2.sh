#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# HACS V2 - HUMAN-AUDITABLE COMPRESSION SYSTEM (Patent Implementation)
# ═══════════════════════════════════════════════════════════════════════════
# Implements the HACS algorithm as specified in COMBINED_HACS_CDIS_SPECIFICATION.md
# Target: 10:1 compression ratio with human-readable intermediate format
# Output: Multi-level dictionary + token stream
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORKESTRA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

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

# ═══════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════

# Frequency thresholds (as per specification)
PHRASE_THRESHOLD=0.01    # 1% - phrases must appear at least 1% of time
WORD_THRESHOLD=0.001     # 0.1% - words must appear at least 0.1% of time

# Target compression ratio
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
# STEP 1: BUILD MULTI-LEVEL DICTIONARIES
# ═══════════════════════════════════════════════════════════════════════════

build_entity_dictionary() {
    local input_file="$1"
    local output_dict="$2"
    
    log_info "Building Entity Dictionary (E_HACS)..."
    
    # Extract entities using patterns:
    # - Dates: YYYY-MM-DD, MM/DD/YYYY
    # - Emails: user@domain.com
    # - URLs: http(s)://...
    # - IPs: xxx.xxx.xxx.xxx
    # - Names: Capitalized words (heuristic)
    
    python3 << 'PYTHON_EOF' > "$output_dict"
import re
import json
import sys

def extract_entities(text):
    entities = {}
    entity_id = 1
    
    # Date patterns (ISO format)
    dates = re.findall(r'\b\d{4}-\d{2}-\d{2}\b', text)
    for date in set(dates):
        entities[f"D:{date.replace('-', '')}"] = {
            "original": date,
            "type": "date",
            "frequency": dates.count(date)
        }
    
    # Email addresses
    emails = re.findall(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', text)
    for email in set(emails):
        # Use initials + domain
        parts = email.split('@')
        user_initials = ''.join([c for c in parts[0] if c.isupper() or c.isdigit()])[:3]
        domain_parts = parts[1].split('.')
        entity_id_str = f"E:{user_initials}{domain_parts[0][:3]}"
        entities[entity_id_str] = {
            "original": email,
            "type": "email",
            "frequency": emails.count(email)
        }
    
    # URLs
    urls = re.findall(r'https?://[^\s<>"{}|\\^`\[\]]+', text)
    for url in set(urls):
        domain = re.search(r'://([^/]+)', url)
        if domain:
            domain_name = domain.group(1).split('.')[0]
            entity_id_str = f"U:{domain_name[:6]}"
            entities[entity_id_str] = {
                "original": url,
                "type": "url",
                "frequency": urls.count(url)
            }
    
    # IP addresses
    ips = re.findall(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', text)
    for ip in set(ips):
        parts = ip.split('.')
        entity_id_str = f"IP:{parts[0]}{parts[3]}"
        entities[entity_id_str] = {
            "original": ip,
            "type": "ip",
            "frequency": ips.count(ip)
        }
    
    # Proper names (heuristic: capitalized words not at sentence start)
    # This is simplified - production would use NER
    words = text.split()
    for i in range(1, len(words)):
        word = re.sub(r'[^\w]', '', words[i])
        if word and word[0].isupper() and len(word) > 2:
            if word not in entities:
                initials = ''.join([c for c in word if c.isupper()])
                entity_id_str = f"N:{initials[:4]}"
                if entity_id_str not in entities:
                    entities[entity_id_str] = {
                        "original": word,
                        "type": "name",
                        "frequency": 1
                    }
                else:
                    entities[entity_id_str]["frequency"] += 1
    
    return entities

# Read input
input_file = sys.argv[1] if len(sys.argv) > 1 else '/dev/stdin'
with open(input_file, 'r') as f:
    text = f.read()

entities = extract_entities(text)

# Output as JSON
print(json.dumps({
    "type": "entity_dictionary",
    "version": "1.0",
    "count": len(entities),
    "entries": entities
}, indent=2))
PYTHON_EOF

    if [ $? -eq 0 ]; then
        local entity_count=$(jq '.count' "$output_dict")
        log_success "Entity dictionary built: $entity_count entities"
    else
        log_error "Failed to build entity dictionary"
        return 1
    fi
}

build_phrase_dictionary() {
    local input_file="$1"
    local output_dict="$2"
    local threshold="$3"
    
    log_info "Building Phrase Dictionary (P_HACS) with threshold=$threshold..."
    
    python3 - "$input_file" "$threshold" << 'PYTHON_EOF' > "$output_dict"
import re
import json
import sys
from collections import Counter

def extract_phrases(text, threshold):
    # Extract n-grams (2-6 words) and count frequencies
    phrases = {}
    
    # Clean and tokenize
    text = re.sub(r'[^\w\s]', ' ', text.lower())
    words = text.split()
    total_words = len(words)
    
    if total_words == 0:
        return phrases
    
    # Extract n-grams
    for n in range(2, 7):  # 2 to 6 word phrases
        for i in range(len(words) - n + 1):
            phrase = ' '.join(words[i:i+n])
            if phrase not in phrases:
                phrases[phrase] = 0
            phrases[phrase] += 1
    
    # Filter by threshold
    min_count = int(total_words * threshold)
    filtered_phrases = {}
    phrase_id = 1
    
    for phrase, count in phrases.items():
        if count >= max(min_count, 2):  # At least 2 occurrences
            freq = count / total_words
            filtered_phrases[f"P{phrase_id:04d}"] = {
                "original": phrase,
                "frequency": freq,
                "count": count
            }
            phrase_id += 1
    
    return filtered_phrases

# Read input
input_file = sys.argv[1] if len(sys.argv) > 1 else '/dev/stdin'
threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 0.01

with open(input_file, 'r') as f:
    text = f.read()

phrases = extract_phrases(text, threshold)

# Output as JSON
print(json.dumps({
    "type": "phrase_dictionary",
    "version": "1.0",
    "threshold": threshold,
    "count": len(phrases),
    "entries": phrases
}, indent=2))
PYTHON_EOF

    if [ $? -eq 0 ]; then
        local phrase_count=$(jq '.count' "$output_dict")
        log_success "Phrase dictionary built: $phrase_count phrases"
    else
        log_error "Failed to build phrase dictionary"
        return 1
    fi
}

build_word_dictionary() {
    local input_file="$1"
    local output_dict="$2"
    local threshold="$3"
    
    log_info "Building Word Dictionary (W_HACS) with threshold=$threshold..."
    
    python3 - "$input_file" "$threshold" << 'PYTHON_EOF' > "$output_dict"
import re
import json
import sys
from collections import Counter

def extract_words(text, threshold):
    # Extract individual words and count frequencies
    words = {}
    
    # Clean and tokenize
    text = re.sub(r'[^\w\s]', ' ', text.lower())
    word_list = text.split()
    total_words = len(word_list)
    
    if total_words == 0:
        return words
    
    # Count word frequencies
    word_counts = Counter(word_list)
    
    # Common words get short IDs (like "the" -> "_th")
    common_words = [
        ("the", "_th"), ("be", "_be"), ("to", "_to"), ("of", "_of"),
        ("and", "_and"), ("a", "_a"), ("in", "_in"), ("that", "_that"),
        ("have", "_hv"), ("i", "_i"), ("it", "_it"), ("for", "_for"),
        ("not", "_not"), ("on", "_on"), ("with", "_wth"), ("he", "_he"),
        ("as", "_as"), ("you", "_you"), ("do", "_do"), ("at", "_at"),
        ("this", "_ths"), ("but", "_but"), ("his", "_his"), ("by", "_by"),
        ("from", "_frm"), ("they", "_thy"), ("we", "_we"), ("say", "_say"),
        ("her", "_her"), ("she", "_she"), ("or", "_or"), ("an", "_an"),
        ("will", "_wl"), ("my", "_my"), ("one", "_one"), ("all", "_all"),
        ("would", "_wd"), ("there", "_thr"), ("their", "_thr")
    ]
    
    filtered_words = {}
    
    # Add common words first
    for word, word_id in common_words:
        if word in word_counts:
            filtered_words[word_id] = {
                "original": word,
                "frequency": word_counts[word] / total_words,
                "count": word_counts[word]
            }
    
    # Add other frequent words
    min_count = int(total_words * threshold)
    word_id = 1
    
    for word, count in word_counts.items():
        if count >= max(min_count, 3):  # At least 3 occurrences
            # Skip if already in common words
            if any(word == w[0] for w in common_words):
                continue
            
            freq = count / total_words
            # Generate mnemonic ID (first 3-4 chars)
            mnemonic = word[:4] if len(word) > 3 else word
            word_id_str = f"W:{mnemonic}{word_id:03d}"
            
            filtered_words[word_id_str] = {
                "original": word,
                "frequency": freq,
                "count": count
            }
            word_id += 1
    
    return filtered_words

# Read input
input_file = sys.argv[1] if len(sys.argv) > 1 else '/dev/stdin'
threshold = float(sys.argv[2]) if len(sys.argv) > 2 else 0.001

with open(input_file, 'r') as f:
    text = f.read()

words = extract_words(text, threshold)

# Output as JSON
print(json.dumps({
    "type": "word_dictionary",
    "version": "1.0",
    "threshold": threshold,
    "count": len(words),
    "entries": words
}, indent=2))
PYTHON_EOF

    if [ $? -eq 0 ]; then
        local word_count=$(jq '.count' "$output_dict")
        log_success "Word dictionary built: $word_count words"
    else
        log_error "Failed to build word dictionary"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2: ENCODE INPUT USING LONGEST-MATCH-FIRST
# ═══════════════════════════════════════════════════════════════════════════

encode_with_dictionaries() {
    local input_file="$1"
    local entity_dict="$2"
    local phrase_dict="$3"
    local word_dict="$4"
    local output_file="$5"
    
    log_info "Encoding input using multi-level dictionaries..."
    
    python3 - "$input_file" "$entity_dict" "$phrase_dict" "$word_dict" << 'PYTHON_EOF' > "$output_file"
import json
import sys
import re

def load_dictionary(dict_file):
    with open(dict_file, 'r') as f:
        data = json.load(f)
    
    # Create reverse mapping: original -> id
    reverse_map = {}
    for id, entry in data['entries'].items():
        original = entry['original']
        reverse_map[original] = id
    
    return reverse_map, data

def longest_match_encode(text, entity_dict, phrase_dict, word_dict):
    """
    Encode text using longest-match-first strategy.
    Priority: Entity > Phrase > Word > Literal
    """
    tokens = []
    position = 0
    text_lower = text.lower()
    
    while position < len(text):
        matched = False
        match_len = 0
        match_id = None
        match_type = None
        
        # Try Entity match first
        for original, eid in entity_dict.items():
            if text[position:position+len(original)] == original:
                if len(original) > match_len:
                    match_len = len(original)
                    match_id = eid
                    match_type = "entity"
                    matched = True
        
        # Try Phrase match (on lowercase)
        if not matched:
            for original, pid in phrase_dict.items():
                # Check if phrase matches at current position
                if text_lower[position:position+len(original)] == original:
                    # Verify word boundaries
                    if (position == 0 or not text[position-1].isalnum()) and \
                       (position+len(original) >= len(text) or not text[position+len(original)].isalnum()):
                        if len(original) > match_len:
                            match_len = len(original)
                            match_id = pid
                            match_type = "phrase"
                            matched = True
        
        # Try Word match (on lowercase)
        if not matched:
            # Extract next word
            word_match = re.match(r'\w+', text[position:])
            if word_match:
                word = word_match.group(0).lower()
                if word in word_dict:
                    match_len = len(word)
                    match_id = word_dict[word]
                    match_type = "word"
                    matched = True
        
        if matched:
            # Add matched token
            tokens.append({
                "type": match_type,
                "id": match_id,
                "position": position,
                "length": match_len
            })
            position += match_len
        else:
            # Add literal character
            char = text[position]
            # Combine consecutive literals
            if tokens and tokens[-1]["type"] == "literal":
                tokens[-1]["text"] += char
            else:
                tokens.append({
                    "type": "literal",
                    "text": char,
                    "position": position,
                    "length": 1
                })
            position += 1
    
    return tokens

# Read inputs
input_file = sys.argv[1]
entity_dict_file = sys.argv[2]
phrase_dict_file = sys.argv[3]
word_dict_file = sys.argv[4]

with open(input_file, 'r') as f:
    text = f.read()

entity_dict, entity_data = load_dictionary(entity_dict_file)
phrase_dict, phrase_data = load_dictionary(phrase_dict_file)
word_dict, word_data = load_dictionary(word_dict_file)

# Encode
tokens = longest_match_encode(text, entity_dict, phrase_dict, word_dict)

# Calculate compression stats
original_size = len(text)
encoded_size = 0
for token in tokens:
    if token["type"] == "literal":
        encoded_size += len(token["text"])
    else:
        encoded_size += len(token["id"]) + 2  # ID + delimiters

compression_ratio = original_size / encoded_size if encoded_size > 0 else 0

# Output
output = {
    "type": "hacs_encoded",
    "version": "1.0",
    "original_size": original_size,
    "encoded_size": encoded_size,
    "compression_ratio": round(compression_ratio, 2),
    "token_count": len(tokens),
    "tokens": tokens,
    "dictionaries": {
        "entities": entity_dict_file,
        "phrases": phrase_dict_file,
        "words": word_dict_file
    }
}

print(json.dumps(output, indent=2))
PYTHON_EOF

    if [ $? -eq 0 ]; then
        local ratio=$(jq '.compression_ratio' "$output_file")
        local token_count=$(jq '.token_count' "$output_file")
        log_success "Encoding complete: ${token_count} tokens, ${ratio}:1 compression"
    else
        log_error "Failed to encode input"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN COMPRESSION WORKFLOW
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
    echo -e "${BOLD}  HACS V2 - Human-Auditable Compression System${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Step 1: Build dictionaries
    echo -e "${CYAN}Step 1/2: Building Multi-Level Dictionaries${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    build_entity_dictionary "$input_file" "$entity_dict" || return 1
    build_phrase_dictionary "$input_file" "$phrase_dict" "$PHRASE_THRESHOLD" || return 1
    build_word_dictionary "$input_file" "$word_dict" "$WORD_THRESHOLD" || return 1
    
    echo ""
    
    # Step 2: Encode
    echo -e "${CYAN}Step 2/2: Encoding with Longest-Match-First${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    encode_with_dictionaries "$input_file" "$entity_dict" "$phrase_dict" "$word_dict" "$encoded_file" || return 1
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  HACS Compression Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Output files:"
    echo "  • Entity Dictionary:  $entity_dict"
    echo "  • Phrase Dictionary:  $phrase_dict"
    echo "  • Word Dictionary:    $word_dict"
    echo "  • Encoded Stream:     $encoded_file"
    echo ""
    
    # Display statistics
    local original_size=$(stat -f%z "$input_file" 2>/dev/null || stat -c%s "$input_file")
    local ratio=$(jq '.compression_ratio' "$encoded_file")
    local tokens=$(jq '.token_count' "$encoded_file")
    
    echo "Statistics:"
    echo "  • Original size:      $(numfmt --to=iec --format="%.2f" $original_size 2>/dev/null || echo "$original_size bytes")"
    echo "  • Compression ratio:  ${ratio}:1"
    echo "  • Token count:        $tokens"
    echo "  • Target ratio:       ${TARGET_RATIO}:1"
    
    if (( $(echo "$ratio >= $TARGET_RATIO" | bc -l) )); then
        echo -e "  • Status:             ${GREEN}✓ Target achieved!${NC}"
    else
        echo -e "  • Status:             ${YELLOW}⚠ Below target (${ratio}/${TARGET_RATIO})${NC}"
    fi
    
    echo ""
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
        
    help
        Show this help message

Examples:
    # Compress a text file
    $0 compress document.txt /tmp/compressed
    
    # This will create:
    #   /tmp/compressed_entities.json
    #   /tmp/compressed_phrases.json
    #   /tmp/compressed_words.json
    #   /tmp/compressed_encoded.json

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
