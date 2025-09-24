import 'package:flutter/material.dart';

/// Available theme modes in the application
enum AppThemeMode {
  /// KWASU-first theme with university branding (default)
  kwasu,
  /// Standard light theme
  light,
  /// Standard dark theme
  dark,
  /// High contrast theme for accessibility
  highContrast,
}

/// Animation configuration for the app
class AnimationConfig {
  /// Default animation duration for micro-interactions
  static const Duration microDuration = Duration(milliseconds: 200);
  
  /// Default animation duration for screen transitions
  static const Duration screenTransitionDuration = Duration(milliseconds: 300);
  
  /// Default animation duration for loading states
  static const Duration loadingDuration = Duration(milliseconds: 1000);
  
  /// Default spring animation curve
  static const Curve springCurve = Curves.elasticOut;
  
  /// Default easing curve for smooth transitions
  static const Curve easingCurve = Curves.easeInOutCubic;
  
  /// Bounce curve for playful interactions
  static const Curve bounceCurve = Curves.bounceOut;
  
  /// Reduce motion duration for accessibility
  static const Duration reducedMotionDuration = Duration(milliseconds: 50);
}

/// Neomorphic design configuration
class NeomorphicConfig {
  /// Default elevation for neomorphic elements
  static const double defaultElevation = 4.0;
  
  /// Pressed state elevation
  static const double pressedElevation = 1.0;
  
  /// Default border radius
  static const double defaultBorderRadius = 12.0;
  
  /// Default shadow blur radius
  static const double defaultShadowBlur = 8.0;
  
  /// Default shadow spread radius
  static const double defaultShadowSpread = 2.0;
  
  /// Light shadow opacity
  static const double lightShadowOpacity = 0.2;
  
  /// Dark shadow opacity
  static const double darkShadowOpacity = 0.8;
}

/// Typography scale configuration
class TypographyConfig {
  /// Base font size
  static const double baseFontSize = 16.0;
  
  /// Typography scale ratio
  static const double scaleRatio = 1.25;
  
  /// Font family
  static const String fontFamily = 'KWASU';
  
  /// Letter spacing for headings
  static const double headingLetterSpacing = -0.5;
  
  /// Letter spacing for body text
  static const double bodyLetterSpacing = 0.0;
  
  /// Line height multiplier
  static const double lineHeightMultiplier = 1.5;
}

/// Spacing system configuration
class SpacingConfig {
  /// Base spacing unit
  static const double baseUnit = 8.0;
  
  /// Extra small spacing
  static const double xs = baseUnit * 0.5; // 4
  
  /// Small spacing
  static const double sm = baseUnit; // 8
  
  /// Medium spacing
  static const double md = baseUnit * 2; // 16
  
  /// Large spacing
  static const double lg = baseUnit * 3; // 24
  
  /// Extra large spacing
  static const double xl = baseUnit * 4; // 32
  
  /// Extra extra large spacing
  static const double xxl = baseUnit * 6; // 48
}