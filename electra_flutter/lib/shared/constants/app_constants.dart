/// Application constants and configuration values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // API Configuration
  static const String baseUrl = 'http://your_server_url_goes_here:8000';
  static const String apiVersion = 'v1';

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

  // University Information
  static const String universityName = 'Kwara State University';
  static const String universityAbbr = 'KWASU';
  static const String supportEmail = 'electoral@kwasu.edu.ng';
  static const String supportPhone = '+234-XXX-XXX-XXXX';

  // App Information
  static const String appName = 'Electra';
  static const String appDescription = 'Secure Digital Voting System';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Legal
  static const String privacyPolicyUrl = 'https://electra.kwasu.edu.ng/privacy';
  static const String termsOfServiceUrl = 'https://electra.kwasu.edu.ng/terms';

  // Feature Flags
  static const bool enableBiometrics = true;
  static const bool enableOfflineVoting = true;
  static const bool enableAnalytics = true;
  static const bool enableNotifications = true;
  static const bool enableDarkMode = true;

  // Security
  static const Duration sessionTimeout = Duration(hours: 1);
  static const Duration tokenRefreshThreshold = Duration(minutes: 5);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
}
