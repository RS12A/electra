import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';

import '../storage/storage_service.dart';
import '../../shared/utils/logger.dart';
import 'theme_config.dart';
import 'app_colors.dart';

/// Theme controller for managing application themes
@singleton
class ThemeController extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _accessibilityKey = 'accessibility_settings';
  
  final StorageService _storageService;
  
  AppThemeMode _currentTheme = AppThemeMode.kwasu;
  bool _reduceMotion = false;
  bool _highContrast = false;
  double _textScaleFactor = 1.0;
  bool _initialized = false;

  ThemeController(this._storageService);

  /// Current theme mode
  AppThemeMode get currentTheme => _currentTheme;
  
  /// Whether motion should be reduced for accessibility
  bool get reduceMotion => _reduceMotion;
  
  /// Whether high contrast mode is enabled
  bool get highContrast => _highContrast;
  
  /// Current text scale factor
  double get textScaleFactor => _textScaleFactor;
  
  /// Whether the controller is initialized
  bool get initialized => _initialized;

  /// Initialize theme controller with persisted settings
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Load persisted theme
      final themeData = await _storageService.readSecure(_themeKey);
      if (themeData != null) {
        final themeIndex = int.tryParse(themeData) ?? 0;
        if (themeIndex >= 0 && themeIndex < AppThemeMode.values.length) {
          _currentTheme = AppThemeMode.values[themeIndex];
        }
      }

      // Load accessibility settings
      final accessibilityData = await _storageService.readSecure(_accessibilityKey);
      if (accessibilityData != null) {
        final settings = accessibilityData.split(',');
        if (settings.length >= 3) {
          _reduceMotion = settings[0] == 'true';
          _highContrast = settings[1] == 'true';
          _textScaleFactor = double.tryParse(settings[2]) ?? 1.0;
        }
      }

      // Apply system accessibility settings if not explicitly set
      await _checkSystemAccessibilitySettings();

      _initialized = true;
      notifyListeners();
      
      AppLogger.info('Theme controller initialized with theme: $_currentTheme');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize theme controller', e, stackTrace);
      _initialized = true; // Still mark as initialized to prevent hanging
      notifyListeners();
    }
  }

  /// Change the current theme
  Future<void> changeTheme(AppThemeMode theme) async {
    if (_currentTheme == theme) return;
    
    try {
      _currentTheme = theme;
      
      // Persist theme selection
      await _storageService.storeSecure(_themeKey, theme.index.toString());
      
      // Update system UI overlay style
      _updateSystemUIOverlay();
      
      notifyListeners();
      AppLogger.info('Theme changed to: $theme');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to change theme', e, stackTrace);
    }
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newTheme = _currentTheme == AppThemeMode.dark 
        ? AppThemeMode.light 
        : AppThemeMode.dark;
    await changeTheme(newTheme);
  }

  /// Set accessibility preferences
  Future<void> setAccessibilitySettings({
    bool? reduceMotion,
    bool? highContrast,
    double? textScaleFactor,
  }) async {
    bool changed = false;
    
    try {
      if (reduceMotion != null && _reduceMotion != reduceMotion) {
        _reduceMotion = reduceMotion;
        changed = true;
      }
      
      if (highContrast != null && _highContrast != highContrast) {
        _highContrast = highContrast;
        changed = true;
        
        // Auto-switch to high contrast theme if enabled
        if (highContrast && _currentTheme != AppThemeMode.highContrast) {
          await changeTheme(AppThemeMode.highContrast);
        }
      }
      
      if (textScaleFactor != null && _textScaleFactor != textScaleFactor) {
        _textScaleFactor = textScaleFactor.clamp(0.8, 2.0);
        changed = true;
      }
      
      if (changed) {
        // Persist accessibility settings
        final settingsString = '$_reduceMotion,$_highContrast,$_textScaleFactor';
        await _storageService.storeSecure(_accessibilityKey, settingsString);
        
        notifyListeners();
        AppLogger.info('Accessibility settings updated');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update accessibility settings', e, stackTrace);
    }
  }

  /// Check and apply system accessibility settings
  Future<void> _checkSystemAccessibilitySettings() async {
    try {
      // Note: In a real implementation, you would check platform-specific
      // accessibility settings. For now, we'll use sensible defaults.
      
      // Check if we should respect system settings
      final mediaQuery = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
      
      if (mediaQuery.reduceMotion && !_reduceMotion) {
        _reduceMotion = true;
        AppLogger.info('Applied system reduce motion setting');
      }
      
      if (mediaQuery.highContrast && !_highContrast) {
        _highContrast = true;
        if (_currentTheme != AppThemeMode.highContrast) {
          _currentTheme = AppThemeMode.highContrast;
        }
        AppLogger.info('Applied system high contrast setting');
      }
      
      // Save updated settings
      if (_reduceMotion || _highContrast) {
        final settingsString = '$_reduceMotion,$_highContrast,$_textScaleFactor';
        await _storageService.storeSecure(_accessibilityKey, settingsString);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check system accessibility settings', e, stackTrace);
    }
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUIOverlay() {
    final isDark = _currentTheme == AppThemeMode.dark || 
                   (_currentTheme == AppThemeMode.kwasu && false); // KWASU is light-based
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark 
            ? AppColors.grey900 
            : AppColors.white,
        systemNavigationBarIconBrightness: isDark 
            ? Brightness.light 
            : Brightness.dark,
      ),
    );
  }

  /// Get appropriate animation duration based on accessibility settings
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_reduceMotion) {
      return AnimationConfig.reducedMotionDuration;
    }
    return defaultDuration;
  }

  /// Get current theme data
  ThemeData get currentThemeData {
    return _buildThemeData(_currentTheme);
  }

  /// Build theme data for specific theme mode
  ThemeData _buildThemeData(AppThemeMode themeMode) {
    final colorScheme = AppColors.getColorScheme(themeMode);
    final isDark = colorScheme.brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: TypographyConfig.fontFamily,
        ),
      ),
      
      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: NeomorphicConfig.defaultElevation,
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingConfig.lg, 
            vertical: SpacingConfig.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          ),
          textStyle: TextStyle(
            fontSize: TypographyConfig.baseFontSize,
            fontWeight: FontWeight.w600,
            fontFamily: TypographyConfig.fontFamily,
          ),
        ),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: NeomorphicConfig.defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
        ),
        color: colorScheme.surface,
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingConfig.md,
          vertical: SpacingConfig.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NeomorphicConfig.defaultBorderRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      
      // Scaffold background
      scaffoldBackgroundColor: AppColors.getBackgroundColor(themeMode),
    );
  }

  /// Build text theme with proper scaling
  TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final Color textColor = colorScheme.onSurface;
    const String fontFamily = TypographyConfig.fontFamily;
    final double scale = _textScaleFactor;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57 * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
        letterSpacing: TypographyConfig.headingLetterSpacing,
      ),
      displayMedium: TextStyle(
        fontSize: 45 * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36 * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32 * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
        letterSpacing: TypographyConfig.headingLetterSpacing,
      ),
      headlineMedium: TextStyle(
        fontSize: 28 * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22 * scale,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: TypographyConfig.baseFontSize * scale,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: TypographyConfig.baseFontSize * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
        letterSpacing: TypographyConfig.bodyLetterSpacing,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * scale,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11 * scale,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
    );
  }
}

/// Provider for theme controller
final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  // Create a mock storage service for now
  // In production, this should be injected via proper DI
  final mockStorage = _MockStorageService();
  return ThemeController(mockStorage);
});

/// Mock storage service that implements the interface needed by ThemeController
class _MockStorageService implements StorageService {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> readSecure(String key) async {
    return _storage[key];
  }
  
  @override
  Future<void> storeSecure(String key, String value) async {
    _storage[key] = value;
  }
  
  // Required by StorageService interface but not used by ThemeController
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return default values for unimplemented methods
    return super.noSuchMethod(invocation);
  }
}

/// Provider for current theme mode
final currentThemeProvider = Provider<AppThemeMode>((ref) {
  final controller = ref.watch(themeControllerProvider);
  return controller.currentTheme;
});

/// Provider for current theme data
final currentThemeDataProvider = Provider<ThemeData>((ref) {
  final controller = ref.watch(themeControllerProvider);
  return controller.currentThemeData;
});

/// Provider for animation duration (respects accessibility settings)
final animationDurationProvider = Provider.family<Duration, Duration>((ref, defaultDuration) {
  final controller = ref.watch(themeControllerProvider);
  return controller.getAnimationDuration(defaultDuration);
});

/// Provider for accessibility settings
final accessibilitySettingsProvider = Provider<({bool reduceMotion, bool highContrast, double textScale})>((ref) {
  final controller = ref.watch(themeControllerProvider);
  return (
    reduceMotion: controller.reduceMotion,
    highContrast: controller.highContrast,
    textScale: controller.textScaleFactor,
  );
});