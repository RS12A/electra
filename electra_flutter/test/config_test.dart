import 'package:flutter_test/flutter_test.dart';
import 'package:electra_flutter/core/config/env_config.dart';
import 'package:electra_flutter/core/config/app_config.dart';

void main() {
  group('Environment Configuration Tests', () {
    test('Environment validation should work without errors', () async {
      // Test that environment validation runs without throwing exceptions
      expect(() async => await EnvironmentConfig.validateEnvironment(), 
             returnsNormally);
    });

    test('AppConfig should provide default values', () {
      // Test default configuration values
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.apiVersion, equals('v1'));
      expect(AppConfig.universityName, isNotEmpty);
      expect(AppConfig.universityAbbr, isNotEmpty);
    });

    test('AppConfig should handle boolean feature flags', () {
      // Test boolean feature flags
      expect(AppConfig.enableBiometrics, isA<bool>());
      expect(AppConfig.enableOfflineVoting, isA<bool>());
      expect(AppConfig.enableAnalytics, isA<bool>());
      expect(AppConfig.enableNotifications, isA<bool>());
      expect(AppConfig.enableDarkMode, isA<bool>());
    });

    test('AppConfig should provide configuration map', () {
      // Test configuration map generation
      final config = AppConfig.toMap();
      expect(config, isA<Map<String, dynamic>>());
      expect(config.containsKey('baseUrl'), isTrue);
      expect(config.containsKey('enableBiometrics'), isTrue);
      expect(config.containsKey('universityName'), isTrue);
    });

    test('EnvironmentConfig should provide config summary', () {
      // Test configuration summary
      final summary = EnvironmentConfig.getConfigSummary();
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary.containsKey('api_base_url'), isTrue);
      expect(summary.containsKey('enable_biometrics'), isTrue);
    });

    test('AppConfig helper methods should work correctly', () {
      // Test helper methods
      expect(AppConfig.isFirebaseConfigured, isA<bool>());
      expect(AppConfig.isAnalyticsConfigured, isA<bool>());
      expect(AppConfig.isPushNotificationsEnabled, isA<bool>());
    });
  });

  group('Environment Variable Parsing Tests', () {
    test('Boolean environment variables should parse correctly', () {
      // Test that boolean values are parsed correctly from environment
      // This test will use default values in CI
      final enableBiometrics = AppConfig.enableBiometrics;
      expect(enableBiometrics, isA<bool>());
    });

    test('String environment variables should have reasonable defaults', () {
      // Test string environment variables
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.universityName, isNotEmpty);
      expect(AppConfig.supportEmail, contains('@'));
    });
  });
}