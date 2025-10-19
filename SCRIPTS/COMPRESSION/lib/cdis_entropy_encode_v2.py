#!/usr/bin/env python3
"""
CDIS Entropy Encoder V2 - Token-Level Huffman Coding

This version encodes full tokens (not characters) using Huffman coding.
Each token gets a variable-length code based on frequency.
"""

import json
import sys
from collections import Counter
from heapq import heappush, heappop

class HuffmanNode:
    def __init__(self, symbol=None, freq=0, left=None, right=None):
        self.symbol = symbol
        self.freq = freq
        self.left = left
        self.right = right
    
    def __lt__(self, other):
        return self.freq < other.freq

def token_to_key(token):
    """Convert token dict to hashable key including case variant for lossless compression"""
    if token['type'] == 'literal':
        return ('L', token['text'])
    elif token['type'] == 'pattern':
        # Pattern IDs are like C0001, C0002 (CDIS patterns)
        return ('PATTERN', token['id'])
    elif token['type'] == 'phrase':
        # Phrase IDs are like P0001, P0002 (HACS phrases)
        # Include original case variant to preserve exact capitalization
        return ('PHRASE', token['id'], token.get('original', ''))
    elif token['type'] == 'word':
        # Include original case variant to preserve exact capitalization
        return ('WORD', token['id'], token.get('original', ''))
    elif token['type'] == 'entity':
        # Include original case variant to preserve exact capitalization
        return ('ENTITY', token['id'], token.get('original', ''))
    else:
        raise ValueError(f"Unknown token type: {token['type']}")

def build_frequency_table(tokens):
    """Count token occurrences"""
    token_keys = [token_to_key(t) for t in tokens]
    return Counter(token_keys)

def build_huffman_tree(frequencies):
    """Build Huffman tree from frequency table"""
    if len(frequencies) == 1:
        # Special case: only one symbol
        symbol = list(frequencies.keys())[0]
        return HuffmanNode(symbol=symbol, freq=frequencies[symbol])
    
    heap = []
    for symbol, freq in frequencies.items():
        heappush(heap, HuffmanNode(symbol=symbol, freq=freq))
    
    while len(heap) > 1:
        left = heappop(heap)
        right = heappop(heap)
        parent = HuffmanNode(freq=left.freq + right.freq, left=left, right=right)
        heappush(heap, parent)
    
    return heap[0]

def generate_huffman_codes(root, prefix='', codes=None):
    """Generate variable-length codes from Huffman tree"""
    if codes is None:
        codes = {}
    
    if root is None:
        return codes
    
    # Leaf node
    if root.symbol is not None:
        codes[root.symbol] = prefix if prefix else '0'
        return codes
    
    # Traverse tree
    generate_huffman_codes(root.left, prefix + '0', codes)
    generate_huffman_codes(root.right, prefix + '1', codes)
    
    return codes

def encode_tokens(tokens, huffman_codes):
    """Encode tokens using Huffman codes"""
    bitstring = ''
    for token in tokens:
        key = token_to_key(token)
        bitstring += huffman_codes[key]
    return bitstring

def bits_to_bytes(bitstring):
    """Convert bit string to bytes with padding"""
    # Pad to multiple of 8
    padding = (8 - len(bitstring) % 8) % 8
    bitstring += '0' * padding
    
    # Convert to bytes
    byte_array = bytearray()
    for i in range(0, len(bitstring), 8):
        byte = int(bitstring[i:i+8], 2)
        byte_array.append(byte)
    
    return byte_array, padding

def bytes_to_hex(byte_array):
    """Convert bytes to hex string for JSON storage"""
    return ''.join(f'{b:02x}' for b in byte_array)

def main():
    if len(sys.argv) < 2:
        print("Usage: cdis_entropy_encode_v2.py <cdis_patterns.json>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Load CDIS pattern-detected data
    with open(input_file, 'r') as f:
        cdis_data = json.load(f)
    
    tokens = cdis_data['substituted_tokens']
    original_size = cdis_data['original_size']
    hacs_size = cdis_data.get('hacs_size', 0)
    
    print(f"Encoding {len(tokens)} tokens with Huffman coding...", file=sys.stderr)
    
    # Step 1: Build frequency table
    frequencies = build_frequency_table(tokens)
    print(f"Found {len(frequencies)} unique token types", file=sys.stderr)
    
    # Step 2: Build Huffman tree
    huffman_tree = build_huffman_tree(frequencies)
    
    # Step 3: Generate codes
    huffman_codes = generate_huffman_codes(huffman_tree)
    print(f"Generated {len(huffman_codes)} Huffman codes", file=sys.stderr)
    
    # Show most common tokens
    print(f"\nMost frequent tokens:", file=sys.stderr)
    for token_key, freq in sorted(frequencies.items(), key=lambda x: -x[1])[:10]:
        code = huffman_codes[token_key]
        print(f"  {token_key}: '{code}' (freq={freq})", file=sys.stderr)
    
    # Step 4: Encode token stream
    encoded_bits = encode_tokens(tokens, huffman_codes)
    print(f"\nEncoded to {len(encoded_bits)} bits", file=sys.stderr)
    
    # Step 5: Convert to bytes
    byte_array, padding = bits_to_bytes(encoded_bits)
    compressed_size = len(byte_array)
    print(f"Compressed to {compressed_size} bytes (padding={padding})", file=sys.stderr)
    
    # Calculate statistics
    cdis_pattern_size = len(json.dumps(cdis_data['substituted_tokens']))
    
    hacs_ratio = original_size / hacs_size if hacs_size > 0 else 0
    pattern_ratio = hacs_size / cdis_pattern_size if cdis_pattern_size > 0 else 0
    entropy_ratio = cdis_pattern_size / compressed_size if compressed_size > 0 else 0
    total_ratio = original_size / compressed_size if compressed_size > 0 else 0
    
    # Average code length
    total_bits = sum(frequencies[key] * len(huffman_codes[key]) for key in huffman_codes)
    total_symbols = sum(frequencies.values())
    avg_code_length = total_bits / total_symbols if total_symbols > 0 else 0
    
    print(f"\n{'='*60}", file=sys.stderr)
    print(f"Compression Pipeline Results:", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)
    print(f"Original size:        {original_size:,} bytes", file=sys.stderr)
    print(f"After HACS:           {hacs_size:,} bytes ({hacs_ratio:.2f}:1)", file=sys.stderr)
    print(f"After CDIS patterns:  {cdis_pattern_size:,} bytes ({pattern_ratio:.2f}:1)", file=sys.stderr)
    print(f"After entropy coding: {compressed_size:,} bytes ({entropy_ratio:.2f}:1)", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)
    print(f"TOTAL COMPRESSION:    {total_ratio:.2f}:1", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)
    
    # Output JSON result
    result = {
        'type': 'cdis_entropy_encoded',
        'version': '2.0',
        'original_size': original_size,
        'hacs_size': hacs_size,
        'cdis_pattern_size': cdis_pattern_size,
        'entropy_size': compressed_size,
        'hacs_ratio': round(hacs_ratio, 2),
        'cdis_pattern_ratio': round(pattern_ratio, 2),
        'entropy_ratio': round(entropy_ratio, 2),
        'total_ratio': round(total_ratio, 2),
        'huffman_stats': {
            'unique_tokens': len(frequencies),
            'avg_code_length': round(avg_code_length, 2),
            'compressed_bits': len(encoded_bits),
            'padding_bits': padding,
            'compressed_bytes': compressed_size
        },
        'huffman_codes': {str(k): v for k, v in huffman_codes.items()},
        'compressed_data': bytes_to_hex(byte_array),
        'patterns': cdis_data.get('pattern_dictionary', {}),
        'hacs_dictionaries': cdis_data.get('hacs_dictionaries', {})
    }
    
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
