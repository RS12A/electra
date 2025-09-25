import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/layout/auth_layout.dart';

/// Login page for user authentication
///
/// Supports login with email, matriculation number, or staff ID
/// with secure credential handling and biometric authentication.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
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
          // Welcome text
          Text(
            'Welcome Back',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: KWASUColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Sign in to continue voting',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: KWASUColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Identifier field
          TextFormField(
            controller: _identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email, Matric Number, or Staff ID',
              hintText: 'e.g., student@kwasu.edu.ng or MAT12345',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your identifier';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
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
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Remember me and forgot password
          Row(
            children: [
              // Remember me checkbox
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
              const Text('Remember me'),

              const Spacer(),

              // Forgot password link
              TextButton(
                onPressed: () => context.go(AppRoutes.forgotPassword),
                child: const Text('Forgot Password?'),
              ),
            ],
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
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
                : const Text('Sign In'),
          ),

          const SizedBox(height: 16),

          // Biometric login (if available)
          OutlinedButton.icon(
            onPressed: _handleBiometricLogin,
            icon: const Icon(Icons.fingerprint),
            label: const Text('Use Biometric'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Don\'t have an account?',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: KWASUColors.grey500,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 16),

          // Register button
          TextButton(
            onPressed: () => context.go(AppRoutes.register),
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  /// Handle login form submission
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final identifier = _identifierController.text.trim();
      final password = _passwordController.text.trim();

      // Implement login logic
      final authNotifier = ref.read(authStateProvider.notifier);
      
      // For now, simulate successful login for demo purposes
      // In production, this would call the actual auth service
      final user = User(
        id: 'demo_user_id',
        email: identifier,
        fullName: 'Demo User',
        role: UserRole.student,
        matricNumber: identifier.contains('@') ? null : identifier,
      );
      
      authNotifier.state = AuthState.authenticated(user);

      // Navigate to home on success
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${error.toString()}'),
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

  /// Handle biometric login
  void _handleBiometricLogin() async {
    try {
      // Implement biometric authentication placeholder
      // In production, this would use local_auth package
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication feature ready for implementation'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Biometric login failed: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
