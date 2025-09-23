import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';

/// Metrics grid widget displaying key system statistics
///
/// Shows comprehensive dashboard metrics with neomorphic design,
/// smooth animations, and responsive grid layout.
class AdminMetricsGrid extends StatefulWidget {
  final AdminDashboardMetrics metrics;
  final bool isTablet;
  final bool isDesktop;

  const AdminMetricsGrid({
    super.key,
    required this.metrics,
    required this.isTablet,
    required this.isDesktop,
  });

  @override
  State<AdminMetricsGrid> createState() => _AdminMetricsGridState();
}

class _AdminMetricsGridState extends State<AdminMetricsGrid>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setupAnimations() {
    const int itemCount = 8;
    _controllers = [];
    _scaleAnimations = [];
    _fadeAnimations = [];

    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (i * 100)),
        vsync: this,
      );

      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));

      _controllers.add(controller);
      _scaleAnimations.add(scaleAnimation);
      _fadeAnimations.add(fadeAnimation);

      // Start animation with delay
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = widget.isDesktop ? 4 : (widget.isTablet ? 3 : 2);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: widget.isDesktop ? 1.2 : 1.0,
      children: [
        _buildAnimatedMetricCard(
          0,
          'Active Elections',
          widget.metrics.activeElections,
          Icons.ballot_outlined,
          KWASUColors.primaryBlue,
          suffix: '',
        ),
        _buildAnimatedMetricCard(
          1,
          'Total Voters',
          widget.metrics.totalVoters,
          Icons.people_outline,
          KWASUColors.info,
          formatAsNumber: true,
        ),
        _buildAnimatedMetricCard(
          2,
          'Votes Cast',
          widget.metrics.totalVotesCast,
          Icons.how_to_vote_outlined,
          KWASUColors.success,
          formatAsNumber: true,
        ),
        _buildAnimatedMetricCard(
          3,
          'Avg Turnout',
          widget.metrics.averageTurnout.toInt(),
          Icons.trending_up_outlined,
          KWASUColors.accentGold,
          suffix: '%',
        ),
        _buildAnimatedMetricCard(
          4,
          'Active Sessions',
          widget.metrics.activeSessions,
          Icons.wifi_tethering_outlined,
          KWASUColors.secondaryGreen,
          formatAsNumber: true,
        ),
        _buildAnimatedMetricCard(
          5,
          'Security Incidents',
          widget.metrics.securityIncidents,
          Icons.security_outlined,
          widget.metrics.securityIncidents > 0 ? KWASUColors.error : KWASUColors.success,
          suffix: '',
        ),
        _buildAnimatedMetricCard(
          6,
          'System Uptime',
          widget.metrics.systemUptime.toInt(),
          Icons.schedule_outlined,
          KWASUColors.info,
          suffix: 'h',
        ),
        _buildAnimatedMetricCard(
          7,
          'Database Health',
          widget.metrics.databaseHealth,
          Icons.storage_outlined,
          widget.metrics.databaseHealth >= 90 
              ? KWASUColors.success 
              : widget.metrics.databaseHealth >= 70 
              ? KWASUColors.warning 
              : KWASUColors.error,
          suffix: '%',
        ),
      ],
    );
  }

  /// Build animated metric card with neomorphic design
  Widget _buildAnimatedMetricCard(
    int index,
    String title,
    num value,
    IconData icon,
    Color color, {
    String suffix = '',
    bool formatAsNumber = false,
  }) {
    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: ScaleTransition(
            scale: _scaleAnimations[index],
            child: _buildMetricCard(
              title,
              value,
              icon,
              color,
              suffix: suffix,
              formatAsNumber: formatAsNumber,
            ),
          ),
        );
      },
    );
  }

  /// Build individual metric card with neomorphic styling
  Widget _buildMetricCard(
    String title,
    num value,
    IconData icon,
    Color color, {
    String suffix = '',
    bool formatAsNumber = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? KWASUColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Neomorphic outer shadow
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : KWASUColors.grey300.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(4, 4),
          ),
          // Neomorphic inner highlight
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            blurRadius: 12,
            offset: const Offset(-4, -4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onMetricTapped(title),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with colored background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: widget.isDesktop ? 32 : 28,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Value with animated counter
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    formatAsNumber ? _formatLargeNumber(value.toInt()) : '${value.toInt()}$suffix',
                    key: ValueKey(value),
                    style: (widget.isDesktop 
                            ? theme.textTheme.headlineMedium 
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KWASU',
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Trend indicator (mock for now)
                if (_shouldShowTrend(title))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: KWASUColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+12%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: KWASUColors.success,
                            fontWeight: FontWeight.w600,
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

  /// Format large numbers with K/M suffixes
  String _formatLargeNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Check if metric should show trend indicator
  bool _shouldShowTrend(String title) {
    final trendMetrics = ['Total Voters', 'Votes Cast', 'Active Sessions'];
    return trendMetrics.contains(title);
  }

  /// Handle metric card tap
  void _onMetricTapped(String metricTitle) {
    // Show detailed view or navigate to relevant section
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing details for $metricTitle'),
        duration: const Duration(seconds: 2),
        backgroundColor: KWASUColors.primaryBlue,
      ),
    );
  }
}