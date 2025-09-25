# Electra Production Deployment Guide

This guide provides step-by-step instructions for deploying the Electra e-voting system to production.

## 🚀 Pre-Deployment Checklist

### 1. Environment Configuration

- [ ] Copy `.env.production.template` to `.env.production`
- [ ] Replace ALL placeholder values (`CHANGE_ME`, `YOUR_`, `your_KEY_goes_here`)
- [ ] Set strong, unique passwords and secrets
- [ ] Configure production domain names
- [ ] Set up SSL certificates

### 2. Security Setup

- [ ] Generate RSA keys: `python scripts/generate_rsa_keys.py --key-size=4096`
- [ ] Set proper file permissions: `chmod 600 keys/private_key.pem`
- [ ] Validate environment: `python scripts/validate_environment.py --strict`
- [ ] Run security checks: `python scripts/production_readiness_check.py`

### 3. Database Setup

- [ ] Set up PostgreSQL production database
- [ ] Create database user with limited permissions
- [ ] Configure SSL connections
- [ ] Set up automated backups

### 4. External Services

- [ ] Configure SMTP email service
- [ ] Set up Redis for caching
- [ ] Configure Firebase for push notifications (optional)
- [ ] Set up monitoring services (Sentry, etc.)

### 5. Infrastructure

- [ ] Set up reverse proxy (nginx)
- [ ] Configure SSL/TLS certificates
- [ ] Set up firewall rules
- [ ] Configure log rotation
- [ ] Set up monitoring and alerting

## 📋 Deployment Steps

### Step 1: Server Preparation

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip postgresql-client redis-tools nginx certbot

# Create application user
sudo useradd -m -s /bin/bash electra
sudo usermod -aG sudo electra
```

### Step 2: Application Deployment

```bash
# Clone repository
git clone https://github.com/RS12A/electra.git /opt/electra
cd /opt/electra

# Set ownership
sudo chown -R electra:electra /opt/electra

# Switch to electra user
sudo su - electra

# Set up Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Generate RSA keys
python scripts/generate_rsa_keys.py --key-size=4096

# Set proper permissions
chmod 600 keys/private_key.pem
chmod 644 keys/public_key.pem
```

### Step 3: Database Setup

```bash
# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE electra_production;
CREATE USER electra_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE electra_production TO electra_user;
ALTER USER electra_user CREATEDB;
\q
EOF

# Run migrations
python manage.py migrate --settings=electra_server.settings.prod
```

### Step 4: Configure Environment

```bash
# Copy and configure environment file
cp .env.production.template .env.production

# Edit with your production values
nano .env.production

# Validate configuration
python scripts/validate_environment.py --strict
```

### Step 5: Static Files and Media

```bash
# Collect static files
python manage.py collectstatic --noinput --settings=electra_server.settings.prod

# Create media directories
mkdir -p media/{ballots,reports,backups}
chmod 755 media/
```

### Step 6: Set up System Services

Create systemd service file:

```bash
sudo nano /etc/systemd/system/electra.service
```

```ini
[Unit]
Description=Electra Django Application
After=network.target

[Service]
Type=forking
User=electra
Group=electra
WorkingDirectory=/opt/electra
Environment=PATH=/opt/electra/venv/bin
ExecStart=/opt/electra/venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 3 --worker-class gthread --threads 2 --daemon --pid /opt/electra/electra.pid electra_server.wsgi:application
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Step 7: Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/electra
```

```nginx
server {
    listen 80;
    server_name your-domain.com api.your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com api.your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }

    location /static/ {
        alias /opt/electra/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/electra/media/;
        expires 7d;
    }
}
```

### Step 8: SSL Certificate Setup

```bash
# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d api.your-domain.com

# Set up auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Step 9: Start Services

```bash
# Enable and start services
sudo systemctl enable electra
sudo systemctl start electra
sudo systemctl enable nginx
sudo systemctl restart nginx

# Check status
sudo systemctl status electra
sudo systemctl status nginx
```

### Step 10: Deploy Flutter Web App

```bash
cd electra_flutter

# Install Flutter dependencies
flutter pub get

# Build for web
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.your-domain.com \
  --dart-define=WS_BASE_URL=wss://api.your-domain.com \
  --dart-define=FIREBASE_PROJECT_ID=your-firebase-project \
  --dart-define=FIREBASE_API_KEY=your-firebase-api-key

# Deploy web build
sudo cp -r build/web/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
```

## 🔍 Post-Deployment Verification

### Health Checks

```bash
# Check application health
curl -f https://api.your-domain.com/api/health/

# Check database connectivity
python manage.py dbshell --settings=electra_server.settings.prod

# Run production readiness check
python scripts/production_readiness_check.py
```

### Security Validation

```bash
# Test SSL configuration
curl -I https://api.your-domain.com/

# Check security headers
curl -I https://api.your-domain.com/ | grep -E "(X-Frame-Options|X-Content-Type-Options|Strict-Transport-Security)"

# Validate HTTPS redirect
curl -I http://api.your-domain.com/
```

### Monitoring Setup

```bash
# Deploy monitoring stack
cd monitoring
./scripts/deploy_monitoring.sh production

# Verify monitoring endpoints
curl -f http://localhost:9090/-/healthy    # Prometheus
curl -f http://localhost:3000/api/health   # Grafana
```

## 📊 Performance Optimization

### Database Optimization

```sql
-- Create indexes for better performance
CREATE INDEX idx_votes_election_id ON votes_vote(election_id);
CREATE INDEX idx_ballots_user_id ON ballots_ballottoken(user_id);
CREATE INDEX idx_audit_timestamp ON audit_auditlog(timestamp);
```

### Redis Configuration

```bash
# Configure Redis for production
sudo nano /etc/redis/redis.conf

# Set:
# maxmemory 256mb
# maxmemory-policy allkeys-lru
# save 900 1
# save 300 10
# save 60 10000
```

## 🔒 Security Hardening

### Firewall Configuration

```bash
# Configure UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Additional Security Measures

```bash
# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable cups

# Configure fail2ban
sudo apt install fail2ban
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Secure SSH
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PermitRootLogin no
sudo systemctl restart sshd
```

## 📦 Backup and Recovery

### Automated Backups

```bash
# Set up automated database backup
sudo crontab -e
# Add: 0 2 * * * /opt/electra/scripts/db_backup.sh

# Set up automated file backup
# Add: 0 3 * * * /opt/electra/scripts/file_backup.sh
```

### Disaster Recovery Testing

```bash
# Test backup restoration
python scripts/db_restore.py --backup-file=/path/to/backup.sql

# Verify data integrity
python manage.py check_integrity --settings=electra_server.settings.prod
```

## 🚨 Emergency Procedures

### System Recovery

```bash
# Emergency stop
sudo systemctl stop electra nginx

# Quick restart
sudo systemctl restart electra nginx

# Rollback deployment
git checkout previous-stable-tag
sudo systemctl restart electra
```

### Monitoring and Alerts

- Monitor application logs: `/opt/electra/logs/`
- Check system metrics: Grafana dashboard
- Security alerts: Configured via Slack/email

## 📞 Support and Maintenance

### Regular Maintenance Tasks

- [ ] Weekly security updates
- [ ] Monthly backup verification  
- [ ] Quarterly security audits
- [ ] SSL certificate renewal (automated)

### Support Contacts

- **Technical Support**: tech-support@your-domain.com
- **Security Issues**: security@your-domain.com
- **Emergency Contact**: +234-XXX-XXX-XXXX

---

**⚠️ IMPORTANT**: Always test deployments in a staging environment before production. Keep this guide updated with any infrastructure changes.