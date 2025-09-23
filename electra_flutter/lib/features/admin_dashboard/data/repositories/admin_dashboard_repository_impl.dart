import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../domain/entities/admin_dashboard_metrics.dart';
import '../../domain/entities/admin_election.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_remote_data_source.dart';

/// Implementation of AdminDashboardRepository
///
/// Handles data operations for the admin dashboard using clean architecture
/// principles with proper error handling and data transformation.
@LazySingleton(as: AdminDashboardRepository)
class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminRemoteDataSourceFactory _remoteDataSourceFactory;
  late final AdminRemoteDataSource _remoteDataSource;

  AdminDashboardRepositoryImpl(this._remoteDataSourceFactory) {
    _remoteDataSource = _remoteDataSourceFactory.create();
  }

  // Dashboard Metrics
  @override
  Future<Either<Failure, AdminDashboardMetrics>> getDashboardMetrics() async {
    try {
      final model = await _remoteDataSource.getDashboardMetrics();
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch dashboard metrics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<QuickAction>>> getQuickActions() async {
    try {
      final models = await _remoteDataSource.getQuickActions();
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch quick actions: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SystemAlert>>> getSystemAlerts({
    int limit = 10,
    List<AlertSeverity>? severities,
    List<AlertCategory>? categories,
    bool unacknowledgedOnly = true,
  }) async {
    try {
      final severityParam = severities?.map((s) => s.name).join(',');
      final categoryParam = categories?.map((c) => c.name).join(',');
      
      final models = await _remoteDataSource.getSystemAlerts(
        limit: limit,
        severity: severityParam,
        category: categoryParam,
        unacknowledgedOnly: unacknowledgedOnly,
      );
      
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch system alerts: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeAlert(String alertId) async {
    try {
      await _remoteDataSource.acknowledgeAlert(alertId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to acknowledge alert: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeAlerts(List<String> alertIds) async {
    try {
      await _remoteDataSource.acknowledgeAlerts({'alert_ids': alertIds});
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to acknowledge alerts: $e'));
    }
  }

  // Election Management
  @override
  Future<Either<Failure, List<AdminElection>>> getElections({
    ElectionStatus? status,
    String? searchQuery,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final models = await _remoteDataSource.getElections(
        status: status?.name,
        searchQuery: searchQuery,
        page: page,
        limit: limit,
        sortBy: _convertSortField(sortBy),
        sortOrder: sortOrder,
      );
      
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch elections: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> getElectionById(String electionId) async {
    try {
      final model = await _remoteDataSource.getElectionById(electionId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch election: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> createElection(AdminElection election) async {
    try {
      final model = AdminElectionModel.fromEntity(election);
      final created = await _remoteDataSource.createElection(model);
      return Right(created.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to create election: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> updateElection(AdminElection election) async {
    try {
      final model = AdminElectionModel.fromEntity(election);
      final updated = await _remoteDataSource.updateElection(election.id, model);
      return Right(updated.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to update election: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteElection(String electionId) async {
    try {
      await _remoteDataSource.deleteElection(electionId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to delete election: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> activateElection(String electionId) async {
    try {
      final model = await _remoteDataSource.activateElection(electionId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to activate election: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> closeElection(String electionId) async {
    try {
      final model = await _remoteDataSource.closeElection(electionId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to close election: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminElection>> suspendElection(String electionId) async {
    try {
      final model = await _remoteDataSource.suspendElection(electionId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to suspend election: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getElectionResults(String electionId) async {
    try {
      final results = await _remoteDataSource.getElectionResults(electionId);
      return Right(results);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch election results: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> publishResults(String electionId) async {
    try {
      await _remoteDataSource.publishResults(electionId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to publish results: $e'));
    }
  }

  // Candidate Management
  @override
  Future<Either<Failure, List<AdminCandidate>>> getCandidates({
    required String electionId,
    String? position,
    bool activeOnly = true,
    String sortBy = 'displayOrder',
  }) async {
    try {
      final models = await _remoteDataSource.getCandidates(
        electionId,
        position: position,
        activeOnly: activeOnly,
        sortBy: _convertSortField(sortBy),
      );
      
      return Right(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch candidates: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminCandidate>> getCandidateById(String candidateId) async {
    try {
      final model = await _remoteDataSource.getCandidateById(candidateId);
      return Right(model.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch candidate: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminCandidate>> createCandidate(AdminCandidate candidate) async {
    try {
      final model = AdminCandidateModel.fromEntity(candidate);
      final created = await _remoteDataSource.createCandidate(model);
      return Right(created.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to create candidate: $e'));
    }
  }

  @override
  Future<Either<Failure, AdminCandidate>> updateCandidate(AdminCandidate candidate) async {
    try {
      final model = AdminCandidateModel.fromEntity(candidate);
      final updated = await _remoteDataSource.updateCandidate(candidate.id, model);
      return Right(updated.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to update candidate: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCandidate(String candidateId) async {
    try {
      await _remoteDataSource.deleteCandidate(candidateId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to delete candidate: $e'));
    }
  }

  @override
  Future<Either<Failure, CandidateMedia>> uploadCandidateMedia({
    required String candidateId,
    required String filePath,
    required MediaType mediaType,
    String? title,
    String? description,
    bool isPrimary = false,
  }) async {
    try {
      final file = File(filePath);
      final media = await _remoteDataSource.uploadCandidateMedia(
        candidateId,
        file,
        mediaType.name,
        title,
        description,
        isPrimary,
      );
      return Right(media.toEntity());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to upload candidate media: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCandidateMedia(String mediaId) async {
    try {
      await _remoteDataSource.deleteCandidateMedia(mediaId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to delete candidate media: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateCandidateOrder({
    required String electionId,
    required String position,
    required List<String> candidateIds,
  }) async {
    try {
      await _remoteDataSource.updateCandidateOrder(
        electionId,
        {
          'position': position,
          'candidate_ids': candidateIds,
        },
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure('Failed to update candidate order: $e'));
    }
  }

  // User Management methods would follow the same pattern...
  // [Abbreviated for brevity - continue with remaining methods]

  // Helper methods
  String _convertSortField(String field) {
    // Convert camelCase to snake_case for API
    return field.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }

  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkFailure('Network timeout occurred');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode ?? 0;
        final message = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        
        if (statusCode == 401) {
          return AuthFailure('Authentication failed');
        } else if (statusCode == 403) {
          return AuthFailure('Access forbidden');
        } else if (statusCode == 404) {
          return NotFoundFailure('Resource not found');
        } else if (statusCode >= 400 && statusCode < 500) {
          return ValidationFailure(message.toString());
        } else {
          return ServerFailure('Server error: $message');
        }
      case DioExceptionType.cancel:
        return NetworkFailure('Request was cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure('Connection error occurred');
      case DioExceptionType.badCertificate:
        return NetworkFailure('Certificate verification failed');
      case DioExceptionType.unknown:
      default:
        return NetworkFailure('Network error: ${e.message}');
    }
  }

  // Real-time updates (implementation would depend on WebSocket/SSE setup)
  @override
  Stream<AdminDashboardMetrics> watchDashboardMetrics() {
    // TODO: Implement WebSocket/SSE stream
    throw UnimplementedError('Real-time dashboard metrics not implemented');
  }

  @override
  Stream<List<SystemAlert>> watchSystemAlerts() {
    // TODO: Implement WebSocket/SSE stream
    throw UnimplementedError('Real-time system alerts not implemented');
  }

  @override
  Stream<List<AdminElection>> watchElections() {
    // TODO: Implement WebSocket/SSE stream
    throw UnimplementedError('Real-time elections not implemented');
  }

  @override
  Stream<List<UserActivityLog>> watchUserActivity() {
    // TODO: Implement WebSocket/SSE stream  
    throw UnimplementedError('Real-time user activity not implemented');
  }

  // Stub implementations for brevity - would implement all remaining methods
  @override
  Future<Either<Failure, List<AdminUser>>> getUsers({
    UserRole? role,
    AccountStatus? status,
    String? searchQuery,
    String? department,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) {
    // TODO: Implement user management methods
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> getUserById(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> updateUser(AdminUser user) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> activateUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> deactivateUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> suspendUser(String userId, {Duration? duration, String? reason}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> lockUser(String userId, {Duration? duration, String? reason}) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> unlockUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> assignRole(String userId, UserRole role) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> grantPermissions(String userId, List<UserPermission> permissions) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, AdminUser>> revokePermissions(String userId, List<UserPermission> permissions) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, BulkUserOperationResult>> bulkActivateUsers(List<String> userIds) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, BulkUserOperationResult>> bulkDeactivateUsers(List<String> userIds) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<UserActivityLog>>> getUserActivityLogs({
    String? userId,
    UserAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    AuditCategory? category,
    AuditAction? action,
    AuditResult? result,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<BallotTokenAudit>>> getBallotTokenAudits({
    String? electionId,
    TokenStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<VoteAudit>>> getVoteAudits({
    String? electionId,
    DateTime? startDate,
    DateTime? endDate,
    bool validOnly = true,
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, ChainIntegrityResult>> verifyChainIntegrity({
    int? startSequence,
    int? endSequence,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> exportAuditLogs({
    AuditCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv',
  }) {
    throw UnimplementedError();
  }
}