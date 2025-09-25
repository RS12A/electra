import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Voting dashboard page showing available elections and voting status
///
/// Displays active elections, voting history, and provides navigation
/// to cast votes with proper eligibility checking.
class VotingDashboardPage extends ConsumerStatefulWidget {
  const VotingDashboardPage({super.key});

  @override
  ConsumerState<VotingDashboardPage> createState() =>
      _VotingDashboardPageState();
}

class _VotingDashboardPageState extends ConsumerState<VotingDashboardPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome section
                    _buildWelcomeSection(theme),

                    const SizedBox(height: 24),

                    // Quick stats
                    _buildQuickStats(theme, isTablet),

                    const SizedBox(height: 24),

                    // Active elections
                    _buildActiveElections(theme, isTablet),

                    const SizedBox(height: 24),

                    // Recent activity
                    _buildRecentActivity(theme),
                  ],
                ),
              ),
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KWASUColors.primaryBlue, KWASUColors.darkBlue],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.how_to_vote, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Electra',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Secure Digital Voting System',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Exercise your democratic right. Your vote is secure, anonymous, and counts.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build quick stats section
  Widget _buildQuickStats(ThemeData theme, bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active Elections',
            '3',
            Icons.ballot_outlined,
            KWASUColors.primaryBlue,
            theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Votes Cast',
            '1',
            Icons.check_circle_outline,
            KWASUColors.success,
            theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Pending',
            '2',
            Icons.schedule,
            KWASUColors.warning,
            theme,
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build active elections section
  Widget _buildActiveElections(ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Elections',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Mock election cards
        _buildElectionCard(
          'Student Union Executive Elections 2024',
          'Vote for your student union representatives',
          DateTime.now().add(const Duration(days: 7)),
          false,
          'election_1',
          theme,
        ),

        const SizedBox(height: 12),

        _buildElectionCard(
          'Faculty Representative Elections',
          'Choose your faculty representatives',
          DateTime.now().add(const Duration(days: 14)),
          false,
          'election_2',
          theme,
        ),

        const SizedBox(height: 12),

        _buildElectionCard(
          'Course Representative Elections',
          'Select your course representatives',
          DateTime.now().subtract(const Duration(hours: 2)),
          true,
          'election_3',
          theme,
        ),
      ],
    );
  }

  /// Build individual election card
  Widget _buildElectionCard(
    String title,
    String description,
    DateTime endTime,
    bool hasVoted,
    String electionId,
    ThemeData theme,
  ) {
    final isActive = endTime.isAfter(DateTime.now());
    final timeLeft = isActive
        ? endTime.difference(DateTime.now())
        : DateTime.now().difference(endTime);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasVoted
                        ? KWASUColors.success.withOpacity(0.1)
                        : isActive
                        ? KWASUColors.primaryBlue.withOpacity(0.1)
                        : KWASUColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasVoted
                        ? 'Voted'
                        : isActive
                        ? 'Active'
                        : 'Closed',
                    style: TextStyle(
                      color: hasVoted
                          ? KWASUColors.success
                          : isActive
                          ? KWASUColors.primaryBlue
                          : KWASUColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time info
            Row(
              children: [
                Icon(
                  isActive ? Icons.schedule : Icons.check_circle,
                  size: 16,
                  color: isActive ? KWASUColors.warning : KWASUColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  isActive
                      ? 'Ends in ${_formatDuration(timeLeft)}'
                      : hasVoted
                      ? 'You voted ${_formatDuration(timeLeft)} ago'
                      : 'Ended ${_formatDuration(timeLeft)} ago',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasVoted || !isActive
                    ? null
                    : () => AppNavigation.toCastVote(context, electionId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasVoted
                      ? KWASUColors.success
                      : KWASUColors.primaryBlue,
                ),
                child: Text(hasVoted ? 'View Receipt' : 'Cast Vote'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build recent activity section
  Widget _buildRecentActivity(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildActivityItem(
                'Vote cast successfully',
                'Course Representative Elections',
                DateTime.now().subtract(const Duration(hours: 2)),
                Icons.check_circle,
                KWASUColors.success,
                theme,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Ballot token received',
                'Student Union Executive Elections 2024',
                DateTime.now().subtract(const Duration(hours: 4)),
                Icons.verified_user,
                KWASUColors.primaryBlue,
                theme,
              ),
              const Divider(height: 1),
              _buildActivityItem(
                'Election notification',
                'New elections are now available',
                DateTime.now().subtract(const Duration(days: 1)),
                Icons.notifications,
                KWASUColors.warning,
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual activity item
  Widget _buildActivityItem(
    String title,
    String subtitle,
    DateTime time,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Text(
        _formatTime(time),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Just now';
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }

  /// Load dashboard data
  Future<void> _loadDashboardData() async {
    // Implement data loading from API
    // In production, this would fetch real election and vote data
    try {
      // Simulate fetching active elections
      // final elections = await ref.read(electionServiceProvider).getActiveElections();
      // final userVotes = await ref.read(voteServiceProvider).getUserVotes();
      
      // For now, simulate successful API call
      await Future.delayed(const Duration(seconds: 1));
      
      // In a real implementation, update state with fetched data
      // setState(() {
      //   _activeElections = elections;
      //   _userVotes = userVotes;
      //   _isLoading = false;
      // });
      
    } catch (error) {
      // Handle API errors appropriately
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
