"""
Test views for votes app.

Contains API view tests for vote casting, verification, and management.
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
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APIClient

from electra_server.apps.auth.models import UserRole
from electra_server.apps.elections.models import Election, ElectionStatus
from electra_server.apps.ballots.models import BallotToken
from electra_server.apps.votes.models import (
    Vote,
    VoteToken,
    OfflineVoteQueue,
    VoteAuditLog,
)
from .test_models import UserFactory, ElectionFactory, BallotTokenFactory

User = get_user_model()


class VoteCastViewTest(TestCase):
    """Test cases for VoteCastView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
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

        # Prepare request data
        self.cast_data = {
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

    def test_cast_vote_success(self):
        """Test successful vote casting."""
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("vote_token", response.data)
        self.assertEqual(response.data["status"], "cast")

        # Verify vote was created
        vote_token = uuid.UUID(response.data["vote_token"])
        vote = Vote.objects.get(vote_token=vote_token)
        self.assertEqual(vote.election, self.election)
        self.assertTrue(vote.verify_signature())

        # Verify ballot token was marked as used
        self.ballot_token.refresh_from_db()
        self.assertEqual(self.ballot_token.status, "used")

        # Verify vote token was created and used
        vote_token_record = VoteToken.objects.get(vote_token=vote_token)
        self.assertTrue(vote_token_record.is_used)

    def test_cast_vote_unauthenticated(self):
        """Test vote casting without authentication."""
        response = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_cast_vote_invalid_role(self):
        """Test vote casting with invalid user role."""
        admin_user = UserFactory(role=UserRole.ADMIN)
        self.client.force_authenticate(user=admin_user)

        response = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_cast_vote_invalid_token(self):
        """Test vote casting with invalid ballot token."""
        self.client.force_authenticate(user=self.user)

        invalid_data = self.cast_data.copy()
        invalid_data["token_uuid"] = str(uuid.uuid4())

        response = self.client.post(
            reverse("votes:vote-cast"), data=invalid_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("token_uuid", response.data)

    def test_cast_vote_already_used_token(self):
        """Test vote casting with already used ballot token."""
        self.client.force_authenticate(user=self.user)

        # Mark token as used
        self.ballot_token.status = "used"
        self.ballot_token.save()

        response = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cast_vote_election_not_active(self):
        """Test vote casting for inactive election."""
        self.client.force_authenticate(user=self.user)

        # Make election inactive
        self.election.status = ElectionStatus.COMPLETED
        self.election.save()

        response = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cast_vote_duplicate(self):
        """Test preventing duplicate vote casting."""
        self.client.force_authenticate(user=self.user)

        # Cast first vote
        response1 = self.client.post(
            reverse("votes:vote-cast"), data=self.cast_data, format="json"
        )
        self.assertEqual(response1.status_code, status.HTTP_201_CREATED)

        # Try to cast second vote with same token (should fail)
        # Note: This would normally fail at the ballot token level since it's marked as used
        # But let's test the vote-level duplicate detection too

        # Create new ballot token for same user/election
        new_ballot_token = BallotTokenFactory(
            user=self.user, election=self.election, status="issued"
        )
        new_ballot_token.signature = new_ballot_token.create_signature()
        new_ballot_token.save()

        # The anonymous vote token should be the same, so this should be detected as duplicate
        duplicate_data = self.cast_data.copy()
        duplicate_data["token_uuid"] = str(new_ballot_token.token_uuid)
        duplicate_data["token_signature"] = new_ballot_token.signature

        response2 = self.client.post(
            reverse("votes:vote-cast"), data=duplicate_data, format="json"
        )

        # This should fail due to duplicate vote token
        self.assertEqual(response2.status_code, status.HTTP_400_BAD_REQUEST)


class VoteVerifyViewTest(TestCase):
    """Test cases for VoteVerifyView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        self.user = UserFactory(role=UserRole.STUDENT)
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create a vote
        self.vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        # Create proper vote signature
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

    def test_verify_vote_success(self):
        """Test successful vote verification."""
        self.client.force_authenticate(user=self.user)

        verify_data = {
            "vote_token": str(self.vote_token),
            "election_id": str(self.election.id),
        }

        response = self.client.post(
            reverse("votes:vote-verify"), data=verify_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["vote_token"], str(self.vote_token))
        self.assertTrue(response.data["signature_valid"])
        self.assertEqual(response.data["status"], "cast")

    def test_verify_vote_not_found(self):
        """Test vote verification with non-existent vote token."""
        self.client.force_authenticate(user=self.user)

        verify_data = {
            "vote_token": str(uuid.uuid4()),
            "election_id": str(self.election.id),
        }

        response = self.client.post(
            reverse("votes:vote-verify"), data=verify_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_verify_vote_unauthenticated(self):
        """Test vote verification without authentication."""
        verify_data = {
            "vote_token": str(self.vote_token),
            "election_id": str(self.election.id),
        }

        response = self.client.post(
            reverse("votes:vote-verify"), data=verify_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class OfflineVoteQueueViewTest(TestCase):
    """Test cases for OfflineVoteQueueView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        self.user = UserFactory(role=UserRole.STUDENT)
        self.admin_user = UserFactory(role=UserRole.ADMIN)
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        self.encrypted_vote_data = {
            "election_id": str(self.election.id),
            "encrypted_vote_data": "encrypted_data_here",
            "encryption_nonce": "nonce_here",
            "vote_signature": "signature_here",
            "encryption_key_hash": "key_hash_here",
        }

    def test_list_offline_queue_user(self):
        """Test listing offline queue entries for regular user."""
        # Create offline vote queue entry for user
        OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now(),
        )

        # Create entry for another user (should not be visible)
        other_user = UserFactory()
        other_token = BallotTokenFactory(user=other_user, election=self.election)
        OfflineVoteQueue.objects.create(
            ballot_token=other_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now(),
        )

        self.client.force_authenticate(user=self.user)
        response = self.client.get(reverse("votes:offline-vote-queue"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(
            response.data["results"][0]["ballot_token_uuid"],
            str(self.ballot_token.token_uuid),
        )

    def test_list_offline_queue_admin(self):
        """Test listing offline queue entries for admin user."""
        # Create offline vote queue entries
        OfflineVoteQueue.objects.create(
            ballot_token=self.ballot_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now(),
        )

        other_user = UserFactory()
        other_token = BallotTokenFactory(user=other_user, election=self.election)
        OfflineVoteQueue.objects.create(
            ballot_token=other_token,
            encrypted_vote_data=self.encrypted_vote_data,
            client_timestamp=timezone.now(),
        )

        self.client.force_authenticate(user=self.admin_user)
        response = self.client.get(reverse("votes:offline-vote-queue"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Admin should see all entries
        self.assertEqual(len(response.data["results"]), 2)


class OfflineVoteSubmissionViewTest(TestCase):
    """Test cases for OfflineVoteSubmissionView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        self.user = UserFactory(role=UserRole.STUDENT)
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

        self.submission_data = {
            "token_uuid": str(self.ballot_token.token_uuid),
            "token_signature": self.ballot_token.signature,
            "encrypted_vote_data": self.encrypted_vote_data,
            "client_timestamp": timezone.now().isoformat(),
        }

    def test_offline_vote_submission_success(self):
        """Test successful offline vote submission."""
        self.client.force_authenticate(user=self.user)

        response = self.client.post(
            reverse("votes:offline-vote-submit"),
            data=self.submission_data,
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("queue_entry_id", response.data)
        self.assertEqual(response.data["status"], "queued")

        # Verify queue entry was created
        queue_entry = OfflineVoteQueue.objects.get(ballot_token=self.ballot_token)
        self.assertEqual(queue_entry.encrypted_vote_data, self.encrypted_vote_data)
        self.assertTrue(queue_entry.is_synced)

    def test_offline_vote_submission_invalid_token(self):
        """Test offline vote submission with invalid token."""
        self.client.force_authenticate(user=self.user)

        invalid_data = self.submission_data.copy()
        invalid_data["token_uuid"] = str(uuid.uuid4())

        response = self.client.post(
            reverse("votes:offline-vote-submit"), data=invalid_data, format="json"
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_offline_vote_submission_unauthenticated(self):
        """Test offline vote submission without authentication."""
        response = self.client.post(
            reverse("votes:offline-vote-submit"),
            data=self.submission_data,
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class VoteStatusViewTest(TestCase):
    """Test cases for VoteStatusView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        self.user = UserFactory(role=UserRole.STUDENT)
        self.election = ElectionFactory()
        self.ballot_token = BallotTokenFactory(user=self.user, election=self.election)

        # Create a vote
        self.vote_token = Vote.create_anonymous_vote_token(self.ballot_token)

        # Create proper vote signature
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

    def test_get_vote_status_success(self):
        """Test getting vote status successfully."""
        self.client.force_authenticate(user=self.user)

        response = self.client.get(
            reverse("votes:vote-status", kwargs={"vote_token": self.vote_token})
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["vote_token"], str(self.vote_token))
        self.assertEqual(response.data["status"], "cast")
        self.assertTrue(response.data["signature_valid"])

    def test_get_vote_status_not_found(self):
        """Test getting status for non-existent vote."""
        self.client.force_authenticate(user=self.user)

        response = self.client.get(
            reverse("votes:vote-status", kwargs={"vote_token": uuid.uuid4()})
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_get_vote_status_unauthenticated(self):
        """Test getting vote status without authentication."""
        response = self.client.get(
            reverse("votes:vote-status", kwargs={"vote_token": self.vote_token})
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class VoteAuditLogViewTest(TestCase):
    """Test cases for VoteAuditLogView."""

    def setUp(self):
        """Set up test data."""
        self.client = APIClient()
        self.admin_user = UserFactory(role=UserRole.ADMIN)
        self.regular_user = UserFactory(role=UserRole.STUDENT)
        self.election = ElectionFactory()

        # Create audit log entries
        VoteAuditLog.objects.create(
            action="cast_vote",
            election=self.election,
            ip_address="127.0.0.1",
            user_agent="test-agent",
            result="success",
        )

        VoteAuditLog.objects.create(
            action="verify_vote",
            election=self.election,
            ip_address="192.168.1.1",
            user_agent="test-agent",
            result="success",
        )

    def test_list_audit_logs_admin(self):
        """Test listing audit logs as admin."""
        self.client.force_authenticate(user=self.admin_user)

        response = self.client.get(reverse("votes:vote-audit-logs"))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 2)

    def test_list_audit_logs_regular_user(self):
        """Test listing audit logs as regular user (should be forbidden)."""
        self.client.force_authenticate(user=self.regular_user)

        response = self.client.get(reverse("votes:vote-audit-logs"))

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_list_audit_logs_with_filters(self):
        """Test listing audit logs with filters."""
        self.client.force_authenticate(user=self.admin_user)

        # Filter by action
        response = self.client.get(
            reverse("votes:vote-audit-logs"), {"action": "cast_vote"}
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data["results"]), 1)
        self.assertEqual(response.data["results"][0]["action"], "cast_vote")

    def test_list_audit_logs_unauthenticated(self):
        """Test listing audit logs without authentication."""
        response = self.client.get(reverse("votes:vote-audit-logs"))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
