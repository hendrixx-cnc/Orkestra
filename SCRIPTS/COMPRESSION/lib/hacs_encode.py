#!/usr/bin/env python3
"""
HACS Encoder - Compress text using multi-level dictionaries
Implements longest-match-first with case preservation
"""
import json
import sys
import re

def load_dictionary(dict_file):
    """Load dictionary and create reverse mapping"""
    with open(dict_file, 'r') as f:
        data = json.load(f)
    
    # Create reverse mapping: original -> id
    reverse_map = {}
    for id_str, entry in data['entries'].items():
        original = entry['original']
        reverse_map[original] = id_str
        # Also map lowercase version for case-insensitive matching
        if 'case_sensitive' in entry and entry['case_sensitive']:
            reverse_map[original.lower()] = id_str
    
    return reverse_map, data

def longest_match_encode(text, entity_dict, phrase_dict, word_dict):
    """
    Encode text using longest-match-first strategy
    Priority: Entity > Phrase > Word > Literal
    """
    tokens = []
    position = 0
    
    while position < len(text):
        matched = False
        match_len = 0
        match_id = None
        match_type = None
        match_original = None
        
        # Try Entity match (exact match required)
        for original, eid in entity_dict.items():
            if text[position:position+len(original)] == original:
                if len(original) > match_len:
                    match_len = len(original)
                    match_id = eid
                    match_type = "entity"
                    match_original = original
                    matched = True
        
        # Try Phrase match (case-insensitive with word boundaries)
        if not matched:
            # Look ahead to extract potential phrase
            remaining = text[position:]
            # Extract up to 10 words ahead
            words_ahead = re.findall(r'\b\w+\b', remaining[:200])
            
            # Try different phrase lengths (longest first)
            for n in range(min(6, len(words_ahead)), 1, -1):
                phrase = ' '.join(words_ahead[:n])
                phrase_lower = phrase.lower()
                
                if phrase_lower in phrase_dict:
                    # Verify this phrase actually appears at current position
                    # Account for whitespace/punctuation variations
                    phrase_pattern = r'\b' + re.escape(phrase).replace(r'\ ', r'\s+') + r'\b'
                    match_obj = re.match(phrase_pattern, remaining, re.IGNORECASE)
                    
                    if match_obj:
                        matched_text = match_obj.group(0)
                        if len(matched_text) > match_len:
                            match_len = len(matched_text)
                            match_id = phrase_dict[phrase_lower]
                            match_type = "phrase"
                            match_original = matched_text
                            matched = True
                            break
        
        # Try Word match (case-insensitive)
        if not matched:
            word_match = re.match(r'\b(\w+)\b', text[position:])
            if word_match:
                word = word_match.group(1)
                word_lower = word.lower()
                
                if word_lower in word_dict:
                    match_len = len(word)
                    match_id = word_dict[word_lower]
                    match_type = "word"
                    match_original = word
                    matched = True
        
        if matched:
            # Add matched token
            tokens.append({
                "type": match_type,
                "id": match_id,
                "original": match_original,  # Store for verification
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
                tokens[-1]["length"] += 1
            else:
                tokens.append({
                    "type": "literal",
                    "text": char,
                    "position": position,
                    "length": 1
                })
            position += 1
    
    return tokens

def main():
    if len(sys.argv) < 5:
        print("Usage: hacs_encode.py <input_file> <entity_dict> <phrase_dict> <word_dict>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    entity_dict_file = sys.argv[2]
    phrase_dict_file = sys.argv[3]
    word_dict_file = sys.argv[4]
    
    # Load input text
    with open(input_file, 'r') as f:
        text = f.read()
    
    # Load dictionaries
    entity_dict, entity_data = load_dictionary(entity_dict_file)
    phrase_dict, phrase_data = load_dictionary(phrase_dict_file)
    word_dict, word_data = load_dictionary(word_dict_file)
    
    # Encode
    tokens = longest_match_encode(text, entity_dict, phrase_dict, word_dict)
    
    # Calculate compression stats
    original_size = len(text)
    
    # Estimate encoded size more accurately
    encoded_size = 0
    for token in tokens:
        if token["type"] == "literal":
            encoded_size += len(token["text"])
        else:
            # ID + delimiters (more realistic than before)
            encoded_size += len(token["id"]) + 2
    
    compression_ratio = original_size / encoded_size if encoded_size > 0 else 0
    
    # Calculate token type statistics
    token_stats = {"entity": 0, "phrase": 0, "word": 0, "literal": 0}
    for token in tokens:
        token_stats[token["type"]] += 1
    
    # Output
    output = {
        "type": "hacs_encoded",
        "version": "2.0",
        "original_size": original_size,
        "encoded_size": encoded_size,
        "compression_ratio": round(compression_ratio, 2),
        "token_count": len(tokens),
        "token_stats": token_stats,
        "tokens": tokens,
        "dictionaries": {
            "entities": entity_dict_file,
            "phrases": phrase_dict_file,
            "words": word_dict_file
        },
        "dictionary_stats": {
            "entities": entity_data["count"],
            "phrases": phrase_data["count"],
            "words": word_data["count"]
        }
    }
    
    print(json.dumps(output, indent=2))

if __name__ == "__main__":
    main()
