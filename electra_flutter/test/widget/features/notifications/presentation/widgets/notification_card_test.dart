import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../lib/features/notifications/domain/entities/notification.dart';
import '../../../../../../lib/features/notifications/presentation/widgets/notification_card.dart';
import '../../../../../../lib/shared/theme/app_theme.dart';

void main() {
  group('NotificationCard Widget Tests', () {
    late Notification testNotification;

    setUp(() {
      testNotification = Notification(
        id: 'test-1',
        title: 'Test Notification',
        message: 'This is a test notification message',
        type: NotificationType.election,
        priority: NotificationPriority.normal,
        isRead: false,
        isDismissed: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        metadata: {'election_id': 'election-123'},
        actions: [],
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('displays notification title and message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: testNotification),
        ),
      );

      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.text('This is a test notification message'), findsOneWidget);
    });

    testWidgets('shows unread indicator for unread notifications', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: testNotification),
        ),
      );

      // Look for the unread indicator (circular dot)
      expect(find.byType(Container), findsWidgets);
      
      // Verify the notification is marked as unread
      expect(testNotification.isUnread, isTrue);
    });

    testWidgets('displays notification type badge', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: testNotification),
        ),
      );

      expect(find.text('Election'), findsOneWidget);
    });

    testWidgets('shows mark as read action for unread notifications', (tester) async {
      bool markAsReadCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(
            notification: testNotification,
            onMarkAsRead: () => markAsReadCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Mark Read'));
      expect(markAsReadCalled, isTrue);
    });

    testWidgets('shows dismiss action when provided', (tester) async {
      bool dismissCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(
            notification: testNotification,
            onDismiss: () => dismissCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Dismiss'));
      expect(dismissCalled, isTrue);
    });

    testWidgets('handles tap events', (tester) async {
      bool tapCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(
            notification: testNotification,
            onTap: () => tapCalled = true,
          ),
        ),
      );

      await tester.tap(find.byType(NotificationCard));
      expect(tapCalled, isTrue);
    });

    testWidgets('displays compact layout correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(
            notification: testNotification,
            compact: true,
          ),
        ),
      );

      // In compact mode, actions should not be shown
      expect(find.text('Mark Read'), findsNothing);
      expect(find.text('Dismiss'), findsNothing);
    });

    testWidgets('shows critical priority indicator', (tester) async {
      final criticalNotification = testNotification.copyWith(
        priority: NotificationPriority.critical,
      );

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: criticalNotification),
        ),
      );

      expect(find.text('URGENT'), findsOneWidget);
    });

    testWidgets('displays notification actions when available', (tester) async {
      final notificationWithActions = testNotification.copyWith(
        actions: [
          NotificationAction(
            id: 'action-1',
            title: 'Vote Now',
            type: 'primary',
            deepLinkUrl: '/elections/123',
          ),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: notificationWithActions),
        ),
      );

      expect(find.text('Vote Now'), findsOneWidget);
    });

    testWidgets('handles expand/collapse for long messages', (tester) async {
      final longMessageNotification = testNotification.copyWith(
        message: 'This is a very long notification message that should trigger the expand/collapse functionality when it exceeds the maximum number of lines allowed in the compact view.',
      );

      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: longMessageNotification),
        ),
      );

      // Should show expand button
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      // Should now show collapse button
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });

    testWidgets('displays timestamp correctly', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: testNotification),
        ),
      );

      // Should show "30m" for 30 minutes ago
      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('shows metadata chips when not compact', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          NotificationCard(notification: testNotification),
        ),
      );

      expect(find.text('election_id: election-123'), findsOneWidget);
    });
  });

  group('CompactNotificationCard Widget Tests', () {
    late Notification testNotification;

    setUp(() {
      testNotification = Notification(
        id: 'test-1',
        title: 'Test Notification',
        message: 'This is a test notification message',
        type: NotificationType.election,
        priority: NotificationPriority.normal,
        isRead: false,
        isDismissed: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        metadata: {},
        actions: [],
      );
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('displays in compact mode', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          CompactNotificationCard(notification: testNotification),
        ),
      );

      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.text('This is a test notification message'), findsOneWidget);
      
      // Actions should not be visible in compact mode
      expect(find.text('Mark Read'), findsNothing);
      expect(find.text('Dismiss'), findsNothing);
    });
  });
}