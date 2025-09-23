import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_dashboard_metrics.dart';
import '../entities/admin_election.dart';
import '../entities/admin_user.dart';
import '../entities/audit_log.dart';

/// Admin dashboard repository interface
///
/// Defines the contract for admin dashboard data operations following
/// Clean Architecture principles with comprehensive error handling.
abstract class AdminDashboardRepository {
  // Dashboard Metrics
  /// Get dashboard metrics and statistics
  Future<Either<Failure, AdminDashboardMetrics>> getDashboardMetrics();

  /// Get quick actions for the current admin user
  Future<Either<Failure, List<QuickAction>>> getQuickActions();

  /// Get system alerts for the dashboard
  Future<Either<Failure, List<SystemAlert>>> getSystemAlerts({
    int limit = 10,
    List<AlertSeverity>? severities,
    List<AlertCategory>? categories,
    bool unacknowledgedOnly = true,
  });

  /// Acknowledge a system alert
  Future<Either<Failure, void>> acknowledgeAlert(String alertId);

  /// Acknowledge multiple system alerts
  Future<Either<Failure, void>> acknowledgeAlerts(List<String> alertIds);

  // Election Management
  /// Get all elections with admin details
  Future<Either<Failure, List<AdminElection>>> getElections({
    ElectionStatus? status,
    String? searchQuery,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get election by ID with full admin details
  Future<Either<Failure, AdminElection>> getElectionById(String electionId);

  /// Create a new election
  Future<Either<Failure, AdminElection>> createElection(AdminElection election);

  /// Update an existing election
  Future<Either<Failure, AdminElection>> updateElection(AdminElection election);

  /// Delete an election
  Future<Either<Failure, void>> deleteElection(String electionId);

  /// Activate an election (make it live)
  Future<Either<Failure, AdminElection>> activateElection(String electionId);

  /// Close an election (end voting)
  Future<Either<Failure, AdminElection>> closeElection(String electionId);

  /// Suspend an election (temporarily halt)
  Future<Either<Failure, AdminElection>> suspendElection(String electionId);

  /// Get election results
  Future<Either<Failure, Map<String, dynamic>>> getElectionResults(String electionId);

  /// Publish election results
  Future<Either<Failure, void>> publishResults(String electionId);

  // Candidate Management
  /// Get candidates for an election
  Future<Either<Failure, List<AdminCandidate>>> getCandidates({
    required String electionId,
    String? position,
    bool activeOnly = true,
    String sortBy = 'displayOrder',
  });

  /// Get candidate by ID
  Future<Either<Failure, AdminCandidate>> getCandidateById(String candidateId);

  /// Create a new candidate
  Future<Either<Failure, AdminCandidate>> createCandidate(AdminCandidate candidate);

  /// Update an existing candidate
  Future<Either<Failure, AdminCandidate>> updateCandidate(AdminCandidate candidate);

  /// Delete a candidate
  Future<Either<Failure, void>> deleteCandidate(String candidateId);

  /// Upload candidate media (photo/video)
  Future<Either<Failure, CandidateMedia>> uploadCandidateMedia({
    required String candidateId,
    required String filePath,
    required MediaType mediaType,
    String? title,
    String? description,
    bool isPrimary = false,
  });

  /// Delete candidate media
  Future<Either<Failure, void>> deleteCandidateMedia(String mediaId);

  /// Update candidate display order
  Future<Either<Failure, void>> updateCandidateOrder({
    required String electionId,
    required String position,
    required List<String> candidateIds,
  });

  // User Management
  /// Get all users with admin details
  Future<Either<Failure, List<AdminUser>>> getUsers({
    UserRole? role,
    AccountStatus? status,
    String? searchQuery,
    String? department,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  });

  /// Get user by ID
  Future<Either<Failure, AdminUser>> getUserById(String userId);

  /// Update user information
  Future<Either<Failure, AdminUser>> updateUser(AdminUser user);

  /// Activate user account
  Future<Either<Failure, AdminUser>> activateUser(String userId);

  /// Deactivate user account
  Future<Either<Failure, AdminUser>> deactivateUser(String userId);

  /// Suspend user account
  Future<Either<Failure, AdminUser>> suspendUser(String userId, {
    Duration? duration,
    String? reason,
  });

  /// Lock user account
  Future<Either<Failure, AdminUser>> lockUser(String userId, {
    Duration? duration,
    String? reason,
  });

  /// Unlock user account
  Future<Either<Failure, AdminUser>> unlockUser(String userId);

  /// Assign role to user
  Future<Either<Failure, AdminUser>> assignRole(String userId, UserRole role);

  /// Grant permissions to user
  Future<Either<Failure, AdminUser>> grantPermissions(
    String userId,
    List<UserPermission> permissions,
  );

  /// Revoke permissions from user
  Future<Either<Failure, AdminUser>> revokePermissions(
    String userId,
    List<UserPermission> permissions,
  );

  /// Bulk activate users
  Future<Either<Failure, BulkUserOperationResult>> bulkActivateUsers(
    List<String> userIds,
  );

  /// Bulk deactivate users
  Future<Either<Failure, BulkUserOperationResult>> bulkDeactivateUsers(
    List<String> userIds,
  );

  /// Get user activity logs
  Future<Either<Failure, List<UserActivityLog>>> getUserActivityLogs({
    String? userId,
    UserAction? action,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  // Audit & Security
  /// Get audit logs with filtering
  Future<Either<Failure, List<AuditLog>>> getAuditLogs({
    AuditCategory? category,
    AuditAction? action,
    AuditResult? result,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  /// Get ballot token audit logs
  Future<Either<Failure, List<BallotTokenAudit>>> getBallotTokenAudits({
    String? electionId,
    TokenStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  });

  /// Get vote audit logs (anonymized)
  Future<Either<Failure, List<VoteAudit>>> getVoteAudits({
    String? electionId,
    DateTime? startDate,
    DateTime? endDate,
    bool validOnly = true,
    int page = 1,
    int limit = 20,
  });

  /// Verify audit chain integrity
  Future<Either<Failure, ChainIntegrityResult>> verifyChainIntegrity({
    int? startSequence,
    int? endSequence,
  });

  /// Export audit logs
  Future<Either<Failure, String>> exportAuditLogs({
    AuditCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv', // csv, json, pdf
  });

  // Real-time Updates
  /// Subscribe to dashboard metrics updates
  Stream<AdminDashboardMetrics> watchDashboardMetrics();

  /// Subscribe to system alerts
  Stream<List<SystemAlert>> watchSystemAlerts();

  /// Subscribe to election updates
  Stream<List<AdminElection>> watchElections();

  /// Subscribe to user activity
  Stream<List<UserActivityLog>> watchUserActivity();
}