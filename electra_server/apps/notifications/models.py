"""
Notification models for electra_server.

This module contains models for managing notifications, including email,
SMS, and push notifications for the electra voting system.
"""
import uuid
from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone

from electra_server.apps.elections.models import Election

User = get_user_model()


class NotificationType(models.TextChoices):
    """Notification type choices."""
    EMAIL = 'email', 'Email'
    SMS = 'sms', 'SMS'
    PUSH = 'push', 'Push Notification'
    IN_APP = 'in_app', 'In-App Notification'


class NotificationStatus(models.TextChoices):
    """Notification status choices."""
    PENDING = 'pending', 'Pending'
    SENT = 'sent', 'Sent'
    DELIVERED = 'delivered', 'Delivered'
    FAILED = 'failed', 'Failed'
    READ = 'read', 'Read'


class NotificationTemplate(models.Model):
    """
    Template for notifications with support for multiple languages.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the notification template'
    )
    
    name = models.CharField(
        max_length=100,
        unique=True,
        help_text='Template name for identification'
    )
    
    notification_type = models.CharField(
        max_length=20,
        choices=NotificationType.choices,
        help_text='Type of notification this template is for'
    )
    
    subject_template = models.CharField(
        max_length=200,
        help_text='Template for notification subject/title'
    )
    
    body_template = models.TextField(
        help_text='Template for notification body content'
    )
    
    language = models.CharField(
        max_length=10,
        default='en',
        help_text='Language code for this template'
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text='Whether this template is active'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['name', 'language']]
        ordering = ['name', 'language']
    
    def __str__(self):
        return f"{self.name} ({self.language})"


class Notification(models.Model):
    """
    Individual notification instance.
    """
    
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text='Unique identifier for the notification'
    )
    
    recipient = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        help_text='User who will receive the notification'
    )
    
    template = models.ForeignKey(
        NotificationTemplate,
        on_delete=models.CASCADE,
        related_name='notifications',
        help_text='Template used for this notification'
    )
    
    election = models.ForeignKey(
        Election,
        on_delete=models.CASCADE,
        related_name='notifications',
        null=True,
        blank=True,
        help_text='Election context for this notification'
    )
    
    notification_type = models.CharField(
        max_length=20,
        choices=NotificationType.choices,
        help_text='Type of notification'
    )
    
    status = models.CharField(
        max_length=20,
        choices=NotificationStatus.choices,
        default=NotificationStatus.PENDING,
        help_text='Current status of the notification'
    )
    
    subject = models.CharField(
        max_length=200,
        help_text='Rendered notification subject'
    )
    
    body = models.TextField(
        help_text='Rendered notification body'
    )
    
    recipient_address = models.CharField(
        max_length=255,
        help_text='Email address, phone number, or device token'
    )
    
    context_data = models.JSONField(
        default=dict,
        help_text='Additional context data used for rendering'
    )
    
    scheduled_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the notification should be sent'
    )
    
    sent_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the notification was sent'
    )
    
    delivered_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the notification was delivered'
    )
    
    read_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text='When the notification was read'
    )
    
    error_message = models.TextField(
        blank=True,
        help_text='Error message if delivery failed'
    )
    
    retry_count = models.IntegerField(
        default=0,
        help_text='Number of delivery attempts'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['recipient', 'status']),
            models.Index(fields=['election', 'notification_type']),
            models.Index(fields=['scheduled_at']),
        ]
    
    def __str__(self):
        return f"{self.notification_type} to {self.recipient.email}: {self.subject}"
    
    def mark_as_sent(self):
        """Mark notification as sent."""
        self.status = NotificationStatus.SENT
        self.sent_at = timezone.now()
        self.save(update_fields=['status', 'sent_at'])
    
    def mark_as_delivered(self):
        """Mark notification as delivered."""
        self.status = NotificationStatus.DELIVERED
        self.delivered_at = timezone.now()
        self.save(update_fields=['status', 'delivered_at'])
    
    def mark_as_failed(self, error_message: str = ''):
        """Mark notification as failed."""
        self.status = NotificationStatus.FAILED
        self.error_message = error_message
        self.retry_count += 1
        self.save(update_fields=['status', 'error_message', 'retry_count'])
    
    def mark_as_read(self):
        """Mark notification as read."""
        self.status = NotificationStatus.READ
        self.read_at = timezone.now()
        self.save(update_fields=['status', 'read_at'])


class NotificationPreference(models.Model):
    """
    User preferences for notifications.
    """
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='notification_preferences',
        help_text='User these preferences belong to'
    )
    
    email_enabled = models.BooleanField(
        default=True,
        help_text='Whether email notifications are enabled'
    )
    
    sms_enabled = models.BooleanField(
        default=False,
        help_text='Whether SMS notifications are enabled'
    )
    
    push_enabled = models.BooleanField(
        default=True,
        help_text='Whether push notifications are enabled'
    )
    
    in_app_enabled = models.BooleanField(
        default=True,
        help_text='Whether in-app notifications are enabled'
    )
    
    election_updates = models.BooleanField(
        default=True,
        help_text='Receive election status updates'
    )
    
    voting_reminders = models.BooleanField(
        default=True,
        help_text='Receive voting deadline reminders'
    )
    
    security_alerts = models.BooleanField(
        default=True,
        help_text='Receive security-related alerts'
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Notification preferences for {self.user.email}"