"""
Django management command to seed initial data.
Creates admin user and sample election for development.
"""

import os
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.auth.models import User, Election
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = 'Seed database with initial data (admin user and sample election)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force creation even if data exists',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting database seeding...'))
        
        force = options.get('force', False)
        
        # Create admin user
        self.create_admin_user(force)
        
        # Create sample election for development
        if settings.DEBUG:
            self.create_sample_election(force)
        
        self.stdout.write(self.style.SUCCESS('Database seeding completed!'))

    def create_admin_user(self, force=False):
        """Create admin user from environment variables."""
        
        admin_email = os.environ.get('ADMIN_EMAIL', 'admin@electra.local')
        admin_password = os.environ.get('ADMIN_DEFAULT_PASSWORD', 'admin123!')
        admin_matric = 'ADMIN001'
        
        # Check if admin user already exists
        if User.objects.filter(matric_number=admin_matric).exists():
            if not force:
                self.stdout.write(
                    self.style.WARNING(f'Admin user {admin_matric} already exists. Use --force to recreate.')
                )
                return
            else:
                User.objects.filter(matric_number=admin_matric).delete()
                self.stdout.write(
                    self.style.WARNING(f'Deleted existing admin user {admin_matric}')
                )
        
        # Create admin user
        admin_user = User.objects.create_user(
            username=admin_matric,
            matric_number=admin_matric,
            email=admin_email,
            password=admin_password,
            first_name='System',
            last_name='Administrator',
            faculty='Administration',
            department='IT Services',
            level='admin',
            is_staff=True,
            is_superuser=True,
            is_verified=True,
            is_active=True,
        )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Created admin user: {admin_user.matric_number} / {admin_email} / {admin_password}'
            )
        )
        
        # Create electoral committee user
        ec_email = os.environ.get('EC_EMAIL', 'ec@electra.local')
        ec_password = os.environ.get('EC_DEFAULT_PASSWORD', 'ec123!')
        ec_matric = 'EC001'
        
        if not User.objects.filter(matric_number=ec_matric).exists() or force:
            if force:
                User.objects.filter(matric_number=ec_matric).delete()
            
            ec_user = User.objects.create_user(
                username=ec_matric,
                matric_number=ec_matric,
                email=ec_email,
                password=ec_password,
                first_name='Electoral',
                last_name='Committee',
                faculty='Administration',
                department='Electoral Committee',
                level='staff',
                is_staff=True,
                is_verified=True,
                is_active=True,
            )
            
            self.stdout.write(
                self.style.SUCCESS(
                    f'Created EC user: {ec_user.matric_number} / {ec_email} / {ec_password}'
                )
            )

    def create_sample_election(self, force=False):
        """Create a sample election for development."""
        
        if not settings.DEBUG:
            return
        
        election_title = 'Sample Student Union Election 2024'
        
        if Election.objects.filter(title=election_title).exists():
            if not force:
                self.stdout.write(
                    self.style.WARNING(f'Sample election already exists. Use --force to recreate.')
                )
                return
            else:
                Election.objects.filter(title=election_title).delete()
        
        # Get admin user as creator
        admin_user = User.objects.get(matric_number='ADMIN001')
        
        # Create sample election
        start_date = timezone.now() + timedelta(days=1)
        end_date = start_date + timedelta(days=7)
        
        election = Election.objects.create(
            title=election_title,
            description='A sample election for testing the voting system. This includes positions for Student Union President, Vice President, and other executive roles.',
            start_date=start_date,
            end_date=end_date,
            is_active=True,
            requires_verification=True,
            allow_multiple_votes=False,
            eligible_levels=['100', '200', '300', '400'],
            eligible_faculties=[],  # Empty means all faculties
            created_by=admin_user,
        )
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Created sample election: {election.title}'
            )
        )
        
        # Create sample students for testing
        sample_students = [
            {
                'matric_number': 'KWU/SCI/001',
                'email': 'student1@kwasu.edu.ng',
                'first_name': 'John',
                'last_name': 'Doe',
                'faculty': 'Science',
                'department': 'Computer Science',
                'level': '300',
            },
            {
                'matric_number': 'KWU/SCI/002',
                'email': 'student2@kwasu.edu.ng',
                'first_name': 'Jane',
                'last_name': 'Smith',
                'faculty': 'Science',
                'department': 'Mathematics',
                'level': '200',
            },
            {
                'matric_number': 'KWU/ENG/001',
                'email': 'student3@kwasu.edu.ng',
                'first_name': 'Bob',
                'last_name': 'Johnson',
                'faculty': 'Engineering',
                'department': 'Electrical Engineering',
                'level': '400',
            },
        ]
        
        for student_data in sample_students:
            if not User.objects.filter(matric_number=student_data['matric_number']).exists() or force:
                if force:
                    User.objects.filter(matric_number=student_data['matric_number']).delete()
                
                User.objects.create_user(
                    username=student_data['matric_number'],
                    password='student123!',
                    is_verified=True,
                    is_active=True,
                    **student_data
                )
                
                self.stdout.write(
                    self.style.SUCCESS(
                        f'Created sample student: {student_data["matric_number"]} / student123!'
                    )
                )