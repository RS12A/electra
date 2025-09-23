import 'package:flutter/material.dart';

import '../../domain/entities/notification.dart';
import '../../../shared/widgets/common/neomorphic_container.dart';

/// Notification card widget with neomorphic design
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDismiss,
    this.onDelete,
  });

  final Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return NeomorphicContainer(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _buildContent(theme),
            if (notification.hasActions) _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Priority indicator
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: Color(int.parse('0xFF${notification.priorityColor.substring(1)}')),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        
        // Type badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            notification.type.toString().split('.').last.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const Spacer(),
        
        // Timestamp
        Text(
          notification.ageDisplay,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        
        // Unread indicator
        if (notification.isUnread) ...[
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notification.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (notification.isUnread && onMarkAsRead != null)
            TextButton.icon(
              onPressed: onMarkAsRead,
              icon: const Icon(Icons.mark_email_read, size: 16),
              label: const Text('Mark as Read'),
            ),
          if (onDismiss != null)
            TextButton.icon(
              onPressed: onDismiss,
              icon: const Icon(Icons.remove_circle_outline, size: 16),
              label: const Text('Dismiss'),
            ),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }
}