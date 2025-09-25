/// Application configuration that adapts based on environment variables
/// This replaces hardcoded values in app_constants.dart with environment-aware configuration
class AppConfig {
  AppConfig._();

  // API Configuration (from environment)
  static String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000', // Fallback for development
  );

  static String get apiVersion => const String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  static String get wsBaseUrl => const String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000',
  );

  // Firebase Configuration
  static String get firebaseProjectId => const String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static String get firebaseApiKey => const String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static String get firebaseAuthDomain => const String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );

  static String get firebaseStorageBucket => const String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static String get fcmSenderId => const String.fromEnvironment(
    'FCM_SENDER_ID',
    defaultValue: '',
  );

  static String get firebaseAppId => const String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  static String get firebaseMeasurementId => const String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: '',
  );

  // Analytics Configuration
  static String get googleAnalyticsId => const String.fromEnvironment(
    'GOOGLE_ANALYTICS_ID',
    defaultValue: '',
  );

  static String get mixpanelToken => const String.fromEnvironment(
    'MIXPANEL_TOKEN',
    defaultValue: '',
  );

  static String get amplitudeApiKey => const String.fromEnvironment(
    'AMPLITUDE_API_KEY',
    defaultValue: '',
  );

  // Feature Flags
  static bool get enableBiometrics => const String.fromEnvironment(
    'ENABLE_BIOMETRICS',
    defaultValue: 'true',
  ).toLowerCase() == 'true';

  static bool get enableOfflineVoting => const String.fromEnvironment(
    'ENABLE_OFFLINE_VOTING',
    defaultValue: 'true',
  ).toLowerCase() == 'true';

  static bool get enableAnalytics => const String.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: 'true',
  ).toLowerCase() == 'true';

  static bool get enableNotifications => const String.fromEnvironment(
    'ENABLE_NOTIFICATIONS',
    defaultValue: 'true',
  ).toLowerCase() == 'true';

  static bool get enableDarkMode => const String.fromEnvironment(
    'ENABLE_DARK_MODE',
    defaultValue: 'true',
  ).toLowerCase() == 'true';

  // University Configuration
  static String get universityName => const String.fromEnvironment(
    'UNIVERSITY_NAME',
    defaultValue: 'Kwara State University',
  );

  static String get universityAbbr => const String.fromEnvironment(
    'UNIVERSITY_ABBR',
    defaultValue: 'KWASU',
  );

  static String get supportEmail => const String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'electoral@kwasu.edu.ng',
  );

  static String get supportPhone => const String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+234-XXX-XXX-XXXX',
  );

  // Social Authentication
  static String get googleClientId => const String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // Development Configuration
  static bool get developmentMode => const String.fromEnvironment(
    'DEVELOPMENT_MODE',
    defaultValue: 'false',
  ).toLowerCase() == 'true';

  static bool get debugMode => const String.fromEnvironment(
    'FLUTTER_DEBUG',
    defaultValue: 'false',
  ).toLowerCase() == 'true';

  // Helper methods
  static bool get isFirebaseConfigured => 
    firebaseProjectId.isNotEmpty && 
    firebaseApiKey.isNotEmpty && 
    firebaseAppId.isNotEmpty;

  static bool get isAnalyticsConfigured => 
    googleAnalyticsId.isNotEmpty || 
    mixpanelToken.isNotEmpty || 
    amplitudeApiKey.isNotEmpty;

  static bool get isPushNotificationsEnabled => 
    isFirebaseConfigured && 
    fcmSenderId.isNotEmpty && 
    enableNotifications;

  /// Build configuration map for debugging and validation
  static Map<String, dynamic> toMap() {
    return {
      'baseUrl': baseUrl,
      'apiVersion': apiVersion,
      'wsBaseUrl': wsBaseUrl,
      'firebaseProjectId': firebaseProjectId,
      'firebaseApiKey': firebaseApiKey.isEmpty ? 'not_set' : '***configured***',
      'firebaseAuthDomain': firebaseAuthDomain,
      'firebaseStorageBucket': firebaseStorageBucket,
      'fcmSenderId': fcmSenderId,
      'firebaseAppId': firebaseAppId,
      'firebaseMeasurementId': firebaseMeasurementId,
      'googleAnalyticsId': googleAnalyticsId,
      'mixpanelToken': mixpanelToken.isEmpty ? 'not_set' : '***configured***',
      'amplitudeApiKey': amplitudeApiKey.isEmpty ? 'not_set' : '***configured***',
      'enableBiometrics': enableBiometrics,
      'enableOfflineVoting': enableOfflineVoting,
      'enableAnalytics': enableAnalytics,
      'enableNotifications': enableNotifications,
      'enableDarkMode': enableDarkMode,
      'universityName': universityName,
      'universityAbbr': universityAbbr,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'googleClientId': googleClientId.isEmpty ? 'not_set' : '***configured***',
      'developmentMode': developmentMode,
      'debugMode': debugMode,
      'isFirebaseConfigured': isFirebaseConfigured,
      'isAnalyticsConfigured': isAnalyticsConfigured,
      'isPushNotificationsEnabled': isPushNotificationsEnabled,
    };
  }

  /// Print configuration summary for debugging
  static void printConfigSummary() {
    print('📱 Flutter App Configuration Summary:');
    print('=====================================');
    final config = toMap();
    for (final entry in config.entries) {
      print('${entry.key}: ${entry.value}');
    }
    print('=====================================');
  }
}