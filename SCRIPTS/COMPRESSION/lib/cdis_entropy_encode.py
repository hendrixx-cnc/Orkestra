#!/usr/bin/env python3
"""
CDIS Entropy Encoder - Huffman Coding
Compresses pattern-substituted token stream using variable-length codes
Final stage of CDIS compression achieving target compression ratio
"""
import json
import sys
import heapq
from collections import Counter, defaultdict

class HuffmanNode:
    """Node in Huffman tree"""
    def __init__(self, char, freq):
        self.char = char
        self.freq = freq
        self.left = None
        self.right = None
    
    def __lt__(self, other):
        return self.freq < other.freq

def build_frequency_table(tokens):
    """
    Build frequency table from token stream
    Returns: {token_key: frequency}
    """
    frequencies = Counter()
    
    for token in tokens:
        if token['type'] == 'literal':
            # Count individual characters in literals
            for char in token['text']:
                frequencies[('L', char)] += 1
        else:
            # Count token ID
            frequencies[(token['type'][0].upper(), token['id'])] += 1
    
    return frequencies

def build_huffman_tree(frequencies):
    """
    Build Huffman tree from frequency table
    Returns: root node of tree
    """
    # Create priority queue with leaf nodes
    heap = []
    for token_key, freq in frequencies.items():
        node = HuffmanNode(token_key, freq)
        heapq.heappush(heap, node)
    
    # Build tree bottom-up
    while len(heap) > 1:
        left = heapq.heappop(heap)
        right = heapq.heappop(heap)
        
        merged = HuffmanNode(None, left.freq + right.freq)
        merged.left = left
        merged.right = right
        
        heapq.heappush(heap, merged)
    
    return heap[0] if heap else None

def generate_huffman_codes(root):
    """
    Generate Huffman codes from tree
    Returns: {token_key: bit_string}
    """
    if root is None:
        return {}
    
    codes = {}
    
    def traverse(node, code):
        if node.char is not None:  # Leaf node
            codes[node.char] = code if code else '0'
        else:
            if node.left:
                traverse(node.left, code + '0')
            if node.right:
                traverse(node.right, code + '1')
    
    traverse(root, '')
    return codes

def encode_with_huffman(tokens, huffman_codes):
    """
    Encode token stream using Huffman codes
    Returns: bit string
    """
    bits = []
    
    for token in tokens:
        if token['type'] == 'literal':
            # Encode each character
            for char in token['text']:
                key = ('L', char)
                if key in huffman_codes:
                    bits.append(huffman_codes[key])
                else:
                    # Unknown character - use escape code
                    bits.append('11111111')  # 8 bits of 1s
                    # Append 8-bit ASCII
                    bits.append(format(ord(char), '08b'))
        else:
            # Encode token ID
            key = (token['type'][0].upper(), token['id'])
            if key in huffman_codes:
                bits.append(huffman_codes[key])
            else:
                # Unknown token - shouldn't happen
                bits.append('11111111')
    
    return ''.join(bits)

def bits_to_bytes(bit_string):
    """
    Convert bit string to byte array
    Pads to 8-bit boundary
    """
    # Pad to multiple of 8
    padding = (8 - len(bit_string) % 8) % 8
    bit_string += '0' * padding
    
    # Convert to bytes
    byte_array = bytearray()
    for i in range(0, len(bit_string), 8):
        byte = int(bit_string[i:i+8], 2)
        byte_array.append(byte)
    
    return bytes(byte_array), padding

def calculate_compression_stats(original_size, frequencies, huffman_codes):
    """
    Calculate theoretical compression statistics
    """
    # Calculate average code length
    total_freq = sum(frequencies.values())
    avg_code_length = sum(
        frequencies[key] * len(huffman_codes[key])
        for key in huffman_codes
    ) / total_freq
    
    # Theoretical compressed size (bits)
    compressed_bits = sum(
        frequencies[key] * len(huffman_codes[key])
        for key in huffman_codes
    )
    compressed_bytes = (compressed_bits + 7) // 8  # Round up
    
    # Compression ratio
    ratio = original_size / compressed_bytes if compressed_bytes > 0 else 0
    
    return {
        'avg_code_length': avg_code_length,
        'compressed_bits': compressed_bits,
        'compressed_bytes': compressed_bytes,
        'compression_ratio': ratio
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: cdis_entropy_encode.py <cdis_patterns.json>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Load CDIS pattern-detected data
    with open(input_file, 'r') as f:
        cdis_data = json.load(f)
    
    tokens = cdis_data['substituted_tokens']
    original_size = cdis_data['original_size']
    
    print(f"Building Huffman codes for {len(tokens)} tokens...", file=sys.stderr)
    
    # Step 1: Build frequency table
    frequencies = build_frequency_table(tokens)
    print(f"Frequency table: {len(frequencies)} unique symbols", file=sys.stderr)
    
    # Step 2: Build Huffman tree
    huffman_tree = build_huffman_tree(frequencies)
    
    # Step 3: Generate codes
    huffman_codes = generate_huffman_codes(huffman_tree)
    print(f"Huffman codes generated: {len(huffman_codes)} codes", file=sys.stderr)
    
    # Show some example codes
    print("\nSample Huffman codes:", file=sys.stderr)
    sorted_codes = sorted(huffman_codes.items(), key=lambda x: frequencies[x[0]], reverse=True)
    for token_key, code in sorted_codes[:10]:
        freq = frequencies[token_key]
        print(f"  {token_key}: '{code}' (freq={freq})", file=sys.stderr)
    
    # Step 4: Encode token stream
    bit_string = encode_with_huffman(tokens, huffman_codes)
    print(f"\nEncoded to {len(bit_string)} bits", file=sys.stderr)
    
    # Step 5: Convert to bytes
    compressed_bytes, padding = bits_to_bytes(bit_string)
    print(f"Compressed to {len(compressed_bytes)} bytes (padding={padding})", file=sys.stderr)
    
    # Step 6: Calculate statistics
    stats = calculate_compression_stats(original_size, frequencies, huffman_codes)
    
    # Calculate all ratios
    hacs_size = cdis_data['hacs_size']
    cdis_pattern_size = cdis_data['cdis_size']
    entropy_size = len(compressed_bytes)
    
    hacs_ratio = original_size / hacs_size if hacs_size > 0 else 0
    cdis_pattern_ratio = hacs_size / cdis_pattern_size if cdis_pattern_size > 0 else 0
    entropy_ratio = cdis_pattern_size / entropy_size if entropy_size > 0 else 0
    total_ratio = original_size / entropy_size if entropy_size > 0 else 0
    
    print(f"\n{'='*60}", file=sys.stderr)
    print(f"Compression Pipeline Results:", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)
    print(f"Original size:        {original_size:,} bytes", file=sys.stderr)
    print(f"After HACS:           {hacs_size:,} bytes ({hacs_ratio:.2f}:1)", file=sys.stderr)
    print(f"After CDIS patterns:  {cdis_pattern_size:,} bytes ({cdis_pattern_ratio:.2f}:1)", file=sys.stderr)
    print(f"After entropy coding: {entropy_size:,} bytes ({entropy_ratio:.2f}:1)", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)
    print(f"TOTAL COMPRESSION:    {total_ratio:.2f}:1", file=sys.stderr)
    print(f"{'='*60}\n", file=sys.stderr)
    
    # Output result
    result = {
        'type': 'cdis_entropy_encoded',
        'version': '1.0',
        'original_size': original_size,
        'hacs_size': hacs_size,
        'cdis_pattern_size': cdis_pattern_size,
        'entropy_size': entropy_size,
        'hacs_ratio': round(hacs_ratio, 2),
        'cdis_pattern_ratio': round(cdis_pattern_ratio, 2),
        'entropy_ratio': round(entropy_ratio, 2),
        'total_ratio': round(total_ratio, 2),
        'huffman_stats': {
            'unique_symbols': len(frequencies),
            'avg_code_length': round(stats['avg_code_length'], 2),
            'compressed_bits': stats['compressed_bits'],
            'padding_bits': padding
        },
        'huffman_codes': {str(k): v for k, v in huffman_codes.items()},
        'frequency_table': {str(k): v for k, v in frequencies.items()},
        'compressed_data': compressed_bytes.hex(),
        'cdis_data': cdis_data
    }
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
