import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'theme_config.dart';

/// Custom page route transitions
class AppPageRoutes {
  /// Fade transition page route
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget child,
    RouteSettings? settings,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      reverseTransitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: AnimationConfig.easingCurve,
          ),
          child: child,
        );
      },
    );
  }

  /// Slide transition page route
  static PageRouteBuilder<T> slideTransition<T>({
    required Widget child,
    RouteSettings? settings,
    Duration? duration,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      reverseTransitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        late Offset begin;
        const Offset end = Offset.zero;

        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, 1.0);
            break;
        }

        final tween = Tween(begin: begin, end: end);
        final offsetAnimation = animation.drive(
          tween.chain(CurveTween(curve: AnimationConfig.easingCurve)),
        );

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  /// Scale transition page route
  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget child,
    RouteSettings? settings,
    Duration? duration,
    double startScale = 0.0,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      reverseTransitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: startScale,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: AnimationConfig.springCurve,
          )),
          child: child,
        );
      },
    );
  }

  /// Combined slide and fade transition
  static PageRouteBuilder<T> slideFadeTransition<T>({
    required Widget child,
    RouteSettings? settings,
    Duration? duration,
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      reverseTransitionDuration: duration ?? AnimationConfig.screenTransitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        late Offset begin;
        const Offset end = Offset.zero;

        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-0.3, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(0.3, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, -0.3);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, 0.3);
            break;
        }

        final slideAnimation = Tween(begin: begin, end: end).animate(
          CurvedAnimation(parent: animation, curve: AnimationConfig.easingCurve),
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: AnimationConfig.easingCurve,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }
}

/// Slide direction for transitions
enum SlideDirection {
  left,
  right,
  up,
  down,
}

/// Animated button with press effects
class AnimatedPressButton extends StatefulWidget {
  const AnimatedPressButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.duration,
    this.pressScale = 0.95,
    this.enabled = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Duration? duration;
  final double pressScale;
  final bool enabled;

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.microDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.easingCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onPressed != null) {
      _controller.reverse();
      widget.onPressed?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Shimmer loading animation
class AnimatedShimmer extends StatefulWidget {
  const AnimatedShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration,
    this.enabled = true,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;
  final bool enabled;

  @override
  State<AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? AnimationConfig.loadingDuration,
      vsync: this,
    );

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor = widget.baseColor ?? theme.colorScheme.surfaceVariant;
    final highlightColor = widget.highlightColor ?? 
        theme.colorScheme.surface.withOpacity(0.5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Staggered animation controller for lists
class StaggeredAnimationController {
  static List<AnimationController> createStaggeredControllers({
    required TickerProvider vsync,
    required int itemCount,
    Duration? duration,
    Duration? staggerDelay,
  }) {
    final controllers = <AnimationController>[];
    final animDuration = duration ?? AnimationConfig.screenTransitionDuration;
    final delay = staggerDelay ?? const Duration(milliseconds: 100);

    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(
        duration: animDuration,
        vsync: vsync,
      );
      controllers.add(controller);
    }

    return controllers;
  }

  static void startStaggeredAnimation({
    required List<AnimationController> controllers,
    Duration? staggerDelay,
  }) {
    final delay = staggerDelay ?? const Duration(milliseconds: 100);

    for (int i = 0; i < controllers.length; i++) {
      Future.delayed(delay * i, () {
        if (!controllers[i].isDisposed) {
          controllers[i].forward();
        }
      });
    }
  }

  static void disposeControllers(List<AnimationController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}

/// Lottie animation widget with caching and error handling
class AppLottieAnimation extends StatelessWidget {
  const AppLottieAnimation({
    super.key,
    required this.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    this.onLoaded,
    this.errorWidget,
  });

  /// Asset path (e.g., 'assets/animations/your_animation.json')
  final String asset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final LottieComposition Function(LottieComposition)? onLoaded;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      onLoaded: onLoaded,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
            Container(
              width: width ?? 100,
              height: height ?? 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.animation_outlined,
                size: (width ?? 100) * 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
      },
    );
  }
}

/// Floating Action Button with bouncy animation
class BouncyFAB extends StatefulWidget {
  const BouncyFAB({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Object? heroTag;
  final String? tooltip;

  @override
  State<BouncyFAB> createState() => _BouncyFABState();
}

class _BouncyFABState extends State<BouncyFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationConfig.microDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConfig.bounceCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onPressed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            onPressed: _handlePress,
            backgroundColor: widget.backgroundColor,
            foregroundColor: widget.foregroundColor,
            heroTag: widget.heroTag,
            tooltip: widget.tooltip,
            child: widget.child,
          ),
        );
      },
    );
  }
}