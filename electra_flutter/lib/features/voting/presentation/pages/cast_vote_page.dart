import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

/// Cast vote page for selecting and submitting votes
///
/// Displays election candidates, handles vote selection,
/// and manages secure vote submission with ballot tokens.
class CastVotePage extends ConsumerStatefulWidget {
  final String? electionId;

  const CastVotePage({super.key, this.electionId});

  @override
  ConsumerState<CastVotePage> createState() => _CastVotePageState();
}

class _CastVotePageState extends ConsumerState<CastVotePage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, String> _selectedCandidates = {};

  @override
  void initState() {
    super.initState();
    _loadElectionData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cast Your Vote'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Election info
                  _buildElectionInfo(theme),

                  const SizedBox(height: 24),

                  // Voting instructions
                  _buildInstructions(theme),

                  const SizedBox(height: 24),

                  // Ballot sections
                  _buildBallotSections(theme),

                  const SizedBox(height: 32),

                  // Submit button
                  _buildSubmitSection(theme),
                ],
              ),
            ),
    );
  }

  /// Build election information section
  Widget _buildElectionInfo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.ballot, color: KWASUColors.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Student Union Executive Elections 2024',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Choose your student union representatives for the 2024-2025 academic session.',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _buildInfoChip(
                  'Ends in 6 days',
                  Icons.schedule,
                  KWASUColors.warning,
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  '3,245 eligible voters',
                  Icons.people,
                  KWASUColors.info,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build info chip
  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build voting instructions
  Widget _buildInstructions(ThemeData theme) {
    return Container(
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
              Icon(Icons.info_outline, color: KWASUColors.info),
              const SizedBox(width: 8),
              Text(
                'Voting Instructions',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: KWASUColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '• Select one candidate for each position\n'
            '• You can change your selection before submitting\n'
            '• Review your choices carefully before confirming\n'
            '• Your vote is anonymous and cannot be traced back to you',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: KWASUColors.info,
            ),
          ),
        ],
      ),
    );
  }

  /// Build ballot sections
  Widget _buildBallotSections(ThemeData theme) {
    return Column(
      children: [
        _buildBallotSection('President', 'president', [
          _mockCandidate(
            'John Doe',
            'Computer Science',
            'Transforming KWASU through technology',
          ),
          _mockCandidate(
            'Jane Smith',
            'Mass Communication',
            'Unity, Progress, Excellence',
          ),
          _mockCandidate(
            'Mike Johnson',
            'Business Administration',
            'Students first, always',
          ),
        ], theme),

        const SizedBox(height: 24),

        _buildBallotSection('Vice President', 'vice_president', [
          _mockCandidate(
            'Sarah Wilson',
            'Engineering',
            'Building bridges, creating solutions',
          ),
          _mockCandidate(
            'David Brown',
            'Law',
            'Justice and fairness for all students',
          ),
        ], theme),

        const SizedBox(height: 24),

        _buildBallotSection('Secretary General', 'secretary', [
          _mockCandidate(
            'Emma Davis',
            'English',
            'Effective communication, efficient service',
          ),
          _mockCandidate(
            'Alex Taylor',
            'Mathematics',
            'Precision in leadership, excellence in service',
          ),
          _mockCandidate(
            'Lisa Garcia',
            'Psychology',
            'Understanding students, serving better',
          ),
        ], theme),
      ],
    );
  }

  /// Build individual ballot section
  Widget _buildBallotSection(
    String position,
    String positionId,
    List<Map<String, String>> candidates,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          position,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: KWASUColors.primaryBlue,
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Column(
            children: candidates
                .asMap()
                .entries
                .map(
                  (entry) => _buildCandidateOption(
                    entry.value,
                    positionId,
                    entry.key,
                    theme,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  /// Build individual candidate option
  Widget _buildCandidateOption(
    Map<String, String> candidate,
    String positionId,
    int index,
    ThemeData theme,
  ) {
    final isSelected = _selectedCandidates[positionId] == candidate['id'];

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: index < 2
              ? BorderSide(color: theme.dividerColor)
              : BorderSide.none,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          candidate['name']!,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidate['department']!),
            const SizedBox(height: 4),
            Text(
              candidate['manifesto']!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        value: candidate['id']!,
        groupValue: _selectedCandidates[positionId],
        onChanged: (value) {
          setState(() {
            _selectedCandidates[positionId] = value!;
          });
        },
        activeColor: KWASUColors.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  /// Build submit section
  Widget _buildSubmitSection(ThemeData theme) {
    final hasAllSelections = _selectedCandidates.length >= 3; // All positions

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Review selections
        if (_selectedCandidates.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Selections',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ..._selectedCandidates.entries.map((entry) {
                    final candidate = _getCandidateById(entry.value);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: KWASUColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_getPositionName(entry.key)}: ${candidate['name']}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting || !hasAllSelections
              ? null
              : _handleSubmitVote,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: KWASUColors.success,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Submit Vote'),
        ),

        if (!hasAllSelections) ...[
          const SizedBox(height: 8),
          Text(
            'Please select a candidate for all positions before submitting.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: KWASUColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Handle vote submission
  void _handleSubmitVote() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Vote'),
        content: const Text(
          'Are you sure you want to submit your vote? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement vote submission logic
      // await ref.read(voteServiceProvider).submitVote(
      //   electionId: widget.electionId!,
      //   selections: _selectedCandidates,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle,
              color: KWASUColors.success,
              size: 48,
            ),
            title: const Text('Vote Submitted Successfully'),
            content: const Text(
              'Your vote has been recorded securely. '
              'Thank you for participating in the election.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to dashboard
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vote: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Load election data
  Future<void> _loadElectionData() async {
    // TODO: Load election and candidates from API
    // final election = await ref.read(electionServiceProvider).getElection(widget.electionId!);
    // final candidates = await ref.read(candidateServiceProvider).getCandidates(widget.electionId!);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Create mock candidate data
  Map<String, String> _mockCandidate(
    String name,
    String department,
    String manifesto,
  ) {
    return {
      'id': name.toLowerCase().replaceAll(' ', '_'),
      'name': name,
      'department': department,
      'manifesto': manifesto,
    };
  }

  /// Get candidate by ID
  Map<String, String> _getCandidateById(String id) {
    // Mock implementation
    final allCandidates = [
      _mockCandidate(
        'John Doe',
        'Computer Science',
        'Transforming KWASU through technology',
      ),
      _mockCandidate(
        'Jane Smith',
        'Mass Communication',
        'Unity, Progress, Excellence',
      ),
      _mockCandidate(
        'Mike Johnson',
        'Business Administration',
        'Students first, always',
      ),
      _mockCandidate(
        'Sarah Wilson',
        'Engineering',
        'Building bridges, creating solutions',
      ),
      _mockCandidate(
        'David Brown',
        'Law',
        'Justice and fairness for all students',
      ),
      _mockCandidate(
        'Emma Davis',
        'English',
        'Effective communication, efficient service',
      ),
      _mockCandidate(
        'Alex Taylor',
        'Mathematics',
        'Precision in leadership, excellence in service',
      ),
      _mockCandidate(
        'Lisa Garcia',
        'Psychology',
        'Understanding students, serving better',
      ),
    ];

    return allCandidates.firstWhere((c) => c['id'] == id);
  }

  /// Get position name by ID
  String _getPositionName(String positionId) {
    switch (positionId) {
      case 'president':
        return 'President';
      case 'vice_president':
        return 'Vice President';
      case 'secretary':
        return 'Secretary General';
      default:
        return positionId;
    }
  }
}
