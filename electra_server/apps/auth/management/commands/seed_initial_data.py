"""
Management command to seed initial data for development.

This command creates:
1. An admin user from environment variables
2. A sample election record for development purposes

The command is idempotent - it can be run multiple times safely.
"""
import os
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction
from django.conf import settings
from django.utils import timezone

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed initial data for development (admin user and sample records)'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--admin-username',
            type=str,
            default=os.getenv('ADMIN_USERNAME', 'admin'),
            help='Admin username (default: from ADMIN_USERNAME env or "admin")'
        )
        parser.add_argument(
            '--admin-email',
            type=str,
            default=os.getenv('ADMIN_EMAIL', 'admin@electra.com'),
            help='Admin email (default: from ADMIN_EMAIL env or "admin@electra.com")'
        )
        parser.add_argument(
            '--admin-password',
            type=str,
            default=os.getenv('ADMIN_PASSWORD', 'admin123'),
            help='Admin password (default: from ADMIN_PASSWORD env or "admin123")'
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force update existing admin user'
        )
    
    def handle(self, *args, **options):
        """Handle the command execution."""
        self.stdout.write(self.style.SUCCESS('Starting initial data seeding...'))
        
        try:
            with transaction.atomic():
                # Create admin user
                admin_created = self._create_admin_user(
                    username=options['admin_username'],
                    email=options['admin_email'],
                    password=options['admin_password'],
                    force=options['force']
                )
                
                # Create sample election (placeholder for future implementation)
                self._create_sample_election()
                
                if admin_created:
                    self.stdout.write(
                        self.style.SUCCESS('✓ Initial data seeding completed successfully!')
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING('✓ Seeding completed (admin user already existed)')
                    )
                
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'✗ Error during seeding: {str(e)}')
            )
            raise e
    
    def _create_admin_user(self, username, email, password, force=False):
        """
        Create admin user if it doesn't exist.
        
        Args:
            username (str): Admin username
            email (str): Admin email
            password (str): Admin password
            force (bool): Force update if user exists
        
        Returns:
            bool: True if user was created, False if already existed
        """
        try:
            user = User.objects.get(email=email)
            
            if force:
                # Update existing user
                user.is_staff = True
                user.is_superuser = True
                user.is_active = True
                user.role = 'admin'
                user.set_password(password)
                
                # Set required fields if missing
                if not user.full_name:
                    user.full_name = 'System Administrator'
                if not user.staff_id:
                    user.staff_id = 'ADMIN001'
                
                user.save()
                self.stdout.write(f'✓ Updated existing admin user: {user.email}')
                return True
            else:
                self.stdout.write(f'→ Admin user already exists: {user.email}')
                return False
                
        except User.DoesNotExist:
            # Create new admin user
            user = User.objects.create_user(
                email=email,
                password=password,
                full_name='System Administrator',
                staff_id='ADMIN001',
                role='admin',
                is_staff=True,
                is_superuser=True,
                is_active=True
            )
            
            self.stdout.write(f'✓ Created admin user: {user.email}')
            return True
    
    def _create_sample_election(self):
        """
        Create sample election data for development.
        """
        try:
            from electra_server.apps.elections.models import Election
            from datetime import timedelta
            
            # Get the admin user as creator
            admin_user = User.objects.get(email='admin@electra.com')
            
            election, created = Election.objects.get_or_create(
                title='Sample Student Council Election 2024',
                defaults={
                    'description': 'This is a sample election for development purposes.',
                    'start_time': timezone.now() + timedelta(days=7),
                    'end_time': timezone.now() + timedelta(days=14),
                    'status': 'draft',
                    'created_by': admin_user,
                    'delayed_reveal': False,
                }
            )
            
            if created:
                self.stdout.write('✓ Created sample election')
            else:
                self.stdout.write('→ Sample election already exists')
                
        except Exception as e:
            self.stdout.write(
                self.style.WARNING(f'→ Could not create sample election: {str(e)}')
            )
    
    def _get_env_or_prompt(self, env_var, default, prompt):
        """
        Get value from environment variable or prompt user.
        
        Args:
            env_var (str): Environment variable name
            default (str): Default value
            prompt (str): Prompt message
        
        Returns:
            str: The value to use
        """
        value = os.getenv(env_var)
        if not value:
            if settings.DEBUG:
                # In development, use default
                value = default
                self.stdout.write(f'→ Using default for {env_var}: {value}')
            else:
                # In production, prompt for value
                value = input(f'{prompt} (default: {default}): ').strip() or default
        
        return value