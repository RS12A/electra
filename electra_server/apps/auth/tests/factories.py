"""
Test factories for authentication models.

This module contains factory classes for creating test instances
of authentication models using factory_boy.
"""
import factory
from factory import Faker, SubFactory
from django.contrib.auth.hashers import make_password

from ..models import User, UserRole, PasswordResetOTP, LoginAttempt


class UserFactory(factory.django.DjangoModelFactory):
    """Factory for User model."""
    
    class Meta:
        model = User
    
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
            return f"U{factory.Faker('random_number', digits=7, fix_len=True).generate({})}"
        return None
    
    @factory.lazy_attribute
    def staff_id(self):
        """Generate staff ID for staff/admin."""
        if self.role in [UserRole.STAFF, UserRole.ADMIN, UserRole.ELECTORAL_COMMITTEE]:
            return f"ST{factory.Faker('random_number', digits=6, fix_len=True).generate({})}"
        return None
    
    @factory.post_generation
    def password(self, create, extracted, **kwargs):
        """Set password for user."""
        if not create:
            return
        
        password = extracted or 'TestPassword123'
        self.set_password(password)
        self.save()


class StudentUserFactory(UserFactory):
    """Factory for Student users."""
    
    role = UserRole.STUDENT
    matric_number = factory.LazyAttribute(
        lambda obj: f"U{factory.Faker('random_number', digits=7, fix_len=True).generate({})}"
    )
    staff_id = None


class StaffUserFactory(UserFactory):
    """Factory for Staff users."""
    
    role = UserRole.STAFF
    staff_id = factory.LazyAttribute(
        lambda obj: f"ST{factory.Faker('random_number', digits=6, fix_len=True).generate({})}"
    )
    matric_number = None


class AdminUserFactory(UserFactory):
    """Factory for Admin users."""
    
    role = UserRole.ADMIN
    is_staff = True
    is_superuser = True
    staff_id = factory.LazyAttribute(
        lambda obj: f"AD{factory.Faker('random_number', digits=6, fix_len=True).generate({})}"
    )
    matric_number = None


class ElectoralCommitteeUserFactory(UserFactory):
    """Factory for Electoral Committee users."""
    
    role = UserRole.ELECTORAL_COMMITTEE
    is_staff = True
    staff_id = factory.LazyAttribute(
        lambda obj: f"EC{factory.Faker('random_number', digits=6, fix_len=True).generate({})}"
    )
    matric_number = None


class CandidateUserFactory(UserFactory):
    """Factory for Candidate users."""
    
    role = UserRole.CANDIDATE
    
    @factory.lazy_attribute
    def matric_number(self):
        """Candidates can be students."""
        return f"U{factory.Faker('random_number', digits=7, fix_len=True).generate({})}"
    
    @factory.lazy_attribute
    def staff_id(self):
        """Or staff members."""
        return None


class PasswordResetOTPFactory(factory.django.DjangoModelFactory):
    """Factory for PasswordResetOTP model."""
    
    class Meta:
        model = PasswordResetOTP
    
    user = SubFactory(UserFactory)
    otp_code = factory.LazyAttribute(
        lambda obj: f"{factory.Faker('random_number', digits=6, fix_len=True).generate({})}"
    )
    expires_at = factory.LazyAttribute(
        lambda obj: factory.Faker('future_datetime', end_date='+1d').generate({})
    )
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
    user = SubFactory(UserFactory)


class FailedLoginAttemptFactory(LoginAttemptFactory):
    """Factory for failed login attempts."""
    
    success = False
    failure_reason = 'Invalid credentials'
    user = None