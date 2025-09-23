import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';

/// Quick actions widget for admin dashboard
///
/// Displays configurable action buttons with icons, badges, and 
/// neomorphic design with smooth hover effects.
class AdminQuickActions extends StatefulWidget {
  final List<QuickAction> actions;
  final bool isLoading;

  const AdminQuickActions({
    super.key,
    required this.actions,
    this.isLoading = false,
  });

  @override
  State<AdminQuickActions> createState() => _AdminQuickActionsState();
}

class _AdminQuickActionsState extends State<AdminQuickActions>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _listController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setupAnimations() {
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _setupCardAnimations();
    _listController.forward();
  }

  void _setupCardAnimations() {
    _cardControllers = [];
    _cardAnimations = [];

    final defaultActions = _getDefaultActions();
    final allActions = widget.isLoading ? defaultActions : (widget.actions.isNotEmpty ? widget.actions : defaultActions);

    for (int i = 0; i < allActions.length; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400 + (i * 100)),
        vsync: this,
      );

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.elasticOut,
      ));

      _cardControllers.add(controller);
      _cardAnimations.add(animation);

      // Start animation with staggered delay
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bolt_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Actions Grid
            if (widget.isLoading)
              _buildLoadingGrid(isTablet)
            else
              _buildActionsGrid(theme, isTablet),
          ],
        ),
      ),
    );
  }

  /// Build loading placeholder grid
  Widget _buildLoadingGrid(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildLoadingCard();
      },
    );
  }

  /// Build actions grid with animations
  Widget _buildActionsGrid(ThemeData theme, bool isTablet) {
    final actions = widget.actions.isNotEmpty ? widget.actions : _getDefaultActions();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        if (index < _cardAnimations.length) {
          return AnimatedBuilder(
            animation: _cardAnimations[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[index].value,
                child: Opacity(
                  opacity: _cardAnimations[index].value,
                  child: _buildActionCard(actions[index], theme),
                ),
              );
            },
          );
        }
        return _buildActionCard(actions[index], theme);
      },
    );
  }

  /// Build loading card placeholder
  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: KWASUColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Build individual action card
  Widget _buildActionCard(QuickAction action, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? KWASUColors.grey800 : Colors.white;
    final iconColor = Color(action.colorCode);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2)
                : KWASUColors.grey300.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: action.isEnabled ? () => _handleActionTap(action) : null,
          child: Stack(
            children: [
              // Main content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon with background
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconData(action.iconCode, fontFamily: 'MaterialIcons'),
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      action.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: action.isEnabled 
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Description
                    if (action.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          action.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Badge for notifications
              if (action.badgeCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: KWASUColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      action.badgeCount > 99 ? '99+' : action.badgeCount.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              
              // Disabled overlay
              if (!action.isEnabled)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle action tap
  void _handleActionTap(QuickAction action) {
    // Handle elevated access if required
    if (action.requiresElevatedAccess) {
      _showElevatedAccessDialog(action);
    } else {
      context.push(action.route);
    }
  }

  /// Show elevated access confirmation dialog
  void _showElevatedAccessDialog(QuickAction action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elevated Access Required'),
        content: Text(
          'This action requires elevated administrative privileges. '
          'Are you sure you want to proceed to ${action.title}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(action.route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KWASUColors.warning,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  /// Get default actions when none are provided
  List<QuickAction> _getDefaultActions() {
    return [
      QuickAction(
        id: 'create_election',
        title: 'Create Election',
        description: 'Set up a new election',
        iconCode: Icons.add_box.codePoint,
        colorCode: KWASUColors.primaryBlue.value,
        route: '/admin/elections/create',
      ),
      QuickAction(
        id: 'manage_users',
        title: 'Manage Users',
        description: 'User accounts & roles',
        iconCode: Icons.people_outline.codePoint,
        colorCode: KWASUColors.info.value,
        route: '/admin/users',
      ),
      QuickAction(
        id: 'view_analytics',
        title: 'Analytics',
        description: 'Election insights',
        iconCode: Icons.analytics_outlined.codePoint,
        colorCode: KWASUColors.success.value,
        route: '/admin/analytics',
      ),
      QuickAction(
        id: 'audit_logs',
        title: 'Audit Logs',
        description: 'System activity',
        iconCode: Icons.receipt_long_outlined.codePoint,
        colorCode: KWASUColors.warning.value,
        route: '/admin/audit',
      ),
      QuickAction(
        id: 'system_settings',
        title: 'Settings',
        description: 'System configuration',
        iconCode: Icons.settings_outlined.codePoint,
        colorCode: KWASUColors.grey600.value,
        route: '/admin/settings',
        requiresElevatedAccess: true,
      ),
      QuickAction(
        id: 'bulk_import',
        title: 'Bulk Import',
        description: 'Import users/data',
        iconCode: Icons.upload_file_outlined.codePoint,
        colorCode: KWASUColors.accentGold.value,
        route: '/admin/import',
      ),
    ];
  }
}