"""
Test factories for authentication models.

This module contains factory classes for creating test instances
of authentication models using factory_boy.
"""
import factory
from factory import Faker, SubFactory, LazyFunction, Sequence
from datetime import timedelta
from django.utils import timezone
from faker import Faker as FakerLib

from ..models import User, UserRole, PasswordResetOTP, LoginAttempt

# Create faker instance  
fake = FakerLib()


class UserFactory(factory.django.DjangoModelFactory):
    """Factory for User model."""
    
    class Meta:
        model = User
        django_get_or_create = ('email',)
    
    email = Faker('email')
    full_name = Faker('name')
    role = UserRole.STUDENT
    is_active = True
    is_staff = False
    is_superuser = False
    
    @factory.lazy_attribute
    def matric_number(self):
        """Generate matric number for students."""
        if self.role == UserRole.STUDENT:
            return f"U{fake.random_int(min=1000000, max=9999999)}"
        return None
    
    @factory.lazy_attribute
    def staff_id(self):
        """Generate staff ID for staff/admin."""
        if self.role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            return f"ST{fake.random_int(min=100000, max=999999)}"
        return None
    
    @classmethod
    def _create(cls, model_class, *args, **kwargs):
        """Override _create to set password before save."""
        password = kwargs.pop('password', 'TestPassword123')
        user = model_class(*args, **kwargs)
        user.set_password(password)
        user.save(skip_validation=True)  # Skip validation for factory creation
        return user


class StudentUserFactory(UserFactory):
    """Factory for Student users."""
    
    role = UserRole.STUDENT
    matric_number = Sequence(lambda n: f"U{1000000 + n}")
    staff_id = None


class StaffUserFactory(UserFactory):
    """Factory for Staff users."""
    
    role = UserRole.STAFF  
    staff_id = Sequence(lambda n: f"ST{100000 + n}")
    matric_number = None


class AdminUserFactory(UserFactory):
    """Factory for Admin users."""
    
    role = UserRole.ADMIN
    is_staff = True
    is_superuser = True
    staff_id = Sequence(lambda n: f"AD{100000 + n}")
    matric_number = None


class ElectoralCommitteeUserFactory(UserFactory):
    """Factory for Electoral Committee users."""
    
    role = UserRole.ELECTORAL_COMMITTEE
    is_staff = True
    staff_id = Sequence(lambda n: f"EC{100000 + n}")
    matric_number = None


class CandidateUserFactory(UserFactory):
    """Factory for Candidate users."""
    
    role = UserRole.CANDIDATE
    matric_number = Sequence(lambda n: f"U{2000000 + n}")
    staff_id = None


class PasswordResetOTPFactory(factory.django.DjangoModelFactory):
    """Factory for PasswordResetOTP model."""
    
    class Meta:
        model = PasswordResetOTP
    
    user = SubFactory(StudentUserFactory)
    otp_code = Sequence(lambda n: f"{100000 + (n % 900000):06d}")
    expires_at = LazyFunction(lambda: timezone.now() + timedelta(minutes=15))
    is_used = False
    ip_address = Faker('ipv4')


class LoginAttemptFactory(factory.django.DjangoModelFactory):
    """Factory for LoginAttempt model."""
    
    class Meta:
        model = LoginAttempt
    
    email = Faker('email')
    ip_address = Faker('ipv4')
    user_agent = Faker('user_agent')
    success = True
    failure_reason = ''
    user = SubFactory(StudentUserFactory)


class FailedLoginAttemptFactory(LoginAttemptFactory):
    """Factory for failed login attempts."""
    
    success = False
    failure_reason = 'Invalid credentials'
    user = None