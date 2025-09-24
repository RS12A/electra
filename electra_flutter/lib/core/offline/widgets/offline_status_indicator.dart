import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sync_config.dart';
import '../providers/offline_providers.dart';

/// Status indicator showing offline/online state and sync progress
///
/// Displays connection status, pending items count, and sync progress
/// with smooth animations and KWASU theming.
class OfflineStatusIndicator extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const OfflineStatusIndicator({
    super.key,
    this.showDetails = true,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineStateProvider);
    final theme = Theme.of(context);
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(offlineState, theme).withOpacity(0.1),
            border: Border.all(
              color: _getStatusColor(offlineState, theme),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusIcon(offlineState, theme),
              const SizedBox(width: 6),
              if (showDetails) ...[
                _buildStatusText(offlineState, theme),
                if (offlineState.pendingItemsCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildPendingItemsBadge(offlineState, theme),
                ],
              ],
              if (offlineState.syncStatus == SyncOrchestratorStatus.syncing)
                _buildSyncingIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(OfflineState state, ThemeData theme) {
    IconData iconData;
    Color iconColor = _getStatusColor(state, theme);

    if (!state.networkStatus.isConnected) {
      iconData = Icons.cloud_off;
    } else if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      iconData = Icons.sync;
    } else if (state.pendingItemsCount > 0) {
      iconData = Icons.cloud_upload;
    } else {
      iconData = Icons.cloud_done;
    }

    Widget icon = Icon(
      iconData,
      size: 16,
      color: iconColor,
    );

    // Add rotation animation for syncing state
    if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      return RotationTransition(
        turns: const AlwaysStoppedAnimation(0.0),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.rotate(
              angle: value * 2 * 3.14159,
              child: icon,
            );
          },
        ),
      );
    }

    return icon;
  }

  Widget _buildStatusText(OfflineState state, ThemeData theme) {
    String statusText;
    
    if (!state.networkStatus.isConnected) {
      statusText = 'Offline';
    } else if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      statusText = 'Syncing';
    } else if (state.pendingItemsCount > 0) {
      statusText = 'Pending';
    } else {
      switch (state.networkStatus.quality) {
        case NetworkQuality.excellent:
          statusText = 'Online';
          break;
        case NetworkQuality.good:
          statusText = 'Online';
          break;
        case NetworkQuality.moderate:
          statusText = 'Online';
          break;
        case NetworkQuality.poor:
          statusText = 'Poor Signal';
          break;
        case NetworkQuality.offline:
          statusText = 'Offline';
          break;
      }
    }

    return Text(
      statusText,
      style: theme.textTheme.labelSmall?.copyWith(
        color: _getStatusColor(state, theme),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPendingItemsBadge(OfflineState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${state.pendingItemsCount}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSyncingIndicator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      width: 12,
      height: 12,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Color _getStatusColor(OfflineState state, ThemeData theme) {
    if (!state.networkStatus.isConnected) {
      return theme.colorScheme.error;
    } else if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      return theme.colorScheme.primary;
    } else if (state.pendingItemsCount > 0) {
      return theme.colorScheme.tertiary;
    } else {
      return theme.colorScheme.primary;
    }
  }
}

/// Compact version of the status indicator for app bars
class CompactOfflineStatusIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const CompactOfflineStatusIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineStateProvider);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            Icon(
              _getCompactIcon(offlineState),
              size: 20,
              color: _getStatusColor(offlineState, theme),
            ),
            if (offlineState.pendingItemsCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCompactIcon(OfflineState state) {
    if (!state.networkStatus.isConnected) {
      return Icons.cloud_off;
    } else if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      return Icons.sync;
    } else if (state.pendingItemsCount > 0) {
      return Icons.cloud_upload;
    } else {
      return Icons.cloud_done;
    }
  }

  Color _getStatusColor(OfflineState state, ThemeData theme) {
    if (!state.networkStatus.isConnected) {
      return theme.colorScheme.error;
    } else if (state.syncStatus == SyncOrchestratorStatus.syncing) {
      return theme.colorScheme.primary;
    } else if (state.pendingItemsCount > 0) {
      return theme.colorScheme.tertiary;
    } else {
      return theme.colorScheme.primary;
    }
  }
}

/// Detailed offline status card for settings or debug views
class DetailedOfflineStatusCard extends ConsumerWidget {
  const DetailedOfflineStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineStateProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.offline_bolt,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Offline Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Connection',
              offlineState.networkStatus.isConnected ? 'Online' : 'Offline',
              offlineState.networkStatus.isConnected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
            _buildStatusRow(
              'Network Quality',
              offlineState.networkStatus.quality.name.toUpperCase(),
              _getQualityColor(offlineState.networkStatus.quality, theme),
            ),
            _buildStatusRow(
              'Pending Items',
              '${offlineState.pendingItemsCount}',
              offlineState.pendingItemsCount > 0
                  ? theme.colorScheme.tertiary
                  : theme.colorScheme.primary,
            ),
            _buildStatusRow(
              'Sync Status',
              offlineState.syncStatus.name.toUpperCase(),
              offlineState.syncStatus == SyncOrchestratorStatus.syncing
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            if (offlineState.lastSuccessfulSync != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last Sync: ${_formatDateTime(offlineState.lastSuccessfulSync!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (offlineState.recentErrors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recent Errors:',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...offlineState.recentErrors.take(3).map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getQualityColor(NetworkQuality quality, ThemeData theme) {
    switch (quality) {
      case NetworkQuality.excellent:
        return Colors.green;
      case NetworkQuality.good:
        return Colors.lightGreen;
      case NetworkQuality.moderate:
        return Colors.orange;
      case NetworkQuality.poor:
        return Colors.red;
      case NetworkQuality.offline:
        return theme.colorScheme.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}