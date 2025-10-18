#!/bin/bash

# CDIS Master Formula Backup Sync Script
# Syncs primary copy to all 3 backup locations

set -e

PRIMARY="/workspaces/The-Quantum-Self-/AI/CDIS_MASTER_FORMULA.md"
BACKUP1="/workspaces/The-Quantum-Self-/Safe/CDIS_MASTER_FORMULA_BACKUP_1.md"
BACKUP2="/workspaces/The-Quantum-Self-/0_Archive/CDIS_MASTER_FORMULA_BACKUP_2.md"
BACKUP3="/workspaces/The-Quantum-Self-/CDIS_MASTER_FORMULA_BACKUP_3.md"

# Legal protection file
LEGAL_PRIMARY="/workspaces/The-Quantum-Self-/AI/CDIS_LEGAL_PROTECTION.md"
LEGAL_BACKUP1="/workspaces/The-Quantum-Self-/Safe/CDIS_LEGAL_PROTECTION_BACKUP_1.md"
LEGAL_BACKUP2="/workspaces/The-Quantum-Self-/0_Archive/CDIS_LEGAL_PROTECTION_BACKUP_2.md"
LEGAL_BACKUP3="/workspaces/The-Quantum-Self-/CDIS_LEGAL_PROTECTION_BACKUP_3.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 CDIS MASTER FORMULA BACKUP SYNC"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check primary exists
if [[ ! -f "$PRIMARY" ]]; then
    echo "❌ ERROR: Primary file not found!"
    echo "   Location: $PRIMARY"
    echo ""
    echo "🚨 ATTEMPTING RESTORATION FROM BACKUP..."
    
    if [[ -f "$BACKUP1" ]]; then
        cp "$BACKUP1" "$PRIMARY"
        echo "✅ Restored from Backup 1"
    elif [[ -f "$BACKUP2" ]]; then
        cp "$BACKUP2" "$PRIMARY"
        echo "✅ Restored from Backup 2"
    elif [[ -f "$BACKUP3" ]]; then
        cp "$BACKUP3" "$PRIMARY"
        echo "✅ Restored from Backup 3"
    else
        echo "❌ CRITICAL: All copies lost! Manual intervention required."
        exit 1
    fi
fi

# Verify primary contains required phrases
echo "🔍 Verifying primary file integrity..."

if ! grep -q "0.4 × Uniqueness" "$PRIMARY"; then
    echo "❌ ERROR: Primary file corrupted (missing weight formula)"
    exit 1
fi

if ! grep -q "Democratic_Score" "$PRIMARY"; then
    echo "❌ ERROR: Primary file corrupted (missing democratic validation)"
    exit 1
fi

echo "✅ Primary file verified"
echo ""

# Sync to backups
echo "📋 Syncing to backups..."

cp "$PRIMARY" "$BACKUP1"
echo "  ✅ Backup 1 synced"

cp "$PRIMARY" "$BACKUP2"
echo "  ✅ Backup 2 synced"

cp "$PRIMARY" "$BACKUP3"
echo "  ✅ Backup 3 synced"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SYNC COMPLETE: All formula backups updated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$BACKUP1" "$BACKUP2" "$BACKUP3"
echo ""

# Sync legal protection file
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🛡️ SYNCING LEGAL PROTECTION FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$LEGAL_PRIMARY" ]; then
    echo "❌ ERROR: Legal protection file not found!"
    exit 1
fi

# Verify legal file integrity
if ! grep -q "LAYER 1: PATENT PROTECTION" "$LEGAL_PRIMARY"; then
    echo "❌ ERROR: Legal file corrupted (patent section missing)"
    exit 1
fi

if ! grep -q "LAYER 7: FINANCIAL PROTECTION" "$LEGAL_PRIMARY"; then
    echo "❌ ERROR: Legal file corrupted (financial section missing)"
    exit 1
fi

echo "✅ Legal protection file verified"

# Copy to all backup locations
cp "$LEGAL_PRIMARY" "$LEGAL_BACKUP1"
cp "$LEGAL_PRIMARY" "$LEGAL_BACKUP2"
cp "$LEGAL_PRIMARY" "$LEGAL_BACKUP3"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ SYNC COMPLETE: All legal protection backups updated"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ls -lh "$LEGAL_BACKUP1" "$LEGAL_BACKUP2" "$LEGAL_BACKUP3"
echo ""
echo "📊 Status:"
echo "  Primary:  $(ls -lh $PRIMARY | awk '{print $5}')"
echo "  Backup 1: $(ls -lh $BACKUP_1 | awk '{print $5}')"
echo "  Backup 2: $(ls -lh $BACKUP_2 | awk '{print $5}')"
echo "  Backup 3: $(ls -lh $BACKUP_3 | awk '{print $5}')"
echo ""
echo "Timestamp: $(date)"
echo ""
