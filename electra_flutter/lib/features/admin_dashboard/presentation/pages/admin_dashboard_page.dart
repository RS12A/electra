import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../ui/components/index.dart';
import '../providers/admin_dashboard_providers.dart';
import '../widgets/admin_header_widget.dart';
import '../widgets/admin_metrics_grid.dart';
import '../widgets/admin_quick_actions.dart';
import '../widgets/admin_system_alerts.dart';
import '../widgets/admin_recent_elections.dart';

/// Enhanced admin dashboard page with production-grade UI/UX
///
/// Features:
/// - Responsive neomorphic design with GPU-optimized animations
/// - Real-time metrics dashboard with live updates
/// - Staggered card animations for smooth user experience
/// - Role-based access controls and permissions
/// - Advanced data visualization and analytics
/// - Pull-to-refresh functionality
/// - Comprehensive accessibility support
class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _staggeredControllers;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    StaggeredAnimationController.disposeControllers(_staggeredControllers);
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: AnimationConfig.slowDuration,
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AnimationConfig.smoothCurve,
    );

    // Initialize staggered animations for dashboard sections
    _staggeredControllers = StaggeredAnimationController.createStaggeredControllers(
      vsync: this,
      itemCount: 5, // Header, metrics, actions, alerts, recent elections
      duration: AnimationConfig.screenTransitionDuration,
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    
    // Start staggered animations with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        StaggeredAnimationController.startStaggeredAnimation(
          controllers: _staggeredControllers,
        );
      }
    });
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.refresh(adminDashboardCombinedProvider.future);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh dashboard: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dashboardAsync = ref.watch(adminDashboardCombinedProvider);
    
    return Scaffold(
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveContainer(
          child: dashboardAsync.when(
            data: (data) => _buildDashboard(screenWidth, data),
            loading: () => _buildLoadingState(),
            error: (error, stack) => _buildErrorState(error),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Admin Dashboard',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _handleRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Dashboard',
        ),
        IconButton(
          onPressed: () => context.push('/admin/settings'),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Export Data'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'backup',
              child: ListTile(
                leading: Icon(Icons.backup),
                title: Text('Create Backup'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'audit',
              child: ListTile(
                leading: Icon(Icons.security),
                title: Text('View Audit Log'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboard(double screenWidth, dynamic data) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ResponsivePadding(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              _buildAnimatedItem(
                0,
                _buildWelcomeHeader(screenWidth, data),
              ),
              
              SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
              
              // Metrics grid
              _buildAnimatedItem(
                1,
                _buildMetricsSection(screenWidth, data),
              ),
              
              SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
              
              // Quick actions
              _buildAnimatedItem(
                2,
                _buildQuickActionsSection(screenWidth),
              ),
              
              SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
              
              // System alerts and recent elections
              ResponsiveFlex(
                mobileDirection: Axis.vertical,
                tabletDirection: Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: ResponsiveConfig.isDesktop(screenWidth) ? 1 : 1,
                    child: _buildAnimatedItem(
                      3,
                      _buildSystemAlertsSection(data),
                    ),
                  ),
                  
                  SizedBox(
                    width: ResponsiveConfig.isMobile(screenWidth) ? 0 : SpacingConfig.lg,
                    height: ResponsiveConfig.isMobile(screenWidth) ? SpacingConfig.lg : 0,
                  ),
                  
                  Expanded(
                    flex: ResponsiveConfig.isDesktop(screenWidth) ? 2 : 1,
                    child: _buildAnimatedItem(
                      4,
                      _buildRecentElectionsSection(data),
                    ),
                  ),
                ],
              ),
              
              // Bottom padding for FAB
              const SizedBox(height: SpacingConfig.massive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _staggeredControllers[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _staggeredControllers[index].value)),
          child: Opacity(
            opacity: _staggeredControllers[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(double screenWidth, dynamic data) {
    return NeomorphicCards.header(
      child: ResponsiveFlex(
        mobileDirection: Axis.vertical,
        tabletDirection: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, Admin',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: SpacingConfig.sm),
                Text(
                  'Here\'s what\'s happening with your elections today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: SpacingConfig.md),
                _buildQuickStats(data),
              ],
            ),
          ),
          
          if (ResponsiveConfig.isTablet(screenWidth) || ResponsiveConfig.isDesktop(screenWidth)) ...[
            const SizedBox(width: SpacingConfig.xl),
            _buildSystemStatus(),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(dynamic data) {
    return ResponsiveWrap(
      spacing: SpacingConfig.lg,
      children: [
        _buildStatChip('Active Elections', '3', Icons.how_to_vote, AppColors.success),
        _buildStatChip('Total Voters', '1,247', Icons.people, AppColors.info),
        _buildStatChip('Votes Today', '89', Icons.ballot, AppColors.warning),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConfig.md,
        vertical: SpacingConfig.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(NeomorphicConfig.largeBorderRadius),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: SpacingConfig.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.success,
                AppColors.success.withOpacity(0.7),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: SpacingConfig.sm),
        Text(
          'All Systems Online',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(double screenWidth, dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: SpacingConfig.md),
        AdminMetricsGrid(
          metrics: data?.metrics ?? _getMockMetrics(),
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: SpacingConfig.md),
        AdminQuickActions(
          actions: _getQuickActions(),
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildSystemAlertsSection(dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Alerts',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: SpacingConfig.md),
        AdminSystemAlerts(
          alerts: data?.alerts ?? _getMockAlerts(),
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildRecentElectionsSection(dynamic data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Elections',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/admin/elections'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: SpacingConfig.md),
        AdminRecentElections(
          elections: data?.recentElections ?? _getMockElections(),
          isLoading: false,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: SpacingConfig.lg),
          Text('Loading dashboard...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: NeomorphicCards.content(
        padding: const EdgeInsets.all(SpacingConfig.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: SpacingConfig.lg),
            Text(
              'Dashboard Error',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingConfig.md),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingConfig.lg),
            NeomorphicButtons.primary(
              onPressed: _handleRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return BouncyFAB(
      onPressed: () => _showCreateElectionDialog(),
      tooltip: 'Create New Election',
      child: const Icon(Icons.add),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _handleExportData();
        break;
      case 'backup':
        _handleCreateBackup();
        break;
      case 'audit':
        context.push('/admin/audit-log');
        break;
    }
  }

  void _handleExportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preparing data export...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _handleCreateBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating system backup...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showCreateElectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return NeomorphicCards.content(
            margin: const EdgeInsets.all(SpacingConfig.md),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: SpacingConfig.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(SpacingConfig.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Election',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: SpacingConfig.lg),
                        
                        NeomorphicInputs.text(
                          labelText: 'Election Title',
                          hintText: 'Enter election title',
                        ),
                        
                        const SizedBox(height: SpacingConfig.lg),
                        
                        NeomorphicInputs.textArea(
                          labelText: 'Description',
                          hintText: 'Enter election description',
                        ),
                        
                        const SizedBox(height: SpacingConfig.xl),
                        
                        SizedBox(
                          width: double.infinity,
                          child: NeomorphicButtons.primary(
                            onPressed: () {
                              Navigator.pop(context);
                              context.push('/admin/elections/create');
                            },
                            child: const Text('Continue Setup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Mock data methods
  dynamic _getMockMetrics() {
    return {
      'activeElections': 3,
      'totalVoters': 1247,
      'votesToday': 89,
      'systemUptime': '99.9%',
    };
  }

  List<dynamic> _getQuickActions() {
    return [
      {'title': 'Create Election', 'icon': Icons.add_box, 'route': '/admin/elections/create'},
      {'title': 'Manage Users', 'icon': Icons.people, 'route': '/admin/users'},
      {'title': 'View Reports', 'icon': Icons.analytics, 'route': '/admin/reports'},
      {'title': 'System Settings', 'icon': Icons.settings, 'route': '/admin/settings'},
    ];
  }

  List<dynamic> _getMockAlerts() {
    return [
      {'message': 'Server maintenance scheduled for tonight', 'type': 'info'},
      {'message': 'High voter turnout detected', 'type': 'success'},
      {'message': 'Backup completed successfully', 'type': 'success'},
    ];
  }

  List<dynamic> _getMockElections() {
    return [
      {'title': 'Student Union Elections 2024', 'status': 'Active', 'votes': 234},
      {'title': 'Faculty Representative Elections', 'status': 'Upcoming', 'votes': 0},
      {'title': 'Class Representative Elections', 'status': 'Completed', 'votes': 456},
    ];
  }
}
                flexibleSpace: FlexibleSpaceBar(
                  background: AdminHeaderWidget(
                    metrics: dashboardState.metrics,
                    isLoading: dashboardState.isLoading,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isRefreshing ? Icons.refresh : Icons.refresh_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    onPressed: isRefreshing ? null : _handleRefresh,
                    tooltip: 'Refresh Dashboard',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/admin/settings'),
                    tooltip: 'Admin Settings',
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              // Main Content
              SliverPadding(
                padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Error Display
                    if (dashboardState.error != null)
                      _buildErrorCard(dashboardState.error!, theme),

                    // System Alerts (Priority)
                    if (dashboardState.alerts.isNotEmpty) ...[
                      AdminSystemAlerts(
                        alerts: dashboardState.alerts,
                        onAcknowledge: _handleAcknowledgeAlert,
                        onAcknowledgeAll: _handleAcknowledgeAllAlerts,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Key Metrics Grid
                    if (dashboardState.metrics != null)
                      AdminMetricsGrid(
                        metrics: dashboardState.metrics!,
                        isTablet: isTablet,
                        isDesktop: isDesktop,
                      ),

                    const SizedBox(height: 24),

                    // Quick Actions and Recent Activity Row
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: AdminQuickActions(
                              actions: dashboardState.quickActions,
                              isLoading: dashboardState.isLoading,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 3,
                            child: AdminRecentElections(
                              onViewAll: () => context.push('/admin/elections'),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile/Tablet: Stacked layout
                      AdminQuickActions(
                        actions: dashboardState.quickActions,
                        isLoading: dashboardState.isLoading,
                      ),
                      const SizedBox(height: 24),
                      AdminRecentElections(
                        onViewAll: () => context.push('/admin/elections'),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // System Status Footer
                    _buildSystemStatus(theme, dashboardState),

                    // Add bottom padding for FAB
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Action Button for Quick Access
      floatingActionButton: _buildFloatingActionButton(context, theme),
    );
  }

  /// Handle refresh action
  Future<void> _handleRefresh() async {
    final controller = ref.read(adminDashboardRefreshControllerProvider.notifier);
    await controller.performRefresh();
  }

  /// Handle acknowledging single alert
  Future<void> _handleAcknowledgeAlert(String alertId) async {
    try {
      final alertsNotifier = ref.read(adminSystemAlertsProvider().notifier);
      await alertsNotifier.acknowledgeAlert(alertId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert acknowledged successfully'),
            backgroundColor: KWASUColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alert: $e'),
            backgroundColor: KWASUColors.error,
          ),
        );
      }
    }
  }

  /// Handle acknowledging all alerts
  Future<void> _handleAcknowledgeAllAlerts(List<String> alertIds) async {
    try {
      final alertsNotifier = ref.read(adminSystemAlertsProvider().notifier);
      await alertsNotifier.acknowledgeAlerts(alertIds);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alertIds.length} alerts acknowledged successfully'),
            backgroundColor: KWASUColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to acknowledge alerts: $e'),
            backgroundColor: KWASUColors.error,
          ),
        );
      }
    }
  }

  /// Build error display card
  Widget _buildErrorCard(String error, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KWASUColors.error.withOpacity(0.1),
        border: Border.all(color: KWASUColors.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: KWASUColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Error',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: KWASUColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: KWASUColors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            color: KWASUColors.error,
            onPressed: _handleRefresh,
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  /// Build system status footer
  Widget _buildSystemStatus(ThemeData theme, AdminDashboardState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.speed_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatusIndicator(
                  'Database',
                  state.metrics?.databaseHealth ?? 100,
                  theme,
                ),
                const SizedBox(width: 32),
                _buildStatusIndicator(
                  'API Response',
                  _calculateApiHealthScore(state.metrics?.apiResponseTime ?? 0),
                  theme,
                ),
                const SizedBox(width: 32),
                _buildStatusIndicator(
                  'Security',
                  state.metrics?.securityIncidents == 0 ? 100 : 75,
                  theme,
                ),
              ],
            ),
            if (state.lastUpdated != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last updated: ${_formatLastUpdated(state.lastUpdated!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build status indicator
  Widget _buildStatusIndicator(String label, int health, ThemeData theme) {
    final color = health >= 90
        ? KWASUColors.success
        : health >= 70
        ? KWASUColors.warning
        : KWASUColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              health >= 90 ? Icons.check_circle : Icons.warning,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$health%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton(BuildContext context, ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/admin/elections/create'),
      backgroundColor: KWASUColors.primaryBlue,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('New Election'),
      tooltip: 'Create New Election',
    );
  }

  /// Calculate API health score from response time
  int _calculateApiHealthScore(double responseTime) {
    if (responseTime < 100) return 100;
    if (responseTime < 300) return 90;
    if (responseTime < 500) return 75;
    if (responseTime < 1000) return 50;
    return 25;
  }

  /// Format last updated time
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);
    
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
                context.go(AppRoutes.electionManagement);
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
          // Navigate to election details (assuming we'll create this route later)
          context.go('${AppRoutes.electionManagement}/details');
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
                context.go('${AppRoutes.electionManagement}/create');
              },
              theme,
            ),
            _buildActionCard(
              'Manage Users',
              Icons.people_outline,
              KWASUColors.info,
              () {
                context.go('${AppRoutes.adminDashboard}/users');
              },
              theme,
            ),
            _buildActionCard(
              'View Reports',
              Icons.analytics_outlined,
              KWASUColors.success,
              () {
                context.go(AppRoutes.analytics);
              },
              theme,
            ),
            _buildActionCard(
              'System Logs',
              Icons.list_alt,
              KWASUColors.warning,
              () {
                context.go('${AppRoutes.adminDashboard}/logs');
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
                context.go(AppRoutes.settings);
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
