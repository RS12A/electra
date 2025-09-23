import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../../../shared/constants/app_constants.dart';
import '../../../core/network/network_service.dart';
import '../models/admin_dashboard_metrics_model.dart';
import '../models/admin_election_model.dart';
import '../models/admin_user_model.dart';
import '../models/audit_log_model.dart';

part 'admin_remote_data_source.g.dart';

/// Remote data source for admin dashboard API calls
///
/// Uses Retrofit with Dio for type-safe HTTP client generation.
/// Handles all backend communication for admin dashboard features.
@RestApi()
abstract class AdminRemoteDataSource {
  factory AdminRemoteDataSource(Dio dio, {String baseUrl}) = _AdminRemoteDataSource;

  // Dashboard Metrics
  @GET('${AppConstants.adminEndpoint}/dashboard/metrics')
  Future<AdminDashboardMetricsModel> getDashboardMetrics();

  @GET('${AppConstants.adminEndpoint}/dashboard/quick-actions')
  Future<List<QuickActionModel>> getQuickActions();

  @GET('${AppConstants.adminEndpoint}/dashboard/alerts')
  Future<List<SystemAlertModel>> getSystemAlerts({
    @Query('limit') int limit = 10,
    @Query('severity') String? severity,
    @Query('category') String? category,
    @Query('unacknowledged_only') bool unacknowledgedOnly = true,
  });

  @PATCH('${AppConstants.adminEndpoint}/dashboard/alerts/{alertId}/acknowledge')
  Future<void> acknowledgeAlert(@Path('alertId') String alertId);

  @PATCH('${AppConstants.adminEndpoint}/dashboard/alerts/acknowledge-multiple')
  Future<void> acknowledgeAlerts(@Body() Map<String, List<String>> alertIds);

  // Election Management
  @GET('${AppConstants.adminEndpoint}/elections')
  Future<List<AdminElectionModel>> getElections({
    @Query('status') String? status,
    @Query('search') String? searchQuery,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('sort_by') String sortBy = 'created_at',
    @Query('sort_order') String sortOrder = 'desc',
  });

  @GET('${AppConstants.adminEndpoint}/elections/{electionId}')
  Future<AdminElectionModel> getElectionById(@Path('electionId') String electionId);

  @POST('${AppConstants.adminEndpoint}/elections')
  Future<AdminElectionModel> createElection(@Body() AdminElectionModel election);

  @PUT('${AppConstants.adminEndpoint}/elections/{electionId}')
  Future<AdminElectionModel> updateElection(
    @Path('electionId') String electionId,
    @Body() AdminElectionModel election,
  );

  @DELETE('${AppConstants.adminEndpoint}/elections/{electionId}')
  Future<void> deleteElection(@Path('electionId') String electionId);

  @PATCH('${AppConstants.adminEndpoint}/elections/{electionId}/activate')
  Future<AdminElectionModel> activateElection(@Path('electionId') String electionId);

  @PATCH('${AppConstants.adminEndpoint}/elections/{electionId}/close')
  Future<AdminElectionModel> closeElection(@Path('electionId') String electionId);

  @PATCH('${AppConstants.adminEndpoint}/elections/{electionId}/suspend')
  Future<AdminElectionModel> suspendElection(@Path('electionId') String electionId);

  @GET('${AppConstants.adminEndpoint}/elections/{electionId}/results')
  Future<Map<String, dynamic>> getElectionResults(@Path('electionId') String electionId);

  @PATCH('${AppConstants.adminEndpoint}/elections/{electionId}/publish-results')
  Future<void> publishResults(@Path('electionId') String electionId);

  // Candidate Management
  @GET('${AppConstants.adminEndpoint}/elections/{electionId}/candidates')
  Future<List<AdminCandidateModel>> getCandidates(
    @Path('electionId') String electionId, {
    @Query('position') String? position,
    @Query('active_only') bool activeOnly = true,
    @Query('sort_by') String sortBy = 'display_order',
  });

  @GET('${AppConstants.adminEndpoint}/candidates/{candidateId}')
  Future<AdminCandidateModel> getCandidateById(@Path('candidateId') String candidateId);

  @POST('${AppConstants.adminEndpoint}/candidates')
  Future<AdminCandidateModel> createCandidate(@Body() AdminCandidateModel candidate);

  @PUT('${AppConstants.adminEndpoint}/candidates/{candidateId}')
  Future<AdminCandidateModel> updateCandidate(
    @Path('candidateId') String candidateId,
    @Body() AdminCandidateModel candidate,
  );

  @DELETE('${AppConstants.adminEndpoint}/candidates/{candidateId}')
  Future<void> deleteCandidate(@Path('candidateId') String candidateId);

  @POST('${AppConstants.adminEndpoint}/candidates/{candidateId}/media')
  @MultiPart()
  Future<CandidateMediaModel> uploadCandidateMedia(
    @Path('candidateId') String candidateId,
    @Part() File file,
    @Part() String mediaType,
    @Part() String? title,
    @Part() String? description,
    @Part() bool isPrimary,
  );

  @DELETE('${AppConstants.adminEndpoint}/candidates/media/{mediaId}')
  Future<void> deleteCandidateMedia(@Path('mediaId') String mediaId);

  @PATCH('${AppConstants.adminEndpoint}/elections/{electionId}/candidates/reorder')
  Future<void> updateCandidateOrder(
    @Path('electionId') String electionId,
    @Body() Map<String, dynamic> orderData,
  );

  // User Management
  @GET('${AppConstants.adminEndpoint}/users')
  Future<List<AdminUserModel>> getUsers({
    @Query('role') String? role,
    @Query('status') String? status,
    @Query('search') String? searchQuery,
    @Query('department') String? department,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('sort_by') String sortBy = 'created_at',
    @Query('sort_order') String sortOrder = 'desc',
  });

  @GET('${AppConstants.adminEndpoint}/users/{userId}')
  Future<AdminUserModel> getUserById(@Path('userId') String userId);

  @PUT('${AppConstants.adminEndpoint}/users/{userId}')
  Future<AdminUserModel> updateUser(
    @Path('userId') String userId,
    @Body() AdminUserModel user,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/activate')
  Future<AdminUserModel> activateUser(@Path('userId') String userId);

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/deactivate')
  Future<AdminUserModel> deactivateUser(@Path('userId') String userId);

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/suspend')
  Future<AdminUserModel> suspendUser(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> suspensionData,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/lock')
  Future<AdminUserModel> lockUser(
    @Path('userId') String userId,
    @Body() Map<String, dynamic> lockData,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/unlock')
  Future<AdminUserModel> unlockUser(@Path('userId') String userId);

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/assign-role')
  Future<AdminUserModel> assignRole(
    @Path('userId') String userId,
    @Body() Map<String, String> roleData,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/grant-permissions')
  Future<AdminUserModel> grantPermissions(
    @Path('userId') String userId,
    @Body() Map<String, List<String>> permissionsData,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/{userId}/revoke-permissions')
  Future<AdminUserModel> revokePermissions(
    @Path('userId') String userId,
    @Body() Map<String, List<String>> permissionsData,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/bulk-activate')
  Future<BulkUserOperationResultModel> bulkActivateUsers(
    @Body() Map<String, List<String>> userIds,
  );

  @PATCH('${AppConstants.adminEndpoint}/users/bulk-deactivate')
  Future<BulkUserOperationResultModel> bulkDeactivateUsers(
    @Body() Map<String, List<String>> userIds,
  );

  @GET('${AppConstants.adminEndpoint}/users/activity-logs')
  Future<List<UserActivityLogModel>> getUserActivityLogs({
    @Query('user_id') String? userId,
    @Query('action') String? action,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  // Audit & Security
  @GET('${AppConstants.adminEndpoint}/audit-logs')
  Future<List<AuditLogModel>> getAuditLogs({
    @Query('category') String? category,
    @Query('action') String? action,
    @Query('result') String? result,
    @Query('user_id') String? userId,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  @GET('${AppConstants.adminEndpoint}/audit-logs/ballot-tokens')
  Future<List<BallotTokenAuditModel>> getBallotTokenAudits({
    @Query('election_id') String? electionId,
    @Query('status') String? status,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  @GET('${AppConstants.adminEndpoint}/audit-logs/votes')
  Future<List<VoteAuditModel>> getVoteAudits({
    @Query('election_id') String? electionId,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('valid_only') bool validOnly = true,
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
  });

  @GET('${AppConstants.adminEndpoint}/audit-logs/verify-integrity')
  Future<ChainIntegrityResultModel> verifyChainIntegrity({
    @Query('start_sequence') int? startSequence,
    @Query('end_sequence') int? endSequence,
  });

  @GET('${AppConstants.adminEndpoint}/audit-logs/export')
  Future<String> exportAuditLogs({
    @Query('category') String? category,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
    @Query('format') String format = 'csv',
  });
}

/// Injectable factory for creating AdminRemoteDataSource
@Injectable()
class AdminRemoteDataSourceFactory {
  final NetworkService _networkService;

  AdminRemoteDataSourceFactory(this._networkService);

  AdminRemoteDataSource create() {
    return AdminRemoteDataSource(_networkService.dio, baseUrl: AppConstants.baseUrl);
  }
}