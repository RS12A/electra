"""
Schema health tests for the Electra project.

These tests verify that the database schema is properly configured,
all required tables exist, and basic database operations work correctly.
"""
import pytest
from django.test import TestCase, TransactionTestCase
from django.db import connection
from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.apps import apps
from django.conf import settings

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election
from electra_server.apps.ballots.models import BallotToken
from electra_server.apps.votes.models import Vote
from electra_server.apps.audit.models import AuditLog


class SchemaHealthTestCase(TestCase):
    """Test case for basic schema health checks."""
    
    def test_database_connection(self):
        """Test that database connection is working."""
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            self.assertEqual(result[0], 1)
    
    def test_critical_tables_exist(self):
        """Test that all critical tables exist in the database."""
        critical_tables = [
            'electra_auth_user',
            'auth_group',
            'auth_permission',
            'django_content_type',
            'django_migrations',
            'elections_election',
            'ballots_ballot_token',
            'votes_vote',
            'audit_log',
        ]
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            """)
            existing_tables = {row[0] for row in cursor.fetchall()}
        
        missing_tables = []
        for table in critical_tables:
            if table not in existing_tables:
                missing_tables.append(table)
        
        self.assertEqual(
            missing_tables, [],
            f"Missing critical tables: {missing_tables}"
        )
    
    def test_custom_user_model_configuration(self):
        """Test that the custom user model is properly configured."""
        User = get_user_model()
        
        # Check AUTH_USER_MODEL setting
        self.assertEqual(settings.AUTH_USER_MODEL, 'electra_auth.User')
        
        # Check user model is the expected class
        self.assertEqual(User.__name__, 'User')
        self.assertEqual(User._meta.app_label, 'electra_auth')
        
        # Check required fields exist
        required_fields = ['id', 'email', 'full_name', 'role', 'is_active', 'date_joined']
        model_fields = [field.name for field in User._meta.get_fields()]
        
        for field in required_fields:
            self.assertIn(field, model_fields, f"Missing required field: {field}")
    
    def test_model_table_mapping(self):
        """Test that all Django models have corresponding database tables."""
        all_models = apps.get_models()
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
            """)
            existing_tables = {row[0] for row in cursor.fetchall()}
        
        missing_tables = []
        for model in all_models:
            if hasattr(model, '_meta'):
                table_name = model._meta.db_table
                if table_name not in existing_tables:
                    missing_tables.append(f"{model.__name__} -> {table_name}")
        
        self.assertEqual(
            missing_tables, [],
            f"Models without database tables: {missing_tables}"
        )
    
    def test_database_indexes_exist(self):
        """Test that important database indexes exist."""
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT schemaname, tablename, indexname 
                FROM pg_indexes 
                WHERE schemaname = 'public'
            """)
            indexes = cursor.fetchall()
        
        # Should have some indexes (at least primary keys and foreign keys)
        self.assertGreater(len(indexes), 0, "No database indexes found")
        
        # Check for some critical indexes
        index_names = [idx[2] for idx in indexes]
        
        # Primary key indexes should exist
        expected_pk_indexes = [
            'electra_auth_user_pkey',
            'elections_election_pkey',
        ]
        
        for expected_index in expected_pk_indexes:
            self.assertIn(expected_index, index_names, f"Missing index: {expected_index}")


class SchemaOperationsTestCase(TestCase):
    """Test case for basic database operations."""
    
    def test_user_creation_and_retrieval(self):
        """Test creating and retrieving users with different roles."""
        User = get_user_model()
        
        # Create a staff user
        staff_user = User.objects.create_user(
            email='staff@electra.test',
            full_name='Test Staff User',
            password='testpass123',
            role=UserRole.STAFF,
            staff_id='STAFF001'
        )
        
        # Verify user was created
        self.assertEqual(staff_user.email, 'staff@electra.test')
        self.assertEqual(staff_user.role, UserRole.STAFF)
        self.assertTrue(staff_user.is_active)
        
        # Retrieve user from database
        retrieved_user = User.objects.get(email='staff@electra.test')
        self.assertEqual(retrieved_user.id, staff_user.id)
        self.assertEqual(retrieved_user.full_name, 'Test Staff User')
        
        # Test user count
        user_count = User.objects.count()
        self.assertEqual(user_count, 1)
        
        # Create a student user
        student_user = User.objects.create_user(
            email='student@electra.test',
            full_name='Test Student User',
            password='testpass123',
            role=UserRole.STUDENT,
            matric_number='ST001'
        )
        
        # Verify both users exist
        self.assertEqual(User.objects.count(), 2)
        
        # Test filtering by role
        staff_users = User.objects.filter(role=UserRole.STAFF)
        student_users = User.objects.filter(role=UserRole.STUDENT)
        
        self.assertEqual(staff_users.count(), 1)
        self.assertEqual(student_users.count(), 1)
    
    def test_related_model_operations(self):
        """Test operations with related models."""
        User = get_user_model()
        
        # Create a user
        user = User.objects.create_user(
            email='admin@electra.test',
            full_name='Test Admin',
            password='testpass123',
            role=UserRole.ADMIN,
            staff_id='ADMIN001'
        )
        
        # Create an election
        election = Election.objects.create(
            title='Test Election',
            description='A test election',
            created_by=user,
            start_time='2025-01-01T10:00:00Z',
            end_time='2025-01-02T10:00:00Z'
        )
        
        # Verify relationships work
        self.assertEqual(election.created_by, user)
        self.assertEqual(user.created_elections.count(), 1)
        self.assertEqual(user.created_elections.first(), election)
    
    def test_audit_log_operations(self):
        """Test audit log functionality."""
        from electra_server.apps.audit.models import AuditActionType
        
        # Create an audit log entry
        audit_entry = AuditLog.objects.create(
            action_type=AuditActionType.USER_LOGIN,
            action_description='User logged in successfully',
            user_identifier='test@electra.test',
            ip_address='127.0.0.1',
            outcome='success'
        )
        
        # Verify audit log was created
        self.assertEqual(audit_entry.action_type, AuditActionType.USER_LOGIN)
        self.assertEqual(audit_entry.outcome, 'success')
        
        # Test audit log retrieval
        retrieved_entry = AuditLog.objects.get(id=audit_entry.id)
        self.assertEqual(retrieved_entry.action_type, audit_entry.action_type)
        
        # Test audit log filtering
        success_logs = AuditLog.objects.filter(outcome='success')
        self.assertEqual(success_logs.count(), 1)


class SchemaMigrationTestCase(TransactionTestCase):
    """Test case for migration-related functionality."""
    
    def test_migrations_applied(self):
        """Test that all migrations have been applied."""
        from django.db.migrations.executor import MigrationExecutor
        from django.db import connections
        
        executor = MigrationExecutor(connections['default'])
        plan = executor.migration_plan(executor.loader.graph.leaf_nodes())
        
        self.assertEqual(
            len(plan), 0,
            f"Unapplied migrations found: {[migration.name for migration, backwards in plan]}"
        )
    
    def test_no_missing_migrations(self):
        """Test that there are no missing migrations."""
        from django.core.management import call_command
        from io import StringIO
        import sys
        
        # Capture makemigrations --dry-run output
        old_stdout = sys.stdout
        old_stderr = sys.stderr
        sys.stdout = captured_output = StringIO()
        sys.stderr = captured_errors = StringIO()
        
        try:
            call_command('makemigrations', '--dry-run', verbosity=1)
            output = captured_output.getvalue()
            errors = captured_errors.getvalue()
        finally:
            sys.stdout = old_stdout  
            sys.stderr = old_stderr
        
        # Should show "No changes detected" if all migrations exist
        # Or output should be empty if no changes are needed
        if output.strip():
            self.assertIn('No changes detected', output, 
                         f"Missing migrations detected: {output}")
        # If output is empty, that's also fine - means no changes needed


class SchemaConstraintsTestCase(TestCase):
    """Test case for database constraints and validation."""
    
    def test_user_email_uniqueness(self):
        """Test that user email uniqueness constraint works."""
        User = get_user_model()
        
        # Create first user
        User.objects.create_user(
            email='unique@electra.test',
            full_name='First User',
            password='testpass123',
            role=UserRole.STAFF,
            staff_id='STAFF001'
        )
        
        # Try to create second user with same email
        with self.assertRaises(Exception):  # Should raise IntegrityError
            User.objects.create_user(
                email='unique@electra.test',
                full_name='Second User',
                password='testpass123',
                role=UserRole.STAFF,
                staff_id='STAFF002'
            )
    
    def test_user_staff_id_uniqueness(self):
        """Test that staff ID uniqueness constraint works."""
        User = get_user_model()
        
        # Create first staff user
        User.objects.create_user(
            email='staff1@electra.test',
            full_name='First Staff',
            password='testpass123',
            role=UserRole.STAFF,
            staff_id='STAFF001'
        )
        
        # Try to create second staff user with same staff_id
        with self.assertRaises(Exception):  # Should raise IntegrityError
            User.objects.create_user(
                email='staff2@electra.test',
                full_name='Second Staff',
                password='testpass123',
                role=UserRole.STAFF,
                staff_id='STAFF001'
            )
    
    def test_user_matric_number_uniqueness(self):
        """Test that matric number uniqueness constraint works."""
        User = get_user_model()
        
        # Create first student
        User.objects.create_user(
            email='student1@electra.test',
            full_name='First Student',
            password='testpass123',
            role=UserRole.STUDENT,
            matric_number='ST001'
        )
        
        # Try to create second student with same matric_number
        with self.assertRaises(Exception):  # Should raise IntegrityError
            User.objects.create_user(
                email='student2@electra.test',
                full_name='Second Student',
                password='testpass123',
                role=UserRole.STUDENT,
                matric_number='ST001'
            )


@pytest.mark.integration
class SchemaIntegrationTestCase(TransactionTestCase):
    """Integration tests for schema functionality."""
    
    def test_full_user_workflow(self):
        """Test a complete user workflow including related models."""
        User = get_user_model()
        
        # Create admin user
        admin = User.objects.create_user(
            email='admin@electra.test',
            full_name='Election Admin',
            password='admin123',
            role=UserRole.ADMIN,
            staff_id='ADMIN001'
        )
        
        # Create student user
        student = User.objects.create_user(
            email='student@electra.test',
            full_name='Test Student',
            password='student123',
            role=UserRole.STUDENT,
            matric_number='ST001'
        )
        
        # Admin creates an election
        election = Election.objects.create(
            title='Student Council Election',
            description='Annual student council election',
            created_by=admin,
            start_time='2025-01-01T10:00:00Z',
            end_time='2025-01-02T10:00:00Z'
        )
        
        # Verify relationships
        self.assertEqual(election.created_by, admin)
        
        # Verify reverse relationships
        self.assertEqual(admin.created_elections.count(), 1)
        
        # Test queries across relationships
        admin_elections = Election.objects.filter(created_by__role=UserRole.ADMIN)
        self.assertEqual(admin_elections.count(), 1)
    
    def test_cascade_deletions(self):
        """Test that cascade deletions work properly."""
        User = get_user_model()
        
        # Create user and related objects
        user = User.objects.create_user(
            email='cascade@electra.test',
            full_name='Cascade Test User',
            password='test123',
            role=UserRole.ADMIN,
            staff_id='CASCADE001'
        )
        
        election = Election.objects.create(
            title='Cascade Test Election',
            description='Test cascade deletion',
            created_by=user,
            start_time='2025-01-01T10:00:00Z',
            end_time='2025-01-02T10:00:00Z'
        )
        
        election_id = election.id
        
        # The election has a protected foreign key to user, so deletion should fail
        with self.assertRaises(Exception):  # Should raise ProtectedError
            user.delete()
        
        # Election should still exist
        self.assertTrue(Election.objects.filter(id=election_id).exists())
        
        # Delete election first, then user should be deletable
        election.delete()
        user.delete()
        
        # Verify both are gone
        self.assertFalse(Election.objects.filter(id=election_id).exists())
        self.assertFalse(User.objects.filter(email='cascade@electra.test').exists())