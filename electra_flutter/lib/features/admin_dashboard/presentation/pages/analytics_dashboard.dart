import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Analytics dashboard page for viewing election metrics and reports
///
/// Displays comprehensive analytics including turnout metrics,
/// participation data, and exportable reports with data visualization.
class AnalyticsDashboardPage extends ConsumerStatefulWidget {
  const AnalyticsDashboardPage({super.key});

  @override
  ConsumerState<AnalyticsDashboardPage> createState() =>
      _AnalyticsDashboardPageState();
}

class _AnalyticsDashboardPageState
    extends ConsumerState<AnalyticsDashboardPage> {
  bool _isLoading = true;
  String _selectedTimePeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Analytics header
                  _buildAnalyticsHeader(theme),

                  const SizedBox(height: 24),

                  // Time period selector
                  _buildTimePeriodSelector(theme),

                  const SizedBox(height: 24),

                  // Key metrics
                  _buildKeyMetrics(theme, isTablet),

                  const SizedBox(height: 24),

                  // Turnout chart
                  _buildTurnoutChart(theme),

                  const SizedBox(height: 24),

                  // Participation breakdown
                  _buildParticipationBreakdown(theme, isTablet),

                  const SizedBox(height: 24),

                  // Export options
                  _buildExportOptions(theme),
                ],
              ),
            ),
    );
  }

  /// Build analytics header
  Widget _buildAnalyticsHeader(ThemeData theme) {
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
              Icon(Icons.analytics, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Election Insights & Reports',
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
            'Monitor voting patterns, track participation, and generate comprehensive reports.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build time period selector
  Widget _buildTimePeriodSelector(ThemeData theme) {
    final periods = ['This Week', 'This Month', 'This Year', 'All Time'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: periods.map((period) {
                final isSelected = _selectedTimePeriod == period;
                return FilterChip(
                  label: Text(period),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedTimePeriod = period;
                      });
                      _loadAnalyticsData();
                    }
                  },
                  selectedColor: KWASUColors.primaryBlue.withOpacity(0.2),
                  checkmarkColor: KWASUColors.primaryBlue,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build key metrics
  Widget _buildKeyMetrics(ThemeData theme, bool isTablet) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildMetricCard(
          'Total Turnout',
          '75.2%',
          '+5.2% from last month',
          Icons.trending_up,
          KWASUColors.success,
          theme,
        ),
        _buildMetricCard(
          'Active Elections',
          '3',
          '2 ending this week',
          Icons.ballot_outlined,
          KWASUColors.primaryBlue,
          theme,
        ),
        _buildMetricCard(
          'Total Votes Cast',
          '12,456',
          '+1,234 this week',
          Icons.how_to_vote_outlined,
          KWASUColors.info,
          theme,
        ),
        _buildMetricCard(
          'Eligible Voters',
          '16,542',
          '458 new registrations',
          Icons.people_outline,
          KWASUColors.warning,
          theme,
        ),
      ],
    );
  }

  /// Build metric card
  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.trending_up, color: color, size: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

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
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build turnout chart placeholder
  Widget _buildTurnoutChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Turnout Trends',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Turnout Chart',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chart visualization will be implemented with fl_chart',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build participation breakdown
  Widget _buildParticipationBreakdown(ThemeData theme, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participation Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildParticipationCard(
                'Students',
                '68.5%',
                '8,542 / 12,456',
                KWASUColors.primaryBlue,
                theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildParticipationCard(
                'Staff',
                '82.1%',
                '3,914 / 4,768',
                KWASUColors.success,
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build participation card
  Widget _buildParticipationCard(
    String category,
    String percentage,
    String breakdown,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              percentage,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              breakdown,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: 0.685, // Mock value
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
      ),
    );
  }

  /// Build export options
  Widget _buildExportOptions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Reports',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport('CSV'),
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Export CSV'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportReport('PDF'),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportReport('Excel'),
                    icon: const Icon(Icons.file_download),
                    label: const Text('Export Excel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Export report in specified format
  void _exportReport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting analytics report as $format...'),
        backgroundColor: KWASUColors.info,
      ),
    );

    // TODO: Implement export functionality
    // await ref.read(analyticsServiceProvider).exportReport(format, _selectedTimePeriod);
  }

  /// Load analytics data
  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load analytics data from API
    // final analytics = await ref.read(analyticsServiceProvider).getAnalytics(_selectedTimePeriod);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
