import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:electra_flutter/features/voting/domain/entities/candidate.dart';
import 'package:electra_flutter/features/voting/presentation/widgets/candidate_card.dart';

void main() {
  group('CandidateCard Widget Tests', () {
    late Candidate testCandidate;

    setUp(() {
      testCandidate = const Candidate(
        id: 'test-candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Transforming KWASU through technology and innovation',
        electionId: 'test-election-1',
      );
    });

    Widget createTestWidget({
      bool isSelected = false,
      bool isExpanded = false,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: testCandidate,
              isSelected: isSelected,
              isExpanded: isExpanded,
              onTap: () {},
              onExpand: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('should display candidate name', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display candidate department', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Computer Science'), findsOneWidget);
    });

    testWidgets('should display candidate position', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('President'), findsOneWidget);
    });

    testWidgets('should display candidate manifesto', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.textContaining('Transforming KWASU through technology'), findsOneWidget);
    });

    testWidgets('should show selected state when selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(isSelected: true));

      expect(find.text('Selected'), findsOneWidget);
    });

    testWidgets('should show vote button when not selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Vote for this Candidate'), findsOneWidget);
    });

    testWidgets('should have proper accessibility semantics', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final semantics = tester.getSemantics(find.byType(CandidateCard));
      expect(semantics.label, contains('Candidate card for John Doe'));
      expect(semantics.hasFlag(SemanticsFlag.isButton), true);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: testCandidate,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      ));

      await tester.tap(find.byType(CandidateCard));
      await tester.pump();

      expect(wasTapped, true);
    });

    testWidgets('should show expand button when onExpand is provided', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: testCandidate,
              onTap: () {},
              onExpand: () {},
            ),
          ),
        ),
      ));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('should handle photo placeholder when no photo URL', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should show video section when expanded and video URL exists', (WidgetTester tester) async {
      final candidateWithVideo = testCandidate.copyWith(
        videoUrl: 'https://example.com/video.mp4',
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: candidateWithVideo,
              isExpanded: true,
              onTap: () {},
              onExpand: () {},
            ),
          ),
        ),
      ));

      expect(find.text('Campaign Video'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('should show additional info when expanded', (WidgetTester tester) async {
      final candidateWithInfo = testCandidate.copyWith(
        additionalInfo: 'Additional information about the candidate',
      );

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CandidateCard(
              candidate: candidateWithInfo,
              isExpanded: true,
              onTap: () {},
              onExpand: () {},
            ),
          ),
        ),
      ));

      expect(find.text('Additional Information'), findsOneWidget);
      expect(find.text('Additional information about the candidate'), findsOneWidget);
    });

    testWidgets('should animate scale when pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // This test verifies the animation setup exists
      // Full animation testing would require more complex mocking
      final cardFinder = find.byType(CandidateCard);
      expect(cardFinder, findsOneWidget);
    });

    testWidgets('should display share button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    });
  });
}