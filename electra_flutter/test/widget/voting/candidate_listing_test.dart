import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:electra_flutter/features/voting/domain/entities/candidate.dart';
import 'package:electra_flutter/features/voting/domain/entities/election.dart';
import 'package:electra_flutter/features/voting/presentation/pages/candidate_listing_page.dart';
import 'package:electra_flutter/features/voting/presentation/widgets/candidate_card.dart';
import 'package:electra_flutter/features/voting/presentation/widgets/election_info_card.dart';

void main() {
  group('CandidateListingPage', () {
    late Widget testWidget;

    setUp(() {
      testWidget = ProviderScope(
        child: MaterialApp(
          home: CandidateListingPage(
            electionId: 'test-election-id',
            electionTitle: 'Test Election',
          ),
        ),
      );
    });

    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Candidates'), findsOneWidget);
      expect(find.text('Test Election'), findsOneWidget);
    });

    testWidgets('should display loading state initially', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading candidates...'), findsOneWidget);
    });

    testWidgets('should display refresh button in app bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('CandidateCard', () {
    const testCandidate = Candidate(
      id: 'candidate-1',
      name: 'John Doe',
      manifesto: 'Test manifesto for John Doe',
      position: 'President',
      photoUrl: 'https://example.com/photo.jpg',
    );

    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: CandidateCard(
            candidate: testCandidate,
            onTap: () {},
          ),
        ),
      );
    });

    testWidgets('should display candidate information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('President'), findsOneWidget);
      expect(find.text('Test manifesto for John Doe'), findsOneWidget);
    });

    testWidgets('should display vote button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Vote for this Candidate'), findsOneWidget);
      expect(find.byIcon(Icons.how_to_vote), findsOneWidget);
    });

    testWidgets('should display expand button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should expand when expand button is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);
      
      // Find and tap the expand button
      final expandButton = find.byIcon(Icons.expand_more);
      await tester.tap(expandButton);
      await tester.pump();

      // Assert
      expect(find.text('Manifesto'), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('should call onTap when vote button is pressed', (WidgetTester tester) async {
      // Arrange
      bool wasTapped = false;
      final widget = MaterialApp(
        home: Scaffold(
          body: CandidateCard(
            candidate: testCandidate,
            onTap: () => wasTapped = true,
          ),
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.tap(find.text('Vote for this Candidate'));

      // Assert
      expect(wasTapped, isTrue);
    });

    testWidgets('should have proper accessibility labels', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      final candidateCard = find.byType(CandidateCard);
      expect(candidateCard, findsOneWidget);
      
      final semantics = tester.getSemantics(candidateCard);
      expect(semantics.label, contains('Candidate: John Doe'));
      expect(semantics.label, contains('Position: President'));
    });
  });

  group('ElectionInfoCard', () {
    final testElection = Election(
      id: 'test-election-id',
      title: 'Test Election 2024',
      description: 'Annual student election',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1)),
      status: 'active',
    );

    late Widget testWidget;

    setUp(() {
      testWidget = MaterialApp(
        home: Scaffold(
          body: ElectionInfoCard(election: testElection),
        ),
      );
    });

    testWidgets('should display election information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Test Election 2024'), findsOneWidget);
      expect(find.text('Annual student election'), findsOneWidget);
    });

    testWidgets('should display election status', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('should display timing information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.text('Started'), findsOneWidget);
      expect(find.text('Ends'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsWidgets);
    });

    testWidgets('should display countdown for active election', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(testWidget);

      // Assert
      expect(find.byIcon(Icons.timer), findsOneWidget);
      // Should find text containing "remaining"
      expect(find.textContaining('remaining'), findsOneWidget);
    });

    testWidgets('should display different status for upcoming election', (WidgetTester tester) async {
      // Arrange
      final upcomingElection = Election(
        id: 'upcoming-election',
        title: 'Upcoming Election',
        description: 'Future election',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 2)),
        status: 'upcoming',
      );

      final widget = MaterialApp(
        home: Scaffold(
          body: ElectionInfoCard(election: upcomingElection),
        ),
      );

      // Act
      await tester.pumpWidget(widget);

      // Assert
      expect(find.text('UPCOMING'), findsOneWidget);
      expect(find.byIcon(Icons.upcoming), findsAtLeastNWidgets(1));
    });
  });
}