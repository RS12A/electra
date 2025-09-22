import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:electra_flutter/features/admin_dashboard/presentation/pages/dashboard_home_page.dart';
import 'package:electra_flutter/core/theme/app_theme.dart';

void main() {
  group('DashboardHomePage Widget Tests', () {
    testWidgets('should display welcome message and dashboard title', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Welcome Back, Admin'), findsOneWidget);
      expect(find.text('Here\'s what\'s happening in your election system today.'), findsOneWidget);
    });

    testWidgets('should display statistics cards', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('Active Elections'), findsOneWidget);
      expect(find.text('Votes Cast'), findsOneWidget);
      expect(find.text('Participation'), findsOneWidget);
      
      // Check if stat values are displayed
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('8,976'), findsOneWidget);
      expect(find.text('89.2%'), findsOneWidget);
    });

    testWidgets('should display active elections section', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Active Elections'), findsOneWidget);
      expect(find.text('Student Union President 2024'), findsOneWidget);
      expect(find.text('Faculty Representative'), findsOneWidget);
      expect(find.text('Sports Committee'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    });

    testWidgets('should display recent activity section', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('New user registered'), findsOneWidget);
      expect(find.text('Election activated'), findsOneWidget);
      expect(find.text('Candidate added'), findsOneWidget);
      expect(find.text('Ballot tokens issued'), findsOneWidget);
    });

    testWidgets('should display app bar with notifications and profile', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should handle notifications button tap', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.notifications_outlined));
      await tester.pumpAndSettle();

      // assert - The button should be tappable (no exception thrown)
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should display progress indicators for elections', (WidgetTester tester) async {
      // arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      // act
      await tester.pumpAndSettle();

      // assert
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3)); // Three active elections
      expect(find.text('78.5%'), findsOneWidget);
      expect(find.text('45.2%'), findsOneWidget);
      expect(find.text('23.8%'), findsOneWidget);
    });

    testWidgets('should be responsive for different screen sizes', (WidgetTester tester) async {
      // Test desktop layout
      tester.binding.window.physicalSizeTestValue = const Size(1200, 800);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Desktop layout should show stats in a row
      expect(find.text('Total Users'), findsOneWidget);
      
      // Test mobile layout
      tester.binding.window.physicalSizeTestValue = const Size(400, 800);
      
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DashboardHomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mobile layout should still display all elements
      expect(find.text('Total Users'), findsOneWidget);
      
      // Reset to default
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}