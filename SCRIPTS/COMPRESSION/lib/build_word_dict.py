#!/usr/bin/env python3
"""
HACS Word Dictionary Builder
Extracts frequent words with mnemonic IDs, preserving case information
"""
import re
import json
import sys
from collections import defaultdict, Counter

def extract_words(text, threshold):
    """Extract words with case tracking"""
    words_data = defaultdict(lambda: {"variants": [], "total_count": 0})
    
    # Extract all words
    word_list = re.findall(r'\b\w+\b', text)
    total_words = len(word_list)
    
    if total_words == 0:
        return {}
    
    # Track each word and its case variants
    for word in word_list:
        word_lower = word.lower()
        words_data[word_lower]["variants"].append(word)
        words_data[word_lower]["total_count"] += 1
    
    # Common words get short IDs
    common_words = [
        "the", "be", "to", "of", "and", "a", "in", "that",
        "have", "i", "it", "for", "not", "on", "with", "he",
        "as", "you", "do", "at", "this", "but", "his", "by",
        "from", "they", "we", "say", "her", "she", "or", "an",
        "will", "my", "one", "all", "would", "there", "their"
    ]
    
    common_word_ids = {
        "the": "_th", "be": "_be", "to": "_to", "of": "_of",
        "and": "_and", "a": "_a", "in": "_in", "that": "_that",
        "have": "_hv", "i": "_i", "it": "_it", "for": "_for",
        "not": "_not", "on": "_on", "with": "_wth", "he": "_he",
        "as": "_as", "you": "_you", "do": "_do", "at": "_at",
        "this": "_ths", "but": "_but", "his": "_his", "by": "_by",
        "from": "_frm", "they": "_thy", "we": "_we", "say": "_say",
        "her": "_her", "she": "_she", "or": "_or", "an": "_an",
        "will": "_wl", "my": "_my", "one": "_one", "all": "_all",
        "would": "_wd", "there": "_thr", "their": "_thr2"
    }
    
    filtered_words = {}
    
    # Add common words first
    for word in common_words:
        if word in words_data:
            data = words_data[word]
            variant_counts = Counter(data["variants"])
            most_common = variant_counts.most_common(1)[0][0]
            
            filtered_words[common_word_ids[word]] = {
                "original": most_common,
                "frequency": data["total_count"] / total_words,
                "count": data["total_count"],
                "case_sensitive": len(set(data["variants"])) > 1
            }
    
    # Add other frequent words
    min_count = int(total_words * threshold)
    word_id = 1
    
    for word_lower, data in words_data.items():
        if word_lower in common_words:
            continue
        
        if data["total_count"] >= max(min_count, 3):
            variant_counts = Counter(data["variants"])
            most_common = variant_counts.most_common(1)[0][0]
            
            # Generate mnemonic ID
            mnemonic = word_lower[:4] if len(word_lower) > 3 else word_lower
            word_id_str = f"W:{mnemonic}{word_id:03d}"
            
            filtered_words[word_id_str] = {
                "original": most_common,
                "frequency": data["total_count"] / total_words,
                "count": data["total_count"],
                "case_sensitive": len(set(data["variants"])) > 1
            }
            word_id += 1
    
    return filtered_words

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: build_word_dict.py <input_file> <threshold>", file=sys.stderr)
        sys.exit(1)
    
    input_file = sys.argv[1]
    threshold = float(sys.argv[2])
    
    with open(input_file, 'r') as f:
        text = f.read()
    
    words = extract_words(text, threshold)
    
    # Output as JSON
    output = {
        "type": "word_dictionary",
        "version": "1.0",
        "threshold": threshold,
        "count": len(words),
        "entries": words
    }
    
    print(json.dumps(output, indent=2))
