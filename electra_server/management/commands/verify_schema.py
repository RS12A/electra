"""
Django management command to verify database schema integrity.

This command checks that all critical tables exist, compares models to DB schema,
and reports any mismatches or missing migrations.
"""
import sys
from typing import List, Dict, Any, Tuple
from django.core.management.base import BaseCommand, CommandError
from django.db import connection, models
from django.apps import apps
from django.db.models import Model
from django.conf import settings


class Command(BaseCommand):
    """Management command to verify database schema integrity."""
    
    help = 'Verify database schema integrity and check for missing migrations'
    
    def add_arguments(self, parser):
        """Add command line arguments."""
        parser.add_argument(
            '--fix-missing',
            action='store_true',
            help='Automatically run makemigrations if missing migrations are detected'
        )
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='Enable verbose output'
        )
        
    def handle(self, *args, **options):
        """Main command handler."""
        self.verbose = options.get('verbose', False)
        self.fix_missing = options.get('fix_missing', False)
        
        self.stdout.write(self.style.HTTP_INFO('🔍 Starting database schema verification...'))
        
        # Track any issues found
        issues_found = []
        
        try:
            # 1. Check database connection
            if not self._check_database_connection():
                issues_found.append("Database connection failed")
                
            # 2. Check critical tables exist
            missing_tables = self._check_critical_tables()
            if missing_tables:
                issues_found.extend([f"Missing table: {table}" for table in missing_tables])
                
            # 3. Check for unmigrated changes
            unmigrated_apps = self._check_unmigrated_changes()
            if unmigrated_apps:
                issues_found.extend([f"Unmigrated changes in app: {app}" for app in unmigrated_apps])
                
            # 4. Verify custom user model
            if not self._verify_custom_user_model():
                issues_found.append("Custom user model verification failed")
                
            # 5. Check model-database schema consistency
            schema_issues = self._check_schema_consistency()
            if schema_issues:
                issues_found.extend(schema_issues)
                
            # 6. Verify basic database operations
            if not self._test_basic_operations():
                issues_found.append("Basic database operations failed")
                
            # Report results
            if issues_found:
                self.stdout.write(self.style.ERROR(f'\n❌ Schema verification failed with {len(issues_found)} issues:'))
                for issue in issues_found:
                    self.stdout.write(self.style.ERROR(f'  • {issue}'))
                    
                if self.fix_missing and unmigrated_apps:
                    self._attempt_auto_fix(unmigrated_apps)
                else:
                    self.stdout.write(self.style.WARNING('\n💡 Run with --fix-missing to automatically fix migration issues'))
                    
                sys.exit(1)
            else:
                self.stdout.write(self.style.SUCCESS('\n✅ All schema verification checks passed!'))
                self.stdout.write(self.style.SUCCESS('🎉 Database schema is healthy and consistent'))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'\n💥 Schema verification failed with exception: {e}'))
            if self.verbose:
                import traceback
                self.stdout.write(traceback.format_exc())
            sys.exit(1)
            
    def _check_database_connection(self) -> bool:
        """Check if database connection is working."""
        try:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                result = cursor.fetchone()
                if result and result[0] == 1:
                    if self.verbose:
                        self.stdout.write(self.style.SUCCESS('✓ Database connection successful'))
                    return True
                return False
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Database connection failed: {e}'))
            return False
            
    def _check_critical_tables(self) -> List[str]:
        """Check that all critical tables exist."""
        # Define critical tables that must exist
        critical_tables = [
            'electra_auth_user',  # Custom user model
            'auth_group',
            'auth_permission',
            'django_content_type',
            'django_migrations',
            'elections_election',
            'ballots_ballot_token',
            'votes_vote',
            'audit_log',
        ]
        
        # Get list of existing tables
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            """)
            existing_tables = {row[0] for row in cursor.fetchall()}
            
        # Check for missing tables
        missing_tables = []
        for table in critical_tables:
            if table not in existing_tables:
                missing_tables.append(table)
            elif self.verbose:
                self.stdout.write(self.style.SUCCESS(f'✓ Table exists: {table}'))
                
        return missing_tables
        
    def _check_unmigrated_changes(self) -> List[str]:
        """Check for apps with unmigrated model changes."""
        from django.core.management import execute_from_command_line
        from io import StringIO
        import sys
        
        unmigrated_apps = []
        
        try:
            # Capture makemigrations --dry-run output
            old_stdout = sys.stdout
            sys.stdout = captured_output = StringIO()
            
            execute_from_command_line(['manage.py', 'makemigrations', '--dry-run'])
            
            sys.stdout = old_stdout
            output = captured_output.getvalue()
            
            # Parse output to find apps with changes
            lines = output.split('\n')
            for line in lines:
                if line.startswith('Migrations for '):
                    app_name = line.split("'")[1]
                    unmigrated_apps.append(app_name)
                    
        except Exception as e:
            if self.verbose:
                self.stdout.write(self.style.WARNING(f'Could not check for unmigrated changes: {e}'))
                
        return unmigrated_apps
        
    def _verify_custom_user_model(self) -> bool:
        """Verify the custom user model is properly configured."""
        try:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            
            # Check AUTH_USER_MODEL setting
            expected_model = 'electra_auth.User'
            actual_model = settings.AUTH_USER_MODEL
            
            if actual_model != expected_model:
                self.stdout.write(self.style.ERROR(
                    f'AUTH_USER_MODEL mismatch: expected {expected_model}, got {actual_model}'
                ))
                return False
                
            # Verify user model fields
            required_fields = ['id', 'email', 'full_name', 'role', 'is_active', 'date_joined']
            model_fields = [field.name for field in User._meta.get_fields()]
            
            missing_fields = [field for field in required_fields if field not in model_fields]
            if missing_fields:
                self.stdout.write(self.style.ERROR(
                    f'Missing required fields in User model: {missing_fields}'
                ))
                return False
                
            # Test basic user model operations
            user_count = User.objects.count()
            if self.verbose:
                self.stdout.write(self.style.SUCCESS(f'✓ Custom user model verified ({user_count} users in database)'))
                
            return True
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Custom user model verification failed: {e}'))
            return False
            
    def _check_schema_consistency(self) -> List[str]:
        """Check consistency between Django models and database schema."""
        issues = []
        
        try:
            # Get all Django models
            all_models = apps.get_models()
            
            with connection.cursor() as cursor:
                for model in all_models:
                    if hasattr(model, '_meta'):
                        table_name = model._meta.db_table
                        
                        # Check if table exists
                        cursor.execute("""
                            SELECT EXISTS (
                                SELECT FROM information_schema.tables 
                                WHERE table_schema = 'public' 
                                AND table_name = %s
                            )
                        """, [table_name])
                        
                        exists = cursor.fetchone()[0]
                        if not exists:
                            issues.append(f'Table missing for model {model.__name__}: {table_name}')
                        elif self.verbose:
                            self.stdout.write(self.style.SUCCESS(f'✓ Model table exists: {table_name}'))
                            
        except Exception as e:
            issues.append(f'Schema consistency check failed: {e}')
            
        return issues
        
    def _test_basic_operations(self) -> bool:
        """Test basic database operations."""
        try:
            from django.contrib.auth import get_user_model
            from electra_server.apps.auth.models import UserRole
            User = get_user_model()
            
            # Test basic query
            user_count = User.objects.count()
            
            # Test database write (create and delete a test record)
            test_email = 'schema_test@electra.test'
            
            # Clean up any existing test user first
            User.objects.filter(email=test_email).delete()
            
            # Create test user as staff to avoid matric_number requirement
            test_user = User.objects.create_user(
                email=test_email,
                full_name='Schema Test User',
                password='test_password',
                role=UserRole.STAFF,
                staff_id='TEST001'
            )
            
            # Verify it was created
            retrieved_user = User.objects.get(email=test_email)
            if retrieved_user.email != test_email:
                return False
                
            # Clean up
            test_user.delete()
            
            if self.verbose:
                self.stdout.write(self.style.SUCCESS('✓ Basic database operations successful'))
                
            return True
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Basic operations test failed: {e}'))
            return False
            
    def _attempt_auto_fix(self, unmigrated_apps: List[str]) -> None:
        """Attempt to automatically fix migration issues."""
        self.stdout.write(self.style.WARNING('\n🔧 Attempting to fix migration issues...'))
        
        try:
            from django.core.management import call_command
            
            # Run makemigrations
            self.stdout.write('Running makemigrations...')
            call_command('makemigrations', verbosity=1)
            
            # Run migrate
            self.stdout.write('Running migrate...')
            call_command('migrate', verbosity=1)
            
            self.stdout.write(self.style.SUCCESS('✅ Auto-fix completed successfully'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Auto-fix failed: {e}'))