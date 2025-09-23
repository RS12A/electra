import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../providers/admin_election_providers.dart';

/// Recent elections overview widget for admin dashboard
///
/// Displays recent election activity with status indicators,
/// quick actions, and navigation to full election management.
class AdminRecentElections extends ConsumerStatefulWidget {
  final VoidCallback onViewAll;

  const AdminRecentElections({
    super.key,
    required this.onViewAll,
  });

  @override
  ConsumerState<AdminRecentElections> createState() => _AdminRecentElectionsState();
}

class _AdminRecentElectionsState extends ConsumerState<AdminRecentElections>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late List<AnimationController> _itemControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _listController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setupAnimations() {
    _listController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _itemControllers = [];
    _fadeAnimations = [];
    _slideAnimations = [];

    // Create animations for up to 5 items
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (i * 100)),
        vsync: this,
      );

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ));

      _itemControllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _slideAnimations.add(slideAnimation);

      // Start animations with staggered delay
      Future.delayed(Duration(milliseconds: 200 + (i * 150)), () {
        if (mounted) controller.forward();
      });
    }

    _listController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final electionsAsync = ref.watch(adminElectionsProvider(limit: 5));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(theme),
            
            const SizedBox(height: 20),
            
            // Elections list
            electionsAsync.when(
              loading: () => _buildLoadingList(),
              error: (error, stack) => _buildErrorState(error.toString(), theme),
              data: (elections) => elections.isEmpty 
                  ? _buildEmptyState(theme)
                  : _buildElectionsList(elections, theme),
            ),
          ],
        ),
      ),
    );
  }

  /// Build widget header
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.ballot_outlined,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Recent Elections',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          label: const Text('View All'),
          onPressed: widget.onViewAll,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Build loading list placeholder
  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildLoadingItem(),
        ),
      ),
    );
  }

  /// Build loading item placeholder
  Widget _buildLoadingItem() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: KWASUColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KWASUColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: KWASUColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: KWASUColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load recent elections: $error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: KWASUColors.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminElectionsProvider()),
            color: KWASUColors.error,
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.ballot_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Elections Yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first election to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Election'),
            onPressed: () => context.push('/admin/elections/create'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KWASUColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build elections list
  Widget _buildElectionsList(List<dynamic> elections, ThemeData theme) {
    return Column(
      children: elections.asMap().entries.map((entry) {
        final index = entry.key;
        final election = entry.value;
        
        if (index < _fadeAnimations.length) {
          return AnimatedBuilder(
            animation: _itemControllers[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildElectionItem(election, theme),
                  ),
                ),
              );
            },
          );
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildElectionItem(election, theme),
        );
      }).toList(),
    );
  }

  /// Build individual election item
  Widget _buildElectionItem(dynamic election, ThemeData theme) {
    // Mock data structure - replace with actual AdminElection when available
    final title = election?.title ?? 'Sample Election';
    final status = election?.status?.toString() ?? 'draft';
    final startDate = election?.startDate ?? DateTime.now();
    final votesCast = election?.votesCast ?? 0;
    final eligibleVoters = election?.eligibleVoters ?? 100;
    
    final statusColor = _getStatusColor(status);
    final progress = eligibleVoters > 0 ? (votesCast / eligibleVoters) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _onElectionTap(election),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Date
                    Text(
                      _formatDate(startDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Title
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Progress and stats
                Row(
                  children: [
                    // Progress indicator
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Turnout',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 4,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Vote counts
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$votesCast votes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'of $eligibleVoters',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Quick actions for active elections
                if (status.toLowerCase() == 'active') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Monitor'),
                        onPressed: () => _monitorElection(election),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: statusColor,
                          side: BorderSide(color: statusColor),
                          minimumSize: const Size(80, 28),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.stop, size: 16),
                        label: const Text('Close'),
                        onPressed: () => _closeElection(election),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KWASUColors.error,
                          side: BorderSide(color: KWASUColors.error),
                          minimumSize: const Size(80, 28),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return KWASUColors.success;
      case 'scheduled':
      case 'pending':
        return KWASUColors.info;
      case 'completed':
        return KWASUColors.primaryBlue;
      case 'cancelled':
      case 'suspended':
        return KWASUColors.error;
      default:
        return KWASUColors.grey600;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Handle election item tap
  void _onElectionTap(dynamic election) {
    final electionId = election?.id ?? 'sample';
    context.push('/admin/elections/$electionId');
  }

  /// Monitor election
  void _monitorElection(dynamic election) {
    final electionId = election?.id ?? 'sample';
    context.push('/admin/elections/$electionId/monitor');
  }

  /// Close election
  void _closeElection(dynamic election) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Election'),
        content: Text(
          'Are you sure you want to close "${election?.title ?? 'this election'}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement close election
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Election closed successfully'),
                  backgroundColor: KWASUColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KWASUColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}