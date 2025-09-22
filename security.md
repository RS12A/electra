# Security Guidelines for Electra Server

This document outlines security best practices and hardening procedures for the Electra Server Django application.

## Production Security Checklist

### 🔐 Authentication & Authorization

- [ ] **JWT Security**
  - [ ] Use RSA-256 signing with 4096-bit keys
  - [ ] Set short access token lifetime (15 minutes recommended)
  - [ ] Enable refresh token rotation
  - [ ] Implement token blacklisting
  - [ ] Store signing keys securely (not in code)

- [ ] **Password Security**
  - [ ] Argon2 password hashing enabled (default in settings)
  - [ ] Minimum password length enforced (8 characters)
  - [ ] Password complexity validation active
  - [ ] Account lockout after failed attempts (implement rate limiting)

- [ ] **User Registration**
  - [ ] Email verification required
  - [ ] Matric/Staff ID validation implemented
  - [ ] Input sanitization on all fields
  - [ ] CAPTCHA for registration (recommended for production)

### 🌐 Web Security Headers

The following security headers are configured in production settings:

- [ ] **HTTPS Enforcement**
  - [ ] `SECURE_SSL_REDIRECT = True`
  - [ ] `SECURE_PROXY_SSL_HEADER` configured for reverse proxy
  - [ ] SSL certificate valid and properly configured

- [ ] **HTTP Strict Transport Security (HSTS)**
  - [ ] `SECURE_HSTS_SECONDS = 31536000` (1 year)
  - [ ] `SECURE_HSTS_INCLUDE_SUBDOMAINS = True`
  - [ ] `SECURE_HSTS_PRELOAD = True`
  - [ ] Domain added to HSTS preload list

- [ ] **Content Security Policy**
  - [ ] `X_FRAME_OPTIONS = 'DENY'`
  - [ ] `SECURE_CONTENT_TYPE_NOSNIFF = True`
  - [ ] `SECURE_BROWSER_XSS_FILTER = True`
  - [ ] `SECURE_REFERRER_POLICY` configured

- [ ] **Cookie Security**
  - [ ] `SESSION_COOKIE_SECURE = True`
  - [ ] `SESSION_COOKIE_HTTPONLY = True`
  - [ ] `SESSION_COOKIE_SAMESITE = 'Strict'`
  - [ ] `CSRF_COOKIE_SECURE = True`
  - [ ] `CSRF_COOKIE_HTTPONLY = True`

### 🗄️ Database Security

- [ ] **PostgreSQL Configuration**
  - [ ] Use PostgreSQL in production (no SQLite)
  - [ ] Database credentials stored securely
  - [ ] Connection pooling configured
  - [ ] Database user has minimal required permissions
  - [ ] Regular database backups automated

- [ ] **Connection Security**
  - [ ] Use SSL/TLS for database connections
  - [ ] Restrict database access to application servers only
  - [ ] Monitor database connection attempts
  - [ ] Use environment variables for connection strings

### 🔒 Environment & Infrastructure

- [ ] **Environment Variables**
  - [ ] All secrets stored in environment variables
  - [ ] `.env` file never committed to version control
  - [ ] Different secrets for different environments
  - [ ] Secret rotation procedures documented

- [ ] **Server Configuration**
  - [ ] Non-root user for application process
  - [ ] Firewall configured (only necessary ports open)
  - [ ] OS security updates automated
  - [ ] Log monitoring and alerting configured

- [ ] **Docker Security**
  - [ ] Multi-stage builds to minimize image size
  - [ ] Non-root user in containers
  - [ ] Security scanning of container images
  - [ ] Minimal base images used
  - [ ] Secrets mounted as volumes, not environment variables

### 📊 Logging & Monitoring

- [ ] **Security Logging**
  - [ ] Authentication attempts logged
  - [ ] Failed login attempts monitored
  - [ ] Suspicious activity alerts configured
  - [ ] Log integrity protection
  - [ ] Centralized log management

- [ ] **Application Monitoring**
  - [ ] Health check endpoints monitored
  - [ ] Performance metrics tracked
  - [ ] Error tracking configured
  - [ ] Security incident response plan

### 🔄 Key Management & Rotation

#### RSA Key Rotation Procedure

1. **Preparation**
   ```bash
   # Generate new key pair
   python scripts/generate_rsa_keys.py --output-dir keys_new/
   
   # Verify new keys
   openssl rsa -in keys_new/private_key.pem -check -noout
   openssl rsa -in keys_new/private_key.pem -pubout | diff - keys_new/public_key.pem
   ```

2. **Deployment**
   ```bash
   # Backup current keys
   cp -r keys/ keys_backup_$(date +%Y%m%d)/
   
   # Deploy new keys (keep old keys for grace period)
   # Update environment variables to point to new keys
   # Restart application
   ```

3. **Grace Period**
   - Keep old keys for 24-48 hours to verify existing tokens
   - Monitor for authentication errors
   - Rollback if issues detected

4. **Cleanup**
   ```bash
   # After grace period, remove old keys
   rm -rf keys_backup_*/
   ```

#### Database Secret Rotation

1. Create new database credentials
2. Update connection string in environment
3. Test connection with new credentials
4. Deploy with zero-downtime strategy
5. Revoke old credentials

#### JWT Secret Rotation

1. Generate new JWT secret key
2. Deploy alongside existing secret (support both temporarily)
3. Monitor token validation
4. Remove old secret after all tokens expire

### 🔍 Security Scanning & Auditing

#### Automated Security Checks

```bash
# Python dependency security scanning
make security-check

# Or manually:
safety check
bandit -r apps/
```

#### Manual Security Audit

- [ ] **Code Review**
  - [ ] Static analysis tools configured
  - [ ] Security-focused code reviews
  - [ ] Dependency vulnerability scanning
  - [ ] SQL injection prevention verified

- [ ] **Penetration Testing**
  - [ ] Regular penetration testing scheduled
  - [ ] Vulnerability assessment performed
  - [ ] Security findings remediated
  - [ ] Testing includes API endpoints

### 📋 Incident Response

#### Security Incident Procedures

1. **Detection**
   - Monitor logs for suspicious activity
   - Set up alerts for security events
   - Regular security health checks

2. **Response**
   - Isolate affected systems
   - Preserve evidence and logs
   - Assess scope of compromise
   - Notify stakeholders

3. **Recovery**
   - Patch vulnerabilities
   - Rotate compromised credentials
   - Restore from clean backups
   - Update security measures

4. **Lessons Learned**
   - Document incident details
   - Update security procedures
   - Train team on new threats
   - Implement preventive measures

### 🛡️ Additional Security Measures

#### Rate Limiting
```python
# Add to settings for API rate limiting
REST_FRAMEWORK['DEFAULT_THROTTLE_CLASSES'] = [
    'rest_framework.throttling.AnonRateThrottle',
    'rest_framework.throttling.UserRateThrottle'
]
REST_FRAMEWORK['DEFAULT_THROTTLE_RATES'] = {
    'anon': '100/hour',
    'user': '1000/hour'
}
```

#### IP Whitelisting
```python
# Add to production settings if needed
ALLOWED_HOSTS = ['your-domain.com']
INTERNAL_IPS = ['127.0.0.1']  # For debug toolbar in dev
```

#### Security Headers Middleware
```python
# Additional security headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
X_FRAME_OPTIONS = 'DENY'
```

### 📚 Security Resources

- [Django Security Documentation](https://docs.djangoproject.com/en/stable/topics/security/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Django Security Checklist](https://docs.djangoproject.com/en/stable/howto/deployment/checklist/)
- [JWT Security Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)

### 🚨 Emergency Contacts

- **Security Team**: security@electra.com
- **DevOps Team**: devops@electra.com
- **Emergency Hotline**: +1-XXX-XXX-XXXX

---

**Note**: This security guide should be reviewed and updated regularly as the application evolves and new security threats emerge. All team members should be familiar with these procedures.