import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../../shared/utils/logger.dart';
import '../../domain/entities/timetable_event.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../datasources/timetable_datasource.dart';
import '../models/timetable_event_model.dart';

/// Repository implementation for timetable operations
@Injectable(as: TimetableRepository)
class TimetableRepositoryImpl implements TimetableRepository {
  const TimetableRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  final TimetableRemoteDataSource _remoteDataSource;
  final TimetableLocalDataSource _localDataSource;
  final Connectivity _connectivity;

  /// Check if device is connected to internet
  Future<bool> get _isConnected async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
    String? relatedElectionId,
  }) async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvents = await _remoteDataSource.getEvents(
            startDate: startDate,
            endDate: endDate,
            type: type,
            status: status,
            relatedElectionId: relatedElectionId,
          );
          
          await _localDataSource.cacheEvents(remoteEvents);
          return Right(remoteEvents);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedEvents = await _localDataSource.getCachedEvents(
        startDate: startDate,
        endDate: endDate,
        type: type,
        status: status,
      );
      
      return Right(cachedEvents);
    } catch (e) {
      AppLogger.error('Error getting events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TimetableEvent>> getEventById(String id) async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvent = await _remoteDataSource.getEventById(id);
          await _localDataSource.cacheEvent(remoteEvent);
          return Right(remoteEvent);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedEvent = await _localDataSource.getCachedEventById(id);
      if (cachedEvent != null) {
        return Right(cachedEvent);
      } else {
        return const Left(CacheFailure(message: 'Event not found in cache'));
      }
    } catch (e) {
      AppLogger.error('Error getting event by ID', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getEventsForDate(DateTime date) async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvents = await _remoteDataSource.getEventsForDate(date);
          await _localDataSource.cacheEvents(remoteEvents);
          return Right(remoteEvents);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedEvents = await _localDataSource.getCachedEventsForDate(date);
      return Right(cachedEvents);
    } catch (e) {
      AppLogger.error('Error getting events for date', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getActiveEvents() async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvents = await _remoteDataSource.getActiveEvents();
          await _localDataSource.cacheEvents(remoteEvents);
          return Right(remoteEvents);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedEvents = await _localDataSource.getCachedActiveEvents();
      return Right(cachedEvents);
    } catch (e) {
      AppLogger.error('Error getting active events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getUpcomingEvents({
    int? limit,
    Duration? withinDuration,
  }) async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvents = await _remoteDataSource.getUpcomingEvents(
            limit: limit,
            withinDuration: withinDuration,
          );
          await _localDataSource.cacheEvents(remoteEvents);
          return Right(remoteEvents);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedEvents = await _localDataSource.getCachedUpcomingEvents();
      
      // Apply limit to cached data
      List<TimetableEventModel> filteredEvents = cachedEvents;
      if (limit != null && filteredEvents.length > limit) {
        filteredEvents = filteredEvents.take(limit).toList();
      }
      
      return Right(filteredEvents);
    } catch (e) {
      AppLogger.error('Error getting upcoming events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TimetableEvent>> createEvent({
    required EventType type,
    required String title,
    required String description,
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? location,
    String? relatedElectionId,
    String? relatedCandidateId,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool isAllDay = false,
    String? color,
  }) async {
    try {
      if (await _isConnected) {
        final createdEvent = await _remoteDataSource.createEvent(
          type: type,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          location: location,
          relatedElectionId: relatedElectionId,
          relatedCandidateId: relatedCandidateId,
          tags: tags,
          metadata: metadata,
          isAllDay: isAllDay,
          color: color,
        );
        
        await _localDataSource.cacheEvent(createdEvent);
        return Right(createdEvent);
      } else {
        // Queue for offline sync and create local event
        final eventData = {
          'type': type.toString().split('.').last,
          'title': title,
          'description': description,
          'start_date_time': startDateTime.toIso8601String(),
          'end_date_time': endDateTime?.toIso8601String(),
          'location': location,
          'related_election_id': relatedElectionId,
          'related_candidate_id': relatedCandidateId,
          'tags': tags,
          'metadata': metadata,
          'is_all_day': isAllDay,
          'color': color,
        };
        
        await _localDataSource.queueEventChangeForSync(
          action: 'create',
          eventData: eventData,
        );
        
        // Create local event with temporary ID
        final localEvent = TimetableEventModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          status: EventStatus.upcoming,
          location: location,
          relatedElectionId: relatedElectionId,
          relatedCandidateId: relatedCandidateId,
          tags: tags,
          metadata: metadata,
          isAllDay: isAllDay,
          color: color,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _localDataSource.cacheEvent(localEvent);
        return Right(localEvent);
      }
    } on ServerException catch (e) {
      AppLogger.error('Error creating event', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error creating event', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TimetableEvent>> updateEvent({
    required String id,
    EventType? type,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventStatus? status,
    String? location,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isAllDay,
    String? color,
  }) async {
    try {
      if (await _isConnected) {
        final updatedEvent = await _remoteDataSource.updateEvent(
          id: id,
          type: type,
          title: title,
          description: description,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
          status: status,
          location: location,
          tags: tags,
          metadata: metadata,
          isAllDay: isAllDay,
          color: color,
        );
        
        await _localDataSource.updateCachedEvent(updatedEvent);
        return Right(updatedEvent);
      } else {
        // Queue for offline sync and update local event
        final eventData = <String, dynamic>{'id': id};
        
        if (type != null) eventData['type'] = type.toString().split('.').last;
        if (title != null) eventData['title'] = title;
        if (description != null) eventData['description'] = description;
        if (startDateTime != null) eventData['start_date_time'] = startDateTime.toIso8601String();
        if (endDateTime != null) eventData['end_date_time'] = endDateTime.toIso8601String();
        if (status != null) eventData['status'] = status.toString().split('.').last;
        if (location != null) eventData['location'] = location;
        if (tags != null) eventData['tags'] = tags;
        if (metadata != null) eventData['metadata'] = metadata;
        if (isAllDay != null) eventData['is_all_day'] = isAllDay;
        if (color != null) eventData['color'] = color;
        
        await _localDataSource.queueEventChangeForSync(
          action: 'update',
          eventData: eventData,
        );
        
        // Update local event optimistically
        final cachedEvent = await _localDataSource.getCachedEventById(id);
        if (cachedEvent != null) {
          final updatedEvent = TimetableEventModel.fromEntity(cachedEvent).copyWith(
            type: type,
            title: title,
            description: description,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            status: status,
            location: location,
            tags: tags,
            metadata: metadata,
            isAllDay: isAllDay,
            color: color,
            updatedAt: DateTime.now(),
          );
          
          await _localDataSource.updateCachedEvent(updatedEvent);
          return Right(updatedEvent);
        } else {
          return const Left(CacheFailure(message: 'Event not found in cache'));
        }
      }
    } on ServerException catch (e) {
      AppLogger.error('Error updating event', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error updating event', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) async {
    try {
      if (await _isConnected) {
        await _remoteDataSource.deleteEvent(id);
      } else {
        // Queue for offline sync
        await _localDataSource.queueEventChangeForSync(
          action: 'delete',
          eventData: {'id': id},
        );
      }
      
      // Remove from local cache
      await _localDataSource.removeCachedEvent(id);
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Error deleting event', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error deleting event', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TimetableSummary>> getTimetableSummary() async {
    try {
      if (await _isConnected) {
        try {
          final remoteSummary = await _remoteDataSource.getTimetableSummary();
          await _localDataSource.cacheTimetableSummary(remoteSummary);
          return Right(remoteSummary);
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      final cachedSummary = await _localDataSource.getCachedTimetableSummary();
      if (cachedSummary != null) {
        return Right(cachedSummary);
      } else {
        // Generate summary from cached events
        final cachedEvents = await _localDataSource.getCachedEvents();
        final summary = _generateSummaryFromEvents(cachedEvents);
        return Right(summary);
      }
    } catch (e) {
      AppLogger.error('Error getting timetable summary', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getElectionEvents(
    String electionId,
  ) async {
    return getEvents(relatedElectionId: electionId);
  }

  @override
  Future<Either<Failure, void>> subscribeToEventNotifications(
    String eventId,
    Duration notificationTime,
  ) async {
    try {
      // Always save locally
      await _localDataSource.saveEventNotificationSubscription(eventId, notificationTime);
      
      if (await _isConnected) {
        await _remoteDataSource.subscribeToEventNotifications(eventId, notificationTime);
      }
      
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Error subscribing to event notifications', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error subscribing to event notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unsubscribeFromEventNotifications(
    String eventId,
  ) async {
    try {
      // Always remove locally
      await _localDataSource.removeEventNotificationSubscription(eventId);
      
      if (await _isConnected) {
        await _remoteDataSource.unsubscribeFromEventNotifications(eventId);
      }
      
      return const Right(null);
    } on ServerException catch (e) {
      AppLogger.error('Error unsubscribing from event notifications', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error unsubscribing from event notifications', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<TimetableEvent>>>> getCalendarData({
    required DateTime startDate,
    required DateTime endDate,
    CalendarView view = CalendarView.month,
  }) async {
    try {
      if (await _isConnected) {
        try {
          final remoteCalendarData = await _remoteDataSource.getCalendarData(
            startDate: startDate,
            endDate: endDate,
            view: view,
          );
          
          // Cache all events from calendar data
          final allEvents = <TimetableEventModel>[];
          remoteCalendarData.values.forEach((events) {
            allEvents.addAll(events);
          });
          await _localDataSource.cacheEvents(allEvents);
          
          return Right(remoteCalendarData.cast<String, List<TimetableEvent>>());
        } on ServerException catch (e) {
          AppLogger.warning('Remote fetch failed, falling back to cache', e);
        }
      }
      
      // Generate calendar data from cached events
      final cachedEvents = await _localDataSource.getCachedEvents(
        startDate: startDate,
        endDate: endDate,
      );
      
      final calendarData = _generateCalendarDataFromEvents(cachedEvents);
      return Right(calendarData);
    } catch (e) {
      AppLogger.error('Error getting calendar data', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> searchEvents({
    required String query,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (await _isConnected) {
        try {
          final remoteEvents = await _remoteDataSource.searchEvents(
            query: query,
            type: type,
            startDate: startDate,
            endDate: endDate,
          );
          return Right(remoteEvents);
        } on ServerException catch (e) {
          AppLogger.warning('Remote search failed, searching cache', e);
        }
      }
      
      // Search in cached events
      final cachedEvents = await _localDataSource.getCachedEvents(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      
      final filteredEvents = cachedEvents.where((event) {
        final searchQuery = query.toLowerCase();
        return event.title.toLowerCase().contains(searchQuery) ||
               event.description.toLowerCase().contains(searchQuery) ||
               (event.location?.toLowerCase().contains(searchQuery) ?? false) ||
               (event.tags?.any((tag) => tag.toLowerCase().contains(searchQuery)) ?? false);
      }).toList();
      
      return Right(filteredEvents);
    } catch (e) {
      AppLogger.error('Error searching events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getCachedEvents() async {
    try {
      final cachedEvents = await _localDataSource.getCachedEvents();
      return Right(cachedEvents);
    } catch (e) {
      AppLogger.error('Error getting cached events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncEvents() async {
    try {
      if (!await _isConnected) {
        return const Left(ServerFailure(message: 'No internet connection'));
      }

      final queuedChanges = await _localDataSource.getQueuedEventChanges();
      
      for (final queuedItem in queuedChanges) {
        try {
          final action = queuedItem['action'] as String;
          final queueId = queuedItem['queue_id'] as String;
          
          switch (action) {
            case 'create':
              await _remoteDataSource.createEvent(
                type: EventType.values.firstWhere(
                  (e) => e.toString().split('.').last == queuedItem['type'] as String,
                ),
                title: queuedItem['title'] as String,
                description: queuedItem['description'] as String,
                startDateTime: DateTime.parse(queuedItem['start_date_time'] as String),
                endDateTime: queuedItem['end_date_time'] != null
                    ? DateTime.parse(queuedItem['end_date_time'] as String)
                    : null,
                location: queuedItem['location'] as String?,
                relatedElectionId: queuedItem['related_election_id'] as String?,
                relatedCandidateId: queuedItem['related_candidate_id'] as String?,
                tags: (queuedItem['tags'] as List<dynamic>?)?.cast<String>(),
                metadata: queuedItem['metadata'] as Map<String, dynamic>?,
                isAllDay: queuedItem['is_all_day'] as bool? ?? false,
                color: queuedItem['color'] as String?,
              );
              break;
            case 'update':
              await _remoteDataSource.updateEvent(
                id: queuedItem['id'] as String,
                type: queuedItem['type'] != null
                    ? EventType.values.firstWhere(
                        (e) => e.toString().split('.').last == queuedItem['type'] as String,
                      )
                    : null,
                title: queuedItem['title'] as String?,
                description: queuedItem['description'] as String?,
                startDateTime: queuedItem['start_date_time'] != null
                    ? DateTime.parse(queuedItem['start_date_time'] as String)
                    : null,
                endDateTime: queuedItem['end_date_time'] != null
                    ? DateTime.parse(queuedItem['end_date_time'] as String)
                    : null,
                status: queuedItem['status'] != null
                    ? EventStatus.values.firstWhere(
                        (e) => e.toString().split('.').last == queuedItem['status'] as String,
                      )
                    : null,
                location: queuedItem['location'] as String?,
                tags: (queuedItem['tags'] as List<dynamic>?)?.cast<String>(),
                metadata: queuedItem['metadata'] as Map<String, dynamic>?,
                isAllDay: queuedItem['is_all_day'] as bool?,
                color: queuedItem['color'] as String?,
              );
              break;
            case 'delete':
              await _remoteDataSource.deleteEvent(queuedItem['id'] as String);
              break;
          }
          
          // Remove from queue after successful sync
          await _localDataSource.removeQueuedEventChange(queueId);
        } catch (e) {
          AppLogger.warning('Failed to sync queued event change: ${e.toString()}');
          // Continue with next item
        }
      }
      
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error syncing events', e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> queueEventChange({
    required String action,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      await _localDataSource.queueEventChangeForSync(
        action: action,
        eventData: eventData,
      );
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error queuing event change', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getQueuedEventChanges() async {
    try {
      final queuedChanges = await _localDataSource.getQueuedEventChanges();
      return Right(queuedChanges);
    } catch (e) {
      AppLogger.error('Error getting queued event changes', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearQueuedEventChanges() async {
    try {
      await _localDataSource.clearQueuedEventChanges();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Error clearing queued event changes', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> checkEventConflicts({
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? excludeEventId,
  }) async {
    try {
      if (await _isConnected) {
        try {
          final conflicts = await _remoteDataSource.checkEventConflicts(
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            excludeEventId: excludeEventId,
          );
          return Right(conflicts);
        } on ServerException catch (e) {
          AppLogger.warning('Remote conflict check failed, checking cache', e);
        }
      }
      
      // Check conflicts in cached events
      final cachedEvents = await _localDataSource.getCachedEvents();
      final conflicts = <TimetableEventModel>[];
      
      for (final event in cachedEvents) {
        if (excludeEventId != null && event.id == excludeEventId) continue;
        
        final eventEnd = event.endDateTime ?? event.startDateTime.add(const Duration(hours: 1));
        final checkEnd = endDateTime ?? startDateTime.add(const Duration(hours: 1));
        
        // Check if events overlap
        if (startDateTime.isBefore(eventEnd) && checkEnd.isAfter(event.startDateTime)) {
          conflicts.add(event);
        }
      }
      
      return Right(conflicts);
    } catch (e) {
      AppLogger.error('Error checking event conflicts', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> getRecurringEventInstances({
    required String parentEventId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // For now, return empty list as recurring events are not implemented
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<TimetableEvent>>> importEvents(
    String calendarData,
    String format,
  ) async {
    try {
      if (!await _isConnected) {
        return const Left(ServerFailure(message: 'No internet connection required for import'));
      }
      
      final importedEvents = await _remoteDataSource.importEvents(calendarData, format);
      await _localDataSource.cacheEvents(importedEvents);
      return Right(importedEvents);
    } on ServerException catch (e) {
      AppLogger.error('Error importing events', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error importing events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> exportEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    EventType? type,
  }) async {
    try {
      if (!await _isConnected) {
        return const Left(ServerFailure(message: 'No internet connection required for export'));
      }
      
      final exportedData = await _remoteDataSource.exportEvents(
        startDate: startDate,
        endDate: endDate,
        format: format,
        type: type,
      );
      return Right(exportedData);
    } on ServerException catch (e) {
      AppLogger.error('Error exporting events', e);
      return Left(ServerFailure.fromException(e));
    } catch (e) {
      AppLogger.error('Unexpected error exporting events', e);
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Generate timetable summary from cached events
  TimetableSummary _generateSummaryFromEvents(List<TimetableEventModel> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final totalEvents = events.length;
    final activeEvents = events.where((e) => e.isActive).length;
    final upcomingEvents = events.where((e) => e.isUpcoming).length;
    
    final eventsByType = <EventType, int>{};
    for (final type in EventType.values) {
      eventsByType[type] = events.where((e) => e.type == type).length;
    }
    
    final todayEvents = events.where((e) =>
      e.startDateTime.isAfter(today) && e.startDateTime.isBefore(tomorrow)
    ).cast<TimetableEvent>().toList();
    
    final upcomingElections = events.where((e) =>
      e.isElectionRelated && e.isUpcoming
    ).cast<TimetableEvent>().toList();
    
    return TimetableSummaryModel(
      totalEvents: totalEvents,
      activeEvents: activeEvents,
      upcomingEvents: upcomingEvents,
      eventsByType: eventsByType,
      todayEvents: todayEvents,
      upcomingElections: upcomingElections,
    );
  }

  /// Generate calendar data from events
  Map<String, List<TimetableEvent>> _generateCalendarDataFromEvents(
    List<TimetableEventModel> events,
  ) {
    final calendarData = <String, List<TimetableEvent>>{};
    
    for (final event in events) {
      final dateKey = '${event.startDateTime.year}-${event.startDateTime.month.toString().padLeft(2, '0')}-${event.startDateTime.day.toString().padLeft(2, '0')}';
      
      if (calendarData.containsKey(dateKey)) {
        calendarData[dateKey]!.add(event);
      } else {
        calendarData[dateKey] = [event];
      }
    }
    
    // Sort events for each date
    calendarData.forEach((date, events) {
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    });
    
    return calendarData;
  }
}