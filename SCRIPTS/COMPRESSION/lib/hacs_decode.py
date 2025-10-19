#!/usr/bin/env python3
"""
HACS Decoder - Reconstruct original text from token stream
Implements lossless decompression using dictionaries
"""
import json
import sys

def load_dictionary(dict_file):
    """Load dictionary and create ID -> original mapping"""
    with open(dict_file, 'r') as f:
        data = json.load(f)
    
    # Create forward mapping: id -> original
    forward_map = {}
    for id_str, entry in data['entries'].items():
        forward_map[id_str] = entry['original']
    
    return forward_map

def decode_tokens(tokens, entity_dict, phrase_dict, word_dict):
    """Reconstruct original text from token stream"""
    result = []
    
    for token in tokens:
        token_type = token['type']
        
        if token_type == 'literal':
            # Literal text - use as-is
            result.append(token['text'])
        elif token_type == 'entity':
            # Entity - use exact original from token (case-preserved during encoding)
            if 'original' in token:
                result.append(token['original'])
            elif token['id'] in entity_dict:
                result.append(entity_dict[token['id']])
            else:
                result.append(f"[UNKNOWN_ENTITY:{token['id']}]")
        elif token_type == 'phrase':
            # Phrase - use exact original from token
            if 'original' in token:
                result.append(token['original'])
            elif token['id'] in phrase_dict:
                result.append(phrase_dict[token['id']])
            else:
                result.append(f"[UNKNOWN_PHRASE:{token['id']}]")
        elif token_type == 'word':
            # Word - use exact original from token
            if 'original' in token:
                result.append(token['original'])
            elif token['id'] in word_dict:
                result.append(word_dict[token['id']])
            else:
                result.append(f"[UNKNOWN_WORD:{token['id']}]")
        else:
            result.append(f"[UNKNOWN_TYPE:{token_type}]")
    
    return ''.join(result)

def main():
    if len(sys.argv) < 2:
        print("Usage: hacs_decode.py <encoded_file.json>", file=sys.stderr)
        print("", file=sys.stderr)
        print("Decodes HACS-compressed token stream back to original text", file=sys.stderr)
        sys.exit(1)
    
    encoded_file = sys.argv[1]
    
    # Load encoded data
    with open(encoded_file, 'r') as f:
        encoded_data = json.load(f)
    
    # Get dictionary paths
    entity_dict_file = encoded_data['dictionaries']['entities']
    phrase_dict_file = encoded_data['dictionaries']['phrases']
    word_dict_file = encoded_data['dictionaries']['words']
    
    # Load dictionaries
    entity_dict = load_dictionary(entity_dict_file)
    phrase_dict = load_dictionary(phrase_dict_file)
    word_dict = load_dictionary(word_dict_file)
    
    # Decode tokens
    tokens = encoded_data['tokens']
    reconstructed = decode_tokens(tokens, entity_dict, phrase_dict, word_dict)
    
    # Output reconstructed text
    print(reconstructed, end='')

if __name__ == "__main__":
    main()
