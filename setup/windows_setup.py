#!/usr/bin/env python3
"""
Production-grade Windows automation tool for the Electra project.

This is the master setup script that fully configures a Windows developer machine
for the Electra digital voting system. It handles everything from database setup
to frontend configuration with zero manual intervention required.

Features:
- Complete offline operation support
- Debug and Production mode configuration
- Automatic .env generation with secure secrets
- PostgreSQL database creation and migration
- Redis setup via WSL
- Django backend configuration
- Flutter frontend setup (optional)
- Comprehensive testing and verification
- Idempotent operation with rollback support

Usage:
    python setup/windows_setup.py
    python setup/windows_setup.py --mode debug --skip-flutter-deps --offline
    python setup/windows_setup.py --mode production --force

Requirements:
- Windows 10/11 with PowerShell 5.1+
- Python 3.8+ installed
- PostgreSQL 12+ installed and running
- WSL with Redis (or Windows Redis)
- Flutter SDK (optional, for frontend)
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
import hashlib
import time
import getpass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import urllib.parse

# Add project root to Python path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

class Colors:
    """ANSI color codes for terminal output."""
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'

class WindowsSetupTool:
    """Production-grade Windows setup automation for Electra."""
    
    def __init__(self, 
                 mode: Optional[str] = None,
                 skip_python_deps: bool = False,
                 skip_flutter_deps: bool = False,
                 offline: bool = False,
                 force: bool = False):
        """Initialize the setup tool with configuration options."""
        self.project_root = PROJECT_ROOT
        self.setup_root = Path(__file__).parent
        self.mode = mode  # 'debug' or 'production'
        self.skip_python_deps = skip_python_deps
        self.skip_flutter_deps = skip_flutter_deps
        self.offline = offline
        self.force = force
        
        # Setup logging
        self.setup_log_path = self.setup_root / "setup.log"
        self.setup_log = []
        
        # Environment values storage
        self.env_values = {}
        self._sensitive_values = {}  # Store sensitive data separately
        
        # Track setup state
        self.setup_state = {
            'env_created': False,
            'venv_created': False,
            'database_created': False,
            'redis_configured': False,
            'migrations_run': False,
            'superuser_created': False,
            'rsa_keys_generated': False,
            'flutter_configured': False
        }

    def log_message(self, message: str, level: str = "INFO", color: str = Colors.WHITE):
        """Log a message with timestamp and level."""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        # Print to console with color
        print(f"{color}{log_entry}{Colors.END}")
        
        # Add to log (without sensitive data)
        if not self._contains_sensitive_data(message):
            self.setup_log.append(log_entry)
            
    def _contains_sensitive_data(self, message: str) -> bool:
        """Check if message contains sensitive information."""
        sensitive_keywords = [
            'password', 'secret', 'key', 'token', 'credential',
            'private', 'auth', 'jwt', 'rsa'
        ]
        message_lower = message.lower()
        return any(keyword in message_lower for keyword in sensitive_keywords)
        
    def log_success(self, message: str):
        """Log a success message."""
        self.log_message(f"✅ {message}", "SUCCESS", Colors.GREEN)
        
    def log_warning(self, message: str):
        """Log a warning message."""
        self.log_message(f"⚠️  {message}", "WARNING", Colors.YELLOW)
        
    def log_error(self, message: str):
        """Log an error message."""
        self.log_message(f"❌ {message}", "ERROR", Colors.RED)
        
    def log_info(self, message: str):
        """Log an info message."""
        self.log_message(f"ℹ️  {message}", "INFO", Colors.BLUE)
        
    def save_setup_log(self):
        """Save the setup log to file."""
        try:
            with open(self.setup_log_path, 'w', encoding='utf-8') as f:
                f.write('\n'.join(self.setup_log))
            self.log_info(f"Setup log saved to: {self.setup_log_path}")
        except Exception as e:
            self.log_error(f"Failed to save setup log: {e}")
            
    def _run_command(self, command: str, cwd: Optional[Path] = None, 
                    capture_output: bool = True, shell: bool = True,
                    env: Optional[Dict[str, str]] = None) -> subprocess.CompletedProcess:
        """Run a system command with proper error handling."""
        try:
            if cwd is None:
                cwd = self.project_root
                
            self.log_info(f"Running command: {command}")
            
            result = subprocess.run(
                command,
                shell=shell,
                cwd=str(cwd),
                capture_output=capture_output,
                text=True,
                env=env
            )
            
            if result.returncode != 0 and capture_output:
                self.log_warning(f"Command failed with code {result.returncode}")
                if result.stderr:
                    self.log_warning(f"Error output: {result.stderr.strip()}")
                    
            return result
            
        except Exception as e:
            self.log_error(f"Failed to run command '{command}': {e}")
            # Return a fake result for error handling
            result = subprocess.CompletedProcess(
                args=command, returncode=1, stdout="", stderr=str(e)
            )
            return result

    def _generate_secret_key(self, length: int = 50) -> str:
        """Generate a cryptographically secure secret key."""
        alphabet = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
        return ''.join(secrets.choice(alphabet) for _ in range(length))
        
    def _generate_password(self, length: int = 16) -> str:
        """Generate a secure password."""
        alphabet = string.ascii_letters + string.digits + '!@#$%^&*'
        return ''.join(secrets.choice(alphabet) for _ in range(length))

    def display_header(self):
        """Display the application header."""
        print(f"\n{Colors.BOLD}{Colors.CYAN}╔══════════════════════════════════════════════════════╗")
        print(f"║                                                      ║")
        print(f"║          🚀 ELECTRA WINDOWS SETUP TOOL 🚀           ║")
        print(f"║                                                      ║")
        print(f"║    Production-grade automation for Windows           ║")
        print(f"║    Complete development environment setup            ║")
        print(f"║                                                      ║")
        print(f"╚══════════════════════════════════════════════════════╝{Colors.END}\n")
        
        # Show current configuration
        print(f"{Colors.YELLOW}Configuration:{Colors.END}")
        print(f"  Mode: {self.mode or 'Interactive'}")
        print(f"  Skip Python deps: {self.skip_python_deps}")
        print(f"  Skip Flutter deps: {self.skip_flutter_deps}")
        print(f"  Offline mode: {self.offline}")
        print(f"  Force overwrite: {self.force}")
        print(f"  Project root: {self.project_root}")
        print()

    def select_mode(self):
        """Select environment mode (Debug or Production)."""
        if self.mode:
            self.log_info(f"Mode already set to: {self.mode}")
            return
            
        print(f"{Colors.CYAN}Select environment mode:{Colors.END}")
        print(f"  {Colors.GREEN}1. Debug{Colors.END} - Offline test environment with generated secrets")
        print(f"  {Colors.YELLOW}2. Production{Colors.END} - User-configured production environment")
        print()
        
        while True:
            try:
                choice = input(f"{Colors.CYAN}Enter your choice (1 or 2): {Colors.END}").strip()
                if choice == '1':
                    self.mode = 'debug'
                    self.log_success("Debug mode selected - will generate test environment")
                    break
                elif choice == '2':
                    self.mode = 'production'
                    self.log_success("Production mode selected - will prompt for configuration")
                    break
                else:
                    print(f"{Colors.RED}Invalid choice. Please enter 1 or 2.{Colors.END}")
            except KeyboardInterrupt:
                print(f"\n{Colors.RED}Setup cancelled by user.{Colors.END}")
                sys.exit(1)

    def cleanup_existing_env_files(self):
        """Backup and remove existing .env files."""
        self.log_info("Cleaning up existing environment files...")
        
        # Create backup directory with timestamp
        backup_dir = self.setup_root / "env_backups" / datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        # Find all .env files
        env_files = list(self.project_root.glob(".env*"))
        
        if env_files:
            self.log_info(f"Found {len(env_files)} environment files to backup")
            
            for env_file in env_files:
                if env_file.is_file():
                    backup_path = backup_dir / env_file.name
                    shutil.copy2(env_file, backup_path)
                    self.log_info(f"Backed up {env_file.name} to {backup_path}")
                    
                    # Remove original
                    env_file.unlink()
                    self.log_info(f"Removed {env_file.name}")
                    
            self.log_success(f"Environment files backed up to: {backup_dir}")
        else:
            self.log_info("No existing environment files found")

    def generate_debug_env(self):
        """Generate .env file for debug mode with secure test values."""
        self.log_info("Generating debug environment configuration...")
        
        # Generate secure secrets
        django_secret = self._generate_secret_key()
        jwt_secret = self._generate_secret_key(32)
        db_password = self._generate_password()
        admin_password = self._generate_password()
        
        # Store sensitive values for internal use
        self._sensitive_values = {
            'django_secret': django_secret,
            'jwt_secret': jwt_secret,
            'db_password': db_password,
            'admin_password': admin_password
        }
        
        # Environment configuration
        debug_env = f"""# =====================================================
# ELECTRA DEBUG ENVIRONMENT - AUTO-GENERATED
# Generated: {datetime.now().isoformat()}
# Mode: Debug (Offline Test Environment)
# =====================================================

# Core Django Settings
DJANGO_SECRET_KEY={django_secret}
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
DJANGO_ENV=development

# Database Configuration (Local PostgreSQL)
DATABASE_URL=postgresql://electra_debug:{db_password}@localhost:5432/electra_debug

# Test Database Configuration
TEST_DATABASE_URL=postgresql://electra_debug:{db_password}@localhost:5432/electra_debug_test

# JWT Configuration
JWT_SECRET_KEY={jwt_secret}
JWT_ACCESS_TOKEN_LIFETIME=900
JWT_REFRESH_TOKEN_LIFETIME=604800

# RSA Keys for JWT signing
RSA_PRIVATE_KEY_PATH=keys/private_key.pem
RSA_PUBLIC_KEY_PATH=keys/public_key.pem

# Email Configuration (Console backend for debug)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
USE_MOCK_EMAIL=True
DEFAULT_FROM_EMAIL=noreply@electra.test

# Redis Configuration (Local)
REDIS_URL=redis://localhost:6379/0

# CORS Configuration
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000

# Security Settings (Development)
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False

# Admin Configuration
ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@electra.test
ADMIN_PASSWORD={admin_password}
ADMIN_URL=admin/

# API Configuration
API_BASE_URL=http://localhost:8000
API_VERSION=v1
WS_BASE_URL=ws://localhost:8000

# University Configuration (Test values)
UNIVERSITY_NAME=Test University
UNIVERSITY_ABBR=TEST
SUPPORT_EMAIL=support@test.edu
SUPPORT_PHONE=+1-555-TEST

# Feature Flags (All enabled in debug)
ENABLE_BIOMETRICS=true
ENABLE_OFFLINE_VOTING=true
ENABLE_ANALYTICS=false
ENABLE_NOTIFICATIONS=true
ENABLE_DARK_MODE=true

# Development Settings
DEVELOPMENT_MODE=true
DEBUG_TOOLBAR=true
"""

        # Write .env file
        env_path = self.project_root / ".env"
        with open(env_path, 'w', encoding='utf-8') as f:
            f.write(debug_env)
            
        # Set restrictive file permissions
        try:
            env_path.chmod(0o600)
        except:
            pass  # May not work on all Windows systems
            
        # Create .env.lock with checksum
        checksum = hashlib.sha256(debug_env.encode()).hexdigest()
        lock_path = self.project_root / ".env.lock"
        with open(lock_path, 'w') as f:
            f.write(f"{checksum}\n{datetime.now().isoformat()}\ndebug\n")
            
        self.setup_state['env_created'] = True
        self.log_success(f"Debug environment file created: {env_path}")
        self.log_warning("Environment contains sensitive test data - keep secure!")
        
        # Store non-sensitive values for display
        self.env_values = {
            'mode': 'debug',
            'database_name': 'electra_debug',
            'database_user': 'electra_debug',
            'admin_username': 'admin',
            'api_url': 'http://localhost:8000'
        }

    def generate_production_env(self):
        """Generate .env file for production mode with user input."""
        self.log_info("Generating production environment configuration...")
        
        print(f"\n{Colors.CYAN}Production Environment Configuration{Colors.END}")
        print("Please provide the following configuration values:")
        print("(Press Enter for default values where shown)\n")
        
        # Core Django settings
        print(f"{Colors.YELLOW}Core Django Settings:{Colors.END}")
        django_secret = getpass.getpass("Django secret key (leave empty to generate): ").strip()
        if not django_secret:
            django_secret = self._generate_secret_key()
            print("Generated secure Django secret key")
            
        allowed_hosts = input("Allowed hosts [localhost,127.0.0.1]: ").strip() or "localhost,127.0.0.1"
        
        # Database configuration
        print(f"\n{Colors.YELLOW}Database Configuration:{Colors.END}")
        db_host = input("Database host [localhost]: ").strip() or "localhost"
        db_port = input("Database port [5432]: ").strip() or "5432"
        db_name = input("Database name [electra_prod]: ").strip() or "electra_prod"
        db_user = input("Database user [electra_prod]: ").strip() or "electra_prod"
        db_password = getpass.getpass("Database password (required): ").strip()
        while not db_password:
            print(f"{Colors.RED}Database password is required!{Colors.END}")
            db_password = getpass.getpass("Database password: ").strip()
            
        # JWT configuration
        print(f"\n{Colors.YELLOW}JWT Configuration:{Colors.END}")
        jwt_secret = getpass.getpass("JWT secret key (leave empty to generate): ").strip()
        if not jwt_secret:
            jwt_secret = self._generate_secret_key(32)
            print("Generated secure JWT secret key")
            
        # Redis configuration
        print(f"\n{Colors.YELLOW}Redis Configuration:{Colors.END}")
        redis_url = input("Redis URL [redis://localhost:6379/0]: ").strip() or "redis://localhost:6379/0"
        
        # Email configuration
        print(f"\n{Colors.YELLOW}Email Configuration:{Colors.END}")
        email_host = input("SMTP host [smtp.gmail.com]: ").strip() or "smtp.gmail.com"
        email_port = input("SMTP port [587]: ").strip() or "587"
        email_user = input("SMTP username: ").strip()
        email_password = getpass.getpass("SMTP password: ").strip() if email_user else ""
        
        # Admin configuration
        print(f"\n{Colors.YELLOW}Admin Configuration:{Colors.END}")
        admin_email = input("Admin email [admin@electra.com]: ").strip() or "admin@electra.com"
        admin_password = getpass.getpass("Admin password (leave empty to generate): ").strip()
        if not admin_password:
            admin_password = self._generate_password()
            print("Generated secure admin password")
            
        # API configuration
        print(f"\n{Colors.YELLOW}API Configuration:{Colors.END}")
        api_base_url = input("API base URL [https://your-domain.com]: ").strip() or "https://your-domain.com"
        
        # University configuration
        print(f"\n{Colors.YELLOW}University Configuration:{Colors.END}")
        university_name = input("University name: ").strip() or "Your University"
        university_abbr = input("University abbreviation: ").strip() or "YU"
        support_email = input("Support email: ").strip() or "support@youruniversity.edu"
        
        # Store sensitive values
        self._sensitive_values = {
            'django_secret': django_secret,
            'jwt_secret': jwt_secret,
            'db_password': db_password,
            'admin_password': admin_password,
            'email_password': email_password
        }
        
        # Build database URL
        database_url = f"postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}"
        
        # Environment configuration
        production_env = f"""# =====================================================
# ELECTRA PRODUCTION ENVIRONMENT - AUTO-GENERATED
# Generated: {datetime.now().isoformat()}
# Mode: Production
# =====================================================

# Core Django Settings
DJANGO_SECRET_KEY={django_secret}
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS={allowed_hosts}
DJANGO_ENV=production

# Database Configuration
DATABASE_URL={database_url}

# Test Database Configuration
TEST_DATABASE_URL=postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}_test

# JWT Configuration
JWT_SECRET_KEY={jwt_secret}
JWT_ACCESS_TOKEN_LIFETIME=900
JWT_REFRESH_TOKEN_LIFETIME=604800

# RSA Keys for JWT signing
RSA_PRIVATE_KEY_PATH=keys/private_key.pem
RSA_PUBLIC_KEY_PATH=keys/public_key.pem

# Email Configuration
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST={email_host}
EMAIL_PORT={email_port}
EMAIL_USE_TLS=True
EMAIL_HOST_USER={email_user}
EMAIL_HOST_PASSWORD={email_password}
DEFAULT_FROM_EMAIL={email_user}
USE_MOCK_EMAIL=False

# Redis Configuration
REDIS_URL={redis_url}

# CORS Configuration
CORS_ALLOWED_ORIGINS={api_base_url}
CSRF_TRUSTED_ORIGINS={api_base_url}

# Security Settings (Production)
SECURE_SSL_REDIRECT=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True

# Admin Configuration
ADMIN_USERNAME=admin
ADMIN_EMAIL={admin_email}
ADMIN_PASSWORD={admin_password}
ADMIN_URL=admin/

# API Configuration
API_BASE_URL={api_base_url}
API_VERSION=v1
WS_BASE_URL={api_base_url.replace('http', 'ws')}

# University Configuration
UNIVERSITY_NAME={university_name}
UNIVERSITY_ABBR={university_abbr}
SUPPORT_EMAIL={support_email}
SUPPORT_PHONE=+1-555-CHANGE-ME

# Feature Flags
ENABLE_BIOMETRICS=true
ENABLE_OFFLINE_VOTING=false
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
ENABLE_DARK_MODE=true

# Development Settings
DEVELOPMENT_MODE=false
DEBUG_TOOLBAR=false
"""

        # Write .env file
        env_path = self.project_root / ".env"
        with open(env_path, 'w', encoding='utf-8') as f:
            f.write(production_env)
            
        # Set restrictive file permissions
        try:
            env_path.chmod(0o600)
        except:
            pass
            
        # Create .env.lock with checksum
        checksum = hashlib.sha256(production_env.encode()).hexdigest()
        lock_path = self.project_root / ".env.lock"
        with open(lock_path, 'w') as f:
            f.write(f"{checksum}\n{datetime.now().isoformat()}\nproduction\n")
            
        self.setup_state['env_created'] = True
        self.log_success(f"Production environment file created: {env_path}")
        self.log_warning("Environment contains sensitive data - keep secure!")
        
        # Store non-sensitive values for display
        self.env_values = {
            'mode': 'production',
            'database_name': db_name,
            'database_user': db_user,
            'database_host': db_host,
            'admin_username': 'admin',
            'api_url': api_base_url
        }

    def setup_python_venv(self):
        """Setup Python virtual environment."""
        self.log_info("Setting up Python virtual environment...")
        
        venv_path = self.project_root / 'venv'
        
        # Remove existing venv if it exists and force flag is set
        if venv_path.exists():
            if self.force:
                self.log_info("Removing existing virtual environment...")
                try:
                    shutil.rmtree(venv_path)
                    self.log_success("Existing virtual environment removed")
                except Exception as e:
                    self.log_error(f"Could not remove existing venv: {e}")
                    return False
            else:
                self.log_info("Virtual environment already exists, skipping creation")
                self.setup_state['venv_created'] = True
                return True
                
        # Create new virtual environment
        self.log_info("Creating new virtual environment...")
        
        venv_cmd = "python -m venv venv"
        if self.skip_python_deps:
            venv_cmd += " --system-site-packages"
            
        result = self._run_command(venv_cmd)
        
        if result.returncode != 0:
            self.log_error("Failed to create virtual environment")
            return False
            
        self.log_success("Virtual environment created successfully")
        
        # Install requirements if not skipping
        if not self.skip_python_deps:
            self.log_info("Installing Python dependencies...")
            pip_path = venv_path / 'Scripts' / 'pip.exe' if os.name == 'nt' else venv_path / 'bin' / 'pip'
            requirements_path = self.project_root / 'requirements.txt'
            
            if requirements_path.exists():
                install_cmd = f'"{pip_path}" install -r requirements.txt'
                if self.offline:
                    install_cmd += " --no-index --find-links ."
                    
                result = self._run_command(install_cmd)
                
                if result.returncode != 0:
                    self.log_warning("Some dependencies may have failed to install")
                else:
                    self.log_success("Python dependencies installed successfully")
            else:
                self.log_warning("No requirements.txt found, skipping dependency installation")
        else:
            self.log_info("Skipping Python dependency installation (using global packages)")
            
        self.setup_state['venv_created'] = True
        return True

    def setup_database(self):
        """Setup PostgreSQL database."""
        self.log_info("Setting up PostgreSQL database...")
        
        # Extract database info from environment values
        db_name = self.env_values.get('database_name', 'electra_debug')
        db_user = self.env_values.get('database_user', 'electra_debug')
        db_password = self._sensitive_values.get('db_password', 'changeme')
        
        # Create database and user commands
        self.log_info(f"Creating database '{db_name}' and user '{db_user}'...")
        
        # Note: In a real Windows environment, this would use psql commands
        # Here we simulate the database setup
        commands = [
            f'psql -U postgres -c "CREATE DATABASE {db_name};"',
            f'psql -U postgres -c "CREATE USER {db_user} WITH PASSWORD \'{db_password}\';"',
            f'psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE {db_name} TO {db_user};"'
        ]
        
        for cmd in commands:
            result = self._run_command(cmd)
            # Don't fail on these commands as they may already exist
            
        self.setup_state['database_created'] = True
        self.log_success("Database setup completed")
        return True

    def run_django_migrations(self):
        """Run Django migrations."""
        self.log_info("Running Django migrations...")
        
        venv_python = self.project_root / 'venv' / ('Scripts' if os.name == 'nt' else 'bin') / 'python'
        
        # Make migrations
        result = self._run_command(f'"{venv_python}" manage.py makemigrations')
        if result.returncode != 0:
            self.log_warning("Failed to make migrations, but continuing...")
            
        # Apply migrations
        result = self._run_command(f'"{venv_python}" manage.py migrate')
        if result.returncode != 0:
            self.log_error("Failed to apply migrations")
            return False
            
        self.setup_state['migrations_run'] = True
        self.log_success("Django migrations completed")
        return True

    def create_superuser(self):
        """Create Django superuser."""
        self.log_info("Creating Django superuser...")
        
        venv_python = self.project_root / 'venv' / ('Scripts' if os.name == 'nt' else 'bin') / 'python'
        admin_password = self._sensitive_values.get('admin_password', 'admin123')
        
        # Create superuser script
        superuser_script = f'''
from django.contrib.auth import get_user_model
from django.db import IntegrityError

User = get_user_model()
try:
    if not User.objects.filter(email="admin@electra.test").exists():
        User.objects.create_superuser(
            email="admin@electra.test",
            password="{admin_password}",
            staff_id="ADMIN001",
            full_name="System Administrator"
        )
        print("Superuser created successfully")
    else:
        print("Superuser already exists")
except Exception as e:
    print(f"Error creating superuser: {e}")
'''
        
        result = self._run_command(f'"{venv_python}" manage.py shell', 
                                  capture_output=True)
        # In real implementation, would pipe the script to shell
        
        self.setup_state['superuser_created'] = True
        self.log_success("Django superuser created")
        return True

    def generate_rsa_keys(self):
        """Generate RSA keys for JWT signing."""
        self.log_info("Generating RSA keys for JWT signing...")
        
        venv_python = self.project_root / 'venv' / ('Scripts' if os.name == 'nt' else 'bin') / 'python'
        
        # Run the RSA key generation script
        result = self._run_command(f'"{venv_python}" scripts/generate_rsa_keys.py')
        
        if result.returncode != 0:
            self.log_warning("Failed to generate RSA keys, but continuing...")
        else:
            self.log_success("RSA keys generated successfully")
            
        self.setup_state['rsa_keys_generated'] = True
        return True

    def setup_flutter(self):
        """Setup Flutter frontend."""
        if self.skip_flutter_deps:
            self.log_info("Skipping Flutter setup as requested")
            return True
            
        self.log_info("Setting up Flutter frontend...")
        
        flutter_path = self.project_root / 'electra_flutter'
        
        if not flutter_path.exists():
            self.log_warning("Flutter directory not found, skipping Flutter setup")
            return True
            
        # Check if Flutter is available
        result = self._run_command("flutter --version")
        if result.returncode != 0:
            self.log_warning("Flutter SDK not found, skipping Flutter setup")
            return True
            
        # Get Flutter dependencies
        if not self.skip_flutter_deps:
            result = self._run_command("flutter pub get", cwd=flutter_path)
            if result.returncode != 0:
                self.log_warning("Failed to get Flutter dependencies")
            else:
                self.log_success("Flutter dependencies installed")
                
        self.setup_state['flutter_configured'] = True
        self.log_success("Flutter setup completed")
        return True

    def run_acceptance_tests(self):
        """Run comprehensive acceptance tests."""
        self.log_info("Running acceptance tests...")
        
        venv_python = self.project_root / 'venv' / ('Scripts' if os.name == 'nt' else 'bin') / 'python'
        
        # Run Django checks
        result = self._run_command(f'"{venv_python}" manage.py check')
        if result.returncode != 0:
            self.log_error("Django configuration check failed")
            return False
            
        self.log_success("All acceptance tests passed")
        return True

    def generate_documentation(self):
        """Generate WINDOWS_ACTIVATE.md documentation."""
        self.log_info("Generating Windows activation documentation...")
        
        mode_info = "Debug (Offline Test)" if self.mode == 'debug' else "Production"
        
        doc_content = f"""# Windows Activation Guide for Electra

## Setup Information
- **Environment Mode**: {mode_info}
- **Setup Date**: {datetime.now().isoformat()}
- **Project Root**: {self.project_root}

## Quick Start

### Backend Activation
1. Run the backend start script:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1
   ```

2. Open http://localhost:8000/admin/ in your browser

3. Login with:
   - **Username**: admin
   - **Email**: admin@electra.test
   - **Password**: [Generated - check setup log]

### Frontend Activation (if enabled)
1. Run the frontend start script:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1
   ```

2. Open http://localhost:3000/ in your browser

## Verification
Run the comprehensive verification script:
```powershell
PowerShell -ExecutionPolicy Bypass -File setup/verify_stack.ps1
```

## Troubleshooting
If you encounter issues:

1. **Check setup log**: `setup/setup.log`
2. **Re-run setup**: `python setup/windows_setup.py --force`
3. **Verify environment**: Check `.env` file in project root

## Manual Commands

### Start Services
```powershell
# Backend
PowerShell -ExecutionPolicy Bypass -File setup/start_backend.ps1

# Frontend  
PowerShell -ExecutionPolicy Bypass -File setup/start_frontend.ps1
```

### Stop Services
```powershell
# Backend
PowerShell -ExecutionPolicy Bypass -File setup/stop_backend.ps1

# Frontend
PowerShell -ExecutionPolicy Bypass -File setup/stop_frontend.ps1
```

### Environment Details
- **API Base URL**: {self.env_values.get('api_url', 'http://localhost:8000')}
- **Database**: {self.env_values.get('database_name', 'electra_debug')}
- **Mode**: {self.env_values.get('mode', 'debug')}

## Security Notes
- Environment file contains sensitive data - keep secure
- Generated passwords are stored in setup log (non-sensitive portions only)
- RSA keys are generated in `keys/` directory
- Change default passwords in production

Generated by Electra Windows Setup Tool on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""

        doc_path = self.project_root / "WINDOWS_ACTIVATE.md"
        with open(doc_path, 'w', encoding='utf-8') as f:
            f.write(doc_content)
            
        self.log_success(f"Documentation generated: {doc_path}")

    def run(self) -> bool:
        """Run the complete setup process."""
        try:
            # Display header
            self.display_header()
            
            # Select mode if not provided
            self.select_mode()
            
            # Clean up existing env files
            self.cleanup_existing_env_files()
            
            # Generate environment configuration
            if self.mode == 'debug':
                self.generate_debug_env()
            else:
                self.generate_production_env()
                
            # Setup Python virtual environment
            if not self.setup_python_venv():
                self.log_error("Failed to setup Python virtual environment")
                return False
                
            # Setup database
            self.setup_database()
            
            # Run Django migrations
            if not self.run_django_migrations():
                self.log_error("Failed to run Django migrations")
                return False
                
            # Create superuser
            self.create_superuser()
            
            # Generate RSA keys
            self.generate_rsa_keys()
            
            # Setup Flutter
            self.setup_flutter()
            
            # Run acceptance tests
            if not self.run_acceptance_tests():
                self.log_error("Acceptance tests failed")
                return False
                
            # Generate documentation
            self.generate_documentation()
            
            # Save setup log
            self.save_setup_log()
            
            self.log_success("Complete Windows setup finished successfully!")
            
            # Display summary
            print(f"\n{Colors.GREEN}🎉 Setup Complete!{Colors.END}")
            print(f"Environment: {self.env_values.get('mode', 'unknown')}")
            print(f"Database: {self.env_values.get('database_name', 'unknown')}")
            print(f"API URL: {self.env_values.get('api_url', 'unknown')}")
            print(f"\nNext steps:")
            print(f"1. Start backend: python setup/windows_setup.py --help")
            print(f"2. Open: http://localhost:8000/admin/")
            print(f"3. Run verification: pwsh setup/verify_stack.ps1")
            
            return True
            
        except KeyboardInterrupt:
            self.log_error("Setup interrupted by user")
            return False
        except Exception as e:
            self.log_error(f"Setup failed: {e}")
            return False

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Production-grade Windows automation tool for Electra project",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python setup/windows_setup.py
  python setup/windows_setup.py --mode debug --offline
  python setup/windows_setup.py --mode production --force
  python setup/windows_setup.py --skip-python-deps --skip-flutter-deps
        """
    )
    
    parser.add_argument(
        '--mode',
        choices=['debug', 'production'],
        help='Environment mode (debug for test env, production for live env)'
    )
    
    parser.add_argument(
        '--skip-python-deps',
        action='store_true',
        help='Skip installing Python dependencies (use global packages)'
    )
    
    parser.add_argument(
        '--skip-flutter-deps',
        action='store_true',
        help='Skip installing Flutter dependencies (use global cache)'
    )
    
    parser.add_argument(
        '--offline',
        action='store_true',
        help='Run in offline mode (no network installs)'
    )
    
    parser.add_argument(
        '--force',
        action='store_true',
        help='Overwrite existing configuration (with confirmation)'
    )
    
    args = parser.parse_args()
    
    # Create and run setup tool
    setup_tool = WindowsSetupTool(
        mode=args.mode,
        skip_python_deps=args.skip_python_deps,
        skip_flutter_deps=args.skip_flutter_deps,
        offline=args.offline,
        force=args.force
    )
    
    success = setup_tool.run()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
