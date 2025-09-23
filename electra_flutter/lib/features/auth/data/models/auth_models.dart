import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_entities.dart';
import 'user_model.dart';

part 'auth_models.g.dart';

/// Authentication response model for API serialization
@JsonSerializable()
class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required String accessToken,
    required String refreshToken,
    required UserModel user,
    required int expiresIn,
    String tokenType = 'Bearer',
  }) : super(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
          expiresIn: expiresIn,
          tokenType: tokenType,
        );

  /// Create from JSON response
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      expiresIn: json['expires_in'] as int? ?? 900, // Default 15 minutes
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': (user as UserModel).toJson(),
      'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }

  /// Convert to domain entity
  @override
  AuthResponse toEntity() {
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: (user as UserModel).toEntity(),
      expiresIn: expiresIn,
      tokenType: tokenType,
    );
  }
}

/// Login request model
@JsonSerializable()
class LoginRequestModel {
  final String identifier;
  final String password;

  const LoginRequestModel({
    required this.identifier,
    required this.password,
  });

  factory LoginRequestModel.fromCredentials(LoginCredentials credentials) {
    return LoginRequestModel(
      identifier: credentials.identifier,
      password: credentials.password,
    );
  }

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);
}

/// Registration request model
@JsonSerializable()
class RegistrationRequestModel {
  final String email;
  final String password;
  @JsonKey(name: 'password_confirm')
  final String passwordConfirm;
  @JsonKey(name: 'full_name')
  final String fullName;
  final String role;
  @JsonKey(name: 'matric_number')
  final String? matricNumber;
  @JsonKey(name: 'staff_id')
  final String? staffId;

  const RegistrationRequestModel({
    required this.email,
    required this.password,
    required this.passwordConfirm,
    required this.fullName,
    required this.role,
    this.matricNumber,
    this.staffId,
  });

  factory RegistrationRequestModel.fromData(RegistrationData data) {
    return RegistrationRequestModel(
      email: data.email,
      password: data.password,
      passwordConfirm: data.password,
      fullName: data.fullName,
      role: data.role.toApiString(),
      matricNumber: data.matricNumber,
      staffId: data.staffId,
    );
  }

  factory RegistrationRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RegistrationRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$RegistrationRequestModelToJson(this);
}

/// Password reset request model
@JsonSerializable()
class PasswordResetRequestModel {
  final String email;

  const PasswordResetRequestModel({required this.email});

  factory PasswordResetRequestModel.fromRequest(PasswordResetRequest request) {
    return PasswordResetRequestModel(email: request.email);
  }

  factory PasswordResetRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$PasswordResetRequestModelToJson(this);
}

/// OTP verification model
@JsonSerializable()
class OtpVerificationModel {
  final String email;
  @JsonKey(name: 'otp_code')
  final String otpCode;
  @JsonKey(name: 'new_password')
  final String? newPassword;
  @JsonKey(name: 'new_password_confirm')
  final String? newPasswordConfirm;

  const OtpVerificationModel({
    required this.email,
    required this.otpCode,
    this.newPassword,
    this.newPasswordConfirm,
  });

  factory OtpVerificationModel.fromVerification(OtpVerification verification) {
    return OtpVerificationModel(
      email: verification.email,
      otpCode: verification.otpCode,
      newPassword: verification.newPassword,
      newPasswordConfirm: verification.newPassword,
    );
  }

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) =>
      _$OtpVerificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$OtpVerificationModelToJson(this);
}

/// Token refresh request model
@JsonSerializable()
class TokenRefreshModel {
  final String refresh;

  const TokenRefreshModel({required this.refresh});

  factory TokenRefreshModel.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenRefreshModelToJson(this);
}

/// Error response model
@JsonSerializable()
class ErrorResponseModel {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;
  final List<String>? errors;

  const ErrorResponseModel({
    required this.message,
    this.code,
    this.details,
    this.errors,
  });

  factory ErrorResponseModel.fromJson(Map<String, dynamic> json) {
    return ErrorResponseModel(
      message: json['message'] as String? ??
          json['detail'] as String? ??
          json['error'] as String? ??
          'An unknown error occurred',
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => _$ErrorResponseModelToJson(this);
}

/// API response wrapper model
@JsonSerializable(genericArgumentFactories: true)
class ApiResponseModel<T> {
  final bool success;
  final T? data;
  final String? message;
  final ErrorResponseModel? error;

  const ApiResponseModel({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponseModel.success(T data, [String? message]) {
    return ApiResponseModel(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponseModel.error(ErrorResponseModel error) {
    return ApiResponseModel(
      success: false,
      error: error,
    );
  }

  factory ApiResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponseModel(
      success: json['success'] as bool? ?? true,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] as String?,
      error: json['error'] != null
          ? ErrorResponseModel.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'success': success,
      if (data != null) 'data': toJsonT(data as T),
      if (message != null) 'message': message,
      if (error != null) 'error': error!.toJson(),
    };
  }
}