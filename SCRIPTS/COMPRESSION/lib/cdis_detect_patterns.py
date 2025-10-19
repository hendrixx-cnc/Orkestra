#!/usr/bin/env python3
"""
CDIS Pattern Detector - Stage 1 of CDIS compression
Analyzes HACS token streams to find recurring patterns
Implements LZ77-style pattern matching on token sequences
"""
import json
import sys
from collections import defaultdict, Counter

def extract_token_sequences(tokens, min_length=2, max_length=10):
    """
    Extract all possible token sequences from the stream
    Returns: {sequence_tuple: [positions]}
    """
    sequences = defaultdict(list)
    
    for length in range(min_length, max_length + 1):
        for i in range(len(tokens) - length + 1):
            # Extract sequence of token IDs/types
            sequence = []
            for j in range(length):
                token = tokens[i + j]
                if token['type'] == 'literal':
                    # For literals, use the actual text
                    sequence.append(('L', token['text']))
                else:
                    # For dictionary tokens, use type and ID
                    sequence.append((token['type'][0].upper(), token['id']))
            
            seq_tuple = tuple(sequence)
            sequences[seq_tuple].append(i)
    
    return sequences

def calculate_savings(sequence, positions, sequence_length):
    """
    Calculate how much space we save by replacing this pattern
    Savings = (original_size - replacement_size) * occurrence_count
    """
    occurrence_count = len(positions)
    
    # Original size: sum of all token representations
    original_size = 0
    for token_type, token_data in sequence:
        if token_type == 'L':
            original_size += len(token_data)  # Literal text length
        else:
            original_size += len(token_data) + 2  # ID + delimiters
    
    original_total = original_size * occurrence_count
    
    # Replacement size: pattern ID (e.g., "C001") + overhead
    replacement_size = 6 * occurrence_count  # Pattern ID per occurrence
    pattern_definition = original_size + 10  # Store pattern once
    
    savings = original_total - (replacement_size + pattern_definition)
    return savings

def select_best_patterns(sequences, min_savings=10, max_patterns=1000):
    """
    Select patterns that provide the best compression
    Priority: high frequency + long length = best savings
    """
    pattern_candidates = []
    
    for sequence, positions in sequences.items():
        if len(positions) < 2:  # Must appear at least twice
            continue
        
        savings = calculate_savings(sequence, positions, len(sequence))
        
        if savings >= min_savings:
            pattern_candidates.append({
                'sequence': sequence,
                'positions': positions,
                'count': len(positions),
                'length': len(sequence),
                'savings': savings
            })
    
    # Sort by savings (descending)
    pattern_candidates.sort(key=lambda x: x['savings'], reverse=True)
    
    # Take top patterns
    return pattern_candidates[:max_patterns]

def build_pattern_dictionary(patterns):
    """
    Create CDIS pattern dictionary
    Returns: {pattern_id: pattern_sequence}
    """
    pattern_dict = {}
    
    for i, pattern in enumerate(patterns, 1):
        pattern_id = f"C{i:04d}"
        pattern_dict[pattern_id] = {
            'sequence': pattern['sequence'],
            'count': pattern['count'],
            'length': pattern['length'],
            'savings': pattern['savings']
        }
    
    return pattern_dict

def substitute_patterns(tokens, pattern_dict):
    """
    Replace pattern occurrences with pattern IDs
    Returns: new token stream with patterns substituted
    """
    # Create a mapping of positions to skip (already replaced)
    skip_positions = set()
    substituted_tokens = []
    pattern_occurrences = defaultdict(int)
    
    i = 0
    while i < len(tokens):
        if i in skip_positions:
            i += 1
            continue
        
        # Try to match patterns at current position (longest first)
        matched = False
        
        for pattern_id, pattern_data in sorted(
            pattern_dict.items(),
            key=lambda x: x[1]['length'],
            reverse=True
        ):
            pattern_seq = pattern_data['sequence']
            pattern_len = len(pattern_seq)
            
            # Check if pattern matches at current position
            if i + pattern_len <= len(tokens):
                match = True
                for j in range(pattern_len):
                    token = tokens[i + j]
                    expected = pattern_seq[j]
                    
                    if expected[0] == 'L':
                        if token['type'] != 'literal' or token['text'] != expected[1]:
                            match = False
                            break
                    else:
                        token_type_char = token['type'][0].upper()
                        if token_type_char != expected[0] or token['id'] != expected[1]:
                            match = False
                            break
                
                if match:
                    # Replace with pattern token
                    substituted_tokens.append({
                        'type': 'pattern',
                        'id': pattern_id,
                        'length': pattern_len,
                        'position': i
                    })
                    pattern_occurrences[pattern_id] += 1
                    
                    # Mark positions as used
                    for j in range(pattern_len):
                        skip_positions.add(i + j)
                    
                    i += pattern_len
                    matched = True
                    break
        
        if not matched:
            # No pattern matched, keep original token
            substituted_tokens.append(tokens[i])
            i += 1
    
    return substituted_tokens, pattern_occurrences

def main():
    if len(sys.argv) < 2:
        print("Usage: cdis_detect_patterns.py <hacs_encoded.json>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Load HACS encoded data
    with open(input_file, 'r') as f:
        hacs_data = json.load(f)
    
    tokens = hacs_data['tokens']
    
    # Extract all possible sequences
    sequences = extract_token_sequences(tokens, min_length=2, max_length=8)
    
    # Select best patterns
    patterns = select_best_patterns(sequences, min_savings=20, max_patterns=500)
    
    # Build pattern dictionary
    pattern_dict = build_pattern_dictionary(patterns)
    
    # Substitute patterns
    substituted_tokens, pattern_occurrences = substitute_patterns(tokens, pattern_dict)
    
    # Calculate compression ratio
    original_size = hacs_data['original_size']
    hacs_encoded_size = hacs_data['encoded_size']
    
    # Estimate CDIS size
    cdis_size = 0
    for token in substituted_tokens:
        if token['type'] == 'literal':
            cdis_size += len(token['text'])
        elif token['type'] == 'pattern':
            cdis_size += 6  # Pattern ID
        else:
            cdis_size += len(token['id']) + 2
    
    # Add pattern dictionary overhead
    for pattern_data in pattern_dict.values():
        cdis_size += len(pattern_data['sequence']) * 8  # Rough estimate
    
    hacs_ratio = original_size / hacs_encoded_size if hacs_encoded_size > 0 else 0
    cdis_ratio = hacs_encoded_size / cdis_size if cdis_size > 0 else 0
    total_ratio = original_size / cdis_size if cdis_size > 0 else 0
    
    # Output result
    result = {
        'type': 'cdis_pattern_detected',
        'version': '1.0',
        'input_file': input_file,
        'original_size': original_size,
        'hacs_size': hacs_encoded_size,
        'cdis_size': cdis_size,
        'hacs_ratio': round(hacs_ratio, 2),
        'cdis_ratio': round(cdis_ratio, 2),
        'total_ratio': round(total_ratio, 2),
        'pattern_count': len(pattern_dict),
        'token_reduction': len(tokens) - len(substituted_tokens),
        'pattern_dictionary': pattern_dict,
        'substituted_tokens': substituted_tokens,
        'pattern_occurrences': dict(pattern_occurrences),
        'hacs_dictionaries': hacs_data['dictionaries']
    }
    
    print(json.dumps(result, indent=2))

if __name__ == "__main__":
    main()
