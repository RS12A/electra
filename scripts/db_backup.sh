#!/bin/bash
set -euo pipefail

# Electra Database Backup Script
# Production-grade PostgreSQL backup with encryption and retention management

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/electra}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
COMPRESSION_LEVEL="${COMPRESSION_LEVEL:-6}"

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
        log_error "Backup failed with exit code $exit_code"
        
        # Clean up temporary files
        rm -f "$TEMP_BACKUP_FILE" "$TEMP_COMPRESSED_FILE" 2>/dev/null || true
    fi
    exit $exit_code
}

trap cleanup EXIT

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [ENVIRONMENT] [VERSION_TAG]

Create encrypted database backup with retention management

ARGUMENTS:
    ENVIRONMENT             Environment (staging|production) [default: staging]
    VERSION_TAG             Version tag for backup naming [optional]

OPTIONS:
    --database-url URL      Database connection URL [default: from env]
    --backup-dir DIR        Backup directory [default: /var/backups/electra]
    --retention-days DAYS   Backup retention in days [default: 30]
    --compression-level N   Compression level 1-9 [default: 6]
    --encryption-key KEY    Encryption key for backup [default: from env]
    --no-compression        Disable compression
    --no-encryption         Disable encryption (NOT RECOMMENDED)
    --include-schema        Include schema in backup
    --exclude-table TABLE   Exclude specific table (can be used multiple times)
    --dry-run              Show what would be backed up without doing it
    --verify                Verify backup integrity after creation
    --upload-s3             Upload backup to S3 (requires AWS CLI)
    --s3-bucket BUCKET      S3 bucket for backup upload
    --cleanup-only          Only run cleanup of old backups
    -h, --help             Show this help message

EXAMPLES:
    $0 production v1.0.0
    $0 staging --verify --upload-s3
    $0 --cleanup-only --retention-days 7
    $0 production --exclude-table audit_log --exclude-table session_data

ENVIRONMENT VARIABLES:
    DATABASE_URL            PostgreSQL connection string
    BACKUP_ENCRYPTION_KEY   Key for backup encryption
    AWS_ACCESS_KEY_ID       AWS access key (for S3 upload)
    AWS_SECRET_ACCESS_KEY   AWS secret key (for S3 upload)
    BACKUP_DIR              Directory for backups
    PGPASSWORD              PostgreSQL password (alternative to URL)

BACKUP NAMING:
    electra_[environment]_[timestamp]_[version].sql.gz.enc

EOF
}

# Parse command line arguments
DATABASE_URL="${DATABASE_URL:-}"
ENCRYPTION_KEY="${BACKUP_ENCRYPTION_KEY:-}"
INCLUDE_SCHEMA=false
EXCLUDE_TABLES=()
DRY_RUN=false
VERIFY_BACKUP=false
UPLOAD_S3=false
S3_BUCKET="${S3_BUCKET:-}"
NO_COMPRESSION=false
NO_ENCRYPTION=false
CLEANUP_ONLY=false

# Parse positional arguments first
if [[ $# -gt 0 ]] && [[ "$1" != --* ]]; then
    ENVIRONMENT="$1"
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
        --retention-days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --compression-level)
            COMPRESSION_LEVEL="$2"
            shift 2
            ;;
        --encryption-key)
            ENCRYPTION_KEY="$2"
            shift 2
            ;;
        --no-compression)
            NO_COMPRESSION=true
            shift
            ;;
        --no-encryption)
            NO_ENCRYPTION=true
            shift
            ;;
        --include-schema)
            INCLUDE_SCHEMA=true
            shift
            ;;
        --exclude-table)
            EXCLUDE_TABLES+=("$2")
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verify)
            VERIFY_BACKUP=true
            shift
            ;;
        --upload-s3)
            UPLOAD_S3=true
            shift
            ;;
        --s3-bucket)
            S3_BUCKET="$2"
            shift 2
            ;;
        --cleanup-only)
            CLEANUP_ONLY=true
            shift
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

# Generate backup filename
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%S")
VERSION_SUFFIX=""
if [[ -n "${VERSION_TAG:-}" ]]; then
    VERSION_SUFFIX="_${VERSION_TAG}"
fi

BACKUP_FILENAME="electra_${ENVIRONMENT}_${TIMESTAMP}${VERSION_SUFFIX}.sql"
TEMP_BACKUP_FILE="/tmp/$BACKUP_FILENAME"
TEMP_COMPRESSED_FILE="/tmp/${BACKUP_FILENAME}.gz"
FINAL_BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILENAME"

# Add compression extension if enabled
if [[ "$NO_COMPRESSION" == false ]]; then
    FINAL_BACKUP_FILE="${FINAL_BACKUP_FILE}.gz"
fi

# Add encryption extension if enabled
if [[ "$NO_ENCRYPTION" == false ]]; then
    FINAL_BACKUP_FILE="${FINAL_BACKUP_FILE}.enc"
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check PostgreSQL client tools
    if ! command -v pg_dump &> /dev/null; then
        log_error "pg_dump is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        log_error "psql is not installed or not in PATH"
        exit 1
    fi
    
    # Check database URL
    if [[ -z "$DATABASE_URL" ]]; then
        log_error "DATABASE_URL is not set"
        exit 1
    fi
    
    # Check encryption key if encryption is enabled
    if [[ "$NO_ENCRYPTION" == false ]] && [[ -z "$ENCRYPTION_KEY" ]]; then
        log_error "BACKUP_ENCRYPTION_KEY is required for encryption"
        exit 1
    fi
    
    # Check compression tools if compression is enabled
    if [[ "$NO_COMPRESSION" == false ]] && ! command -v gzip &> /dev/null; then
        log_error "gzip is not installed or not in PATH"
        exit 1
    fi
    
    # Check encryption tools if encryption is enabled
    if [[ "$NO_ENCRYPTION" == false ]] && ! command -v openssl &> /dev/null; then
        log_error "openssl is not installed or not in PATH"
        exit 1
    fi
    
    # Check AWS CLI if S3 upload is enabled
    if [[ "$UPLOAD_S3" == true ]] && ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed or not in PATH"
        exit 1
    fi
    
    # Create backup directory if it doesn't exist
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_info "Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    
    # Check backup directory permissions
    if [[ ! -w "$BACKUP_DIR" ]]; then
        log_error "Backup directory is not writable: $BACKUP_DIR"
        exit 1
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

# Get database information
get_database_info() {
    log_info "Retrieving database information..."
    
    # Get database size
    local db_size
    db_size=$(psql "$DATABASE_URL" -t -c "SELECT pg_size_pretty(pg_database_size(current_database()));" | xargs)
    log_info "Database size: $db_size"
    
    # Get table count
    local table_count
    table_count=$(psql "$DATABASE_URL" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)
    log_info "Table count: $table_count"
    
    # Get estimated row count
    local row_count
    row_count=$(psql "$DATABASE_URL" -t -c "SELECT sum(n_tup_ins + n_tup_upd + n_tup_del) FROM pg_stat_user_tables;" | xargs)
    log_info "Estimated total rows: ${row_count:-0}"
}

# Create database backup
create_backup() {
    log_info "Creating database backup..."
    log_info "Backup file: $FINAL_BACKUP_FILE"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would create backup with the following settings:"
        log_info "  Source: $DATABASE_URL"
        log_info "  Target: $FINAL_BACKUP_FILE"
        log_info "  Compression: $([ "$NO_COMPRESSION" == true ] && echo "disabled" || echo "enabled (level $COMPRESSION_LEVEL)")"
        log_info "  Encryption: $([ "$NO_ENCRYPTION" == true ] && echo "disabled" || echo "enabled")"
        log_info "  Include schema: $INCLUDE_SCHEMA"
        log_info "  Excluded tables: ${EXCLUDE_TABLES[*]:-none}"
        return 0
    fi
    
    # Build pg_dump command
    local pg_dump_cmd=(
        pg_dump
        "$DATABASE_URL"
        --verbose
        --no-password
        --format=custom
        --compress=0  # We'll handle compression separately
    )
    
    # Add schema options
    if [[ "$INCLUDE_SCHEMA" == true ]]; then
        pg_dump_cmd+=(--schema-only)
    else
        pg_dump_cmd+=(--data-only)
    fi
    
    # Add table exclusions
    for table in "${EXCLUDE_TABLES[@]}"; do
        pg_dump_cmd+=(--exclude-table="$table")
    done
    
    # Execute pg_dump
    log_info "Executing pg_dump..."
    if "${pg_dump_cmd[@]}" > "$TEMP_BACKUP_FILE"; then
        log_success "Database dump completed"
    else
        log_error "Database dump failed"
        return 1
    fi
    
    # Get backup file size
    local backup_size
    backup_size=$(du -h "$TEMP_BACKUP_FILE" | cut -f1)
    log_info "Backup file size (uncompressed): $backup_size"
    
    # Compress backup if enabled
    if [[ "$NO_COMPRESSION" == false ]]; then
        log_info "Compressing backup..."
        if gzip -"$COMPRESSION_LEVEL" "$TEMP_BACKUP_FILE"; then
            mv "$TEMP_BACKUP_FILE.gz" "$TEMP_COMPRESSED_FILE"
            local compressed_size
            compressed_size=$(du -h "$TEMP_COMPRESSED_FILE" | cut -f1)
            log_info "Backup file size (compressed): $compressed_size"
        else
            log_error "Compression failed"
            return 1
        fi
    else
        # Use uncompressed file
        TEMP_COMPRESSED_FILE="$TEMP_BACKUP_FILE"
    fi
    
    # Encrypt backup if enabled
    if [[ "$NO_ENCRYPTION" == false ]]; then
        log_info "Encrypting backup..."
        if echo "$ENCRYPTION_KEY" | openssl enc -aes-256-cbc -salt -pbkdf2 -iter 100000 -in "$TEMP_COMPRESSED_FILE" -out "$FINAL_BACKUP_FILE" -pass stdin; then
            log_success "Backup encryption completed"
        else
            log_error "Backup encryption failed"
            return 1
        fi
    else
        # Move unencrypted file to final location
        mv "$TEMP_COMPRESSED_FILE" "$FINAL_BACKUP_FILE"
    fi
    
    # Set appropriate permissions
    chmod 600 "$FINAL_BACKUP_FILE"
    
    # Get final backup file size
    local final_size
    final_size=$(du -h "$FINAL_BACKUP_FILE" | cut -f1)
    log_info "Final backup file size: $final_size"
    
    log_success "Backup created successfully: $FINAL_BACKUP_FILE"
}

# Verify backup integrity
verify_backup() {
    if [[ "$VERIFY_BACKUP" == false ]]; then
        return 0
    fi
    
    log_info "Verifying backup integrity..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would verify backup integrity"
        return 0
    fi
    
    # Create temporary verification file
    local verify_file="/tmp/verify_$TIMESTAMP.sql"
    
    # Decrypt and decompress for verification
    if [[ "$NO_ENCRYPTION" == false ]]; then
        echo "$ENCRYPTION_KEY" | openssl enc -aes-256-cbc -d -pbkdf2 -iter 100000 -in "$FINAL_BACKUP_FILE" -pass stdin | \
        if [[ "$NO_COMPRESSION" == false ]]; then
            gzip -d > "$verify_file"
        else
            cat > "$verify_file"
        fi
    else
        if [[ "$NO_COMPRESSION" == false ]]; then
            gzip -dc "$FINAL_BACKUP_FILE" > "$verify_file"
        else
            cp "$FINAL_BACKUP_FILE" "$verify_file"
        fi
    fi
    
    # Verify the backup file structure
    if pg_restore --list "$verify_file" &> /dev/null; then
        log_success "✓ Backup verification passed"
        rm -f "$verify_file"
    else
        log_error "✗ Backup verification failed"
        rm -f "$verify_file"
        return 1
    fi
}

# Upload backup to S3
upload_to_s3() {
    if [[ "$UPLOAD_S3" == false ]]; then
        return 0
    fi
    
    if [[ -z "$S3_BUCKET" ]]; then
        log_error "S3_BUCKET is required for S3 upload"
        return 1
    fi
    
    log_info "Uploading backup to S3..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would upload to s3://$S3_BUCKET/backups/$(basename "$FINAL_BACKUP_FILE")"
        return 0
    fi
    
    local s3_key="backups/$(basename "$FINAL_BACKUP_FILE")"
    
    if aws s3 cp "$FINAL_BACKUP_FILE" "s3://$S3_BUCKET/$s3_key" \
        --storage-class STANDARD_IA \
        --server-side-encryption AES256; then
        log_success "Backup uploaded to S3: s3://$S3_BUCKET/$s3_key"
    else
        log_error "S3 upload failed"
        return 1
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log_info "Cleaning up backups older than $RETENTION_DAYS days..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "DRY RUN: Would delete backups older than $RETENTION_DAYS days"
        find "$BACKUP_DIR" -name "electra_${ENVIRONMENT}_*.sql*" -type f -mtime +$RETENTION_DAYS || true
        return 0
    fi
    
    # Find and delete old backups
    local deleted_count=0
    while IFS= read -r -d '' file; do
        log_info "Deleting old backup: $(basename "$file")"
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "electra_${ENVIRONMENT}_*.sql*" -type f -mtime +$RETENTION_DAYS -print0 2>/dev/null || true)
    
    log_info "Deleted $deleted_count old backup(s)"
    
    # Cleanup S3 backups if enabled
    if [[ "$UPLOAD_S3" == true ]] && [[ -n "$S3_BUCKET" ]]; then
        log_info "Cleaning up old S3 backups..."
        
        # List and delete old S3 backups (this is a simplified version)
        aws s3 ls "s3://$S3_BUCKET/backups/" --recursive | \
        awk -v env="$ENVIRONMENT" -v days="$RETENTION_DAYS" '
        /electra_'$ENVIRONMENT'_/ {
            cmd = "date -d \""$1" "$2"\" +%s"
            cmd | getline timestamp
            close(cmd)
            
            cmd = "date -d \"-"days" days\" +%s"
            cmd | getline cutoff
            close(cmd)
            
            if (timestamp < cutoff) {
                print "s3://'$S3_BUCKET'/"$4
            }
        }' | while read -r s3_path; do
            log_info "Deleting old S3 backup: $s3_path"
            aws s3 rm "$s3_path" || true
        done
    fi
}

# Generate backup report
generate_report() {
    log_info "Backup Report:"
    log_info "=============="
    log_info "Environment: $ENVIRONMENT"
    log_info "Timestamp: $TIMESTAMP"
    log_info "Version: ${VERSION_TAG:-N/A}"
    log_info "Database URL: ${DATABASE_URL%%@*}@[REDACTED]"
    log_info "Backup file: $FINAL_BACKUP_FILE"
    log_info "Compression: $([ "$NO_COMPRESSION" == true ] && echo "disabled" || echo "enabled")"
    log_info "Encryption: $([ "$NO_ENCRYPTION" == true ] && echo "disabled" || echo "enabled")"
    log_info "S3 upload: $([ "$UPLOAD_S3" == true ] && echo "enabled" || echo "disabled")"
    log_info "Retention: $RETENTION_DAYS days"
    
    if [[ -f "$FINAL_BACKUP_FILE" ]] && [[ "$DRY_RUN" == false ]]; then
        local file_size
        file_size=$(du -h "$FINAL_BACKUP_FILE" | cut -f1)
        log_info "Final size: $file_size"
    fi
}

# Main execution
main() {
    log_info "Starting Electra database backup process"
    log_info "Environment: $ENVIRONMENT"
    log_info "Backup directory: $BACKUP_DIR"
    
    # Check prerequisites
    check_prerequisites
    
    # Cleanup only mode
    if [[ "$CLEANUP_ONLY" == true ]]; then
        cleanup_old_backups
        log_success "Cleanup completed"
        return 0
    fi
    
    # Test database connection
    test_database_connection
    
    # Get database information
    get_database_info
    
    # Create backup
    create_backup
    
    # Verify backup
    verify_backup
    
    # Upload to S3
    upload_to_s3
    
    # Cleanup old backups
    cleanup_old_backups
    
    # Generate report
    generate_report
    
    log_success "Database backup process completed successfully"
}

# Run main function
main "$@"