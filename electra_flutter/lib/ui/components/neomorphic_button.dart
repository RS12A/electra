import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/animations.dart';

/// Enhanced neomorphic button with animations and accessibility
class NeomorphicButton extends ConsumerStatefulWidget {
  const NeomorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = NeomorphicConfig.defaultBorderRadius,
    this.elevation = NeomorphicConfig.defaultElevation,
    this.color,
    this.shadowColor,
    this.disabledColor,
    this.enabled = true,
    this.style = NeomorphicButtonStyle.elevated,
    this.animationType = NeomorphicAnimationType.press,
    this.hapticFeedback = true,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;
  final Color? color;
  final Color? shadowColor;
  final Color? disabledColor;
  final bool enabled;
  final NeomorphicButtonStyle style;
  final NeomorphicAnimationType animationType;
  final bool hapticFeedback;
  final String? tooltip;

  @override
  ConsumerState<NeomorphicButton> createState() => _NeomorphicButtonState();
}

class _NeomorphicButtonState extends ConsumerState<NeomorphicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: AnimationConfig.microDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.easingCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: NeomorphicConfig.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AnimationConfig.easingCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    
    setState(() => _isPressed = true);
    
    if (widget.animationType == NeomorphicAnimationType.press) {
      _animationController.forward();
    }
    
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;
    
    setState(() => _isPressed = false);
    
    if (widget.animationType == NeomorphicAnimationType.press) {
      _animationController.reverse();
    }
    
    // Delay the callback slightly for visual feedback
    Future.delayed(const Duration(milliseconds: 50), () {
      widget.onPressed?.call();
    });
    
    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    
    setState(() => _isPressed = false);
    
    if (widget.animationType == NeomorphicAnimationType.press) {
      _animationController.reverse();
    }
  }

  void _handleHover(bool isHovered) {
    if (!widget.enabled) return;
    
    setState(() => _isHovered = isHovered);
    
    if (widget.animationType == NeomorphicAnimationType.hover && isHovered) {
      _animationController.forward();
    } else if (widget.animationType == NeomorphicAnimationType.hover && !isHovered) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    
    final baseColor = widget.color ?? 
        AppColors.getSurfaceColor(currentTheme);
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);
    
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: Tooltip(
          message: widget.tooltip ?? '',
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final currentElevation = widget.animationType == NeomorphicAnimationType.press
                  ? _elevationAnimation.value
                  : (_isHovered ? widget.elevation * 1.2 : widget.elevation);
              
              final scale = widget.animationType == NeomorphicAnimationType.press
                  ? _scaleAnimation.value
                  : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  padding: widget.padding,
                  decoration: _buildDecoration(
                    baseColor,
                    lightShadowColor,
                    darkShadowColor,
                    currentElevation,
                  ),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: widget.enabled ? 1.0 : 0.6,
                      duration: AnimationConfig.microDuration,
                      child: widget.child,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(
    Color baseColor,
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
  ) {
    switch (widget.style) {
      case NeomorphicButtonStyle.elevated:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? _buildInsetShadows(lightShadowColor, darkShadowColor, elevation)
              : _buildElevatedShadows(lightShadowColor, darkShadowColor, elevation),
        );
      
      case NeomorphicButtonStyle.inset:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _buildInsetShadows(lightShadowColor, darkShadowColor, elevation),
        );
      
      case NeomorphicButtonStyle.flat:
        return BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: darkShadowColor.withOpacity(0.2),
            width: 1,
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
        color: darkShadowColor,
        offset: Offset(elevation, elevation),
        blurRadius: NeomorphicConfig.defaultShadowBlur,
        spreadRadius: NeomorphicConfig.defaultShadowSpread,
      ),
      BoxShadow(
        color: lightShadowColor,
        offset: Offset(-elevation * 0.5, -elevation * 0.5),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.7,
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
        color: darkShadowColor,
        offset: Offset(elevation * 0.5, elevation * 0.5),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.5,
        spreadRadius: -NeomorphicConfig.defaultShadowSpread,
        inset: true,
      ),
      BoxShadow(
        color: lightShadowColor,
        offset: Offset(-elevation * 0.3, -elevation * 0.3),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.3,
        spreadRadius: -NeomorphicConfig.defaultShadowSpread * 0.5,
        inset: true,
      ),
    ];
  }
}

/// Neomorphic button styles
enum NeomorphicButtonStyle {
  elevated,
  inset,
  flat,
}

/// Neomorphic animation types
enum NeomorphicAnimationType {
  press,
  hover,
  none,
}

/// Preset neomorphic button variants
class NeomorphicButtons {
  /// Primary action button
  static Widget primary({
    required VoidCallback? onPressed,
    required Widget child,
    bool enabled = true,
    String? tooltip,
  }) {
    return NeomorphicButton(
      onPressed: onPressed,
      enabled: enabled,
      tooltip: tooltip,
      style: NeomorphicButtonStyle.elevated,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConfig.lg,
        vertical: SpacingConfig.md,
      ),
      child: child,
    );
  }

  /// Secondary action button
  static Widget secondary({
    required VoidCallback? onPressed,
    required Widget child,
    bool enabled = true,
    String? tooltip,
  }) {
    return NeomorphicButton(
      onPressed: onPressed,
      enabled: enabled,
      tooltip: tooltip,
      style: NeomorphicButtonStyle.flat,
      elevation: 2.0,
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingConfig.lg,
        vertical: SpacingConfig.md,
      ),
      child: child,
    );
  }

  /// Icon button
  static Widget icon({
    required VoidCallback? onPressed,
    required Widget icon,
    bool enabled = true,
    String? tooltip,
    double size = 48.0,
  }) {
    return NeomorphicButton(
      onPressed: onPressed,
      enabled: enabled,
      tooltip: tooltip,
      width: size,
      height: size,
      padding: EdgeInsets.all(SpacingConfig.sm),
      borderRadius: size / 2,
      style: NeomorphicButtonStyle.elevated,
      child: icon,
    );
  }

  /// Floating action button
  static Widget fab({
    required VoidCallback? onPressed,
    required Widget child,
    bool enabled = true,
    String? tooltip,
    double size = 56.0,
  }) {
    return NeomorphicButton(
      onPressed: onPressed,
      enabled: enabled,
      tooltip: tooltip,
      width: size,
      height: size,
      padding: EdgeInsets.all(SpacingConfig.md),
      borderRadius: size / 2,
      elevation: 6.0,
      style: NeomorphicButtonStyle.elevated,
      animationType: NeomorphicAnimationType.press,
      child: child,
    );
  }
}