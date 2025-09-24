import 'package:flutter/material.dart';

/// A neomorphic container widget that provides modern, elevated design
/// 
/// Features:
/// - Soft shadows for depth perception
/// - Configurable elevation and border radius
/// - Press state for interactive elements
/// - Theme-aware color adaptation for light/dark modes
/// - KWASU brand color integration
class NeomorphicContainer extends StatefulWidget {
  /// Creates a neomorphic container
  const NeomorphicContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12.0,
    this.elevation = 4.0,
    this.color,
    this.isPressed = false,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.shadowBlurRadius = 8.0,
    this.shadowSpreadRadius = 2.0,
    this.width,
    this.height,
  });

  /// The widget to display inside the container
  final Widget child;
  
  /// Internal padding of the container
  final EdgeInsets padding;
  
  /// External margin of the container
  final EdgeInsets margin;
  
  /// Border radius for rounded corners
  final double borderRadius;
  
  /// Elevation depth (affects shadow intensity)
  final double elevation;
  
  /// Background color (defaults to theme background)
  final Color? color;
  
  /// Whether the container appears pressed/inset
  final bool isPressed;
  
  /// Tap callback for interactive containers
  final VoidCallback? onTap;
  
  /// Animation duration for press states
  final Duration duration;
  
  /// Shadow blur radius
  final double shadowBlurRadius;
  
  /// Shadow spread radius
  final double shadowSpreadRadius;
  
  /// Container width
  final double? width;
  
  /// Container height
  final double? height;

  @override
  State<NeomorphicContainer> createState() => _NeomorphicContainerState();
}

class _NeomorphicContainerState extends State<NeomorphicContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 0.3,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color calculations for neomorphic effect
    final baseColor = widget.color ?? theme.scaffoldBackgroundColor;
    final lightShadowColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.8);
    final darkShadowColor = isDark
        ? Colors.black.withOpacity(0.8)
        : Colors.grey.shade400.withOpacity(0.6);

    return AnimatedBuilder(
      animation: _elevationAnimation,
      builder: (context, child) {
        final currentElevation = widget.isPressed || _isPressed
            ? _elevationAnimation.value
            : widget.elevation;

        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedContainer(
              duration: widget.duration,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: widget.isPressed || _isPressed
                    ? [
                        // Inset shadow effect for pressed state
                        BoxShadow(
                          color: darkShadowColor,
                          offset: Offset(currentElevation * 0.5, currentElevation * 0.5),
                          blurRadius: widget.shadowBlurRadius * 0.5,
                          spreadRadius: -widget.shadowSpreadRadius,
                          inset: true,
                        ),
                        BoxShadow(
                          color: lightShadowColor,
                          offset: Offset(-currentElevation * 0.3, -currentElevation * 0.3),
                          blurRadius: widget.shadowBlurRadius * 0.3,
                          spreadRadius: -widget.shadowSpreadRadius * 0.5,
                          inset: true,
                        ),
                      ]
                    : [
                        // Elevated shadow effect for normal state
                        BoxShadow(
                          color: darkShadowColor,
                          offset: Offset(currentElevation, currentElevation),
                          blurRadius: widget.shadowBlurRadius,
                          spreadRadius: widget.shadowSpreadRadius,
                        ),
                        BoxShadow(
                          color: lightShadowColor,
                          offset: Offset(-currentElevation * 0.5, -currentElevation * 0.5),
                          blurRadius: widget.shadowBlurRadius * 0.7,
                          spreadRadius: widget.shadowSpreadRadius * 0.5,
                        ),
                      ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// A specialized neomorphic button with KWASU theming
class NeomorphicButton extends StatelessWidget {
  const NeomorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 8.0,
    this.elevation = 3.0,
    this.color,
    this.disabledColor,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final double elevation;
  final Color? color;
  final Color? disabledColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = enabled
        ? (color ?? theme.colorScheme.primary)
        : (disabledColor ?? theme.disabledColor);

    return NeomorphicContainer(
      padding: padding,
      borderRadius: borderRadius,
      elevation: elevation,
      color: effectiveColor,
      onTap: enabled ? onPressed : null,
      child: DefaultTextStyle(
        style: TextStyle(
          color: enabled
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface.withOpacity(0.38),
          fontWeight: FontWeight.w600,
          fontFamily: 'KWASU',
        ),
        child: child,
      ),
    );
  }
}

/// A neomorphic card with enhanced styling for content display
class NeomorphicCard extends StatelessWidget {
  const NeomorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    this.borderRadius = 16.0,
    this.elevation = 6.0,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double elevation;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeomorphicContainer(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      elevation: elevation,
      color: color,
      onTap: onTap,
      child: child,
    );
  }
}

/// A neomorphic input field for forms
class NeomorphicTextField extends StatefulWidget {
  const NeomorphicTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.borderRadius = 12.0,
    this.elevation = 2.0,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final double borderRadius;
  final double elevation;

  @override
  State<NeomorphicTextField> createState() => _NeomorphicTextFieldState();
}

class _NeomorphicTextFieldState extends State<NeomorphicTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NeomorphicContainer(
      borderRadius: widget.borderRadius,
      elevation: _isFocused ? widget.elevation * 0.5 : widget.elevation,
      isPressed: _isFocused,
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        validator: widget.validator,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        onFocusChange: (focused) {
          setState(() {
            _isFocused = focused;
          });
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          filled: false,
        ),
        style: TextStyle(
          fontFamily: 'KWASU',
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}