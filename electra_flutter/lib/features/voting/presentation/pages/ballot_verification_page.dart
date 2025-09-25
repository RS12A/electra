import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Ballot verification page for verifying vote integrity
///
/// Allows users to verify their vote was recorded correctly
/// using their vote token while maintaining anonymity.
class BallotVerificationPage extends ConsumerStatefulWidget {
  final String? voteToken;

  const BallotVerificationPage({super.key, this.voteToken});

  @override
  ConsumerState<BallotVerificationPage> createState() =>
      _BallotVerificationPageState();
}

class _BallotVerificationPageState
    extends ConsumerState<BallotVerificationPage> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isVerified = false;
  Map<String, dynamic>? _verificationResult;

  @override
  void initState() {
    super.initState();
    if (widget.voteToken != null) {
      _tokenController.text = widget.voteToken!;
      _handleVerification();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Vote'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header section
            _buildHeader(theme),

            const SizedBox(height: 24),

            // Token input section
            if (!_isVerified) _buildTokenInput(theme),

            // Verification result
            if (_isVerified && _verificationResult != null)
              _buildVerificationResult(theme),

            const SizedBox(height: 24),

            // Info section
            _buildInfoSection(theme),
          ],
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.verified_user, color: KWASUColors.primaryBlue, size: 48),

            const SizedBox(height: 16),

            Text(
              'Vote Verification',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: KWASUColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Verify that your vote was recorded correctly without compromising your anonymity.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build token input section
  Widget _buildTokenInput(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Vote Token',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Vote Token',
                hintText: 'Enter your vote verification token',
                prefixIcon: Icon(Icons.token),
                helperText: 'This token was provided after you voted',
              ),
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerification,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Verify Vote'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build verification result section
  Widget _buildVerificationResult(ThemeData theme) {
    final result = _verificationResult!;
    final isValid = result['valid'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? KWASUColors.success : KWASUColors.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValid ? 'Vote Verified' : 'Verification Failed',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isValid
                              ? KWASUColors.success
                              : KWASUColors.error,
                        ),
                      ),
                      Text(
                        isValid
                            ? 'Your vote has been successfully verified'
                            : 'Unable to verify this vote token',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isValid) ...[
              const SizedBox(height: 24),

              // Election details
              _buildDetailItem(
                'Election',
                result['election_title'] ?? 'N/A',
                theme,
              ),
              _buildDetailItem(
                'Vote Cast',
                result['vote_timestamp'] ?? 'N/A',
                theme,
              ),
              _buildDetailItem('Status', result['status'] ?? 'N/A', theme),
              _buildDetailItem(
                'Verification ID',
                result['verification_id'] ?? 'N/A',
                theme,
              ),

              const SizedBox(height: 16),

              // Security info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KWASUColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: KWASUColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your vote choices remain anonymous and cannot be traced back to you.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: KWASUColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KWASUColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Possible reasons:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: KWASUColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Invalid or expired token\n'
                      '• Token already used for verification\n'
                      '• Vote not yet processed by the system',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: KWASUColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isVerified = false;
                        _verificationResult = null;
                        _tokenController.clear();
                      });
                    },
                    child: const Text('Verify Another'),
                  ),
                ),
                if (isValid) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _downloadReceipt,
                      child: const Text('Download Receipt'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build detail item
  Widget _buildDetailItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Build info section
  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: KWASUColors.info),
                const SizedBox(width: 8),
                Text(
                  'About Vote Verification',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: KWASUColors.info,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'The verification system allows you to confirm that your vote was recorded without revealing your choices or identity. Here\'s how it works:',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            _buildInfoPoint(
              '🔒',
              'Your vote token is generated cryptographically',
              theme,
            ),
            _buildInfoPoint(
              '🔍',
              'Verification confirms your vote exists in the system',
              theme,
            ),
            _buildInfoPoint(
              '🤐',
              'Your identity and choices remain completely anonymous',
              theme,
            ),
            _buildInfoPoint(
              '📝',
              'You can verify your vote multiple times if needed',
              theme,
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KWASUColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: KWASUColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep your vote token secure. Anyone with this token can verify your vote status.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: KWASUColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build info point
  Widget _buildInfoPoint(String emoji, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Handle verification
  void _handleVerification() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a vote token'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Implement verification logic
      // In production, this would call the actual vote verification API
      // final result = await ref.read(voteServiceProvider).verifyVote(token);
      
      // For now, simulate API call with basic validation
      await Future.delayed(const Duration(seconds: 2));
      
      // Basic token validation (in production, this would be server-side)
      if (token.length < 10) {
        throw Exception('Invalid verification token format');
      }
      
      // Mock verification result (replace with actual API response)
      final mockResult = {
        'valid': true,
        'election_title': 'Student Union Executive Elections 2024',
        'vote_timestamp': 'March 15, 2024 at 2:30 PM',
        'status': 'Recorded',
        'verification_id': 'VER-${DateTime.now().millisecondsSinceEpoch}',
        'vote_hash': token.substring(0, 8) + '...',
        'blockchain_confirmed': true,
      };

      setState(() {
        _verificationResult = mockResult;
        _isVerified = true;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${error.toString()}'),
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

  /// Download verification receipt
  void _downloadReceipt() async {
    try {
      // Implement receipt download
      // In production, this would generate and download a PDF receipt
      // await ref.read(voteServiceProvider).downloadReceipt(_verificationResult!);
      
      // For now, show a placeholder message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt download feature ready for implementation - PDF generation needed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Future implementation would:
      // 1. Generate PDF with verification details
      // 2. Save to downloads folder
      // 3. Show confirmation with file location
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download receipt: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
