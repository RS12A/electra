import 'package:flutter/material.dart';

import '../../../../shared/widgets/neomorphic_container.dart';
import '../../domain/entities/notification.dart';

/// An elegant filter chip for notification filtering
/// 
/// Features:
/// - Neomorphic design with smooth animations
/// - Color-coded notification types
/// - Badge support for counts
/// - Accessibility support
/// - KWASU theme integration
class NotificationFilterChip extends StatefulWidget {
  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelectionChanged,
    this.notificationType,
    this.count,
    this.color,
    this.showCount = true,
    this.icon,
  });

  /// Display label for the chip
  final String label;
  
  /// Whether the chip is currently selected
  final bool isSelected;
  
  /// Callback when selection state changes
  final ValueChanged<bool> onSelectionChanged;
  
  /// Associated notification type for styling
  final NotificationType? notificationType;
  
  /// Number of items in this filter category
  final int? count;
  
  /// Custom color override
  final Color? color;
  
  /// Whether to show the count badge
  final bool showCount;
  
  /// Optional icon for the chip
  final IconData? icon;

  @override
  State<NotificationFilterChip> createState() => _NotificationFilterChipState();
}

class _NotificationFilterChipState extends State<NotificationFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NotificationFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = _getChipColor(theme);
    
    _colorAnimation = ColorTween(
      begin: theme.colorScheme.surface,
      end: chipColor.withOpacity(0.2),
    ).animate(_animationController);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: NeomorphicContainer(
            padding: EdgeInsets.zero,
            elevation: widget.isSelected ? 6 : 3,
            isPressed: widget.isSelected,
            color: _colorAnimation.value,
            onTap: () => _handleTap(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: widget.isSelected
                          ? chipColor
                          : theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 6),
                  ],
                  
                  // Type indicator dot
                  if (widget.notificationType != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: chipColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // Label
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: widget.isSelected
                          ? chipColor
                          : theme.textTheme.bodyMedium?.color,
                      fontFamily: 'KWASU',
                    ),
                  ),
                  
                  // Count badge
                  if (widget.showCount && widget.count != null && widget.count! > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap() {
    widget.onSelectionChanged(!widget.isSelected);
  }

  Color _getChipColor(ThemeData theme) {
    if (widget.color != null) {
      return widget.color!;
    }
    
    if (widget.notificationType != null) {
      return _getNotificationTypeColor(widget.notificationType!);
    }
    
    return theme.colorScheme.primary;
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
}

/// A collection of filter chips for notification filtering
class NotificationFilterBar extends StatefulWidget {
  const NotificationFilterBar({
    super.key,
    required this.selectedFilters,
    required this.onFiltersChanged,
    this.notificationCounts,
    this.showAllFilter = true,
    this.scrollable = true,
  });

  /// Currently selected notification types
  final Set<NotificationType> selectedFilters;
  
  /// Callback when filter selection changes
  final ValueChanged<Set<NotificationType>> onFiltersChanged;
  
  /// Count of notifications per type
  final Map<NotificationType, int>? notificationCounts;
  
  /// Whether to show an "All" filter option
  final bool showAllFilter;
  
  /// Whether the filter bar should be scrollable
  final bool scrollable;

  @override
  State<NotificationFilterBar> createState() => _NotificationFilterBarState();
}

class _NotificationFilterBarState extends State<NotificationFilterBar> {
  late Set<NotificationType> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = Set.from(widget.selectedFilters);
  }

  @override
  void didUpdateWidget(NotificationFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilters != oldWidget.selectedFilters) {
      _selectedFilters = Set.from(widget.selectedFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = _buildFilterChips();

    if (widget.scrollable) {
      return SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: chips.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) => chips[index],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      );
    }
  }

  List<Widget> _buildFilterChips() {
    final List<Widget> chips = [];

    // All filter
    if (widget.showAllFilter) {
      chips.add(
        NotificationFilterChip(
          label: 'All',
          isSelected: _selectedFilters.isEmpty,
          onSelectionChanged: (selected) {
            if (selected) {
              _updateFilters({});
            }
          },
          icon: Icons.select_all,
          count: widget.notificationCounts?.values
              .fold<int>(0, (sum, count) => sum + count),
        ),
      );
    }

    // Type-specific filters
    for (final type in NotificationType.values) {
      chips.add(
        NotificationFilterChip(
          label: _getTypeLabel(type),
          isSelected: _selectedFilters.contains(type),
          onSelectionChanged: (selected) {
            final newFilters = Set<NotificationType>.from(_selectedFilters);
            if (selected) {
              newFilters.add(type);
            } else {
              newFilters.remove(type);
            }
            _updateFilters(newFilters);
          },
          notificationType: type,
          count: widget.notificationCounts?[type],
          icon: _getTypeIcon(type),
        ),
      );
    }

    return chips;
  }

  void _updateFilters(Set<NotificationType> newFilters) {
    setState(() {
      _selectedFilters = newFilters;
    });
    widget.onFiltersChanged(newFilters);
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.election:
        return 'Elections';
      case NotificationType.system:
        return 'System';
      case NotificationType.security:
        return 'Security';
      case NotificationType.announcement:
        return 'News';
      case NotificationType.votingReminder:
        return 'Reminders';
      case NotificationType.deadline:
        return 'Deadlines';
      default:
        return type.name;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
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
}

/// A priority filter chip for filtering by notification priority
class PriorityFilterChip extends StatelessWidget {
  const PriorityFilterChip({
    super.key,
    required this.priority,
    required this.isSelected,
    required this.onSelectionChanged,
    this.count,
  });

  final NotificationPriority priority;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return NotificationFilterChip(
      label: _getPriorityLabel(priority),
      isSelected: isSelected,
      onSelectionChanged: onSelectionChanged,
      color: _getPriorityColor(priority),
      count: count,
      icon: _getPriorityIcon(priority),
    );
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
      default:
        return priority.name;
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

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case NotificationPriority.normal:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case NotificationPriority.critical:
        return Icons.priority_high;
      default:
        return Icons.help_outline;
    }
  }
}

/// A status filter chip for filtering by read/unread status
class StatusFilterChip extends StatelessWidget {
  const StatusFilterChip({
    super.key,
    required this.showUnreadOnly,
    required this.onToggle,
    this.unreadCount,
  });

  final bool showUnreadOnly;
  final ValueChanged<bool> onToggle;
  final int? unreadCount;

  @override
  Widget build(BuildContext context) {
    return NotificationFilterChip(
      label: 'Unread Only',
      isSelected: showUnreadOnly,
      onSelectionChanged: onToggle,
      color: Colors.red,
      count: unreadCount,
      icon: Icons.mark_email_unread,
    );
  }
}

/// A compact filter toggle for simple on/off filtering
class CompactFilterToggle extends StatelessWidget {
  const CompactFilterToggle({
    super.key,
    required this.label,
    required this.isActive,
    required this.onToggle,
    this.color,
    this.icon,
  });

  final String label;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? effectiveColor : theme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isActive ? effectiveColor : theme.disabledColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? effectiveColor : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}