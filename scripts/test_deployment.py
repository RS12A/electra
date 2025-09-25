#!/usr/bin/env python3
"""
Deployment readiness testing script for Electra.

This script performs comprehensive deployment testing including:
- Environment validation
- Database connectivity
- Redis connectivity
- Email configuration
- RSA key validation
- Service health checks

Usage:
    python scripts/test_deployment.py
    python scripts/test_deployment.py --env-file .env.production
    python scripts/test_deployment.py --skip-services  # Skip service connectivity tests
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


def test_database_connectivity():
    """Test database connectivity."""
    print("\n🗄️  Testing database connectivity...")
    
    database_url = os.getenv('DATABASE_URL')
    if not database_url or database_url == 'your_KEY_goes_here':
        print("❌ DATABASE_URL not configured")
        return False
    
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        # Parse database URL
        parsed = urlparse(database_url)
        
        # Test connection
        conn = psycopg2.connect(
            host=parsed.hostname,
            port=parsed.port or 5432,
            user=parsed.username,
            password=parsed.password,
            database=parsed.path[1:] if parsed.path else 'postgres',
            connect_timeout=10
        )
        
        # Test basic query
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        
        print(f"✅ Database connection successful")
        print(f"   PostgreSQL version: {version.split(',')[0]}")
        return True
        
    except ImportError:
        print("⚠️  psycopg2 not installed - skipping database connectivity test")
        return True
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        return False


def test_redis_connectivity():
    """Test Redis connectivity."""
    print("\n🔴 Testing Redis connectivity...")
    
    redis_url = os.getenv('REDIS_URL')
    if not redis_url or redis_url == 'your_KEY_goes_here':
        print("❌ REDIS_URL not configured")
        return False
    
    try:
        import redis
        from urllib.parse import urlparse
        
        # Parse Redis URL
        parsed = urlparse(redis_url)
        
        # Create Redis client
        r = redis.Redis(
            host=parsed.hostname,
            port=parsed.port or 6379,
            password=parsed.password,
            socket_connect_timeout=10,
            socket_timeout=10
        )
        
        # Test connection
        r.ping()
        info = r.info()
        
        print(f"✅ Redis connection successful")
        print(f"   Redis version: {info.get('redis_version')}")
        print(f"   Memory usage: {info.get('used_memory_human')}")
        return True
        
    except ImportError:
        print("⚠️  redis package not installed - skipping Redis connectivity test")
        return True
    except Exception as e:
        print(f"❌ Redis connection failed: {e}")
        return False


def test_email_configuration():
    """Test email configuration."""
    print("\n📧 Testing email configuration...")
    
    email_host = os.getenv('EMAIL_HOST')
    email_user = os.getenv('EMAIL_HOST_USER')
    email_password = os.getenv('EMAIL_HOST_PASSWORD')
    
    if not all([email_host, email_user, email_password]):
        print("⚠️  Email configuration incomplete - skipping test")
        return True
    
    if any(val == 'your_KEY_goes_here' for val in [email_host, email_user, email_password]):
        print("❌ Email configuration contains placeholder values")
        return False
    
    try:
        import smtplib
        from email.mime.text import MIMEText
        
        # Test SMTP connection
        port = int(os.getenv('EMAIL_PORT', 587))
        server = smtplib.SMTP(email_host, port, timeout=30)
        
        if os.getenv('EMAIL_USE_TLS', 'True').lower() == 'true':
            server.starttls()
        
        server.login(email_user, email_password)
        server.quit()
        
        print(f"✅ Email configuration successful")
        print(f"   SMTP server: {email_host}:{port}")
        return True
        
    except Exception as e:
        print(f"❌ Email configuration test failed: {e}")
        return False


def test_jwt_keys():
    """Test JWT RSA keys."""
    print("\n🔐 Testing JWT RSA keys...")
    
    private_key_path = os.getenv('RSA_PRIVATE_KEY_PATH', 'keys/private_key.pem')
    public_key_path = os.getenv('RSA_PUBLIC_KEY_PATH', 'keys/public_key.pem')
    
    if not os.path.exists(private_key_path):
        print(f"❌ Private key not found: {private_key_path}")
        return False
    
    if not os.path.exists(public_key_path):
        print(f"❌ Public key not found: {public_key_path}")
        return False
    
    try:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import rsa
        import jwt
        
        # Load private key
        with open(private_key_path, 'rb') as f:
            private_key = serialization.load_pem_private_key(
                f.read(),
                password=None
            )
        
        # Load public key
        with open(public_key_path, 'rb') as f:
            public_key = serialization.load_pem_public_key(f.read())
        
        # Test key compatibility
        if not isinstance(private_key, rsa.RSAPrivateKey):
            print("❌ Private key is not RSA format")
            return False
        
        if not isinstance(public_key, rsa.RSAPublicKey):
            print("❌ Public key is not RSA format")
            return False
        
        # Test JWT signing and verification
        test_payload = {'test': 'data', 'user_id': 123}
        
        # Sign token with private key
        token = jwt.encode(test_payload, private_key, algorithm='RS256')
        
        # Verify token with public key
        decoded = jwt.decode(token, public_key, algorithms=['RS256'])
        
        if decoded != test_payload:
            print("❌ JWT token verification failed")
            return False
        
        # Check key size
        key_size = private_key.key_size
        
        print(f"✅ RSA keys validation successful")
        print(f"   Key size: {key_size} bits")
        print(f"   Private key: {private_key_path}")
        print(f"   Public key: {public_key_path}")
        
        if key_size < 2048:
            print("⚠️  Key size less than 2048 bits - consider upgrading")
        
        return True
        
    except ImportError as e:
        print(f"⚠️  Missing dependencies for JWT testing: {e}")
        return True
    except Exception as e:
        print(f"❌ JWT keys test failed: {e}")
        return False


def test_django_settings():
    """Test Django settings loading."""
    print("\n⚙️  Testing Django settings...")
    
    try:
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.prod')
        
        import django
        from django.conf import settings
        
        django.setup()
        
        # Test critical settings
        if not settings.SECRET_KEY:
            print("❌ Django SECRET_KEY not set")
            return False
        
        if not settings.ALLOWED_HOSTS:
            print("❌ Django ALLOWED_HOSTS not set")
            return False
        
        if settings.DEBUG:
            print("⚠️  Django DEBUG mode is enabled")
        
        print("✅ Django settings loaded successfully")
        return True
        
    except Exception as e:
        print(f"❌ Django settings test failed: {e}")
        return False


def test_docker_environment():
    """Test Docker environment readiness."""
    print("\n🐳 Testing Docker environment...")
    
    try:
        # Check if docker-compose.yml exists
        compose_file = PROJECT_ROOT / 'docker-compose.yml'
        if not compose_file.exists():
            print("❌ docker-compose.yml not found")
            return False
        
        # Test docker-compose config validation
        result = subprocess.run(
            ['docker-compose', 'config', '--quiet'],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            print(f"❌ Docker Compose configuration invalid: {result.stderr}")
            return False
        
        print("✅ Docker environment configuration valid")
        return True
        
    except FileNotFoundError:
        print("⚠️  Docker Compose not installed - skipping Docker test")
        return True
    except subprocess.TimeoutExpired:
        print("❌ Docker Compose validation timed out")
        return False
    except Exception as e:
        print(f"❌ Docker environment test failed: {e}")
        return False


def main():
    """Main deployment testing function."""
    parser = argparse.ArgumentParser(
        description="Test Electra deployment readiness",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--env-file',
        type=str,
        help='Environment file to load'
    )
    
    parser.add_argument(
        '--skip-services',
        action='store_true',
        help='Skip service connectivity tests'
    )
    
    parser.add_argument(
        '--skip-django',
        action='store_true',
        help='Skip Django settings test'
    )
    
    parser.add_argument(
        '--skip-docker',
        action='store_true',
        help='Skip Docker environment test'
    )
    
    args = parser.parse_args()
    
    print("🧪 Electra Deployment Readiness Test")
    print("=" * 50)
    
    # Load environment file if specified
    if args.env_file:
        if not os.path.exists(args.env_file):
            print(f"❌ Environment file not found: {args.env_file}")
            sys.exit(1)
        
        print(f"📄 Loading environment from: {args.env_file}")
        try:
            from dotenv import load_dotenv
            load_dotenv(args.env_file)
        except ImportError:
            print("⚠️  python-dotenv not available - manual loading required")
    
    # Run environment validation first
    try:
        from electra_server.settings.env_validation import validate_environment
        print("\n🔍 Running environment validation...")
        # Run validation but don't exit on failure
        is_valid = validate_environment(fail_on_error=False)
        if not is_valid:
            print("❌ Environment validation failed")
    except Exception as e:
        print(f"⚠️  Environment validation error: {e}")
    
    # Run tests
    tests_passed = 0
    tests_total = 0
    
    if not args.skip_services:
        tests_total += 3
        if test_database_connectivity():
            tests_passed += 1
        if test_redis_connectivity():
            tests_passed += 1
        if test_email_configuration():
            tests_passed += 1
    
    tests_total += 1
    if test_jwt_keys():
        tests_passed += 1
    
    if not args.skip_django:
        tests_total += 1
        if test_django_settings():
            tests_passed += 1
    
    if not args.skip_docker:
        tests_total += 1
        if test_docker_environment():
            tests_passed += 1
    
    # Final results
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {tests_passed}/{tests_total} tests passed")
    
    if tests_passed == tests_total:
        print("✅ All deployment readiness tests passed!")
        print("🚀 System is ready for deployment")
        return True
    else:
        failed = tests_total - tests_passed
        print(f"❌ {failed} test(s) failed")
        print("💡 Fix the above issues before deploying")
        return False


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)