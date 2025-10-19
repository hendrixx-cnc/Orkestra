#!/usr/bin/env python3
"""
HACS Binary Format Encoder
Converts JSON token stream to compact binary format for true compression
"""
import json
import sys
import struct

def encode_to_binary(encoded_json_file, output_binary_file):
    """
    Convert JSON token stream to binary format:
    
    Format:
    - Header: "HACS" (4 bytes) + version (1 byte) + flags (1 byte)
    - Dictionary count: entities (2 bytes) + phrases (2 bytes) + words (2 bytes)
    - Dictionary paths (null-terminated strings)
    - Token count (4 bytes)
    - Tokens: type (1 byte) + data (variable)
        - Literal: length (2 bytes) + text (UTF-8)
        - Entity/Phrase/Word: ID string length (1 byte) + ID (ASCII)
    """
    # Load JSON
    with open(encoded_json_file, 'r') as f:
        data = json.load(f)
    
    with open(output_binary_file, 'wb') as f:
        # Header
        f.write(b'HACS')  # Magic number
        f.write(struct.pack('B', 3))  # Version 3
        f.write(struct.pack('B', 0))  # Flags (reserved)
        
        # Dictionary stats
        entity_count = data['dictionary_stats']['entities']
        phrase_count = data['dictionary_stats']['phrases']
        word_count = data['dictionary_stats']['words']
        f.write(struct.pack('HHH', entity_count, phrase_count, word_count))
        
        # Dictionary paths (null-terminated)
        for dict_key in ['entities', 'phrases', 'words']:
            path = data['dictionaries'][dict_key]
            f.write(path.encode('utf-8') + b'\x00')
        
        # Token count
        token_count = len(data['tokens'])
        f.write(struct.pack('I', token_count))
        
        # Tokens
        type_map = {'literal': 0, 'entity': 1, 'phrase': 2, 'word': 3}
        
        for token in data['tokens']:
            token_type = token['type']
            f.write(struct.pack('B', type_map[token_type]))
            
            if token_type == 'literal':
                # Literal: length + text
                text = token['text'].encode('utf-8')
                f.write(struct.pack('H', len(text)))
                f.write(text)
            else:
                # ID: length + string (but we need original for lossless)
                id_str = token['id']
                original = token['original']
                
                # Encode: ID length + ID + original length + original
                id_bytes = id_str.encode('ascii')
                orig_bytes = original.encode('utf-8')
                
                f.write(struct.pack('B', len(id_bytes)))
                f.write(id_bytes)
                f.write(struct.pack('H', len(orig_bytes)))
                f.write(orig_bytes)
    
    # Calculate sizes
    json_size = len(json.dumps(data))
    binary_size = open(output_binary_file, 'rb').seek(0, 2)
    
    return json_size, binary_size

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: hacs_to_binary.py <encoded.json> <output.hacs>", file=sys.stderr)
        sys.exit(1)
    
    json_file = sys.argv[1]
    binary_file = sys.argv[2]
    
    json_size, binary_size = encode_to_binary(json_file, binary_file)
    
    print(f"Binary encoding complete:")
    print(f"  JSON size:   {json_size:,} bytes")
    print(f"  Binary size: {binary_size:,} bytes")
    print(f"  Reduction:   {100 * (1 - binary_size/json_size):.1f}%")
