import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../core/theme/app_theme.dart';

/// Network status indicator widget
///
/// Shows connection status with visual indicators,
/// offline mode warnings, and sync opportunities.
class NetworkStatusWidget extends ConsumerWidget {
  final bool showDetails;
  final VoidCallback? onRetryConnection;

  const NetworkStatusWidget({
    super.key,
    this.showDetails = false,
    this.onRetryConnection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return StreamBuilder<ConnectivityResult>(
      stream: Connectivity().onConnectivityChanged,
      initialData: ConnectivityResult.wifi, // Assume connected initially
      builder: (context, snapshot) {
        final isConnected = snapshot.data != ConnectivityResult.none;
        
        if (isConnected && !showDetails) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected 
                ? KWASUColors.success.withOpacity(0.1)
                : KWASUColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnected 
                  ? KWASUColors.success.withOpacity(0.3)
                  : KWASUColors.error.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                color: isConnected ? KWASUColors.success : KWASUColors.error,
                size: 20,
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? 'Online' : 'Offline',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isConnected ? KWASUColors.success : KWASUColors.error,
                      ),
                    ),
                    if (showDetails || !isConnected)
                      Text(
                        isConnected 
                            ? 'All features available'
                            : 'Votes will be queued for later submission',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: KWASUColors.grey600,
                        ),
                      ),
                  ],
                ),
              ),
              
              if (!isConnected && onRetryConnection != null)
                TextButton.icon(
                  onPressed: onRetryConnection,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(
                    foregroundColor: KWASUColors.primaryBlue,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}