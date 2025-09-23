import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Auth layout wrapper for login, register, and forgot password pages
///
/// Provides a consistent layout for authentication screens with
/// KWASU branding and responsive design.
class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: KWASUColors.primaryBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // Background pattern
            _buildBackground(),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 48.0 : 24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and branding
                        _buildHeader(theme, isTablet),

                        SizedBox(height: isTablet ? 48 : 32),

                        // Auth form card
                        Card(
                          elevation: 8,
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                            child: child,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Footer
                        _buildFooter(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build background pattern
  Widget _buildBackground() {
    return Positioned.fill(
      child: CustomPaint(painter: AuthBackgroundPainter()),
    );
  }

  /// Build header with logo and title
  Widget _buildHeader(ThemeData theme, bool isTablet) {
    return Column(
      children: [
        // University logo placeholder
        Container(
          width: isTablet ? 120 : 80,
          height: isTablet ? 120 : 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.how_to_vote,
            size: isTablet ? 60 : 40,
            color: KWASUColors.primaryBlue,
          ),
        ),

        SizedBox(height: isTablet ? 24 : 16),

        // App title
        Text(
          'Electra',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'KWASU',
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Secure Digital Voting System',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 4),

        // University name
        Text(
          'Kwara State University',
          style: TextStyle(
            color: Colors.white60,
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Build footer with support info
  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        // Support text
        Text(
          'Need help? Contact Electoral Committee',
          style: TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // App version
        Text(
          'Version 1.0.0',
          style: TextStyle(color: Colors.white50, fontSize: 10),
        ),
      ],
    );
  }
}

/// Custom painter for auth background pattern
class AuthBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw subtle grid pattern
    final gridSize = 50.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some decorative circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      100,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.8),
      120,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
