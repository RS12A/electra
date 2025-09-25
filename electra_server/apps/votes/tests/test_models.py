"""
Test models for votes app.

Contains model tests for vote casting, encryption, and anonymization.
"""
import json
import secrets
import uuid
from base64 import b64encode, b64decode
from datetime import timedelta

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.exceptions import ValidationError
from django.test import TestCase
from django.utils import timezone
from factory import SubFactory, Faker, LazyAttribute
from factory.django import DjangoModelFactory

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken
from electra_server.apps.votes.models import (
    Vote,
    VoteToken,
    OfflineVoteQueue,
    VoteAuditLog,
    VoteStatus,
)

User = get_user_model()


class UserFactory(DjangoModelFactory):
    """Factory for creating test users."""

    class Meta:
        model = User

    email = Faker("email")
    full_name = Faker("name")
    role = UserRole.STUDENT
    is_active = True
    matric_number = Faker("numerify", text="A#######")
    password = "testpassword123"


class AdminUserFactory(UserFactory):
    """Factory for creating test admin users with proper staff_id."""
    role = UserRole.ADMIN
    matric_number = None
    staff_id = Faker("numerify", text="ADM####")


class StaffUserFactory(UserFactory):
    """Factory for creating test staff users with proper staff_id."""
    role = UserRole.STAFF
    matric_number = None
    staff_id = Faker("numerify", text="STF####")


class ElectionFactory(DjangoModelFactory):
    """Factory for creating test elections."""

    class Meta:
        model = Election

    title = Faker("sentence", nb_words=3)
    description = Faker("text")
    start_time = LazyAttribute(lambda _: timezone.now() - timedelta(hours=1))
    end_time = LazyAttribute(lambda _: timezone.now() + timedelta(hours=2))
    status = ElectionStatus.ACTIVE
    created_by = SubFactory(AdminUserFactory)


class BallotTokenFactory(DjangoModelFactory):
    """Factory for creating test ballot tokens."""

    class Meta:
        model = BallotToken

    user = SubFactory(UserFactory)
    election = SubFactory(ElectionFactory)
    status = "issued"
    signature = "test_signature_data"
    issued_ip = "127.0.0.1"
    issued_user_agent = "test-agent/1.0"


class VoteModelTest(TestCase):
    """Test cases for Vote model."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create test vote data
        self.vote_data = {
            "candidate_id": str(uuid.uuid4()),
            "preferences": ["choice1", "choice2"],
        }

        # Generate AES key and encrypt data
        self.aes_key = secrets.token_bytes(32)  # 32 bytes = 256 bits
        self.encrypted_data, self.nonce = self._encrypt_vote_data(self.vote_data)

        # Create vote signature
        self.vote_signature = self._create_vote_signature()

    def _encrypt_vote_data(self, data):
        """Encrypt vote data with AES-256-GCM."""
        aesgcm = AESGCM(self.aes_key)
        nonce = secrets.token_bytes(12)  # 96-bit nonce for GCM

        json_data = json.dumps(data)
        encrypted = aesgcm.encrypt(nonce, json_data.encode(), None)

        return b64encode(encrypted).decode(), b64encode(nonce).decode()

    def _create_vote_signature(self):
        """Create RSA signature for vote."""
        # Load private key
        private_key_path = settings.BASE_DIR / settings.RSA_PRIVATE_KEY_PATH
        with open(private_key_path, "rb") as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(), password=None
            )

        # Create signature data
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)
        signature_data = {
            "vote_token": str(vote_token),
            "encrypted_data": self.encrypted_data,
            "election_id": str(self.election.id),
            "encryption_nonce": self.nonce,
        }

        data_string = json.dumps(signature_data, sort_keys=True)
        signature = private_key.sign(
            data_string.encode("utf-8"),
            padding.PSS(
                mgf=padding.MGF1(hashes.SHA256()), salt_length=padding.PSS.MAX_LENGTH
            ),
            hashes.SHA256(),
        )

        return b64encode(signature).decode()

    def test_create_vote(self):
        """Test creating a vote."""
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        vote = Vote.objects.create(
            vote_token=vote_token,
            encrypted_data=self.encrypted_data,
            encryption_nonce=self.nonce,
            signature=self.vote_signature,
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        self.assertEqual(vote.status, VoteStatus.CAST)
        self.assertEqual(vote.election, self.election)
        self.assertTrue(vote.verify_signature())

    def test_anonymous_vote_token_creation(self):
        """Test that anonymous vote tokens are deterministic but anonymous."""
        token1 = Vote.create_anonymous_vote_token(self.ballot_token)
        token2 = Vote.create_anonymous_vote_token(self.ballot_token)

        # Should be the same for the same ballot token
        self.assertEqual(token1, token2)

        # Should be different from the original ballot token
        self.assertNotEqual(token1, self.ballot_token.token_uuid)

    def test_ballot_token_hash_creation(self):
        """Test ballot token hash creation."""
        hash1 = Vote.create_ballot_token_hash(self.ballot_token)
        hash2 = Vote.create_ballot_token_hash(self.ballot_token)

        # Should be consistent
        self.assertEqual(hash1, hash2)
        self.assertEqual(len(hash1), 64)  # SHA-256 hex length

    def test_vote_signature_verification(self):
        """Test vote signature verification."""
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        vote = Vote.objects.create(
            vote_token=vote_token,
            encrypted_data=self.encrypted_data,
            encryption_nonce=self.nonce,
            signature=self.vote_signature,
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        self.assertTrue(vote.verify_signature())

    def test_vote_data_decryption(self):
        """Test vote data decryption."""
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        vote = Vote.objects.create(
            vote_token=vote_token,
            encrypted_data=self.encrypted_data,
            encryption_nonce=self.nonce,
            signature=self.vote_signature,
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        decrypted_data = vote.decrypt_vote_data(self.aes_key)
        self.assertEqual(decrypted_data, self.vote_data)

    def test_vote_unique_constraint(self):
        """Test that votes are unique per token per election."""
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        # Create first vote
        Vote.objects.create(
            vote_token=vote_token,
            encrypted_data=self.encrypted_data,
            encryption_nonce=self.nonce,
            signature=self.vote_signature,
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        # Attempt to create duplicate should fail
        with self.assertRaises(Exception):  # IntegrityError
            Vote.objects.create(
                vote_token=vote_token,
                encrypted_data=self.encrypted_data,
                encryption_nonce=self.nonce,
                signature=self.vote_signature,
                election=self.election,
                ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
                submitted_ip="127.0.0.1",
                encryption_key_hash="test_key_hash",
            )


class VoteTokenModelTest(TestCase):
    """Test cases for VoteToken model."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

    def test_create_vote_token(self):
        """Test creating a vote token."""
        vote_token_uuid = Vote.create_anonymous_vote_token(self.ballot_token)
        ballot_hash = Vote.create_ballot_token_hash(self.ballot_token)

        vote_token = VoteToken.objects.create(
            vote_token=vote_token_uuid,
            ballot_token_hash=ballot_hash,
            election=self.election,
        )

        self.assertEqual(vote_token.vote_token, vote_token_uuid)
        self.assertEqual(vote_token.election, self.election)
        self.assertFalse(vote_token.is_used)
        self.assertIsNone(vote_token.used_at)

    def test_mark_as_used(self):
        """Test marking vote token as used."""
        vote_token_uuid = Vote.create_anonymous_vote_token(self.ballot_token)
        ballot_hash = Vote.create_ballot_token_hash(self.ballot_token)

        vote_token = VoteToken.objects.create(
            vote_token=vote_token_uuid,
            ballot_token_hash=ballot_hash,
            election=self.election,
        )

        vote_token.mark_as_used()

        self.assertTrue(vote_token.is_used)
        self.assertIsNotNone(vote_token.used_at)

    def test_unique_constraint(self):
        """Test unique constraint per ballot/election."""
        vote_token_uuid = Vote.create_anonymous_vote_token(self.ballot_token)
        ballot_hash = Vote.create_ballot_token_hash(self.ballot_token)

        # Create first token
        VoteToken.objects.create(
            vote_token=vote_token_uuid,
            ballot_token_hash=ballot_hash,
            election=self.election,
        )

        # Attempt to create duplicate should fail
        with self.assertRaises(Exception):  # IntegrityError
            VoteToken.objects.create(
                vote_token=vote_token_uuid,
                ballot_token_hash=ballot_hash,
                election=self.election,
            )


class OfflineVoteQueueModelTest(TestCase):
    """Test cases for OfflineVoteQueue model."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        self.encrypted_vote_data = {
            "election_id": str(self.election.id),
            "encrypted_vote_data": "encrypted_data_here",
            "encryption_nonce": "nonce_here",
            "vote_signature": "signature_here",
            "encryption_key_hash": "key_hash_here",
        }

    def test_create_offline_vote_queue(self):
        """Test creating offline vote queue entry."""
        client_timestamp = timezone.now() - timedelta(minutes=10)

        queue_entry = OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=client_timestamp,
            client_ip="192.168.1.1",
        )

        self.assertEqual(queue_entry.ballot_token, self.ballot_token)
        self.assertEqual(queue_entry.encrypted_vote_data, self.encrypted_vote_data)
        self.assertFalse(queue_entry.is_synced)
        self.assertIsNone(queue_entry.synced_at)

    def test_mark_as_synced(self):
        """Test marking offline vote as synced."""
        queue_entry = OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now() - timedelta(minutes=10),
        )

        queue_entry.mark_as_synced("Successfully processed")

        self.assertTrue(queue_entry.is_synced)
        self.assertIsNotNone(queue_entry.synced_at)
        self.assertEqual(queue_entry.sync_result, "Successfully processed")

    def test_unique_pending_constraint(self):
        """Test unique pending offline vote per token."""
        # Create first pending entry
        OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now() - timedelta(minutes=10),
        )

        # Attempt to create another pending entry should fail
        with self.assertRaises(Exception):  # IntegrityError
            OfflineVoteQueue.objects.create(
                ballot_token=self.ballot_token,
                encrypted_vote_data=self.encrypted_vote_data,
                client_timestamp=timezone.now() - timedelta(minutes=5),
            )


class VoteAuditLogModelTest(TestCase):
    """Test cases for VoteAuditLog model."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create a vote for testing
        vote_token = Vote.create_anonymous_vote_token(self.ballot_token)
        self.vote = Vote.objects.create(
            vote_token=vote_token,
            encrypted_data="encrypted_data",
            encryption_nonce="nonce",
            signature="signature",
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="key_hash",
        )

    def test_create_audit_log(self):
        """Test creating vote audit log entry."""
        audit_log = VoteAuditLog.objects.create(
            vote=self.vote,
            action="cast_vote",
            election=self.election,
            vote_token=self.vote.vote_token,
            ballot_token_hash=self.vote.ballot_token_hash,
            ip_address="127.0.0.1",
            user_agent="test-agent",
            metadata={"test": "data"},
            result="success",
        )

        self.assertEqual(audit_log.vote, self.vote)
        self.assertEqual(audit_log.action, "cast_vote")
        self.assertEqual(audit_log.election, self.election)
        self.assertEqual(audit_log.result, "success")
        self.assertEqual(audit_log.metadata, {"test": "data"})

    def test_audit_log_without_vote(self):
        """Test creating audit log without specific vote reference."""
        audit_log = VoteAuditLog.objects.create(
            action="verify_vote_failed",
            election=self.election,
            ip_address="127.0.0.1",
            user_agent="test-agent",
            result="failure",
            error_details="Invalid token",
        )

        self.assertIsNone(audit_log.vote)
        self.assertEqual(audit_log.action, "verify_vote_failed")
        self.assertEqual(audit_log.result, "failure")
        self.assertEqual(audit_log.error_details, "Invalid token")
