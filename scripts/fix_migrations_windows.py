#!/usr/bin/env python
"""
Windows automation script to fix Django migrations and database schema.

This script runs makemigrations and migrate, verifies that all tables exist,
detects missing migrations or schema mismatches and automatically fixes them.
Runs safely and idempotently on Windows.
"""
import os
import sys
import subprocess
import argparse
from pathlib import Path
from typing import List, Optional, Tuple, Dict

# Add the project root to the Python path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'electra_server.settings.dev')

import django
django.setup()

from django.core.management import call_command, execute_from_command_line
from django.db import connection
from django.apps import apps


class Colors:
    """ANSI color codes for terminal output."""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    BOLD = '\033[1m'
    END = '\033[0m'


class MigrationFixer:
    """Main class for fixing Django migrations and database schema."""
    
    def __init__(self, verbose: bool = False, dry_run: bool = False):
        """Initialize the migration fixer."""
        self.verbose = verbose
        self.dry_run = dry_run
        self.issues_found = []
        self.fixes_applied = []
        
    def log_info(self, message: str) -> None:
        """Log an info message."""
        print(f"{Colors.BLUE}ℹ️  {message}{Colors.END}")
        
    def log_success(self, message: str) -> None:
        """Log a success message."""
        print(f"{Colors.GREEN}✅ {message}{Colors.END}")
        
    def log_warning(self, message: str) -> None:
        """Log a warning message."""
        print(f"{Colors.YELLOW}⚠️  {message}{Colors.END}")
        
    def log_error(self, message: str) -> None:
        """Log an error message."""
        print(f"{Colors.RED}❌ {message}{Colors.END}")
        
    def run_command(self, command: List[str], capture_output: bool = True) -> Tuple[int, str, str]:
        """Run a command and return exit code, stdout, stderr."""
        try:
            if self.verbose:
                self.log_info(f"Running: {' '.join(command)}")
                
            result = subprocess.run(
                command,
                cwd=PROJECT_ROOT,
                capture_output=capture_output,
                text=True,
                check=False
            )
            
            return result.returncode, result.stdout, result.stderr
            
        except Exception as e:
            self.log_error(f"Failed to run command {' '.join(command)}: {e}")
            return 1, "", str(e)
    
    def check_database_connection(self) -> bool:
        """Check if database connection is working."""
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                if result and result[0] == 1:
                    self.log_success("Database connection successful")
                    return True
                return False
        except Exception as e:
            self.log_error(f"Database connection failed: {e}")
            return False
    
    def check_migrations_directories(self) -> List[str]:
        """Check that all apps have migrations directories."""
        missing_dirs = []
        apps_dir = PROJECT_ROOT / 'electra_server' / 'apps'
        
        if not apps_dir.exists():
            self.log_error("Apps directory not found")
            return ['electra_server/apps']
            
        for app_dir in apps_dir.iterdir():
            if app_dir.is_dir() and not app_dir.name.startswith('__'):
                migrations_dir = app_dir / 'migrations'
                if not migrations_dir.exists():
                    missing_dirs.append(str(migrations_dir))
                elif self.verbose:
                    self.log_success(f"Migrations directory exists: {migrations_dir}")
                    
        return missing_dirs
    
    def create_missing_migration_directories(self, missing_dirs: List[str]) -> bool:
        """Create missing migrations directories."""
        if not missing_dirs:
            return True
            
        success = True
        for migrations_path in missing_dirs:
            try:
                if not self.dry_run:
                    migrations_dir = Path(migrations_path)
                    migrations_dir.mkdir(parents=True, exist_ok=True)
                    
                    # Create __init__.py
                    init_file = migrations_dir / '__init__.py'
                    init_file.touch()
                    
                self.log_success(f"Created migrations directory: {migrations_path}")
                self.fixes_applied.append(f"Created {migrations_path}")
                
            except Exception as e:
                self.log_error(f"Failed to create migrations directory {migrations_path}: {e}")
                success = False
                
        return success
    
    def run_makemigrations(self) -> bool:
        """Run Django makemigrations command."""
        try:
            self.log_info("Running makemigrations...")
            
            if self.dry_run:
                self.log_info("DRY RUN: Would run makemigrations")
                return True
                
            # Use Django's call_command for better integration
            from io import StringIO
            import sys
            
            # Capture output
            old_stdout = sys.stdout
            sys.stdout = captured_output = StringIO()
            
            try:
                call_command('makemigrations', verbosity=1)
                output = captured_output.getvalue()
                sys.stdout = old_stdout
                
                if 'No changes detected' in output:
                    self.log_success("No new migrations needed")
                else:
                    self.log_success("Migrations created successfully")
                    self.fixes_applied.append("Created new migrations")
                    
                if self.verbose:
                    print(output)
                    
                return True
                
            finally:
                sys.stdout = old_stdout
                
        except Exception as e:
            self.log_error(f"Failed to run makemigrations: {e}")
            return False
    
    def run_migrate(self) -> bool:
        """Run Django migrate command."""
        try:
            self.log_info("Running migrate...")
            
            if self.dry_run:
                self.log_info("DRY RUN: Would run migrate")
                return True
                
            # Use Django's call_command for better integration
            from io import StringIO
            import sys
            
            # Capture output
            old_stdout = sys.stdout
            sys.stdout = captured_output = StringIO()
            
            try:
                call_command('migrate', verbosity=1)
                output = captured_output.getvalue()
                sys.stdout = old_stdout
                
                self.log_success("Database migrations applied successfully")
                self.fixes_applied.append("Applied database migrations")
                
                if self.verbose:
                    print(output)
                    
                return True
                
            finally:
                sys.stdout = old_stdout
                
        except Exception as e:
            self.log_error(f"Failed to run migrate: {e}")
            return False
    
    def verify_critical_tables(self) -> List[str]:
        """Verify that critical tables exist in the database."""
        critical_tables = [
            'electra_auth_user',
            'auth_group',
            'auth_permission',
            'django_content_type',
            'django_migrations',
            'elections_election',
            'ballots_ballot_token',
            'votes_vote',
            'audit_log'
        ]
        
        missing_tables = []
        
        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                """)
                existing_tables = {row[0] for row in cursor.fetchall()}
                
            for table in critical_tables:
                if table not in existing_tables:
                    missing_tables.append(table)
                elif self.verbose:
                    self.log_success(f"Table exists: {table}")
                    
        except Exception as e:
            self.log_error(f"Failed to verify tables: {e}")
            missing_tables.extend(critical_tables)  # Assume all missing on error
            
        return missing_tables
    
    def run_schema_verification(self) -> bool:
        """Run the verify_schema management command."""
        try:
            self.log_info("Running schema verification...")
            
            # Use Django's call_command
            call_command('verify_schema')
            self.log_success("Schema verification passed")
            return True
            
        except Exception as e:
            self.log_error(f"Schema verification failed: {e}")
            return False
    
    def fix_migrations(self) -> bool:
        """Main method to fix all migration issues."""
        self.log_info("🔧 Starting migration fixes...")
        
        success = True
        
        # 1. Check database connection
        if not self.check_database_connection():
            self.issues_found.append("Database connection failed")
            success = False
            return success
        
        # 2. Check and create missing migrations directories
        missing_dirs = self.check_migrations_directories()
        if missing_dirs:
            self.issues_found.extend([f"Missing migrations directory: {d}" for d in missing_dirs])
            if not self.create_missing_migration_directories(missing_dirs):
                success = False
        
        # 3. Run makemigrations
        if not self.run_makemigrations():
            self.issues_found.append("Failed to run makemigrations")
            success = False
        
        # 4. Run migrate
        if not self.run_migrate():
            self.issues_found.append("Failed to run migrate")
            success = False
        
        # 5. Verify critical tables exist
        missing_tables = self.verify_critical_tables()
        if missing_tables:
            self.issues_found.extend([f"Missing table: {t}" for t in missing_tables])
            success = False
        
        # 6. Run schema verification
        if not self.run_schema_verification():
            self.issues_found.append("Schema verification failed")
            success = False
        
        return success
    
    def print_summary(self) -> None:
        """Print a summary of the fixes applied and issues found."""
        print(f"\n{Colors.BOLD}=== MIGRATION FIX SUMMARY ==={Colors.END}")
        
        if self.fixes_applied:
            print(f"\n{Colors.GREEN}✅ Fixes Applied ({len(self.fixes_applied)}):{Colors.END}")
            for fix in self.fixes_applied:
                print(f"  • {fix}")
        
        if self.issues_found:
            print(f"\n{Colors.RED}❌ Issues Found ({len(self.issues_found)}):{Colors.END}")
            for issue in self.issues_found:
                print(f"  • {issue}")
        
        if not self.issues_found and not self.fixes_applied:
            print(f"\n{Colors.GREEN}🎉 No issues found - everything looks good!{Colors.END}")
        
        print(f"\n{Colors.BOLD}=== END SUMMARY ==={Colors.END}")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Fix Django migrations and database schema for Electra project",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python scripts/fix_migrations_windows.py
  python scripts/fix_migrations_windows.py --verbose
  python scripts/fix_migrations_windows.py --dry-run --verbose
        """
    )
    
    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Enable verbose output'
    )
    
    parser.add_argument(
        '--dry-run', '-n',
        action='store_true',
        help='Show what would be done without making changes'
    )
    
    args = parser.parse_args()
    
    # Print header
    print(f"{Colors.CYAN}{Colors.BOLD}🔧 Electra Migration Fixer for Windows{Colors.END}")
    print(f"{Colors.CYAN}Fixing Django migrations and database schema...{Colors.END}\n")
    
    if args.dry_run:
        print(f"{Colors.YELLOW}🔍 DRY RUN MODE - No changes will be made{Colors.END}\n")
    
    try:
        fixer = MigrationFixer(verbose=args.verbose, dry_run=args.dry_run)
        success = fixer.fix_migrations()
        
        fixer.print_summary()
        
        if success:
            print(f"\n{Colors.GREEN}🎉 All migration fixes completed successfully!{Colors.END}")
            sys.exit(0)
        else:
            print(f"\n{Colors.RED}💥 Some migration fixes failed. Check the issues above.{Colors.END}")
            sys.exit(1)
            
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}⚠️  Operation cancelled by user{Colors.END}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}💥 Unexpected error: {e}{Colors.END}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()