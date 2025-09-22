"""
Test serializers for votes app.

Contains serializer tests for vote casting, verification, and management.
"""
import json
import secrets
import uuid
from base64 import b64encode
from datetime import timedelta

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from django.conf import settings
from django.test import TestCase
from django.utils import timezone

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import ElectionStatus
from electra_server.apps.ballots.models import BallotToken
from electra_server.apps.votes.models import Vote, OfflineVoteQueue
from electra_server.apps.votes.serializers import (
    VoteCastSerializer,
    VoteVerificationSerializer,
    OfflineVoteQueueSerializer,
    OfflineVoteSubmissionSerializer,
    VoteStatusSerializer,
)
from .test_models import UserFactory, ElectionFactory, BallotTokenFactory


class VoteCastSerializerTest(TestCase):
    """Test cases for VoteCastSerializer."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory(role=UserRole.STUDENT)
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(
            user=self.user, election=self.election, status="issued"
        )

        # Generate ballot token signature
        self.ballot_token.signature = self.ballot_token.create_signature()
        self.ballot_token.save()

        # Create test vote data
        self.vote_data = {
            "candidate_id": str(uuid.uuid4()),
            "preferences": ["choice1", "choice2"],
        }

        # Generate AES key and encrypt data
        self.aes_key = secrets.token_bytes(32)
        self.encrypted_data, self.nonce = self._encrypt_vote_data(self.vote_data)
        self.vote_signature = self._create_vote_signature()

        self.valid_data = {
            "token_uuid": str(self.ballot_token.token_uuid),
            "token_signature": self.ballot_token.signature,
            "election_id": str(self.election.id),
            "encrypted_vote_data": self.encrypted_data,
            "encryption_nonce": self.nonce,
            "vote_signature": self.vote_signature,
            "encryption_key_hash": "test_key_hash",
        }

    def _encrypt_vote_data(self, data):
        """Encrypt vote data with AES-256-GCM."""
        aesgcm = AESGCM(self.aes_key)
        nonce = secrets.token_bytes(12)

        json_data = json.dumps(data)
        encrypted = aesgcm.encrypt(nonce, json_data.encode(), None)

        return b64encode(encrypted).decode(), b64encode(nonce).decode()

    def _create_vote_signature(self):
        """Create RSA signature for vote."""
        private_key_path = settings.BASE_DIR / settings.RSA_PRIVATE_KEY_PATH
        with open(private_key_path, "rb") as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(), password=None
            )

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

    def test_valid_data(self):
        """Test serializer with valid data."""
        serializer = VoteCastSerializer(data=self.valid_data)
        self.assertTrue(serializer.is_valid())

        validated_data = serializer.validated_data
        self.assertEqual(validated_data["ballot_token"], self.ballot_token)
        self.assertEqual(validated_data["election"], self.election)
        self.assertIn("vote_token", validated_data)

    def test_invalid_token_uuid(self):
        """Test serializer with invalid token UUID."""
        invalid_data = self.valid_data.copy()
        invalid_data["token_uuid"] = str(uuid.uuid4())

        serializer = VoteCastSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("token_uuid", serializer.errors)

    def test_invalid_election_id(self):
        """Test serializer with invalid election ID."""
        invalid_data = self.valid_data.copy()
        invalid_data["election_id"] = str(uuid.uuid4())

        serializer = VoteCastSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("election_id", serializer.errors)

    def test_inactive_election(self):
        """Test serializer with inactive election."""
        self.election.status = ElectionStatus.COMPLETED
        self.election.save()

        serializer = VoteCastSerializer(data=self.valid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("election_id", serializer.errors)

    def test_token_election_mismatch(self):
        """Test serializer with token-election mismatch."""
        other_election = ElectionFactory()

        invalid_data = self.valid_data.copy()
        invalid_data["election_id"] = str(other_election.id)

        serializer = VoteCastSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_invalid_token_signature(self):
        """Test serializer with invalid token signature."""
        invalid_data = self.valid_data.copy()
        invalid_data["token_signature"] = "invalid_signature"

        serializer = VoteCastSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_used_token(self):
        """Test serializer with already used token."""
        self.ballot_token.status = "used"
        self.ballot_token.save()

        serializer = VoteCastSerializer(data=self.valid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_invalid_base64_data(self):
        """Test serializer with invalid base64 encoded data."""
        invalid_data = self.valid_data.copy()
        invalid_data["encrypted_vote_data"] = "not_base64!"

        serializer = VoteCastSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)


class VoteVerificationSerializerTest(TestCase):
    """Test cases for VoteVerificationSerializer."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create a vote
        self.vote_token = Vote.create_anonymous_vote_token(self.ballot_token)
        self.vote = Vote.objects.create(
            vote_token=self.vote_token,
            encrypted_data="encrypted_test_data",
            encryption_nonce="test_nonce",
            signature="test_signature",
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        self.valid_data = {
            "vote_token": str(self.vote_token),
            "election_id": str(self.election.id),
        }

    def test_valid_data(self):
        """Test serializer with valid data."""
        serializer = VoteVerificationSerializer(data=self.valid_data)
        self.assertTrue(serializer.is_valid())

        validated_data = serializer.validated_data
        self.assertEqual(validated_data["vote"], self.vote)

    def test_invalid_vote_token(self):
        """Test serializer with invalid vote token."""
        invalid_data = self.valid_data.copy()
        invalid_data["vote_token"] = str(uuid.uuid4())

        serializer = VoteVerificationSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_invalid_election_id(self):
        """Test serializer with invalid election ID."""
        invalid_data = self.valid_data.copy()
        invalid_data["election_id"] = str(uuid.uuid4())

        serializer = VoteVerificationSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)


class OfflineVoteQueueSerializerTest(TestCase):
    """Test cases for OfflineVoteQueueSerializer."""

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

        self.queue_entry = OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now() - timedelta(minutes=10),
            client_ip="192.168.1.1",
        )

    def test_serialization(self):
        """Test serializing offline queue entry."""
        serializer = OfflineVoteQueueSerializer(instance=self.queue_entry)
        data = serializer.data

        self.assertEqual(data["id"], str(self.queue_entry.id))
        self.assertEqual(data["ballot_token_uuid"], str(self.ballot_token.token_uuid))
        self.assertEqual(data["election_title"], self.election.title)
        self.assertEqual(data["encrypted_vote_data"], self.encrypted_vote_data)
        self.assertFalse(data["is_synced"])
        self.assertEqual(data["client_ip"], "192.168.1.1")


class OfflineVoteSubmissionSerializerTest(TestCase):
    """Test cases for OfflineVoteSubmissionSerializer."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(
            user=self.user, election=self.election, status="issued"
        )

        # Generate ballot token signature
        self.ballot_token.signature = self.ballot_token.create_signature()
        self.ballot_token.save()

        self.encrypted_vote_data = {
            "election_id": str(self.election.id),
            "encrypted_vote_data": "encrypted_data_here",
            "encryption_nonce": "nonce_here",
            "vote_signature": "signature_here",
            "encryption_key_hash": "key_hash_here",
        }

        self.valid_data = {
            "token_uuid": str(self.ballot_token.token_uuid),
            "token_signature": self.ballot_token.signature,
            "encrypted_vote_data": self.encrypted_vote_data,
            "client_timestamp": timezone.now().isoformat(),
        }

    def test_valid_data(self):
        """Test serializer with valid data."""
        serializer = OfflineVoteSubmissionSerializer(data=self.valid_data)
        self.assertTrue(serializer.is_valid())

        validated_data = serializer.validated_data
        self.assertEqual(validated_data["ballot_token"], self.ballot_token)
        self.assertEqual(validated_data["election"], self.election)

    def test_invalid_token_uuid(self):
        """Test serializer with invalid token UUID."""
        invalid_data = self.valid_data.copy()
        invalid_data["token_uuid"] = str(uuid.uuid4())

        serializer = OfflineVoteSubmissionSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("token_uuid", serializer.errors)

    def test_invalid_token_signature(self):
        """Test serializer with invalid token signature."""
        invalid_data = self.valid_data.copy()
        invalid_data["token_signature"] = "invalid_signature"

        serializer = OfflineVoteSubmissionSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_missing_required_fields(self):
        """Test serializer with missing required fields in vote data."""
        invalid_vote_data = {
            "election_id": str(self.election.id),
            # Missing other required fields
        }

        invalid_data = self.valid_data.copy()
        invalid_data["encrypted_vote_data"] = invalid_vote_data

        serializer = OfflineVoteSubmissionSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)

    def test_election_token_mismatch(self):
        """Test serializer with election-token mismatch."""
        other_election = ElectionFactory()

        invalid_vote_data = self.encrypted_vote_data.copy()
        invalid_vote_data["election_id"] = str(other_election.id)

        invalid_data = self.valid_data.copy()
        invalid_data["encrypted_vote_data"] = invalid_vote_data

        serializer = OfflineVoteSubmissionSerializer(data=invalid_data)
        self.assertFalse(serializer.is_valid())
        self.assertIn("non_field_errors", serializer.errors)


class VoteStatusSerializerTest(TestCase):
    """Test cases for VoteStatusSerializer."""

    def setUp(self):
        """Set up test data."""
        self.user = UserFactory()
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create a vote with proper signature
        self.vote_token = Vote.create_anonymous_vote_token(self.ballot_token)
        self.vote_signature = self._create_vote_signature()

        self.vote = Vote.objects.create(
            vote_token=self.vote_token,
            encrypted_data="encrypted_test_data",
            encryption_nonce="test_nonce",
            signature=self.vote_signature,
            election=self.election,
            ballot_token_hash=Vote.create_ballot_token_hash(self.ballot_token),
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

    def _create_vote_signature(self):
        """Create RSA signature for vote."""
        private_key_path = settings.BASE_DIR / settings.RSA_PRIVATE_KEY_PATH
        with open(private_key_path, "rb") as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(), password=None
            )

        signature_data = {
            "vote_token": str(self.vote_token),
            "encrypted_data": "encrypted_test_data",
            "election_id": str(self.election.id),
            "encryption_nonce": "test_nonce",
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

    def test_serialization(self):
        """Test serializing vote status."""
        serializer = VoteStatusSerializer(instance=self.vote)
        data = serializer.data

        self.assertEqual(data["id"], str(self.vote.id))
        self.assertEqual(data["vote_token"], str(self.vote_token))
        self.assertEqual(data["election_id"], str(self.election.id))
        self.assertEqual(data["election_title"], self.election.title)
        self.assertEqual(data["status"], "cast")
        self.assertTrue(data["signature_valid"])
        self.assertIn("submitted_at", data)

    def test_signature_validation(self):
        """Test signature validation in serialization."""
        # Create vote with invalid signature
        invalid_vote = Vote.objects.create(
            vote_token=uuid.uuid4(),
            encrypted_data="encrypted_test_data",
            encryption_nonce="test_nonce",
            signature="invalid_signature",
            election=self.election,
            ballot_token_hash="test_hash",
            submitted_ip="127.0.0.1",
            encryption_key_hash="test_key_hash",
        )

        serializer = VoteStatusSerializer(instance=invalid_vote)
        data = serializer.data

        self.assertFalse(data["signature_valid"])
