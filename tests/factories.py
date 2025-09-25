"""
Test factories for creating test data.

This module provides factory classes for creating test instances
of all models in the electra system with proper relationships and data.
"""
import uuid
from datetime import datetime, timedelta
from django.utils import timezone
from django.contrib.auth import get_user_model
import factory
from factory.django import DjangoModelFactory

# Import models
User = get_user_model()

try:
    from electra_server.apps.elections.models import Election
    from electra_server.apps.ballots.models import BallotToken  
    from electra_server.apps.votes.models import Vote
    from electra_server.apps.audit.models import AuditLog
except ImportError:
    # Models might not be available in all test scenarios
    Election = None
    BallotToken = None
    Vote = None
    AuditLog = None


class UserFactory(DjangoModelFactory):
    """Factory for creating test users."""
    
    class Meta:
        model = User
        django_get_or_create = ('email',)
        skip_postgeneration_save = True
    
    email = factory.Sequence(lambda n: f'user{n}@electra.test')
    full_name = factory.Faker('name')
    role = 'student'
    matric_number = factory.Sequence(lambda n: f'U{n:07d}')
    staff_id = None
    is_active = True
    is_staff = False
    is_superuser = False
    
    @classmethod
    def _create(cls, model_class, *args, **kwargs):
        """Override to use create_user method."""
        password = kwargs.pop('password', 'TestPassword123')
        manager = cls._get_manager(model_class)
        
        if hasattr(manager, 'create_user'):
            return manager.create_user(password=password, **kwargs)
        else:
            return super()._create(model_class, *args, password=password, **kwargs)


class StaffUserFactory(UserFactory):
    """Factory for creating staff users."""
    
    role = 'staff'
    matric_number = None
    staff_id = factory.Sequence(lambda n: f'ST{n:06d}')
    is_staff = True


class AdminUserFactory(UserFactory):
    """Factory for creating admin users."""
    
    role = 'admin'
    matric_number = None
    staff_id = factory.Sequence(lambda n: f'AD{n:06d}')
    is_staff = True
    is_superuser = True
    
    @classmethod
    def _create(cls, model_class, *args, **kwargs):
        """Override to use create_superuser method."""
        password = kwargs.pop('password', 'TestPassword123')
        manager = cls._get_manager(model_class)
        
        if hasattr(manager, 'create_superuser'):
            return manager.create_superuser(password=password, **kwargs)
        else:
            return super()._create(model_class, *args, password=password, **kwargs)


class CandidateUserFactory(UserFactory):
    """Factory for creating candidate users."""
    
    role = 'candidate'
    # Candidates can have either matric_number or staff_id


if Election:
    class ElectionFactory(DjangoModelFactory):
        """Factory for creating test elections."""
        
        class Meta:
            model = Election
            django_get_or_create = ('title',)
        
        title = factory.Sequence(lambda n: f'Test Election {n}')
        description = factory.Faker('text', max_nb_chars=200)
        start_time = factory.LazyFunction(lambda: timezone.now() + timedelta(hours=1))
        end_time = factory.LazyFunction(lambda: timezone.now() + timedelta(days=7))
        status = 'scheduled'
        created_by = factory.SubFactory(AdminUserFactory)
        delayed_reveal = False


if BallotToken:
    class BallotTokenFactory(DjangoModelFactory):
        """Factory for creating test ballot tokens."""
        
        class Meta:
            model = BallotToken
        
        user = factory.SubFactory(UserFactory)
        election = factory.SubFactory(ElectionFactory)
        token_uuid = factory.LazyFunction(uuid.uuid4)
        signature = factory.Faker('sha256')
        status = 'valid'
        issued_at = factory.LazyFunction(timezone.now)
        expires_at = factory.LazyFunction(lambda: timezone.now() + timedelta(hours=24))
        issued_ip = factory.Faker('ipv4')


if Vote:
    class VoteFactory(DjangoModelFactory):
        """Factory for creating test votes."""
        
        class Meta:
            model = Vote
        
        election = factory.SubFactory(ElectionFactory)
        anonymous_token = factory.LazyFunction(uuid.uuid4)
        encrypted_vote_data = factory.Faker('binary', length=256)
        encryption_nonce = factory.Faker('binary', length=12)
        vote_signature = factory.Faker('sha512')
        encryption_key_hash = factory.Faker('sha256')
        cast_at = factory.LazyFunction(timezone.now)
        verified = True


if AuditLog:
    class AuditLogFactory(DjangoModelFactory):
        """Factory for creating test audit logs."""
        
        class Meta:
            model = AuditLog
        
        action_type = 'user_login'
        action_description = factory.Faker('sentence')
        outcome = 'success'
        user = factory.SubFactory(UserFactory)
        user_identifier = factory.LazyAttribute(lambda obj: obj.user.email if obj.user else 'system')
        session_key = factory.Faker('uuid4')
        ip_address = factory.Faker('ipv4')
        user_agent = factory.Faker('user_agent')
        election = factory.SubFactory(ElectionFactory)
        target_resource_type = 'user'
        target_resource_id = factory.LazyAttribute(lambda obj: str(obj.user.id) if obj.user else 'system')
        metadata = factory.Dict({'action': 'login', 'success': True})
        timestamp = factory.LazyFunction(timezone.now)