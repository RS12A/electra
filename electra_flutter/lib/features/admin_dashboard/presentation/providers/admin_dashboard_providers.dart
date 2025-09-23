import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'admin_dashboard_providers.g.dart';
part 'admin_dashboard_providers.freezed.dart';

/// Admin dashboard metrics state
@freezed
class AdminDashboardState with _$AdminDashboardState {
  const factory AdminDashboardState({
    AdminDashboardMetrics? metrics,
    @Default([]) List<QuickAction> quickActions,
    @Default([]) List<SystemAlert> alerts,
    @Default(false) bool isLoading,
    @Default(false) bool isRefreshing,
    String? error,
    DateTime? lastUpdated,
  }) = _AdminDashboardState;
}

/// Admin dashboard metrics provider
@riverpod
class AdminDashboardMetrics extends _$AdminDashboardMetrics {
  @override
  Future<AdminDashboardMetrics> build() async {
    final getDashboardMetrics = getIt<GetDashboardMetrics>();
    final result = await getDashboardMetrics(NoParams());
    
    return result.fold(
      (failure) => throw failure,
      (metrics) => metrics,
    );
  }

  /// Refresh dashboard metrics
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final getDashboardMetrics = getIt<GetDashboardMetrics>();
    final result = await getDashboardMetrics(NoParams());
    
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (metrics) => AsyncValue.data(metrics),
    );
  }
}

/// Quick actions provider
@riverpod
class AdminQuickActions extends _$AdminQuickActions {
  @override
  Future<List<QuickAction>> build() async {
    final getQuickActions = getIt<GetQuickActions>();
    final result = await getQuickActions(NoParams());
    
    return result.fold(
      (failure) => throw failure,
      (actions) => actions,
    );
  }
}

/// System alerts provider
@riverpod
class AdminSystemAlerts extends _$AdminSystemAlerts {
  @override
  Future<List<SystemAlert>> build({
    int limit = 10,
    List<AlertSeverity> severities = const [],
    List<AlertCategory> categories = const [],
    bool unacknowledgedOnly = true,
  }) async {
    final getSystemAlerts = getIt<GetSystemAlerts>();
    final result = await getSystemAlerts(GetSystemAlertsParams(
      limit: limit,
      severities: severities.isEmpty ? null : severities,
      categories: categories.isEmpty ? null : categories,
      unacknowledgedOnly: unacknowledgedOnly,
    ));
    
    return result.fold(
      (failure) => throw failure,
      (alerts) => alerts,
    );
  }

  /// Acknowledge a single alert
  Future<void> acknowledgeAlert(String alertId) async {
    final acknowledgeAlert = getIt<AcknowledgeAlert>();
    final result = await acknowledgeAlert(AcknowledgeAlertParams.single(alertId));
    
    result.fold(
      (failure) => throw failure,
      (_) {
        // Refresh alerts after acknowledgment
        ref.invalidateSelf();
      },
    );
  }

  /// Acknowledge multiple alerts
  Future<void> acknowledgeAlerts(List<String> alertIds) async {
    final acknowledgeAlert = getIt<AcknowledgeAlert>();
    final result = await acknowledgeAlert(AcknowledgeAlertParams(alertIds: alertIds));
    
    result.fold(
      (failure) => throw failure,
      (_) {
        // Refresh alerts after acknowledgment
        ref.invalidateSelf();
      },
    );
  }
}

/// Combined dashboard state provider
@riverpod
class AdminDashboardCombined extends _$AdminDashboardCombined {
  @override
  AdminDashboardState build() {
    final metricsAsync = ref.watch(adminDashboardMetricsProvider);
    final quickActionsAsync = ref.watch(adminQuickActionsProvider);
    final alertsAsync = ref.watch(adminSystemAlertsProvider());

    final isLoading = metricsAsync.isLoading || 
                     quickActionsAsync.isLoading || 
                     alertsAsync.isLoading;

    final error = metricsAsync.hasError 
        ? metricsAsync.error.toString()
        : quickActionsAsync.hasError
        ? quickActionsAsync.error.toString()
        : alertsAsync.hasError
        ? alertsAsync.error.toString()
        : null;

    return AdminDashboardState(
      metrics: metricsAsync.valueOrNull,
      quickActions: quickActionsAsync.valueOrNull ?? [],
      alerts: alertsAsync.valueOrNull ?? [],
      isLoading: isLoading,
      error: error,
      lastUpdated: DateTime.now(),
    );
  }

  /// Refresh all dashboard data
  Future<void> refreshAll() async {
    ref.invalidate(adminDashboardMetricsProvider);
    ref.invalidate(adminQuickActionsProvider);
    ref.invalidate(adminSystemAlertsProvider());
  }
}

/// Dashboard refresh controller
@riverpod
class AdminDashboardRefreshController extends _$AdminDashboardRefreshController {
  @override
  bool build() => false;

  /// Start refresh
  void startRefresh() {
    state = true;
  }

  /// End refresh
  void endRefresh() {
    state = false;
  }

  /// Perform full dashboard refresh
  Future<void> performRefresh() async {
    startRefresh();
    
    try {
      final dashboardState = ref.read(adminDashboardCombinedProvider.notifier);
      await dashboardState.refreshAll();
    } finally {
      endRefresh();
    }
  }
}