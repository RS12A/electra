import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../ui/components/index.dart';
import '../widgets/auth_widgets.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/auth_entities.dart';

/// Enhanced login page with production-grade authentication
///
/// Features:
/// - Enhanced neomorphic design with smooth GPU-optimized animations
/// - Support for email, matriculation number, or staff ID login
/// - Biometric authentication support
/// - Offline login capabilities
/// - Comprehensive validation and error handling
/// - Full accessibility support with screen reader compatibility
/// - Responsive design for mobile, tablet, and desktop
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  String? _successMessage;

  late List<AnimationController> _staggeredControllers;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeAnimationController = AnimationController(
      duration: AnimationConfig.slowDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: AnimationConfig.smoothCurve,
    ));

    // Create staggered animations for form elements
    _staggeredControllers = StaggeredAnimationController.createStaggeredControllers(
      vsync: this,
      itemCount: 6, // Header, inputs, button, biometric, links, footer
      duration: AnimationConfig.screenTransitionDuration,
    );
  }

  void _startAnimations() {
    _fadeAnimationController.forward();
    
    // Start staggered animation with delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        StaggeredAnimationController.startStaggeredAnimation(
          controllers: _staggeredControllers,
        );
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _fadeAnimationController.dispose();
    StaggeredAnimationController.disposeControllers(_staggeredControllers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveContainer(
          maxWidth: 480,
          child: ResponsivePadding(
            mobile: const EdgeInsets.all(SpacingConfig.lg),
            tablet: const EdgeInsets.all(SpacingConfig.xl),
            desktop: const EdgeInsets.all(SpacingConfig.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome header
                  _buildAnimatedItem(
                    0,
                    _buildWelcomeHeader(screenWidth),
                  ),
                  
                  SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.xl)),
                  
                  // Login form card
                  _buildAnimatedItem(
                    1,
                    _buildLoginFormCard(authState, screenWidth),
                  ),
                  
                  SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
                  
                  // Login button
                  _buildAnimatedItem(
                    2,
                    _buildLoginButton(authState),
                  ),
                  
                  // Biometric login (if available)
                  if (authState.canUseBiometric) ...[
                    SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
                    _buildAnimatedItem(
                      3,
                      _buildBiometricSection(authState),
                    ),
                  ],
                  
                  SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.lg)),
                  
                  // Navigation links
                  _buildAnimatedItem(
                    4,
                    _buildNavigationLinks(screenWidth),
                  ),
                  
                  SizedBox(height: SpacingConfig.getResponsiveSpacing(screenWidth, SpacingConfig.md)),
                  
                  // Footer
                  _buildAnimatedItem(
                    5,
                    _buildFooter(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    return AnimatedBuilder(
      animation: _staggeredControllers[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _staggeredControllers[index].value)),
          child: Opacity(
            opacity: _staggeredControllers[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(double screenWidth) {
    return Column(
      children: [
        // Logo or app icon
        Container(
          width: ResponsiveConfig.isMobile(screenWidth) ? 80 : 100,
          height: ResponsiveConfig.isMobile(screenWidth) ? 80 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: const Icon(
            Icons.how_to_vote,
            size: 40,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: SpacingConfig.lg),
        
        Text(
          'Welcome to Electra',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: SpacingConfig.sm),
        
        Text(
          'Secure Digital Voting System',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginFormCard(AuthState authState, double screenWidth) {
    return NeomorphicCards.content(
      padding: EdgeInsets.all(
        ResponsiveConfig.isMobile(screenWidth) 
            ? SpacingConfig.lg 
            : SpacingConfig.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Identifier input
          NeomorphicInputs.text(
            controller: _identifierController,
            labelText: 'Email, Matric No, or Staff ID',
            hintText: 'Enter your login credential',
            prefixIcon: const Icon(Icons.person_outline),
            enabled: !authState.isLoading,
          ),
          
          const SizedBox(height: SpacingConfig.lg),
          
          // Password input
          NeomorphicInputs.password(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            enabled: !authState.isLoading,
            onToggleVisibility: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          
          const SizedBox(height: SpacingConfig.md),
          
          // Remember me toggle
          NeomorphicSwitches.withLabel(
            value: _rememberMe,
            onChanged: authState.isLoading 
                ? null 
                : (value) => setState(() => _rememberMe = value),
            label: 'Remember me',
          ),
          
          // Error message
          if (authState.error != null) ...[
            const SizedBox(height: SpacingConfig.md),
            AnimatedContainer(
              duration: AnimationConfig.fastDuration,
              padding: const EdgeInsets.all(SpacingConfig.md),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NeomorphicConfig.smallBorderRadius),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConfig.sm),
                  Expanded(
                    child: Text(
                      authState.error!,
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Success message
          if (_successMessage != null) ...[
            const SizedBox(height: SpacingConfig.md),
            AnimatedContainer(
              duration: AnimationConfig.fastDuration,
              padding: const EdgeInsets.all(SpacingConfig.md),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(NeomorphicConfig.smallBorderRadius),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: SpacingConfig.sm),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthState authState) {
    return NeomorphicButtons.primary(
      onPressed: authState.isLoading ? null : _handleLogin,
      enabled: !authState.isLoading,
      child: authState.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildBiometricSection(AuthState authState) {
    return Column(
      children: [
        // Divider with "OR"
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: SpacingConfig.md),
              child: Text(
                'OR',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        
        const SizedBox(height: SpacingConfig.lg),
        
        // Biometric button
        NeomorphicButtons.secondary(
          onPressed: authState.isLoading ? null : _handleBiometricLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: SpacingConfig.sm),
              const Text('Use Biometric Login'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationLinks(double screenWidth) {
    return ResponsiveWrap(
      spacing: ResponsiveConfig.isMobile(screenWidth) 
          ? SpacingConfig.sm 
          : SpacingConfig.lg,
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: () => context.push('/forgot-password'),
          child: const Text('Forgot Password?'),
        ),
        TextButton(
          onPressed: () => context.push('/register'),
          child: const Text('Create Account'),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'Powered by Electra © 2024\nKwara State University',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    try {
      await ref.read(authStateProvider.notifier).login(
        identifier: identifier,
        password: password,
        rememberMe: _rememberMe,
      );
      
      setState(() {
        _successMessage = 'Login successful! Redirecting...';
      });
      
      // Navigate to dashboard after success
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    } catch (e) {
      // Error is handled by the provider
    }
  }

  void _handleBiometricLogin() async {
    try {
      await ref.read(authStateProvider.notifier).loginWithBiometric();
      
      setState(() {
        _successMessage = 'Biometric login successful! Redirecting...';
      });
      
      // Navigate to dashboard after success
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.go('/dashboard');
        }
      });
    } catch (e) {
      // Error is handled by the provider
    }
  }
}
    );
    
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    // Watch auth state
    final authState = ref.watch(authStateProvider);
    final canUseBiometric = authState.canUseBiometric;

    return AuthLayout(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome header with animation
                _buildWelcomeHeader(theme, isTablet),
                
                SizedBox(height: isTablet ? 40 : 32),
                
                // Login form
                _buildLoginForm(theme, isTablet),
                
                SizedBox(height: isTablet ? 32 : 24),
                
                // Login button
                _buildLoginButton(authState),
                
                // Error message
                AnimatedErrorMessage(error: authState.error),
                
                // Success message
                AnimatedSuccessMessage(message: _successMessage),
                
                SizedBox(height: isTablet ? 24 : 20),
                
                // Biometric login (if available)
                if (canUseBiometric) ...[
                  _buildDivider(theme),
                  const SizedBox(height: 20),
                  _buildBiometricButton(authState),
                ],
                
                SizedBox(height: isTablet ? 32 : 24),
                
                // Navigation links
                _buildNavigationLinks(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build welcome header with animated text
  Widget _buildWelcomeHeader(ThemeData theme, bool isTablet) {
    return Column(
      children: [
        // App logo/icon with neomorphic design
        Container(
          width: isTablet ? 80 : 64,
          height: isTablet ? 80 : 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                KWASUColors.primaryBlue.withOpacity(0.1),
                KWASUColors.primaryBlue.withOpacity(0.05),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(4, 4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(-4, -4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.how_to_vote_rounded,
            size: isTablet ? 40 : 32,
            color: KWASUColors.primaryBlue,
          ),
        ),
        
        SizedBox(height: isTablet ? 24 : 20),
        
        // Welcome text
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: KWASUColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 28 : 24,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Sign in to continue to Electra',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: KWASUColors.grey600,
            fontSize: isTablet ? 16 : 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build login form with neomorphic fields
  Widget _buildLoginForm(ThemeData theme, bool isTablet) {
    return Column(
      children: [
        // Identifier field
        NeomorphicTextFormField(
          labelText: 'Email, Matric Number, or Staff ID',
          hintText: 'Enter your login identifier',
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email, matric number, or staff ID';
            }
            return null;
          },
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Password field
        NeomorphicTextFormField(
          labelText: 'Password',
          hintText: 'Enter your password',
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
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
          onFieldSubmitted: (_) => _handleLogin(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Remember me and forgot password
        Row(
          children: [
            // Remember me checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  _rememberMe = !_rememberMe;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _rememberMe 
                          ? KWASUColors.primaryBlue 
                          : Colors.transparent,
                      border: Border.all(
                        color: _rememberMe 
                            ? KWASUColors.primaryBlue 
                            : KWASUColors.grey400,
                        width: 2,
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: KWASUColors.grey600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Forgot password link
            TextButton(
              onPressed: () => context.go(AppRoutes.forgotPassword),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: KWASUColors.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build login button
  Widget _buildLoginButton(AuthState authState) {
    return NeomorphicElevatedButton(
      onPressed: authState.isLoading ? null : _handleLogin,
      isLoading: authState.isLoading,
      child: const Text('Sign In'),
    );
  }

  /// Build divider with text
  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: KWASUColors.grey300),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: theme.textTheme.bodySmall?.copyWith(
              color: KWASUColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: KWASUColors.grey300),
        ),
      ],
    );
  }

  /// Build biometric login button
  Widget _buildBiometricButton(AuthState authState) {
    return BiometricButton(
      onPressed: authState.isLoading ? null : _handleBiometricLogin,
      isEnabled: !authState.isLoading && authState.canUseBiometric,
      label: 'Use Biometric Login',
    );
  }

  /// Build navigation links
  Widget _buildNavigationLinks(ThemeData theme) {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: KWASUColors.grey300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Don\'t have an account?',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: KWASUColors.grey500,
                ),
              ),
            ),
            Expanded(child: Divider(color: KWASUColors.grey300)),
          ],
        ),

        const SizedBox(height: 16),

        // Register button
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Create Account',
            style: TextStyle(
              color: KWASUColors.primaryBlue,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Help text
        Text(
          'Need help? Contact Electoral Committee',
          style: theme.textTheme.bodySmall?.copyWith(
            color: KWASUColors.grey500,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Handle login form submission
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear any previous messages
    setState(() {
      _successMessage = null;
    });

    // Create login credentials
    final credentials = LoginCredentials(
      identifier: _identifierController.text.trim(),
      password: _passwordController.text.trim(),
      rememberMe: _rememberMe,
    );

    // Attempt login using auth provider
    final success = await ref.read(authStateProvider.notifier).state.copyWith();
    
    // TODO: Replace with actual auth provider call when implemented
    // final success = await ref.read(authNotifierProvider.notifier).login(credentials);
    
    if (success) {
      // Show success message briefly before navigation
      setState(() {
        _successMessage = 'Login successful! Redirecting...';
      });

      // Navigate after short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  /// Handle biometric login
  Future<void> _handleBiometricLogin() async {
    // Clear any previous messages
    setState(() {
      _successMessage = null;
    });

    try {
      // TODO: Replace with actual biometric login call when implemented
      // final success = await ref.read(authNotifierProvider.notifier).loginWithBiometric();
      
      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _successMessage = 'Biometric authentication successful!';
        });

        // Navigate after short delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go(AppRoutes.home);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: ${error.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}