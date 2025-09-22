"""
Simple test for votes app setup.

Basic test to verify the votes app is configured correctly.
"""
from django.test import TestCase
from electra_server.apps.votes.models import Vote, VoteStatus


class VotesAppTest(TestCase):
    """Basic test cases for votes app setup."""

    def test_vote_status_choices(self):
        """Test that vote status choices are available."""
        self.assertEqual(VoteStatus.CAST, "cast")
        self.assertEqual(VoteStatus.VERIFIED, "verified")
        self.assertEqual(VoteStatus.INVALIDATED, "invalidated")

    def test_vote_model_exists(self):
        """Test that Vote model can be imported."""
        self.assertTrue(hasattr(Vote, "objects"))

    def test_vote_model_fields(self):
        """Test that Vote model has expected fields."""
        vote_fields = [field.name for field in Vote._meta.fields]

        expected_fields = [
            "id",
            "vote_token",
            "encrypted_data",
            "encryption_nonce",
            "signature",
            "election",
            "status",
            "ballot_token_hash",
            "submitted_at",
            "submitted_ip",
            "encryption_key_hash",
        ]

        for field in expected_fields:
            self.assertIn(
                field, vote_fields, f"Field '{field}' not found in Vote model"
            )
