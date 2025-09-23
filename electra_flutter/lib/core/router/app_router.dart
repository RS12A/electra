import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/voting/presentation/pages/voting_dashboard_page.dart';
import '../../features/voting/presentation/pages/cast_vote_page.dart';
import '../../features/voting/presentation/pages/ballot_verification_page.dart';
import '../../features/admin_dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin_dashboard/presentation/pages/election_management_page.dart';
import '../../features/analytics/presentation/pages/analytics_dashboard_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../shared/widgets/layout/main_layout.dart';
import '../../shared/widgets/layout/auth_layout.dart';
import '../error/error_page.dart';

/// Application route names and paths
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main routes
  static const String home = '/';
  static const String votingDashboard = '/voting';
  static const String castVote = '/voting/cast';
  static const String ballotVerification = '/voting/verify';

  // Admin routes
  static const String adminDashboard = '/admin';
  static const String electionManagement = '/admin/elections';

  // Analytics routes
  static const String analytics = '/analytics';

  // Other routes
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

/// Main router configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated
        ? AppRoutes.home
        : AppRoutes.login,
    debugLogDiagnostics: true,

    // Redirect logic for authentication
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthPage = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ].contains(state.location);

      // If not authenticated and not on auth page, redirect to login
      if (!isAuthenticated && !isOnAuthPage) {
        return AppRoutes.login;
      }

      // If authenticated and on auth page, redirect to home
      if (isAuthenticated && isOnAuthPage) {
        return AppRoutes.home;
      }

      return null; // No redirect needed
    },

    routes: [
      // Auth routes wrapped in AuthLayout
      ShellRoute(
        builder: (context, state, child) => AuthLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.login,
            name: 'login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: AppRoutes.register,
            name: 'register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordPage(),
          ),
        ],
      ),

      // Main app routes wrapped in MainLayout
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Home/Voting Dashboard
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const VotingDashboardPage(),
          ),

          // Voting routes
          GoRoute(
            path: AppRoutes.votingDashboard,
            name: 'voting-dashboard',
            builder: (context, state) => const VotingDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.castVote,
            name: 'cast-vote',
            builder: (context, state) {
              final electionId = state.queryParameters['electionId'];
              return CastVotePage(electionId: electionId);
            },
          ),
          GoRoute(
            path: AppRoutes.ballotVerification,
            name: 'ballot-verification',
            builder: (context, state) {
              final voteToken = state.queryParameters['voteToken'];
              return BallotVerificationPage(voteToken: voteToken);
            },
          ),

          // Admin routes (role-protected)
          GoRoute(
            path: AppRoutes.adminDashboard,
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardPage(),
            redirect: (context, state) {
              final userRole = authState.user?.role;
              if (userRole != UserRole.admin &&
                  userRole != UserRole.electoralCommittee) {
                return AppRoutes.home; // Redirect non-admin users
              }
              return null;
            },
          ),
          GoRoute(
            path: AppRoutes.electionManagement,
            name: 'election-management',
            builder: (context, state) => const ElectionManagementPage(),
            redirect: (context, state) {
              final userRole = authState.user?.role;
              if (userRole != UserRole.admin &&
                  userRole != UserRole.electoralCommittee) {
                return AppRoutes.home;
              }
              return null;
            },
          ),

          // Analytics routes (role-protected)
          GoRoute(
            path: AppRoutes.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsDashboardPage(),
            redirect: (context, state) {
              final userRole = authState.user?.role;
              if (userRole != UserRole.admin &&
                  userRole != UserRole.electoralCommittee) {
                return AppRoutes.home;
              }
              return null;
            },
          ),

          // Other routes
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
        ],
      ),
    ],

    // Error page for invalid routes
    errorBuilder: (context, state) => ErrorPage(
      error: 'Route not found: ${state.location}',
      onRetry: () => context.go(AppRoutes.home),
    ),
  );
});

/// Navigation helper class
class AppNavigation {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;
  static GlobalKey<NavigatorState> get shellNavigatorKey => _shellNavigatorKey;

  /// Navigate to login page
  static void toLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  /// Navigate to register page
  static void toRegister(BuildContext context) {
    context.go(AppRoutes.register);
  }

  /// Navigate to home page
  static void toHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  /// Navigate to cast vote page
  static void toCastVote(BuildContext context, String electionId) {
    context.go('${AppRoutes.castVote}?electionId=$electionId');
  }

  /// Navigate to ballot verification page
  static void toBallotVerification(BuildContext context, String voteToken) {
    context.go('${AppRoutes.ballotVerification}?voteToken=$voteToken');
  }

  /// Navigate to admin dashboard
  static void toAdminDashboard(BuildContext context) {
    context.go(AppRoutes.adminDashboard);
  }

  /// Navigate to analytics dashboard
  static void toAnalytics(BuildContext context) {
    context.go(AppRoutes.analytics);
  }

  /// Navigate to notifications
  static void toNotifications(BuildContext context) {
    context.go(AppRoutes.notifications);
  }

  /// Navigate back
  static void back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}

/// Dummy auth state provider (will be replaced with actual implementation)
final authStateProvider = StateProvider<AuthState>(
  (ref) => const AuthState(),
);

/// Auth state model
class AuthState {
  final bool isAuthenticated;
  final User? user;

  const AuthState({this.isAuthenticated = false, this.user});

  factory AuthState.authenticated(User user) =>
      AuthState(isAuthenticated: true, user: user);

  factory AuthState.unauthenticated() =>
      const AuthState(isAuthenticated: false, user: null);
}
