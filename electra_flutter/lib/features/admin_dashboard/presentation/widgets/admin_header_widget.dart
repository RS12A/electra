import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';

/// Admin dashboard header widget with animated gradient and metrics overview
///
/// Displays key information and branding with smooth animations and 
/// responsive design for various screen sizes.
class AdminHeaderWidget extends StatefulWidget {
  final AdminDashboardMetrics? metrics;
  final bool isLoading;

  const AdminHeaderWidget({
    super.key,
    this.metrics,
    this.isLoading = false,
  });

  @override
  State<AdminHeaderWidget> createState() => _AdminHeaderWidgetState();
}

class _AdminHeaderWidgetState extends State<AdminHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _contentController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KWASUColors.primaryBlue,
            KWASUColors.darkBlue,
            KWASUColors.primaryBlue.withOpacity(0.8),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: KWASUColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  // Admin Icon with Animation
                  AnimatedBuilder(
                    animation: _backgroundController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: isDesktop ? 40 : 32,
                        ),
                      );
                    },
                  ),

                  SizedBox(width: isTablet ? 20 : 16),

                  // Title and Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: (isDesktop
                                  ? theme.textTheme.headlineMedium
                                  : theme.textTheme.headlineSmall)
                              ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KWASU',
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 8 : 4),
                        
                        Text(
                          'KWASU Electoral Committee Portal',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Indicator
                  if (widget.metrics != null && !widget.isLoading)
                    _buildStatusIndicator(theme),
                ],
              ),

              SizedBox(height: isTablet ? 24 : 16),

              // Description and Key Stats
              Text(
                'Monitor elections, manage users, and ensure system integrity with comprehensive administrative tools.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  height: 1.5,
                ),
              ),

              if (widget.metrics != null && isDesktop) ...[
                const SizedBox(height: 24),
                _buildQuickStats(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build system status indicator
  Widget _buildStatusIndicator(ThemeData theme) {
    final metrics = widget.metrics!;
    final isHealthy = metrics.databaseHealth >= 90 && 
                     metrics.securityIncidents == 0 &&
                     metrics.apiResponseTime < 500;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHealthy ? KWASUColors.success : KWASUColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isHealthy ? 'System Healthy' : 'Attention Required',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build quick stats for desktop view
  Widget _buildQuickStats(ThemeData theme) {
    final metrics = widget.metrics!;
    
    return Row(
      children: [
        _buildQuickStat(
          'Active Elections',
          metrics.activeElections.toString(),
          Icons.ballot_outlined,
          theme,
        ),
        const SizedBox(width: 32),
        _buildQuickStat(
          'Total Voters',
          _formatNumber(metrics.totalVoters),
          Icons.people_outline,
          theme,
        ),
        const SizedBox(width: 32),
        _buildQuickStat(
          'Avg Turnout',
          '${metrics.averageTurnout.toStringAsFixed(1)}%',
          Icons.trending_up_outlined,
          theme,
        ),
        if (metrics.alertCount > 0) ...[
          const SizedBox(width: 32),
          _buildQuickStat(
            'Alerts',
            metrics.alertCount.toString(),
            Icons.warning_amber_outlined,
            theme,
            color: KWASUColors.warning,
          ),
        ],
      ],
    );
  }

  /// Build individual quick stat
  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color ?? Colors.white.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Format large numbers with K/M suffixes
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}