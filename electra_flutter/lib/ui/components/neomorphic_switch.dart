import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Enhanced neomorphic switch with smooth animations
class NeomorphicSwitch extends ConsumerStatefulWidget {
  const NeomorphicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.width = 50.0,
    this.height = 26.0,
    this.thumbSize,
    this.animationDuration,
    this.hapticFeedback = true,
    this.enabled = true,
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

  @override
  ConsumerState<NeomorphicSwitch> createState() => _NeomorphicSwitchState();
}

class _NeomorphicSwitchState extends ConsumerState<NeomorphicSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _thumbAnimation;
  late Animation<Color?> _trackColorAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    final duration = widget.animationDuration ?? 
        AnimationConfig.microDuration;
    
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    _thumbAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.easingCurve,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 4.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.easingCurve,
    ));

    // Set initial state
    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NeomorphicSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null) return;
    
    final newValue = !widget.value;
    widget.onChanged!(newValue);
    
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    final colorScheme = AppColors.getColorScheme(currentTheme);
    
    final activeColor = widget.activeColor ?? colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? 
        colorScheme.surfaceVariant;
    final thumbColor = widget.thumbColor ?? 
        AppColors.getSurfaceColor(currentTheme);
    
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);

    // Setup track color animation
    _trackColorAnimation = ColorTween(
      begin: inactiveColor,
      end: activeColor,
    ).animate(_controller);

    final thumbSize = widget.thumbSize ?? (widget.height - 4);
    final thumbTravel = widget.width - thumbSize - 4;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final trackColor = _trackColorAnimation.value ?? inactiveColor;
          final thumbPosition = _thumbAnimation.value * thumbTravel;
          final elevation = _elevationAnimation.value;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                // Inset shadow for track
                BoxShadow(
                  color: darkShadowColor.withOpacity(0.3),
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  spreadRadius: -1,
                  inset: true,
                ),
                BoxShadow(
                  color: lightShadowColor.withOpacity(0.2),
                  offset: const Offset(-1, -1),
                  blurRadius: 2,
                  spreadRadius: -0.5,
                  inset: true,
                ),
              ],
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: AnimationConfig.microDuration,
                  left: 2 + thumbPosition,
                  top: 2,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        // Elevated shadow for thumb
                        BoxShadow(
                          color: darkShadowColor.withOpacity(0.4),
                          offset: Offset(elevation * 0.5, elevation * 0.5),
                          blurRadius: elevation * 2,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: lightShadowColor.withOpacity(0.6),
                          offset: Offset(-elevation * 0.3, -elevation * 0.3),
                          blurRadius: elevation,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Neomorphic switch with label
class NeomorphicSwitchTile extends ConsumerWidget {
  const NeomorphicSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.leading,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.enabled = true,
    this.contentPadding,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final bool enabled;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: NeomorphicSwitch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        thumbColor: thumbColor,
        enabled: enabled,
      ),
      onTap: enabled ? () => onChanged?.call(!value) : null,
      contentPadding: contentPadding ?? 
          const EdgeInsets.symmetric(
            horizontal: SpacingConfig.md,
            vertical: SpacingConfig.sm,
          ),
      enabled: enabled,
    );
  }
}

/// Toggle button with neomorphic styling
class NeomorphicToggleButton extends ConsumerStatefulWidget {
  const NeomorphicToggleButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
    required this.child,
    this.selectedColor,
    this.unselectedColor,
    this.width,
    this.height = 40.0,
    this.borderRadius = 8.0,
    this.enabled = true,
    this.hapticFeedback = true,
  });

  final bool isSelected;
  final VoidCallback? onPressed;
  final Widget child;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool enabled;
  final bool hapticFeedback;

  @override
  ConsumerState<NeomorphicToggleButton> createState() => 
      _NeomorphicToggleButtonState();
}

class _NeomorphicToggleButtonState extends ConsumerState<NeomorphicToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: AnimationConfig.microDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: NeomorphicConfig.defaultElevation,
      end: NeomorphicConfig.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.easingCurve,
    ));

    // Set initial state
    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(NeomorphicToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onPressed == null) return;
    
    widget.onPressed!();
    
    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    final colorScheme = AppColors.getColorScheme(currentTheme);
    
    final selectedColor = widget.selectedColor ?? colorScheme.primary;
    final unselectedColor = widget.unselectedColor ?? 
        AppColors.getSurfaceColor(currentTheme);
    
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);

    // Setup color animation
    _colorAnimation = ColorTween(
      begin: unselectedColor,
      end: selectedColor,
    ).animate(_controller);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final backgroundColor = _colorAnimation.value ?? unselectedColor;
          final elevation = widget.isSelected 
              ? NeomorphicConfig.pressedElevation 
              : _elevationAnimation.value;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.isSelected
                  ? _buildInsetShadows(lightShadowColor, darkShadowColor, elevation)
                  : _buildElevatedShadows(lightShadowColor, darkShadowColor, elevation),
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: AnimationConfig.microDuration,
                style: TextStyle(
                  color: widget.isSelected 
                      ? colorScheme.onPrimary 
                      : colorScheme.onSurface,
                  fontWeight: widget.isSelected 
                      ? FontWeight.w600 
                      : FontWeight.w500,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
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

/// Toggle buttons group with neomorphic styling
class NeomorphicToggleButtons extends ConsumerWidget {
  const NeomorphicToggleButtons({
    super.key,
    required this.children,
    required this.isSelected,
    required this.onPressed,
    this.direction = Axis.horizontal,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = 8.0,
    this.spacing = 4.0,
    this.constraints,
  });

  final List<Widget> children;
  final List<bool> isSelected;
  final void Function(int index)? onPressed;
  final Axis direction;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double borderRadius;
  final double spacing;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(children.length == isSelected.length);

    return Flex(
      direction: direction,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(children.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            right: direction == Axis.horizontal && index < children.length - 1 
                ? spacing : 0,
            bottom: direction == Axis.vertical && index < children.length - 1 
                ? spacing : 0,
          ),
          child: ConstrainedBox(
            constraints: constraints ?? const BoxConstraints(),
            child: NeomorphicToggleButton(
              isSelected: isSelected[index],
              onPressed: onPressed != null ? () => onPressed!(index) : null,
              selectedColor: selectedColor,
              unselectedColor: unselectedColor,
              borderRadius: borderRadius,
              child: children[index],
            ),
          ),
        );
      }),
    );
  }
}