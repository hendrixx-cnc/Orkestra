# Preserve Case in HACS → CDIS Pipeline

## Summary
We've implemented HACS V3, a CDIS pattern detector, and a token-level Huffman entropy encoder/decoder. The end-to-end pipeline compresses a 2.9KB sample down to 167 bytes (≈17.7:1) but the round-trip is **lossy with regard to case**: tokens' `original` fields lose capitalization (e.g., "Orkestra" → "orkestra").

## Relevant Files
- `SCRIPTS/COMPRESSION/lib/hacs_encode.py` — HACS encoder (produces tokens with `original` case preserved)
- `SCRIPTS/COMPRESSION/lib/hacs_decode.py` — HACS decoder (expects tokens with `original` fields)
- `SCRIPTS/COMPRESSION/lib/cdis_detect_patterns.py` — Pattern detector (builds `pattern_dictionary` and `substituted_tokens`)
- `SCRIPTS/COMPRESSION/lib/cdis_entropy_encode_v2.py` — Token-level Huffman encoder (generates `huffman_codes`, `compressed_data`, `patterns`, `hacs_dictionaries`)
- `SCRIPTS/COMPRESSION/lib/cdis_entropy_decode.py` — Huffman decoder and token reconstructor
- `SCRIPTS/COMPRESSION/lib/cdis_entropy_encode.py` — earlier entropy encoder (char-level, deprecated)

## Observed Behavior
1. HACS encoder emits tokens with `original` preserving case
2. CDIS detector substitutes tokens with IDs (patterns, phrase IDs, word IDs)
3. Token-level Huffman encoder maps token "keys" to Huffman symbols
4. After Huffman decode, tokens have lowercase variants (canonical dictionary form) instead of their per-occurrence case

## Root Cause Analysis
- The encoder reduces tokens to compact keys (e.g., `('WORD', 'W:orke001')`)
- Huffman encoding stores only the key, not per-occurrence `original` text
- HACS dictionaries store a canonical `original` (usually lowercase)
- The decoder loads this canonical form and uses it for all occurrences
- **Per-occurrence case information is lost during entropy encoding**

## Sample Data Characteristics
Based on our 2.9KB test file (readme.md):
- **Total tokens**: 231 (116 literals + 115 non-literals)
- **Unique dictionary IDs**: 29 (words, phrases, entities)
- **Unique case variants**: 45 (same ID, different capitalization)
- **Current compression**: 167 bytes with 106 Huffman symbols
- **Case variant examples**:
  - `W:orke001` appears as "Orkestra" (5×), "orkestra" (3×)
  - `W:scri006` appears as "SCRIPTS" (5×), "scripts" (4×)
  - `W:star018` appears as "Start" (4×), "start" (2×)
  - `W:auto014` appears as "automation" (5×), "AUTOMATION" (2×)

## Engineering Question
**How should we preserve per-occurrence case through the CDIS tokenization + entropy encoding stages while keeping size-efficient compression?**

---

## Options with Efficiency Analysis

### Option 1: Case Bitmap (Side-Channel)
**Approach**: For each non-literal token, store a compact bitmask encoding character-level case (1=upper, 0=lower). Pack all bitmasks into a binary side-stream.

**Size Estimate**:
- Average token length: ~8 characters
- 115 non-literal tokens × 8 bits/token = 920 bits = 115 bytes
- With run-length encoding or Huffman: ~40-60 bytes
- **Total overhead**: ~40-60 bytes
- **Final size**: 167 + 50 = **~217 bytes** (13.6:1 ratio)

**Pros**:
- Predictable overhead (scales with token count)
- Simple to implement and debug
- Preserves exact case per character
- Works well with high case consistency

**Cons**:
- Fixed overhead even when most tokens are lowercase
- Requires aligning bitmask to token text length
- Doesn't compress well if case is random

**Implementation complexity**: Medium

---

### Option 2: Variant Symbols in Huffman Alphabet ⭐ RECOMMENDED
**Approach**: Treat each case-variant as a separate Huffman symbol (e.g., `('WORD', 'W:orke001', 'Orkestra')` vs `('WORD', 'W:orke001', 'orkestra')`).

**Size Estimate**:
- Current: 106 symbols → New: 106 + 16 variants = **122 symbols**
- Alphabet growth: +15% (only variants that actually occur)
- Huffman tree depth: log₂(122) ≈ 6.93 bits (was 6.73)
- Rare variants add ~1-2 bits to tree
- **Overhead**: ~10-20 bytes for larger tree
- **Final size**: **~177-187 bytes** (15.8-16.3:1 ratio)

**Pros**:
- **MOST EFFICIENT** - minimal overhead (~6-12% size increase)
- No separate side-stream needed
- Huffman automatically optimizes frequent variants
- Simple implementation (modify `token_to_key` function)
- Natural integration with existing pipeline
- Gracefully handles varying case patterns

**Cons**:
- Alphabet size grows with unique case combinations
- Worst case: each token has unique capitalization (unlikely in practice)

**Implementation complexity**: Low (single function change)

---

### Option 3: Delta from Canonical with Match Flags
**Approach**: Store 1-bit flag per non-literal token (0=canonical, 1=variant). For variants, store compact delta or full original.

**Size Estimate**:
- Match flags: 115 tokens × 1 bit = 115 bits = 15 bytes
- Non-matching tokens: ~16 variants × 8 bytes avg = 128 bytes
- With compression: flags ~8 bytes, variants ~60 bytes
- **Total overhead**: ~68 bytes
- **Final size**: 167 + 68 = **~235 bytes** (12.6:1 ratio)

**Pros**:
- Compact when most tokens match canonical
- Clear separation of case metadata
- Easy to extend with other per-token metadata

**Cons**:
- Higher overhead than variant symbols (~40% increase)
- Requires storing full original for mismatches
- Two-stage decode (flags then strings)
- More complex than Option 2

**Implementation complexity**: Medium-High

---

### Option 4: Replacement Table for Case Variants
**Approach**: Build a small lookup table of case variants (e.g., `{0: "Orkestra", 1: "SCRIPTS", ...}`) and reference by 4-bit IDs.

**Size Estimate**:
- Replacement table: 16 variants × 10 bytes avg = 160 bytes (stored once)
- Token references: 115 tokens × 4 bits = 58 bytes
- Table overhead dominates for small files
- **Total overhead**: ~218 bytes
- **Final size**: 167 + 218 = **~385 bytes** (7.7:1 ratio)

**Pros**:
- Good for large files with repeated case patterns
- Compact references (4-8 bits per token)
- Could reuse table across similar files

**Cons**:
- **LEAST EFFICIENT** for small/medium files (~130% overhead)
- High fixed overhead (table storage)
- Complex to implement and maintain
- Not suitable for our use case

**Implementation complexity**: High

---

### Option 5: No Case Preservation (Current - Lossy) ❌
**Current state**: Ignore case variants, use canonical dictionary form.

**Size**: **167 bytes** (17.7:1 ratio)

**Pros**:
- Smallest size
- Simplest implementation
- Already working

**Cons**:
- **LOSSY** - not acceptable for lossless compression
- Breaks round-trip verification
- Loses important formatting information

---

## Efficiency Ranking (for our 2.9KB sample)

| Rank | Option | Size | Ratio | Overhead | Efficiency |
|------|--------|------|-------|----------|------------|
| 🥇 | **Option 2 (Variant symbols)** | **177-187 bytes** | **15.8-16.3:1** | **+6-12%** | ⭐⭐⭐⭐⭐ |
| 🥈 | Option 1 (Case bitmap) | ~217 bytes | 13.6:1 | +30% | ⭐⭐⭐⭐ |
| 🥉 | Option 3 (Delta flags) | ~235 bytes | 12.6:1 | +41% | ⭐⭐⭐ |
| 4 | Option 4 (Replacement table) | ~385 bytes | 7.7:1 | +131% | ⭐⭐ |
| ❌ | Option 5 (No preservation) | 167 bytes | 17.7:1 | 0% | ❌ (lossy) |

**Clear Winner: Option 2 (Variant Symbols)** - adds only 10-20 bytes overhead while maintaining lossless compression.

---

## Recommended Implementation: Option 2 (Variant Symbols)

### Changes Required

**File: `SCRIPTS/COMPRESSION/lib/cdis_entropy_encode_v2.py`**
```python
def token_to_key(token):
    """Convert token dict to hashable key including case variant"""
    if token['type'] == 'literal':
        return ('L', token['text'])
    elif token['type'] == 'pattern':
        return ('PATTERN', token['id'])
    elif token['type'] == 'phrase':
        # Include original case variant in key
        return ('PHRASE', token['id'], token.get('original', ''))
    elif token['type'] == 'word':
        # Include original case variant in key
        return ('WORD', token['id'], token.get('original', ''))
    elif token['type'] == 'entity':
        # Include original case variant in key
        return ('ENTITY', token['id'], token.get('original', ''))
    else:
        raise ValueError(f"Unknown token type: {token['type']}")
```

**File: `SCRIPTS/COMPRESSION/lib/cdis_entropy_decode.py`**
```python
# Update to handle 3-tuple keys with case variant
def reconstruct_token_objects(token_keys, patterns, hacs_data):
    tokens = []
    position = 0
    
    for key in token_keys:
        # Handle both 2-tuple (old) and 3-tuple (new with case)
        if len(key) == 3:
            token_type_code, token_id, original_case = key
        elif len(key) == 2:
            token_type_code, token_id = key
            original_case = None  # Fallback to dictionary
        
        # ... rest of reconstruction using original_case when available
```

### Expected Results
- **Compression ratio**: 15.8-16.3:1 (vs 17.7:1 lossy)
- **Overhead**: 10-20 bytes (~6-12% increase)
- **Lossless**: ✅ Perfect round-trip
- **Implementation time**: ~30 minutes
- **Testing time**: ~10 minutes

---

## Next Steps

1. ✅ Analyze efficiency of all options (COMPLETED)
2. **Implement Option 2** (Variant Symbols in Huffman)
3. Run round-trip test on 2.9KB sample
4. Verify lossless compression with `diff`
5. Measure actual compression stats
6. Update documentation

**Ready to proceed?** Confirm and I'll implement Option 2 immediately.

---

## UPDATE: Iteration 1 Complete ✅

**Implementation**: Option 2 (Variant Symbols) has been successfully implemented.

**Results**:
- **Original size**: 2,958 bytes
- **Compressed size**: 174 bytes
- **Compression ratio**: **15.72:1** (fully lossless, verified)
- **Huffman symbols**: 122 (up from 106)
- **Case preservation overhead**: +7 bytes (~4%)

**Verification**: Perfect round-trip confirmed with `diff` - no data loss.

**Files modified**:
- `SCRIPTS/COMPRESSION/lib/cdis_entropy_encode_v2.py` - Added case variant to token keys
- `SCRIPTS/COMPRESSION/lib/cdis_entropy_decode.py` - Handle 3-tuple keys with original case

**Next Steps**: See handoff document for iterations 2-4 toward 100:1 target:
- **→** `/workspaces/Orkestra/DOCS/QUESTIONS/hacs-cdis-iteration-handoff.md`

This document contains:
- Complete current state analysis
- Identified bottlenecks (literal compression, pattern detection)
- Specific questions for next optimization iterations
- Test commands and file locations
- Success criteria for reaching 100:1

---

*Generated on 2025-10-19 by Orkestra compression system analysis*
*Updated after Iteration 1 completion*
