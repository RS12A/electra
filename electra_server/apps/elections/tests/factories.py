"""
Test factories for elections app.

Factory classes for creating test instances of Election models
using factory_boy.
"""
import factory
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import timedelta

from ..models import Election, ElectionStatus

User = get_user_model()


class ElectionFactory(factory.django.DjangoModelFactory):
    """Factory for creating Election test instances."""
    
    class Meta:
        model = Election
    
    title = factory.Sequence(lambda n: f"Test Election {n}")
    description = factory.Faker('text', max_nb_chars=200)
    
    # Set start time 1 hour from now
    start_time = factory.LazyFunction(
        lambda: timezone.now() + timedelta(hours=1)
    )
    
    # Set end time 2 hours after start time
    end_time = factory.LazyAttribute(
        lambda obj: obj.start_time + timedelta(hours=2)
    )
    
    status = ElectionStatus.DRAFT
    delayed_reveal = False
    
    # Will need to be set explicitly in tests since User factory might not be available
    created_by = factory.SubFactory(
        'electra_server.apps.auth.tests.factories.AdminUserFactory'
    )


class DraftElectionFactory(ElectionFactory):
    """Factory for draft elections."""
    status = ElectionStatus.DRAFT


class ActiveElectionFactory(ElectionFactory):
    """Factory for active elections."""
    status = ElectionStatus.ACTIVE
    
    # Active elections should have started
    start_time = factory.LazyFunction(
        lambda: timezone.now() - timedelta(minutes=30)
    )
    
    end_time = factory.LazyAttribute(
        lambda obj: obj.start_time + timedelta(hours=2)
    )


class CompletedElectionFactory(ElectionFactory):
    """Factory for completed elections."""
    status = ElectionStatus.COMPLETED
    
    # Completed elections are in the past
    start_time = factory.LazyFunction(
        lambda: timezone.now() - timedelta(days=1)
    )
    
    end_time = factory.LazyAttribute(
        lambda obj: obj.start_time + timedelta(hours=2)
    )


class CancelledElectionFactory(ElectionFactory):
    """Factory for cancelled elections."""
    status = ElectionStatus.CANCELLED


class FutureElectionFactory(ElectionFactory):
    """Factory for elections scheduled in the future."""
    status = ElectionStatus.DRAFT
    
    start_time = factory.LazyFunction(
        lambda: timezone.now() + timedelta(days=7)
    )
    
    end_time = factory.LazyAttribute(
        lambda obj: obj.start_time + timedelta(hours=2)
    )


class PastElectionFactory(ElectionFactory):
    """Factory for elections that have ended."""
    status = ElectionStatus.COMPLETED
    
    start_time = factory.LazyFunction(
        lambda: timezone.now() - timedelta(days=2)
    )
    
    end_time = factory.LazyFunction(
        lambda: timezone.now() - timedelta(days=1)
    )


class OngoingElectionFactory(ElectionFactory):
    """Factory for elections currently in progress."""
    status = ElectionStatus.ACTIVE
    
    start_time = factory.LazyFunction(
        lambda: timezone.now() - timedelta(minutes=30)
    )
    
    end_time = factory.LazyFunction(
        lambda: timezone.now() + timedelta(hours=1)
    )