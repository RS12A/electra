/// Unit tests for authentication use cases
/// 
/// This file tests the authentication use cases to ensure they work correctly
/// with proper error handling and validation.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:electra_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:electra_flutter/features/auth/domain/usecases/login_usecase.dart';
import 'package:electra_flutter/features/auth/domain/usecases/register_usecase.dart';
import 'package:electra_flutter/features/auth/domain/usecases/password_recovery_usecase.dart';
import 'package:electra_flutter/features/auth/domain/usecases/biometric_auth_usecase.dart';
import 'package:electra_flutter/features/auth/domain/entities/user.dart';
import 'package:electra_flutter/core/error/app_exception.dart';

import 'auth_usecases_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUseCase(mockRepository);
    });

    group('call', () {
      const tParams = LoginParams(
        identifier: 'test@kwasu.edu.ng',
        password: 'password123',
        rememberMe: true,
      );

      final tUser = User(
        id: '1',
        email: 'test@kwasu.edu.ng',
        fullName: 'Test User',
        role: 'student',
        matricNumber: 'CSC12345',
      );

      final tAuthResponse = AuthResponse(
        user: tUser,
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      test('should return AuthResponse when login is successful', () async {
        // arrange
        when(mockRepository.validateLoginCredentials(any, any)).thenReturn(true);
        when(mockRepository.login(any)).thenAnswer((_) async => tAuthResponse);
        when(mockRepository.storeAuthData(any)).thenAnswer((_) async {});

        // act
        final result = await useCase(tParams);

        // assert
        expect(result, equals(tAuthResponse));
        verify(mockRepository.validateLoginCredentials(tParams.identifier, tParams.password));
        verify(mockRepository.login(tParams));
        verify(mockRepository.storeAuthData(tAuthResponse));
      });

      test('should throw ValidationException when credentials are invalid', () async {
        // arrange
        when(mockRepository.validateLoginCredentials(any, any)).thenReturn(false);

        // act & assert
        expect(
          () async => await useCase(tParams),
          throwsA(isA<ValidationException>()),
        );
        verify(mockRepository.validateLoginCredentials(tParams.identifier, tParams.password));
        verifyNever(mockRepository.login(any));
      });

      test('should not store auth data when remember me is false', () async {
        // arrange
        const tParamsNoRemember = LoginParams(
          identifier: 'test@kwasu.edu.ng',
          password: 'password123',
          rememberMe: false,
        );
        when(mockRepository.validateLoginCredentials(any, any)).thenReturn(true);
        when(mockRepository.login(any)).thenAnswer((_) async => tAuthResponse);

        // act
        await useCase(tParamsNoRemember);

        // assert
        verify(mockRepository.login(tParamsNoRemember));
        verifyNever(mockRepository.storeAuthData(any));
      });
    });

    group('loginWithBiometrics', () {
      test('should return true when biometric login is successful', () async {
        // arrange
        when(mockRepository.isBiometricEnabled()).thenAnswer((_) async => true);
        when(mockRepository.isBiometricAvailable()).thenAnswer((_) async => true);
        when(mockRepository.authenticateWithBiometrics()).thenAnswer((_) async => true);

        // act
        final result = await useCase.loginWithBiometrics();

        // assert
        expect(result, true);
        verify(mockRepository.isBiometricEnabled());
        verify(mockRepository.isBiometricAvailable());
        verify(mockRepository.authenticateWithBiometrics());
      });

      test('should throw BiometricException when biometric is not enabled', () async {
        // arrange
        when(mockRepository.isBiometricEnabled()).thenAnswer((_) async => false);

        // act & assert
        expect(
          () async => await useCase.loginWithBiometrics(),
          throwsA(isA<BiometricException>()),
        );
        verify(mockRepository.isBiometricEnabled());
        verifyNever(mockRepository.isBiometricAvailable());
        verifyNever(mockRepository.authenticateWithBiometrics());
      });

      test('should throw BiometricException when biometric is not available', () async {
        // arrange
        when(mockRepository.isBiometricEnabled()).thenAnswer((_) async => true);
        when(mockRepository.isBiometricAvailable()).thenAnswer((_) async => false);

        // act & assert
        expect(
          () async => await useCase.loginWithBiometrics(),
          throwsA(isA<BiometricException>()),
        );
        verify(mockRepository.isBiometricEnabled());
        verify(mockRepository.isBiometricAvailable());
        verifyNever(mockRepository.authenticateWithBiometrics());
      });
    });

    group('canAutoLogin', () {
      test('should return true when user has stored credentials', () async {
        // arrange
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => true);

        // act
        final result = await useCase.canAutoLogin();

        // assert
        expect(result, true);
        verify(mockRepository.isAuthenticated());
      });

      test('should return false when user has no stored credentials', () async {
        // arrange
        when(mockRepository.isAuthenticated()).thenAnswer((_) async => false);

        // act
        final result = await useCase.canAutoLogin();

        // assert
        expect(result, false);
        verify(mockRepository.isAuthenticated());
      });
    });
  });

  group('PasswordRecoveryUseCase', () {
    late PasswordRecoveryUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = PasswordRecoveryUseCase(mockRepository);
    });

    group('requestPasswordRecovery', () {
      test('should complete successfully for valid email', () async {
        // arrange
        const tEmail = 'test@kwasu.edu.ng';
        when(mockRepository.requestPasswordRecovery(any)).thenAnswer((_) async {});

        // act
        await useCase.requestPasswordRecovery(tEmail);

        // assert
        verify(mockRepository.requestPasswordRecovery(any));
      });

      test('should throw ValidationException for invalid email', () async {
        // act & assert
        expect(
          () async => await useCase.requestPasswordRecovery('invalid-email'),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.requestPasswordRecovery(any));
      });

      test('should throw ValidationException for non-university email', () async {
        // act & assert
        expect(
          () async => await useCase.requestPasswordRecovery('test@gmail.com'),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.requestPasswordRecovery(any));
      });
    });

    group('resetPassword', () {
      test('should complete successfully with valid data', () async {
        // arrange
        when(mockRepository.resetPassword(any)).thenAnswer((_) async {});

        // act
        await useCase.resetPassword(
          email: 'test@kwasu.edu.ng',
          otpCode: '123456',
          newPassword: 'NewPassword123!',
          newPasswordConfirm: 'NewPassword123!',
        );

        // assert
        verify(mockRepository.resetPassword(any));
      });

      test('should throw ValidationException for invalid OTP', () async {
        // act & assert
        expect(
          () async => await useCase.resetPassword(
            email: 'test@kwasu.edu.ng',
            otpCode: '12345', // Invalid length
            newPassword: 'NewPassword123!',
            newPasswordConfirm: 'NewPassword123!',
          ),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.resetPassword(any));
      });

      test('should throw ValidationException for password mismatch', () async {
        // act & assert
        expect(
          () async => await useCase.resetPassword(
            email: 'test@kwasu.edu.ng',
            otpCode: '123456',
            newPassword: 'NewPassword123!',
            newPasswordConfirm: 'DifferentPassword123!',
          ),
          throwsA(isA<ValidationException>()),
        );
        verifyNever(mockRepository.resetPassword(any));
      });
    });

    group('getPasswordStrength', () {
      test('should return correct strength for strong password', () {
        // act
        final result = useCase.getPasswordStrength('StrongPassword123!');

        // assert
        expect(result['hasMinLength'], true);
        expect(result['hasUppercase'], true);
        expect(result['hasLowercase'], true);
        expect(result['hasNumber'], true);
        expect(result['hasSpecialChar'], true);
      });

      test('should return correct strength for weak password', () {
        // act
        final result = useCase.getPasswordStrength('weak');

        // assert
        expect(result['hasMinLength'], false);
        expect(result['hasUppercase'], false);
        expect(result['hasLowercase'], true);
        expect(result['hasNumber'], false);
        expect(result['hasSpecialChar'], false);
      });
    });

    group('calculatePasswordStrengthScore', () {
      test('should return 5 for strong password', () {
        // act
        final result = useCase.calculatePasswordStrengthScore('StrongPassword123!');

        // assert
        expect(result, 5);
      });

      test('should return 1 for weak password', () {
        // act
        final result = useCase.calculatePasswordStrengthScore('weak');

        // assert
        expect(result, 1);
      });
    });
  });
}