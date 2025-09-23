import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/admin_user.dart';
import '../repositories/admin_dashboard_repository.dart';

/// Use case for getting users
class GetUsers extends UseCase<List<AdminUser>, GetUsersParams> {
  final AdminDashboardRepository repository;

  GetUsers(this.repository);

  @override
  Future<Either<Failure, List<AdminUser>>> call(GetUsersParams params) {
    return repository.getUsers(
      role: params.role,
      status: params.status,
      searchQuery: params.searchQuery,
      department: params.department,
      page: params.page,
      limit: params.limit,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

/// Use case for getting user by ID
class GetUserById extends UseCase<AdminUser, StringParams> {
  final AdminDashboardRepository repository;

  GetUserById(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(StringParams params) {
    return repository.getUserById(params.value);
  }
}

/// Use case for updating user
class UpdateUser extends UseCase<AdminUser, UpdateUserParams> {
  final AdminDashboardRepository repository;

  UpdateUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(UpdateUserParams params) {
    return repository.updateUser(params.user);
  }
}

/// Use case for activating user
class ActivateUser extends UseCase<AdminUser, StringParams> {
  final AdminDashboardRepository repository;

  ActivateUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(StringParams params) {
    return repository.activateUser(params.value);
  }
}

/// Use case for deactivating user
class DeactivateUser extends UseCase<AdminUser, StringParams> {
  final AdminDashboardRepository repository;

  DeactivateUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(StringParams params) {
    return repository.deactivateUser(params.value);
  }
}

/// Use case for suspending user
class SuspendUser extends UseCase<AdminUser, SuspendUserParams> {
  final AdminDashboardRepository repository;

  SuspendUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(SuspendUserParams params) {
    return repository.suspendUser(
      params.userId,
      duration: params.duration,
      reason: params.reason,
    );
  }
}

/// Use case for locking user
class LockUser extends UseCase<AdminUser, LockUserParams> {
  final AdminDashboardRepository repository;

  LockUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(LockUserParams params) {
    return repository.lockUser(
      params.userId,
      duration: params.duration,
      reason: params.reason,
    );
  }
}

/// Use case for unlocking user
class UnlockUser extends UseCase<AdminUser, StringParams> {
  final AdminDashboardRepository repository;

  UnlockUser(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(StringParams params) {
    return repository.unlockUser(params.value);
  }
}

/// Use case for assigning role to user
class AssignRole extends UseCase<AdminUser, AssignRoleParams> {
  final AdminDashboardRepository repository;

  AssignRole(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(AssignRoleParams params) {
    return repository.assignRole(params.userId, params.role);
  }
}

/// Use case for granting permissions to user
class GrantPermissions extends UseCase<AdminUser, GrantPermissionsParams> {
  final AdminDashboardRepository repository;

  GrantPermissions(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(GrantPermissionsParams params) {
    return repository.grantPermissions(params.userId, params.permissions);
  }
}

/// Use case for revoking permissions from user
class RevokePermissions extends UseCase<AdminUser, RevokePermissionsParams> {
  final AdminDashboardRepository repository;

  RevokePermissions(this.repository);

  @override
  Future<Either<Failure, AdminUser>> call(RevokePermissionsParams params) {
    return repository.revokePermissions(params.userId, params.permissions);
  }
}

/// Use case for bulk activating users
class BulkActivateUsers extends UseCase<BulkUserOperationResult, BulkUserActionParams> {
  final AdminDashboardRepository repository;

  BulkActivateUsers(this.repository);

  @override
  Future<Either<Failure, BulkUserOperationResult>> call(BulkUserActionParams params) {
    return repository.bulkActivateUsers(params.userIds);
  }
}

/// Use case for bulk deactivating users
class BulkDeactivateUsers extends UseCase<BulkUserOperationResult, BulkUserActionParams> {
  final AdminDashboardRepository repository;

  BulkDeactivateUsers(this.repository);

  @override
  Future<Either<Failure, BulkUserOperationResult>> call(BulkUserActionParams params) {
    return repository.bulkDeactivateUsers(params.userIds);
  }
}

/// Use case for getting user activity logs
class GetUserActivityLogs extends UseCase<List<UserActivityLog>, GetUserActivityLogsParams> {
  final AdminDashboardRepository repository;

  GetUserActivityLogs(this.repository);

  @override
  Future<Either<Failure, List<UserActivityLog>>> call(GetUserActivityLogsParams params) {
    return repository.getUserActivityLogs(
      userId: params.userId,
      action: params.action,
      startDate: params.startDate,
      endDate: params.endDate,
      page: params.page,
      limit: params.limit,
    );
  }
}

/// Parameters for GetUsers use case
class GetUsersParams extends Equatable {
  final UserRole? role;
  final AccountStatus? status;
  final String? searchQuery;
  final String? department;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const GetUsersParams({
    this.role,
    this.status,
    this.searchQuery,
    this.department,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  @override
  List<Object?> get props => [
        role,
        status,
        searchQuery,
        department,
        page,
        limit,
        sortBy,
        sortOrder,
      ];
}

/// Parameters for UpdateUser use case
class UpdateUserParams extends Equatable {
  final AdminUser user;

  const UpdateUserParams({
    required this.user,
  });

  @override
  List<Object?> get props => [user];
}

/// Parameters for SuspendUser use case
class SuspendUserParams extends Equatable {
  final String userId;
  final Duration? duration;
  final String? reason;

  const SuspendUserParams({
    required this.userId,
    this.duration,
    this.reason,
  });

  @override
  List<Object?> get props => [userId, duration, reason];
}

/// Parameters for LockUser use case
class LockUserParams extends Equatable {
  final String userId;
  final Duration? duration;
  final String? reason;

  const LockUserParams({
    required this.userId,
    this.duration,
    this.reason,
  });

  @override
  List<Object?> get props => [userId, duration, reason];
}

/// Parameters for AssignRole use case
class AssignRoleParams extends Equatable {
  final String userId;
  final UserRole role;

  const AssignRoleParams({
    required this.userId,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, role];
}

/// Parameters for GrantPermissions use case
class GrantPermissionsParams extends Equatable {
  final String userId;
  final List<UserPermission> permissions;

  const GrantPermissionsParams({
    required this.userId,
    required this.permissions,
  });

  @override
  List<Object?> get props => [userId, permissions];
}

/// Parameters for RevokePermissions use case
class RevokePermissionsParams extends Equatable {
  final String userId;
  final List<UserPermission> permissions;

  const RevokePermissionsParams({
    required this.userId,
    required this.permissions,
  });

  @override
  List<Object?> get props => [userId, permissions];
}

/// Parameters for bulk user actions
class BulkUserActionParams extends Equatable {
  final List<String> userIds;

  const BulkUserActionParams({
    required this.userIds,
  });

  @override
  List<Object?> get props => [userIds];
}

/// Parameters for GetUserActivityLogs use case
class GetUserActivityLogsParams extends Equatable {
  final String? userId;
  final UserAction? action;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int limit;

  const GetUserActivityLogsParams({
    this.userId,
    this.action,
    this.startDate,
    this.endDate,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [userId, action, startDate, endDate, page, limit];
}

/// Generic string parameter class
class StringParams extends Equatable {
  final String value;

  const StringParams(this.value);

  @override
  List<Object?> get props => [value];
}