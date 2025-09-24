import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../error/failures.dart';
import '../../services/logger_service.dart';
import '../../../features/auth/domain/usecases/auth_usecases.dart';
import '../../../features/notifications/domain/usecases/notification_usecases.dart';
import '../../../features/voting/domain/usecases/vote_usecases.dart';
import '../models/queue_item.dart';
import '../models/sync_config.dart';

/// Service for handling individual sync operations
///
/// Coordinates with specific feature repositories to sync different
/// types of operations with appropriate conflict resolution strategies.
@singleton
class SyncHandlerService {
  final LoggerService _logger;
  
  // Use cases for different operation types
  final CastVote _castVoteUseCase;
  final RefreshToken _refreshTokenUseCase;
  final MarkNotificationAsRead _markNotificationAsReadUseCase;
  
  // Conflict resolution rules
  Map<QueueOperationType, ConflictRule> _conflictRules = {};

  SyncHandlerService(
    this._logger,
    this._castVoteUseCase,
    this._refreshTokenUseCase,
    this._markNotificationAsReadUseCase,
  ) {
    _initializeConflictRules();
  }

  /// Update conflict resolution rules
  void updateConflictRules(Map<QueueOperationType, ConflictRule> rules) {
    _conflictRules = Map.from(rules);
    _logger.info('Conflict resolution rules updated');
  }

  /// Sync a queue item to the server
  Future<Either<Failure, bool>> syncItem(
    QueueItem item,
    Map<String, dynamic> payload,
  ) async {
    try {
      _logger.debug('Syncing item: ${item.uuid} (${item.operationType.value})');
      
      // Apply timeout for sync operation
      final conflictRule = _conflictRules[item.operationType];
      final timeout = conflictRule?.timeout ?? const Duration(seconds: 30);
      
      final result = await Future.any([
        _performSync(item, payload),
        Future.delayed(timeout).then((_) => 
          Left(NetworkFailure(message: 'Sync operation timed out'))),
      ]);

      return result.fold(
        (failure) {
          _logger.error('Sync failed for ${item.uuid}: ${failure.message}');
          return Left(failure);
        },
        (success) {
          _logger.info('Sync successful for ${item.uuid}');
          return const Right(true);
        },
      );
    } catch (e) {
      _logger.error('Unexpected error during sync', e);
      return Left(UnknownFailure(message: 'Sync error: ${e.toString()}'));
    }
  }

  /// Handle conflict resolution for duplicate operations
  Future<Either<Failure, bool>> resolveConflict(
    QueueItem item,
    Map<String, dynamic> payload,
    Failure originalFailure,
  ) async {
    final conflictRule = _conflictRules[item.operationType];
    if (conflictRule == null) {
      return Left(originalFailure);
    }

    _logger.info('Resolving conflict for ${item.uuid} using ${conflictRule.strategy}');

    switch (conflictRule.strategy) {
      case ConflictResolution.reject:
        return Left(ConflictFailure(
          message: 'Operation rejected due to conflict: ${originalFailure.message}',
        ));

      case ConflictResolution.serverWins:
        // Accept server state, mark as synced even though we didn't send
        _logger.info('Server wins conflict resolution for ${item.uuid}');
        return const Right(true);

      case ConflictResolution.localWins:
        // Force sync with override flag
        return await _performSyncWithOverride(item, payload);

      case ConflictResolution.latestWins:
        return await _handleLatestWinsConflict(item, payload, originalFailure);

      case ConflictResolution.merge:
        return await _handleMergeConflict(item, payload, originalFailure);

      case ConflictResolution.duplicate:
        return await _handleDuplicateConflict(item, payload);
    }
  }

  // Private methods

  void _initializeConflictRules() {
    _conflictRules = SyncConfigPresets.getDefaultConflictRules();
  }

  Future<Either<Failure, bool>> _performSync(
    QueueItem item,
    Map<String, dynamic> payload,
  ) async {
    switch (item.operationType) {
      case QueueOperationType.vote:
        return await _syncVote(payload);
        
      case QueueOperationType.authRefresh:
        return await _syncAuthRefresh(payload);
        
      case QueueOperationType.profileUpdate:
        return await _syncProfileUpdate(payload);
        
      case QueueOperationType.notificationAck:
        return await _syncNotificationAck(payload);
        
      case QueueOperationType.timetableEvent:
        return await _syncTimetableEvent(payload);
    }
  }

  Future<Either<Failure, bool>> _syncVote(Map<String, dynamic> payload) async {
    try {
      final params = CastVoteParams(
        electionId: payload['electionId'] as String,
        selections: Map<String, String>.from(payload['selections'] as Map),
        ballotToken: payload['ballotToken'] as String,
      );

      final result = await _castVoteUseCase(params);
      
      return result.fold(
        (failure) {
          // Check if this is a duplicate vote conflict
          if (failure.message?.contains('already voted') == true ||
              failure.message?.contains('duplicate') == true) {
            return Left(ConflictFailure(message: failure.message ?? 'Duplicate vote'));
          }
          return Left(failure);
        },
        (confirmation) => const Right(true),
      );
    } catch (e) {
      return Left(UnknownFailure(message: 'Vote sync error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _syncAuthRefresh(Map<String, dynamic> payload) async {
    try {
      final refreshToken = payload['refreshToken'] as String;
      final result = await _refreshTokenUseCase(StringParams(refreshToken));
      
      return result.fold(
        (failure) => Left(failure),
        (tokens) => const Right(true),
      );
    } catch (e) {
      return Left(UnknownFailure(message: 'Auth refresh sync error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _syncProfileUpdate(Map<String, dynamic> payload) async {
    try {
      // This would integrate with profile update use case
      // For now, simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure(message: 'Profile update sync error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _syncNotificationAck(Map<String, dynamic> payload) async {
    try {
      final notificationId = payload['notificationId'] as String;
      final result = await _markNotificationAsReadUseCase(StringParams(notificationId));
      
      return result.fold(
        (failure) => Left(failure),
        (success) => const Right(true),
      );
    } catch (e) {
      return Left(UnknownFailure(message: 'Notification ack sync error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _syncTimetableEvent(Map<String, dynamic> payload) async {
    try {
      // This would integrate with timetable event use case
      // For now, simulate success
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(true);
    } catch (e) {
      return Left(UnknownFailure(message: 'Timetable event sync error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _performSyncWithOverride(
    QueueItem item,
    Map<String, dynamic> payload,
  ) async {
    // Add override flag to payload
    final overridePayload = Map<String, dynamic>.from(payload);
    overridePayload['forceOverride'] = true;
    
    return await _performSync(item, overridePayload);
  }

  Future<Either<Failure, bool>> _handleLatestWinsConflict(
    QueueItem item,
    Map<String, dynamic> payload,
    Failure originalFailure,
  ) async {
    try {
      // Check if our item is newer than server version
      final itemTimestamp = item.createdAt;
      final serverTimestamp = _extractServerTimestamp(originalFailure);
      
      if (serverTimestamp != null && itemTimestamp.isAfter(serverTimestamp)) {
        // Our version is newer, force sync
        return await _performSyncWithOverride(item, payload);
      } else {
        // Server version is newer, accept server state
        return const Right(true);
      }
    } catch (e) {
      return Left(ConflictFailure(message: 'Latest wins resolution failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _handleMergeConflict(
    QueueItem item,
    Map<String, dynamic> payload,
    Failure originalFailure,
  ) async {
    try {
      // For notification acknowledgments, we can safely merge
      if (item.operationType == QueueOperationType.notificationAck) {
        return const Right(true); // Acknowledgment is idempotent
      }
      
      // For other types, fall back to latest wins
      return await _handleLatestWinsConflict(item, payload, originalFailure);
    } catch (e) {
      return Left(ConflictFailure(message: 'Merge resolution failed: ${e.toString()}'));
    }
  }

  Future<Either<Failure, bool>> _handleDuplicateConflict(
    QueueItem item,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Create a new unique identifier for the duplicate
      final duplicatePayload = Map<String, dynamic>.from(payload);
      duplicatePayload['isDuplicate'] = true;
      duplicatePayload['originalId'] = item.uuid;
      
      return await _performSync(item, duplicatePayload);
    } catch (e) {
      return Left(ConflictFailure(message: 'Duplicate resolution failed: ${e.toString()}'));
    }
  }

  DateTime? _extractServerTimestamp(Failure failure) {
    try {
      // This would parse server timestamp from error message or metadata
      // Implementation would depend on server response format
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Failure type for conflict resolution
class ConflictFailure extends Failure {
  const ConflictFailure({required String message}) : super(message: message);
}

/// Failure type for sync operations  
class SyncFailure extends Failure {
  const SyncFailure({required String message}) : super(message: message);
}