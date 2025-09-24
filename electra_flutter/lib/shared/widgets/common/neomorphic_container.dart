import 'package:flutter/material.dart';

/// Neomorphic container widget for modern UI design
class NeomorphicContainer extends StatelessWidget {
  const NeomorphicContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 12.0,
    this.depth = 4.0,
    this.intensity = 0.15,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double depth;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
        boxShadow: isDark
            ? [
                // Dark theme shadows
                BoxShadow(
                  color: Colors.black.withOpacity(intensity * 2),
                  offset: Offset(depth, depth),
                  blurRadius: depth * 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(intensity / 4),
                  offset: Offset(-depth / 2, -depth / 2),
                  blurRadius: depth,
                ),
              ]
            : [
                // Light theme shadows
                BoxShadow(
                  color: Colors.black.withOpacity(intensity),
                  offset: Offset(depth, depth),
                  blurRadius: depth * 2,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  offset: Offset(-depth, -depth),
                  blurRadius: depth * 2,
                ),
              ],
      ),
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}