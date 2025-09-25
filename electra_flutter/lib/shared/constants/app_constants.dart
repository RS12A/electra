import '../../core/config/app_config.dart';

/// Application constants and configuration values
/// Now uses environment-aware configuration from AppConfig
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // API Configuration (now environment-aware)
  static String get baseUrl => AppConfig.baseUrl;
  static String get apiVersion => AppConfig.apiVersion;
  static String get wsBaseUrl => AppConfig.wsBaseUrl;

  // Endpoints
  static const String authEndpoint = '/api/auth';
  static const String electionsEndpoint = '/api/elections';
  static const String ballotsEndpoint = '/api/ballots';
  static const String votesEndpoint = '/api/votes';
  static const String adminEndpoint = '/api/admin';
  static const String analyticsEndpoint = '/api/analytics';
  static const String healthEndpoint = '/api/health';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String biometricsKey = 'biometrics_enabled';

  // Cache Keys
  static const String electionsCache = 'elections_cache';
  static const String candidatesCache = 'candidates_cache';
  static const String profileCache = 'profile_cache';
  static const String analyticsCache = 'analytics_cache';

  // Offline Queue
  static const String offlineVoteQueue = 'offline_vote_queue';
  static const String offlineBallotQueue = 'offline_ballot_queue';

  // File Paths
  static const String documentsPath = '/documents';
  static const String imagesPath = '/images';
  static const String logsPath = '/logs';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;
  static const Duration otpExpiration = Duration(minutes: 10);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Encryption
  static const int aesKeySize = 256;
  static const int rsaKeySize = 4096;

  // Logging
  static const int maxLogFiles = 10;
  static const int maxLogSizeBytes = 10 * 1024 * 1024; // 10MB

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration splashDelay = Duration(seconds: 2);

  // University Information (now environment-aware)
  static String get universityName => AppConfig.universityName;
  static String get universityAbbr => AppConfig.universityAbbr;
  static String get supportEmail => AppConfig.supportEmail;
  static String get supportPhone => AppConfig.supportPhone;

  // App Information
  static const String appName = 'Electra';
  static const String appDescription = 'Secure Digital Voting System';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Legal URLs (should be configurable per deployment)
  static String get privacyPolicyUrl => 'https://electra.${AppConfig.universityAbbr.toLowerCase()}.edu.ng/privacy';
  static String get termsOfServiceUrl => 'https://electra.${AppConfig.universityAbbr.toLowerCase()}.edu.ng/terms';

  // Feature Flags (now environment-aware)
  static bool get enableBiometrics => AppConfig.enableBiometrics;
  static bool get enableOfflineVoting => AppConfig.enableOfflineVoting;
  static bool get enableAnalytics => AppConfig.enableAnalytics;
  static bool get enableNotifications => AppConfig.enableNotifications;
  static bool get enableDarkMode => AppConfig.enableDarkMode;

  // Security
  static const Duration sessionTimeout = Duration(hours: 1);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  // Development and Debug
  static bool get developmentMode => AppConfig.developmentMode;
  static bool get debugMode => AppConfig.debugMode;

  // Firebase Configuration (now environment-aware)
  static String get firebaseProjectId => AppConfig.firebaseProjectId;
  static String get firebaseApiKey => AppConfig.firebaseApiKey;
  static String get firebaseAuthDomain => AppConfig.firebaseAuthDomain;
  static String get firebaseStorageBucket => AppConfig.firebaseStorageBucket;
  static String get fcmSenderId => AppConfig.fcmSenderId;
  static String get firebaseAppId => AppConfig.firebaseAppId;
  static String get firebaseMeasurementId => AppConfig.firebaseMeasurementId;

  // Analytics Configuration (now environment-aware)
  static String get googleAnalyticsId => AppConfig.googleAnalyticsId;
  static String get mixpanelToken => AppConfig.mixpanelToken;
  static String get amplitudeApiKey => AppConfig.amplitudeApiKey;

  // Helper methods for configuration checks
  static bool get isFirebaseConfigured => AppConfig.isFirebaseConfigured;
  static bool get isAnalyticsConfigured => AppConfig.isAnalyticsConfigured;
  static bool get isPushNotificationsEnabled => AppConfig.isPushNotificationsEnabled;

  /// Print configuration for debugging
  static void printConfiguration() {
    if (developmentMode || debugMode) {
      AppConfig.printConfigSummary();
    }
  }
}
