import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:electra_flutter/features/voting/domain/entities/candidate.dart';
import 'package:electra_flutter/features/voting/domain/entities/election.dart';
import 'package:electra_flutter/features/voting/domain/entities/vote.dart';
import 'package:electra_flutter/features/voting/domain/entities/ballot_token.dart';
import 'package:electra_flutter/features/voting/domain/repositories/voting_repository.dart';
import 'package:electra_flutter/features/voting/domain/usecases/get_candidates_usecase.dart';
import 'package:electra_flutter/features/voting/domain/usecases/cast_vote_usecase.dart';
import 'package:electra_flutter/features/voting/domain/usecases/verify_vote_usecase.dart';
import 'package:electra_flutter/features/voting/domain/usecases/queue_offline_vote_usecase.dart';
import 'package:electra_flutter/core/error/api_exception.dart';

@GenerateMocks([VotingRepository])
import 'voting_usecases_test.mocks.dart';

void main() {
  late MockVotingRepository mockRepository;
  late GetCandidatesUseCase getCandidatesUseCase;
  late CastVoteUseCase castVoteUseCase;
  late VerifyVoteUseCase verifyVoteUseCase;
  late QueueOfflineVoteUseCase queueOfflineVoteUseCase;

  setUp(() {
    mockRepository = MockVotingRepository();
    getCandidatesUseCase = GetCandidatesUseCase(mockRepository);
    castVoteUseCase = CastVoteUseCase(mockRepository);
    verifyVoteUseCase = VerifyVoteUseCase(mockRepository);
    queueOfflineVoteUseCase = QueueOfflineVoteUseCase(mockRepository);
  });

  group('GetCandidatesUseCase', () {
    const electionId = 'test-election-id';
    
    final testElection = Election(
      id: electionId,
      title: 'Test Election',
      description: 'Test Description',
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().add(const Duration(days: 1)),
      status: 'active',
    );

    final testCandidates = [
      const Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        manifesto: 'Test manifesto 1',
        position: 'President',
        photoUrl: 'https://example.com/photo1.jpg',
      ),
      const Candidate(
        id: 'candidate-2',
        name: 'Jane Smith',
        manifesto: 'Test manifesto 2',
        position: 'President',
      ),
    ];

    test('should get candidates and election info successfully', () async {
      // Arrange
      when(mockRepository.getCandidates(electionId))
          .thenAnswer((_) async => testCandidates);
      when(mockRepository.getElection(electionId))
          .thenAnswer((_) async => testElection);

      // Act
      final result = await getCandidatesUseCase(electionId);

      // Assert
      expect(result.candidates, equals(testCandidates));
      expect(result.election, equals(testElection));
      verify(mockRepository.getCandidates(electionId));
      verify(mockRepository.getElection(electionId));
    });

    test('should throw exception when repository fails', () async {
      // Arrange
      when(mockRepository.getCandidates(electionId))
          .thenThrow(const NetworkException());
      when(mockRepository.getElection(electionId))
          .thenAnswer((_) async => testElection);

      // Act & Assert
      expect(() => getCandidatesUseCase(electionId), throwsA(isA<NetworkException>()));
    });
  });

  group('CastVoteUseCase', () {
    final testBallotToken = BallotToken(
      tokenUuid: 'test-token-uuid',
      signature: 'test-signature',
      electionId: 'test-election-id',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    final testVote = Vote(
      voteToken: 'test-vote-token',
      electionId: 'test-election-id',
      candidateId: 'candidate-1',
      encryptedVoteData: 'encrypted-data',
      status: 'cast',
      submittedAt: DateTime.now(),
    );

    test('should cast vote successfully', () async {
      // Arrange
      final params = CastVoteParams(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      );

      when(mockRepository.validateBallotToken(testBallotToken))
          .thenAnswer((_) async => true);
      when(mockRepository.castVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      )).thenAnswer((_) async => testVote);

      // Act
      final result = await castVoteUseCase(params);

      // Assert
      expect(result, equals(testVote));
      verify(mockRepository.validateBallotToken(testBallotToken));
      verify(mockRepository.castVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      ));
    });

    test('should throw exception for invalid ballot token', () async {
      // Arrange
      final params = CastVoteParams(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      );

      when(mockRepository.validateBallotToken(testBallotToken))
          .thenAnswer((_) async => false);

      // Act & Assert
      expect(() => castVoteUseCase(params), throwsA(isA<Exception>()));
      verify(mockRepository.validateBallotToken(testBallotToken));
      verifyNever(mockRepository.castVote(
        ballotToken: anyNamed('ballotToken'),
        candidateId: anyNamed('candidateId'),
        electionId: anyNamed('electionId'),
      ));
    });

    test('should throw exception when vote casting fails', () async {
      // Arrange
      final params = CastVoteParams(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      );

      when(mockRepository.validateBallotToken(testBallotToken))
          .thenAnswer((_) async => true);
      when(mockRepository.castVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      )).thenThrow(const VoteCastingException());

      // Act & Assert
      expect(() => castVoteUseCase(params), throwsA(isA<VoteCastingException>()));
    });
  });

  group('VerifyVoteUseCase', () {
    final testVote = Vote(
      voteToken: 'test-vote-token',
      electionId: 'test-election-id',
      candidateId: '',
      encryptedVoteData: '',
      status: 'verified',
      submittedAt: DateTime.now(),
      isVerified: true,
      verifiedAt: DateTime.now(),
    );

    test('should verify vote successfully', () async {
      // Arrange
      final params = VerifyVoteParams(
        voteToken: 'test-vote-token',
        electionId: 'test-election-id',
      );

      when(mockRepository.verifyVote(
        voteToken: 'test-vote-token',
        electionId: 'test-election-id',
      )).thenAnswer((_) async => testVote);

      // Act
      final result = await verifyVoteUseCase(params);

      // Assert
      expect(result, equals(testVote));
      expect(result.isVerified, isTrue);
      verify(mockRepository.verifyVote(
        voteToken: 'test-vote-token',
        electionId: 'test-election-id',
      ));
    });

    test('should throw exception when verification fails', () async {
      // Arrange
      final params = VerifyVoteParams(
        voteToken: 'test-vote-token',
        electionId: 'test-election-id',
      );

      when(mockRepository.verifyVote(
        voteToken: 'test-vote-token',
        electionId: 'test-election-id',
      )).thenThrow(const NotFoundException());

      // Act & Assert
      expect(() => verifyVoteUseCase(params), throwsA(isA<NotFoundException>()));
    });
  });

  group('QueueOfflineVoteUseCase', () {
    final testBallotToken = BallotToken(
      tokenUuid: 'test-token-uuid',
      signature: 'test-signature',
      electionId: 'test-election-id',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    test('should queue offline vote successfully', () async {
      // Arrange
      final params = QueueOfflineVoteParams(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      );

      when(mockRepository.queueOfflineVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      )).thenAnswer((_) async => true);

      // Act
      final result = await queueOfflineVoteUseCase(params);

      // Assert
      expect(result, isTrue);
      verify(mockRepository.queueOfflineVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      ));
    });

    test('should return false when queueing fails', () async {
      // Arrange
      final params = QueueOfflineVoteParams(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      );

      when(mockRepository.queueOfflineVote(
        ballotToken: testBallotToken,
        candidateId: 'candidate-1',
        electionId: 'test-election-id',
      )).thenAnswer((_) async => false);

      // Act
      final result = await queueOfflineVoteUseCase(params);

      // Assert
      expect(result, isFalse);
    });

    test('should get queued votes successfully', () async {
      // Arrange
      final queuedVotes = [
        {'id': '1', 'candidate_id': 'candidate-1'},
        {'id': '2', 'candidate_id': 'candidate-2'},
      ];

      when(mockRepository.getQueuedOfflineVotes())
          .thenAnswer((_) async => queuedVotes);

      // Act
      final result = await queueOfflineVoteUseCase.getQueuedVotes();

      // Assert
      expect(result, equals(queuedVotes));
      verify(mockRepository.getQueuedOfflineVotes());
    });

    test('should submit queued votes successfully', () async {
      // Arrange
      when(mockRepository.submitQueuedOfflineVotes())
          .thenAnswer((_) async => 2);

      // Act
      final result = await queueOfflineVoteUseCase.submitQueuedVotes();

      // Assert
      expect(result, equals(2));
      verify(mockRepository.submitQueuedOfflineVotes());
    });

    test('should clear vote queue successfully', () async {
      // Arrange
      when(mockRepository.clearOfflineVoteQueue())
          .thenAnswer((_) async {});

      // Act
      await queueOfflineVoteUseCase.clearQueue();

      // Assert
      verify(mockRepository.clearOfflineVoteQueue());
    });
  });
}