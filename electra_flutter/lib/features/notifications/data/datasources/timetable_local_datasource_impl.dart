import 'package:injectable/injectable.dart';

import '../../../core/storage/storage_service.dart';
import '../../../shared/utils/logger.dart';
import '../models/timetable_event_model.dart';
import '../../domain/entities/timetable_event.dart';
import 'timetable_datasource.dart';

/// Local data source implementation for timetable caching
@Injectable(as: TimetableLocalDataSource)
class TimetableLocalDataSourceImpl implements TimetableLocalDataSource {
  const TimetableLocalDataSourceImpl(this._storageService);

  final StorageService _storageService;

  static const String _eventsCacheKey = 'timetable_events_cache';
  static const String _eventsSummaryCacheKey = 'timetable_summary_cache';
  static const String _eventNotificationSubscriptionsKey = 'event_notification_subscriptions';
  static const String _queueKeyPrefix = 'timetable_queue_';

  @override
  Future<List<TimetableEventModel>> getCachedEvents({
    DateTime? startDate,
    DateTime? endDate,
    EventType? type,
    EventStatus? status,
  }) async {
    try {
      final cachedData = await _storageService.getCachedData(_eventsCacheKey);
      if (cachedData == null) return [];

      final List<dynamic> eventsList = cachedData['events'] as List<dynamic>? ?? [];
      List<TimetableEventModel> events = eventsList
          .map((json) => TimetableEventModel.fromCacheMap(json as Map<String, dynamic>))
          .toList();

      // Apply filters
      if (startDate != null) {
        events = events.where((e) => 
          e.startDateTime.isAfter(startDate) || e.startDateTime.isAtSameMomentAs(startDate)
        ).toList();
      }
      
      if (endDate != null) {
        events = events.where((e) => 
          e.startDateTime.isBefore(endDate) || e.startDateTime.isAtSameMomentAs(endDate)
        ).toList();
      }
      
      if (type != null) {
        events = events.where((e) => e.type == type).toList();
      }
      
      if (status != null) {
        events = events.where((e) => e.status == status).toList();
      }

      // Sort by start date time
      events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

      return events;
    } catch (e) {
      AppLogger.error('Error getting cached events', e);
      return [];
    }
  }

  @override
  Future<void> cacheEvents(List<TimetableEventModel> events) async {
    try {
      final cacheData = {
        'events': events.map((e) => e.toCacheMap()).toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      await _storageService.cacheData(_eventsCacheKey, cacheData);
      AppLogger.debug('Cached ${events.length} events');
    } catch (e) {
      AppLogger.error('Error caching events', e);
    }
  }

  @override
  Future<TimetableEventModel?> getCachedEventById(String id) async {
    try {
      final events = await getCachedEvents();
      return events.cast<TimetableEventModel?>().firstWhere(
        (e) => e?.id == id,
        orElse: () => null,
      );
    } catch (e) {
      AppLogger.error('Error getting cached event by ID', e);
      return null;
    }
  }

  @override
  Future<void> cacheEvent(TimetableEventModel event) async {
    try {
      final existingEvents = await getCachedEvents();
      final index = existingEvents.indexWhere((e) => e.id == event.id);
      
      if (index != -1) {
        existingEvents[index] = event;
      } else {
        existingEvents.add(event);
      }

      await cacheEvents(existingEvents);
      AppLogger.debug('Cached single event: ${event.id}');
    } catch (e) {
      AppLogger.error('Error caching single event', e);
    }
  }

  @override
  Future<void> updateCachedEvent(TimetableEventModel event) async {
    try {
      final existingEvents = await getCachedEvents();
      final index = existingEvents.indexWhere((e) => e.id == event.id);
      
      if (index != -1) {
        existingEvents[index] = event;
        await cacheEvents(existingEvents);
        AppLogger.debug('Updated cached event: ${event.id}');
      }
    } catch (e) {
      AppLogger.error('Error updating cached event', e);
    }
  }

  @override
  Future<void> removeCachedEvent(String id) async {
    try {
      final existingEvents = await getCachedEvents();
      existingEvents.removeWhere((e) => e.id == id);
      await cacheEvents(existingEvents);
      AppLogger.debug('Removed cached event: $id');
    } catch (e) {
      AppLogger.error('Error removing cached event', e);
    }
  }

  @override
  Future<void> clearCachedEvents() async {
    try {
      await _storageService.deleteCachedData(_eventsCacheKey);
      AppLogger.debug('Cleared all cached events');
    } catch (e) {
      AppLogger.error('Error clearing cached events', e);
    }
  }

  @override
  Future<List<TimetableEventModel>> getCachedEventsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    
    return getCachedEvents(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Future<List<TimetableEventModel>> getCachedActiveEvents() async {
    final now = DateTime.now();
    final events = await getCachedEvents();
    
    return events.where((event) {
      if (event.endDateTime != null) {
        return now.isAfter(event.startDateTime) && now.isBefore(event.endDateTime!);
      }
      return event.startDateTime.isBefore(now) && 
             now.difference(event.startDateTime).inHours < 24; // Active within 24 hours
    }).toList();
  }

  @override
  Future<List<TimetableEventModel>> getCachedUpcomingEvents() async {
    final now = DateTime.now();
    final events = await getCachedEvents(startDate: now);
    
    return events.where((event) => event.startDateTime.isAfter(now)).take(50).toList();
  }

  @override
  Future<TimetableSummaryModel?> getCachedTimetableSummary() async {
    try {
      final cachedData = await _storageService.getCachedData(_eventsSummaryCacheKey);
      if (cachedData == null) return null;

      return TimetableSummaryModel.fromJson(cachedData as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error('Error getting cached timetable summary', e);
      return null;
    }
  }

  @override
  Future<void> cacheTimetableSummary(TimetableSummaryModel summary) async {
    try {
      await _storageService.cacheData(
        _eventsSummaryCacheKey,
        summary.toJson(),
      );
      AppLogger.debug('Cached timetable summary');
    } catch (e) {
      AppLogger.error('Error caching timetable summary', e);
    }
  }

  @override
  Future<void> queueEventChangeForSync({
    required String action,
    required Map<String, dynamic> eventData,
  }) async {
    try {
      final queueData = {
        'action': action,
        'data': eventData,
      };
      
      await _storageService.queueForSync('timetable_event', queueData);
      AppLogger.debug('Queued event change for sync: $action');
    } catch (e) {
      AppLogger.error('Error queuing event change for sync', e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getQueuedEventChanges() async {
    try {
      final queuedItems = await _storageService.getQueuedItems();
      final List<Map<String, dynamic>> eventChanges = [];
      
      queuedItems.forEach((key, value) {
        final data = value as Map<String, dynamic>;
        if (data['type'] == 'timetable_event') {
          eventChanges.add({
            'queue_id': key,
            ...data['data'] as Map<String, dynamic>,
          });
        }
      });

      return eventChanges;
    } catch (e) {
      AppLogger.error('Error getting queued event changes', e);
      return [];
    }
  }

  @override
  Future<void> removeQueuedEventChange(String queueId) async {
    try {
      await _storageService.removeFromQueue(queueId);
      AppLogger.debug('Removed queued event change: $queueId');
    } catch (e) {
      AppLogger.error('Error removing queued event change', e);
    }
  }

  @override
  Future<void> clearQueuedEventChanges() async {
    try {
      final queuedItems = await _storageService.getQueuedItems();
      
      for (final key in queuedItems.keys) {
        final data = queuedItems[key] as Map<String, dynamic>;
        if (data['type'] == 'timetable_event') {
          await _storageService.removeFromQueue(key);
        }
      }
      
      AppLogger.debug('Cleared all queued event changes');
    } catch (e) {
      AppLogger.error('Error clearing queued event changes', e);
    }
  }

  @override
  Future<void> saveEventNotificationSubscription(
    String eventId,
    Duration notificationTime,
  ) async {
    try {
      final subscriptions = await getEventNotificationSubscriptions();
      subscriptions[eventId] = notificationTime;
      
      final subscriptionsData = <String, int>{};
      subscriptions.forEach((eventId, duration) {
        subscriptionsData[eventId] = duration.inMinutes;
      });

      await _storageService.cacheData(
        _eventNotificationSubscriptionsKey,
        subscriptionsData,
      );
      
      AppLogger.debug('Saved event notification subscription: $eventId');
    } catch (e) {
      AppLogger.error('Error saving event notification subscription', e);
    }
  }

  @override
  Future<void> removeEventNotificationSubscription(String eventId) async {
    try {
      final subscriptions = await getEventNotificationSubscriptions();
      subscriptions.remove(eventId);
      
      final subscriptionsData = <String, int>{};
      subscriptions.forEach((eventId, duration) {
        subscriptionsData[eventId] = duration.inMinutes;
      });

      await _storageService.cacheData(
        _eventNotificationSubscriptionsKey,
        subscriptionsData,
      );
      
      AppLogger.debug('Removed event notification subscription: $eventId');
    } catch (e) {
      AppLogger.error('Error removing event notification subscription', e);
    }
  }

  @override
  Future<Map<String, Duration>> getEventNotificationSubscriptions() async {
    try {
      final cachedData = await _storageService.getCachedData(_eventNotificationSubscriptionsKey);
      if (cachedData == null) return {};

      final Map<String, dynamic> subscriptionsData = cachedData as Map<String, dynamic>;
      final Map<String, Duration> subscriptions = {};
      
      subscriptionsData.forEach((eventId, minutes) {
        subscriptions[eventId] = Duration(minutes: minutes as int);
      });

      return subscriptions;
    } catch (e) {
      AppLogger.error('Error getting event notification subscriptions', e);
      return {};
    }
  }
}