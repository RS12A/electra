#!/usr/bin/env python3
"""
Production Readiness Verification Script for Electra E-Voting System

This script performs comprehensive checks across all components to ensure 
the system is ready for production deployment.
"""
import os
import sys
import json
import subprocess
import requests
from pathlib import Path
from typing import Dict, List, Tuple, Any
import argparse


class ProductionReadinessChecker:
    """Comprehensive production readiness checker."""
    
    def __init__(self):
        self.errors: List[str] = []
        self.warnings: List[str] = []
        self.passed_checks: List[str] = []
        self.base_dir = Path(__file__).parent.parent
        
    def log_error(self, message: str) -> None:
        """Log an error that blocks production deployment."""
        self.errors.append(message)
        print(f"❌ ERROR: {message}")
    
    def log_warning(self, message: str) -> None:
        """Log a warning that should be addressed but doesn't block deployment."""
        self.warnings.append(message)
        print(f"⚠️  WARNING: {message}")
    
    def log_pass(self, message: str) -> None:
        """Log a successful check."""
        self.passed_checks.append(message)
        print(f"✅ PASS: {message}")
    
    def check_environment_config(self) -> None:
        """Check environment configuration."""
        print("\n🔧 Checking Environment Configuration...")
        
        # Required environment variables
        required_vars = [
            'DJANGO_SECRET_KEY',
            'DATABASE_URL',
            'JWT_SECRET_KEY',
            'RSA_PRIVATE_KEY_PATH',
            'RSA_PUBLIC_KEY_PATH',
            'EMAIL_HOST',
            'EMAIL_HOST_USER',
            'EMAIL_HOST_PASSWORD',
            'REDIS_URL'
        ]
        
        missing_vars = []
        for var in required_vars:
            value = os.getenv(var)
            if not value or value in ['your_KEY_goes_here', 'CHANGE_ME', 'CONFIGURE_ME']:
                missing_vars.append(var)
        
        if missing_vars:
            self.log_error(f"Missing or placeholder environment variables: {', '.join(missing_vars)}")
        else:
            self.log_pass("All required environment variables are configured")
    
    def check_rsa_keys(self) -> None:
        """Check RSA key configuration."""
        print("\n🔐 Checking RSA Keys...")
        
        private_key_path = os.getenv('RSA_PRIVATE_KEY_PATH', 'keys/private_key.pem')
        public_key_path = os.getenv('RSA_PUBLIC_KEY_PATH', 'keys/public_key.pem')
        
        # Check if paths are absolute, make them relative to base_dir if not
        if not os.path.isabs(private_key_path):
            private_key_path = self.base_dir / private_key_path
        if not os.path.isabs(public_key_path):
            public_key_path = self.base_dir / public_key_path
        
        # Check private key
        if not os.path.exists(private_key_path):
            self.log_error(f"Private RSA key not found: {private_key_path}")
        else:
            # Check permissions
            stat_info = os.stat(private_key_path)
            permissions = oct(stat_info.st_mode)[-3:]
            if permissions not in ['600', '400']:
                self.log_warning(f"Private key has insecure permissions: {permissions}")
            else:
                self.log_pass("Private RSA key found with secure permissions")
        
        # Check public key
        if not os.path.exists(public_key_path):
            self.log_error(f"Public RSA key not found: {public_key_path}")
        else:
            self.log_pass("Public RSA key found")
    
    def check_security_settings(self) -> None:
        """Check security settings."""
        print("\n🔒 Checking Security Settings...")
        
        # Check debug mode
        debug = os.getenv('DJANGO_DEBUG', 'False').lower()
        if debug in ['true', '1', 'yes']:
            self.log_error("DEBUG mode is enabled - must be False for production")
        else:
            self.log_pass("DEBUG mode is disabled")
        
        # Check SSL redirect
        ssl_redirect = os.getenv('SECURE_SSL_REDIRECT', 'False').lower()
        if ssl_redirect not in ['true', '1', 'yes']:
            self.log_warning("SSL redirect is disabled - enable for production")
        else:
            self.log_pass("SSL redirect is enabled")
        
        # Check allowed hosts
        allowed_hosts = os.getenv('DJANGO_ALLOWED_HOSTS', '')
        if not allowed_hosts or 'localhost' in allowed_hosts or '127.0.0.1' in allowed_hosts:
            self.log_warning("ALLOWED_HOSTS contains localhost - ensure production domains are configured")
        else:
            self.log_pass("ALLOWED_HOSTS configured for production")
    
    def check_database_config(self) -> None:
        """Check database configuration."""
        print("\n🗄️  Checking Database Configuration...")
        
        database_url = os.getenv('DATABASE_URL', '')
        if not database_url.startswith('postgresql://'):
            self.log_error("DATABASE_URL must use PostgreSQL for production")
        else:
            self.log_pass("Database configured with PostgreSQL")
        
        # Check if database URL contains default values
        if 'localhost' in database_url or 'your_KEY_goes_here' in database_url:
            self.log_warning("Database URL contains development values")
    
    def check_monitoring_config(self) -> None:
        """Check monitoring and observability configuration."""
        print("\n📊 Checking Monitoring Configuration...")
        
        # Check Sentry
        sentry_dsn = os.getenv('SENTRY_DSN', '')
        if not sentry_dsn or sentry_dsn == 'your_KEY_goes_here':
            self.log_warning("Sentry error tracking not configured")
        else:
            self.log_pass("Sentry error tracking configured")
        
        # Check Prometheus
        metrics_enabled = os.getenv('ELECTRA_METRICS_ENABLED', 'False').lower()
        if metrics_enabled in ['true', '1', 'yes']:
            self.log_pass("Prometheus metrics enabled")
        else:
            self.log_warning("Prometheus metrics disabled")
    
    def check_flutter_config(self) -> None:
        """Check Flutter frontend configuration."""
        print("\n📱 Checking Flutter Configuration...")
        
        flutter_dir = self.base_dir / 'electra_flutter'
        if not flutter_dir.exists():
            self.log_error("Flutter directory not found")
            return
        
        # Check pubspec.yaml
        pubspec_file = flutter_dir / 'pubspec.yaml'
        if not pubspec_file.exists():
            self.log_error("Flutter pubspec.yaml not found")
        else:
            self.log_pass("Flutter pubspec.yaml found")
        
        # Check if Flutter can be analyzed
        try:
            result = subprocess.run(
                ['flutter', 'analyze', '--no-pub'],
                cwd=flutter_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode == 0:
                self.log_pass("Flutter analysis passed")
            else:
                self.log_warning("Flutter analysis found issues")
        except (subprocess.TimeoutExpired, FileNotFoundError):
            self.log_warning("Flutter not available or analysis timed out")
    
    def check_ci_cd_config(self) -> None:
        """Check CI/CD configuration."""
        print("\n🔄 Checking CI/CD Configuration...")
        
        github_workflows = self.base_dir / '.github' / 'workflows'
        if not github_workflows.exists():
            self.log_error("GitHub workflows directory not found")
            return
        
        required_workflows = ['ci.yml', 'cd.yml', 'security-scan.yml']
        for workflow in required_workflows:
            workflow_file = github_workflows / workflow
            if not workflow_file.exists():
                self.log_error(f"Required workflow not found: {workflow}")
            else:
                self.log_pass(f"Workflow found: {workflow}")
    
    def check_docker_config(self) -> None:
        """Check Docker configuration."""
        print("\n🐳 Checking Docker Configuration...")
        
        dockerfile = self.base_dir / 'Dockerfile'
        if not dockerfile.exists():
            self.log_error("Dockerfile not found")
        else:
            self.log_pass("Dockerfile found")
        
        docker_compose = self.base_dir / 'docker-compose.yml'
        if not docker_compose.exists():
            self.log_error("docker-compose.yml not found")
        else:
            self.log_pass("docker-compose.yml found")
    
    def check_backup_config(self) -> None:
        """Check backup and disaster recovery configuration."""
        print("\n💾 Checking Backup Configuration...")
        
        backup_script = self.base_dir / 'scripts' / 'db_backup.sh'
        if not backup_script.exists():
            self.log_warning("Database backup script not found")
        else:
            self.log_pass("Database backup script found")
        
        # Check backup encryption key
        backup_key = os.getenv('BACKUP_ENCRYPTION_KEY', '')
        if not backup_key or backup_key == 'your_KEY_goes_here':
            self.log_warning("Backup encryption key not configured")
        else:
            self.log_pass("Backup encryption key configured")
    
    def check_ssl_config(self) -> None:
        """Check SSL/TLS configuration."""
        print("\n🔐 Checking SSL/TLS Configuration...")
        
        ssl_cert_path = os.getenv('SSL_CERT_PATH', '')
        ssl_key_path = os.getenv('SSL_KEY_PATH', '')
        
        if ssl_cert_path and os.path.exists(ssl_cert_path):
            self.log_pass("SSL certificate file found")
        else:
            self.log_warning("SSL certificate not configured - ensure proper SSL setup")
        
        if ssl_key_path and os.path.exists(ssl_key_path):
            self.log_pass("SSL private key file found")
        else:
            self.log_warning("SSL private key not configured")
    
    def check_test_coverage(self) -> None:
        """Check test coverage and quality."""
        print("\n🧪 Checking Test Coverage...")
        
        # Check backend tests
        backend_tests = list(self.base_dir.glob('**/test*.py'))
        if backend_tests:
            self.log_pass(f"Found {len(backend_tests)} backend test files")
        else:
            self.log_warning("No backend test files found")
        
        # Check Flutter tests
        flutter_tests = list((self.base_dir / 'electra_flutter').glob('test/**/*.dart'))
        if flutter_tests:
            self.log_pass(f"Found {len(flutter_tests)} Flutter test files")
        else:
            self.log_warning("No Flutter test files found")
    
    def check_documentation(self) -> None:
        """Check documentation completeness."""
        print("\n📚 Checking Documentation...")
        
        required_docs = ['README.md', 'security.md']
        for doc in required_docs:
            doc_file = self.base_dir / doc
            if not doc_file.exists():
                self.log_warning(f"Required documentation not found: {doc}")
            else:
                self.log_pass(f"Documentation found: {doc}")
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive readiness report."""
        total_checks = len(self.passed_checks) + len(self.warnings) + len(self.errors)
        
        report = {
            'timestamp': str(timezone.now()),
            'summary': {
                'total_checks': total_checks,
                'passed': len(self.passed_checks),
                'warnings': len(self.warnings),
                'errors': len(self.errors),
                'production_ready': len(self.errors) == 0
            },
            'passed_checks': self.passed_checks,
            'warnings': self.warnings,
            'errors': self.errors,
            'recommendations': []
        }
        
        # Add recommendations based on findings
        if self.errors:
            report['recommendations'].append("Fix all error conditions before deploying to production")
        
        if self.warnings:
            report['recommendations'].append("Address warning conditions for optimal production setup")
        
        if len(self.errors) == 0:
            report['recommendations'].append("System appears ready for production deployment")
        
        return report
    
    def run_all_checks(self) -> None:
        """Run all production readiness checks."""
        print("🚀 Electra Production Readiness Check")
        print("=" * 50)
        
        # Run all checks
        self.check_environment_config()
        self.check_rsa_keys()
        self.check_security_settings()
        self.check_database_config()
        self.check_monitoring_config()
        self.check_flutter_config()
        self.check_ci_cd_config()
        self.check_docker_config()
        self.check_backup_config()
        self.check_ssl_config()
        self.check_test_coverage()
        self.check_documentation()
        
        # Generate and display report
        report = self.generate_report()
        
        print("\n" + "=" * 50)
        print("📊 SUMMARY REPORT")
        print("=" * 50)
        print(f"Total Checks: {report['summary']['total_checks']}")
        print(f"✅ Passed: {report['summary']['passed']}")
        print(f"⚠️  Warnings: {report['summary']['warnings']}")
        print(f"❌ Errors: {report['summary']['errors']}")
        
        if report['summary']['errors'] == 0:
            print("\n🎉 PRODUCTION READY!")
            print("All critical checks passed. System is ready for production deployment.")
        else:
            print("\n❌ NOT PRODUCTION READY")
            print("Fix error conditions before deploying to production.")
        
        if report['warnings']:
            print("\n⚠️  Please address the warnings for optimal production setup.")
        
        # Save report to file
        report_file = self.base_dir / 'production_readiness_report.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        print(f"\n📄 Detailed report saved to: {report_file}")
        
        return len(self.errors) == 0


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description='Electra Production Readiness Checker')
    parser.add_argument('--strict', action='store_true', help='Treat warnings as errors')
    args = parser.parse_args()
    
    checker = ProductionReadinessChecker()
    is_ready = checker.run_all_checks()
    
    if args.strict and checker.warnings:
        print("\n❌ STRICT MODE: Treating warnings as errors")
        is_ready = False
    
    sys.exit(0 if is_ready else 1)


if __name__ == '__main__':
    # Import django timezone if available
    try:
        import django
        from django.utils import timezone
    except ImportError:
        import datetime
        class timezone:
            @staticmethod
            def now():
                return datetime.datetime.now()
    
    main()