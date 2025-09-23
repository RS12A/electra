import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vote.dart';
import '../../../../core/theme/app_theme.dart';

/// Offline vote queue widget for displaying queued votes
///
/// Shows offline votes waiting for synchronization with
/// retry controls and connection status indicators.
class OfflineVoteQueueWidget extends ConsumerWidget {
  final List<OfflineVote> queuedVotes;
  final bool isSyncing;
  final VoidCallback? onSync;
  final Function(String)? onRetry;
  final Function(String)? onDelete;

  const OfflineVoteQueueWidget({
    super.key,
    required this.queuedVotes,
    this.isSyncing = false,
    this.onSync,
    this.onRetry,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    if (queuedVotes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KWASUColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KWASUColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.cloud_off,
                color: KWASUColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Offline Votes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KWASUColors.warning,
                  ),
                ),
              ),
              if (onSync != null)
                ElevatedButton.icon(
                  onPressed: isSyncing ? null : onSync,
                  icon: isSyncing 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(isSyncing ? 'Syncing...' : 'Sync All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KWASUColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '${queuedVotes.length} vote${queuedVotes.length > 1 ? 's' : ''} waiting to be submitted when connection is restored.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: KWASUColors.warning,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Vote list
          ...queuedVotes.map((vote) => _buildOfflineVoteCard(vote, theme)),
        ],
      ),
    );
  }

  Widget _buildOfflineVoteCard(OfflineVote vote, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vote info
          Row(
            children: [
              Icon(
                Icons.how_to_vote,
                color: KWASUColors.primaryBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vote ID: ${vote.id.substring(0, 8)}...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildVoteStatusChip(vote, theme),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Queued: ${_formatDateTime(vote.queuedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: KWASUColors.grey600,
            ),
          ),
          
          if (vote.syncResult != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last attempt: ${vote.syncResult}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: vote.isSynced ? KWASUColors.success : KWASUColors.error,
              ),
            ),
          ],
          
          if (vote.nextRetryAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next retry: ${_formatDateTime(vote.nextRetryAt!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: KWASUColors.info,
              ),
            ),
          ],
          
          // Action buttons
          if (!vote.isSynced) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onRetry != null)
                  TextButton.icon(
                    onPressed: () => onRetry!(vote.id),
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: KWASUColors.primaryBlue,
                    ),
                  ),
                const Spacer(),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: () => onDelete!(vote.id),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: KWASUColors.error,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteStatusChip(OfflineVote vote, ThemeData theme) {
    Color color;
    IconData icon;
    String text;
    
    if (vote.isSynced) {
      color = KWASUColors.success;
      icon = Icons.check_circle;
      text = 'Synced';
    } else if (vote.retryCount > 0) {
      color = KWASUColors.error;
      icon = Icons.error;
      text = 'Failed (${vote.retryCount})';
    } else {
      color = KWASUColors.warning;
      icon = Icons.schedule;
      text = 'Pending';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}