import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_colors.dart';
import 'theme_config.dart';
import 'theme_controller.dart';

// Re-export for backward compatibility
export 'app_colors.dart';
export 'theme_config.dart';
export 'theme_controller.dart';

/// Legacy KWASUColors class for backward compatibility
/// @deprecated Use AppColors instead
class KWASUColors {
  static const Color primaryBlue = AppColors.kwasuBlue;
  static const Color secondaryGreen = AppColors.kwasuSecondary;
  static const Color accentGold = AppColors.kwasuGold;
  static const Color lightBlue = AppColors.kwasuLightBlue;
  static const Color darkBlue = AppColors.kwasuBlue;

  // Semantic colors
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color error = AppColors.error;
  static const Color info = AppColors.info;

  // Neutral colors
  static const Color white = AppColors.white;
  static const Color black = AppColors.black;
  static const Color grey50 = AppColors.grey50;
  static const Color grey100 = AppColors.grey100;
  static const Color grey200 = AppColors.grey200;
  static const Color grey300 = AppColors.grey300;
  static const Color grey400 = AppColors.grey400;
  static const Color grey500 = AppColors.grey500;
  static const Color grey600 = AppColors.grey600;
  static const Color grey700 = AppColors.grey700;
  static const Color grey800 = AppColors.grey800;
  static const Color grey900 = AppColors.grey900;
}

/// Legacy AppTheme class for backward compatibility
/// @deprecated Use ThemeController and related providers instead
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme configuration
  /// @deprecated Use ThemeController.currentThemeData instead
  static ThemeData get lightTheme {
    final colorScheme = AppColors.getColorScheme(AppThemeMode.light);
    return _buildLegacyTheme(colorScheme, AppThemeMode.light);
  }

  /// Dark theme configuration
  /// @deprecated Use ThemeController.currentThemeData instead
  static ThemeData get darkTheme {
    final colorScheme = AppColors.getColorScheme(AppThemeMode.dark);
    return _buildLegacyTheme(colorScheme, AppThemeMode.dark);
  }

  /// Build legacy theme for backward compatibility
  static ThemeData _buildLegacyTheme(ColorScheme colorScheme, AppThemeMode themeMode) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: themeMode == AppThemeMode.dark 
            ? KWASUColors.grey800 
            : (themeMode == AppThemeMode.light ? colorScheme.surface : KWASUColors.primaryBlue),
        foregroundColor: themeMode == AppThemeMode.dark || themeMode == AppThemeMode.light 
            ? colorScheme.onSurface 
            : KWASUColors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: themeMode == AppThemeMode.dark || themeMode == AppThemeMode.light 
              ? colorScheme.onSurface 
              : KWASUColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: TypographyConfig.fontFamily,
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: TypographyConfig.fontFamily,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: TypographyConfig.fontFamily,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: TypographyConfig.fontFamily,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6), fontSize: 14),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: colorScheme.surface,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Typography
      textTheme: _buildTextTheme(colorScheme.brightness),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.getBackgroundColor(themeMode),
    );
  }

  /// Build text theme for the given brightness
  /// @deprecated Use ThemeController._buildTextTheme instead
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light
        ? KWASUColors.grey900
        : KWASUColors.grey100;

    const String fontFamily = TypographyConfig.fontFamily;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor,
        fontFamily: fontFamily,
      ),
    );
  }
}

/// Theme mode provider for legacy support
/// @deprecated Use currentThemeProvider instead
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
