import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/animations.dart';

/// Enhanced neomorphic input field with fluid animations and accessibility
class NeomorphicInput extends ConsumerStatefulWidget {
  const NeomorphicInput({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorColor,
    this.onTap,
    this.autofillHints = const <String>[],
    // Neomorphic specific properties
    this.borderRadius,
    this.elevation = 3.0,
    this.padding,
    this.backgroundColor,
    this.animateFocus = true,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.shadowIntensity = 0.6,
    this.focusedElevation = 1.0,
    this.animationDuration,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final Color? cursorColor;
  final GestureTapCallback? onTap;
  final Iterable<String>? autofillHints;

  // Neomorphic properties
  final double? borderRadius;
  final double elevation;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool animateFocus;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double shadowIntensity;
  final double focusedElevation;
  final Duration? animationDuration;

  @override
  ConsumerState<NeomorphicInput> createState() => _NeomorphicInputState();
}

class _NeomorphicInputState extends ConsumerState<NeomorphicInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late FocusNode _focusNode;
  
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupAnimations();
    _setupFocusListener();
    _hasError = widget.errorText != null;
  }

  @override
  void didUpdateWidget(NeomorphicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      setState(() {
        _hasError = widget.errorText != null;
      });
    }
  }

  void _setupAnimations() {
    final themeController = ref.read(themeControllerProvider);
    final duration = widget.animationDuration ?? 
        themeController.getAnimationDuration(AnimationConfig.fastDuration);
    
    _focusController = AnimationController(
      duration: duration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.focusedElevation,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AnimationConfig.smoothCurve,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.01,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AnimationConfig.springCurve,
    ));
  }

  void _setupFocusListener() {
    _focusNode.addListener(() {
      final isFocused = _focusNode.hasFocus;
      if (_isFocused != isFocused) {
        setState(() => _isFocused = isFocused);
        
        if (widget.animateFocus) {
          if (isFocused) {
            _focusController.forward();
          } else {
            _focusController.reverse();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeControllerProvider);
    final currentTheme = themeController.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    final baseColor = widget.backgroundColor ?? AppColors.getSurfaceColor(currentTheme);
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);
    
    final borderRadius = widget.borderRadius ?? NeomorphicConfig.defaultBorderRadius;
    final padding = widget.padding ?? ResponsiveConfig.getContentPadding(screenWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: SpacingConfig.xs),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _hasError 
                    ? AppColors.error 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _focusController,
            builder: (context, child) {
              final currentElevation = widget.animateFocus
                  ? _elevationAnimation.value
                  : widget.elevation;
              final currentScale = widget.animateFocus
                  ? _scaleAnimation.value
                  : 1.0;

              return Transform.scale(
                scale: currentScale,
                child: Container(
                  decoration: _buildDecoration(
                    baseColor,
                    lightShadowColor,
                    darkShadowColor,
                    currentElevation,
                    borderRadius,
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    style: widget.style,
                    textAlign: widget.textAlign,
                    textAlignVertical: widget.textAlignVertical,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    obscureText: widget.obscureText,
                    autocorrect: widget.autocorrect,
                    enableSuggestions: widget.enableSuggestions,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    onChanged: widget.onChanged,
                    onEditingComplete: widget.onEditingComplete,
                    onSubmitted: widget.onSubmitted,
                    inputFormatters: widget.inputFormatters,
                    enabled: widget.enabled,
                    cursorWidth: widget.cursorWidth,
                    cursorColor: widget.cursorColor ?? Theme.of(context).colorScheme.primary,
                    onTap: widget.onTap,
                    autofillHints: widget.autofillHints,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: widget.prefixIcon,
                      suffixIcon: widget.suffixIcon,
                      contentPadding: padding,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: SpacingConfig.xs),
          AnimatedSwitcher(
            duration: AnimationConfig.fastDuration,
            child: Text(
              widget.errorText ?? widget.helperText ?? '',
              key: ValueKey(widget.errorText ?? widget.helperText),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _hasError 
                    ? AppColors.error 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }

  BoxDecoration _buildDecoration(
    Color baseColor,
    Color lightShadowColor,
    Color darkShadowColor,
    double elevation,
    double borderRadius,
  ) {
    final lightOffset = NeomorphicConfig.getShadowOffset(elevation * 0.3, isLight: true);
    final darkOffset = NeomorphicConfig.getShadowOffset(elevation * 0.5);
    final blurRadius = NeomorphicConfig.getBlurRadius(elevation) * 0.5;
    
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: _hasError
          ? Border.all(color: AppColors.error.withOpacity(0.5), width: 1)
          : _isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
      boxShadow: [
        // Inner shadows for inset effect
        BoxShadow(
          color: darkShadowColor.withOpacity(NeomorphicConfig.darkShadowOpacity * 0.4 * widget.shadowIntensity),
          offset: darkOffset,
          blurRadius: blurRadius * widget.shadowIntensity,
          spreadRadius: -NeomorphicConfig.defaultShadowSpread,
        ),
        BoxShadow(
          color: lightShadowColor.withOpacity(NeomorphicConfig.lightShadowOpacity * 0.3 * widget.shadowIntensity),
          offset: -lightOffset,
          blurRadius: blurRadius * 0.6 * widget.shadowIntensity,
          spreadRadius: -NeomorphicConfig.defaultShadowSpread * 0.5,
        ),
      ],
    );
  }
}

/// Specialized neomorphic input variants
class NeomorphicInputs {
  /// Standard text input
  static Widget text({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.text,
    );
  }

  /// Email input with validation
  static Widget email({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
    );
  }

  /// Password input with visibility toggle
  static Widget password({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    bool obscureText = true,
    VoidCallback? onToggleVisibility,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText ?? 'Password',
      hintText: hintText ?? 'Enter your password',
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const [AutofillHints.password],
      suffixIcon: onToggleVisibility != null
          ? IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
              ),
            )
          : null,
    );
  }

  /// Search input with search icon
  static Widget search({
    TextEditingController? controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return NeomorphicInput(
      controller: controller,
      hintText: hintText ?? 'Search...',
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: onClear != null
          ? IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
            )
          : null,
    );
  }

  /// Multiline text area
  static Widget textArea({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? helperText,
    String? errorText,
    ValueChanged<String>? onChanged,
    int maxLines = 4,
    bool enabled = true,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: maxLines,
      minLines: 3,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}