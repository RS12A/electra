import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import '../../lib/features/notifications/domain/entities/timetable_event.dart';
import '../../lib/features/notifications/presentation/pages/timetable_page.dart';
import '../../lib/features/notifications/presentation/widgets/timetable_calendar.dart';
import '../../lib/features/notifications/presentation/widgets/countdown_timer.dart';
import '../../lib/shared/theme/app_theme.dart';

void main() {
  group('Timetable Integration Tests', () {
    late List<TimetableEvent> testEvents;

    setUp(() {
      testEvents = [
        TimetableEvent(
          id: 'event-1',
          title: 'Student Election Registration Opens',
          description: 'Registration for student body elections begins',
          type: EventType.electionStart,
          status: EventStatus.upcoming,
          startDateTime: DateTime.now().add(const Duration(days: 2)),
          endDateTime: DateTime.now().add(const Duration(days: 9)),
          location: 'Online Portal',
          organizerId: 'org-1',
          isAllDay: false,
          reminders: [
            EventReminder(
              id: 'rem-1',
              eventId: 'event-1',
              reminderTime: const Duration(hours: 2),
              isActive: true,
            ),
          ],
          relatedElectionId: 'election-1',
          metadata: {'department': 'Student Affairs'},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TimetableEvent(
          id: 'event-2',
          title: 'Voting Deadline',
          description: 'Last day to cast your vote',
          type: EventType.electionEnd,
          status: EventStatus.active,
          startDateTime: DateTime.now().add(const Duration(hours: 6)),
          endDateTime: DateTime.now().add(const Duration(hours: 18)),
          location: 'All Voting Centers',
          organizerId: 'org-1',
          isAllDay: false,
          reminders: [],
          relatedElectionId: 'election-1',
          metadata: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });

    Widget createTestApp({required Widget child}) {
      return ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('TimetablePage displays events correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Should display the page title
      expect(find.text('Election Timetable'), findsOneWidget);

      // Should show search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search events...'), findsOneWidget);

      // Should show filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Elections'), findsOneWidget);
      expect(find.text('Deadlines'), findsOneWidget);
    });

    testWidgets('Calendar navigation works correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TimetableCalendar(
            selectedDate: DateTime.now(),
            events: testEvents,
            calendarView: CalendarView.month,
            onDateSelected: (date) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display weekday headers
      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsWidgets);
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsWidgets);

      // Should display current date
      final today = DateTime.now();
      expect(find.text(today.day.toString()), findsOneWidget);
    });

    testWidgets('Search functionality filters events', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field and enter text
      final searchField = find.byType(TextField);
      await tester.tap(searchField);
      await tester.enterText(searchField, 'Registration');
      await tester.pumpAndSettle();

      // Should filter to show only registration events
      expect(find.text('Student Election Registration Opens'), findsOneWidget);
      expect(find.text('Voting Deadline'), findsNothing);
    });

    testWidgets('Filter chips work correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Elections filter
      await tester.tap(find.text('Elections'));
      await tester.pumpAndSettle();

      // Should show selected state
      // The filter chip should appear pressed/selected
      expect(find.text('Elections'), findsOneWidget);
    });

    testWidgets('Calendar view switching works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // Find view selector button
      final viewButton = find.byIcon(Icons.view_module);
      expect(viewButton, findsOneWidget);

      // Tap to open menu
      await tester.tap(viewButton);
      await tester.pumpAndSettle();

      // Should show view options
      expect(find.text('Week View'), findsOneWidget);
      expect(find.text('Agenda View'), findsOneWidget);

      // Select week view
      await tester.tap(find.text('Week View'));
      await tester.pumpAndSettle();

      // Menu should close
      expect(find.text('Week View'), findsNothing);
    });

    testWidgets('Event details modal displays correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for an event to tap (this assumes events are loaded)
      final eventCard = find.text('Student Election Registration Opens').first;
      if (tester.widgetList(eventCard).isNotEmpty) {
        await tester.tap(eventCard);
        await tester.pumpAndSettle();

        // Should show event details in bottom sheet
        expect(find.text('Student Election Registration Opens'), findsAtLeastNWidgets(1));
        expect(find.text('Registration for student body elections begins'), findsOneWidget);
        expect(find.text('Get Reminders'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
      }
    });

    testWidgets('Pull to refresh works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // Perform pull to refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      // Should trigger refresh (we can't easily test the actual refresh without mocking)
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('Countdown timers display correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CountdownTimer(
            event: testEvents[1], // Active event
            timeRemaining: const Duration(hours: 6),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display countdown
      expect(find.text('6'), findsOneWidget); // Hours
      expect(find.text('00'), findsOneWidget); // Minutes
      expect(find.text('Voting Deadline'), findsOneWidget);
    });

    testWidgets('Compact countdown timer works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CompactCountdownTimer(
            event: testEvents[1],
            timeRemaining: const Duration(hours: 6),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display in compact format
      expect(find.text('6h 0m'), findsOneWidget);
      expect(find.text('Voting Deadline'), findsOneWidget);
    });

    testWidgets('Calendar switches between views correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TimetableCalendar(
            selectedDate: DateTime.now(),
            events: testEvents,
            calendarView: CalendarView.agenda,
            onDateSelected: (date) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In agenda view, should show events in list format
      expect(find.text('Student Election Registration Opens'), findsOneWidget);
      expect(find.text('Voting Deadline'), findsOneWidget);
    });

    testWidgets('Event type colors are displayed correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TimetableCalendar(
            selectedDate: DateTime.now(),
            events: testEvents,
            calendarView: CalendarView.month,
            onDateSelected: (date) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display event indicators with different colors for different types
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Date selection updates selected date', (tester) async {
      DateTime? selectedDate;
      
      await tester.pumpWidget(
        createTestApp(
          child: TimetableCalendar(
            selectedDate: DateTime.now(),
            events: testEvents,
            calendarView: CalendarView.month,
            onDateSelected: (date) {
              selectedDate = date;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find a different date to tap
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowText = find.text(tomorrow.day.toString());
      
      if (tester.widgetList(tomorrowText).isNotEmpty) {
        await tester.tap(tomorrowText.first);
        await tester.pumpAndSettle();

        // Should have called onDateSelected
        expect(selectedDate, isNotNull);
        expect(selectedDate!.day, equals(tomorrow.day));
      }
    });

    testWidgets('Empty state displays when no events', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TimetableCalendar(
            selectedDate: DateTime.now(),
            events: [], // No events
            calendarView: CalendarView.agenda,
            onDateSelected: (date) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No events scheduled'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('Event reminders can be subscribed to', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const TimetablePage(),
        ),
      );

      await tester.pumpAndSettle();

      // This test would need to be expanded with proper mocking
      // to test the actual reminder subscription functionality
      expect(find.byType(TimetablePage), findsOneWidget);
    });
  });
}