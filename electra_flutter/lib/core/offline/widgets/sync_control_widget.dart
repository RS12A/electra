import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/queue_item.dart';
import '../models/sync_config.dart';
import '../providers/offline_providers.dart';

/// Widget for controlling sync operations and displaying sync progress
///
/// Provides manual sync trigger, progress monitoring, and queue management
/// with smooth animations and user feedback.
class SyncControlWidget extends ConsumerWidget {
  final bool showAdvancedControls;
  final EdgeInsets? padding;

  const SyncControlWidget({
    super.key,
    this.showAdvancedControls = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineStateProvider);
    final theme = Theme.of(context);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSyncHeader(context, offlineState, theme),
          const SizedBox(height: 16),
          _buildSyncProgress(context, offlineState, theme, ref),
          const SizedBox(height: 16),
          _buildSyncControls(context, offlineState, theme, ref),
          if (showAdvancedControls) ...[
            const SizedBox(height: 16),
            _buildAdvancedControls(context, offlineState, theme, ref),
          ],
        ],
      ),
    );
  }

  Widget _buildSyncHeader(
    BuildContext context,
    OfflineState state,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(
          Icons.sync,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Sync Status',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (state.syncStatus == SyncOrchestratorStatus.syncing)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildSyncProgress(
    BuildContext context,
    OfflineState state,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final session = state.currentSyncSession;
    
    if (session == null && state.pendingItemsCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Synced',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'No pending operations',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.pendingItemsCount > 0) ...[
          _buildPendingItemsCard(state, theme),
          const SizedBox(height: 12),
        ],
        if (session != null) ...[
          _buildSyncSessionCard(session, theme),
          const SizedBox(height: 12),
        ],
        if (state.syncingItems.isNotEmpty)
          _buildCurrentSyncItems(state.syncingItems, theme),
      ],
    );
  }

  Widget _buildPendingItemsCard(OfflineState state, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.tertiary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload,
            color: theme.colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Operations',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                Text(
                  '${state.pendingItemsCount} operations waiting to sync',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.pendingItemsCount}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncSessionCard(SyncSession session, ThemeData theme) {
    final progressValue = session.totalItems > 0
        ? (session.successfulItems + session.failedItems) / session.totalItems
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sync,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sync in Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${session.successfulItems + session.failedItems}/${session.totalItems}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (session.successfulItems > 0) ...[
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.successfulItems}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (session.failedItems > 0) ...[
                Icon(
                  Icons.error,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${session.failedItems}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSyncItems(List<QueueItem> items, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Currently Syncing',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...items.take(3).map((item) => _buildSyncItemRow(item, theme)),
          if (items.length > 3)
            Text(
              '... and ${items.length - 3} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncItemRow(QueueItem item, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            _getOperationIcon(item.operationType),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getOperationDisplayName(item.operationType),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            _getPriorityText(item.priority),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getPriorityColor(item.priority, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncControls(
    BuildContext context,
    OfflineState state,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final canSync = state.networkStatus.isConnected &&
        state.syncStatus != SyncOrchestratorStatus.syncing &&
        state.pendingItemsCount > 0;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: canSync
                ? () => _handleManualSync(ref)
                : null,
            icon: Icon(
              state.syncStatus == SyncOrchestratorStatus.syncing
                  ? Icons.sync
                  : Icons.cloud_upload,
            ),
            label: Text(
              state.syncStatus == SyncOrchestratorStatus.syncing
                  ? 'Syncing...'
                  : 'Sync Now',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (state.syncStatus == SyncOrchestratorStatus.syncing) ...[
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _handleCancelSync(ref),
            child: const Text('Cancel'),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedControls(
    BuildContext context,
    OfflineState state,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advanced Controls',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip(
              'Votes Only',
              () => _handleFilteredSync(ref, [QueueOperationType.vote]),
              theme,
            ),
            _buildFilterChip(
              'High Priority',
              () => _handlePrioritySync(ref, [QueuePriority.high, QueuePriority.critical]),
              theme,
            ),
            _buildFilterChip(
              'Clear Errors',
              () => _handleClearErrors(ref),
              theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    VoidCallback onPressed,
    ThemeData theme,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.surfaceVariant,
    );
  }

  // Event handlers

  void _handleManualSync(WidgetRef ref) {
    ref.read(offlineStateProvider.notifier).startManualSync();
  }

  void _handleCancelSync(WidgetRef ref) {
    ref.read(offlineStateProvider.notifier).cancelSync();
  }

  void _handleFilteredSync(WidgetRef ref, List<QueueOperationType> types) {
    ref.read(offlineStateProvider.notifier).startManualSync(
      operationTypes: types,
    );
  }

  void _handlePrioritySync(WidgetRef ref, List<QueuePriority> priorities) {
    ref.read(offlineStateProvider.notifier).startManualSync(
      priorities: priorities,
    );
  }

  void _handleClearErrors(WidgetRef ref) {
    ref.read(offlineStateProvider.notifier).clearRecentErrors();
  }

  // Helper methods

  IconData _getOperationIcon(QueueOperationType type) {
    switch (type) {
      case QueueOperationType.vote:
        return Icons.how_to_vote;
      case QueueOperationType.authRefresh:
        return Icons.refresh;
      case QueueOperationType.profileUpdate:
        return Icons.person;
      case QueueOperationType.notificationAck:
        return Icons.notifications;
      case QueueOperationType.timetableEvent:
        return Icons.event;
    }
  }

  String _getOperationDisplayName(QueueOperationType type) {
    switch (type) {
      case QueueOperationType.vote:
        return 'Vote Submission';
      case QueueOperationType.authRefresh:
        return 'Auth Refresh';
      case QueueOperationType.profileUpdate:
        return 'Profile Update';
      case QueueOperationType.notificationAck:
        return 'Notification Ack';
      case QueueOperationType.timetableEvent:
        return 'Timetable Event';
    }
  }

  String _getPriorityText(QueuePriority priority) {
    switch (priority) {
      case QueuePriority.low:
        return 'LOW';
      case QueuePriority.normal:
        return 'NORMAL';
      case QueuePriority.high:
        return 'HIGH';
      case QueuePriority.critical:
        return 'CRITICAL';
    }
  }

  Color _getPriorityColor(QueuePriority priority, ThemeData theme) {
    switch (priority) {
      case QueuePriority.low:
        return theme.colorScheme.onSurfaceVariant;
      case QueuePriority.normal:
        return theme.colorScheme.primary;
      case QueuePriority.high:
        return theme.colorScheme.tertiary;
      case QueuePriority.critical:
        return theme.colorScheme.error;
    }
  }
}