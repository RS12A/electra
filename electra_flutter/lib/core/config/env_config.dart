/// Environment configuration and validation for Flutter app
/// 
/// This class validates all required environment configurations
/// and provides runtime validation for production readiness.
class EnvironmentConfig {
  // Private constructor
  EnvironmentConfig._();

  static const _productionMarkers = [
    'your_KEY_goes_here',
    'your_server_url_goes_here',
    'localhost',
    '127.0.0.1',
  ];

  /// Validate all environment configurations
  static Future<bool> validateEnvironment() async {
    print('🔍 Validating Flutter environment configuration...');
    
    final errors = <String>[];
    final warnings = <String>[];

    // API Configuration
    _validateApiConfig(errors, warnings);
    
    // Firebase Configuration
    _validateFirebaseConfig(errors, warnings);
    
    // Analytics Configuration
    _validateAnalyticsConfig(errors, warnings);
    
    // Feature Flags
    _validateFeatureFlags(errors, warnings);

    // Print results
    if (errors.isNotEmpty) {
      print('\n❌ Flutter Environment Validation Errors:');
      for (final error in errors) {
        print('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      print('\n⚠️  Flutter Environment Validation Warnings:');
      for (final warning in warnings) {
        print('  - $warning');
      }
    }

    if (errors.isEmpty && warnings.isEmpty) {
      print('✅ All Flutter environment variables are properly configured!');
    } else if (errors.isEmpty) {
      print('✅ Required Flutter environment variables are configured (with warnings)');
    }

    if (errors.isNotEmpty) {
      print('\n💡 Update your environment configuration before deploying.');
      print('   See README.md for configuration instructions.');
      return false;
    }

    return true;
  }

  static void _validateApiConfig(List<String> errors, List<String> warnings) {
    // Check base URL configuration
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL', 
      defaultValue: 'http://your_server_url_goes_here:8000'
    );
    
    if (_isProductionMarker(baseUrl)) {
      errors.add('API_BASE_URL must be set to your production server URL');
    } else if (baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1')) {
      warnings.add('API_BASE_URL is set to localhost - ensure this is correct for your environment');
    }

    // Check WebSocket URL
    const wsUrl = String.fromEnvironment(
      'WS_BASE_URL', 
      defaultValue: 'wss://your_server_url_goes_here:8000'
    );
    
    if (_isProductionMarker(wsUrl)) {
      warnings.add('WS_BASE_URL not configured - real-time features may not work');
    }
  }

  static void _validateFirebaseConfig(List<String> errors, List<String> warnings) {
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
    const appId = String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');
    const fcmSenderId = String.fromEnvironment('FCM_SENDER_ID', defaultValue: '');

    if (_isProductionMarker(projectId) || projectId.isEmpty) {
      warnings.add('Firebase Project ID not configured - push notifications disabled');
    }

    if (_isProductionMarker(apiKey) || apiKey.isEmpty) {
      warnings.add('Firebase API Key not configured - Firebase features disabled');
    }

    if (_isProductionMarker(appId) || appId.isEmpty) {
      warnings.add('Firebase App ID not configured - analytics may not work');
    }

    if (_isProductionMarker(fcmSenderId) || fcmSenderId.isEmpty) {
      warnings.add('FCM Sender ID not configured - push notifications disabled');
    }
  }

  static void _validateAnalyticsConfig(List<String> errors, List<String> warnings) {
    const googleAnalyticsId = String.fromEnvironment('GOOGLE_ANALYTICS_ID', defaultValue: '');
    const mixpanelToken = String.fromEnvironment('MIXPANEL_TOKEN', defaultValue: '');
    const amplitudeApiKey = String.fromEnvironment('AMPLITUDE_API_KEY', defaultValue: '');

    if (_isProductionMarker(googleAnalyticsId) || googleAnalyticsId.isEmpty) {
      warnings.add('Google Analytics not configured - web analytics disabled');
    }

    if (_isProductionMarker(mixpanelToken) || mixpanelToken.isEmpty) {
      warnings.add('Mixpanel not configured - event tracking may be limited');
    }

    if (_isProductionMarker(amplitudeApiKey) || amplitudeApiKey.isEmpty) {
      warnings.add('Amplitude not configured - advanced analytics disabled');
    }
  }

  static void _validateFeatureFlags(List<String> errors, List<String> warnings) {
    // Feature flags validation (ensure they're properly set)
    const enableBiometrics = String.fromEnvironment('ENABLE_BIOMETRICS', defaultValue: 'true');
    const enableOfflineVoting = String.fromEnvironment('ENABLE_OFFLINE_VOTING', defaultValue: 'true');
    const enableNotifications = String.fromEnvironment('ENABLE_NOTIFICATIONS', defaultValue: 'true');

    if (!['true', 'false'].contains(enableBiometrics.toLowerCase())) {
      warnings.add('ENABLE_BIOMETRICS should be "true" or "false"');
    }

    if (!['true', 'false'].contains(enableOfflineVoting.toLowerCase())) {
      warnings.add('ENABLE_OFFLINE_VOTING should be "true" or "false"');
    }

    if (!['true', 'false'].contains(enableNotifications.toLowerCase())) {
      warnings.add('ENABLE_NOTIFICATIONS should be "true" or "false"');
    }
  }

  static bool _isProductionMarker(String value) {
    return _productionMarkers.any((marker) => value.contains(marker));
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'api_base_url': const String.fromEnvironment('API_BASE_URL', defaultValue: 'not_set'),
      'ws_base_url': const String.fromEnvironment('WS_BASE_URL', defaultValue: 'not_set'),
      'firebase_project_id': const String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: 'not_set'),
      'enable_biometrics': const String.fromEnvironment('ENABLE_BIOMETRICS', defaultValue: 'true'),
      'enable_offline_voting': const String.fromEnvironment('ENABLE_OFFLINE_VOTING', defaultValue: 'true'),
      'enable_notifications': const String.fromEnvironment('ENABLE_NOTIFICATIONS', defaultValue: 'true'),
      'enable_analytics': const String.fromEnvironment('ENABLE_ANALYTICS', defaultValue: 'true'),
      'university_name': const String.fromEnvironment('UNIVERSITY_NAME', defaultValue: 'Kwara State University'),
    };
  }
}