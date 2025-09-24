import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/notification.dart';
import '../../../../shared/widgets/neomorphic_container.dart';
import '../../../../shared/theme/app_theme.dart';

/// Enhanced notification card widget with neomorphic design and interactive actions
/// 
/// Features:
/// - Neomorphic design with KWASU theming
/// - Interactive actions (mark as read, dismiss, delete)
/// - Priority indicators and visual hierarchy
/// - Swipe-to-dismiss gesture support
/// - Deep link navigation support
/// - Accessibility features
class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDismiss,
    this.onDelete,
    this.onAction,
    this.showActions = true,
    this.enableSwipeToRead = true,
    this.enableSwipeToDismiss = true,
    this.compact = false,
  });

  final Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDismiss;
  final VoidCallback? onDelete;
  final ValueChanged<NotificationAction>? onAction;
  final bool showActions;
  final bool enableSwipeToRead;
  final bool enableSwipeToDismiss;
  final bool compact;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 50),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: _buildNotificationContent(theme),
          ),
        );
      },
    );
  }

  Widget _buildNotificationContent(ThemeData theme) {
    if (widget.enableSwipeToDismiss || widget.enableSwipeToRead) {
      return Dismissible(
        key: Key(widget.notification.id),
        background: _buildSwipeBackground(theme, isLeading: true),
        secondaryBackground: _buildSwipeBackground(theme, isLeading: false),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd && widget.enableSwipeToRead) {
            widget.onMarkAsRead?.call();
            return false; // Don't dismiss, just mark as read
          } else if (direction == DismissDirection.endToStart && widget.enableSwipeToDismiss) {
            widget.onDismiss?.call();
            return true; // Dismiss the notification
          }
          return false;
        },
        child: _buildCard(theme),
      );
    } else {
      return _buildCard(theme);
    }
  }

  Widget _buildSwipeBackground(ThemeData theme, {required bool isLeading}) {
    final color = isLeading ? Colors.green : Colors.red;
    final icon = isLeading ? Icons.mark_email_read : Icons.delete_sweep;
    final text = isLeading ? 'Mark as Read' : 'Dismiss';

    return Container(
      alignment: isLeading ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: color.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeomorphicContainer(
        padding: EdgeInsets.all(widget.compact ? 12 : 16),
        elevation: widget.notification.isUnread ? 6 : 3,
        color: widget.notification.isUnread 
            ? theme.colorScheme.primary.withOpacity(0.05)
            : null,
        onTap: () => _handleTap(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            SizedBox(height: widget.compact ? 8 : 12),
            _buildContent(theme),
            if (widget.notification.imageUrl != null && !widget.compact)
              _buildImage(theme),
            if (widget.showActions && _hasActions()) 
              _buildActions(theme),
            if (widget.notification.actions.isNotEmpty && !widget.compact)
              _buildNotificationActions(theme),
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
          height: widget.compact ? 20 : 24,
          decoration: BoxDecoration(
            color: _getPriorityColor(widget.notification.priority),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        
        // Type icon and badge
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _getNotificationTypeColor(widget.notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getNotificationTypeIcon(widget.notification.type),
            size: 16,
            color: _getNotificationTypeColor(widget.notification.type),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Type badge
        if (!widget.compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getNotificationTypeColor(widget.notification.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getTypeLabel(widget.notification.type),
              style: theme.textTheme.labelSmall?.copyWith(
                color: _getNotificationTypeColor(widget.notification.type),
                fontWeight: FontWeight.w600,
                fontFamily: 'KWASU',
              ),
            ),
          ),
        
        const Spacer(),
        
        // Priority indicator for critical notifications
        if (widget.notification.priority == NotificationPriority.critical)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'URGENT',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Timestamp
        Text(
          _formatTimestamp(widget.notification.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: 'KWASU',
          ),
        ),
        
        // Unread indicator
        if (widget.notification.isUnread) ...[
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
        
        // Expand/collapse button for long content
        if (!widget.compact && widget.notification.message.length > 100)
          IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with status indicator
        Row(
          children: [
            Expanded(
              child: Text(
                widget.notification.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: widget.notification.isUnread ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'KWASU',
                  color: widget.notification.isUnread 
                      ? theme.textTheme.titleMedium?.color
                      : theme.textTheme.titleMedium?.color?.withOpacity(0.8),
                ),
                maxLines: widget.compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.notification.deepLinkUrl != null)
              Icon(
                Icons.link,
                size: 16,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Message content
        AnimatedCrossFade(
          firstChild: Text(
            widget.notification.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            maxLines: widget.compact ? 2 : (_isExpanded ? null : 3),
            overflow: widget.compact || !_isExpanded ? TextOverflow.ellipsis : null,
          ),
          secondChild: Text(
            widget.notification.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          crossFadeState: _isExpanded && !widget.compact 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        
        // Metadata
        if (widget.notification.metadata.isNotEmpty && !widget.compact)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildMetadata(theme),
          ),
      ],
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    final metadata = widget.notification.metadata;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: metadata.entries.take(3).map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.key}: ${entry.value}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.notification.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: theme.colorScheme.surfaceVariant,
              child: Center(
                child: Icon(
                  Icons.broken_image,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: theme.colorScheme.surfaceVariant,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          if (widget.notification.isUnread && widget.onMarkAsRead != null)
            NeomorphicButton(
              onPressed: widget.onMarkAsRead,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              color: Colors.green.withOpacity(0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_read, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Mark Read',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.notification.isUnread && widget.onMarkAsRead != null)
            const SizedBox(width: 8),
          
          if (widget.onDismiss != null)
            NeomorphicButton(
              onPressed: widget.onDismiss,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              color: Colors.orange.withOpacity(0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_circle_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Dismiss',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          
          // Deep link action
          if (widget.notification.deepLinkUrl != null)
            NeomorphicButton(
              onPressed: () => _handleDeepLink(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 2,
              color: theme.colorScheme.primary.withOpacity(0.1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'View',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          
          if (widget.onDelete != null)
            IconButton(
              onPressed: widget.onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.notification.actions.map((action) {
          return NeomorphicButton(
            onPressed: () => widget.onAction?.call(action),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            color: _getActionColor(action.type).withOpacity(0.1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (action.icon != null)
                  Icon(
                    _getActionIcon(action.icon!),
                    size: 16,
                    color: _getActionColor(action.type),
                  ),
                if (action.icon != null) const SizedBox(width: 6),
                Text(
                  action.title,
                  style: TextStyle(
                    color: _getActionColor(action.type),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _hasActions() {
    return (widget.notification.isUnread && widget.onMarkAsRead != null) ||
           widget.onDismiss != null ||
           widget.onDelete != null ||
           widget.notification.deepLinkUrl != null;
  }

  void _handleTap() {
    if (widget.notification.deepLinkUrl != null) {
      _handleDeepLink();
    } else {
      widget.onTap?.call();
    }
  }

  void _handleDeepLink() {
    // Handle deep link navigation
    // This would typically use GoRouter or similar navigation
    widget.onTap?.call();
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.critical:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.election:
        return Colors.blue;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.security:
        return Colors.red;
      case NotificationType.announcement:
        return Colors.green;
      case NotificationType.votingReminder:
        return Colors.orange;
      case NotificationType.deadline:
        return Colors.amber;
      default:
        return Colors.purple;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.election:
        return Icons.how_to_vote;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.security:
        return Icons.security;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.votingReminder:
        return Icons.notifications_active;
      case NotificationType.deadline:
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.election:
        return 'Election';
      case NotificationType.system:
        return 'System';
      case NotificationType.security:
        return 'Security';
      case NotificationType.announcement:
        return 'News';
      case NotificationType.votingReminder:
        return 'Reminder';
      case NotificationType.deadline:
        return 'Deadline';
      default:
        return type.name;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType.toLowerCase()) {
      case 'primary':
        return Colors.blue;
      case 'secondary':
        return Colors.grey;
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getActionIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'vote':
        return Icons.how_to_vote;
      case 'view':
        return Icons.visibility;
      case 'download':
        return Icons.download;
      case 'share':
        return Icons.share;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.touch_app;
    }
  }
}

/// Compact notification card for use in lists or dense layouts
class CompactNotificationCard extends StatelessWidget {
  const CompactNotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDismiss,
  });

  final Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return NotificationCard(
      notification: notification,
      onTap: onTap,
      onMarkAsRead: onMarkAsRead,
      onDismiss: onDismiss,
      compact: true,
      showActions: false,
    );
  }
}