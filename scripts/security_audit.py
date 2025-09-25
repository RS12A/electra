#!/usr/bin/env python3
"""
Security Audit Script for Electra E-Voting System

Performs comprehensive security checks including:
- Code analysis for security vulnerabilities
- Configuration validation
- Dependency security scanning  
- File permission validation
- Secret detection
"""
import os
import sys
import subprocess
import json
from pathlib import Path
from typing import List, Dict, Any


class SecurityAuditor:
    """Comprehensive security auditor for Electra system."""
    
    def __init__(self):
        self.base_dir = Path(__file__).parent.parent
        self.vulnerabilities = []
        self.warnings = []
        self.recommendations = []
    
    def log_vulnerability(self, severity: str, message: str, file_path: str = "") -> None:
        """Log a security vulnerability."""
        self.vulnerabilities.append({
            'severity': severity,
            'message': message,
            'file': file_path,
            'category': 'security'
        })
        print(f"🚨 {severity.upper()}: {message}")
        if file_path:
            print(f"   File: {file_path}")
    
    def log_warning(self, message: str, file_path: str = "") -> None:
        """Log a security warning."""
        self.warnings.append({
            'message': message,
            'file': file_path,
            'category': 'warning'
        })
        print(f"⚠️  WARNING: {message}")
        if file_path:
            print(f"   File: {file_path}")
    
    def audit_file_permissions(self) -> None:
        """Audit file permissions for security issues."""
        print("\n🔒 Auditing File Permissions...")
        
        # Check RSA keys
        private_key = self.base_dir / 'keys' / 'private_key.pem'
        if private_key.exists():
            stat_info = os.stat(private_key)
            permissions = oct(stat_info.st_mode)[-3:]
            if permissions not in ['600', '400']:
                self.log_vulnerability(
                    'high',
                    f'Private RSA key has insecure permissions: {permissions}',
                    str(private_key)
                )
        
        # Check .env files
        env_files = list(self.base_dir.glob('.env*'))
        for env_file in env_files:
            if env_file.name != '.env.example':
                stat_info = os.stat(env_file)
                permissions = oct(stat_info.st_mode)[-3:]
                if permissions not in ['600', '400']:
                    self.log_warning(
                        f'Environment file has permissive permissions: {permissions}',
                        str(env_file)
                    )
    
    def audit_secrets_exposure(self) -> None:
        """Audit for exposed secrets and sensitive data."""
        print("\n🔍 Auditing for Exposed Secrets...")
        
        # Patterns to search for
        secret_patterns = [
            r'password\s*=\s*["\'][^"\']{8,}["\']',
            r'secret\s*=\s*["\'][^"\']{16,}["\']',
            r'api_key\s*=\s*["\'][^"\']{16,}["\']',
            r'access_token\s*=\s*["\'][^"\']{20,}["\']',
        ]
        
        # Check Python files
        for py_file in self.base_dir.rglob('*.py'):
            if 'venv' in str(py_file) or '__pycache__' in str(py_file):
                continue
                
            try:
                content = py_file.read_text()
                
                # Check for hardcoded secrets
                if 'password' in content.lower() and '=' in content:
                    if 'your_KEY_goes_here' not in content and 'CHANGE_ME' not in content:
                        # This might be a hardcoded password
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if 'password' in line.lower() and '=' in line and not line.strip().startswith('#'):
                                self.log_warning(
                                    f'Potential hardcoded password on line {i+1}',
                                    str(py_file)
                                )
                
                # Check for debug flags
                if 'DEBUG = True' in content:
                    self.log_vulnerability(
                        'medium',
                        'DEBUG mode enabled',
                        str(py_file)
                    )
                
            except UnicodeDecodeError:
                continue
    
    def audit_django_security(self) -> None:
        """Audit Django-specific security configurations."""
        print("\n🛡️ Auditing Django Security Settings...")
        
        # Check settings files
        settings_dir = self.base_dir / 'electra_server' / 'settings'
        if settings_dir.exists():
            for settings_file in settings_dir.glob('*.py'):
                try:
                    content = settings_file.read_text()
                    
                    # Check for security misconfigurations
                    if 'ALLOWED_HOSTS = []' in content:
                        self.log_vulnerability(
                            'high',
                            'ALLOWED_HOSTS is empty - allows any host',
                            str(settings_file)
                        )
                    
                    if 'SECRET_KEY =' in content and len(content.split('SECRET_KEY =')[1].split('\n')[0]) < 50:
                        self.log_warning(
                            'Django SECRET_KEY appears to be too short',
                            str(settings_file)
                        )
                    
                    if 'SECURE_SSL_REDIRECT = False' in content:
                        self.log_warning(
                            'SSL redirect is disabled',
                            str(settings_file)
                        )
                    
                except UnicodeDecodeError:
                    continue
    
    def audit_dependencies(self) -> None:
        """Audit dependencies for known vulnerabilities."""
        print("\n📦 Auditing Dependencies...")
        
        # Check Python dependencies
        requirements_file = self.base_dir / 'requirements.txt'
        if requirements_file.exists():
            try:
                # Try to run safety check if available
                result = subprocess.run(
                    ['safety', 'check', '-r', str(requirements_file)],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                if result.returncode != 0 and 'No known security vulnerabilities found' not in result.stdout:
                    self.log_warning('Python dependencies may have security vulnerabilities')
            except (subprocess.TimeoutExpired, FileNotFoundError):
                self.log_warning('Could not check Python dependencies with safety')
        
        # Check Flutter dependencies
        flutter_pubspec = self.base_dir / 'electra_flutter' / 'pubspec.yaml'
        if flutter_pubspec.exists():
            try:
                result = subprocess.run(
                    ['flutter', 'pub', 'audit'],
                    cwd=self.base_dir / 'electra_flutter',
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                if result.returncode != 0:
                    self.log_warning('Flutter dependencies may have security vulnerabilities')
            except (subprocess.TimeoutExpired, FileNotFoundError):
                self.log_warning('Could not check Flutter dependencies')
    
    def audit_docker_security(self) -> None:
        """Audit Docker configuration for security issues."""
        print("\n🐳 Auditing Docker Security...")
        
        dockerfile = self.base_dir / 'Dockerfile'
        if dockerfile.exists():
            content = dockerfile.read_text()
            
            # Check for security best practices
            if 'USER root' in content:
                self.log_vulnerability(
                    'medium',
                    'Docker container runs as root user',
                    str(dockerfile)
                )
            
            if 'ADD' in content and 'http' in content:
                self.log_warning(
                    'Using ADD with HTTP URLs can be insecure',
                    str(dockerfile)
                )
            
            if '--privileged' in content:
                self.log_vulnerability(
                    'high',
                    'Docker container runs in privileged mode',
                    str(dockerfile)
                )
    
    def audit_web_security(self) -> None:
        """Audit web security configurations."""
        print("\n🌐 Auditing Web Security...")
        
        # Check nginx configuration
        nginx_configs = list(self.base_dir.rglob('*.conf')) + list(self.base_dir.rglob('nginx.conf'))
        for config in nginx_configs:
            if config.exists():
                try:
                    content = config.read_text()
                    
                    # Check for security headers
                    security_headers = [
                        'X-Frame-Options',
                        'X-Content-Type-Options',
                        'X-XSS-Protection',
                        'Strict-Transport-Security'
                    ]
                    
                    missing_headers = []
                    for header in security_headers:
                        if header not in content:
                            missing_headers.append(header)
                    
                    if missing_headers:
                        self.log_warning(
                            f'Missing security headers: {", ".join(missing_headers)}',
                            str(config)
                        )
                
                except UnicodeDecodeError:
                    continue
    
    def generate_recommendations(self) -> None:
        """Generate security recommendations based on findings."""
        print("\n💡 Generating Security Recommendations...")
        
        self.recommendations = [
            "Run regular security scans using automated tools",
            "Implement Web Application Firewall (WAF) for production",
            "Set up intrusion detection system (IDS)",
            "Enable database query logging for audit trails",
            "Implement rate limiting on all API endpoints",
            "Set up automated backup verification",
            "Configure log monitoring and alerting",
            "Implement security incident response procedures",
            "Regular security training for development team",
            "Periodic penetration testing by third-party security experts"
        ]
        
        # Add specific recommendations based on findings
        if any(v['severity'] == 'high' for v in self.vulnerabilities):
            self.recommendations.insert(0, "URGENT: Fix high-severity vulnerabilities before production deployment")
        
        if self.vulnerabilities:
            self.recommendations.append("Schedule regular security audits to catch vulnerabilities early")
    
    def generate_report(self) -> Dict[str, Any]:
        """Generate comprehensive security audit report."""
        return {
            'audit_timestamp': str(Path(__file__).stat().st_mtime),
            'summary': {
                'high_severity_vulnerabilities': len([v for v in self.vulnerabilities if v['severity'] == 'high']),
                'medium_severity_vulnerabilities': len([v for v in self.vulnerabilities if v['severity'] == 'medium']),
                'low_severity_vulnerabilities': len([v for v in self.vulnerabilities if v['severity'] == 'low']),
                'warnings': len(self.warnings),
                'security_score': self._calculate_security_score()
            },
            'vulnerabilities': self.vulnerabilities,
            'warnings': self.warnings,
            'recommendations': self.recommendations,
            'audit_categories': [
                'File Permissions',
                'Secret Exposure',
                'Django Security',
                'Dependencies',
                'Docker Security',
                'Web Security'
            ]
        }
    
    def _calculate_security_score(self) -> int:
        """Calculate security score based on findings."""
        score = 100
        
        # Deduct points for vulnerabilities
        for vuln in self.vulnerabilities:
            if vuln['severity'] == 'high':
                score -= 20
            elif vuln['severity'] == 'medium':
                score -= 10
            elif vuln['severity'] == 'low':
                score -= 5
        
        # Deduct points for warnings
        score -= len(self.warnings) * 2
        
        return max(0, score)
    
    def run_full_audit(self) -> None:
        """Run complete security audit."""
        print("🔒 Electra Security Audit")
        print("=" * 50)
        
        self.audit_file_permissions()
        self.audit_secrets_exposure()
        self.audit_django_security()
        self.audit_dependencies()
        self.audit_docker_security()
        self.audit_web_security()
        self.generate_recommendations()
        
        # Generate and save report
        report = self.generate_report()
        
        print("\n" + "=" * 50)
        print("🛡️ SECURITY AUDIT SUMMARY")
        print("=" * 50)
        
        summary = report['summary']
        print(f"Security Score: {summary['security_score']}/100")
        print(f"High Severity Vulnerabilities: {summary['high_severity_vulnerabilities']}")
        print(f"Medium Severity Vulnerabilities: {summary['medium_severity_vulnerabilities']}")
        print(f"Low Severity Vulnerabilities: {summary['low_severity_vulnerabilities']}")
        print(f"Warnings: {summary['warnings']}")
        
        if summary['security_score'] >= 90:
            print("\n✅ EXCELLENT SECURITY POSTURE")
        elif summary['security_score'] >= 80:
            print("\n✅ GOOD SECURITY POSTURE")
        elif summary['security_score'] >= 70:
            print("\n⚠️  ACCEPTABLE SECURITY POSTURE - Address warnings")
        else:
            print("\n❌ POOR SECURITY POSTURE - Fix vulnerabilities before production")
        
        if self.recommendations:
            print("\n💡 Security Recommendations:")
            for i, rec in enumerate(self.recommendations[:5], 1):
                print(f"{i}. {rec}")
        
        # Save report
        report_file = self.base_dir / 'security_audit_report.json'
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        print(f"\n📄 Detailed security report saved to: {report_file}")
        
        return summary['high_severity_vulnerabilities'] == 0


def main():
    """Main entry point."""
    auditor = SecurityAuditor()
    is_secure = auditor.run_full_audit()
    
    sys.exit(0 if is_secure else 1)


if __name__ == '__main__':
    main()