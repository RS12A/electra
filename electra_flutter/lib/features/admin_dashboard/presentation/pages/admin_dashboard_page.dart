import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Admin dashboard page for electoral committee and administrators
///
/// Provides overview of all elections, user management, and system
/// monitoring capabilities with role-based access controls.
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Admin header
                    _buildAdminHeader(theme),

                    const SizedBox(height: 24),

                    // Quick stats grid
                    _buildQuickStats(theme, isTablet),

                    const SizedBox(height: 24),

                    // Recent elections
                    _buildRecentElections(theme),

                    const SizedBox(height: 24),

                    // System status
                    _buildSystemStatus(theme),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(theme, isTablet),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build admin header
  Widget _buildAdminHeader(ThemeData theme) {
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
              Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Electoral Committee Portal',
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
            'Monitor elections, manage users, and ensure system integrity.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build quick stats grid
  Widget _buildQuickStats(ThemeData theme, bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Elections',
          '12',
          Icons.ballot_outlined,
          KWASUColors.primaryBlue,
          theme,
        ),
        _buildStatCard(
          'Active Elections',
          '3',
          Icons.how_to_vote_outlined,
          KWASUColors.success,
          theme,
        ),
        _buildStatCard(
          'Total Votes',
          '8,456',
          Icons.people_outline,
          KWASUColors.info,
          theme,
        ),
        _buildStatCard(
          'System Health',
          '99.9%',
          Icons.health_and_safety_outlined,
          KWASUColors.success,
          theme,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
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

  /// Build recent elections section
  Widget _buildRecentElections(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Elections',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to elections management
              },
              child: const Text('View All'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: [
              _buildElectionListItem(
                'Student Union Executive Elections 2024',
                'Active • 6 days remaining',
                '3,245 eligible • 1,856 voted',
                Icons.how_to_vote,
                KWASUColors.success,
                theme,
              ),
              const Divider(height: 1),
              _buildElectionListItem(
                'Faculty Representative Elections',
                'Active • 14 days remaining',
                '2,180 eligible • 892 voted',
                Icons.how_to_vote,
                KWASUColors.success,
                theme,
              ),
              const Divider(height: 1),
              _buildElectionListItem(
                'Course Representative Elections',
                'Completed',
                '5,420 eligible • 4,321 voted',
                Icons.check_circle,
                KWASUColors.info,
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build election list item
  Widget _buildElectionListItem(
    String title,
    String status,
    String stats,
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
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status),
          Text(
            stats,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.arrow_forward_ios),
        onPressed: () {
          // TODO: Navigate to election details
        },
      ),
    );
  }

  /// Build system status section
  Widget _buildSystemStatus(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildStatusItem(
                  'Database',
                  'Healthy',
                  KWASUColors.success,
                  theme,
                ),
                const Divider(),
                _buildStatusItem(
                  'API Server',
                  'Healthy',
                  KWASUColors.success,
                  theme,
                ),
                const Divider(),
                _buildStatusItem(
                  'Storage',
                  'Healthy',
                  KWASUColors.success,
                  theme,
                ),
                const Divider(),
                _buildStatusItem(
                  'Security',
                  'All checks passed',
                  KWASUColors.success,
                  theme,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build system status item
  Widget _buildStatusItem(
    String component,
    String status,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            component,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          status,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build quick actions section
  Widget _buildQuickActions(ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isTablet ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              'Create Election',
              Icons.add_box,
              KWASUColors.primaryBlue,
              () {
                // TODO: Navigate to create election
              },
              theme,
            ),
            _buildActionCard(
              'Manage Users',
              Icons.people_outline,
              KWASUColors.info,
              () {
                // TODO: Navigate to user management
              },
              theme,
            ),
            _buildActionCard(
              'View Reports',
              Icons.analytics_outlined,
              KWASUColors.success,
              () {
                // TODO: Navigate to reports
              },
              theme,
            ),
            _buildActionCard(
              'System Logs',
              Icons.list_alt,
              KWASUColors.warning,
              () {
                // TODO: Navigate to logs
              },
              theme,
            ),
            _buildActionCard('Backup Data', Icons.backup, KWASUColors.info, () {
              // TODO: Trigger backup
            }, theme),
            _buildActionCard(
              'Settings',
              Icons.settings,
              KWASUColors.grey600,
              () {
                // TODO: Navigate to settings
              },
              theme,
            ),
          ],
        ),
      ],
    );
  }

  /// Build action card
  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Load admin dashboard data
  Future<void> _loadAdminData() async {
    // TODO: Load admin dashboard data from API
    // final stats = await ref.read(adminServiceProvider).getDashboardStats();
    // final elections = await ref.read(electionServiceProvider).getRecentElections();
    // final systemStatus = await ref.read(systemServiceProvider).getSystemStatus();

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
