import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/constants/app_constants.dart';

/// Main layout wrapper for authenticated app screens
///
/// Provides navigation drawer, app bar, and bottom navigation
/// with role-based access control and notification badges.
class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final theme = Theme.of(context);

    // Get navigation items based on user role
    final navItems = _getNavigationItems(user?.role);

    return Scaffold(
      appBar: _buildAppBar(context, theme, user),
      drawer: _buildDrawer(context, theme, user),
      body: widget.child,
      bottomNavigationBar: _buildBottomNavigationBar(context, theme, navItems),
    );
  }

  /// Build app bar with notifications and user menu
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    User? user,
  ) {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.how_to_vote, color: Colors.white, size: 24),
          const SizedBox(width: 8),
          const Text('Electra'),
        ],
      ),
      actions: [
        // Notifications
        Consumer(
          builder: (context, ref, child) {
            // TODO: Watch notification count provider
            final notificationCount =
                0; // ref.watch(notificationCountProvider);

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => context.go(AppRoutes.notifications),
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: KWASUColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        // Profile menu
        PopupMenuButton<String>(
          icon: CircleAvatar(
            backgroundColor: Colors.white,
            child: Text(
              user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
              style: TextStyle(
                color: KWASUColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onSelected: (value) => _handleProfileMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline),
                  const SizedBox(width: 12),
                  const Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings_outlined),
                  const SizedBox(width: 12),
                  const Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.red),
                  const SizedBox(width: 12),
                  const Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build navigation drawer for larger screens
  Widget? _buildDrawer(BuildContext context, ThemeData theme, User? user) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    if (!isLargeScreen) return null;

    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              color: KWASUColors.primaryBlue,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KWASUColors.primaryBlue, KWASUColors.darkBlue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.how_to_vote, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Electra',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(children: _getDrawerItems(context, user?.role)),
          ),

          // Footer
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom navigation bar
  Widget? _buildBottomNavigationBar(
    BuildContext context,
    ThemeData theme,
    List<NavigationItem> items,
  ) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    if (isLargeScreen) return null;

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
        context.go(items[index].route);
      },
      type: BottomNavigationBarType.fixed,
      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  /// Get navigation items based on user role
  List<NavigationItem> _getNavigationItems(UserRole? role) {
    final items = [
      NavigationItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        route: AppRoutes.home,
      ),
      NavigationItem(
        icon: Icons.how_to_vote_outlined,
        label: 'Vote',
        route: AppRoutes.votingDashboard,
      ),
    ];

    // Add admin items for eligible roles
    if (role == UserRole.admin || role == UserRole.electoralCommittee) {
      items.addAll([
        NavigationItem(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Admin',
          route: AppRoutes.adminDashboard,
        ),
        NavigationItem(
          icon: Icons.analytics_outlined,
          label: 'Analytics',
          route: AppRoutes.analytics,
        ),
      ]);
    }

    return items;
  }

  /// Get drawer items
  List<Widget> _getDrawerItems(BuildContext context, UserRole? role) {
    final items = <Widget>[
      ListTile(
        leading: const Icon(Icons.dashboard_outlined),
        title: const Text('Dashboard'),
        onTap: () => context.go(AppRoutes.home),
      ),
      ListTile(
        leading: const Icon(Icons.how_to_vote_outlined),
        title: const Text('Voting'),
        onTap: () => context.go(AppRoutes.votingDashboard),
      ),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Notifications'),
        onTap: () => context.go(AppRoutes.notifications),
      ),
    ];

    // Add admin items for eligible roles
    if (role == UserRole.admin || role == UserRole.electoralCommittee) {
      items.addAll([
        const Divider(),
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Admin Dashboard'),
          onTap: () => context.go(AppRoutes.adminDashboard),
        ),
        ListTile(
          leading: const Icon(Icons.ballot_outlined),
          title: const Text('Elections'),
          onTap: () => context.go(AppRoutes.electionManagement),
        ),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text('Analytics'),
          onTap: () => context.go(AppRoutes.analytics),
        ),
      ]);
    }

    return items;
  }

  /// Handle profile menu actions
  void _handleProfileMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        // TODO: Navigate to profile page
        break;
      case 'settings':
        // TODO: Navigate to settings page
        break;
      case 'logout':
        _handleLogout(context);
        break;
    }
  }

  /// Handle logout
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement logout logic
              context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
