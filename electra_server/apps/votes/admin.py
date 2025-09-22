"""
Votes admin configuration for electra_server.

This module contains Django admin configuration for vote models.
"""
from django.contrib import admin
from django.utils.html import format_html

from .models import Vote, VoteToken, OfflineVoteQueue, VoteAuditLog


@admin.register(Vote)
class VoteAdmin(admin.ModelAdmin):
    """Admin interface for Vote model."""

    list_display = [
        "vote_token_short",
        "election",
        "status",
        "signature_valid_display",
        "submitted_at",
        "submitted_ip",
    ]

    list_filter = [
        "status",
        "election",
        "submitted_at",
    ]

    search_fields = [
        "vote_token",
        "ballot_token_hash",
        "election__title",
    ]

    readonly_fields = [
        "id",
        "vote_token",
        "encrypted_data",
        "encryption_nonce",
        "signature",
        "ballot_token_hash",
        "submitted_at",
        "submitted_ip",
        "signature_valid_display",
    ]

    fieldsets = [
        (
            "Vote Information",
            {
                "fields": [
                    "id",
                    "vote_token",
                    "status",
                    "election",
                ]
            },
        ),
        (
            "Encryption Details",
            {
                "fields": [
                    "encrypted_data",
                    "encryption_nonce",
                    "encryption_key_hash",
                    "signature",
                    "signature_valid_display",
                ]
            },
        ),
        (
            "Audit Information",
            {
                "fields": [
                    "ballot_token_hash",
                    "submitted_at",
                    "submitted_ip",
                ]
            },
        ),
    ]

    def vote_token_short(self, obj):
        """Display shortened vote token."""
        return f"{str(obj.vote_token)[:8]}..."

    vote_token_short.short_description = "Vote Token"

    def signature_valid_display(self, obj):
        """Display signature validation status."""
        try:
            is_valid = obj.verify_signature()
            if is_valid:
                return format_html('<span style="color: green;">✓ Valid</span>')
            else:
                return format_html('<span style="color: red;">✗ Invalid</span>')
        except Exception:
            return format_html('<span style="color: orange;">? Unknown</span>')

    signature_valid_display.short_description = "Signature Valid"

    def has_add_permission(self, request):
        """Disable adding votes through admin."""
        return False

    def has_change_permission(self, request, obj=None):
        """Allow viewing but limit editing."""
        return request.user.is_superuser

    def has_delete_permission(self, request, obj=None):
        """Disable deleting votes through admin."""
        return request.user.is_superuser


@admin.register(VoteToken)
class VoteTokenAdmin(admin.ModelAdmin):
    """Admin interface for VoteToken model."""

    list_display = [
        "vote_token_short",
        "election",
        "is_used",
        "created_at",
        "used_at",
    ]

    list_filter = [
        "is_used",
        "election",
        "created_at",
    ]

    search_fields = [
        "vote_token",
        "ballot_token_hash",
        "election__title",
    ]

    readonly_fields = [
        "id",
        "vote_token",
        "ballot_token_hash",
        "election",
        "created_at",
        "used_at",
    ]

    def vote_token_short(self, obj):
        """Display shortened vote token."""
        return f"{str(obj.vote_token)[:8]}..."

    vote_token_short.short_description = "Vote Token"

    def has_add_permission(self, request):
        """Disable adding vote tokens through admin."""
        return False

    def has_change_permission(self, request, obj=None):
        """Allow viewing but limit editing."""
        return request.user.is_superuser

    def has_delete_permission(self, request, obj=None):
        """Disable deleting vote tokens through admin."""
        return request.user.is_superuser


@admin.register(OfflineVoteQueue)
class OfflineVoteQueueAdmin(admin.ModelAdmin):
    """Admin interface for OfflineVoteQueue model."""

    list_display = [
        "id_short",
        "ballot_token_short",
        "election",
        "is_synced",
        "queued_at",
        "synced_at",
    ]

    list_filter = [
        "is_synced",
        "queued_at",
        "synced_at",
    ]

    search_fields = [
        "ballot_token__token_uuid",
        "ballot_token__election__title",
    ]

    readonly_fields = [
        "id",
        "ballot_token",
        "client_timestamp",
        "queued_at",
        "synced_at",
        "sync_result",
        "client_ip",
    ]

    fieldsets = [
        (
            "Queue Information",
            {
                "fields": [
                    "id",
                    "ballot_token",
                    "client_timestamp",
                    "queued_at",
                ]
            },
        ),
        (
            "Sync Status",
            {
                "fields": [
                    "is_synced",
                    "synced_at",
                    "sync_result",
                ]
            },
        ),
        (
            "Network Information",
            {
                "fields": [
                    "client_ip",
                ]
            },
        ),
        (
            "Vote Data",
            {
                "fields": [
                    "encrypted_vote_data",
                ]
            },
        ),
    ]

    def id_short(self, obj):
        """Display shortened ID."""
        return f"{str(obj.id)[:8]}..."

    id_short.short_description = "ID"

    def ballot_token_short(self, obj):
        """Display shortened ballot token."""
        return f"{str(obj.ballot_token.token_uuid)[:8]}..."

    ballot_token_short.short_description = "Ballot Token"

    def election(self, obj):
        """Display election title."""
        return obj.ballot_token.election.title

    election.short_description = "Election"


@admin.register(VoteAuditLog)
class VoteAuditLogAdmin(admin.ModelAdmin):
    """Admin interface for VoteAuditLog model."""

    list_display = [
        "timestamp",
        "action",
        "election",
        "result",
        "ip_address",
        "vote_token_short",
    ]

    list_filter = [
        "action",
        "result",
        "timestamp",
        "election",
    ]

    search_fields = [
        "action",
        "vote_token",
        "ballot_token_hash",
        "ip_address",
        "election__title",
    ]

    readonly_fields = [
        "id",
        "vote",
        "action",
        "election",
        "vote_token",
        "ballot_token_hash",
        "ip_address",
        "user_agent",
        "metadata",
        "timestamp",
        "result",
        "error_details",
    ]

    fieldsets = [
        (
            "Audit Information",
            {
                "fields": [
                    "id",
                    "action",
                    "result",
                    "timestamp",
                ]
            },
        ),
        (
            "Context",
            {
                "fields": [
                    "vote",
                    "election",
                    "vote_token",
                    "ballot_token_hash",
                ]
            },
        ),
        (
            "Network Information",
            {
                "fields": [
                    "ip_address",
                    "user_agent",
                ]
            },
        ),
        (
            "Additional Data",
            {
                "fields": [
                    "metadata",
                    "error_details",
                ]
            },
        ),
    ]

    def vote_token_short(self, obj):
        """Display shortened vote token."""
        if obj.vote_token:
            return f"{str(obj.vote_token)[:8]}..."
        return "-"

    vote_token_short.short_description = "Vote Token"

    def has_add_permission(self, request):
        """Disable adding audit logs through admin."""
        return False

    def has_change_permission(self, request, obj=None):
        """Disable editing audit logs."""
        return False

    def has_delete_permission(self, request, obj=None):
        """Allow deleting only for superusers."""
        return request.user.is_superuser
