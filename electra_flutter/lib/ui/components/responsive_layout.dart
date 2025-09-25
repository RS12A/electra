import 'package:flutter/material.dart';

import '../../core/theme/theme_config.dart';

/// Responsive layout builder with optimized rebuilds
class ResponsiveLayoutBuilder extends StatelessWidget {
  const ResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.watch,
    this.breakpoints,
  });

  final Widget Function(BuildContext context, BoxConstraints constraints) mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)? tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktop;
  final Widget Function(BuildContext context, BoxConstraints constraints)? watch;
  final ResponsiveBreakpoints? breakpoints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bp = breakpoints ?? ResponsiveBreakpoints.defaults;
        final width = constraints.maxWidth;

        if (width >= bp.desktop && desktop != null) {
          return desktop!(context, constraints);
        }
        if (width >= bp.tablet && tablet != null) {
          return tablet!(context, constraints);
        }
        if (width <= bp.watch && watch != null) {
          return watch!(context, constraints);
        }
        
        return mobile(context, constraints);
      },
    );
  }
}

/// Responsive breakpoints configuration
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints({
    required this.watch,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  final double watch;
  final double mobile;
  final double tablet;
  final double desktop;

  static const defaults = ResponsiveBreakpoints(
    watch: 300,
    mobile: ResponsiveConfig.mobileBreakpoint,
    tablet: ResponsiveConfig.tabletBreakpoint,
    desktop: ResponsiveConfig.desktopBreakpoint,
  );
}

/// Responsive value that changes based on screen size
class ResponsiveValue<T> {
  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.watch,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;
  final T? watch;

  T getValue(double width) {
    if (width >= ResponsiveConfig.desktopBreakpoint && desktop != null) {
      return desktop!;
    }
    if (width >= ResponsiveConfig.tabletBreakpoint && tablet != null) {
      return tablet!;
    }
    if (width <= 300 && watch != null) {
      return watch!;
    }
    return mobile;
  }
}

/// Responsive padding that adapts to screen size
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile = const EdgeInsets.all(SpacingConfig.md),
    this.tablet,
    this.desktop,
  });

  final Widget child;
  final EdgeInsets mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        EdgeInsets padding = mobile;

        if (width >= ResponsiveConfig.desktopBreakpoint && desktop != null) {
          padding = desktop!;
        } else if (width >= ResponsiveConfig.tabletBreakpoint && tablet != null) {
          padding = tablet!;
        }

        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}

/// Responsive grid that adapts column count
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.mainAxisSpacing = SpacingConfig.md,
    this.crossAxisSpacing = SpacingConfig.md,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = mobileColumns;

        if (width >= ResponsiveConfig.desktopBreakpoint) {
          columns = desktopColumns;
        } else if (width >= ResponsiveConfig.tabletBreakpoint) {
          columns = tabletColumns;
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Responsive container with max width constraint
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveConfig.maxContentWidth,
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Responsive flex that changes direction based on screen size
class ResponsiveFlex extends StatelessWidget {
  const ResponsiveFlex({
    super.key,
    required this.children,
    this.mobileDirection = Axis.vertical,
    this.tabletDirection = Axis.horizontal,
    this.desktopDirection = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  final List<Widget> children;
  final Axis mobileDirection;
  final Axis tabletDirection;
  final Axis desktopDirection;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        Axis direction = mobileDirection;

        if (width >= ResponsiveConfig.desktopBreakpoint) {
          direction = desktopDirection;
        } else if (width >= ResponsiveConfig.tabletBreakpoint) {
          direction = tabletDirection;
        }

        return Flex(
          direction: direction,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: mainAxisSize,
          children: children,
        );
      },
    );
  }
}

/// Responsive wrap that adapts spacing
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = SpacingConfig.sm,
    this.runSpacing = SpacingConfig.sm,
    this.tabletSpacing,
    this.desktopSpacing,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.clipBehavior = Clip.none,
  });

  final List<Widget> children;
  final Axis direction;
  final WrapAlignment alignment;
  final double spacing;
  final double? tabletSpacing;
  final double? desktopSpacing;
  final double runSpacing;
  final WrapCrossAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double currentSpacing = spacing;

        if (width >= ResponsiveConfig.desktopBreakpoint && desktopSpacing != null) {
          currentSpacing = desktopSpacing!;
        } else if (width >= ResponsiveConfig.tabletBreakpoint && tabletSpacing != null) {
          currentSpacing = tabletSpacing!;
        }

        return Wrap(
          direction: direction,
          alignment: alignment,
          spacing: currentSpacing,
          runSpacing: runSpacing,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          clipBehavior: clipBehavior,
          children: children,
        );
      },
    );
  }
}

/// Helper widget to detect screen size
class ScreenSizeHelper extends StatelessWidget {
  const ScreenSizeHelper({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        ScreenSize screenSize;

        if (width >= ResponsiveConfig.desktopBreakpoint) {
          screenSize = ScreenSize.desktop;
        } else if (width >= ResponsiveConfig.tabletBreakpoint) {
          screenSize = ScreenSize.tablet;
        } else {
          screenSize = ScreenSize.mobile;
        }

        return builder(context, screenSize);
      },
    );
  }
}

/// Screen size enumeration
enum ScreenSize {
  mobile,
  tablet,
  desktop,
}

/// Extension methods for screen size detection
extension ScreenSizeExtension on BuildContext {
  /// Get current screen size
  ScreenSize get screenSize {
    final width = MediaQuery.of(this).size.width;
    if (width >= ResponsiveConfig.desktopBreakpoint) {
      return ScreenSize.desktop;
    } else if (width >= ResponsiveConfig.tabletBreakpoint) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.mobile;
    }
  }

  /// Check if current screen is mobile
  bool get isMobile => screenSize == ScreenSize.mobile;

  /// Check if current screen is tablet
  bool get isTablet => screenSize == ScreenSize.tablet;

  /// Check if current screen is desktop
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Get responsive value based on current screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (screenSize) {
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.mobile:
        return mobile;
    }
  }
}