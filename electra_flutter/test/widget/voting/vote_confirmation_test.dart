import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:electra_flutter/features/voting/domain/entities/candidate.dart';
import 'package:electra_flutter/features/voting/domain/entities/vote.dart';
import 'package:electra_flutter/features/voting/presentation/pages/vote_confirmation_page.dart';

void main() {
  group('VoteConfirmationPage', () {
    const testCandidate = Candidate(
      id: 'candidate-1',
      name: 'John Doe',
      manifesto: 'Test manifesto',
      position: 'President',
    );

    final testVote = Vote(
      voteToken: 'test-vote-token-123',
      electionId: 'test-election-id',
      candidateId: 'candidate-1',
      encryptedVoteData: 'encrypted-data',
      status: 'cast',
      submittedAt: DateTime.now(),
    );

    late Widget testWidget;

    setUp(() {
      testWidget = ProviderScope(
        child: MaterialApp(
          home: VoteConfirmationPage(
            candidate: testCandidate,
            vote: testVote,
            electionTitle: 'Test Election',
          ),
        ),
      );
    });

    testWidgets('should display success animation', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);
      await tester.pump(const Duration(milliseconds: 100));

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display success message', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Vote Cast Successfully!'), findsOneWidget);
      expect(find.textContaining('securely recorded'), findsOneWidget);
    });

    testWidgets('should display vote summary', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Vote Summary'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('President'), findsOneWidget);
      expect(find.text('Test Election'), findsOneWidget);
    });

    testWidgets('should display vote token', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Anonymous Vote Token'), findsOneWidget);
      expect(find.text('test-vote-token-123'), findsOneWidget);
      expect(find.text('Copy Token'), findsOneWidget);
    });

    testWidgets('should display return to dashboard button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Return to Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.dashboard), findsOneWidget);
    });

    testWidgets('should display verify vote button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Verify My Vote'), findsOneWidget);
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should copy vote token when copy button is pressed', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);
      await tester.tap(find.text('Copy Token'));
      await tester.pump();

      // Assert
      expect(find.text('Copied!'), findsOneWidget);
    });

    testWidgets('should display offline vote message when offline', (WidgetTester tester) async {
      // Arrange
      final offlineWidget = ProviderScope(
        child: MaterialApp(
          home: VoteConfirmationPage(
            candidate: testCandidate,
            vote: testVote,
            electionTitle: 'Test Election',
            isOfflineVote: true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(offlineWidget);

      // Assert
      expect(find.text('Vote Queued Successfully!'), findsOneWidget);
      expect(find.text('Offline Vote Queued'), findsOneWidget);
      expect(find.byIcon(Icons.offline_bolt), findsAtLeastNWidgets(1));
    });

    testWidgets('should not display verify button for offline votes', (WidgetTester tester) async {
      // Arrange
      final offlineWidget = ProviderScope(
        child: MaterialApp(
          home: VoteConfirmationPage(
            candidate: testCandidate,
            vote: testVote,
            electionTitle: 'Test Election',
            isOfflineVote: true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(offlineWidget);

      // Assert
      expect(find.text('Verify My Vote'), findsNothing);
    });

    testWidgets('should prevent back navigation', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Try to go back (should not work)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        null,
        (data) {},
      );
      await tester.pump();

      // Assert - page should still be showing
      expect(find.text('Vote Cast Successfully!'), findsOneWidget);
    });

    testWidgets('should display thank you message', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Thank You for Participating!'), findsOneWidget);
      expect(find.textContaining('democratic process'), findsOneWidget);
    });

    testWidgets('should have proper accessibility support', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.bySemanticsLabel('Vote Confirmed'), findsOneWidget);
      expect(find.bySemanticsLabel('Return to Dashboard'), findsOneWidget);
      expect(find.bySemanticsLabel('Verify My Vote'), findsOneWidget);
    });
  });
}