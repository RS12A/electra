import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:electra_flutter/features/admin_dashboard/domain/entities/dashboard_stats.dart';
import 'package:electra_flutter/features/admin_dashboard/domain/entities/election.dart';
import 'package:electra_flutter/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:electra_flutter/features/admin_dashboard/domain/usecases/get_dashboard_stats.dart';
import 'package:electra_flutter/features/admin_dashboard/domain/usecases/create_election.dart';
import 'package:electra_flutter/core/error/failures.dart';

// Generate mock classes
@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_usecases_test.mocks.dart';

void main() {
  late GetDashboardStats getDashboardStats;
  late CreateElection createElection;
  late MockAdminRepository mockRepository;

  setUp(() {
    mockRepository = MockAdminRepository();
    getDashboardStats = GetDashboardStats(mockRepository);
    createElection = CreateElection(mockRepository);
  });

  group('GetDashboardStats', () {
    final tDashboardStats = DashboardStats(
      userStats: const UserStats(
        totalUsers: 100,
        activeUsers: 95,
        usersByRole: {'student': 80, 'staff': 15, 'admin': 5},
        newUsersToday: 3,
        newUsersThisWeek: 12,
      ),
      electionStats: const ElectionStats(
        totalElections: 5,
        electionsByStatus: {'active': 2, 'completed': 3},
        activeElections: 2,
        upcomingElections: 1,
        completedElections: 3,
      ),
      ballotTokenStats: const BallotTokenStats(
        totalTokens: 200,
        tokensByStatus: {'issued': 150, 'used': 45, 'expired': 5},
        tokensIssuedToday: 25,
        tokensUsedToday: 18,
        validTokens: 150,
        expiredTokens: 5,
      ),
      recentActivities: const [],
      alerts: const [],
    );

    test('should get dashboard stats from repository', () async {
      // arrange
      when(mockRepository.getDashboardStats())
          .thenAnswer((_) async => Right(tDashboardStats));

      // act
      final result = await getDashboardStats();

      // assert
      expect(result, Right(tDashboardStats));
      verify(mockRepository.getDashboardStats());
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Server error');
      when(mockRepository.getDashboardStats())
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await getDashboardStats();

      // assert
      expect(result, const Left(tFailure));
      verify(mockRepository.getDashboardStats());
      verifyNoMoreInteractions(mockRepository);
    });
  });

  group('CreateElection', () {
    final tElectionRequest = ElectionRequest(
      title: 'Test Election',
      description: 'Test election description',
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 25)),
    );

    final tElection = Election(
      id: 1,
      title: 'Test Election',
      description: 'Test election description',
      status: ElectionStatus.draft,
      startTime: DateTime.now().add(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 25)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdById: 1,
      createdByName: 'Admin User',
      createdByEmail: 'admin@kwasu.edu.ng',
      delayedReveal: false,
    );

    test('should create election when validation passes', () async {
      // arrange
      when(mockRepository.createElection(tElectionRequest))
          .thenAnswer((_) async => Right(tElection));

      // act
      final result = await createElection(tElectionRequest);

      // assert
      expect(result, Right(tElection));
      verify(mockRepository.createElection(tElectionRequest));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return validation failure for invalid election data', () async {
      // arrange
      final invalidRequest = ElectionRequest(
        title: '', // Invalid: empty title
        description: 'Test description',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 25)),
      );

      // act
      final result = await createElection(invalidRequest);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
      verifyNever(mockRepository.createElection(any));
    });

    test('should return validation failure when end time is before start time', () async {
      // arrange
      final invalidRequest = ElectionRequest(
        title: 'Test Election',
        description: 'Test description',
        startTime: DateTime.now().add(const Duration(hours: 25)),
        endTime: DateTime.now().add(const Duration(hours: 1)), // Invalid: end before start
      );

      // act
      final result = await createElection(invalidRequest);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });

    test('should return validation failure for election duration less than 1 hour', () async {
      // arrange
      final invalidRequest = ElectionRequest(
        title: 'Test Election',
        description: 'Test description',
        startTime: DateTime.now().add(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(minutes: 90)), // Invalid: less than 1 hour duration
      );

      // act
      final result = await createElection(invalidRequest);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected ValidationFailure'),
      );
    });
  });
}