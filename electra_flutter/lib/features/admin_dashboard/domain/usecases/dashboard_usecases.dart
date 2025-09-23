import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_dashboard_metrics.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Use case for getting dashboard metrics
class GetDashboardMetrics extends UseCase<AdminDashboardMetrics, NoParams> {
  final AdminDashboardRepository repository;

  GetDashboardMetrics(this.repository);

  @override
  Future<Either<Failure, AdminDashboardMetrics>> call(NoParams params) {
    return repository.getDashboardMetrics();
  }
}

/// Use case for getting quick actions
class GetQuickActions extends UseCase<List<QuickAction>, NoParams> {
  final AdminDashboardRepository repository;

  GetQuickActions(this.repository);

  @override
  Future<Either<Failure, List<QuickAction>>> call(NoParams params) {
    return repository.getQuickActions();
  }
}

/// Use case for getting system alerts
class GetSystemAlerts extends UseCase<List<SystemAlert>, GetSystemAlertsParams> {
  final AdminDashboardRepository repository;

  GetSystemAlerts(this.repository);

  @override
  Future<Either<Failure, List<SystemAlert>>> call(GetSystemAlertsParams params) {
    return repository.getSystemAlerts(
      limit: params.limit,
      severities: params.severities,
      categories: params.categories,
      unacknowledgedOnly: params.unacknowledgedOnly,
    );
  }
}

/// Use case for acknowledging system alerts
class AcknowledgeAlert extends UseCase<void, AcknowledgeAlertParams> {
  final AdminDashboardRepository repository;

  AcknowledgeAlert(this.repository);

  @override
  Future<Either<Failure, void>> call(AcknowledgeAlertParams params) {
    if (params.alertIds.length == 1) {
      return repository.acknowledgeAlert(params.alertIds.first);
    } else {
      return repository.acknowledgeAlerts(params.alertIds);
    }
  }
}

/// Parameters for GetSystemAlerts use case
class GetSystemAlertsParams extends Equatable {
  final int limit;
  final List<AlertSeverity>? severities;
  final List<AlertCategory>? categories;
  final bool unacknowledgedOnly;

  const GetSystemAlertsParams({
    this.limit = 10,
    this.severities,
    this.categories,
    this.unacknowledgedOnly = true,
  });

  @override
  List<Object?> get props => [limit, severities, categories, unacknowledgedOnly];
}

/// Parameters for AcknowledgeAlert use case
class AcknowledgeAlertParams extends Equatable {
  final List<String> alertIds;

  const AcknowledgeAlertParams({
    required this.alertIds,
  });

  /// Constructor for single alert
  const AcknowledgeAlertParams.single(String alertId)
      : alertIds = const <String>[],
        super();

  @override
  List<Object?> get props => [alertIds];
}