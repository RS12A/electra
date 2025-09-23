import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../entities/timetable_event.dart';
import '../repositories/timetable_repository.dart';

/// Use case for getting events
class GetEvents extends UseCase<List<TimetableEvent>, GetEventsParams> {
  const GetEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call(GetEventsParams params) async {
    return await repository.getEvents(
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
      status: params.status,
      relatedElectionId: params.relatedElectionId,
    );
  }
}

/// Parameters for getting events
class GetEventsParams {
  const GetEventsParams({
    this.startDate,
    this.endDate,
    this.type,
    this.status,
    this.relatedElectionId,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final EventType? type;
  final EventStatus? status;
  final String? relatedElectionId;
}

/// Use case for getting a single event by ID
class GetEventById extends UseCase<TimetableEvent, StringParams> {
  const GetEventById(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, TimetableEvent>> call(StringParams params) async {
    return await repository.getEventById(params.value);
  }
}

/// Use case for getting events for a specific date
class GetEventsForDate extends UseCase<List<TimetableEvent>, DateParams> {
  const GetEventsForDate(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call(DateParams params) async {
    return await repository.getEventsForDate(params.date);
  }
}

/// Parameters for date-based queries
class DateParams {
  const DateParams(this.date);

  final DateTime date;
}

/// Use case for getting active events
class GetActiveEvents extends NoParamsUseCase<List<TimetableEvent>> {
  const GetActiveEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call() async {
    return await repository.getActiveEvents();
  }
}

/// Use case for getting upcoming events
class GetUpcomingEvents extends UseCase<List<TimetableEvent>, GetUpcomingEventsParams> {
  const GetUpcomingEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call(GetUpcomingEventsParams params) async {
    return await repository.getUpcomingEvents(
      limit: params.limit,
      withinDuration: params.withinDuration,
    );
  }
}

/// Parameters for getting upcoming events
class GetUpcomingEventsParams {
  const GetUpcomingEventsParams({
    this.limit,
    this.withinDuration,
  });

  final int? limit;
  final Duration? withinDuration;
}

/// Use case for creating an event
class CreateEvent extends UseCase<TimetableEvent, CreateEventParams> {
  const CreateEvent(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, TimetableEvent>> call(CreateEventParams params) async {
    return await repository.createEvent(
      type: params.type,
      title: params.title,
      description: params.description,
      startDateTime: params.startDateTime,
      endDateTime: params.endDateTime,
      location: params.location,
      relatedElectionId: params.relatedElectionId,
      relatedCandidateId: params.relatedCandidateId,
      tags: params.tags,
      metadata: params.metadata,
      isAllDay: params.isAllDay,
      color: params.color,
    );
  }
}

/// Parameters for creating an event
class CreateEventParams {
  const CreateEventParams({
    required this.type,
    required this.title,
    required this.description,
    required this.startDateTime,
    this.endDateTime,
    this.location,
    this.relatedElectionId,
    this.relatedCandidateId,
    this.tags,
    this.metadata,
    this.isAllDay = false,
    this.color,
  });

  final EventType type;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String? location;
  final String? relatedElectionId;
  final String? relatedCandidateId;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final bool isAllDay;
  final String? color;
}

/// Use case for updating an event
class UpdateEvent extends UseCase<TimetableEvent, UpdateEventParams> {
  const UpdateEvent(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, TimetableEvent>> call(UpdateEventParams params) async {
    return await repository.updateEvent(
      id: params.id,
      type: params.type,
      title: params.title,
      description: params.description,
      startDateTime: params.startDateTime,
      endDateTime: params.endDateTime,
      status: params.status,
      location: params.location,
      tags: params.tags,
      metadata: params.metadata,
      isAllDay: params.isAllDay,
      color: params.color,
    );
  }
}

/// Parameters for updating an event
class UpdateEventParams {
  const UpdateEventParams({
    required this.id,
    this.type,
    this.title,
    this.description,
    this.startDateTime,
    this.endDateTime,
    this.status,
    this.location,
    this.tags,
    this.metadata,
    this.isAllDay,
    this.color,
  });

  final String id;
  final EventType? type;
  final String? title;
  final String? description;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final EventStatus? status;
  final String? location;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final bool? isAllDay;
  final String? color;
}

/// Use case for deleting an event
class DeleteEvent extends UseCase<void, StringParams> {
  const DeleteEvent(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, void>> call(StringParams params) async {
    return await repository.deleteEvent(params.value);
  }
}

/// Use case for getting timetable summary
class GetTimetableSummary extends NoParamsUseCase<TimetableSummary> {
  const GetTimetableSummary(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, TimetableSummary>> call() async {
    return await repository.getTimetableSummary();
  }
}

/// Use case for getting election events
class GetElectionEvents extends UseCase<List<TimetableEvent>, StringParams> {
  const GetElectionEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call(StringParams params) async {
    return await repository.getElectionEvents(params.value);
  }
}

/// Use case for subscribing to event notifications
class SubscribeToEventNotifications extends UseCase<void, EventNotificationParams> {
  const SubscribeToEventNotifications(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, void>> call(EventNotificationParams params) async {
    return await repository.subscribeToEventNotifications(
      params.eventId,
      params.notificationTime,
    );
  }
}

/// Parameters for event notification subscription
class EventNotificationParams {
  const EventNotificationParams({
    required this.eventId,
    required this.notificationTime,
  });

  final String eventId;
  final Duration notificationTime;
}

/// Use case for unsubscribing from event notifications
class UnsubscribeFromEventNotifications extends UseCase<void, StringParams> {
  const UnsubscribeFromEventNotifications(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, void>> call(StringParams params) async {
    return await repository.unsubscribeFromEventNotifications(params.value);
  }
}

/// Use case for getting calendar data
class GetCalendarData extends UseCase<Map<String, List<TimetableEvent>>, GetCalendarDataParams> {
  const GetCalendarData(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, Map<String, List<TimetableEvent>>>> call(
    GetCalendarDataParams params,
  ) async {
    return await repository.getCalendarData(
      startDate: params.startDate,
      endDate: params.endDate,
      view: params.view,
    );
  }
}

/// Parameters for getting calendar data
class GetCalendarDataParams {
  const GetCalendarDataParams({
    required this.startDate,
    required this.endDate,
    this.view = CalendarView.month,
  });

  final DateTime startDate;
  final DateTime endDate;
  final CalendarView view;
}

/// Use case for searching events
class SearchEvents extends UseCase<List<TimetableEvent>, SearchEventsParams> {
  const SearchEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call(SearchEventsParams params) async {
    return await repository.searchEvents(
      query: params.query,
      type: params.type,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

/// Parameters for searching events
class SearchEventsParams {
  const SearchEventsParams({
    required this.query,
    this.type,
    this.startDate,
    this.endDate,
  });

  final String query;
  final EventType? type;
  final DateTime? startDate;
  final DateTime? endDate;
}

/// Use case for syncing events
class SyncEvents extends NoParamsUseCase<void> {
  const SyncEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.syncEvents();
  }
}

/// Use case for getting cached events
class GetCachedEvents extends NoParamsUseCase<List<TimetableEvent>> {
  const GetCachedEvents(this.repository);

  final TimetableRepository repository;

  @override
  Future<Either<Failure, List<TimetableEvent>>> call() async {
    return await repository.getCachedEvents();
  }
}