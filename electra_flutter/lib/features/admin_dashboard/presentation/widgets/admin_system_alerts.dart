import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';

/// System alerts widget for displaying critical notifications
///
/// Shows real-time system alerts with priority-based styling,
/// acknowledge functionality, and expandable details.
class AdminSystemAlerts extends StatefulWidget {
  final List<SystemAlert> alerts;
  final Function(String) onAcknowledge;
  final Function(List<String>) onAcknowledgeAll;

  const AdminSystemAlerts({
    super.key,
    required this.alerts,
    required this.onAcknowledge,
    required this.onAcknowledgeAll,
  });

  @override
  State<AdminSystemAlerts> createState() => _AdminSystemAlertsState();
}

class _AdminSystemAlertsState extends State<AdminSystemAlerts>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Set<String> _expandedAlerts = {};
  Set<String> _selectedAlerts = {};
  bool _isAcknowledging = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final criticalAlerts = widget.alerts.where(
      (alert) => alert.severity == AlertSeverity.critical
    ).toList();
    final highAlerts = widget.alerts.where(
      (alert) => alert.severity == AlertSeverity.high
    ).toList();
    
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        color: criticalAlerts.isNotEmpty 
            ? KWASUColors.error.withOpacity(0.05)
            : highAlerts.isNotEmpty
            ? KWASUColors.warning.withOpacity(0.05)
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: criticalAlerts.isNotEmpty 
                ? KWASUColors.error.withOpacity(0.3)
                : highAlerts.isNotEmpty
                ? KWASUColors.warning.withOpacity(0.3)
                : Colors.transparent,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with bulk actions
              _buildAlertsHeader(theme),
              
              const SizedBox(height: 16),
              
              // Alerts list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.alerts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _buildAlertItem(widget.alerts[index], theme);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build alerts header with bulk actions
  Widget _buildAlertsHeader(ThemeData theme) {
    final unacknowledgedCount = widget.alerts.where(
      (alert) => !alert.isAcknowledged
    ).length;

    return Row(
      children: [
        // Alert icon with pulsing animation
        AnimatedBuilder(
          animation: _slideController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KWASUColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: KWASUColors.error,
                size: 24,
              ),
            );
          },
        ),
        
        const SizedBox(width: 12),
        
        // Title and count
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Alerts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '$unacknowledgedCount unacknowledged alert${unacknowledgedCount != 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        
        // Bulk actions
        if (_selectedAlerts.isNotEmpty) ...[
          Text(
            '${_selectedAlerts.length} selected',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _isAcknowledging ? null : _acknowledgeSelected,
            tooltip: 'Acknowledge Selected',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSelection,
            tooltip: 'Clear Selection',
          ),
        ] else if (unacknowledgedCount > 1) ...[
          TextButton.icon(
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Acknowledge All'),
            onPressed: _isAcknowledging ? null : _acknowledgeAll,
            style: TextButton.styleFrom(
              foregroundColor: KWASUColors.primaryBlue,
            ),
          ),
        ],
      ],
    );
  }

  /// Build individual alert item
  Widget _buildAlertItem(SystemAlert alert, ThemeData theme) {
    final isExpanded = _expandedAlerts.contains(alert.id);
    final isSelected = _selectedAlerts.contains(alert.id);
    final severityColor = Color(alert.severity.colorCode);

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? severityColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? severityColor.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleExpansion(alert.id),
          onLongPress: () => _toggleSelection(alert.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert header
                Row(
                  children: [
                    // Severity indicator
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Category and severity
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.category.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Severity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        alert.severity.displayName.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Timestamp
                    Text(
                      _formatTimestamp(alert.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    
                    // Selection checkbox
                    if (_selectedAlerts.isNotEmpty || isSelected)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(alert.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    
                    // Expand/Collapse icon
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Title and message
                Text(
                  alert.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  alert.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded ? null : TextOverflow.ellipsis,
                ),
                
                // Expanded content
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  _buildExpandedContent(alert, theme),
                ],
                
                // Action buttons
                if (!alert.isAcknowledged)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Acknowledge'),
                          onPressed: () => widget.onAcknowledge(alert.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: severityColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        OutlinedButton.icon(
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Details'),
                          onPressed: () => _showAlertDetails(alert),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: severityColor,
                            side: BorderSide(color: severityColor),
                            minimumSize: const Size(100, 32),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build expanded alert content
  Widget _buildExpandedContent(SystemAlert alert, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (alert.metadata != null && alert.metadata!.isNotEmpty) ...[
            Text(
              'Additional Information:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...alert.metadata!.entries.map(
              (entry) => Text(
                '${entry.key}: ${entry.value}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          
          if (alert.acknowledgedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Acknowledged: ${_formatTimestamp(alert.acknowledgedAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: KWASUColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (alert.acknowledgedBy != null)
              Text(
                'By: ${alert.acknowledgedBy}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Toggle alert expansion
  void _toggleExpansion(String alertId) {
    setState(() {
      if (_expandedAlerts.contains(alertId)) {
        _expandedAlerts.remove(alertId);
      } else {
        _expandedAlerts.add(alertId);
      }
    });
  }

  /// Toggle alert selection
  void _toggleSelection(String alertId) {
    setState(() {
      if (_selectedAlerts.contains(alertId)) {
        _selectedAlerts.remove(alertId);
      } else {
        _selectedAlerts.add(alertId);
      }
    });
  }

  /// Clear selection
  void _clearSelection() {
    setState(() {
      _selectedAlerts.clear();
    });
  }

  /// Acknowledge selected alerts
  Future<void> _acknowledgeSelected() async {
    if (_selectedAlerts.isEmpty) return;
    
    setState(() {
      _isAcknowledging = true;
    });
    
    try {
      await widget.onAcknowledgeAll(_selectedAlerts.toList());
      setState(() {
        _selectedAlerts.clear();
      });
    } finally {
      setState(() {
        _isAcknowledging = false;
      });
    }
  }

  /// Acknowledge all unacknowledged alerts
  Future<void> _acknowledgeAll() async {
    final unacknowledgedIds = widget.alerts
        .where((alert) => !alert.isAcknowledged)
        .map((alert) => alert.id)
        .toList();
    
    if (unacknowledgedIds.isEmpty) return;
    
    setState(() {
      _isAcknowledging = true;
    });
    
    try {
      await widget.onAcknowledgeAll(unacknowledgedIds);
    } finally {
      setState(() {
        _isAcknowledging = false;
      });
    }
  }

  /// Show alert details dialog
  void _showAlertDetails(SystemAlert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.message),
              if (alert.metadata != null && alert.metadata!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Metadata:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...alert.metadata!.entries.map(
                  (entry) => Text('${entry.key}: ${entry.value}'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!alert.isAcknowledged)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onAcknowledge(alert.id);
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}