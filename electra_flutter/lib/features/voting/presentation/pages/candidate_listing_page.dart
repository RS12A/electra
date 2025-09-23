import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/candidate.dart';
import '../../domain/entities/election.dart';
import '../widgets/candidate_card.dart';
import '../widgets/election_info_card.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';

/// Candidate listing page for displaying election candidates
///
/// Shows candidates with their manifestos, photos, and optional videos
/// with neomorphic design, accessibility features, and smooth animations.
class CandidateListingPage extends ConsumerStatefulWidget {
  final String electionId;
  final String? electionTitle;

  const CandidateListingPage({
    super.key,
    required this.electionId,
    this.electionTitle,
  });

  @override
  ConsumerState<CandidateListingPage> createState() => _CandidateListingPageState();
}

class _CandidateListingPageState extends ConsumerState<CandidateListingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = true;
  String? _error;
  Election? _election;
  List<Candidate> _candidates = [];
  String _selectedPosition = 'all';
  String _expandedCandidateId = '';
  
  // Mock data for demonstration
  final List<String> _positions = ['All Positions', 'President', 'Vice President', 'Secretary General'];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock election data
      _election = Election(
        id: widget.electionId,
        title: widget.electionTitle ?? 'Student Union Elections 2024',
        description: 'Annual student union elections for academic year 2024/2025. Choose your representatives for various positions.',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        status: ElectionStatus.active,
        positions: ['President', 'Vice President', 'Secretary General'],
        totalVoters: 5000,
        votesCast: 1250,
        allowsAnonymousVoting: true,
      );

      // Mock candidates data
      _candidates = [
        Candidate(
          id: 'candidate-1',
          name: 'John Doe',
          department: 'Computer Science',
          position: 'President',
          manifesto: 'Transforming KWASU through technology and innovation. Building bridges between students, faculty, and administration for a better tomorrow.',
          photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
          videoUrl: 'https://example.com/john-campaign-video.mp4',
          additionalInfo: 'John has 3 years of experience in student leadership and has successfully organized multiple tech events on campus.',
          electionId: widget.electionId,
        ),
        Candidate(
          id: 'candidate-2',
          name: 'Jane Smith',
          department: 'Mass Communication',
          position: 'President',
          manifesto: 'Unity, Progress, Excellence. Advocating for better student welfare, improved facilities, and stronger voice in university decisions.',
          photoUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b495?w=150&h=150&fit=crop&crop=face',
          additionalInfo: 'Jane has been class representative for 2 years and has successfully lobbied for improved library facilities.',
          electionId: widget.electionId,
        ),
        Candidate(
          id: 'candidate-3',
          name: 'Michael Johnson',
          department: 'Business Administration',
          position: 'President',
          manifesto: 'Business-minded leadership for practical solutions. Focus on entrepreneurship programs and career development for all students.',
          photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
          electionId: widget.electionId,
        ),
        Candidate(
          id: 'candidate-4',
          name: 'Sarah Wilson',
          department: 'Political Science',
          position: 'Vice President',
          manifesto: 'Bridging the gap between students and administration. Advocating for transparent governance and inclusive policies.',
          photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
          electionId: widget.electionId,
        ),
        Candidate(
          id: 'candidate-5',
          name: 'David Brown',
          department: 'Engineering',
          position: 'Vice President',
          manifesto: 'Engineering solutions for student problems. Focus on infrastructure improvements and technical innovation in student services.',
          photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop&crop=face',
          videoUrl: 'https://example.com/david-campaign-video.mp4',
          electionId: widget.electionId,
        ),
        Candidate(
          id: 'candidate-6',
          name: 'Lisa Garcia',
          department: 'Psychology',
          position: 'Secretary General',
          manifesto: 'Understanding students, serving better. Focus on mental health support, academic guidance, and creating a supportive campus environment.',
          photoUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&h=150&fit=crop&crop=face',
          electionId: widget.electionId,
        ),
      ];

      setState(() {
        _isLoading = false;
      });

      // Start animations
      _fadeController.forward();
      _slideController.forward();

    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load election data. Please try again.';
      });
    }
  }

  List<Candidate> get _filteredCandidates {
    if (_selectedPosition == 'all' || _selectedPosition == 'All Positions') {
      return _candidates;
    }
    return _candidates.where((candidate) => candidate.position == _selectedPosition).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.electionTitle ?? 'Candidates',
          semanticsLabel: 'Candidates for ${widget.electionTitle ?? 'election'}',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh candidates list',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(theme, isTablet),
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Election info header
            if (_election != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: ElectionInfoCard(
                    election: _election!,
                    showProgress: true,
                  ),
                ),
              ),

            // Instructions section
            SliverToBoxAdapter(
              child: _buildInstructions(theme, isTablet),
            ),

            // Position filter
            SliverToBoxAdapter(
              child: _buildPositionFilter(theme, isTablet),
            ),

            // Candidates grid/list
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24.0 : 16.0,
                vertical: 8.0,
              ),
              sliver: isTablet 
                  ? _buildCandidatesGrid()
                  : _buildCandidatesList(),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
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
            'Loading candidates...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: KWASUColors.grey600,
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
              'Oops! Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: KWASUColors.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: KWASUColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: 8.0,
      ),
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
                Icons.info_outline,
                color: KWASUColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'How to Vote',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: KWASUColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            '• Review each candidate\'s manifesto and qualifications\n'
            '• Tap on a candidate card to expand and see more details\n'
            '• Click "Vote for this Candidate" to select them\n'
            '• You can filter candidates by position using the tabs above\n'
            '• Watch campaign videos by tapping the play button',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: KWASUColors.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionFilter(ThemeData theme, bool isTablet) {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 24.0 : 16.0,
        vertical: 8.0,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _positions.length,
        itemBuilder: (context, index) {
          final position = _positions[index];
          final isSelected = _selectedPosition == position || 
                           (_selectedPosition == 'all' && position == 'All Positions');
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(position),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPosition = position == 'All Positions' ? 'all' : position;
                });
                HapticFeedback.selectionClick();
              },
              selectedColor: KWASUColors.primaryBlue.withOpacity(0.2),
              checkmarkColor: KWASUColors.primaryBlue,
              labelStyle: TextStyle(
                color: isSelected ? KWASUColors.primaryBlue : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCandidatesGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final candidate = _filteredCandidates[index];
          return _buildCandidateCard(candidate);
        },
        childCount: _filteredCandidates.length,
      ),
    );
  }

  Widget _buildCandidatesList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final candidate = _filteredCandidates[index];
          return _buildCandidateCard(candidate);
        },
        childCount: _filteredCandidates.length,
      ),
    );
  }

  Widget _buildCandidateCard(Candidate candidate) {
    final isExpanded = _expandedCandidateId == candidate.id;
    
    return CandidateCard(
      candidate: candidate,
      isExpanded: isExpanded,
      onTap: () => _handleCandidateSelection(candidate),
      onExpand: () {
        setState(() {
          _expandedCandidateId = isExpanded ? '' : candidate.id;
        });
        HapticFeedback.lightImpact();
      },
      onVideoPlay: candidate.videoUrl != null 
          ? () => _handleVideoPlay(candidate.videoUrl!)
          : null,
    );
  }

  void _handleCandidateSelection(Candidate candidate) {
    HapticFeedback.mediumImpact();
    
    // Navigate to vote casting page with selected candidate
    context.push('/cast-vote', extra: {
      'electionId': widget.electionId,
      'election': _election,
      'selectedCandidate': candidate,
    });
  }

  void _handleVideoPlay(String videoUrl) {
    // Handle video playback
    // This could open a video player dialog or navigate to a video page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Campaign Video'),
        content: const Text('Video player would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}