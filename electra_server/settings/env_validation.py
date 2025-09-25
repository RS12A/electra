"""
Environment validation utilities for production readiness.
"""
import os
import sys
from typing import List, Dict, Any, Optional


class EnvironmentValidator:
    """Validates environment variables for production deployment."""
    
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
    
    def check_required_var(self, var_name: str, description: str = "") -> bool:
        """Check if a required environment variable is set and not empty."""
        value = os.getenv(var_name)
        if not value or value.strip() == "" or value == "your_KEY_goes_here":
            error_msg = f"Required environment variable '{var_name}' is not set"
            if description:
                error_msg += f" ({description})"
            self.errors.append(error_msg)
            return False
        return True
    
    def check_optional_var(self, var_name: str, default_value: str = None, warning_msg: str = "") -> bool:
        """Check optional environment variable and warn if using default."""
        value = os.getenv(var_name, default_value)
        if not value or value == "your_KEY_goes_here":
            if warning_msg:
                self.warnings.append(f"Optional variable '{var_name}': {warning_msg}")
            return False
        return True
    
    def check_file_exists(self, var_name: str, description: str = "") -> bool:
        """Check if file path from environment variable exists."""
        file_path = os.getenv(var_name)
        if not file_path:
            self.errors.append(f"File path variable '{var_name}' is not set ({description})")
            return False
        
        if not os.path.exists(file_path):
            self.errors.append(f"File specified in '{var_name}' does not exist: {file_path} ({description})")
            return False
        return True
    
    def check_url_format(self, var_name: str, description: str = "") -> bool:
        """Check if URL format is valid."""
        url = os.getenv(var_name)
        if not url:
            return False
        
        valid_schemes = ['http://', 'https://', 'postgresql://', 'redis://', 'rediss://']
        if not any(url.startswith(scheme) for scheme in valid_schemes):
            self.errors.append(f"Invalid URL format for '{var_name}': {url} ({description})")
            return False
        return True
    
    def validate_production_environment(self) -> bool:
        """Validate all required environment variables for production."""
        print("🔍 Validating production environment variables...")
        
        # Core Django settings
        self.check_required_var('DJANGO_SECRET_KEY', 'Django secret key for cryptographic signing')
        self.check_required_var('DJANGO_ALLOWED_HOSTS', 'Comma-separated list of allowed hosts')
        
        # Database
        self.check_required_var('DATABASE_URL', 'PostgreSQL database connection string')
        self.check_url_format('DATABASE_URL', 'Database connection')
        
        # JWT Configuration
        self.check_required_var('JWT_SECRET_KEY', 'JWT signing secret key')
        
        # RSA Keys for JWT
        self.check_file_exists('RSA_PRIVATE_KEY_PATH', 'RSA private key for JWT signing')
        self.check_file_exists('RSA_PUBLIC_KEY_PATH', 'RSA public key for JWT verification')
        
        # Email Configuration
        self.check_required_var('EMAIL_HOST', 'SMTP server hostname')
        self.check_required_var('EMAIL_HOST_USER', 'SMTP username')
        self.check_required_var('EMAIL_HOST_PASSWORD', 'SMTP password')
        
        # Redis (required for production caching)
        self.check_required_var('REDIS_URL', 'Redis connection string for caching')
        self.check_url_format('REDIS_URL', 'Redis connection')
        
        # Security settings
        debug_mode = os.getenv('DJANGO_DEBUG', 'False').lower()
        if debug_mode in ('true', '1', 'yes'):
            self.warnings.append("DEBUG mode is enabled - ensure this is intentional for production")
        
        ssl_redirect = os.getenv('SECURE_SSL_REDIRECT', 'False').lower()
        if ssl_redirect not in ('true', '1', 'yes'):
            self.warnings.append("SSL redirect is disabled - consider enabling for production")
        
        return len(self.errors) == 0
    
    def validate_optional_features(self) -> None:
        """Validate optional feature configurations."""
        
        # Firebase/FCM for push notifications
        if os.getenv('FCM_SERVER_KEY'):
            self.check_required_var('FIREBASE_PROJECT_ID', 'Firebase project ID for FCM')
            self.check_required_var('FCM_SENDER_ID', 'Firebase sender ID for FCM')
        
        # AWS Configuration
        if os.getenv('AWS_ACCESS_KEY_ID'):
            self.check_required_var('AWS_SECRET_ACCESS_KEY', 'AWS secret access key')
            self.check_required_var('AWS_STORAGE_BUCKET_NAME', 'AWS S3 bucket name')
        
        # Monitoring
        self.check_optional_var('SENTRY_DSN', warning_msg="Sentry error tracking not configured")
        self.check_optional_var('SLACK_WEBHOOK_URL', warning_msg="Slack alerting not configured")
        
        # Backup configuration
        self.check_optional_var('BACKUP_ENCRYPTION_KEY', warning_msg="Backup encryption not configured")
    
    def print_results(self) -> None:
        """Print validation results."""
        if self.errors:
            print("\n❌ Environment Validation Errors:")
            for error in self.errors:
                print(f"  - {error}")
        
        if self.warnings:
            print("\n⚠️  Environment Validation Warnings:")
            for warning in self.warnings:
                print(f"  - {warning}")
        
        if not self.errors and not self.warnings:
            print("✅ All environment variables are properly configured!")
        elif not self.errors:
            print("✅ Required environment variables are configured (with warnings)")


def validate_environment(fail_on_error: bool = True) -> bool:
    """
    Validate environment configuration.
    
    Args:
        fail_on_error: Whether to exit with error code if validation fails
        
    Returns:
        bool: True if validation passes, False otherwise
    """
    validator = EnvironmentValidator()
    
    # Run validation
    is_valid = validator.validate_production_environment()
    validator.validate_optional_features()
    
    # Print results
    validator.print_results()
    
    if not is_valid and fail_on_error:
        print("\n💡 Fix the above errors before deploying to production.")
        print("   See README.md for instructions on generating keys and configuring services.")
        sys.exit(1)
    
    return is_valid


def check_key_files() -> bool:
    """Check RSA key files exist and have proper permissions."""
    private_key_path = os.getenv('RSA_PRIVATE_KEY_PATH', 'keys/private_key.pem')
    public_key_path = os.getenv('RSA_PUBLIC_KEY_PATH', 'keys/public_key.pem')
    
    issues = []
    
    if not os.path.exists(private_key_path):
        issues.append(f"Private key file not found: {private_key_path}")
        issues.append("  Run: python scripts/generate_rsa_keys.py")
    else:
        # Check file permissions (should be 600 for private key)
        stat_info = os.stat(private_key_path)
        permissions = oct(stat_info.st_mode)[-3:]
        if permissions not in ['600', '400']:
            issues.append(f"Private key has insecure permissions: {permissions}")
            issues.append(f"  Run: chmod 600 {private_key_path}")
    
    if not os.path.exists(public_key_path):
        issues.append(f"Public key file not found: {public_key_path}")
        issues.append("  Run: python scripts/generate_rsa_keys.py")
    
    if issues:
        print("🔐 RSA Key Issues:")
        for issue in issues:
            print(f"  {issue}")
        return False
    
    print("✅ RSA keys are properly configured")
    return True


if __name__ == "__main__":
    # Allow running this module directly for validation
    validate_environment()