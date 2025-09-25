#!/usr/bin/env python
"""
Comprehensive test runner for the Electra voting system.

This script runs all tests with coverage reporting and generates
detailed reports on test results, coverage, and potential issues.
"""
import os
import sys
import subprocess
import time
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.test')

import django
django.setup()

from django.core.management import execute_from_command_line
from django.test.utils import get_runner
from django.conf import settings


def run_django_tests():
    """Run Django tests with coverage."""
    print("🧪 Running Django Backend Tests...")
    print("=" * 60)
    
    cmd = [
        'python', '-m', 'pytest',
        'tests/',
        'electra_server/apps/',
        '-v',
        '--tb=short',
        '--cov=electra_server',
        '--cov=apps',
        '--cov-report=html:htmlcov',
        '--cov-report=term-missing',
        '--cov-report=json:coverage.json',
        '--junit-xml=junit.xml',
        '--maxfail=10'
    ]
    
    result = subprocess.run(cmd, cwd=project_root)
    return result.returncode == 0


def run_linting():
    """Run code linting."""
    print("\n🔍 Running Code Linting...")
    print("=" * 60)
    
    success = True
    
    # Run flake8
    print("Running flake8...")
    result = subprocess.run(['flake8', '.'], cwd=project_root, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Flake8 errors found:\n{result.stdout}")
        success = False
    else:
        print("✅ Flake8 passed")
    
    # Run black check
    print("Running black...")
    result = subprocess.run(['black', '--check', '.'], cwd=project_root, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ Black formatting issues found:\n{result.stdout}")
        success = False
    else:
        print("✅ Black formatting passed")
    
    # Run isort check
    print("Running isort...")
    result = subprocess.run(['isort', '--check-only', '.'], cwd=project_root, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"❌ isort import issues found:\n{result.stdout}")
        success = False
    else:
        print("✅ isort passed")
    
    return success


def check_security():
    """Run security checks."""
    print("\n🔒 Running Security Checks...")
    print("=" * 60)
    
    success = True
    
    # Django system check
    print("Running Django system check...")
    try:
        from django.core.management import execute_from_command_line
        result = execute_from_command_line(['manage.py', 'check', '--deploy'])
        print("✅ Django system check passed")
    except SystemExit as e:
        if e.code != 0:
            print("❌ Django system check failed")
            success = False
    
    # Run security-specific tests
    print("Running security tests...")
    cmd = [
        'python', '-m', 'pytest',
        'tests/test_security_comprehensive.py',
        '-v',
        '--tb=short'
    ]
    
    result = subprocess.run(cmd, cwd=project_root)
    if result.returncode != 0:
        print("❌ Some security tests failed")
        success = False
    else:
        print("✅ Security tests passed")
    
    return success


def generate_report():
    """Generate comprehensive test report."""
    print("\n📊 Generating Test Report...")
    print("=" * 60)
    
    # Check if coverage data exists
    coverage_file = project_root / 'coverage.json'
    if coverage_file.exists():
        import json
        with open(coverage_file) as f:
            coverage_data = json.load(f)
        
        total_coverage = coverage_data['totals']['percent_covered']
        print(f"📈 Total Test Coverage: {total_coverage:.1f}%")
        
        if total_coverage >= 80:
            print("✅ Coverage meets minimum requirement (80%)")
        else:
            print("❌ Coverage below minimum requirement (80%)")
    
    # Check test results
    junit_file = project_root / 'junit.xml'
    if junit_file.exists():
        print("✅ JUnit XML report generated")
    
    # List generated files
    print("\n📁 Generated Files:")
    if (project_root / 'htmlcov').exists():
        print(f"  📄 HTML Coverage Report: file://{project_root}/htmlcov/index.html")
    if coverage_file.exists():
        print(f"  📄 JSON Coverage Report: {coverage_file}")
    if junit_file.exists():
        print(f"  📄 JUnit XML Report: {junit_file}")


def main():
    """Main test runner."""
    print("🚀 Electra Comprehensive Test Suite")
    print("=" * 60)
    
    start_time = time.time()
    
    # Initialize results
    results = {
        'tests': False,
        'linting': False,
        'security': False,
    }
    
    # Run tests
    try:
        results['tests'] = run_django_tests()
        results['linting'] = run_linting()
        results['security'] = check_security()
        
        generate_report()
        
    except KeyboardInterrupt:
        print("\n❌ Test run interrupted by user")
        return 1
    except Exception as e:
        print(f"\n❌ Test run failed with error: {e}")
        return 1
    
    # Summary
    end_time = time.time()
    duration = end_time - start_time
    
    print("\n" + "=" * 60)
    print("📋 TEST SUMMARY")
    print("=" * 60)
    
    total_passed = sum(results.values())
    total_tests = len(results)
    
    print(f"✅ Tests Passed: {results['tests']}")
    print(f"✅ Linting Passed: {results['linting']}")  
    print(f"✅ Security Passed: {results['security']}")
    print(f"⏱️  Total Duration: {duration:.1f}s")
    
    if total_passed == total_tests:
        print("\n🎉 ALL CHECKS PASSED! 🎉")
        print("The Electra system is ready for production deployment.")
        return 0
    else:
        print(f"\n❌ {total_tests - total_passed} CHECK(S) FAILED")
        print("Please fix the issues before deployment.")
        return 1


if __name__ == '__main__':
    sys.exit(main())