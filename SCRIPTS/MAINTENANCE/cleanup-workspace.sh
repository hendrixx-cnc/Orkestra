#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# WORKSPACE CLEANUP UTILITY
# ═══════════════════════════════════════════════════════════════════════════
# Cleans up temporary files, organizes archives, removes clutter
# Usage: ./cleanup-workspace.sh [dry-run|clean|deep-clean]
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Directories
ORKESTRA_ROOT="/workspaces/Orkestra"
ARCHIVE_DIR="$ORKESTRA_ROOT/ARCHIVE"
LOGS_DIR="$ORKESTRA_ROOT/LOGS"
TEMP_PATTERNS=("*.tmp" "*.temp" "*~" "*.bak" "*.swp" ".DS_Store")

# Counters
archived_count=0
deleted_count=0
cleaned_bytes=0

# ═══════════════════════════════════════════════════════════════════════════
# FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════

log_action() {
    local action="$1"
    local file="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$timestamp | $action | $file" >> "$LOGS_DIR/cleanup-history.log"
}

archive_file() {
    local file="$1"
    local reason="$2"
    local dry_run="${3:-false}"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    # Get relative path
    local rel_path="${file#$ORKESTRA_ROOT/}"
    local archive_path="$ARCHIVE_DIR/$rel_path"
    local archive_parent=$(dirname "$archive_path")
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would archive: ${DIM}$rel_path${NC} ($reason)"
        return
    fi
    
    mkdir -p "$archive_parent"
    mv "$file" "$archive_path"
    
    echo -e "${CYAN}📦${NC} Archived: ${DIM}$rel_path${NC} → ${DIM}ARCHIVE/$rel_path${NC}"
    log_action "ARCHIVED" "$rel_path"
    ((archived_count++))
}

delete_file() {
    local file="$1"
    local reason="$2"
    local dry_run="${3:-false}"
    
    if [[ ! -f "$file" ]]; then
        return
    fi
    
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
    local rel_path="${file#$ORKESTRA_ROOT/}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} Would delete: ${DIM}$rel_path${NC} ($reason)"
        return
    fi
    
    rm "$file"
    
    echo -e "${RED}🗑️${NC}  Deleted: ${DIM}$rel_path${NC} ($(numfmt --to=iec $size 2>/dev/null || echo "$size bytes"))"
    log_action "DELETED" "$rel_path"
    ((deleted_count++))
    ((cleaned_bytes+=size))
}

# ═══════════════════════════════════════════════════════════════════════════
# CLEANUP OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════

cleanup_temp_files() {
    local dry_run="${1:-false}"
    
    echo -e "${BOLD}${CYAN}Cleaning Temporary Files...${NC}"
    echo ""
    
    # Find and remove common temp patterns
    for pattern in "${TEMP_PATTERNS[@]}"; do
        while IFS= read -r -d '' file; do
            delete_file "$file" "temp file" "$dry_run"
        done < <(find "$ORKESTRA_ROOT" -type f -name "$pattern" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/ARCHIVE/*" -print0 2>/dev/null)
    done
    
    # Clean old log files (keep last 30 days)
    if [[ -d "$LOGS_DIR" ]]; then
        while IFS= read -r -d '' file; do
            archive_file "$file" "old log" "$dry_run"
        done < <(find "$LOGS_DIR" -type f -name "*.log" -mtime +30 -print0 2>/dev/null)
    fi
}

cleanup_empty_files() {
    local dry_run="${1:-false}"
    
    echo -e "${BOLD}${CYAN}Removing Empty Files...${NC}"
    echo ""
    
    while IFS= read -r -d '' file; do
        # Skip node_modules and .git
        if [[ "$file" == *"/node_modules/"* ]] || [[ "$file" == *"/.git/"* ]]; then
            continue
        fi
        
        delete_file "$file" "empty file" "$dry_run"
    done < <(find "$ORKESTRA_ROOT" -type f -size 0 -not -path "*/ARCHIVE/*" -print0 2>/dev/null)
}

cleanup_duplicate_docs() {
    local dry_run="${1:-false}"
    
    echo -e "${BOLD}${CYAN}Checking for Duplicate Documentation...${NC}"
    echo ""
    
    # Look for obvious duplicates (files with _OLD, _BACKUP, _COPY in name)
    while IFS= read -r -d '' file; do
        local basename=$(basename "$file")
        if [[ "$basename" =~ _(OLD|BACKUP|COPY|BAK|DEPRECATED|ARCHIVE)[_.] ]]; then
            archive_file "$file" "duplicate/old version" "$dry_run"
        fi
    done < <(find "$ORKESTRA_ROOT/DOCS" -type f \( -name "*.md" -o -name "*.txt" \) -not -path "*/ARCHIVE/*" -print0 2>/dev/null)
}

cleanup_broken_scripts() {
    local dry_run="${1:-false}"
    
    echo -e "${BOLD}${CYAN}Checking for Broken Scripts...${NC}"
    echo ""
    
    while IFS= read -r -d '' file; do
        # Check if script has shebang
        if ! head -1 "$file" | grep -q '^#!'; then
            archive_file "$file" "missing shebang" "$dry_run"
            continue
        fi
        
        # Check for basic syntax
        if ! bash -n "$file" 2>/dev/null; then
            archive_file "$file" "syntax error" "$dry_run"
        fi
    done < <(find "$ORKESTRA_ROOT/SCRIPTS" -type f -name "*.sh" -not -path "*/ARCHIVE/*" -print0 2>/dev/null)
}

deep_clean() {
    local dry_run="${1:-false}"
    
    echo -e "${BOLD}${CYAN}Deep Cleaning...${NC}"
    echo ""
    
    # Clean node_modules cache
    if [[ -d "$ORKESTRA_ROOT/EXTENSIONS/AI-AUTOMATION/node_modules/.cache" ]]; then
        local cache_size=$(du -sh "$ORKESTRA_ROOT/EXTENSIONS/AI-AUTOMATION/node_modules/.cache" 2>/dev/null | cut -f1)
        if [[ "$dry_run" == "true" ]]; then
            echo -e "${YELLOW}[DRY-RUN]${NC} Would clean node_modules cache ($cache_size)"
        else
            rm -rf "$ORKESTRA_ROOT/EXTENSIONS/AI-AUTOMATION/node_modules/.cache"
            echo -e "${GREEN}✓${NC} Cleaned node_modules cache ($cache_size)"
        fi
    fi
    
    # Clean git garbage
    if [[ "$dry_run" == "false" ]]; then
        echo -e "${CYAN}Running git garbage collection...${NC}"
        (cd "$ORKESTRA_ROOT" && git gc --auto --quiet 2>/dev/null || true)
        echo -e "${GREEN}✓${NC} Git cleanup complete"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

show_usage() {
    cat << EOF
${BOLD}Workspace Cleanup Utility${NC}

${BOLD}USAGE:${NC}
    $0 [mode]

${BOLD}MODES:${NC}
    ${GREEN}dry-run${NC}     Show what would be cleaned (default)
    ${GREEN}clean${NC}        Clean temp files and empty files
    ${GREEN}deep-clean${NC}  Clean everything including caches

${BOLD}WHAT GETS CLEANED:${NC}
    • Temporary files (*.tmp, *.bak, *~, etc.)
    • Empty files
    • Old log files (>30 days → archived)
    • Duplicate documentation (archived)
    • Broken scripts (archived)
    • Deep clean: node_modules cache, git gc

${BOLD}EXAMPLES:${NC}
    $0              # Preview what would be cleaned
    $0 clean        # Perform cleanup
    $0 deep-clean   # Full deep clean

EOF
}

main() {
    local mode="${1:-dry-run}"
    local dry_run="true"
    
    case "$mode" in
        clean)
            dry_run="false"
            ;;
        deep-clean)
            dry_run="false"
            ;;
        dry-run)
            dry_run="true"
            ;;
        help|--help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}✗${NC} Unknown mode: $mode"
            show_usage
            exit 1
            ;;
    esac
    
    echo -e "${BOLD}${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║              ORKESTRA WORKSPACE CLEANUP                           ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}⚠  DRY RUN MODE - No files will be modified${NC}"
    else
        echo -e "${GREEN}✓ LIVE MODE - Files will be cleaned${NC}"
    fi
    echo ""
    
    # Create necessary directories
    mkdir -p "$ARCHIVE_DIR" "$LOGS_DIR"
    
    # Run cleanup operations
    cleanup_temp_files "$dry_run"
    cleanup_empty_files "$dry_run"
    cleanup_duplicate_docs "$dry_run"
    cleanup_broken_scripts "$dry_run"
    
    if [[ "$mode" == "deep-clean" ]]; then
        deep_clean "$dry_run"
    fi
    
    # Show summary
    echo ""
    echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}CLEANUP SUMMARY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
    
    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}This was a dry run. Re-run with 'clean' or 'deep-clean' to execute.${NC}"
    else
        echo -e "${GREEN}✓ Files archived:${NC} $archived_count"
        echo -e "${GREEN}✓ Files deleted:${NC} $deleted_count"
        if [[ $cleaned_bytes -gt 0 ]]; then
            echo -e "${GREEN}✓ Space freed:${NC} $(numfmt --to=iec $cleaned_bytes 2>/dev/null || echo "$cleaned_bytes bytes")"
        fi
        echo ""
        echo -e "${CYAN}Archive location:${NC} ${DIM}$ARCHIVE_DIR${NC}"
        echo -e "${CYAN}Cleanup log:${NC} ${DIM}$LOGS_DIR/cleanup-history.log${NC}"
    fi
    
    echo ""
}

main "$@"
