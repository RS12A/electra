import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:electra_flutter/features/auth/domain/entities/user.dart';
import 'package:electra_flutter/features/auth/domain/entities/auth_entities.dart';
import 'package:electra_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:electra_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:electra_flutter/core/error/app_exception.dart';

import 'login_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  group('LoginUseCase', () {
    const tCredentials = LoginCredentials(
      identifier: 'test@kwasu.edu.ng',
      password: 'password123',
      rememberMe: false,
    );

    const tCredentialsWithRememberMe = LoginCredentials(
      identifier: 'test@kwasu.edu.ng',
      password: 'password123',
      rememberMe: true,
    );

    final tUser = User(
      id: '1',
      email: 'test@kwasu.edu.ng',
      fullName: 'Test User',
      role: UserRole.student,
      matricNumber: 'STU12345',
      isEmailVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final tAuthResponse = AuthResponse(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      user: tUser,
      expiresIn: 900,
    );

    group('login', () {
      test('should return AuthResponse when login is successful', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.login(any))
            .thenAnswer((_) async => Right(tAuthResponse));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isEmail(any)).thenReturn(true);

        // act
        final result = await useCase(tCredentials);

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.login(tCredentials));
        verifyNever(mockRepository.storeAuthData(any));
      });

      test('should store auth data when remember me is enabled', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.login(any))
            .thenAnswer((_) async => Right(tAuthResponse));
        when(mockRepository.storeAuthData(any))
            .thenAnswer((_) async => const Right(null));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isEmail(any)).thenReturn(true);

        // act
        final result = await useCase(tCredentialsWithRememberMe);

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.login(tCredentialsWithRememberMe));
        verify(mockRepository.storeAuthData(tAuthResponse));
      });

      test('should return ValidationException when identifier is empty', () async {
        // arrange
        const invalidCredentials = LoginCredentials(
          identifier: '',
          password: 'password123',
        );

        // act
        final result = await useCase(invalidCredentials);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.login(any));
      });

      test('should return ValidationException when password is empty', () async {
        // arrange
        const invalidCredentials = LoginCredentials(
          identifier: 'test@kwasu.edu.ng',
          password: '',
        );

        // act
        final result = await useCase(invalidCredentials);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.login(any));
      });

      test('should return ValidationException when email format is invalid', () async {
        // arrange
        const invalidCredentials = LoginCredentials(
          identifier: 'invalid-email',
          password: 'password123',
        );
        when(mockRepository.isEmail(any)).thenReturn(true);
        when(mockRepository.isValidEmail(any)).thenReturn(false);

        // act
        final result = await useCase(invalidCredentials);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<ValidationException>()),
          (authResponse) => fail('Should return ValidationException'),
        );
        verifyNever(mockRepository.login(any));
      });

      test('should attempt offline login when no network connection', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(false));
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => Right(tAuthResponse));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isEmail(any)).thenReturn(true);

        // act
        final result = await useCase(tCredentials);

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.getStoredAuthData());
        verifyNever(mockRepository.login(any));
      });

      test('should return NetworkException when offline and no stored credentials', () async {
        // arrange
        when(mockRepository.hasNetworkConnection())
            .thenAnswer((_) async => const Right(false));
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => const Right(null));
        when(mockRepository.isValidEmail(any)).thenReturn(true);
        when(mockRepository.isEmail(any)).thenReturn(true);

        // act
        final result = await useCase(tCredentials);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<NetworkException>()),
          (authResponse) => fail('Should return NetworkException'),
        );
      });
    });

    group('loginWithBiometrics', () {
      test('should return AuthResponse when biometric login is successful', () async {
        // arrange
        when(mockRepository.isBiometricAvailable())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.isBiometricEnabled())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.loginWithBiometrics())
            .thenAnswer((_) async => Right(tAuthResponse));

        // act
        final result = await useCase.loginWithBiometrics();

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.isBiometricAvailable());
        verify(mockRepository.isBiometricEnabled());
        verify(mockRepository.loginWithBiometrics());
      });

      test('should return BiometricException when biometric is not available', () async {
        // arrange
        when(mockRepository.isBiometricAvailable())
            .thenAnswer((_) async => const Right(false));

        // act
        final result = await useCase.loginWithBiometrics();

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<BiometricException>()),
          (authResponse) => fail('Should return BiometricException'),
        );
        verify(mockRepository.isBiometricAvailable());
        verifyNever(mockRepository.isBiometricEnabled());
        verifyNever(mockRepository.loginWithBiometrics());
      });

      test('should return BiometricException when biometric is not enabled', () async {
        // arrange
        when(mockRepository.isBiometricAvailable())
            .thenAnswer((_) async => const Right(true));
        when(mockRepository.isBiometricEnabled())
            .thenAnswer((_) async => const Right(false));

        // act
        final result = await useCase.loginWithBiometrics();

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<BiometricException>()),
          (authResponse) => fail('Should return BiometricException'),
        );
        verify(mockRepository.isBiometricAvailable());
        verify(mockRepository.isBiometricEnabled());
        verifyNever(mockRepository.loginWithBiometrics());
      });
    });

    group('canAutoLogin', () {
      test('should return true when user has valid stored credentials', () async {
        // arrange
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => Right(tAuthResponse));

        // act
        final result = await useCase.canAutoLogin();

        // assert
        expect(result, const Right(true));
        verify(mockRepository.getStoredAuthData());
      });

      test('should return false when no stored credentials exist', () async {
        // arrange
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => const Right(null));

        // act
        final result = await useCase.canAutoLogin();

        // assert
        expect(result, const Right(false));
        verify(mockRepository.getStoredAuthData());
      });

      test('should return false when stored credentials are expired', () async {
        // arrange
        final expiredAuthResponse = AuthResponse(
          accessToken: 'expired_token',
          refreshToken: 'refresh_token',
          user: tUser,
          expiresIn: -1, // Expired
        );
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => Right(expiredAuthResponse));

        // act
        final result = await useCase.canAutoLogin();

        // assert
        expect(result, const Right(false));
        verify(mockRepository.getStoredAuthData());
      });
    });

    group('autoLogin', () {
      test('should return stored AuthResponse when valid credentials exist', () async {
        // arrange
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => Right(tAuthResponse));

        // act
        final result = await useCase.autoLogin();

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.getStoredAuthData());
        verifyNever(mockRepository.refreshToken(any));
      });

      test('should attempt token refresh when stored token is expired', () async {
        // arrange
        final expiredAuthResponse = AuthResponse(
          accessToken: 'expired_token',
          refreshToken: 'refresh_token',
          user: tUser,
          expiresIn: -1, // Expired
        );
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => Right(expiredAuthResponse));
        when(mockRepository.refreshToken(any))
            .thenAnswer((_) async => Right(tAuthResponse));

        // act
        final result = await useCase.autoLogin();

        // assert
        expect(result, Right(tAuthResponse));
        verify(mockRepository.getStoredAuthData());
        verify(mockRepository.refreshToken('refresh_token'));
      });

      test('should return exception when no stored credentials exist', () async {
        // arrange
        when(mockRepository.getStoredAuthData())
            .thenAnswer((_) async => const Right(null));

        // act
        final result = await useCase.autoLogin();

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (error) => expect(error, isA<AuthException>()),
          (authResponse) => fail('Should return AuthException'),
        );
        verify(mockRepository.getStoredAuthData());
      });
    });
  });
}