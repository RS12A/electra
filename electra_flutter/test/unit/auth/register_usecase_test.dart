import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:electra_flutter/features/auth/domain/entities/user.dart';
import 'package:electra_flutter/features/auth/domain/entities/auth_entities.dart';
import 'package:electra_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:electra_flutter/features/auth/domain/usecases/register_usecase.dart';
import 'package:electra_flutter/core/error/app_exception.dart';

import 'register_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late RegisterUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = RegisterUseCase(mockRepository);
  });

  group('RegisterUseCase', () {
    const tRegistrationData = RegistrationData(
      email: 'test@kwasu.edu.ng',
      password: 'Password123',
      fullName: 'Test Student',
      role: UserRole.student,
      matricNumber: 'STU12345',
    );

    final tUser = User(
      id: '1',
      email: 'test@kwasu.edu.ng',
      fullName: 'Test Student',
      role: UserRole.student,
      matricNumber: 'STU12345',
      isEmailVerified: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tAuthResponse = AuthResponse(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      user: tUser,
      expiresIn: 900,
    );

    group('register', () {
      test('should return AuthResponse when registration is successful', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.register(any))
            .thenAnswer((_) async => Right(tAuthResponse));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);
        when(mockRepository.isValidMatricNumber(any)).thenReturn(true);

        // act
        final result = await useCase(tRegistrationData);

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.register(tRegistrationData));
      });

      test('should return NetworkException when no network connection', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(false));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);
        when(mockRepository.isValidMatricNumber(any)).thenReturn(true);

        // act
        final result = await useCase(tRegistrationData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<NetworkException>()),
          (authResponse) => fail('Should return NetworkException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for invalid email', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'invalid-email',
          password: 'Password123',
          fullName: 'Test Student',
          role: UserRole.student,
          matricNumber: 'STU12345',
        );
        when(mockRepository.isValidEmail(any)).thenReturn(false);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for weak password', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: '123', // Weak password
          fullName: 'Test Student',
          role: UserRole.student,
          matricNumber: 'STU12345',
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(false);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for empty full name', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: 'Password123',
          fullName: '', // Empty name
          role: UserRole.student,
          matricNumber: 'STU12345',
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for student without matric number', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: 'Password123',
          fullName: 'Test Student',
          role: UserRole.student,
          matricNumber: null, // Missing matric number
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for invalid matric number format', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: 'Password123',
          fullName: 'Test Student',
          role: UserRole.student,
          matricNumber: 'INVALID', // Invalid format
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);
        when(mockRepository.isValidMatricNumber(any)).thenReturn(false);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for staff without staff ID', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: 'Password123',
          fullName: 'Test Staff',
          role: UserRole.staff,
          staffId: null, // Missing staff ID
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });

      test('should return ValidationException for invalid staff ID', () async {
        // arrange
        const invalidData = RegistrationData(
          email: 'test@kwasu.edu.ng',
          password: 'Password123',
          fullName: 'Test Staff',
          role: UserRole.staff,
          staffId: 'ABC', // Too short
        );
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isValidPassword(any)).thenReturn(true);
        when(mockRepository.isValidStaffId(any)).thenReturn(false);

        // act
        final result = await useCase(invalidData);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.register(any));
      });
    });

    group('isEmailAvailable', () {
      test('should return true for available email', () async {
        // arrange
        const email = 'available@kwasu.edu.ng';
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));

        // act
        final result = await useCase.isEmailAvailable(email);

        // assert
        expect(result, const Right(true));
      });

      test('should return ValidationException for invalid email', () async {
        // arrange
        const email = 'invalid-email';
        when(mockRepository.isValidEmail(any)).thenReturn(false);

        // act
        final result = await useCase.isEmailAvailable(email);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (available) => fail('Should return ValidationException'),
        );
      });

      test('should return NetworkException when no connection', () async {
        // arrange
        const email = 'test@kwasu.edu.ng';
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(false));

        // act
        final result = await useCase.isEmailAvailable(email);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<NetworkException>()),
          (available) => fail('Should return NetworkException'),
        );
      });
    });

    group('isMatricNumberAvailable', () {
      test('should return true for available matric number', () async {
        // arrange
        const matricNumber = 'STU99999';
        when(mockRepository.isValidMatricNumber(any)).thenReturn(true);
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));

        // act
        final result = await useCase.isMatricNumberAvailable(matricNumber);

        // assert
        expect(result, const Right(true));
      });

      test('should return ValidationException for invalid matric number', () async {
        // arrange
        const matricNumber = 'INVALID';
        when(mockRepository.isValidMatricNumber(any)).thenReturn(false);

        // act
        final result = await useCase.isMatricNumberAvailable(matricNumber);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (available) => fail('Should return ValidationException'),
        );
      });
    });

    group('isStaffIdAvailable', () {
      test('should return true for available staff ID', () async {
        // arrange
        const staffId = 'STAFF999';
        when(mockRepository.isValidStaffId(any)).thenReturn(true);
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));

        // act
        final result = await useCase.isStaffIdAvailable(staffId);

        // assert
        expect(result, const Right(true));
      });

      test('should return ValidationException for invalid staff ID', () async {
        // arrange
        const staffId = 'ABC';
        when(mockRepository.isValidStaffId(any)).thenReturn(false);

        // act
        final result = await useCase.isStaffIdAvailable(staffId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (available) => fail('Should return ValidationException'),
        );
      });
    });

    group('getAvailableRoles', () {
      test('should return list of available roles', () {
        // act
        final roles = useCase.getAvailableRoles();

        // assert
        expect(roles, contains(UserRole.student));
        expect(roles, contains(UserRole.staff));
        expect(roles.length, equals(2));
      });
    });
  });
}