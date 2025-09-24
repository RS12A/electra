import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../core/network/network_service.dart';
import '../../../core/error/exceptions.dart';
import '../../../shared/utils/logger.dart';
import '../models/timetable_event_model.dart';
import '../../domain/entities/timetable_event.dart';
import 'timetable_datasource.dart';

/// Remote data source implementation for timetable API
@Injectable(as: TimetableRemoteDataSource)
class TimetableRemoteDataSourceImpl implements TimetableRemoteDataSource {
  const TimetableRemoteDataSourceImpl(this._networkService);

  final NetworkService _networkService;

  @override
  Future<List<TimetableEventModel>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
    String? relatedElectionId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (type != null) queryParams['type'] = type.toString().split('.').last;
      if (status != null) queryParams['status'] = status.toString().split('.').last;
      if (relatedElectionId != null) queryParams['election_id'] = relatedElectionId;

      final response = await _networkService.dio.get(
        '/api/timetable/events/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting events', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableEventModel> getEventById(String id) async {
    try {
      final response = await _networkService.dio.get('/api/timetable/events/$id/');

      if (response.statusCode == 200) {
        return TimetableEventModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to get event',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting event by ID', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting event by ID', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> getEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    
    return getEvents(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Future<List<TimetableEventModel>> getActiveEvents() async {
    try {
      final response = await _networkService.dio.get('/api/timetable/events/active/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get active events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting active events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting active events', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> getUpcomingEvents({
    int? limit,
    Duration? withinDuration,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (limit != null) queryParams['limit'] = limit;
      if (withinDuration != null) {
        final endTime = DateTime.now().add(withinDuration);
        queryParams['within_time'] = endTime.toIso8601String();
      }

      final response = await _networkService.dio.get(
        '/api/timetable/events/upcoming/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to get upcoming events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting upcoming events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting upcoming events', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableEventModel> createEvent({
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
      final Map<String, dynamic> data = {
        'type': type.toString().split('.').last,
        'title': title,
        'description': description,
        'start_date_time': startDateTime.toIso8601String(),
        'is_all_day': isAllDay,
      };

      if (endDateTime != null) data['end_date_time'] = endDateTime.toIso8601String();
      if (location != null) data['location'] = location;
      if (relatedElectionId != null) data['related_election_id'] = relatedElectionId;
      if (relatedCandidateId != null) data['related_candidate_id'] = relatedCandidateId;
      if (tags != null) data['tags'] = tags;
      if (metadata != null) data['metadata'] = metadata;
      if (color != null) data['color'] = color;

      final response = await _networkService.dio.post(
        '/api/timetable/events/',
        data: data,
      );

      if (response.statusCode == 201) {
        return TimetableEventModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to create event',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error creating event', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error creating event', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableEventModel> updateEvent({
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
      final Map<String, dynamic> data = {};

      if (type != null) data['type'] = type.toString().split('.').last;
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (startDateTime != null) data['start_date_time'] = startDateTime.toIso8601String();
      if (endDateTime != null) data['end_date_time'] = endDateTime.toIso8601String();
      if (status != null) data['status'] = status.toString().split('.').last;
      if (location != null) data['location'] = location;
      if (tags != null) data['tags'] = tags;
      if (metadata != null) data['metadata'] = metadata;
      if (isAllDay != null) data['is_all_day'] = isAllDay;
      if (color != null) data['color'] = color;

      final response = await _networkService.dio.patch(
        '/api/timetable/events/$id/',
        data: data,
      );

      if (response.statusCode == 200) {
        return TimetableEventModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to update event',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error updating event', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error updating event', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteEvent(String id) async {
    try {
      final response = await _networkService.dio.delete('/api/timetable/events/$id/');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete event',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error deleting event', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error deleting event', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<TimetableSummaryModel> getTimetableSummary() async {
    try {
      final response = await _networkService.dio.get('/api/timetable/summary/');

      if (response.statusCode == 200) {
        return TimetableSummaryModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to get timetable summary',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting timetable summary', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting timetable summary', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> getElectionEvents(String electionId) async {
    return getEvents(relatedElectionId: electionId);
  }

  @override
  Future<void> subscribeToEventNotifications(
    String eventId,
    Duration notificationTime,
  ) async {
    try {
      final response = await _networkService.dio.post(
        '/api/timetable/events/$eventId/subscribe/',
        data: {
          'notification_time_minutes': notificationTime.inMinutes,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to subscribe to event notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error subscribing to event notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error subscribing to event notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> unsubscribeFromEventNotifications(String eventId) async {
    try {
      final response = await _networkService.dio.delete(
        '/api/timetable/events/$eventId/unsubscribe/',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to unsubscribe from event notifications',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error unsubscribing from event notifications', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error unsubscribing from event notifications', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, List<TimetableEventModel>>> getCalendarData({
    required DateTime startDate,
    required DateTime endDate,
    CalendarView view = CalendarView.month,
  }) async {
    try {
      final response = await _networkService.dio.get(
        '/api/timetable/calendar/',
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'view': view.toString().split('.').last,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final Map<String, List<TimetableEventModel>> calendarData = {};
        
        data.forEach((dateKey, eventsData) {
          final List<dynamic> events = eventsData as List<dynamic>;
          calendarData[dateKey] = events
              .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
              .toList();
        });

        return calendarData;
      } else {
        throw ServerException(
          message: 'Failed to get calendar data',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error getting calendar data', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error getting calendar data', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> searchEvents({
    required String query,
    EventType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'q': query,
      };
      
      if (type != null) queryParams['type'] = type.toString().split('.').last;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _networkService.dio.get(
        '/api/timetable/events/search/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to search events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error searching events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error searching events', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> checkEventConflicts({
    required DateTime startDateTime,
    DateTime? endDateTime,
    String? excludeEventId,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'start_date_time': startDateTime.toIso8601String(),
      };
      
      if (endDateTime != null) {
        queryParams['end_date_time'] = endDateTime.toIso8601String();
      }
      if (excludeEventId != null) {
        queryParams['exclude_event_id'] = excludeEventId;
      }

      final response = await _networkService.dio.get(
        '/api/timetable/events/check-conflicts/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['conflicts'] ?? [];
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to check event conflicts',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error checking event conflicts', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error checking event conflicts', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<TimetableEventModel>> importEvents(
    String calendarData,
    String format,
  ) async {
    try {
      final response = await _networkService.dio.post(
        '/api/timetable/events/import/',
        data: {
          'calendar_data': calendarData,
          'format': format,
        },
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = response.data['imported_events'] ?? [];
        return data
            .map((json) => TimetableEventModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to import events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error importing events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error importing events', e);
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> exportEvents({
    required DateTime startDate,
    required DateTime endDate,
    required String format,
    EventType? type,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'format': format,
      };
      
      if (type != null) queryParams['type'] = type.toString().split('.').last;

      final response = await _networkService.dio.get(
        '/api/timetable/events/export/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['calendar_data'] as String;
      } else {
        throw ServerException(
          message: 'Failed to export events',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Error exporting events', e);
      throw ServerException.fromDioError(e);
    } catch (e) {
      AppLogger.error('Unexpected error exporting events', e);
      throw ServerException(message: e.toString());
    }
  }
}