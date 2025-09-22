"""
Votes views for electra_server.

This module contains API views for vote casting, verification, and management
in the electra voting system.
"""
import json
import logging
from typing import Dict, Any

from django.db import transaction
from django.utils import timezone
from rest_framework import generics, views, status
from rest_framework.request import Request
from rest_framework.response import Response

from electra_server.apps.ballots.models import BallotToken, BallotTokenUsageLog
from electra_server.apps.elections.models import Election
from .models import Vote, VoteToken, OfflineVoteQueue, VoteAuditLog
from .serializers import (
    VoteCastSerializer,
    VoteVerificationSerializer,
    OfflineVoteQueueSerializer,
    OfflineVoteSubmissionSerializer,
    VoteStatusSerializer,
    VoteAuditLogSerializer,
)
from .permissions import (
    CanCastVotes,
    CanVerifyVotes,
    CanManageOfflineVotes,
    CanViewAuditLogs,
)

logger = logging.getLogger(__name__)


class VoteCastView(views.APIView):
    """
    Vote casting endpoint.

    POST /api/votes/cast/

    Accepts encrypted vote data with ballot token validation.
    Ensures vote integrity, prevents double voting, and maintains anonymity.
    """

    permission_classes = [CanCastVotes]

    def post(self, request: Request, *args, **kwargs) -> Response:
        """
        Cast a vote with encrypted data and token validation.

        Args:
            request: HTTP request containing vote data

        Returns:
            Response: Vote casting result
        """
        serializer = VoteCastSerializer(data=request.data)

        if not serializer.is_valid():
            # Log failed attempt
            self._log_vote_action(
                action="cast_vote_failed",
                request=request,
                metadata={"errors": serializer.errors},
                result="failure",
            )
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data = serializer.validated_data

        try:
            with transaction.atomic():
                # Create anonymous vote token
                vote_token = validated_data["vote_token"]
                ballot_token = validated_data["ballot_token"]
                election = validated_data["election"]

                # Create vote token record
                vote_token_record = VoteToken.objects.create(
                    vote_token=vote_token,
                    ballot_token_hash=Vote.create_ballot_token_hash(ballot_token),
                    election=election,
                )

                # Create vote record
                vote = Vote.objects.create(
                    vote_token=vote_token,
                    encrypted_data=validated_data["encrypted_vote_data"],
                    encryption_nonce=validated_data["encryption_nonce"],
                    signature=validated_data["vote_signature"],
                    election=election,
                    ballot_token_hash=Vote.create_ballot_token_hash(ballot_token),
                    submitted_ip=self._get_client_ip(request),
                    encryption_key_hash=validated_data["encryption_key_hash"],
                )

                # Mark ballot token as used
                ballot_token.status = "used"
                ballot_token.save(update_fields=["status"])

                # Mark vote token as used
                vote_token_record.mark_as_used()

                # Log successful vote cast
                self._log_vote_action(
                    action="cast_vote",
                    request=request,
                    vote=vote,
                    ballot_token=ballot_token,
                    metadata={
                        "election_id": str(election.id),
                        "vote_token": str(vote_token),
                    },
                    result="success",
                )

                # Log ballot token usage
                BallotTokenUsageLog.objects.create(
                    ballot_token=ballot_token,
                    action="vote_cast",
                    ip_address=self._get_client_ip(request),
                    user_agent=request.META.get("HTTP_USER_AGENT", ""),
                    metadata={
                        "vote_id": str(vote.id),
                        "vote_token": str(vote_token),
                    },
                )

                logger.info(
                    "Vote cast successfully",
                    extra={
                        "vote_id": vote.id,
                        "election_id": election.id,
                        "vote_token": vote_token,
                        "ip_address": self._get_client_ip(request),
                    },
                )

                return Response(
                    {
                        "vote_token": vote_token,
                        "status": "cast",
                        "submitted_at": vote.submitted_at,
                        "message": "Vote cast successfully",
                    },
                    status=status.HTTP_201_CREATED,
                )

        except Exception as e:
            logger.error(
                "Failed to cast vote",
                extra={
                    "error": str(e),
                    "election_id": election.id,
                    "ip_address": self._get_client_ip(request),
                },
            )

            # Log failed attempt
            self._log_vote_action(
                action="cast_vote_error",
                request=request,
                metadata={"error": str(e)},
                result="error",
            )

            return Response(
                {
                    "error": "Failed to cast vote",
                    "detail": "An internal error occurred while processing your vote.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def _get_client_ip(self, request: Request) -> str:
        """
        Get client IP address from request.

        Args:
            request: HTTP request

        Returns:
            str: Client IP address
        """
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            ip = x_forwarded_for.split(",")[0].strip()
        else:
            ip = request.META.get("REMOTE_ADDR", "")
        return ip

    def _log_vote_action(
        self,
        action: str,
        request: Request,
        vote: Vote = None,
        ballot_token: BallotToken = None,
        metadata: Dict[str, Any] = None,
        result: str = "success",
    ) -> None:
        """
        Log vote-related action.

        Args:
            action: Action performed
            request: HTTP request
            vote: Vote object (optional)
            ballot_token: BallotToken object (optional)
            metadata: Additional metadata
            result: Action result
        """
        election = None
        vote_token = None
        ballot_token_hash = None

        if vote:
            election = vote.election
            vote_token = vote.vote_token
            ballot_token_hash = vote.ballot_token_hash
        elif ballot_token:
            election = ballot_token.election
            ballot_token_hash = Vote.create_ballot_token_hash(ballot_token)

        VoteAuditLog.objects.create(
            vote=vote,
            action=action,
            election=election,
            vote_token=vote_token,
            ballot_token_hash=ballot_token_hash,
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get("HTTP_USER_AGENT", ""),
            metadata=metadata or {},
            result=result,
            error_details=metadata.get("error", "") if result == "error" else "",
        )


class VoteVerifyView(views.APIView):
    """
    Vote verification endpoint.

    POST /api/votes/verify/

    Verifies vote signature and integrity using anonymous vote token.
    """

    permission_classes = [CanVerifyVotes]

    def post(self, request: Request, *args, **kwargs) -> Response:
        """
        Verify a vote's signature and integrity.

        Args:
            request: HTTP request containing vote token

        Returns:
            Response: Vote verification result
        """
        serializer = VoteVerificationSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data = serializer.validated_data
        vote = validated_data["vote"]

        try:
            # Verify signature
            signature_valid = vote.verify_signature()

            # Log verification attempt
            self._log_vote_action(
                action="verify_vote",
                request=request,
                vote=vote,
                metadata={
                    "signature_valid": signature_valid,
                },
                result="success",
            )

            logger.info(
                "Vote verification completed",
                extra={
                    "vote_id": vote.id,
                    "vote_token": vote.vote_token,
                    "signature_valid": signature_valid,
                    "ip_address": self._get_client_ip(request),
                },
            )

            return Response(
                {
                    "vote_token": vote.vote_token,
                    "signature_valid": signature_valid,
                    "status": vote.status,
                    "submitted_at": vote.submitted_at,
                    "election": {
                        "id": vote.election.id,
                        "title": vote.election.title,
                    },
                    "verified_at": timezone.now(),
                }
            )

        except Exception as e:
            logger.error(
                "Failed to verify vote",
                extra={
                    "vote_id": vote.id,
                    "error": str(e),
                    "ip_address": self._get_client_ip(request),
                },
            )

            # Log failed verification
            self._log_vote_action(
                action="verify_vote_error",
                request=request,
                vote=vote,
                metadata={"error": str(e)},
                result="error",
            )

            return Response(
                {
                    "error": "Failed to verify vote",
                    "detail": "An internal error occurred during verification.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            ip = x_forwarded_for.split(",")[0].strip()
        else:
            ip = request.META.get("REMOTE_ADDR", "")
        return ip

    def _log_vote_action(
        self,
        action: str,
        request: Request,
        vote: Vote = None,
        metadata: Dict[str, Any] = None,
        result: str = "success",
    ) -> None:
        """Log vote-related action."""
        VoteAuditLog.objects.create(
            vote=vote,
            action=action,
            election=vote.election if vote else None,
            vote_token=vote.vote_token if vote else None,
            ballot_token_hash=vote.ballot_token_hash if vote else None,
            ip_address=self._get_client_ip(request),
            user_agent=request.META.get("HTTP_USER_AGENT", ""),
            metadata=metadata or {},
            result=result,
            error_details=metadata.get("error", "") if result == "error" else "",
        )


class OfflineVoteQueueView(generics.ListCreateAPIView):
    """
    Offline vote queue management.

    GET /api/votes/offline-queue/ - List offline queue entries
    POST /api/votes/offline-queue/ - Add entry to offline queue

    Handles offline voting scenarios where votes need to be queued
    for later synchronization.
    """

    serializer_class = OfflineVoteQueueSerializer
    permission_classes = [CanManageOfflineVotes]

    def get_queryset(self):
        """Get offline queue entries based on user permissions."""
        user = self.request.user

        # Admin roles can see all offline votes
        admin_roles = ["admin", "electoral_committee"]
        if hasattr(user, "role") and user.role in admin_roles:
            return OfflineVoteQueue.objects.select_related(
                "ballot_token__user", "ballot_token__election"
            ).all()
        else:
            # Regular users can only see their own offline votes
            return OfflineVoteQueue.objects.filter(
                ballot_token__user=user
            ).select_related("ballot_token__election")

    def perform_create(self, serializer):
        """Create offline vote queue entry with proper user association."""
        # Note: In a real implementation, you'd need to validate the ballot token
        # and associate it properly. For now, this is a placeholder.
        serializer.save()


class OfflineVoteSubmissionView(views.APIView):
    """
    Offline vote submission synchronization.

    POST /api/votes/offline-submit/

    Processes votes that were cast offline and synchronizes them
    back to the server when connectivity is restored.
    """

    permission_classes = [CanManageOfflineVotes]

    def post(self, request: Request, *args, **kwargs) -> Response:
        """
        Submit offline vote for synchronization.

        Args:
            request: HTTP request containing offline vote data

        Returns:
            Response: Synchronization result
        """
        serializer = OfflineVoteSubmissionSerializer(data=request.data)

        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        validated_data = serializer.validated_data
        ballot_token = validated_data["ballot_token"]
        election = validated_data["election"]

        try:
            with transaction.atomic():
                # Create or update offline queue entry
                queue_entry, created = OfflineVoteQueue.objects.get_or_create(
                    ballot_token=ballot_token,
                    defaults={
                        "encrypted_vote_data": validated_data["encrypted_vote_data"],
                        "client_timestamp": validated_data["client_timestamp"],
                        "client_ip": self._get_client_ip(request),
                    },
                )

                if not created:
                    # Update existing entry
                    queue_entry.encrypted_vote_data = validated_data[
                        "encrypted_vote_data"
                    ]
                    queue_entry.client_timestamp = validated_data["client_timestamp"]
                    queue_entry.save(
                        update_fields=["encrypted_vote_data", "client_timestamp"]
                    )

                # Mark as synced (since we're processing it now)
                queue_entry.mark_as_synced("Offline vote queued for processing")

                # Log the submission
                BallotTokenUsageLog.objects.create(
                    ballot_token=ballot_token,
                    action="offline_submission",
                    ip_address=self._get_client_ip(request),
                    user_agent=request.META.get("HTTP_USER_AGENT", ""),
                    metadata={
                        "queue_entry_id": str(queue_entry.id),
                        "client_timestamp": validated_data[
                            "client_timestamp"
                        ].isoformat(),
                    },
                )

                logger.info(
                    "Offline vote submitted successfully",
                    extra={
                        "ballot_token_id": ballot_token.id,
                        "election_id": election.id,
                        "queue_entry_id": queue_entry.id,
                        "ip_address": self._get_client_ip(request),
                    },
                )

                return Response(
                    {
                        "queue_entry_id": queue_entry.id,
                        "status": "queued",
                        "message": "Offline vote submitted successfully",
                    },
                    status=status.HTTP_201_CREATED,
                )

        except Exception as e:
            logger.error(
                "Failed to submit offline vote",
                extra={
                    "error": str(e),
                    "ballot_token_id": ballot_token.id,
                    "ip_address": self._get_client_ip(request),
                },
            )

            return Response(
                {
                    "error": "Failed to submit offline vote",
                    "detail": "An internal error occurred while processing your offline vote.",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def _get_client_ip(self, request: Request) -> str:
        """Get client IP address from request."""
        x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
        if x_forwarded_for:
            ip = x_forwarded_for.split(",")[0].strip()
        else:
            ip = request.META.get("REMOTE_ADDR", "")
        return ip


class VoteStatusView(generics.RetrieveAPIView):
    """
    Vote status information.

    GET /api/votes/status/<vote_token>/

    Provides status information for a specific vote using vote token.
    """

    serializer_class = VoteStatusSerializer
    permission_classes = [CanVerifyVotes]
    lookup_field = "vote_token"
    lookup_url_kwarg = "vote_token"

    def get_queryset(self):
        """Get votes based on user permissions."""
        return Vote.objects.select_related("election").all()


class VoteAuditLogView(generics.ListAPIView):
    """
    Vote audit log viewing.

    GET /api/votes/audit-logs/

    Provides audit log information for administrators.
    """

    serializer_class = VoteAuditLogSerializer
    permission_classes = [CanViewAuditLogs]

    def get_queryset(self):
        """Get audit logs with filtering options."""
        queryset = VoteAuditLog.objects.select_related("vote", "election").all()

        # Filter by election if specified
        election_id = self.request.query_params.get("election_id")
        if election_id:
            queryset = queryset.filter(election__id=election_id)

        # Filter by action if specified
        action = self.request.query_params.get("action")
        if action:
            queryset = queryset.filter(action=action)

        # Filter by result if specified
        result = self.request.query_params.get("result")
        if result:
            queryset = queryset.filter(result=result)

        return queryset
