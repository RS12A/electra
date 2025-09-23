import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vote.dart';
import '../../domain/entities/election.dart';
import '../../../../core/theme/app_theme.dart';

/// Vote confirmation screen with anonymized summary
///
/// Shows successful vote submission, anonymized details,
/// and countdown to next election with neomorphic design.
class VoteConfirmationPage extends ConsumerStatefulWidget {
  final VoteConfirmation confirmation;
  final Election? election;

  const VoteConfirmationPage({
    super.key,
    required this.confirmation,
    this.election,
  });

  @override
  ConsumerState<VoteConfirmationPage> createState() => _VoteConfirmationPageState();
}

class _VoteConfirmationPageState extends ConsumerState<VoteConfirmationPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _startAnimations();
    _showSuccessHaptics();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    // Auto-show details after initial animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showDetails = true);
      }
    });
  }

  void _showSuccessHaptics() {
    // Success haptic feedback pattern
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.lightImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Vote Confirmed'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.close),
          tooltip: 'Return to Dashboard',
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
            child: Column(
              children: [
                // Success animation and message
                _buildSuccessHeader(theme, isTablet),
                
                const SizedBox(height: 32),
                
                // Vote details
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: _showDetails 
                      ? _buildVoteDetails(theme, isTablet)
                      : const SizedBox.shrink(),
                ),
                
                if (_showDetails) ...[
                  const SizedBox(height: 24),
                  
                  // Security information
                  _buildSecurityInfo(theme, isTablet),
                  
                  const SizedBox(height: 24),
                  
                  // Next election info
                  if (widget.confirmation.nextElectionDate != null)
                    _buildNextElectionInfo(theme, isTablet),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  _buildActionButtons(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessHeader(ThemeData theme, bool isTablet) {
    return Column(
      children: [
        // Animated success icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          child: Container(
            width: isTablet ? 120 : 100,
            height: isTablet ? 120 : 100,
            decoration: BoxDecoration(
              color: KWASUColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: KWASUColors.success.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.verified,
              size: isTablet ? 60 : 50,
              color: KWASUColors.success,
            ),
          ),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Success message
        Text(
          'Vote Successfully Cast!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: KWASUColors.success,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Your vote has been securely encrypted and recorded.\nThank you for participating in the democratic process.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: KWASUColors.grey600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVoteDetails(ThemeData theme, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _buildNeomorphicDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: KWASUColors.primaryBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Vote Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KWASUColors.primaryBlue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildDetailRow(
            'Confirmation ID',
            widget.confirmation.confirmationId,
            theme,
            copyable: true,
          ),
          
          _buildDetailRow(
            'Election',
            widget.confirmation.electionTitle,
            theme,
          ),
          
          _buildDetailRow(
            'Vote Token',
            _maskToken(widget.confirmation.voteToken),
            theme,
            subtitle: 'Use this to verify your vote later',
          ),
          
          _buildDetailRow(
            'Timestamp',
            _formatDateTime(widget.confirmation.timestamp),
            theme,
          ),
          
          _buildDetailRow(
            'Positions Voted',
            '${widget.confirmation.positionsVoted} of ${widget.confirmation.totalPositions}',
            theme,
          ),
          
          const SizedBox(height: 16),
          
          // Verification QR code section
          if (widget.confirmation.verificationCode != null)
            _buildVerificationSection(theme),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme, {
    String? subtitle,
    bool copyable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: KWASUColors.grey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (copyable)
                      IconButton(
                        onPressed: () => _copyToClipboard(value),
                        icon: Icon(
                          Icons.copy,
                          size: 16,
                          color: KWASUColors.primaryBlue,
                        ),
                        tooltip: 'Copy to clipboard',
                      ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: KWASUColors.grey500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KWASUColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KWASUColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code,
                color: KWASUColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Verification Code',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KWASUColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use this code to verify your vote was counted:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: KWASUColors.info,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.confirmation.verificationCode!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _copyToClipboard(widget.confirmation.verificationCode!),
                  icon: Icon(
                    Icons.copy,
                    size: 16,
                    color: KWASUColors.info,
                  ),
                  tooltip: 'Copy verification code',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo(ThemeData theme, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _buildNeomorphicDecoration(theme, color: KWASUColors.success.withOpacity(0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: KWASUColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Security & Privacy',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KWASUColors.success,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildSecurityFeature(
            Icons.lock,
            'Anonymous Voting',
            'Your vote is completely anonymous and cannot be traced back to you',
            theme,
          ),
          
          _buildSecurityFeature(
            Icons.encrypted,
            'End-to-End Encryption',
            'Your vote was encrypted using AES-256-GCM before transmission',
            theme,
          ),
          
          _buildSecurityFeature(
            Icons.verified_user,
            'Cryptographic Verification',
            'Your vote is cryptographically signed and verifiable',
            theme,
          ),
          
          _buildSecurityFeature(
            Icons.visibility_off,
            'Zero Knowledge',
            'The system cannot see your choices, only that you voted',
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(
    IconData icon,
    String title,
    String description,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: KWASUColors.success,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: KWASUColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: KWASUColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextElectionInfo(ThemeData theme, bool isTablet) {
    final timeRemaining = widget.confirmation.nextElectionDate!.difference(DateTime.now());
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _buildNeomorphicDecoration(theme, color: KWASUColors.info.withOpacity(0.1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_upcoming,
                color: KWASUColors.info,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Next Election',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KWASUColors.info,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (widget.confirmation.nextElectionInfo != null)
            Text(
              widget.confirmation.nextElectionInfo!,
              style: theme.textTheme.bodyMedium,
            ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: KWASUColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'In ${_formatDuration(timeRemaining)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => context.go('/verify-vote', extra: {
            'voteToken': widget.confirmation.voteToken,
          }),
          icon: const Icon(Icons.verified_user),
          label: const Text('Verify My Vote'),
          style: ElevatedButton.styleFrom(
            backgroundColor: KWASUColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        OutlinedButton.icon(
          onPressed: _shareVoteConfirmation,
          icon: const Icon(Icons.share),
          label: const Text('Share (Anonymous)'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home),
          label: const Text('Return to Dashboard'),
        ),
      ],
    );
  }

  BoxDecoration _buildNeomorphicDecoration(ThemeData theme, {Color? color}) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? KWASUColors.grey800 : KWASUColors.grey100);
    
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(4, 4),
        ),
        BoxShadow(
          color: isDark 
              ? KWASUColors.grey700.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          blurRadius: 4,
          offset: const Offset(-2, -2),
        ),
      ],
    );
  }

  String _maskToken(String token) {
    if (token.length <= 8) return token;
    final start = token.substring(0, 4);
    final end = token.substring(token.length - 4);
    return '$start****$end';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 30) {
      final months = duration.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: KWASUColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _shareVoteConfirmation() {
    // Implement anonymous sharing functionality
    final shareText = 'I just voted in ${widget.confirmation.electionTitle}! '
        'Make your voice heard in democracy. #Vote #KWASU';
    
    // This would use platform sharing APIs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}