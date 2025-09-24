import 'package:flutter/material.dart';

/// KWASU-themed color scheme and design system for Electra
/// 
/// Features:
/// - KWASU brand colors and typography
/// - Dark and light mode support  
/// - Neomorphic design tokens
/// - Accessibility compliant colors
/// - Material 3 design language
class AppTheme {
  // KWASU Brand Colors
  static const Color kwasuPrimary = Color(0xFF1B5E20); // KWASU Green
  static const Color kwasuSecondary = Color(0xFF2E7D32);
  static const Color kwasuAccent = Color(0xFF4CAF50);
  static const Color kwasuGold = Color(0xFFFFB300);
  
  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral Colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);

  /// Light theme configuration
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: kwasuPrimary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8F5E8),
      onPrimaryContainer: Color(0xFF1B4332),
      secondary: kwasuSecondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8F2E8),
      onSecondaryContainer: Color(0xFF1B4332),
      tertiary: kwasuGold,
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFFFFE082),
      onTertiaryContainer: Color(0xFF3E2723),
      error: error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: Color(0xFFB71C1C),
      surface: Colors.white,
      onSurface: neutral900,
      surfaceVariant: neutral100,
      onSurfaceVariant: neutral700,
      outline: neutral400,
      outlineVariant: neutral300,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: neutral800,
      onInverseSurface: neutral100,
      inversePrimary: Color(0xFF81C784),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'KWASU',
      scaffoldBackgroundColor: neutral50,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: neutral900,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'KWASU',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Text theme
      textTheme: textTheme,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFF81C784),
      onPrimary: Color(0xFF1B4332),
      primaryContainer: Color(0xFF2E7D32),
      onPrimaryContainer: Color(0xFFE8F5E8),
      secondary: Color(0xFF81C784),
      onSecondary: Color(0xFF1B4332),
      secondaryContainer: Color(0xFF2E5735),
      onSecondaryContainer: Color(0xFFE8F2E8),
      tertiary: kwasuGold,
      onTertiary: Colors.black,
      tertiaryContainer: Color(0xFF5D4037),
      onTertiaryContainer: Color(0xFFFFE082),
      error: Color(0xFFEF5350),
      onError: Colors.black,
      errorContainer: Color(0xFFB71C1C),
      onErrorContainer: Color(0xFFFFEBEE),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFE0E0E0),
      surfaceVariant: Color(0xFF2C2C2C),
      onSurfaceVariant: Color(0xFFBDBDBD),
      outline: Color(0xFF616161),
      outlineVariant: Color(0xFF424242),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: Color(0xFFE0E0E0),
      onInverseSurface: Color(0xFF212121),
      inversePrimary: kwasuPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'KWASU',
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'KWASU',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE0E0E0),
        ),
      ),

      // Text theme
      textTheme: textTheme.apply(
        bodyColor: const Color(0xFFE0E0E0),
        displayColor: const Color(0xFFE0E0E0),
      ),
    );
  }

  /// Text theme for KWASU branding
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: TextStyle(
      fontFamily: 'KWASU',
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}