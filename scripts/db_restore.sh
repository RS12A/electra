#!/bin/bash
set -euo pipefail

# Electra Database Restore Script
# Production-grade PostgreSQL restore with safety checks and rollback

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/electra}"
ENVIRONMENT="${ENVIRONMENT:-staging}"

# Safety settings
REQUIRE_CONFIRMATION=true
CREATE_SAFETY_BACKUP=true
SAFETY_BACKUP_DIR="/tmp/electra_safety_backups"

# Logging functions
log() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] $*" >&2
}

log_error() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ERROR: $*" >&2
}

log_info() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] INFO: $*" >&2
}

log_success() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] SUCCESS: $*" >&2
}

log_warning() {
    echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] WARNING: $*" >&2
}

# Error handling
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Restore failed with exit code $exit_code"
        
        # Clean up temporary files
        rm -f "$TEMP_RESTORE_FILE" 2>/dev/null || true
        
        # Offer automatic rollback if safety backup exists
        if [[ -f "$SAFETY_BACKUP_FILE" ]] && [[ "$CREATE_SAFETY_BACKUP" == true ]]; then
            log_warning "Safety backup available at: $SAFETY_BACKUP_FILE"
            if [[ "$REQUIRE_CONFIRMATION" == false ]] || confirm_action "Automatically rollback to safety backup?"; then
                log_info "Performing automatic rollback..."
                restore_from_file "$SAFETY_BACKUP_FILE" "safety-rollback"
            fi
        fi
    fi
    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [BACKUP_FILE|ENVIRONMENT] [VERSION_TAG]

Restore database from encrypted backup with safety checks

ARGUMENTS:
    BACKUP_FILE             Path to backup file to restore [required if not using --latest]
    ENVIRONMENT             Environment (staging|production) [default: staging]
    VERSION_TAG             Version tag to restore [optional, used with --latest]

OPTIONS:
    --database-url URL      Target database connection URL [default: from env]
    --backup-dir DIR        Backup directory [default: /var/backups/electra]
    --encryption-key KEY    Encryption key for backup [default: from env]
    --latest                Use latest backup for environment
    --list-backups          List available backups and exit
    --dry-run              Show what would be restored without doing it
    --no-confirmation       Skip confirmation prompts (DANGEROUS)
    --no-safety-backup     Skip creating safety backup before restore
    --target-database DB    Target database name (creates new DB)
    --clean-restore        Drop and recreate database before restore
    --verify-only          Only verify backup integrity, don't restore
    --rollback-file FILE    Rollback to specific safety backup file
    --download-s3           Download backup from S3 bucket
    --s3-bucket BUCKET      S3 bucket for backup download
    -h, --help             Show this help message

RESTORE MODES:
    1. File restore:    $0 /path/to/backup.sql.gz.enc
    2. Latest restore:  $0 --latest production
    3. Version restore: $0 --latest staging v1.0.0
    4. Rollback:        $0 --rollback-file /tmp/safety_backup.sql

SAFETY FEATURES:
    - Automatic safety backup before restore
    - Confirmation prompts for dangerous operations
    - Backup integrity verification
    - Rollback capability
    - Connection testing before restore

EXAMPLES:
    $0 /var/backups/electra/electra_prod_20231015_120000_v1.0.0.sql.gz.enc
    $0 --latest production --no-confirmation
    $0 --list-backups --environment staging
    $0 --verify-only backup.sql.gz.enc
    $0 --rollback-file /tmp/electra_safety_backup_20231015.sql

ENVIRONMENT VARIABLES:
    DATABASE_URL            PostgreSQL connection string
    BACKUP_ENCRYPTION_KEY   Key for backup decryption  
    AWS_ACCESS_KEY_ID       AWS access key (for S3 download)
    AWS_SECRET_ACCESS_KEY   AWS secret key (for S3 download)
    BACKUP_DIR              Directory containing backups

EOF
}

# Parse command line arguments
DATABASE_URL="${DATABASE_URL:-}"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"
BACKUP_FILE=""
VERSION_TAG=""
USE_LATEST=false
LIST_BACKUPS=false
DRY_RUN=false
TARGET_DATABASE=""
CLEAN_RESTORE=false
VERIFY_ONLY=false
ROLLBACK_FILE=""
DOWNLOAD_S3=false
S3_BUCKET="${S3_BUCKET:-}"

# Parse positional arguments first
if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
    if [[ -f "$1" ]]; then
        BACKUP_FILE="$1"
    else
        ENVIRONMENT="$1"
    fi
    shift
fi

if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
    VERSION_TAG="$1"
    shift
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        --database-url)
            DATABASE_URL="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --encryption-key)
            ENCRYPTION_KEY="$2"
            shift 2
            ;;
        --latest)
            USE_LATEST=true
            shift
            ;;
        --list-backups)
            LIST_BACKUPS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-confirmation)
            REQUIRE_CONFIRMATION=false
            shift
            ;;
        --no-safety-backup)
            CREATE_SAFETY_BACKUP=false
            shift
            ;;
        --target-database)
            TARGET_DATABASE="$2"
            shift 2
            ;;
        --clean-restore)
            CLEAN_RESTORE=true
            shift
            ;;
        --verify-only)
            VERIFY_ONLY=true
            shift
            ;;
        --rollback-file)
            ROLLBACK_FILE="$2"
            shift 2
            ;;
        --download-s3)
            DOWNLOAD_S3=true
            shift
            ;;
        --s3-bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Generate temporary file names
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
TEMP_RESTORE_FILE="/tmp/electra_restore_$TIMESTAMP.sql"
SAFETY_BACKUP_FILE="$SAFETY_BACKUP_DIR/electra_safety_backup_$TIMESTAMP.sql"

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check PostgreSQL client tools
    if ! command -v psql &> /dev/null; then
        log_error "psql is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v pg_restore &> /dev/null; then
        log_error "pg_restore is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v pg_dump &> /dev/null; then
        log_error "pg_dump is not installed or not in PATH (needed for safety backup)"
        exit 1
    fi
    
    # Check database URL
    if [[ -z "$DATABASE_URL" ]]; then
        log_error "DATABASE_URL is not set"
        exit 1
    fi
    
    # Check encryption key
    if [[ -z "$ENCRYPTION_KEY" ]]; then
        log_error "BACKUP_ENCRYPTION_KEY is required for decryption"
        exit 1
    fi
    
    # Check decompression tools
    if ! command -v gzip &> /dev/null; then
        log_error "gzip is not installed or not in PATH"
        exit 1
    fi
    
    # Check decryption tools
    if ! command -v openssl &> /dev/null; then
        log_error "openssl is not installed or not in PATH"
        exit 1
    fi
    
    # Check AWS CLI if S3 download is enabled
    if [[ "$DOWNLOAD_S3" == true ]] && ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Create safety backup directory
    if [[ "$CREATE_SAFETY_BACKUP" == true ]]; then
        mkdir -p "$SAFETY_BACKUP_DIR"
    fi
    
    log_success "Prerequisites check passed"
}

# Test database connection
test_database_connection() {
    log_info "Testing database connection..."
    
    if psql "$DATABASE_URL" -c "SELECT 1;" &> /dev/null; then
        log_success "Database connection successful"
    else
        log_error "Cannot connect to database"
        exit 1
    fi
}

# Confirmation prompt
confirm_action() {
    local message="$1"
    local default="${2:-no}"
    
    if [[ "$REQUIRE_CONFIRMATION" == false ]]; then
        return 0
    fi
    
    local prompt="$message [y/N]: "
    if [[ "$default" == "yes" ]]; then
        prompt="$message [Y/n]: "
    fi
    
    while true; do
        read -r -p "$prompt" response
        case "$response" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                if [[ "$default" == "yes" && "$response" == "" ]]; then
                    return 0
                fi
                return 1
                ;;
            *)
                echo "Please answer yes or no."
                ;;
        esac
    done
}

# List available backups
list_backups() {
    log_info "Available backups for environment: $ENVIRONMENT"
    log_info "Backup directory: $BACKUP_DIR"
    echo "========================================================"
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_warning "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
    
    # Find backup files
    local backup_files=()
    while IFS= read -r -d '' file; do
        backup_files+=("$file")
    done < <(find "$BACKUP_DIR" -name "electra_${ENVIRONMENT}_*.sql*" -type f -print0 2>/dev/null | sort -z)
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        log_info "No backups found for environment: $ENVIRONMENT"
        return 0
    fi
    
    # Display backup files with details
    printf "%-40s %-15s %-20s\n" "Backup File" "Size" "Modified"
    printf "%-40s %-15s %-20s\n" "----------------------------------------" "---------------" "--------------------"
    
    for file in "${backup_files[@]}"; do
        local filename
        filename=$(basename "$file")
        local size
        size=$(du -h "$file" | cut -f1)
        local modified
        modified=$(stat -c "%y" "$file" | cut -d. -f1)
        
        printf "%-40s %-15s %-20s\n" "$filename" "$size" "$modified"
    done
    
    echo ""
    log_info "Use the full path or --latest flag to restore a backup"
}

# Find latest backup
find_latest_backup() {
    log_info "Finding latest backup for environment: $ENVIRONMENT"
    
    local pattern="electra_${ENVIRONMENT}_"
    if [[ -n "$VERSION_TAG" ]]; then
        pattern="${pattern}*_${VERSION_TAG}.sql*"
    else
        pattern="${pattern}*.sql*"
    fi
    
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -name "$pattern" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -z "$latest_backup" ]]; then
        log_error "No backup found matching pattern: $pattern"
        exit 1
    fi
    
    log_info "Latest backup found: $(basename "$latest_backup")"
    echo "$latest_backup"
}

# Download backup from S3
download_from_s3() {
    local backup_filename="$1"
    local local_path="$2"
    
    if [[ -z "$S3_BUCKET" ]]; then
        log_error "S3_BUCKET is required for S3 download"
        exit 1
    fi
    
    log_info "Downloading backup from S3..."
    
    local s3_key="backups/$backup_filename"
    
    if aws s3 cp "s3://$S3_BUCKET/$s3_key" "$local_path"; then
        log_success "Backup downloaded from S3: s3://$S3_BUCKET/$s3_key"
    else
        log_error "S3 download failed"
        exit 1
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_file="$1"
    
    log_info "Verifying backup integrity..."
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Decrypt and decompress to verify
    local verify_file="/tmp/verify_$TIMESTAMP.sql"
    
    # Check if file is encrypted
    if [[ "$backup_file" == *.enc ]]; then
        log_info "Decrypting backup for verification..."
        if ! echo "$ENCRYPTION_KEY" | openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$backup_file" -pass stdin | \
            gzip -dc > "$verify_file" 2>/dev/null; then
            log_error "Failed to decrypt/decompress backup file"
            rm -f "$verify_file"
            return 1
        fi
    elif [[ "$backup_file" == *.gz ]]; then
        log_info "Decompressing backup for verification..."
        if ! gzip -dc "$backup_file" > "$verify_file" 2>/dev/null; then
            log_error "Failed to decompress backup file"
            rm -f "$verify_file"
            return 1
        fi
    else
        # Assume uncompressed SQL file
        cp "$backup_file" "$verify_file"
    fi
    
    # Verify the backup file structure
    if pg_restore --list "$verify_file" &> /dev/null; then
        log_success "✓ Backup verification passed"
        rm -f "$verify_file"
        return 0
    else
        log_error "✗ Backup verification failed"
        rm -f "$verify_file"
        return 1
    fi
}

# Create safety backup
create_safety_backup() {
    if [[ "$CREATE_SAFETY_BACKUP" == false ]]; then
        return 0
    fi
    
    log_info "Creating safety backup before restore..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would create safety backup at $SAFETY_BACKUP_FILE"
        return 0
    fi
    
    # Create safety backup using pg_dump
    if pg_dump "$DATABASE_URL" --verbose --no-password --format=custom --compress=6 > "$SAFETY_BACKUP_FILE"; then
        log_success "Safety backup created: $SAFETY_BACKUP_FILE"
        local safety_size
        safety_size=$(du -h "$SAFETY_BACKUP_FILE" | cut -f1)
        log_info "Safety backup size: $safety_size"
    else
        log_error "Failed to create safety backup"
        return 1
    fi
}

# Prepare restore file
prepare_restore_file() {
    local backup_file="$1"
    
    log_info "Preparing restore file..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would prepare restore file from $backup_file"
        return 0
    fi
    
    # Download from S3 if needed
    if [[ "$DOWNLOAD_S3" == true ]]; then
        local s3_backup_file="/tmp/s3_$(basename "$backup_file")"
        download_from_s3 "$(basename "$backup_file")" "$s3_backup_file"
        backup_file="$s3_backup_file"
    fi
    
    # Decrypt and decompress
    if [[ "$backup_file" == *.enc ]]; then
        log_info "Decrypting and decompressing backup..."
        if ! echo "$ENCRYPTION_KEY" | openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$backup_file" -pass stdin | \
            gzip -dc > "$TEMP_RESTORE_FILE"; then
            log_error "Failed to decrypt/decompress backup file"
            return 1
        fi
    elif [[ "$backup_file" == *.gz ]]; then
        log_info "Decompressing backup..."
        if ! gzip -dc "$backup_file" > "$TEMP_RESTORE_FILE"; then
            log_error "Failed to decompress backup file"
            return 1
        fi
    else
        # Assume uncompressed SQL file
        cp "$backup_file" "$TEMP_RESTORE_FILE"
    fi
    
    log_success "Restore file prepared: $TEMP_RESTORE_FILE"
}

# Perform database restore
restore_database() {
    log_info "Performing database restore..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would restore database from $TEMP_RESTORE_FILE"
        log_info "DRY RUN: Clean restore: $CLEAN_RESTORE"
        log_info "DRY RUN: Target database: ${TARGET_DATABASE:-current}"
        return 0
    fi
    
    # Prepare target database URL
    local target_url="$DATABASE_URL"
    if [[ -n "$TARGET_DATABASE" ]]; then
        # Create new database if specified
        local base_url="${DATABASE_URL%/*}"
        target_url="$base_url/$TARGET_DATABASE"
        
        log_info "Creating target database: $TARGET_DATABASE"
        psql "$DATABASE_URL" -c "CREATE DATABASE \"$TARGET_DATABASE\";" || {
            log_warning "Database might already exist or creation failed"
        }
    fi
    
    # Clean restore if requested
    if [[ "$CLEAN_RESTORE" == true ]]; then
        if confirm_action "This will DROP and recreate the database. Are you sure?"; then
            log_warning "Performing clean restore (dropping existing data)..."
            
            # Drop and recreate database
            local db_name
            db_name=$(echo "$target_url" | sed 's/.*\///')
            local base_url="${target_url%/*}"
            
            psql "$base_url/postgres" -c "DROP DATABASE IF EXISTS \"$db_name\";"
            psql "$base_url/postgres" -c "CREATE DATABASE \"$db_name\";"
        else
            log_info "Clean restore cancelled by user"
            return 1
        fi
    fi
    
    # Perform the restore
    log_info "Restoring database..."
    if pg_restore --verbose --no-password --clean --if-exists --dbname="$target_url" "$TEMP_RESTORE_FILE"; then
        log_success "Database restore completed successfully"
    else
        log_error "Database restore failed"
        return 1
    fi
}

# Restore from specific file (used for rollbacks)
restore_from_file() {
    local file="$1"
    local operation="${2:-restore}"
    
    log_info "Performing $operation from file: $file"
    
    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi
    
    # Use the file directly (assuming it's already prepared)
    if pg_restore --verbose --no-password --clean --if-exists --dbname="$DATABASE_URL" "$file"; then
        log_success "$operation completed successfully"
    else
        log_error "$operation failed"
        return 1
    fi
}

# Get database information
get_database_info() {
    log_info "Current database information:"
    
    # Get database size
    local db_size
    db_size=$(psql "$DATABASE_URL" -t -c "SELECT pg_size_pretty(pg_database_size(current_database()));" | xargs)
    log_info "Database size: $db_size"
    
    # Get table count
    local table_count
    table_count=$(psql "$DATABASE_URL" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
    log_info "Table count: $table_count"
    
    # Get last backup timestamp (if available)
    local last_backup
    last_backup=$(find "$BACKUP_DIR" -name "electra_${ENVIRONMENT}_*.sql*" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2- | xargs basename 2>/dev/null || echo "None found")
    log_info "Last backup: $last_backup"
}

# Generate restore report
generate_report() {
    log_info "Restore Report:"
    log_info "==============="
    log_info "Environment: $ENVIRONMENT"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Source backup: ${BACKUP_FILE:-${ROLLBACK_FILE:-latest}}"
    log_info "Target database: ${TARGET_DATABASE:-current}"
    log_info "Clean restore: $CLEAN_RESTORE"
    log_info "Safety backup: $([ "$CREATE_SAFETY_BACKUP" == true ] && echo "created" || echo "skipped")"
    log_info "Verification: $([ "$VERIFY_ONLY" == true ] && echo "only" || echo "performed")"
    
    if [[ -f "$SAFETY_BACKUP_FILE" ]]; then
        log_info "Safety backup location: $SAFETY_BACKUP_FILE"
    fi
}

# Main execution
main() {
    log_info "Starting Electra database restore process"
    log_info "Environment: $ENVIRONMENT"
    
    # Check prerequisites
    check_prerequisites
    
    # List backups mode
    if [[ "$LIST_BACKUPS" == true ]]; then
        list_backups
        return 0
    fi
    
    # Test database connection
    test_database_connection
    
    # Get current database info
    get_database_info
    
    # Determine backup file to use
    if [[ -n "$ROLLBACK_FILE" ]]; then
        # Rollback mode
        log_info "Rollback mode: using file $ROLLBACK_FILE"
        if confirm_action "Perform rollback from $ROLLBACK_FILE?"; then
            restore_from_file "$ROLLBACK_FILE" "rollback"
        else
            log_info "Rollback cancelled by user"
            return 1
        fi
    elif [[ -n "$BACKUP_FILE" ]]; then
        # Specific file mode
        log_info "Using specified backup file: $BACKUP_FILE"
    elif [[ "$USE_LATEST" == true ]]; then
        # Latest backup mode
        BACKUP_FILE=$(find_latest_backup)
    else
        log_error "No backup file specified. Use --latest, provide a file path, or --list-backups"
        exit 1
    fi
    
    # Verify backup if not in rollback mode
    if [[ -z "$ROLLBACK_FILE" ]]; then
        verify_backup "$BACKUP_FILE"
        
        if [[ "$VERIFY_ONLY" == true ]]; then
            log_success "Backup verification completed successfully"
            return 0
        fi
        
        # Final confirmation
        if ! confirm_action "Restore database from $(basename "$BACKUP_FILE")?"; then
            log_info "Restore cancelled by user"
            return 1
        fi
        
        # Create safety backup
        create_safety_backup
        
        # Prepare restore file
        prepare_restore_file "$BACKUP_FILE"
        
        # Perform restore
        restore_database
    fi
    
    # Generate report
    generate_report
    
    log_success "Database restore process completed successfully"
}

# Run main function
main "$@"