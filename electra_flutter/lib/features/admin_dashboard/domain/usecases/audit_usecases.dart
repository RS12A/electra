import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/audit_log.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Use case for getting audit logs
class GetAuditLogs extends UseCase<List<AuditLog>, GetAuditLogsParams> {
  final AdminDashboardRepository repository;

  GetAuditLogs(this.repository);

  @override
  Future<Either<Failure, List<AuditLog>>> call(GetAuditLogsParams params) {
    return repository.getAuditLogs(
      category: params.category,
      action: params.action,
      result: params.result,
      userId: params.userId,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Use case for getting ballot token audit logs
class GetBallotTokenAudits extends UseCase<List<BallotTokenAudit>, GetBallotTokenAuditsParams> {
  final AdminDashboardRepository repository;

  GetBallotTokenAudits(this.repository);

  @override
  Future<Either<Failure, List<BallotTokenAudit>>> call(GetBallotTokenAuditsParams params) {
    return repository.getBallotTokenAudits(
      electionId: params.electionId,
      status: params.status,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Use case for getting vote audit logs
class GetVoteAudits extends UseCase<List<VoteAudit>, GetVoteAuditsParams> {
  final AdminDashboardRepository repository;

  GetVoteAudits(this.repository);

  @override
  Future<Either<Failure, List<VoteAudit>>> call(GetVoteAuditsParams params) {
    return repository.getVoteAudits(
      electionId: params.electionId,
      startDate: params.startDate,
      endDate: params.endDate,
      validOnly: params.validOnly,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Use case for verifying audit chain integrity
class VerifyChainIntegrity extends UseCase<ChainIntegrityResult, VerifyChainIntegrityParams> {
  final AdminDashboardRepository repository;

  VerifyChainIntegrity(this.repository);

  @override
  Future<Either<Failure, ChainIntegrityResult>> call(VerifyChainIntegrityParams params) {
    return repository.verifyChainIntegrity(
      startSequence: params.startSequence,
      endSequence: params.endSequence,
    );
  }
}

/// Use case for exporting audit logs
class ExportAuditLogs extends UseCase<String, ExportAuditLogsParams> {
  final AdminDashboardRepository repository;

  ExportAuditLogs(this.repository);

  @override
  Future<Either<Failure, String>> call(ExportAuditLogsParams params) {
    return repository.exportAuditLogs(
      category: params.category,
      startDate: params.startDate,
      endDate: params.endDate,
      format: params.format,
    );
  }
}

/// Parameters for GetAuditLogs use case
class GetAuditLogsParams extends Equatable {
  final AuditCategory? category;
  final AuditAction? action;
  final AuditResult? result;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const GetAuditLogsParams({
    this.category,
    this.action,
    this.result,
    this.userId,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        category,
        action,
        result,
        userId,
        startDate,
        endDate,
        page,
        limit,
      ];
}

/// Parameters for GetBallotTokenAudits use case
class GetBallotTokenAuditsParams extends Equatable {
  final String? electionId;
  final TokenStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const GetBallotTokenAuditsParams({
    this.electionId,
    this.status,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        electionId,
        status,
        startDate,
        endDate,
        page,
        limit,
      ];
}

/// Parameters for GetVoteAudits use case
class GetVoteAuditsParams extends Equatable {
  final String? electionId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool validOnly;
  final int page;
  final int limit;

  const GetVoteAuditsParams({
    this.electionId,
    this.startDate,
    this.endDate,
    this.validOnly = true,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [
        electionId,
        startDate,
        endDate,
        validOnly,
        page,
        limit,
      ];
}

/// Parameters for VerifyChainIntegrity use case
class VerifyChainIntegrityParams extends Equatable {
  final int? startSequence;
  final int? endSequence;

  const VerifyChainIntegrityParams({
    this.startSequence,
    this.endSequence,
  });

  @override
  List<Object?> get props => [startSequence, endSequence];
}

/// Parameters for ExportAuditLogs use case
class ExportAuditLogsParams extends Equatable {
  final AuditCategory? category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String format;

  const ExportAuditLogsParams({
    this.category,
    this.startDate,
    this.endDate,
    this.format = 'csv',
  });

  @override
  List<Object?> get props => [category, startDate, endDate, format];
}