import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Notifications page for viewing system and election notifications
///
/// Displays all notifications including election updates, system alerts,
/// and important announcements with proper categorization and actions.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                _markAllAsRead();
              } else if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 12),
                    Text('Mark All as Read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 12),
                    Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter tabs
                _buildFilterTabs(theme),

                // Notifications list
                Expanded(child: _buildNotificationsList(theme)),
              ],
            ),
    );
  }

  /// Build filter tabs
  Widget _buildFilterTabs(ThemeData theme) {
    final filters = ['All', 'Elections', 'System', 'Security'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                    _loadNotifications();
                  }
                },
                selectedColor: KWASUColors.primaryBlue.withOpacity(0.2),
                checkmarkColor: KWASUColors.primaryBlue,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build notifications list
  Widget _buildNotificationsList(ThemeData theme) {
    final notifications = _getMockNotifications();

    if (notifications.isEmpty) {
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification, theme);
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),

          const SizedBox(height: 16),

          Text(
            'No Notifications',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You\'re all caught up! No new notifications at this time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    ThemeData theme,
  ) {
    final isRead = notification['isRead'] as bool;
    final type = notification['type'] as String;
    final priority = notification['priority'] as String;

    final typeColor = _getTypeColor(type);
    final priorityColor = _getPriorityColor(priority);

    return Card(
      elevation: isRead ? 1 : 3,
      color: isRead
          ? null
          : theme.colorScheme.primaryContainer.withOpacity(0.1),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_getTypeIcon(type), color: typeColor, size: 20),
                  ),

                  const SizedBox(width: 12),

                  // Title and priority
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification['title'],
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (priority != 'Normal') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    color: priorityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        Text(
                          _formatTime(notification['timestamp']),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Unread indicator
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: KWASUColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Message
              Text(notification['message'], style: theme.textTheme.bodyMedium),

              // Action buttons (if any)
              if (notification['actions'] != null) ...[
                const SizedBox(height: 16),

                Row(
                  children:
                      (notification['actions'] as List<Map<String, dynamic>>)
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: TextButton(
                                onPressed: () => _handleNotificationAction(
                                  notification,
                                  action['id'],
                                ),
                                child: Text(action['label']),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Get type color
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Election':
        return KWASUColors.primaryBlue;
      case 'System':
        return KWASUColors.info;
      case 'Security':
        return KWASUColors.error;
      case 'Success':
        return KWASUColors.success;
      default:
        return KWASUColors.grey600;
    }
  }

  /// Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return KWASUColors.error;
      case 'Medium':
        return KWASUColors.warning;
      default:
        return KWASUColors.info;
    }
  }

  /// Get type icon
  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Election':
        return Icons.how_to_vote;
      case 'System':
        return Icons.settings;
      case 'Security':
        return Icons.security;
      case 'Success':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  /// Format timestamp
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Get mock notifications based on filter
  List<Map<String, dynamic>> _getMockNotifications() {
    final allNotifications = [
      {
        'id': '1',
        'type': 'Election',
        'priority': 'High',
        'title': 'Election Ending Soon',
        'message':
            'Student Union Executive Elections 2024 will end in 2 days. Make sure to cast your vote!',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'actions': [
          {'id': 'vote', 'label': 'Vote Now'},
          {'id': 'remind', 'label': 'Remind Later'},
        ],
      },
      {
        'id': '2',
        'type': 'Success',
        'priority': 'Normal',
        'title': 'Vote Confirmed',
        'message':
            'Your vote has been successfully recorded for Course Representative Elections.',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
        'isRead': false,
      },
      {
        'id': '3',
        'type': 'System',
        'priority': 'Medium',
        'title': 'Maintenance Scheduled',
        'message':
            'System maintenance is scheduled for tonight at 11:00 PM. The system will be unavailable for 2 hours.',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': true,
      },
      {
        'id': '4',
        'type': 'Election',
        'priority': 'Normal',
        'title': 'New Election Available',
        'message':
            'Faculty Representative Elections are now open for voting. Check your eligibility and cast your vote.',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': true,
      },
      {
        'id': '5',
        'type': 'Security',
        'priority': 'High',
        'title': 'Unusual Login Activity',
        'message':
            'We detected a login attempt from a new device. If this wasn\'t you, please change your password immediately.',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'isRead': true,
      },
    ];

    // Filter notifications based on selected filter
    if (_selectedFilter == 'All') {
      return allNotifications;
    } else {
      return allNotifications
          .where(
            (n) =>
                n['type'] == _selectedFilter ||
                (_selectedFilter == 'Elections' && n['type'] == 'Election'),
          )
          .toList();
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(Map<String, dynamic> notification) {
    if (!notification['isRead']) {
      // Mark as read
      // TODO: Update notification status in API
      // ref.read(notificationServiceProvider).markAsRead(notification['id']);

      setState(() {
        notification['isRead'] = true;
      });
    }

    // Handle specific notification actions based on type
    final type = notification['type'] as String;
    switch (type) {
      case 'Election':
        // Navigate to relevant election
        break;
      case 'System':
        // Show system details
        break;
      case 'Security':
        // Navigate to security settings
        break;
    }
  }

  /// Handle notification action
  void _handleNotificationAction(
    Map<String, dynamic> notification,
    String actionId,
  ) {
    switch (actionId) {
      case 'vote':
        // Navigate to voting page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigating to voting page...')),
        );
        break;
      case 'remind':
        // Set reminder
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder set for later')));
        break;
    }
  }

  /// Mark all notifications as read
  void _markAllAsRead() {
    // TODO: API call to mark all as read
    // ref.read(notificationServiceProvider).markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      // Update local state
    });
  }

  /// Clear all notifications
  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              // TODO: API call to clear all notifications
              // ref.read(notificationServiceProvider).clearAll();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.red,
                ),
              );

              setState(() {
                // Update local state
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Load notifications
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load notifications from API
    // final notifications = await ref.read(notificationServiceProvider).getNotifications(_selectedFilter);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
