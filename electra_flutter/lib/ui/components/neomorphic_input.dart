import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';

/// Enhanced neomorphic input field with animations
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
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection,
    this.selectionControls,
    this.onTap,
    this.mouseCursor,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints = const <String>[],
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.scribbleEnabled = true,
    this.enableIMEPersonalizedLearning = true,
    // Neomorphic specific properties
    this.borderRadius = NeomorphicConfig.defaultBorderRadius,
    this.elevation = 2.0,
    this.padding = const EdgeInsets.symmetric(
      horizontal: SpacingConfig.md,
      vertical: SpacingConfig.sm,
    ),
    this.backgroundColor,
    this.animateFocus = true,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.shadowIntensity = 0.8,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final TextDirection? textDirection;
  final bool readOnly;
  final bool? showCursor;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final AppPrivateCommandCallback? onAppPrivateCommand;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final DragStartBehavior dragStartBehavior;
  final bool? enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final GestureTapCallback? onTap;
  final MouseCursor? mouseCursor;
  final InputCounterWidgetBuilder? buildCounter;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final Clip clipBehavior;
  final String? restorationId;
  final bool scribbleEnabled;
  final bool enableIMEPersonalizedLearning;

  // Neomorphic specific properties
  final double borderRadius;
  final double elevation;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final bool animateFocus;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double shadowIntensity;

  @override
  ConsumerState<NeomorphicInput> createState() => _NeomorphicInputState();
}

class _NeomorphicInputState extends ConsumerState<NeomorphicInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<double> _elevationAnimation;
  late Animation<Color?> _borderAnimation;
  late FocusNode _focusNode;
  
  bool _isFocused = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _setupAnimations();
    _setupFocusListener();
  }

  void _setupAnimations() {
    _focusController = AnimationController(
      duration: AnimationConfig.microDuration,
      vsync: this,
    );

    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.elevation * 0.5,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: AnimationConfig.easingCurve,
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
  void didUpdateWidget(NeomorphicInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update error state
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    if (_hasError != hasError) {
      setState(() => _hasError = hasError);
    }

    // Update focus node if changed
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_setupFocusListener);
      _focusNode = widget.focusNode ?? FocusNode();
      _setupFocusListener();
    }
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
    final colorScheme = AppColors.getColorScheme(currentTheme);
    
    final baseColor = widget.backgroundColor ?? AppColors.getSurfaceColor(currentTheme);
    final lightShadowColor = AppColors.getLightShadowColor(currentTheme);
    final darkShadowColor = AppColors.getDarkShadowColor(currentTheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: SpacingConfig.sm,
              bottom: SpacingConfig.xs,
            ),
            child: Text(
              widget.labelText!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: _hasError
                    ? colorScheme.error
                    : (_isFocused
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        AnimatedBuilder(
          animation: _focusController,
          builder: (context, child) {
            final currentElevation = widget.animateFocus 
                ? _elevationAnimation.value 
                : widget.elevation;

            return Container(
              decoration: _buildDecoration(
                baseColor,
                lightShadowColor,
                darkShadowColor,
                currentElevation,
                colorScheme,
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                style: widget.style,
                strutStyle: widget.strutStyle,
                textAlign: widget.textAlign,
                textAlignVertical: widget.textAlignVertical,
                textDirection: widget.textDirection,
                readOnly: widget.readOnly,
                showCursor: widget.showCursor,
                autofocus: widget.autofocus,
                obscureText: widget.obscureText,
                autocorrect: widget.autocorrect,
                smartDashesType: widget.smartDashesType,
                smartQuotesType: widget.smartQuotesType,
                enableSuggestions: widget.enableSuggestions,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                expands: widget.expands,
                maxLength: widget.maxLength,
                maxLengthEnforcement: widget.maxLengthEnforcement,
                onChanged: widget.onChanged,
                onEditingComplete: widget.onEditingComplete,
                onSubmitted: widget.onSubmitted,
                onAppPrivateCommand: widget.onAppPrivateCommand,
                inputFormatters: widget.inputFormatters,
                enabled: widget.enabled,
                cursorWidth: widget.cursorWidth,
                cursorHeight: widget.cursorHeight,
                cursorRadius: widget.cursorRadius,
                cursorColor: widget.cursorColor ?? colorScheme.primary,
                keyboardAppearance: widget.keyboardAppearance,
                scrollPadding: widget.scrollPadding,
                dragStartBehavior: widget.dragStartBehavior,
                enableInteractiveSelection: widget.enableInteractiveSelection,
                selectionControls: widget.selectionControls,
                onTap: widget.onTap,
                mouseCursor: widget.mouseCursor,
                buildCounter: widget.buildCounter,
                scrollController: widget.scrollController,
                scrollPhysics: widget.scrollPhysics,
                autofillHints: widget.autofillHints,
                clipBehavior: widget.clipBehavior,
                restorationId: widget.restorationId,
                scribbleEnabled: widget.scribbleEnabled,
                enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon,
                  suffixIcon: widget.suffixIcon,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: widget.padding,
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          const SizedBox(height: SpacingConfig.xs),
          Padding(
            padding: const EdgeInsets.only(left: SpacingConfig.sm),
            child: Text(
              widget.errorText ?? widget.helperText ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _hasError
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
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
    ColorScheme colorScheme,
  ) {
    // Build inset shadows for input feel
    final shadows = [
      BoxShadow(
        color: darkShadowColor.withOpacity(0.4 * widget.shadowIntensity),
        offset: Offset(elevation * 0.5, elevation * 0.5),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.5 * widget.shadowIntensity,
        spreadRadius: -1,
        inset: true,
      ),
      BoxShadow(
        color: lightShadowColor.withOpacity(0.2 * widget.shadowIntensity),
        offset: Offset(-elevation * 0.3, -elevation * 0.3),
        blurRadius: NeomorphicConfig.defaultShadowBlur * 0.3 * widget.shadowIntensity,
        spreadRadius: -0.5,
        inset: true,
      ),
    ];

    BoxBorder? border;
    if (_isFocused) {
      border = Border.all(
        color: _hasError ? colorScheme.error : colorScheme.primary,
        width: 2,
      );
    } else if (_hasError) {
      border = Border.all(
        color: colorScheme.error.withOpacity(0.5),
        width: 1,
      );
    }

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      boxShadow: shadows,
      border: border,
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
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      enabled: enabled,
      readOnly: readOnly,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      inputFormatters: inputFormatters,
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
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    Widget? prefixIcon,
  }) {
    return NeomorphicInput(
      controller: controller,
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'Enter your email',
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: prefixIcon ?? const Icon(Icons.email_outlined),
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
    VoidCallback? onEditingComplete,
    ValueChanged<String>? onSubmitted,
    bool enabled = true,
    Widget? prefixIcon,
  }) {
    return _PasswordInput(
      controller: controller,
      labelText: labelText ?? 'Password',
      hintText: hintText ?? 'Enter your password',
      helperText: helperText,
      errorText: errorText,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      enabled: enabled,
      prefixIcon: prefixIcon ?? const Icon(Icons.lock_outline),
    );
  }

  /// Search input
  static Widget search({
    TextEditingController? controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onClear,
    bool enabled = true,
  }) {
    return NeomorphicInput(
      controller: controller,
      hintText: hintText ?? 'Search...',
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: onClear != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
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
    int? maxLength,
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
      maxLength: maxLength,
      textAlignVertical: TextAlignVertical.top,
      padding: const EdgeInsets.all(SpacingConfig.md),
    );
  }
}

/// Password input widget with visibility toggle
class _PasswordInput extends StatefulWidget {
  const _PasswordInput({
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.enabled = true,
    this.prefixIcon,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Widget? prefixIcon;

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  @override
  Widget build(BuildContext context) {
    return NeomorphicInput(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      obscureText: _obscureText,
      textInputAction: TextInputAction.done,
      prefixIcon: widget.prefixIcon,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: _toggleVisibility,
      ),
      autofillHints: const [AutofillHints.password],
    );
  }
}