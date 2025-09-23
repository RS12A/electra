import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/election.dart';
import '../../../../core/theme/app_theme.dart';

/// Election information card with neomorphic design
///
/// Displays election details including status, timing, and progress
/// with accessible design and smooth animations.
class ElectionInfoCard extends StatefulWidget {
  final Election election;
  final VoidCallback? onTap;
  final bool showProgress;
  final bool isCompact;

  const ElectionInfoCard({
    super.key,
    required this.election,
    this.onTap,
    this.showProgress = true,
    this.isCompact = false,
  });

  @override
  State<ElectionInfoCard> createState() => _ElectionInfoCardState();
}

class _ElectionInfoCardState extends State<ElectionInfoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Semantics(
      label: 'Election: ${widget.election.title}',
      hint: widget.onTap != null ? 'Tap to view election details' : null,
      button: widget.onTap != null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        child: _buildCardContent(theme),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildCardContent(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: _buildNeomorphicDecoration(theme),
              child: widget.isCompact 
                  ? _buildCompactContent(theme)
                  : _buildFullContent(theme),
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
      color: baseColor,
      borderRadius: BorderRadius.circular(16),
      border: _getStatusBorder(),
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

  Border? _getStatusBorder() {
    Color? borderColor;
    
    switch (widget.election.status) {
      case ElectionStatus.active:
        borderColor = KWASUColors.success;
        break;
      case ElectionStatus.scheduled:
        borderColor = KWASUColors.warning;
        break;
      case ElectionStatus.ended:
        borderColor = KWASUColors.info;
        break;
      case ElectionStatus.completed:
        borderColor = KWASUColors.primaryBlue;
        break;
      case ElectionStatus.cancelled:
        borderColor = KWASUColors.error;
        break;
    }
    
    return borderColor != null 
        ? Border.all(color: borderColor, width: 2)
        : null;
  }

  Widget _buildCompactContent(ThemeData theme) {
    return Row(
      children: [
        // Status indicator
        _buildStatusIndicator(),
        const SizedBox(width: 12),
        
        // Election info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.election.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Progress indicator (if active)
        if (widget.election.isActive && widget.showProgress)
          _buildProgressIndicator(),
      ],
    );
  }

  Widget _buildFullContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with banner and status
        _buildHeader(theme),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          widget.election.description,
          style: theme.textTheme.bodyMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 16),
        
        // Election details
        _buildElectionDetails(theme),
        
        if (widget.showProgress) ...[
          const SizedBox(height: 16),
          _buildProgressSection(theme),
        ],
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Election banner/icon
        if (widget.election.bannerUrl != null) ...[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: KWASUColors.grey300,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CachedNetworkImage(
                imageUrl: widget.election.bannerUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildBannerPlaceholder(),
                errorWidget: (context, url, error) => _buildBannerPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        
        // Title and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.election.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: KWASUColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusChip(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: KWASUColors.grey200,
      child: Icon(
        Icons.how_to_vote,
        color: KWASUColors.grey500,
        size: 30,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 16,
            color: _getStatusColor(),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildElectionDetails(ThemeData theme) {
    return Column(
      children: [
        _buildDetailRow(
          icon: Icons.calendar_today,
          label: 'Start Date',
          value: _formatDateTime(widget.election.startDate),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.calendar_today_outlined,
          label: 'End Date',
          value: _formatDateTime(widget.election.endDate),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.people,
          label: 'Total Voters',
          value: widget.election.totalVoters.toString(),
          theme: theme,
        ),
        const SizedBox(height: 8),
        _buildDetailRow(
          icon: Icons.assignment,
          label: 'Positions',
          value: widget.election.positions.length.toString(),
          theme: theme,
        ),
        
        if (widget.election.timeUntilStart != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.timer,
            label: 'Starts in',
            value: _formatDuration(widget.election.timeUntilStart!),
            theme: theme,
          ),
        ],
        
        if (widget.election.timeUntilEnd != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow(
            icon: Icons.timer_outlined,
            label: 'Ends in',
            value: _formatDuration(widget.election.timeUntilEnd!),
            theme: theme,
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: KWASUColors.grey600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: KWASUColors.grey600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    if (!widget.election.isActive) return const SizedBox.shrink();
    
    final progress = widget.election.votingProgress;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Voting Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: KWASUColors.primaryBlue,
              ),
            ),
            Text(
              '${progress.toStringAsFixed(1)}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: KWASUColors.success,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        _buildProgressIndicator(),
        
        const SizedBox(height: 8),
        
        Text(
          '${widget.election.votesCast} of ${widget.election.totalVoters} votes cast',
          style: theme.textTheme.bodySmall?.copyWith(
            color: KWASUColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (!widget.election.isActive) return const SizedBox.shrink();
    
    final progress = widget.election.votingProgress / 100;
    
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: KWASUColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: KWASUColors.success,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.election.status) {
      case ElectionStatus.active:
        return KWASUColors.success;
      case ElectionStatus.scheduled:
        return KWASUColors.warning;
      case ElectionStatus.ended:
        return KWASUColors.info;
      case ElectionStatus.completed:
        return KWASUColors.primaryBlue;
      case ElectionStatus.cancelled:
        return KWASUColors.error;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.election.status) {
      case ElectionStatus.active:
        return Icons.play_circle_filled;
      case ElectionStatus.scheduled:
        return Icons.schedule;
      case ElectionStatus.ended:
        return Icons.pause_circle_filled;
      case ElectionStatus.completed:
        return Icons.check_circle;
      case ElectionStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText() {
    switch (widget.election.status) {
      case ElectionStatus.active:
        return 'Active - Voting Open';
      case ElectionStatus.scheduled:
        return 'Scheduled';
      case ElectionStatus.ended:
        return 'Voting Closed';
      case ElectionStatus.completed:
        return 'Completed';
      case ElectionStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours';
    } else {
      return 'Soon';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}