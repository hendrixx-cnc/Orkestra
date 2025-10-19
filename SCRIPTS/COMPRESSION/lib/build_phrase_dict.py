#!/usr/bin/env python3
"""
HACS Phrase Dictionary Builder
Extracts recurring phrases (2-6 word sequences) preserving original case
"""
import re
import json
import sys
from collections import defaultdict

def extract_phrases(text, threshold):
    """Extract phrases with case preservation"""
    phrases_data = defaultdict(lambda: {"variants": [], "total_count": 0})
    
    # Tokenize preserving case and positions
    # Split on whitespace and punctuation but keep track of original text
    words = re.findall(r'\b\w+\b', text)
    total_words = len(words)
    
    if total_words == 0:
        return {}
    
    # Extract n-grams (2-6 words)
    for n in range(2, 7):
        for i in range(len(words) - n + 1):
            phrase = ' '.join(words[i:i+n])
            phrase_lower = phrase.lower()
            
            phrases_data[phrase_lower]["variants"].append(phrase)
            phrases_data[phrase_lower]["total_count"] += 1
    
    # Filter by threshold and choose most common variant
    min_count = int(total_words * threshold)
    filtered_phrases = {}
    phrase_id = 1
    
    for phrase_lower, data in phrases_data.items():
        if data["total_count"] >= max(min_count, 2):
            # Choose most common variant (preserving original case)
            from collections import Counter
            variant_counts = Counter(data["variants"])
            most_common_variant = variant_counts.most_common(1)[0][0]
            
            freq = data["total_count"] / total_words
            filtered_phrases[f"P{phrase_id:04d}"] = {
                "original": most_common_variant,
                "frequency": freq,
                "count": data["total_count"],
                "variants": len(set(data["variants"]))
            }
            phrase_id += 1
    
    return filtered_phrases

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: build_phrase_dict.py <input_file> <threshold>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    threshold = float(sys.argv[2])
    
    with open(input_file, 'r') as f:
        text = f.read()
    
    phrases = extract_phrases(text, threshold)
    
    # Output as JSON
    output = {
        "type": "phrase_dictionary",
        "version": "1.0",
        "threshold": threshold,
        "count": len(phrases),
        "entries": phrases
    }
    
    print(json.dumps(output, indent=2))
