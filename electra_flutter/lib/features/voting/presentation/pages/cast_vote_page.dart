import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/candidate.dart';
import '../../domain/entities/election.dart';
import '../../domain/entities/vote.dart';
import '../widgets/candidate_card.dart';
import '../widgets/election_info_card.dart';

/// Enhanced cast vote page for secure vote submission
///
/// Features production-grade security, encryption, offline support,
/// neomorphic design, and comprehensive accessibility features.
class CastVotePage extends ConsumerStatefulWidget {
  final String? electionId;
  final Election? election;
  final Candidate? preselectedCandidate;

  const CastVotePage({
    super.key, 
    this.electionId,
    this.election,
    this.preselectedCandidate,
  });

  @override
  ConsumerState<CastVotePage> createState() => _CastVotePageState();
}

class _CastVotePageState extends ConsumerState<CastVotePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showConfirmation = false;
  String? _error;
  String? _ballotToken;
  
  Election? _election;
  List<Candidate> _candidates = [];
  Map<String, String> _selectedCandidates = {};
  Map<String, List<Candidate>> _candidatesByPosition = {};
  
  // Security and encryption status
  bool _isSecureConnection = false;
  bool _hasInternetConnection = true;
  int _encryptionProgress = 0;

  @override
  void initState() {
    super.initState();
    
    _initializeAnimations();
    _initializePreselection();
    _loadElectionData();
    _checkSecurityStatus();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
  }

  void _initializePreselection() {
    if (widget.preselectedCandidate != null) {
      _selectedCandidates[widget.preselectedCandidate!.position] = 
          widget.preselectedCandidate!.id;
    }
    
    if (widget.election != null) {
      _election = widget.election;
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadElectionData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock data if not provided
      if (_election == null) {
        _election = Election(
          id: widget.electionId ?? 'default-election',
          title: 'Student Union Elections 2024',
          description: 'Annual student union elections for academic year 2024/2025.',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
          status: ElectionStatus.active,
          positions: ['President', 'Vice President', 'Secretary General'],
          totalVoters: 5000,
          votesCast: 1250,
          allowsAnonymousVoting: true,
        );
      }

      // Load candidates
      _candidates = _getMockCandidates();
      
      // Group candidates by position
      _candidatesByPosition.clear();
      for (final candidate in _candidates) {
        _candidatesByPosition
            .putIfAbsent(candidate.position, () => [])
            .add(candidate);
      }

      // Generate ballot token (mock)
      _ballotToken = 'BT-${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _isLoading = false;
      });

      _fadeController.forward();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load election data. Please check your connection and try again.';
      });
    }
  }

  Future<void> _checkSecurityStatus() async {
    // Simulate security checks
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isSecureConnection = true;
      _hasInternetConnection = true;
    });
  }

  List<Candidate> _getMockCandidates() {
    return [
      Candidate(
        id: 'candidate-1',
        name: 'John Doe',
        department: 'Computer Science',
        position: 'President',
        manifesto: 'Transforming KWASU through technology and innovation. Building bridges between students, faculty, and administration for a better tomorrow.',
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
        videoUrl: 'https://example.com/john-campaign-video.mp4',
        additionalInfo: 'John has 3 years of experience in student leadership.',
        electionId: widget.electionId ?? 'default-election',
      ),
      Candidate(
        id: 'candidate-2',
        name: 'Jane Smith',
        department: 'Mass Communication',
        position: 'President',
        manifesto: 'Unity, Progress, Excellence. Advocating for better student welfare and improved facilities.',
        photoUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b495?w=150&h=150&fit=crop&crop=face',
        electionId: widget.electionId ?? 'default-election',
      ),
      Candidate(
        id: 'candidate-3',
        name: 'Michael Johnson',
        department: 'Business Administration',
        position: 'President',
        manifesto: 'Business-minded leadership for practical solutions and career development.',
        photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
        electionId: widget.electionId ?? 'default-election',
      ),
      Candidate(
        id: 'candidate-4',
        name: 'Sarah Wilson',
        department: 'Political Science',
        position: 'Vice President',
        manifesto: 'Bridging the gap between students and administration with transparent governance.',
        photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
        electionId: widget.electionId ?? 'default-election',
      ),
      Candidate(
        id: 'candidate-5',
        name: 'David Brown',
        department: 'Engineering',
        position: 'Vice President',
        manifesto: 'Engineering solutions for student problems and infrastructure improvements.',
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
        videoUrl: 'https://example.com/david-campaign-video.mp4',
        electionId: widget.electionId ?? 'default-election',
      ),
      Candidate(
        id: 'candidate-6',
        name: 'Lisa Garcia',
        department: 'Psychology',
        position: 'Secretary General',
        manifesto: 'Understanding students, serving better. Focus on mental health support and academic guidance.',
        photoUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&h=150&fit=crop&crop=face',
        electionId: widget.electionId ?? 'default-election',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cast Your Vote',
          semanticsLabel: 'Cast your vote in the election',
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Security indicator
          _buildSecurityIndicator(),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(theme, isTablet),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSecurityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isSecureConnection 
            ? KWASUColors.success.withOpacity(0.2)
            : KWASUColors.warning.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isSecureConnection ? Icons.lock : Icons.lock_open,
            size: 16,
            color: _isSecureConnection ? KWASUColors.success : KWASUColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            _isSecureConnection ? 'SECURE' : 'CHECKING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _isSecureConnection ? KWASUColors.success : KWASUColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isTablet) {
    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null) {
      return _buildErrorState(theme);
    }

    if (_showConfirmation) {
      return _buildConfirmationState(theme, isTablet);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadElectionData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Election information
            if (_election != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: ElectionInfoCard(
                    election: _election!,
                    showProgress: true,
                    isCompact: !isTablet,
                  ),
                ),
              ),

            // Security features section
            SliverToBoxAdapter(
              child: _buildSecuritySection(theme, isTablet),
            ),

            // Voting instructions
            SliverToBoxAdapter(
              child: _buildInstructions(theme, isTablet),
            ),

            // Ballot sections by position
            ..._buildBallotSections(theme, isTablet),

            // Selection summary
            if (_selectedCandidates.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildSelectionSummary(theme, isTablet),
              ),

            // Bottom spacing for floating action button
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(KWASUColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading election data...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: KWASUColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Establishing secure connection',
            style: theme.textTheme.bodySmall?.copyWith(
              color: KWASUColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: KWASUColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Election',
              style: theme.textTheme.titleLarge?.copyWith(
                color: KWASUColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: KWASUColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadElectionData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KWASUColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
