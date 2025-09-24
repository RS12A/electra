import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Enhanced neomorphic card with animations and variants
class NeomorphicCard extends ConsumerStatefulWidget {
  const NeomorphicCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(SpacingConfig.md),
    this.margin = EdgeInsets.zero,
    this.borderRadius = NeomorphicConfig.defaultBorderRadius,
    this.elevation = NeomorphicConfig.defaultElevation,
    this.color,
    this.style = NeomorphicCardStyle.elevated,
    this.onTap,
    this.animateOnHover = false,
    this.shadowIntensity = 1.0,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final Color? color;
  final NeomorphicCardStyle style;
  final VoidCallback? onTap;
  final bool animateOnHover;
  final double shadowIntensity;

  @override
  ConsumerState<NeomorphicCard> createState() => _NeomorphicCardState();
}

class _NeomorphicCardState extends ConsumerState<NeomorphicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _hoverController = AnimationController(
      duration: AnimationConfig.microDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 1.5,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AnimationConfig.easingCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: AnimationConfig.easingCurve,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (!widget.animateOnHover) return;
    
    setState(() => _isHovered = isHovered);
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    
    final baseColor = widget.color ?? AppColors.getSurfaceColor(currentTheme);
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        final currentElevation = widget.animateOnHover 
            ? _elevationAnimation.value 
            : widget.elevation;
        final currentScale = widget.animateOnHover 
            ? _scaleAnimation.value 
            : 1.0;

        return Transform.scale(
          scale: currentScale,
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: widget.margin,
            child: MouseRegion(
              onEnter: (_) => _handleHover(true),
              onExit: (_) => _handleHover(false),
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: widget.padding,
                  decoration: _buildDecoration(
                    baseColor,
                    lightShadowColor,
                    darkShadowColor,
                    currentElevation,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _buildDecoration(
    Color baseColor,
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
  ) {
    switch (widget.style) {
      case NeomorphicCardStyle.elevated:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _buildElevatedShadows(
            lightShadowColor,
            darkShadowColor,
            elevation,
          ),
        );
      
      case NeomorphicCardStyle.inset:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _buildInsetShadows(
            lightShadowColor,
            darkShadowColor,
            elevation,
          ),
        );
      
      case NeomorphicCardStyle.flat:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: darkShadowColor.withOpacity(0.1),
            width: 1,
          ),
        );
      
      case NeomorphicCardStyle.pressed:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _buildInsetShadows(
            lightShadowColor,
            darkShadowColor,
            elevation * 0.5,
          ),
        );
    }
  }

  List<BoxShadow> _buildElevatedShadows(
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
  ) {
    return [
      BoxShadow(
        color: darkShadowColor.withOpacity(
          NeomorphicConfig.darkShadowOpacity * widget.shadowIntensity,
        ),
        offset: Offset(elevation, elevation),
        blurRadius: NeomorphicConfig.defaultShadowBlur * widget.shadowIntensity,
        spreadRadius: NeomorphicConfig.defaultShadowSpread,
      ),
      BoxShadow(
        color: lightShadowColor.withOpacity(
          NeomorphicConfig.lightShadowOpacity * widget.shadowIntensity,
        ),
        offset: Offset(-elevation * 0.5, -elevation * 0.5),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.7 * widget.shadowIntensity,
        spreadRadius: NeomorphicConfig.defaultShadowSpread * 0.5,
      ),
    ];
  }

  List<BoxShadow> _buildInsetShadows(
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
  ) {
    return [
      BoxShadow(
        color: darkShadowColor.withOpacity(0.6 * widget.shadowIntensity),
        offset: Offset(elevation * 0.5, elevation * 0.5),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.5 * widget.shadowIntensity,
        spreadRadius: -NeomorphicConfig.defaultShadowSpread,
        inset: true,
      ),
      BoxShadow(
        color: lightShadowColor.withOpacity(0.3 * widget.shadowIntensity),
        offset: Offset(-elevation * 0.3, -elevation * 0.3),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.3 * widget.shadowIntensity,
        spreadRadius: -NeomorphicConfig.defaultShadowSpread * 0.5,
        inset: true,
      ),
    ];
  }
}

/// Neomorphic card styles
enum NeomorphicCardStyle {
  elevated,
  inset,
  flat,
  pressed,
}

/// Specialized neomorphic card variants
class NeomorphicCards {
  /// Content card with subtle elevation
  static Widget content({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    VoidCallback? onTap,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.elevated,
      elevation: 2.0,
      padding: padding ?? const EdgeInsets.all(SpacingConfig.md),
      margin: margin ?? EdgeInsets.zero,
      onTap: onTap,
      animateOnHover: onTap != null,
      child: child,
    );
  }

  /// Interactive card that responds to hover
  static Widget interactive({
    required Widget child,
    required VoidCallback onTap,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.elevated,
      elevation: 3.0,
      padding: padding ?? const EdgeInsets.all(SpacingConfig.md),
      margin: margin ?? EdgeInsets.zero,
      onTap: onTap,
      animateOnHover: true,
      child: child,
    );
  }

  /// Header card with higher elevation
  static Widget header({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.elevated,
      elevation: 6.0,
      padding: padding ?? const EdgeInsets.all(SpacingConfig.lg),
      margin: margin ?? EdgeInsets.zero,
      shadowIntensity: 1.2,
      child: child,
    );
  }

  /// Dashboard tile card
  static Widget dashboard({
    required Widget child,
    VoidCallback? onTap,
    double? width,
    double? height,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.elevated,
      elevation: 4.0,
      width: width,
      height: height,
      padding: const EdgeInsets.all(SpacingConfig.lg),
      onTap: onTap,
      animateOnHover: onTap != null,
      borderRadius: 16.0,
      child: child,
    );
  }

  /// Input container with inset style
  static Widget input({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.inset,
      elevation: 2.0,
      padding: padding ?? const EdgeInsets.all(SpacingConfig.md),
      shadowIntensity: 0.6,
      child: child,
    );
  }

  /// Status card with custom colors
  static Widget status({
    required Widget child,
    Color? color,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return NeomorphicCard(
      style: NeomorphicCardStyle.flat,
      color: color,
      padding: padding ?? const EdgeInsets.all(SpacingConfig.md),
      margin: margin ?? EdgeInsets.zero,
      borderRadius: 8.0,
      child: child,
    );
  }
}