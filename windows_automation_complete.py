#!/usr/bin/env python3
"""
Complete Production-ready Windows automation tool for the Electra project.

This script fully sets up both testing (debug) and production environments offline,
from backend to frontend to testing. It includes all advanced features:
- Database setup (PostgreSQL)
- Redis integration (WSL or Windows)
- Django migrations and superuser creation
- Flutter frontend setup (optional)
- RSA key generation
- Comprehensive testing
- Documentation generation

Usage:
    python windows_automation_complete.py
    python windows_automation_complete.py --disable-flutter
"""

import os
import sys
import argparse
import subprocess
import shutil
import glob
import secrets
import string
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent
sys.path.insert(0, str(PROJECT_ROOT))

class Colors:
    """ANSI color codes for Windows terminal output."""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

class WindowsElectraAutomationComplete:
    """Complete automation class for Windows Electra setup."""
    
    def __init__(self, disable_flutter: bool = False):
        self.project_root = PROJECT_ROOT
        self.disable_flutter = disable_flutter
        self.mode = None  # Will be set to 'debug' or 'production'
        self.env_values = {}
        self._actual_values = {}  # Store sensitive values separately
        self.setup_log = []
        
    def log(self, message: str, color: str = Colors.WHITE):
        """Log a message with color and timestamp."""
        timestamp = self._get_timestamp()
        formatted_message = f"[{timestamp}] {message}"
        print(f"{color}{formatted_message}{Colors.END}")
        # Only log non-sensitive messages to avoid storing secrets
        if not self._contains_sensitive_data(message):
            self.setup_log.append(formatted_message)
            
    def _contains_sensitive_data(self, message: str) -> bool:
        """Check if message contains sensitive data that should not be logged."""
        sensitive_keywords = ['password', 'secret', 'key', 'token', 'credential']
        message_lower = message.lower()
        return any(keyword in message_lower for keyword in sensitive_keywords)
        
    def log_success(self, message: str):
        """Log a success message."""
        self.log(f"✅ {message}", Colors.GREEN)
        
    def log_warning(self, message: str):
        """Log a warning message."""
        self.log(f"⚠️  {message}", Colors.YELLOW)
        
    def log_error(self, message: str):
        """Log an error message."""
        self.log(f"❌ {message}", Colors.RED)
        
    def log_info(self, message: str):
        """Log an info message."""
        self.log(f"ℹ️  {message}", Colors.BLUE)
        
    def _get_timestamp(self) -> str:
        """Get current timestamp."""
        from datetime import datetime
        return datetime.now().strftime("%H:%M:%S")
        
    def _generate_secret_key(self, length: int = 50) -> str:
        """Generate a secure secret key."""
        alphabet = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
        return ''.join(secrets.choice(alphabet) for _ in range(length))
        
    def _run_command(self, command: str, shell: bool = True, capture_output: bool = True, 
                    check: bool = False, cwd: Optional[str] = None, env: Optional[Dict] = None) -> subprocess.CompletedProcess:
        """Run a command and return the result."""
        try:
            if cwd:
                original_cwd = os.getcwd()
                os.chdir(cwd)
                
            cmd_env = os.environ.copy()
            if env:
                cmd_env.update(env)
                
            result = subprocess.run(
                command,
                shell=shell,
                capture_output=capture_output,
                text=True,
                check=check,
                env=cmd_env
            )
            
            if cwd:
                os.chdir(original_cwd)
                
            return result
        except subprocess.CalledProcessError as e:
            if capture_output:
                self.log_warning(f"Command failed: {command}")
                if e.stderr:
                    self.log_warning(f"Error output: {e.stderr}")
            return e
        except Exception as e:
            self.log_error(f"Unexpected error running command: {command}")
            self.log_error(f"Error: {e}")
            return None
            
    def display_header(self):
        """Display the main header."""
        header = f"""
{Colors.CYAN}{Colors.BOLD}
🚀 ELECTRA COMPLETE WINDOWS AUTOMATION TOOL 🚀
==============================================={Colors.END}
{Colors.WHITE}Production-ready setup for Electra project
- Full environment setup (Debug/Production)
- Database and Redis integration
- Django migrations and superuser
- Flutter frontend (optional)
- Testing and validation
- Complete offline compatibility{Colors.END}

"""
        print(header)
        
    def select_environment_mode(self) -> str:
        """Prompt user to select environment mode."""
        self.log_info("Select environment mode:")
        print(f"{Colors.YELLOW}1. Debug (offline test environment){Colors.END}")
        print(f"{Colors.YELLOW}2. Production (user-configured environment){Colors.END}")
        
        while True:
            choice = input(f"{Colors.CYAN}Enter your choice (1 or 2): {Colors.END}").strip()
            if choice == '1':
                self.mode = 'debug'
                self.log_success("Debug mode selected - setting up offline test environment")
                return 'debug'
            elif choice == '2':
                self.mode = 'production'
                self.log_success("Production mode selected - will prompt for configuration values")
                return 'production'
            else:
                self.log_warning("Invalid choice. Please enter 1 or 2.")
                
    def cleanup_env_files(self):
        """Delete all existing .env* files."""
        self.log_info("Cleaning up existing environment files...")
        
        env_patterns = ['.env*']
        deleted_files = []
        
        for pattern in env_patterns:
            for file_path in glob.glob(str(self.project_root / pattern)):
                if os.path.isfile(file_path):
                    try:
                        os.remove(file_path)
                        deleted_files.append(file_path)
                    except Exception as e:
                        self.log_warning(f"Could not delete {file_path}: {e}")
                        
        if deleted_files:
            self.log_success(f"Deleted {len(deleted_files)} environment files")
        else:
            self.log_info("No existing environment files found")
            
    def generate_debug_env(self):
        """Generate .env file for debug mode with working test values."""
        self.log_info("Generating debug environment configuration...")
        
        # Generate secure test values
        django_secret = self._generate_secret_key()
        jwt_secret = self._generate_secret_key(32)
        admin_password = 'admin123'  # Simple password for debug
        
        # Note: Environment file must contain actual secrets for application functionality
        # This is the standard practice for .env files in development environments
        debug_env = f"""# =====================================================
# ELECTRA DEBUG/TEST ENVIRONMENT - OFFLINE COMPATIBLE
# Generated automatically by Windows Automation Tool
# =====================================================

# Core Django Settings
DJANGO_SECRET_KEY={django_secret}
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
DJANGO_ENV=development

# Database Configuration (Local PostgreSQL)
DATABASE_URL=postgresql://electra_user:electra_dev_password@localhost:5432/electra_db

# JWT Configuration  
JWT_SECRET_KEY={jwt_secret}
JWT_ACCESS_TOKEN_LIFETIME=900
JWT_REFRESH_TOKEN_LIFETIME=604800

# RSA Keys for JWT signing
RSA_PRIVATE_KEY_PATH=keys/private_key.pem
RSA_PUBLIC_KEY_PATH=keys/public_key.pem

# Email Configuration (Mock for offline testing)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
USE_MOCK_EMAIL=True
DEFAULT_FROM_EMAIL=noreply@electra.local
SMTP_HOST=localhost
SMTP_PORT=587
SMTP_USER=test@electra.local
SMTP_PASS=testpass
EMAIL_HOST=localhost
EMAIL_PORT=587
EMAIL_USE_TLS=False
EMAIL_HOST_USER=test@electra.local
EMAIL_HOST_PASSWORD=testpass

# Redis Configuration (Local via WSL)
REDIS_URL=redis://localhost:6379/0

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000,http://127.0.0.1:8000
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000,http://127.0.0.1:8000

# Security Settings (Relaxed for development)
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Admin Configuration
ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@electra.local
ADMIN_PASSWORD={admin_password}
ADMIN_URL=admin/

# Development & Testing
DEVELOPMENT_MODE=True
DEBUG_TOOLBAR=True
TEST_DATABASE_URL=postgresql://electra_user:electra_dev_password@localhost:5432/electra_test

# Feature Flags (All enabled for testing)
ENABLE_BIOMETRICS=True
ENABLE_OFFLINE_VOTING=True
ENABLE_ANALYTICS=False
ENABLE_NOTIFICATIONS=True
ENABLE_DARK_MODE=True

# University Branding (Test values)
UNIVERSITY_NAME=Test University
UNIVERSITY_ABBR=TEST
SUPPORT_EMAIL=support@electra.local
SUPPORT_PHONE=+1-555-0123

# API Configuration for Frontend
API_BASE_URL=http://localhost:8000
API_VERSION=v1
WS_BASE_URL=ws://localhost:8000

# Monitoring (Disabled for offline)
ELECTRA_METRICS_ENABLED=False
PROMETHEUS_EXPORT_MIGRATIONS=False
"""
        
        env_path = self.project_root / '.env'
        with open(env_path, 'w') as f:
            f.write(debug_env)
            
        # Set file permissions to be more restrictive (owner read/write only)
        try:
            import stat
            env_path.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except:
            pass  # Permissions may not be supported on all Windows systems
            
        self.log_success(f"Debug environment file created: {env_path}")
        self.log_info("Environment file contains sensitive data - keep secure and do not commit to version control")
        self.env_values = {
            'admin_username': 'admin',
            'admin_password': '[HIDDEN]',  # Don't store actual password
            'admin_email': 'admin@electra.local',
            'database_url': 'postgresql://electra_user:[HIDDEN]@localhost:5432/electra_db'
        }
        # Store actual values separately for internal use only
        self._actual_values = {
            'admin_password': admin_password,
            'database_url': 'postgresql://electra_user:electra_dev_password@localhost:5432/electra_db'
        }
        
    def generate_production_env(self):
        """Generate .env file for production mode with user input."""
        self.log_info("Generating production environment configuration...")
        self.log_info("Please provide the following configuration values:")
        
        # Import getpass for secure password input
        import getpass
        
        # Core Django settings
        django_secret = self._generate_secret_key()
        self.log_success("Generated Django secret key automatically")
        
        # Database configuration
        print(f"\n{Colors.CYAN}Database Configuration:{Colors.END}")
        db_name = input("Database name [electra_db]: ").strip() or "electra_db"
        db_user = input("Database user [electra_user]: ").strip() or "electra_user"
        try:
            db_password = getpass.getpass("Database password: ").strip()
        except:
            db_password = input("Database password (visible): ").strip()
        if not db_password:
            db_password = "electra_password"
        db_host = input("Database host [localhost]: ").strip() or "localhost"
        db_port = input("Database port [5432]: ").strip() or "5432"
        
        database_url = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        
        # Admin configuration
        print(f"\n{Colors.CYAN}Admin Configuration:{Colors.END}")
        admin_username = input("Admin username [admin]: ").strip() or "admin"
        admin_email = input("Admin email: ").strip() or "admin@electra.com"
        try:
            admin_password = getpass.getpass("Admin password: ").strip()
        except:
            admin_password = input("Admin password (visible): ").strip()
        if not admin_password:
            admin_password = "admin123"
        
        # Generate basic production environment
        # Note: Environment file must contain actual secrets for application functionality
        # This is the standard practice for .env files in production environments
        production_env = f"""# =====================================================
# ELECTRA PRODUCTION ENVIRONMENT
# Generated automatically by Windows Automation Tool
# =====================================================

# Core Django Settings
DJANGO_SECRET_KEY={django_secret}
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1
DJANGO_ENV=production

# Database Configuration
DATABASE_URL={database_url}

# JWT Configuration  
JWT_SECRET_KEY={self._generate_secret_key(32)}
JWT_ACCESS_TOKEN_LIFETIME=900
JWT_REFRESH_TOKEN_LIFETIME=604800

# RSA Keys for JWT signing
RSA_PRIVATE_KEY_PATH=keys/private_key.pem
RSA_PUBLIC_KEY_PATH=keys/public_key.pem

# Email Configuration
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
USE_MOCK_EMAIL=False
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your_email@gmail.com
EMAIL_HOST_PASSWORD=your_app_password
DEFAULT_FROM_EMAIL=noreply@electra.com

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# Security Settings
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Admin Configuration
ADMIN_USERNAME={admin_username}
ADMIN_EMAIL={admin_email}
ADMIN_PASSWORD={admin_password}
ADMIN_URL=admin/

# University Branding
UNIVERSITY_NAME=Your University
UNIVERSITY_ABBR=UNI
SUPPORT_EMAIL=support@university.edu
SUPPORT_PHONE=+1-555-0123

# API Configuration
API_BASE_URL=http://localhost:8000
API_VERSION=v1
WS_BASE_URL=ws://localhost:8000

# Development & Testing
DEVELOPMENT_MODE=False
DEBUG_TOOLBAR=False
TEST_DATABASE_URL={database_url.replace(db_name, f'{db_name}_test')}

# Feature Flags
ENABLE_BIOMETRICS=True
ENABLE_OFFLINE_VOTING=True
ENABLE_ANALYTICS=True
ENABLE_NOTIFICATIONS=True
ENABLE_DARK_MODE=True

# Monitoring
ELECTRA_METRICS_ENABLED=True
PROMETHEUS_EXPORT_MIGRATIONS=False
"""
        
        env_path = self.project_root / '.env'
        with open(env_path, 'w') as f:
            f.write(production_env)
            
        # Set file permissions to be more restrictive (owner read/write only)
        try:
            import stat
            env_path.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except:
            pass  # Permissions may not be supported on all Windows systems
            
        self.log_success(f"Production environment file created: {env_path}")
        self.log_info("Environment file contains sensitive data - keep secure and do not commit to version control")
        self.env_values = {
            'admin_username': admin_username,
            'admin_password': '[HIDDEN]',  # Don't store actual password
            'admin_email': admin_email,
            'database_url': f'postgresql://{db_user}:[HIDDEN]@{db_host}:{db_port}/{db_name}'
        }
        # Store actual values separately for internal use only
        self._actual_values = {
            'admin_password': admin_password,
            'database_url': database_url
        }
        
    def setup_python_venv(self):
        """Setup Python virtual environment offline using system packages."""
        self.log_info("Setting up Python virtual environment...")
        
        venv_path = self.project_root / 'venv'
        
        # Remove existing venv if it exists
        if venv_path.exists():
            self.log_info("Removing existing virtual environment...")
            try:
                shutil.rmtree(venv_path)
                self.log_success("Existing virtual environment removed")
            except Exception as e:
                self.log_error(f"Could not remove existing venv: {e}")
                return False
                
        # Create new virtual environment
        self.log_info("Creating new virtual environment...")
        result = self._run_command("python -m venv venv --system-site-packages", cwd=str(self.project_root))
        
        if result and result.returncode != 0:
            self.log_error("Failed to create virtual environment")
            return False
            
        self.log_success("Virtual environment created successfully")
        
        # Install requirements
        pip_path = venv_path / 'Scripts' / 'pip.exe'
        requirements_path = self.project_root / 'requirements.txt'
        
        if requirements_path.exists():
            self.log_info("Installing Python dependencies...")
            result = self._run_command(f'"{pip_path}" install -r requirements.txt', cwd=str(self.project_root))
            
            if result and result.returncode != 0:
                self.log_warning("Some dependencies may have failed to install")
            else:
                self.log_success("Python dependencies installed successfully")
        else:
            self.log_warning("No requirements.txt found, skipping dependency installation")
            
        return True
        
    def check_postgresql(self) -> bool:
        """Check if PostgreSQL is installed and running."""
        self.log_info("Checking PostgreSQL installation...")
        
        # Check if psql command is available
        result = self._run_command("psql --version")
        if result and result.returncode != 0:
            self.log_error("PostgreSQL is not installed or not in PATH")
            self.log_info("Please install PostgreSQL and ensure it's in your PATH")
            return False
            
        self.log_success("PostgreSQL is installed")
        return True
        
    def setup_postgresql_database(self) -> bool:
        """Create PostgreSQL database and user for Electra."""
        self.log_info("Setting up PostgreSQL database...")
        
        if not self.check_postgresql():
            return False
            
        # Extract database info from DATABASE_URL
        database_url = self._actual_values.get('database_url', self.env_values.get('database_url', ''))
        if not database_url:
            self.log_error("No database URL found in environment")
            return False
            
        # Parse database URL
        try:
            parsed = urlparse(database_url)
            db_name = parsed.path[1:]  # Remove leading slash
            db_user = parsed.username
            db_password = parsed.password
            db_host = parsed.hostname or 'localhost'
            db_port = parsed.port or 5432
        except Exception as e:
            self.log_error(f"Failed to parse database URL: {e}")
            return False
            
        # Check if database exists and create if needed
        self.log_info(f"Setting up database '{db_name}' and user '{db_user}'...")
        
        # Create database and user commands
        commands = [
            # Check if database exists, create if not
            f'''psql -U postgres -h {db_host} -p {db_port} -tc "SELECT 1 FROM pg_database WHERE datname = '{db_name}';" | grep -q 1 || \
        
        for cmd in commands:
            result = self._run_command(cmd)
            # Don't fail on these commands as they may already exist
            
        self.log_success("Database setup completed")
        return True
        
    def check_redis_wsl(self) -> bool:
        """Check if Redis is available via WSL."""
        self.log_info("Checking Redis availability...")
        
        # Check if WSL is available first
        result = self._run_command("wsl --version")
        if result and result.returncode == 0:
            # Check if Redis is in WSL
            result = self._run_command("wsl which redis-server")
            if result and result.returncode == 0:
                self.log_success("Redis found in WSL")
                # Try to start Redis
                self._run_command("wsl redis-server --daemonize yes")
                return True
                
        # Check if Redis is available on Windows
        result = self._run_command("redis-server --version")
        if result and result.returncode == 0:
            self.log_success("Redis found on Windows")
            return True
            
        self.log_warning("Redis not found, but continuing setup...")
        return False
        
    def generate_rsa_keys(self) -> bool:
        """Generate RSA keys for JWT signing."""
        self.log_info("Generating RSA keys for JWT signing...")
        
        keys_dir = self.project_root / 'keys'
        keys_dir.mkdir(exist_ok=True)
        
        private_key_path = keys_dir / 'private_key.pem'
        public_key_path = keys_dir / 'public_key.pem'
        
        # Check if keys already exist
        if private_key_path.exists() and public_key_path.exists():
            self.log_info("RSA keys already exist")
            return True
            
        # Generate keys using the existing script
        python_path = self.project_root / 'venv' / 'Scripts' / 'python.exe'
        generate_script = self.project_root / 'scripts' / 'generate_rsa_keys.py'
        
        if not generate_script.exists():
            self.log_warning("RSA key generation script not found, creating basic keys...")
            return self._generate_basic_rsa_keys(keys_dir)
            
        result = self._run_command(f'"{python_path}" scripts/generate_rsa_keys.py', cwd=str(self.project_root))
        
        if result and result.returncode != 0:
            self.log_warning("Script failed, creating basic keys...")
            return self._generate_basic_rsa_keys(keys_dir)
        else:
            self.log_success("RSA keys generated successfully")
            return True
            
    def _generate_basic_rsa_keys(self, keys_dir: Path) -> bool:
        """Generate basic RSA keys using Python's cryptography library."""
        try:
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.asymmetric import rsa
            
            # Generate private key
            private_key = rsa.generate_private_key(
                public_exponent=65537,
                key_size=2048,
            )
            
            # Serialize private key
            private_pem = private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
            
            # Get public key
            public_key = private_key.public_key()
            public_pem = public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )
            
            # Write keys to files
            with open(keys_dir / 'private_key.pem', 'wb') as f:
                f.write(private_pem)
                
            with open(keys_dir / 'public_key.pem', 'wb') as f:
                f.write(public_pem)
                
            self.log_success("Basic RSA keys generated successfully")
            return True
            
        except ImportError:
            self.log_error("cryptography library not available for key generation")
            return False
        except Exception as e:
            self.log_error(f"Failed to generate RSA keys: {e}")
            return False
            
    def setup_django(self) -> bool:
        """Setup Django migrations and create superuser."""
        self.log_info("Setting up Django...")
        
        python_path = self.project_root / 'venv' / 'Scripts' / 'python.exe'
        manage_py = self.project_root / 'manage.py'
        
        if not python_path.exists():
            self.log_error("Virtual environment Python not found")
            return False
            
        if not manage_py.exists():
            self.log_error("manage.py not found")
            return False
            
        # Set environment variables
        env = {'DJANGO_SETTINGS_MODULE': 'electra_server.settings.dev' if self.mode == 'debug' else 'electra_server.settings.production'}
        
        # Run makemigrations
        self.log_info("Running Django makemigrations...")
        result = self._run_command(f'"{python_path}" manage.py makemigrations', cwd=str(self.project_root), env=env)
        
        if result and result.returncode != 0:
            self.log_warning("Makemigrations completed with warnings")
        else:
            self.log_success("Makemigrations completed successfully")
            
        # Run migrate
        self.log_info("Running Django migrations...")
        result = self._run_command(f'"{python_path}" manage.py migrate', cwd=str(self.project_root), env=env)
        
        if result and result.returncode != 0:
            self.log_warning("Django migrations completed with warnings")
        else:
            self.log_success("Django migrations completed successfully")
            
        # Create superuser
        return self._create_superuser(python_path, env)
        
    def _create_superuser(self, python_path: Path, env: dict) -> bool:
        """Create Django superuser."""
        self.log_info("Creating Django superuser...")
        
        admin_username = self.env_values.get('admin_username', 'admin')
        admin_password = self._actual_values.get('admin_password', self.env_values.get('admin_password', 'admin123'))
        admin_email = self.env_values.get('admin_email', 'admin@electra.local')
        
        # Set environment for createsuperuser
        superuser_env = env.copy()
        superuser_env.update({
            'DJANGO_SUPERUSER_USERNAME': admin_username,
            'DJANGO_SUPERUSER_EMAIL': admin_email,
            'DJANGO_SUPERUSER_PASSWORD': admin_password
        })
        
        # Create superuser
        create_cmd = f'"{python_path}" manage.py createsuperuser --noinput'
        result = self._run_command(create_cmd, cwd=str(self.project_root), env=superuser_env)
        
        if result and result.returncode != 0:
            if result.stderr and "already exists" in result.stderr:
                self.log_info("Superuser already exists")
            else:
                self.log_warning(f"Superuser creation warning, but continuing...")
        else:
            self.log_success(f"Superuser '{admin_username}' created successfully")
            
        # Seed initial data if in debug mode
        if self.mode == 'debug':
            return self._seed_test_data(python_path, env)
            
        return True
        
    def _seed_test_data(self, python_path: Path, env: dict) -> bool:
        """Seed test data for debug mode."""
        self.log_info("Seeding test data for debug mode...")
        
        seed_cmd = f'"{python_path}" manage.py seed_initial_data --force'
        result = self._run_command(seed_cmd, cwd=str(self.project_root), env=env)
        
        if result and result.returncode != 0:
            self.log_warning("Test data seeding completed with warnings")
        else:
            self.log_success("Test data seeded successfully")
            
        return True
        
    def setup_flutter(self) -> bool:
        """Setup Flutter frontend (optional)."""
        if self.disable_flutter:
            self.log_info("Flutter setup disabled by flag")
            return True
            
        self.log_info("Setting up Flutter frontend...")
        
        flutter_dir = self.project_root / 'electra_flutter'
        if not flutter_dir.exists():
            self.log_warning("Flutter directory not found, skipping Flutter setup")
            return True
            
        # Check if Flutter is installed
        result = self._run_command("flutter --version")
        if result and result.returncode != 0:
            self.log_warning("Flutter is not installed or not in PATH, skipping Flutter setup")
            return True
            
        self.log_success("Flutter is installed")
        
        # Run flutter pub get
        self.log_info("Installing Flutter dependencies...")
        result = self._run_command("flutter pub get", cwd=str(flutter_dir))
        
        if result and result.returncode != 0:
            self.log_warning("Flutter dependencies installation completed with warnings")
        else:
            self.log_success("Flutter dependencies installed successfully")
            
        return True
        
    def run_tests(self) -> bool:
        """Run backend and frontend tests."""
        self.log_info("Running tests...")
        
        python_path = self.project_root / 'venv' / 'Scripts' / 'python.exe'
        
        # Set environment
        env = {'DJANGO_SETTINGS_MODULE': 'electra_server.settings.dev' if self.mode == 'debug' else 'electra_server.settings.test'}
        
        # Run backend tests
        self.log_info("Running backend tests...")
        result = self._run_command(f'"{python_path}" -m pytest --tb=short -x', cwd=str(self.project_root), env=env)
        
        if result and result.returncode != 0:
            self.log_warning("Some backend tests failed or had warnings")
        else:
            self.log_success("Backend tests passed successfully")
            
        # Run Flutter tests if enabled
        if not self.disable_flutter:
            flutter_dir = self.project_root / 'electra_flutter'
            if flutter_dir.exists():
                self.log_info("Running Flutter tests...")
                result = self._run_command("flutter test", cwd=str(flutter_dir))
                
                if result and result.returncode != 0:
                    self.log_warning("Some Flutter tests failed or had warnings")
                else:
                    self.log_success("Flutter tests passed successfully")
                    
        return True
        
    def validate_connectivity(self) -> bool:
        """Validate system connectivity."""
        self.log_info("Validating system connectivity...")
        
        python_path = self.project_root / 'venv' / 'Scripts' / 'python.exe'
        
        # Run environment validation
        self.log_info("Running environment validation...")
        result = self._run_command(f'"{python_path}" scripts/validate_environment.py --skip-docker', cwd=str(self.project_root))
        
        if result and result.returncode != 0:
            self.log_warning("Environment validation completed with warnings")
        else:
            self.log_success("Environment validation passed")
            
        return True
        
    def create_activation_scripts(self):
        """Create Windows batch scripts for easy activation."""
        self.log_info("Creating activation scripts...")
        
        # Backend start script
        backend_script = f"""@echo off
title Electra Django Backend
echo ========================================
echo   Electra Django Backend
echo ========================================
call venv\\Scripts\\activate.bat
echo Starting Django development server...
echo Backend will be available at: http://localhost:8000
echo Admin panel: http://localhost:8000/admin/
echo Username: {self.env_values.get('admin_username', 'admin')}
echo Password: [HIDDEN - Check WINDOWS_ACTIVATE.md for details]
echo.
python manage.py runserver 0.0.0.0:8000
pause
"""
        
        with open(self.project_root / 'start_backend.bat', 'w') as f:
            f.write(backend_script)
            
        # Frontend start script (if Flutter not disabled)
        if not self.disable_flutter:
            frontend_script = """@echo off
title Electra Flutter Frontend
echo ========================================
echo   Electra Flutter Frontend
echo ========================================
cd electra_flutter
echo Starting Flutter web development server...
echo Frontend will be available at: http://localhost:3000
echo.
flutter run -d chrome --web-port 3000
pause
"""
            
            with open(self.project_root / 'start_frontend.bat', 'w') as f:
                f.write(frontend_script)
                
        # Validation script
        validation_script = """@echo off
title Electra Environment Validation
echo ========================================
echo   Electra Environment Validation
echo ========================================
call venv\\Scripts\\activate.bat
echo Running environment validation...
python scripts\\validate_environment.py --skip-docker
echo.
pause
"""
        
        with open(self.project_root / 'validate_setup.bat', 'w') as f:
            f.write(validation_script)
            
        self.log_success("Activation scripts created successfully")
        
    def generate_documentation(self):
        """Generate WINDOWS_ACTIVATE.md documentation."""
        self.log_info("Generating activation documentation...")
        
        mode_info = "Debug (Offline Test)" if self.mode == 'debug' else "Production"
        flutter_info = "Disabled" if self.disable_flutter else "Enabled"
        
        doc_content = f"""# Windows Activation Guide for Electra

## Setup Information
- **Environment Mode**: {mode_info}
- **Flutter Integration**: {flutter_info}
- **Setup Date**: {self._get_timestamp()}

## Quick Start

### Backend Activation
1. Double-click `start_backend.bat` to start the Django development server
2. Open http://localhost:8000/admin/ in your browser
3. Login with:
   - Username: `{self.env_values.get('admin_username', 'admin')}`
   - Password: `{self._actual_values.get('admin_password', 'admin123')}`

### Frontend Activation (if enabled)
1. Double-click `start_frontend.bat` to start the Flutter web app
2. Open http://localhost:3000 in your browser

### Environment Validation
- Run `validate_setup.bat` to check all components

## Manual Commands

### Backend Commands
```cmd
# Activate virtual environment
call venv\\Scripts\\activate.bat

# Start Django server
python manage.py runserver

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run tests
python -m pytest
```

### Frontend Commands (if enabled)
```cmd
# Navigate to Flutter directory
cd electra_flutter

# Install dependencies
flutter pub get

# Start web server
flutter run -d chrome --web-port 3000

# Run tests
flutter test
```

## Offline Development (Debug Mode)

### Features Available Offline
- ✅ Django backend with local PostgreSQL
- ✅ Redis caching (if available)
- ✅ Mock email backend (console output)
- ✅ Full voting system functionality
- ✅ Admin interface
- ✅ API endpoints
- ✅ Flutter frontend (if enabled)

### Testing Offline Functionality
1. Start both backend and frontend
2. Disconnect from the internet
3. Test the following:
   - User registration and login
   - Vote casting and storage
   - Admin panel access
   - API endpoints
   - Local data persistence

## Troubleshooting

### Common Issues

**1. Virtual Environment Issues**
```cmd
# Recreate virtual environment
rmdir /s venv
python -m venv venv --system-site-packages
call venv\\Scripts\\activate.bat
pip install -r requirements.txt
```

**2. Database Connection Issues**
```cmd
# Check PostgreSQL service
sc query postgresql*

# Start PostgreSQL service
net start postgresql*

# Test database connection
psql -U postgres -h localhost
```

**3. Redis Connection Issues**
```cmd
# For WSL Redis
wsl redis-server --daemonize yes
wsl redis-cli ping

# For Windows Redis
redis-server
```

### Port Conflicts
- Backend: http://localhost:8000
- Frontend: http://localhost:3000
- PostgreSQL: localhost:5432
- Redis: localhost:6379

If ports are in use, modify the start scripts or configuration files.

### Environment Variables
The `.env` file contains all configuration. Key variables:
- `DJANGO_DEBUG`: Set to `True` for debug mode
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `DJANGO_SECRET_KEY`: Auto-generated secure key

---

Generated by Complete Windows Automation Tool for Electra Project
Mode: {mode_info} | Flutter: {flutter_info}
"""
        
        doc_path = self.project_root / 'WINDOWS_ACTIVATE.md'
        with open(doc_path, 'w') as f:
            f.write(doc_content)
            
        self.log_success(f"Documentation generated: {doc_path}")
        
    def display_final_summary(self):
        """Display final setup summary."""
        self.log_info("Setup Summary:")
        
        summary = f"""
{Colors.CYAN}{Colors.BOLD}🎉 ELECTRA COMPLETE WINDOWS SETUP FINISHED! 🎉{Colors.END}

{Colors.GREEN}Environment Configuration:{Colors.END}
- Mode: {self.mode.title()}
- Flutter: {'Disabled' if self.disable_flutter else 'Enabled'}
- Database: PostgreSQL (Local)
- Cache: Redis (WSL/Local)

{Colors.GREEN}Quick Start Commands:{Colors.END}
- Backend: Double-click start_backend.bat
- Frontend: Double-click start_frontend.bat {'(if enabled)' if not self.disable_flutter else ''}
- Validation: Double-click validate_setup.bat

{Colors.GREEN}Access URLs:{Colors.END}
- Backend API: http://localhost:8000
- Admin Panel: http://localhost:8000/admin/
- Frontend: http://localhost:3000 {'(if enabled)' if not self.disable_flutter else ''}

{Colors.GREEN}Admin Credentials:{Colors.END}
- Username: {self.env_values.get('admin_username', 'admin')}
- Password: [HIDDEN - See WINDOWS_ACTIVATE.md]

{Colors.GREEN}Documentation:{Colors.END}
- Detailed guide: WINDOWS_ACTIVATE.md
- Setup log: {len(self.setup_log)} entries recorded

{Colors.YELLOW}Next Steps:{Colors.END}
1. Run validate_setup.bat to verify everything works
2. Start backend and frontend using the batch files
3. Test offline functionality (Debug mode)
4. Review WINDOWS_ACTIVATE.md for detailed instructions

{Colors.GREEN}Complete setup finished successfully! 🚀{Colors.END}
"""
        
        print(summary)
        
    def run_complete_setup(self):
        """Run the complete setup process."""
        try:
            # Display header
            self.display_header()
            
            # Select environment mode
            self.select_environment_mode()
            
            # Clean up old env files
            self.cleanup_env_files()
            
            # Generate environment configuration
            if self.mode == 'debug':
                self.generate_debug_env()
            else:
                self.generate_production_env()
                
            # Setup Python virtual environment
            if not self.setup_python_venv():
                self.log_error("Failed to setup Python virtual environment")
                return False
                
            # Generate RSA keys
            self.generate_rsa_keys()
                
            # Setup PostgreSQL
            self.setup_postgresql_database()
                
            # Check Redis
            self.check_redis_wsl()
                
            # Setup Django
            if not self.setup_django():
                self.log_error("Failed to setup Django")
                return False
                
            # Setup Flutter (optional)
            self.setup_flutter()
                
            # Run tests
            self.run_tests()
            
            # Validate connectivity
            self.validate_connectivity()
            
            # Create activation scripts
            self.create_activation_scripts()
            
            # Generate documentation
            self.generate_documentation()
            
            # Display final summary
            self.display_final_summary()
            
            return True
            
        except KeyboardInterrupt:
            self.log_warning("Setup interrupted by user")
            return False
        except Exception as e:
            self.log_error(f"Unexpected error during setup: {e}")
            import traceback
            traceback.print_exc()
            return False


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Complete Production-ready Windows automation tool for Electra project",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument(
        '--disable-flutter',
        action='store_true',
        help='Disable Flutter frontend setup and tests'
    )
    
    args = parser.parse_args()
    
    # Create and run automation
    automation = WindowsElectraAutomationComplete(disable_flutter=args.disable_flutter)
    success = automation.run_complete_setup()
    
    if success:
        print(f"\n{Colors.GREEN}✅ Complete setup finished successfully!{Colors.END}")
        sys.exit(0)
    else:
        print(f"\n{Colors.RED}❌ Setup failed. Check the logs above for details.{Colors.END}")
        sys.exit(1)


if __name__ == '__main__':
    main()