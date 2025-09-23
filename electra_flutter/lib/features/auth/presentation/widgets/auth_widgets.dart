import 'package:flutter/material.dart';

/// Custom neomorphic input field widget for authentication forms
///
/// Provides a modern, depth-based design following neomorphic principles
/// with proper accessibility support and validation.
class NeomorphicTextFormField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final int? maxLength;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final Key? fieldKey;

  const NeomorphicTextFormField({
    Key? key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.fieldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Outer shadow (darker, bottom-right)
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          // Inner shadow (lighter, top-left)
          BoxShadow(
            color: isDark 
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.8),
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        maxLength: maxLength,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        enabled: enabled,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          counterText: '', // Hide character counter
          filled: true,
          fillColor: isDark 
              ? theme.colorScheme.surface
              : Colors.grey.shade50,
          
          // Remove default borders to use our neomorphic design
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1,
            ),
          ),
          
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        
        // Accessibility
        semanticsLabel: labelText,
      ),
    );
  }
}

/// Custom neomorphic elevated button
class NeomorphicElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Size? minimumSize;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;

  const NeomorphicElevatedButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.minimumSize,
    this.padding,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isEnabled 
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                colors: [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
              ),
        boxShadow: isEnabled ? [
          // Outer shadow
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          // Inner highlight
          BoxShadow(
            color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
            offset: const Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ] : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(
              minHeight: minimumSize?.height ?? 48,
              minWidth: minimumSize?.width ?? double.infinity,
            ),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : DefaultTextStyle(
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: isEnabled 
                            ? theme.colorScheme.onPrimary 
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated error message widget
class AnimatedErrorMessage extends StatelessWidget {
  final String? error;
  final Duration duration;

  const AnimatedErrorMessage({
    Key? key,
    this.error,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: duration,
      height: error != null ? null : 0,
      child: AnimatedOpacity(
        duration: duration,
        opacity: error != null ? 1.0 : 0.0,
        child: error != null
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Animated success message widget
class AnimatedSuccessMessage extends StatelessWidget {
  final String? message;
  final Duration duration;

  const AnimatedSuccessMessage({
    Key? key,
    this.message,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: duration,
      height: message != null ? null : 0,
      child: AnimatedOpacity(
        duration: duration,
        opacity: message != null ? 1.0 : 0.0,
        child: message != null
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Biometric prompt button with animation
class BiometricButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final String label;

  const BiometricButton({
    Key? key,
    this.onPressed,
    this.isEnabled = true,
    this.label = 'Use Biometric',
  }) : super(key: key);

  @override
  State<BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<BiometricButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.isEnabled ? _onTapDown : null,
            onTapUp: widget.isEnabled ? _onTapUp : null,
            onTapCancel: _onTapCancel,
            onTap: widget.isEnabled ? widget.onPressed : null,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isEnabled 
                      ? theme.colorScheme.primary 
                      : Colors.grey.shade400,
                  width: 1.5,
                ),
                color: Colors.transparent,
                boxShadow: widget.isEnabled ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: widget.isEnabled 
                        ? theme.colorScheme.primary 
                        : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: widget.isEnabled 
                          ? theme.colorScheme.primary 
                          : Colors.grey.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}