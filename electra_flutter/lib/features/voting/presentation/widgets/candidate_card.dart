import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/candidate.dart';
import '../../../../core/theme/app_theme.dart';

/// Neomorphic candidate card with KWASU theme
///
/// Displays candidate information with smooth animations,
/// accessibility support, and neomorphic design elements.
class CandidateCard extends StatefulWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onVideoPlay;
  final bool showVoteButton;
  final bool isExpanded;
  final VoidCallback? onExpand;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onTap,
    this.isSelected = false,
    this.onVideoPlay,
    this.showVoteButton = true,
    this.isExpanded = false,
    this.onExpand,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _expandController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _expandAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    
    if (widget.isExpanded) {
      _expandController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CandidateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Semantics(
      label: 'Candidate card for ${widget.candidate.name}',
      hint: 'Double tap to ${widget.isExpanded ? 'collapse' : 'expand'} details',
      selected: widget.isSelected,
      button: true,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        child: _buildCardContent(theme, isTablet),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildCardContent(ThemeData theme, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 16.0 : 8.0,
        vertical: 8.0,
      ),
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: _buildNeomorphicDecoration(theme),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 12),
                  _buildManifestoPreview(theme),
                  AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: child,
                      );
                    },
                    child: _buildExpandedContent(theme),
                  ),
                  const SizedBox(height: 12),
                  _buildActionButtons(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildNeomorphicDecoration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? KWASUColors.grey800 : KWASUColors.grey100;
    
    return BoxDecoration(
      color: widget.isSelected 
          ? (isDark ? KWASUColors.primaryBlue.withOpacity(0.2) : KWASUColors.lightBlue.withOpacity(0.1))
          : baseColor,
      borderRadius: BorderRadius.circular(16),
      border: widget.isSelected 
          ? Border.all(color: KWASUColors.primaryBlue, width: 2)
          : null,
      boxShadow: [
        // Soft outer shadow
        BoxShadow(
          color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          blurRadius: _isHovered ? 12 : 8,
          offset: Offset(_isPressed ? 2 : 4, _isPressed ? 2 : 4),
        ),
        // Inner highlight
        BoxShadow(
          color: isDark 
              ? KWASUColors.grey700.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          blurRadius: _isHovered ? 8 : 4,
          offset: Offset(_isPressed ? -1 : -2, _isPressed ? -1 : -2),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        // Candidate photo
        _buildCandidatePhoto(),
        const SizedBox(width: 12),
        
        // Name and position
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.candidate.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected 
                      ? KWASUColors.primaryBlue
                      : theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.school,
                    size: 16,
                    color: KWASUColors.secondaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.candidate.department,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: KWASUColors.secondaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: KWASUColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.candidate.position,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: KWASUColors.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Expand button
        if (widget.onExpand != null)
          IconButton(
            onPressed: widget.onExpand,
            icon: AnimatedRotation(
              turns: widget.isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: theme.iconTheme.color,
              ),
            ),
            tooltip: widget.isExpanded ? 'Collapse details' : 'Expand details',
          ),
      ],
    );
  }

  Widget _buildCandidatePhoto() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: widget.isSelected 
              ? KWASUColors.primaryBlue
              : KWASUColors.grey300,
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: widget.candidate.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.candidate.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildPhotoPlaceholder(),
                errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
              )
            : _buildPhotoPlaceholder(),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: KWASUColors.grey200,
      child: Icon(
        Icons.person,
        color: KWASUColors.grey500,
        size: 30,
      ),
    );
  }

  Widget _buildManifestoPreview(ThemeData theme) {
    return Text(
      widget.candidate.manifesto,
      style: theme.textTheme.bodyMedium,
      maxLines: widget.isExpanded ? null : 2,
      overflow: widget.isExpanded ? null : TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.candidate.additionalInfo != null) ...[
            Text(
              'Additional Information',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: KWASUColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.candidate.additionalInfo!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          
          if (widget.candidate.videoUrl != null) ...[
            const SizedBox(height: 12),
            _buildVideoSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Campaign Video',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: KWASUColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white,
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onVideoPlay,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (widget.showVoteButton)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onTap,
              icon: Icon(
                widget.isSelected ? Icons.how_to_vote : Icons.how_to_vote_outlined,
                size: 20,
              ),
              label: Text(
                widget.isSelected ? 'Selected' : 'Vote for this Candidate',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isSelected 
                    ? KWASUColors.success
                    : KWASUColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        
        const SizedBox(width: 8),
        
        // Additional action buttons can be added here
        IconButton(
          onPressed: () {
            // Share candidate functionality
          },
          icon: Icon(Icons.share_outlined),
          tooltip: 'Share candidate',
        ),
      ],
    );
  }
}