import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Forgot password page for password recovery
///
/// Implements OTP-based password recovery flow with email verification
/// following the Django backend API pattern.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Reset Password',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: KWASUColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            _getSubtitleText(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: KWASUColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Step indicator
          _buildStepIndicator(theme),

          SizedBox(height: isTablet ? 32 : 24),

          // Content based on current step
          if (!_otpSent)
            _buildEmailStep()
          else if (!_otpVerified)
            _buildOtpStep()
          else
            _buildNewPasswordStep(),

          SizedBox(height: isTablet ? 32 : 24),

          // Action button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleAction,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_getActionButtonText()),
          ),

          const SizedBox(height: 16),

          // Back to login
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  /// Build step indicator
  Widget _buildStepIndicator(ThemeData theme) {
    return Row(
      children: [
        _buildStepDot(1, !_otpSent, theme),
        Expanded(
          child: Container(
            height: 2,
            color: _otpSent ? KWASUColors.primaryBlue : KWASUColors.grey300,
          ),
        ),
        _buildStepDot(2, _otpSent && !_otpVerified, theme),
        Expanded(
          child: Container(
            height: 2,
            color: _otpVerified ? KWASUColors.primaryBlue : KWASUColors.grey300,
          ),
        ),
        _buildStepDot(3, _otpVerified, theme),
      ],
    );
  }

  /// Build individual step dot
  Widget _buildStepDot(int step, bool isActive, ThemeData theme) {
    final isCompleted =
        (step == 1 && _otpSent) ||
        (step == 2 && _otpVerified) ||
        (step == 3 && false); // Will be completed after password reset

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? KWASUColors.success
            : isActive
            ? KWASUColors.primaryBlue
            : KWASUColors.grey300,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : KWASUColors.grey600,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  /// Build email input step
  Widget _buildEmailStep() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleAction(),
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your KWASU email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Info text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KWASUColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: KWASUColors.info, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We\'ll send a 6-digit verification code to your email address.',
                  style: TextStyle(color: KWASUColors.info, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build OTP verification step
  Widget _buildOtpStep() {
    return Column(
      children: [
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          onFieldSubmitted: (_) => _handleAction(),
          decoration: const InputDecoration(
            labelText: 'Verification Code',
            hintText: '000000',
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the verification code';
            }
            if (value.length != 6) {
              return 'Code must be 6 digits';
            }
            if (!RegExp(r'^\d{6}$').hasMatch(value)) {
              return 'Code must contain only numbers';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Resend countdown or button
        if (_resendCountdown > 0)
          Text(
            'Resend code in ${_resendCountdown}s',
            style: TextStyle(color: KWASUColors.grey500),
          )
        else
          TextButton(
            onPressed: _handleResendOtp,
            child: const Text('Resend Code'),
          ),

        const SizedBox(height: 16),

        // Info text
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: KWASUColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: KWASUColors.warning, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Code expires in 10 minutes. Check your email inbox and spam folder.',
                  style: TextStyle(color: KWASUColors.warning, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build new password step
  Widget _buildNewPasswordStep() {
    return Column(
      children: [
        // New password field
        TextFormField(
          controller: _newPasswordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'New Password',
            hintText: 'At least 8 characters',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a new password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
              return 'Password must contain uppercase, lowercase, and number';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleAction(),
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            hintText: 'Re-enter your new password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please confirm your new password';
            }
            if (value != _newPasswordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Get subtitle text based on current step
  String _getSubtitleText() {
    if (!_otpSent) {
      return 'Enter your email to receive a verification code';
    } else if (!_otpVerified) {
      return 'Enter the 6-digit code sent to ${_emailController.text}';
    } else {
      return 'Create a new secure password';
    }
  }

  /// Get action button text based on current step
  String _getActionButtonText() {
    if (!_otpSent) {
      return 'Send Code';
    } else if (!_otpVerified) {
      return 'Verify Code';
    } else {
      return 'Reset Password';
    }
  }

  /// Handle main action based on current step
  void _handleAction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (!_otpSent) {
        await _sendOtpCode();
      } else if (!_otpVerified) {
        await _verifyOtpCode();
      } else {
        await _resetPassword();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Send OTP code to email
  Future<void> _sendOtpCode() async {
    // TODO: Implement OTP sending logic
    // await ref.read(authProvider.notifier).sendOtpCode(_emailController.text);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _otpSent = true;
    });

    _startResendCountdown();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Verify OTP code
  Future<void> _verifyOtpCode() async {
    // TODO: Implement OTP verification logic
    // await ref.read(authProvider.notifier).verifyOtpCode(
    //   _emailController.text,
    //   _otpController.text,
    // );

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _otpVerified = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code verified successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Reset password with new password
  Future<void> _resetPassword() async {
    // TODO: Implement password reset logic
    // await ref.read(authProvider.notifier).resetPassword(
    //   _emailController.text,
    //   _otpController.text,
    //   _newPasswordController.text,
    // );

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please sign in.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login
      context.go(AppRoutes.login);
    }
  }

  /// Handle resend OTP
  void _handleResendOtp() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _sendOtpCode();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Start resend countdown timer
  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60; // 60 seconds
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    });
  }
}
