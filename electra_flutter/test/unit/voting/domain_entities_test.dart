import 'package:flutter_test/flutter_test.dart';
import 'package:electra_flutter/features/voting/domain/entities/candidate.dart';
import 'package:electra_flutter/features/voting/domain/entities/election.dart';
import 'package:electra_flutter/features/voting/domain/entities/vote.dart';

void main() {
  group('Candidate Entity Tests', () {
    test('should create candidate with required fields', () {
      const candidate = Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Test manifesto',
        electionId: 'election-1',
      );

      expect(candidate.id, 'candidate-1');
      expect(candidate.name, 'John Doe');
      expect(candidate.department, 'Computer Science');
      expect(candidate.position, 'President');
      expect(candidate.manifesto, 'Test manifesto');
      expect(candidate.electionId, 'election-1');
      expect(candidate.isActive, true);
    });

    test('should create candidate with optional fields', () {
      const candidate = Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Test manifesto',
        photoUrl: 'https://example.com/photo.jpg',
        videoUrl: 'https://example.com/video.mp4',
        additionalInfo: 'Additional info',
        electionId: 'election-1',
        isActive: false,
      );

      expect(candidate.photoUrl, 'https://example.com/photo.jpg');
      expect(candidate.videoUrl, 'https://example.com/video.mp4');
      expect(candidate.additionalInfo, 'Additional info');
      expect(candidate.isActive, false);
    });

    test('should support copyWith', () {
      const original = Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Test manifesto',
        electionId: 'election-1',
      );

      final updated = original.copyWith(
        name: 'Jane Doe',
        department: 'Mass Communication',
      );

      expect(updated.id, 'candidate-1');
      expect(updated.name, 'Jane Doe');
      expect(updated.department, 'Mass Communication');
      expect(updated.position, 'President');
      expect(updated.manifesto, 'Test manifesto');
      expect(updated.electionId, 'election-1');
    });

    test('should support equality comparison', () {
      const candidate1 = Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Test manifesto',
        electionId: 'election-1',
      );

      const candidate2 = Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Test manifesto',
        electionId: 'election-1',
      );

      expect(candidate1, equals(candidate2));
      expect(candidate1.hashCode, equals(candidate2.hashCode));
    });
  });

  group('Election Entity Tests', () {
    test('should create election with required fields', () {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 7));

      final election = Election(
        id: 'election-1',
        title: 'Student Union Elections 2024',
        description: 'Annual elections',
        startDate: startDate,
        endDate: endDate,
        status: ElectionStatus.active,
        positions: ['President', 'Vice President'],
        totalVoters: 1000,
      );

      expect(election.id, 'election-1');
      expect(election.title, 'Student Union Elections 2024');
      expect(election.description, 'Annual elections');
      expect(election.startDate, startDate);
      expect(election.endDate, endDate);
      expect(election.status, ElectionStatus.active);
      expect(election.positions, ['President', 'Vice President']);
      expect(election.totalVoters, 1000);
      expect(election.votesCast, 0);
      expect(election.allowsAnonymousVoting, true);
      expect(election.isFeatured, false);
    });

    test('should calculate if election is active', () {
      final election = Election(
        id: 'election-1',
        title: 'Test Election',
        description: 'Test',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        status: ElectionStatus.active,
        positions: ['President'],
        totalVoters: 100,
      );

      expect(election.isActive, true);

      final inactiveElection = election.copyWith(status: ElectionStatus.ended);
      expect(inactiveElection.isActive, false);
    });

    test('should calculate if election has ended', () {
      final endedElection = Election(
        id: 'election-1',
        title: 'Test Election',
        description: 'Test',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        status: ElectionStatus.ended,
        positions: ['President'],
        totalVoters: 100,
      );

      expect(endedElection.hasEnded, true);

      final activeElection = endedElection.copyWith(status: ElectionStatus.active);
      expect(activeElection.hasEnded, false);
    });

    test('should calculate voting progress', () {
      final election = Election(
        id: 'election-1',
        title: 'Test Election',
        description: 'Test',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        status: ElectionStatus.active,
        positions: ['President'],
        totalVoters: 100,
        votesCast: 25,
      );

      expect(election.votingProgress, 25.0);

      final noVotesElection = election.copyWith(votesCast: 0, totalVoters: 0);
      expect(noVotesElection.votingProgress, 0.0);
    });

    test('should calculate time until start for scheduled election', () {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final election = Election(
        id: 'election-1',
        title: 'Test Election',
        description: 'Test',
        startDate: futureDate,
        endDate: futureDate.add(const Duration(days: 1)),
        status: ElectionStatus.scheduled,
        positions: ['President'],
        totalVoters: 100,
      );

      final timeUntilStart = election.timeUntilStart;
      expect(timeUntilStart, isNotNull);
      expect(timeUntilStart!.inHours, closeTo(2, 1));
    });

    test('should calculate time until end for active election', () {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(hours: 3));
      final election = Election(
        id: 'election-1',
        title: 'Test Election',
        description: 'Test',
        startDate: startDate,
        endDate: endDate,
        status: ElectionStatus.active,
        positions: ['President'],
        totalVoters: 100,
      );

      final timeUntilEnd = election.timeUntilEnd;
      expect(timeUntilEnd, isNotNull);
      expect(timeUntilEnd!.inHours, closeTo(3, 1));
    });
  });

  group('Vote Entity Tests', () {
    test('should create vote with required fields', () {
      final vote = Vote(
        id: 'vote-1',
        voteToken: 'token-123',
        electionId: 'election-1',
        encryptedSelections: {'president': 'candidate-1'},
        status: VoteStatus.verified,
        clientTimestamp: DateTime.now(),
        signature: 'signature-123',
        encryptionNonce: 'nonce-123',
        encryptionKeyHash: 'key-hash-123',
      );

      expect(vote.id, 'vote-1');
      expect(vote.voteToken, 'token-123');
      expect(vote.electionId, 'election-1');
      expect(vote.encryptedSelections, {'president': 'candidate-1'});
      expect(vote.status, VoteStatus.verified);
      expect(vote.signature, 'signature-123');
      expect(vote.encryptionNonce, 'nonce-123');
      expect(vote.encryptionKeyHash, 'key-hash-123');
    });

    test('should create vote confirmation', () {
      final confirmation = VoteConfirmation(
        confirmationId: 'conf-123',
        voteToken: 'token-123',
        electionTitle: 'Test Election',
        timestamp: DateTime.now(),
        positionsVoted: 2,
        totalPositions: 3,
      );

      expect(confirmation.confirmationId, 'conf-123');
      expect(confirmation.voteToken, 'token-123');
      expect(confirmation.electionTitle, 'Test Election');
      expect(confirmation.positionsVoted, 2);
      expect(confirmation.totalPositions, 3);
    });

    test('should create offline vote', () {
      final vote = Vote(
        id: 'vote-1',
        voteToken: 'token-123',
        electionId: 'election-1',
        encryptedSelections: {'president': 'candidate-1'},
        status: VoteStatus.pending,
        clientTimestamp: DateTime.now(),
        signature: 'signature-123',
        encryptionNonce: 'nonce-123',
        encryptionKeyHash: 'key-hash-123',
      );

      final offlineVote = OfflineVote(
        id: 'offline-1',
        vote: vote,
        queuedAt: DateTime.now(),
      );

      expect(offlineVote.id, 'offline-1');
      expect(offlineVote.vote, vote);
      expect(offlineVote.isSynced, false);
      expect(offlineVote.retryCount, 0);
    });

    test('should create vote selection', () {
      const selection = VoteSelection(
        positionId: 'president',
        candidateId: 'candidate-1',
        positionName: 'President',
        candidateName: 'John Doe',
      );

      expect(selection.positionId, 'president');
      expect(selection.candidateId, 'candidate-1');
      expect(selection.positionName, 'President');
      expect(selection.candidateName, 'John Doe');
    });
  });

  group('Vote Status Tests', () {
    test('should have correct vote status values', () {
      expect(VoteStatus.values.length, 5);
      expect(VoteStatus.draft, isA<VoteStatus>());
      expect(VoteStatus.pending, isA<VoteStatus>());
      expect(VoteStatus.verified, isA<VoteStatus>());
      expect(VoteStatus.rejected, isA<VoteStatus>());
      expect(VoteStatus.queued, isA<VoteStatus>());
    });
  });

  group('Election Status Tests', () {
    test('should have correct election status values', () {
      expect(ElectionStatus.values.length, 5);
      expect(ElectionStatus.scheduled, isA<ElectionStatus>());
      expect(ElectionStatus.active, isA<ElectionStatus>());
      expect(ElectionStatus.ended, isA<ElectionStatus>());
      expect(ElectionStatus.completed, isA<ElectionStatus>());
      expect(ElectionStatus.cancelled, isA<ElectionStatus>());
    });
  });
}