#!/usr/bin/env python3
"""
Standalone environment validation script for Electra.

This script validates environment configuration without requiring Django setup.
It can be run in CI/CD pipelines or during deployment preparation.

Usage:
    python scripts/validate_environment.py
    python scripts/validate_environment.py --strict  # Fail on warnings too
    python scripts/validate_environment.py --env-file .env.production
"""

import os
import sys
import argparse
from pathlib import Path

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

try:
    from electra_server.settings.env_validation import EnvironmentValidator, check_key_files
except ImportError:
    print("❌ Could not import environment validation module")
    print("   Make sure you're running from the project root directory")
    sys.exit(1)


def load_env_file(env_file_path: str) -> None:
    """Load environment variables from file."""
    if not os.path.exists(env_file_path):
        print(f"❌ Environment file not found: {env_file_path}")
        sys.exit(1)
    
    print(f"📄 Loading environment from: {env_file_path}")
    
    try:
        from dotenv import load_dotenv
        load_dotenv(env_file_path)
        print("✅ Environment file loaded successfully")
    except ImportError:
        print("⚠️  python-dotenv not available, manually parsing env file")
        # Fallback: manual parsing
        with open(env_file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        # Remove quotes if present
                        value = value.strip('"\'')
                        os.environ[key.strip()] = value
                    else:
                        print(f"⚠️  Malformed line {line_num} in {env_file_path}: {line}")


def validate_docker_environment() -> None:
    """Validate Docker-specific environment settings."""
    print("\n🐳 Validating Docker environment...")
    
    # Check for Docker-related environment variables
    docker_vars = [
        'POSTGRES_DB', 'POSTGRES_USER', 'POSTGRES_PASSWORD',
        'REDIS_PORT', 'WEB_PORT', 'NGINX_HTTP_PORT', 'NGINX_HTTPS_PORT'
    ]
    
    warnings = []
    for var in docker_vars:
        if not os.getenv(var):
            warnings.append(f"Docker variable '{var}' not set - using default")
    
    if warnings:
        print("⚠️  Docker Environment Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    else:
        print("✅ Docker environment configuration is complete")


def validate_ci_cd_environment() -> None:
    """Validate CI/CD specific environment settings."""
    print("\n🔄 Validating CI/CD environment...")
    
    ci_vars = [
        'DOCKER_REGISTRY', 'DOCKER_REGISTRY_USER', 'DOCKER_REGISTRY_TOKEN',
        'KUBECONFIG_PATH', 'KUBECTL_CONTEXT', 'SNYK_TOKEN'
    ]
    
    errors = []
    warnings = []
    
    for var in ci_vars:
        value = os.getenv(var, '').strip()
        if not value or value == 'your_KEY_goes_here':
            if var in ['DOCKER_REGISTRY_USER', 'DOCKER_REGISTRY_TOKEN']:
                errors.append(f"CI/CD variable '{var}' is required for deployment")
            else:
                warnings.append(f"CI/CD variable '{var}' not configured")
    
    if errors:
        print("❌ CI/CD Environment Errors:")
        for error in errors:
            print(f"  - {error}")
    
    if warnings:
        print("⚠️  CI/CD Environment Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    
    if not errors and not warnings:
        print("✅ CI/CD environment configuration is complete")
    
    return len(errors) == 0


def validate_security_configuration() -> bool:
    """Validate security-related configuration."""
    print("\n🔒 Validating security configuration...")
    
    errors = []
    warnings = []
    
    # Check for default/insecure values
    insecure_defaults = {
        'DJANGO_SECRET_KEY': ['your_KEY_goes_here', 'dev-secret-key-change-in-production'],
        'JWT_SECRET_KEY': ['your_KEY_goes_here', 'dev-jwt-secret'],
        'ADMIN_PASSWORD': ['your_KEY_goes_here', 'admin', 'password', '123456'],
        'POSTGRES_PASSWORD': ['postgres123', 'password', 'admin'],
    }
    
    for var, insecure_values in insecure_defaults.items():
        value = os.getenv(var, '').strip()
        if value in insecure_values:
            errors.append(f"Insecure default value for '{var}' - must be changed for production")
    
    # Check SSL configuration
    ssl_redirect = os.getenv('SECURE_SSL_REDIRECT', 'False').lower()
    if ssl_redirect not in ['true', '1', 'yes']:
        warnings.append("SSL redirect is disabled - consider enabling for production")
    
    # Check debug mode
    debug_mode = os.getenv('DJANGO_DEBUG', 'False').lower()
    if debug_mode in ['true', '1', 'yes']:
        warnings.append("DEBUG mode is enabled - disable for production")
    
    if errors:
        print("❌ Security Configuration Errors:")
        for error in errors:
            print(f"  - {error}")
    
    if warnings:
        print("⚠️  Security Configuration Warnings:")
        for warning in warnings:
            print(f"  - {warning}")
    
    if not errors and not warnings:
        print("✅ Security configuration looks good")
    
    return len(errors) == 0


def main():
    """Main validation function."""
    parser = argparse.ArgumentParser(
        description="Validate Electra environment configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python scripts/validate_environment.py
    python scripts/validate_environment.py --strict
    python scripts/validate_environment.py --env-file .env.production
    python scripts/validate_environment.py --skip-keys
        """
    )
    
    parser.add_argument(
        '--env-file',
        type=str,
        help='Path to environment file to load (default: .env if it exists)'
    )
    
    parser.add_argument(
        '--strict',
        action='store_true',
        help='Fail on warnings as well as errors'
    )
    
    parser.add_argument(
        '--skip-keys',
        action='store_true',
        help='Skip RSA key validation (useful for CI/CD)'
    )
    
    parser.add_argument(
        '--skip-docker',
        action='store_true',
        help='Skip Docker environment validation'
    )
    
    parser.add_argument(
        '--skip-cicd',
        action='store_true',
        help='Skip CI/CD environment validation'
    )
    
    args = parser.parse_args()
    
    print("🔍 Electra Environment Validation")
    print("=" * 40)
    
    # Load environment file if specified
    if args.env_file:
        load_env_file(args.env_file)
    elif os.path.exists('.env'):
        load_env_file('.env')
    else:
        print("📄 No .env file found - using system environment variables")
    
    # Run validations
    validator = EnvironmentValidator()
    
    # Core Django validation
    is_valid = validator.validate_production_environment()
    validator.validate_optional_features()
    validator.print_results()
    
    # Security validation
    security_valid = validate_security_configuration()
    is_valid = is_valid and security_valid
    
    # Key validation
    if not args.skip_keys:
        keys_valid = check_key_files()
        is_valid = is_valid and keys_valid
    
    # Docker validation
    if not args.skip_docker:
        validate_docker_environment()
    
    # CI/CD validation
    if not args.skip_cicd:
        cicd_valid = validate_ci_cd_environment()
        is_valid = is_valid and cicd_valid
    
    # Final results
    print("\n" + "=" * 40)
    
    if is_valid:
        if validator.warnings:
            print("✅ Environment validation PASSED with warnings")
            if args.strict:
                print("❌ Strict mode enabled - failing due to warnings")
                sys.exit(1)
        else:
            print("✅ Environment validation PASSED")
    else:
        print("❌ Environment validation FAILED")
        print("\n💡 Fix the above errors before deploying to production")
        print("   See README.md for setup instructions")
        sys.exit(1)
    
    print("\n🚀 Ready for deployment!")


if __name__ == "__main__":
    main()