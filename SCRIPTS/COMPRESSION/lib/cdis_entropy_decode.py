#!/usr/bin/env python3
"""
CDIS Entropy Decoder - Reverse Huffman Coding

Decodes Huffman-compressed token stream back to original tokens.
"""

import json
import sys
from collections import deque

def hex_to_bytes(hex_string):
    """Convert hex string to byte array"""
    return bytearray.fromhex(hex_string)

def bytes_to_bits(byte_array, total_bits, padding_bits):
    """Convert bytes to bit string, removing padding"""
    bitstring = ''.join(f'{b:08b}' for b in byte_array)
    # Remove padding bits
    if padding_bits > 0:
        bitstring = bitstring[:-padding_bits]
    return bitstring

def build_decoding_tree(huffman_codes):
    """Build decoding tree from Huffman codes
    
    Tree structure:
    - Each node is a dict with keys '0' and '1' for children
    - Leaf nodes have a 'symbol' key
    """
    root = {}
    
    for symbol_str, code in huffman_codes.items():
        # Parse symbol from string representation
        symbol = eval(symbol_str)
        
        # Navigate/build tree
        node = root
        for bit in code[:-1]:  # All but last bit
            if bit not in node:
                node[bit] = {}
            node = node[bit]
        
        # Last bit leads to leaf
        node[code[-1]] = {'symbol': symbol}
    
    return root

def decode_huffman(bitstring, decoding_tree):
    """Decode bit string using Huffman tree"""
    tokens = []
    node = decoding_tree
    
    for bit in bitstring:
        # Traverse tree
        if bit not in node:
            raise ValueError(f"Invalid bit sequence at position {len(tokens)}")
        
        node = node[bit]
        
        # Check if leaf
        if 'symbol' in node:
            tokens.append(node['symbol'])
            node = decoding_tree  # Reset to root
    
    if node != decoding_tree:
        raise ValueError("Bit string ended mid-symbol")
    
    return tokens

def reconstruct_token_objects(token_keys, patterns, hacs_data):
    """Convert token keys back to full token objects
    
    Token keys are tuples like:
    - ('L', 'text') for literals
    - ('P', 'P0001') for patterns
    - ('W', 'W:word001') for words
    - ('F', 'P0123') for phrases
    - ('E', 'E0001') for entities
    """
    tokens = []
    position = 0
    
    for key in token_keys:
        # Handle both 2-tuple (old/backward compat) and 3-tuple (new with case variant)
        original_case = None
        
        if len(key) == 3:
            token_type_code, token_id, original_case = key
        elif len(key) == 2:
            token_type_code, token_id = key
            # Normalize old single-letter codes to new explicit names
            if token_type_code == 'W':
                token_type_code = 'WORD'
            elif token_type_code == 'P':
                # Could be PHRASE or PATTERN depending on ID
                if token_id.startswith('C'):
                    token_type_code = 'PATTERN'
                else:
                    token_type_code = 'PHRASE'
            elif token_type_code == 'E':
                token_type_code = 'ENTITY'
            elif token_type_code == 'F':
                token_type_code = 'PHRASE'
        else:
            raise ValueError(f"Invalid token key format: {key}")
        
        if token_type_code == 'L':
            # Literal text
            text = token_id
            token = {
                'type': 'literal',
                'text': text,
                'position': position,
                'length': len(text)
            }
            position += len(text)
        
        elif token_type_code == 'PATTERN':
            # CDIS pattern (C####) - need to expand recursively
            if token_id not in patterns:
                raise ValueError(f"Unknown CDIS pattern: {token_id}")
            
            pattern_data = patterns[token_id]
            pattern_sequence = pattern_data['sequence']
            
            # Convert sequence tuples to token keys
            pattern_keys = [tuple(item) for item in pattern_sequence]
            
            # Recursively reconstruct pattern tokens
            expanded = reconstruct_token_objects(
                pattern_keys,
                patterns,
                hacs_data
            )
            tokens.extend(expanded)
            continue
        
        elif token_type_code == 'PHRASE':
            # HACS phrase (P####)
            phrase_dict = hacs_data.get('phrases', {})
            if token_id not in phrase_dict:
                raise ValueError(f"Unknown phrase ID: {token_id}")
            
            # Use original_case if available (from 3-tuple key), else fall back to dictionary
            phrase = original_case if original_case else phrase_dict[token_id]
            token = {
                'type': 'phrase',
                'id': token_id,
                'original': phrase,
                'position': position,
                'length': len(phrase)
            }
            position += len(phrase)
        
        elif token_type_code == 'WORD':
            # Word from HACS dictionary
            word_dict = hacs_data.get('words', {})
            if token_id not in word_dict:
                raise ValueError(f"Unknown word ID: {token_id}")
            
            # Use original_case if available (from 3-tuple key), else fall back to dictionary
            word = original_case if original_case else word_dict[token_id]
            token = {
                'type': 'word',
                'id': token_id,
                'original': word,
                'position': position,
                'length': len(word)
            }
            position += len(word)
        
        elif token_type_code == 'ENTITY':
            # Entity from HACS dictionary
            entity_dict = hacs_data.get('entities', {})
            if token_id not in entity_dict:
                raise ValueError(f"Unknown entity ID: {token_id}")
            
            # Use original_case if available (from 3-tuple key), else fall back to dictionary
            entity = original_case if original_case else entity_dict[token_id]
            token = {
                'type': 'entity',
                'id': token_id,
                'original': entity,
                'position': position,
                'length': len(entity)
            }
            position += len(entity)
        
        else:
            raise ValueError(f"Unknown token type: {token_type_code}")
        
        tokens.append(token)
    
    return tokens

def load_hacs_dictionaries(hacs_dict_paths):
    """Load HACS dictionaries from file paths"""
    hacs_data = {}
    
    if 'entities' in hacs_dict_paths:
        with open(hacs_dict_paths['entities'], 'r') as f:
            dict_data = json.load(f)
            # Extract {id: original} mapping
            hacs_data['entities'] = {
                k: v['original'] 
                for k, v in dict_data.get('entries', {}).items()
            }
    
    if 'phrases' in hacs_dict_paths:
        with open(hacs_dict_paths['phrases'], 'r') as f:
            dict_data = json.load(f)
            hacs_data['phrases'] = {
                k: v['original'] 
                for k, v in dict_data.get('entries', {}).items()
            }
    
    if 'words' in hacs_dict_paths:
        with open(hacs_dict_paths['words'], 'r') as f:
            dict_data = json.load(f)
            hacs_data['words'] = {
                k: v['original'] 
                for k, v in dict_data.get('entries', {}).items()
            }
    
    return hacs_data

def main():
    if len(sys.argv) < 2:
        print("Usage: cdis_entropy_decode.py <compressed.json>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Load compressed data
    with open(input_file, 'r') as f:
        compressed_data = json.load(f)
    
    print(f"Decoding from {compressed_data['entropy_size']} bytes...", file=sys.stderr)
    
    # Extract compression metadata
    huffman_codes = compressed_data['huffman_codes']
    compressed_hex = compressed_data['compressed_data']
    padding_bits = compressed_data['huffman_stats']['padding_bits']
    compressed_bits = compressed_data['huffman_stats']['compressed_bits']
    patterns = compressed_data.get('patterns', {})
    hacs_dict_paths = compressed_data.get('hacs_dictionaries', {})
    
    # Step 1: Convert hex to bits
    byte_array = hex_to_bytes(compressed_hex)
    bitstring = bytes_to_bits(byte_array, compressed_bits, padding_bits)
    print(f"Converted to {len(bitstring)} bits", file=sys.stderr)
    
    # Step 2: Build decoding tree
    decoding_tree = build_decoding_tree(huffman_codes)
    print(f"Built decoding tree from {len(huffman_codes)} codes", file=sys.stderr)
    
    # Step 3: Decode bit string
    token_keys = decode_huffman(bitstring, decoding_tree)
    print(f"Decoded to {len(token_keys)} tokens", file=sys.stderr)
    
    # Step 4: Load HACS dictionaries
    hacs_data = load_hacs_dictionaries(hacs_dict_paths)
    print(f"Loaded HACS dictionaries", file=sys.stderr)
    
    # Step 5: Reconstruct full token objects
    tokens = reconstruct_token_objects(token_keys, patterns, hacs_data)
    print(f"Reconstructed {len(tokens)} full tokens", file=sys.stderr)
    
    # Output result
    result = {
        'type': 'cdis_decoded',
        'version': '1.0',
        'tokens': tokens,
        'token_count': len(tokens),
        'original_size': compressed_data.get('original_size', 0)
    }
    
    print(json.dumps(result, indent=2))
    print(f"\n✓ CDIS decoding complete", file=sys.stderr)

if __name__ == '__main__':
    main()
