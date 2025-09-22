# Security Guide for Electra Django Server

This document outlines the security features and best practices for deploying and maintaining the Electra Django voting system in production.

## 🔒 Security Features

### Authentication & Authorization
- **Argon2 Password Hashing**: Industry-standard password hashing with configurable parameters
- **JWT Authentication**: Short-lived access tokens (15 minutes) with refresh tokens (7 days)
- **Token Blacklisting**: Refresh tokens are blacklisted on logout and rotation
- **Role-based Access Control**: Admin, Electoral Committee, and Student roles with appropriate permissions

### Cryptographic Security
- **RSA-4096 Digital Signatures**: Strong asymmetric cryptography for vote integrity
- **Secure Random Token Generation**: Cryptographically secure random tokens for sessions
- **Key Rotation Support**: Built-in support for periodic key rotation

### Network Security
- **HTTPS Enforcement**: TLS 1.2+ required in production
- **HSTS Headers**: HTTP Strict Transport Security with 1-year max-age
- **CORS Protection**: Restrictive Cross-Origin Resource Sharing policies
- **CSRF Protection**: Cross-Site Request Forgery tokens required
- **Rate Limiting**: Configurable rate limits per endpoint and user

### Data Protection
- **Input Validation**: Comprehensive validation of all user inputs
- **SQL Injection Prevention**: Django ORM provides automatic protection
- **XSS Protection**: Content Security Policy and XSS filtering headers
- **Clickjacking Protection**: X-Frame-Options set to DENY

## 🛡️ Production Hardening Checklist

### Before Deployment

- [ ] **Generate Secure RSA Keys**
  ```bash
  make generate-keys
  chmod 600 keys/private.pem
  chmod 644 keys/public.pem
  ```

- [ ] **Set Strong Secret Keys** (minimum 50 characters each)
  ```bash
  DJANGO_SECRET_KEY=your_production_secret_key_here
  JWT_SECRET_KEY=your_jwt_secret_key_here
  JWT_REFRESH_SECRET_KEY=your_jwt_refresh_secret_key_here
  ```

- [ ] **Configure Production Database**
  ```bash
  DATABASE_URL=postgresql://user:secure_password@host:5432/electra_server?sslmode=require
  ```

- [ ] **Enable SSL/TLS**
  ```bash
  SECURE_SSL_REDIRECT=True
  SECURE_HSTS_SECONDS=31536000
  SECURE_HSTS_INCLUDE_SUBDOMAINS=True
  SECURE_HSTS_PRELOAD=True
  ```

- [ ] **Configure CORS Origins**
  ```bash
  CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://voting.yourdomain.com
  ```

- [ ] **Set Allowed Hosts**
  ```bash
  ALLOWED_HOSTS=yourdomain.com,voting.yourdomain.com,api.yourdomain.com
  ```

### System Configuration

- [ ] **Disable Debug Mode**
  ```bash
  DEBUG=False
  ```

- [ ] **Configure Secure Session Settings**
  - Session cookies: `HttpOnly`, `Secure`, `SameSite=Strict`
  - CSRF cookies: `HttpOnly`, `Secure`, `SameSite=Strict`

- [ ] **Set Up Structured Logging**
  ```bash
  LOG_LEVEL=INFO
  ENABLE_REQUEST_LOGGING=true
  ```

- [ ] **Configure Email Service**
  ```bash
  SMTP_HOST=smtp.yourdomain.com
  SMTP_PORT=587
  SMTP_USE_TLS=true
  SMTP_USER=your_email_user
  SMTP_PASS=your_secure_app_password
  ```

### Infrastructure Security

- [ ] **Database Security**
  - Enable SSL connections: `sslmode=require`
  - Use strong passwords (20+ characters)
  - Enable connection pooling
  - Regular automated backups with encryption

- [ ] **Redis Security** (if using)
  - Enable authentication: `requirepass`
  - Bind to localhost only unless clustered
  - Disable dangerous commands

- [ ] **Reverse Proxy Configuration**
  - Nginx/Apache with proper SSL configuration
  - Security headers middleware
  - Request size limits
  - Rate limiting at proxy level

- [ ] **Firewall Configuration**
  - Allow only necessary ports (80, 443, SSH)
  - Restrict database access to application servers only
  - Enable fail2ban for SSH protection

### Monitoring & Alerting

- [ ] **Security Monitoring**
  - Failed login attempt monitoring
  - Unusual access pattern detection
  - File integrity monitoring
  - Log analysis and alerting

- [ ] **Health Monitoring**
  - Application health checks
  - Database connection monitoring
  - SSL certificate expiration alerts
  - Disk space and memory monitoring

## 🔐 Key Management

### RSA Key Generation
```bash
# Generate new 4096-bit RSA keys
python scripts/generate_rsa_keys.py --key-size 4096

# Validate existing keys
python scripts/generate_rsa_keys.py --validate

# Force regeneration
python scripts/generate_rsa_keys.py --force
```

### Key Storage Best Practices
1. **Production Keys**: Store in secure key management service (AWS KMS, Azure Key Vault, etc.)
2. **Backup Keys**: Encrypt and store in separate secure location
3. **Access Control**: Restrict key file access to application user only
4. **Rotation Schedule**: Rotate keys every 90 days or as per policy

### Key Rotation Procedure
1. Generate new key pair
2. Update application configuration
3. Deploy to staging for testing
4. Deploy to production
5. Monitor for any issues
6. Securely delete old private key
7. Update any external systems using public key

## 🚨 Incident Response

### Security Breach Detection
Monitor for these indicators:
- Multiple failed login attempts
- Unusual API access patterns
- Database connection anomalies
- File system modifications
- Unexpected network traffic

### Response Procedure
1. **Isolate**: Disconnect affected systems
2. **Assess**: Determine scope and impact
3. **Contain**: Prevent further damage
4. **Eradicate**: Remove threat and vulnerabilities
5. **Recover**: Restore services safely
6. **Learn**: Document and improve processes

### Emergency Contacts
- Security Team: security@yourdomain.com
- System Administrator: admin@yourdomain.com
- Database Administrator: dba@yourdomain.com

## 📋 Regular Maintenance

### Weekly Tasks
- [ ] Review security logs
- [ ] Check SSL certificate status
- [ ] Monitor failed login attempts
- [ ] Verify backup integrity

### Monthly Tasks
- [ ] Update dependencies
- [ ] Security vulnerability scan
- [ ] Review user access permissions
- [ ] Test disaster recovery procedures

### Quarterly Tasks
- [ ] Rotate RSA keys
- [ ] Update JWT secret keys
- [ ] Security audit
- [ ] Penetration testing

## 🔧 Security Configuration Examples

### Nginx Configuration
```nginx
server {
    listen 443 ssl http2;
    server_name voting.yourdomain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
    limit_req zone=login burst=10 nodelay;
    
    location / {
        proxy_pass http://django_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Database SSL Configuration
```bash
# PostgreSQL SSL configuration
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
ssl_ciphers = 'ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256'
ssl_prefer_server_ciphers = on
```

## 📞 Support

For security-related questions or to report vulnerabilities:
- Email: security@yourdomain.com
- Security Advisory: [GitHub Security Advisories](https://github.com/yourusername/electra/security/advisories)

**Note**: Please report security vulnerabilities responsibly through private channels before public disclosure.