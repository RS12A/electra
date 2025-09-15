#!/bin/bash

# Electra Production Deployment Script

set -e

echo "🗳️  Deploying Electra to Production"
echo "===================================="

# Configuration
BACKUP_DIR="/backup/electra/$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/electra/deploy.log"

# Functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_requirements() {
    log "📋 Checking deployment requirements..."
    
    # Check if .env file exists
    if [ ! -f .env ]; then
        log "❌ .env file not found. Copy .env.example and configure it."
        exit 1
    fi
    
    # Check if required environment variables are set
    required_vars=("DATABASE_URL" "JWT_SECRET" "JWT_REFRESH_SECRET" "VOTE_ENCRYPTION_KEY")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^$var=" .env; then
            log "❌ Required environment variable $var not set in .env"
            exit 1
        fi
    done
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log "❌ Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "❌ Docker Compose is not installed"
        exit 1
    fi
    
    log "✅ Requirements check passed"
}

backup_data() {
    log "💾 Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup database
    if docker-compose ps postgres | grep -q "Up"; then
        docker-compose exec -T postgres pg_dump -U electra_user electra_db > "$BACKUP_DIR/database.sql"
        log "✅ Database backup created"
    fi
    
    # Backup encryption keys
    if [ -d "server/keys" ]; then
        cp -r server/keys "$BACKUP_DIR/"
        log "✅ Encryption keys backed up"
    fi
    
    # Backup uploads
    if [ -d "server/uploads" ]; then
        cp -r server/uploads "$BACKUP_DIR/"
        log "✅ Uploads backed up"
    fi
    
    log "✅ Backup completed: $BACKUP_DIR"
}

deploy() {
    log "🚀 Starting deployment..."
    
    # Pull latest changes
    log "📥 Pulling latest code..."
    git pull origin main
    
    # Build and deploy with Docker Compose
    log "🔨 Building and starting services..."
    docker-compose down
    docker-compose build
    docker-compose up -d
    
    # Wait for services to be ready
    log "⏳ Waiting for services to be ready..."
    sleep 30
    
    # Check health
    health_check
    
    log "✅ Deployment completed successfully"
}

health_check() {
    log "🏥 Performing health check..."
    
    # Check API health
    if curl -f http://localhost:3000/api/v1/health > /dev/null 2>&1; then
        log "✅ API is healthy"
    else
        log "❌ API health check failed"
        return 1
    fi
    
    # Check database connection
    if docker-compose exec -T postgres pg_isready -U electra_user > /dev/null 2>&1; then
        log "✅ Database is healthy"
    else
        log "❌ Database health check failed"
        return 1
    fi
    
    log "✅ All health checks passed"
}

rollback() {
    log "🔄 Rolling back deployment..."
    
    # Stop current services
    docker-compose down
    
    # Restore database from backup
    if [ -f "$BACKUP_DIR/database.sql" ]; then
        log "Restoring database..."
        docker-compose up -d postgres
        sleep 10
        docker-compose exec -T postgres psql -U electra_user -d electra_db < "$BACKUP_DIR/database.sql"
    fi
    
    # Restore files
    if [ -d "$BACKUP_DIR/keys" ]; then
        cp -r "$BACKUP_DIR/keys" server/
    fi
    
    if [ -d "$BACKUP_DIR/uploads" ]; then
        cp -r "$BACKUP_DIR/uploads" server/
    fi
    
    log "✅ Rollback completed"
}

# Main deployment process
main() {
    log "Starting deployment process..."
    
    check_requirements
    backup_data
    
    if deploy; then
        log "🎉 Deployment successful!"
        
        # Send notification (if configured)
        if [ ! -z "$SLACK_WEBHOOK" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"🎉 Electra deployment successful!"}' \
                "$SLACK_WEBHOOK"
        fi
    else
        log "❌ Deployment failed. Rolling back..."
        rollback
        exit 1
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "rollback")
        if [ -z "$2" ]; then
            log "❌ Please specify backup directory for rollback"
            exit 1
        fi
        BACKUP_DIR="$2"
        rollback
        ;;
    "health")
        health_check
        ;;
    *)
        echo "Usage: $0 [deploy|rollback <backup_dir>|health]"
        exit 1
        ;;
esac