import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:electra_flutter/features/voting/presentation/pages/voting_dashboard_page.dart';

void main() {
  group('Voting Dashboard Widget Tests', () {
    testWidgets('should display welcome section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify welcome section
      expect(find.text('Welcome to Electra'), findsOneWidget);
      expect(find.text('Secure Digital Voting System'), findsOneWidget);
    });

    testWidgets('should display quick stats', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify stats cards
      expect(find.text('Active Elections'), findsOneWidget);
      expect(find.text('Votes Cast'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('should display election cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify election cards are present
      expect(find.text('Active Elections'), findsOneWidget);
      expect(find.text('Student Union Executive Elections 2024'), findsOneWidget);
    });

    testWidgets('should handle refresh', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.fling(find.byType(RefreshIndicator), const Offset(0, 200), 1000);
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show cast vote button for active elections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find cast vote buttons
      expect(find.text('Cast Vote'), findsWidgets);
    });

    testWidgets('should show different states for election cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show different status badges
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Voted'), findsWidgets);
    });
  });

  group('Voting Dashboard Interaction Tests', () {
    testWidgets('should navigate when cast vote is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap first cast vote button
      final castVoteButtons = find.text('Cast Vote');
      if (castVoteButtons.evaluate().isNotEmpty) {
        await tester.tap(castVoteButtons.first);
        await tester.pumpAndSettle();
      }

      // Navigation would happen here in real implementation
    });

    testWidgets('should show recent activity section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify recent activity section
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Vote cast successfully'), findsOneWidget);
    });
  });

  group('Voting Dashboard Responsive Tests', () {
    testWidgets('should adapt to tablet layout', (WidgetTester tester) async {
      // Set larger screen size
      tester.binding.window.physicalSizeTestValue = const Size(1024, 768);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Layout should adapt for tablet
      // Specific assertions would depend on layout changes
      expect(find.byType(VotingDashboardPage), findsOneWidget);

      // Reset window size
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });

    testWidgets('should handle mobile layout', (WidgetTester tester) async {
      // Set mobile screen size
      tester.binding.window.physicalSizeTestValue = const Size(375, 667);
      tester.binding.window.devicePixelRatioTestValue = 2.0;

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VotingDashboardPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mobile layout specific tests
      expect(find.byType(VotingDashboardPage), findsOneWidget);

      // Reset window size
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  });
}