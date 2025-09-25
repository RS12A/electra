import 'package:flutter/material.dart';
import 'app_colors.dart';

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
  /// Custom university theme (dynamically loaded)
  custom,
}

/// University branding configuration
class UniversityBranding {
  final String name;
  final String abbreviation;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String? logoPath;
  final String fontFamily;
  final Map<String, dynamic>? customProperties;

  const UniversityBranding({
    required this.name,
    required this.abbreviation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.logoPath,
    this.fontFamily = 'KWASU',
    this.customProperties,
  });

  /// Default KWASU branding
  static const kwasu = UniversityBranding(
    name: 'Kwara State University',
    abbreviation: 'KWASU',
    primaryColor: AppColors.kwasuPrimary,
    secondaryColor: AppColors.kwasuSecondary,
    accentColor: AppColors.kwasuAccent,
    logoPath: 'assets/logos/kwasu_logo.png',
  );

  /// Create custom university branding from JSON
  factory UniversityBranding.fromJson(Map<String, dynamic> json) {
    return UniversityBranding(
      name: json['name'] ?? 'University',
      abbreviation: json['abbreviation'] ?? 'UNI',
      primaryColor: Color(json['primaryColor'] ?? 0xFF1B5E20),
      secondaryColor: Color(json['secondaryColor'] ?? 0xFF2E7D32),
      accentColor: Color(json['accentColor'] ?? 0xFF4CAF50),
      logoPath: json['logoPath'],
      fontFamily: json['fontFamily'] ?? 'Roboto',
      customProperties: json['customProperties'],
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'accentColor': accentColor.value,
      'logoPath': logoPath,
      'fontFamily': fontFamily,
      'customProperties': customProperties,
    };
  }
}

/// Animation configuration for the app
class AnimationConfig {
  /// Ultra-fast duration for micro-interactions (button press, hover)
  static const Duration microDuration = Duration(milliseconds: 150);
  
  /// Fast duration for component state changes
  static const Duration fastDuration = Duration(milliseconds: 200);
  
  /// Default animation duration for screen transitions
  static const Duration screenTransitionDuration = Duration(milliseconds: 300);
  
  /// Slower duration for complex animations
  static const Duration slowDuration = Duration(milliseconds: 400);
  
  /// Default animation duration for loading states
  static const Duration loadingDuration = Duration(milliseconds: 1200);
  
  /// Duration for staggered list animations
  static const Duration staggerDuration = Duration(milliseconds: 60);
  
  /// Duration for page route transitions
  static const Duration routeTransitionDuration = Duration(milliseconds: 350);
  
  /// GPU-optimized spring curve for smooth interactions
  static const Curve springCurve = Curves.easeOutBack;
  
  /// High-performance easing curve for smooth transitions
  static const Curve easingCurve = Curves.easeInOutCubic;
  
  /// Subtle bounce curve for delightful micro-interactions
  static const Curve bounceCurve = Curves.elasticOut;
  
  /// Sharp curve for quick state changes
  static const Curve sharpCurve = Curves.easeOutQuart;
  
  /// Smooth curve for content animations
  static const Curve smoothCurve = Curves.easeInOutQuint;
  
  /// Reduce motion duration for accessibility
  static const Duration reducedMotionDuration = Duration(milliseconds: 50);
  
  /// Get animation duration based on accessibility settings
  static Duration getDuration(Duration duration, {bool reduceMotion = false}) {
    return reduceMotion ? reducedMotionDuration : duration;
  }
}

/// Enhanced neomorphic design configuration with performance optimizations
class NeomorphicConfig {
  /// Default elevation for neomorphic elements
  static const double defaultElevation = 6.0;
  
  /// Pressed state elevation for tactile feedback
  static const double pressedElevation = 2.0;
  
  /// Hover state elevation multiplier
  static const double hoverElevationMultiplier = 1.3;
  
  /// Default border radius for consistency
  static const double defaultBorderRadius = 16.0;
  
  /// Small border radius for compact elements
  static const double smallBorderRadius = 8.0;
  
  /// Large border radius for prominent elements
  static const double largeBorderRadius = 24.0;
  
  /// Default shadow blur radius for depth
  static const double defaultShadowBlur = 12.0;
  
  /// Intense shadow blur for elevated elements
  static const double intenseShadowBlur = 20.0;
  
  /// Subtle shadow blur for minimal depth
  static const double subtleShadowBlur = 6.0;
  
  /// Default shadow spread radius
  static const double defaultShadowSpread = 1.0;
  
  /// Light shadow opacity for bright themes
  static const double lightShadowOpacity = 0.15;
  
  /// Dark shadow opacity for deep shadows
  static const double darkShadowOpacity = 0.6;
  
  /// High contrast shadow opacity
  static const double highContrastShadowOpacity = 0.8;
  
  /// Animation scale factor for press interactions
  static const double pressScaleFactor = 0.98;
  
  /// Animation scale factor for hover interactions
  static const double hoverScaleFactor = 1.02;
  
  /// Gradient stops for neomorphic highlights
  static const List<double> gradientStops = [0.0, 0.3, 0.7, 1.0];
  
  /// Optimized shadow offsets for different elevations
  static Offset getShadowOffset(double elevation, {bool isLight = false}) {
    final factor = isLight ? 0.5 : 1.0;
    return Offset(elevation * factor, elevation * factor);
  }
  
  /// Get optimized blur radius based on elevation
  static double getBlurRadius(double elevation) {
    return elevation * 2.0 + defaultShadowBlur;
  }
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

/// Enhanced spacing system configuration with responsive considerations
class SpacingConfig {
  /// Base spacing unit for consistent rhythm
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
  
  /// Massive spacing for major sections
  static const double massive = baseUnit * 8; // 64
  
  /// Get responsive spacing based on screen size
  static double getResponsiveSpacing(double width, double spacing) {
    if (ResponsiveConfig.isMobile(width)) return spacing * 0.8;
    if (ResponsiveConfig.isTablet(width)) return spacing;
    return spacing * 1.2;
  }
}

/// Responsive design breakpoints and configuration
class ResponsiveConfig {
  /// Mobile breakpoint (phones)
  static const double mobileBreakpoint = 600.0;
  
  /// Tablet breakpoint 
  static const double tabletBreakpoint = 900.0;
  
  /// Desktop breakpoint
  static const double desktopBreakpoint = 1200.0;
  
  /// Large desktop breakpoint
  static const double largeDesktopBreakpoint = 1800.0;
  
  /// Maximum content width for readability
  static const double maxContentWidth = 1400.0;
  
  /// Check if current screen width is mobile
  static bool isMobile(double width) => width < mobileBreakpoint;
  
  /// Check if current screen width is tablet
  static bool isTablet(double width) => 
      width >= mobileBreakpoint && width < desktopBreakpoint;
  
  /// Check if current screen width is desktop
  static bool isDesktop(double width) => width >= desktopBreakpoint;
  
  /// Get number of columns for grid based on screen size
  static int getGridColumns(double width) {
    if (isMobile(width)) return 1;
    if (isTablet(width)) return 2;
    return width > largeDesktopBreakpoint ? 4 : 3;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getScreenPadding(double width) {
    if (isMobile(width)) return const EdgeInsets.all(SpacingConfig.md);
    if (isTablet(width)) return const EdgeInsets.all(SpacingConfig.lg);
    return const EdgeInsets.all(SpacingConfig.xl);
  }
  
  /// Get responsive horizontal padding for content
  static EdgeInsets getContentPadding(double width) {
    if (isMobile(width)) return const EdgeInsets.symmetric(horizontal: SpacingConfig.md);
    if (isTablet(width)) return const EdgeInsets.symmetric(horizontal: SpacingConfig.xl);
    return const EdgeInsets.symmetric(horizontal: SpacingConfig.xxl);
  }
}