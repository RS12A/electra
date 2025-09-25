import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/animations.dart';

/// Enhanced neomorphic switch with smooth animations and accessibility
class NeomorphicSwitch extends ConsumerStatefulWidget {
  const NeomorphicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.width = 56.0,
    this.height = 28.0,
    this.thumbSize,
    this.animationDuration,
    this.hapticFeedback = true,
    this.enabled = true,
    this.label,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double width;
  final double height;
  final double? thumbSize;
  final Duration? animationDuration;
  final bool hapticFeedback;
  final bool enabled;
  final String? label;
  final String? semanticLabel;

  @override
  ConsumerState<NeomorphicSwitch> createState() => _NeomorphicSwitchState();
}

class _NeomorphicSwitchState extends ConsumerState<NeomorphicSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  late Animation<Color?> _trackColorAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    
    // Set initial state
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NeomorphicSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _setupAnimations() {
    final themeController = ref.read(themeControllerProvider);
    final duration = widget.animationDuration ?? 
        themeController.getAnimationDuration(AnimationConfig.fastDuration);
    
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _thumbAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.springCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.easingCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.sharpCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null) return;

    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }

    widget.onChanged!(!widget.value);
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    
    final baseColor = AppColors.getSurfaceColor(currentTheme);
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);
    
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? baseColor;
    final thumbColor = widget.thumbColor ?? AppColors.getSurfaceColor(currentTheme);
    final thumbSize = widget.thumbSize ?? (widget.height - 6);

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      value: widget.value ? 'On' : 'Off',
      toggled: widget.value,
      onTap: _handleTap,
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final trackColor = Color.lerp(
                inactiveColor,
                activeColor,
                _thumbAnimation.value,
              )!;

              return AnimatedScale(
                scale: _isPressed ? 0.98 : 1.0,
                duration: AnimationConfig.microDuration,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: _buildTrackDecoration(
                    trackColor,
                    lightShadowColor,
                    darkShadowColor,
                  ),
                  child: Stack(
                    children: [
                      // Thumb
                      AnimatedAlign(
                        alignment: Alignment.lerp(
                          Alignment.centerLeft,
                          Alignment.centerRight,
                          _thumbAnimation.value,
                        )!,
                        duration: Duration.zero, // Animation handled by controller
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          margin: const EdgeInsets.all(3),
                          decoration: _buildThumbDecoration(
                            thumbColor,
                            lightShadowColor,
                            darkShadowColor,
                            _elevationAnimation.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildTrackDecoration(
    Color trackColor,
    Color lightShadowColor,
    Color darkShadowColor,
  ) {
    final lightOffset = NeomorphicConfig.getShadowOffset(1.0, isLight: true);
    final darkOffset = NeomorphicConfig.getShadowOffset(1.0);
    
    return BoxDecoration(
      color: trackColor,
      borderRadius: BorderRadius.circular(widget.height / 2),
      boxShadow: [
        // Inner shadows for inset effect
        BoxShadow(
          color: darkShadowColor.withOpacity(0.3),
          offset: darkOffset,
          blurRadius: 4.0,
          spreadRadius: -1.0,
        ),
        BoxShadow(
          color: lightShadowColor.withOpacity(0.2),
          offset: -lightOffset,
          blurRadius: 3.0,
          spreadRadius: -0.5,
        ),
      ],
    );
  }

  BoxDecoration _buildThumbDecoration(
    Color thumbColor,
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
  ) {
    final lightOffset = NeomorphicConfig.getShadowOffset(elevation, isLight: true);
    final darkOffset = NeomorphicConfig.getShadowOffset(elevation);
    final blurRadius = NeomorphicConfig.getBlurRadius(elevation);
    
    return BoxDecoration(
      color: thumbColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: darkShadowColor.withOpacity(NeomorphicConfig.darkShadowOpacity),
          offset: darkOffset,
          blurRadius: blurRadius,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: lightShadowColor.withOpacity(NeomorphicConfig.lightShadowOpacity),
          offset: lightOffset,
          blurRadius: blurRadius * 0.7,
          spreadRadius: 0,
        ),
      ],
    );
  }
}

/// Specialized neomorphic switch variants with labels
class NeomorphicSwitches {
  /// Switch with trailing label
  static Widget withLabel({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String label,
    bool enabled = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        NeomorphicSwitch(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
          label: label,
        ),
        const SizedBox(width: SpacingConfig.sm),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: enabled 
                  ? null 
                  : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  /// Switch with leading label
  static Widget withLeadingLabel({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String label,
    bool enabled = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: enabled 
                  ? null 
                  : Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: SpacingConfig.sm),
        NeomorphicSwitch(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
          label: label,
        ),
      ],
    );
  }

  /// Switch with title and subtitle
  static Widget withDescription({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String title,
    String? subtitle,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: enabled 
                      ? null 
                      : Colors.grey,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled 
                        ? Colors.grey[600] 
                        : Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: SpacingConfig.md),
        NeomorphicSwitch(
          value: value,
          onChanged: onChanged,
          enabled: enabled,
          label: title,
        ),
      ],
    );
  }

  /// List tile style switch
  static Widget listTile({
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String title,
    String? subtitle,
    Widget? leading,
    bool enabled = true,
    EdgeInsets? padding,
  }) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: SpacingConfig.md,
        vertical: SpacingConfig.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: SpacingConfig.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: enabled 
                        ? null 
                        : Colors.grey,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: enabled 
                          ? Colors.grey[600] 
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: SpacingConfig.md),
          NeomorphicSwitch(
            value: value,
            onChanged: onChanged,
            enabled: enabled,
            label: title,
          ),
        ],
      ),
    );
  }
}