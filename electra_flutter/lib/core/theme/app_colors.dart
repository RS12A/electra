import 'package:flutter/material.dart';
import 'theme_config.dart';

/// Comprehensive color system for all theme variations
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// KWASU University Brand Colors
  static const Color kwasuPrimary = Color(0xFF1B5E20); // KWASU Green
  static const Color kwasuSecondary = Color(0xFF2E7D32);
  static const Color kwasuAccent = Color(0xFF4CAF50);
  static const Color kwasuGold = Color(0xFFFFB300);
  static const Color kwasuBlue = Color(0xFF1E3A8A);
  static const Color kwasuLightBlue = Color(0xFF3B82F6);

  /// Semantic Colors (consistent across themes)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF047857);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  /// Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  
  // Grey Scale
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  /// High Contrast Colors
  static const Color highContrastLight = Color(0xFFFFFFFF);
  static const Color highContrastDark = Color(0xFF000000);
  static const Color highContrastPrimary = Color(0xFF0000FF);
  static const Color highContrastSecondary = Color(0xFF008000);

  /// Get color scheme for specific theme
  static ColorScheme getColorScheme(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.kwasu:
        return _getKWASUColorScheme();
      case AppThemeMode.light:
        return _getLightColorScheme();
      case AppThemeMode.dark:
        return _getDarkColorScheme();
      case AppThemeMode.highContrast:
        return _getHighContrastColorScheme();
    }
  }

  /// KWASU-first color scheme
  static ColorScheme _getKWASUColorScheme() {
    return const ColorScheme.light(
      brightness: Brightness.light,
      primary: kwasuPrimary,
      onPrimary: white,
      primaryContainer: Color(0xFFE8F2E8),
      onPrimaryContainer: Color(0xFF1B4332),
      secondary: kwasuGold,
      onSecondary: black,
      secondaryContainer: Color(0xFFFFE082),
      onSecondaryContainer: Color(0xFF3E2723),
      tertiary: kwasuBlue,
      onTertiary: white,
      tertiaryContainer: Color(0xFFE3F2FD),
      onTertiaryContainer: Color(0xFF0D47A1),
      error: error,
      onError: white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: Color(0xFFB71C1C),
      surface: white,
      onSurface: grey900,
      surfaceVariant: grey50,
      onSurfaceVariant: grey700,
      outline: grey400,
      outlineVariant: grey300,
      shadow: black,
      scrim: Color(0x80000000),
      inverseSurface: grey800,
      onInverseSurface: grey100,
      inversePrimary: kwasuAccent,
    );
  }

  /// Standard light color scheme
  static ColorScheme _getLightColorScheme() {
    return const ColorScheme.light(
      brightness: Brightness.light,
      primary: Color(0xFF6750A4),
      onPrimary: white,
      primaryContainer: Color(0xFFEADDFF),
      onPrimaryContainer: Color(0xFF21005D),
      secondary: Color(0xFF625B71),
      onSecondary: white,
      secondaryContainer: Color(0xFFE8DEF8),
      onSecondaryContainer: Color(0xFF1D192B),
      tertiary: Color(0xFF7D5260),
      onTertiary: white,
      tertiaryContainer: Color(0xFFFFD8E4),
      onTertiaryContainer: Color(0xFF31111D),
      error: error,
      onError: white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: white,
      onSurface: grey900,
      surfaceVariant: Color(0xFFE7E0EC),
      onSurfaceVariant: Color(0xFF49454F),
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: black,
      scrim: Color(0x80000000),
      inverseSurface: Color(0xFF313033),
      onInverseSurface: Color(0xFFF4EFF4),
      inversePrimary: Color(0xFFD0BCFF),
    );
  }

  /// Dark color scheme
  static ColorScheme _getDarkColorScheme() {
    return const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: Color(0xFFD0BCFF),
      onPrimary: Color(0xFF381E72),
      primaryContainer: Color(0xFF4F378B),
      onPrimaryContainer: Color(0xFFEADDFF),
      secondary: Color(0xFFCCC2DC),
      onSecondary: Color(0xFF332D41),
      secondaryContainer: Color(0xFF4A4458),
      onSecondaryContainer: Color(0xFFE8DEF8),
      tertiary: Color(0xFFEFB8C8),
      onTertiary: Color(0xFF492532),
      tertiaryContainer: Color(0xFF633B48),
      onTertiaryContainer: Color(0xFFFFD8E4),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1C1B1F),
      onSurface: Color(0xFFE6E1E5),
      surfaceVariant: Color(0xFF49454F),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: black,
      scrim: Color(0x80000000),
      inverseSurface: Color(0xFFE6E1E5),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: Color(0xFF6750A4),
    );
  }

  /// High contrast color scheme for accessibility
  static ColorScheme _getHighContrastColorScheme() {
    return const ColorScheme.light(
      brightness: Brightness.light,
      primary: highContrastDark,
      onPrimary: highContrastLight,
      primaryContainer: Color(0xFFE0E0E0),
      onPrimaryContainer: highContrastDark,
      secondary: highContrastPrimary,
      onSecondary: highContrastLight,
      secondaryContainer: Color(0xFFE6F3FF),
      onSecondaryContainer: Color(0xFF001F3F),
      tertiary: highContrastSecondary,
      onTertiary: highContrastLight,
      tertiaryContainer: Color(0xFFE8F5E8),
      onTertiaryContainer: Color(0xFF003300),
      error: Color(0xFFCC0000),
      onError: highContrastLight,
      errorContainer: Color(0xFFFFE6E6),
      onErrorContainer: Color(0xFF800000),
      surface: highContrastLight,
      onSurface: highContrastDark,
      surfaceVariant: Color(0xFFF0F0F0),
      onSurfaceVariant: highContrastDark,
      outline: Color(0xFF666666),
      outlineVariant: Color(0xFF999999),
      shadow: highContrastDark,
      scrim: Color(0x80000000),
      inverseSurface: highContrastDark,
      onInverseSurface: highContrastLight,
      inversePrimary: Color(0xFF888888),
    );
  }

  /// Get neomorphic light shadow color for theme
  static Color getLightShadowColor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.kwasu:
        return white.withOpacity(0.8);
      case AppThemeMode.light:
        return white.withOpacity(0.9);
      case AppThemeMode.dark:
        return Color(0xFF2A2A2A).withOpacity(0.4);
      case AppThemeMode.highContrast:
        return grey200;
    }
  }

  /// Get neomorphic dark shadow color for theme
  static Color getDarkShadowColor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.kwasu:
        return kwasuPrimary.withOpacity(0.3);
      case AppThemeMode.light:
        return grey400.withOpacity(0.5);
      case AppThemeMode.dark:
        return black.withOpacity(0.8);
      case AppThemeMode.highContrast:
        return highContrastDark.withOpacity(0.8);
    }
  }

  /// Get background color for theme
  static Color getBackgroundColor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.kwasu:
        return const Color(0xFFF8F9FA);
      case AppThemeMode.light:
        return grey50;
      case AppThemeMode.dark:
        return const Color(0xFF121212);
      case AppThemeMode.highContrast:
        return highContrastLight;
    }
  }

  /// Get surface color for theme
  static Color getSurfaceColor(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.kwasu:
        return white;
      case AppThemeMode.light:
        return white;
      case AppThemeMode.dark:
        return const Color(0xFF1E1E1E);
      case AppThemeMode.highContrast:
        return highContrastLight;
    }
  }
}