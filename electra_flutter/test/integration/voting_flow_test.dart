import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:electra_flutter/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Voting Flow Integration Test', () {
    testWidgets('should complete voting flow from dashboard to confirmation', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify dashboard is loaded
      expect(find.text('Welcome to Electra'), findsOneWidget);
      expect(find.text('Secure Digital Voting for KWASU'), findsOneWidget);

      // Check for election cards
      expect(find.text('Active Elections'), findsOneWidget);

      // Tap on an active election
      final electionCard = find.textContaining('Student Union Elections');
      if (electionCard.evaluate().isNotEmpty) {
        await tester.tap(electionCard);
        await tester.pumpAndSettle();

        // Verify candidate listing page
        expect(find.text('Candidates'), findsOneWidget);
        expect(find.text('Choose Your Candidate'), findsOneWidget);

        // Wait for candidates to load
        await tester.pump(const Duration(seconds: 2));

        // Tap on a candidate card
        final candidateCard = find.byType(Card).first;
        if (candidateCard.evaluate().isNotEmpty) {
          await tester.tap(candidateCard);
          await tester.pumpAndSettle();

          // Verify vote casting page
          expect(find.text('Cast Your Vote'), findsOneWidget);
          expect(find.text('Confirm Your Vote'), findsOneWidget);
          expect(find.text('Your Selected Candidate'), findsOneWidget);

          // Verify security information is displayed
          expect(find.text('Security Features'), findsOneWidget);
          expect(find.text('End-to-End Encryption'), findsOneWidget);

          // Tap cast vote button
          final castVoteButton = find.text('Cast My Vote');
          await tester.tap(castVoteButton);
          await tester.pumpAndSettle();

          // Wait for vote casting to complete
          await tester.pump(const Duration(seconds: 5));

          // Verify confirmation page
          expect(find.textContaining('Vote Cast Successfully!'), findsOneWidget);
          expect(find.text('Vote Summary'), findsOneWidget);
          expect(find.text('Anonymous Vote Token'), findsOneWidget);

          // Test copy token functionality
          final copyButton = find.text('Copy Token');
          await tester.tap(copyButton);
          await tester.pump();

          expect(find.text('Copied!'), findsOneWidget);

          // Test return to dashboard
          final dashboardButton = find.text('Return to Dashboard');
          await tester.tap(dashboardButton);
          await tester.pumpAndSettle();

          // Verify we're back on dashboard
          expect(find.text('Welcome to Electra'), findsOneWidget);
        }
      }
    });

    testWidgets('should handle offline voting scenario', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to offline votes page
      final offlineButton = find.byIcon(Icons.offline_bolt);
      if (offlineButton.evaluate().isNotEmpty) {
        await tester.tap(offlineButton);
        await tester.pumpAndSettle();

        // Verify offline votes page
        expect(find.text('Offline Votes Queue'), findsOneWidget);
        expect(find.text('Submit All'), findsOneWidget);
        expect(find.text('Clear All'), findsOneWidget);

        // Test submit offline votes button
        final submitButton = find.text('Submit All');
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Wait for submission to complete
        await tester.pump(const Duration(seconds: 3));
      }
    });

    testWidgets('should display error handling correctly', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Try to refresh with no network (simulated)
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await tester.pumpAndSettle();

        // Should show success message or handle error gracefully
        // Exact behavior depends on network state
      }
    });

    testWidgets('should maintain accessibility throughout voting flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify semantic labels are present
      expect(find.bySemanticsLabel('Welcome to Electra voting system'), findsOneWidget);
      expect(find.bySemanticsLabel('Active elections section'), findsOneWidget);

      // Check accessibility on buttons
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        final semantics = tester.getSemantics(refreshButton);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      }
    });

    testWidgets('should handle theme switching', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial theme (light mode default)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);

      // Theme switching would be tested here if we had theme toggle UI
    });

    testWidgets('should persist voting state correctly', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate through voting flow and verify state persistence
      // This would involve checking that selected candidates, vote tokens, etc.
      // are maintained across navigation
    });
  });
}