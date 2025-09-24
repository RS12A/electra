import 'package:flutter/material.dart';
import 'dart:async';

import '../../../../shared/widgets/neomorphic_container.dart';
import '../../domain/entities/timetable_event.dart';

/// A visual countdown timer widget for displaying time remaining until events
/// 
/// Features:
/// - Real-time countdown updates
/// - Multiple display formats (days, hours, minutes, seconds)
/// - Neomorphic design with animations
/// - Event type color coding
/// - Auto-completion handling
/// - Responsive layout for different screen sizes
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({
    super.key,
    required this.event,
    required this.timeRemaining,
    this.onCompleted,
    this.format = CountdownFormat.auto,
    this.showLabels = true,
    this.compact = false,
    this.color,
  });

  /// The event being counted down to
  final TimetableEvent event;
  
  /// Time remaining until the event
  final Duration timeRemaining;
  
  /// Callback when countdown reaches zero
  final VoidCallback? onCompleted;
  
  /// Display format for the countdown
  final CountdownFormat format;
  
  /// Whether to show time unit labels
  final bool showLabels;
  
  /// Whether to use compact layout
  final bool compact;
  
  /// Custom color override
  final Color? color;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _currentDuration;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _colorController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.timeRemaining;
    
    // Pulse animation for urgency
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Color animation for urgency levels
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _startTimer();
    _updateUrgencyAnimation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentDuration.inSeconds > 0) {
          _currentDuration = _currentDuration - const Duration(seconds: 1);
          _updateUrgencyAnimation();
        } else {
          _timer.cancel();
          widget.onCompleted?.call();
        }
      });
    });
  }

  void _updateUrgencyAnimation() {
    final hoursRemaining = _currentDuration.inHours;
    
    if (hoursRemaining <= 1) {
      // Critical - pulse rapidly
      _pulseController.repeat(reverse: true);
      _colorController.animateTo(1.0);
    } else if (hoursRemaining <= 24) {
      // Urgent - slow pulse
      _pulseController.repeat(reverse: true);
      _colorController.animateTo(0.6);
    } else {
      // Normal - no pulse
      _pulseController.stop();
      _pulseController.reset();
      _colorController.animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Setup color animation
    _colorAnimation = ColorTween(
      begin: widget.color ?? _getEventColor(widget.event.type),
      end: Colors.red,
    ).animate(_colorController);

    if (_currentDuration.inSeconds <= 0) {
      return _buildCompletedWidget(theme);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: NeomorphicContainer(
            padding: widget.compact
                ? const EdgeInsets.all(12)
                : const EdgeInsets.all(16),
            color: _colorAnimation.value?.withOpacity(0.1),
            child: widget.compact ? _buildCompactLayout(theme) : _buildFullLayout(theme),
          ),
        );
      },
    );
  }

  Widget _buildFullLayout(ThemeData theme) {
    final components = _getTimeComponents();
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Event info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _colorAnimation.value ?? _getEventColor(widget.event.type),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEventTypeLabel(widget.event.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            Icon(
              _getEventIcon(widget.event.type),
              size: 16,
              color: _colorAnimation.value ?? _getEventColor(widget.event.type),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Event title
        Text(
          widget.event.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'KWASU',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Countdown display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: components.map((component) {
            return _buildTimeComponent(
              component.value,
              component.label,
              theme,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 8),
        
        // Urgency indicator
        if (_currentDuration.inHours <= 24)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getUrgencyColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getUrgencyText(),
              style: TextStyle(
                color: _getUrgencyColor(),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme) {
    final timeString = _formatCompactTime();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _colorAnimation.value ?? _getEventColor(widget.event.type),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.event.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                timeString,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _colorAnimation.value ?? _getEventColor(widget.event.type),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'KWASU',
                ),
              ),
            ],
          ),
        ),
        Icon(
          _getEventIcon(widget.event.type),
          size: 14,
          color: _colorAnimation.value ?? _getEventColor(widget.event.type),
        ),
      ],
    );
  }

  Widget _buildTimeComponent(int value, String label, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (_colorAnimation.value ?? _getEventColor(widget.event.type))
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: _colorAnimation.value ?? _getEventColor(widget.event.type),
              fontFamily: 'KWASU',
            ),
          ),
        ),
        if (widget.showLabels) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletedWidget(ThemeData theme) {
    return NeomorphicContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.green.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Event Started',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.green,
              fontWeight: FontWeight.w600,
              fontFamily: 'KWASU',
            ),
          ),
          Text(
            widget.event.title,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<TimeComponent> _getTimeComponents() {
    final days = _currentDuration.inDays;
    final hours = _currentDuration.inHours % 24;
    final minutes = _currentDuration.inMinutes % 60;
    final seconds = _currentDuration.inSeconds % 60;

    switch (widget.format) {
      case CountdownFormat.daysHours:
        return [
          TimeComponent(days, 'Days'),
          TimeComponent(hours, 'Hours'),
        ];
      case CountdownFormat.hoursMinutes:
        return [
          TimeComponent(_currentDuration.inHours, 'Hours'),
          TimeComponent(minutes, 'Minutes'),
        ];
      case CountdownFormat.minutesSeconds:
        return [
          TimeComponent(_currentDuration.inMinutes, 'Minutes'),
          TimeComponent(seconds, 'Seconds'),
        ];
      case CountdownFormat.full:
        return [
          TimeComponent(days, 'Days'),
          TimeComponent(hours, 'Hours'),
          TimeComponent(minutes, 'Min'),
          TimeComponent(seconds, 'Sec'),
        ];
      case CountdownFormat.auto:
      default:
        if (days > 0) {
          return [
            TimeComponent(days, 'Days'),
            TimeComponent(hours, 'Hours'),
          ];
        } else if (hours > 0) {
          return [
            TimeComponent(hours, 'Hours'),
            TimeComponent(minutes, 'Min'),
          ];
        } else {
          return [
            TimeComponent(minutes, 'Min'),
            TimeComponent(seconds, 'Sec'),
          ];
        }
    }
  }

  String _formatCompactTime() {
    if (_currentDuration.inDays > 0) {
      return '${_currentDuration.inDays}d ${_currentDuration.inHours % 24}h';
    } else if (_currentDuration.inHours > 0) {
      return '${_currentDuration.inHours}h ${_currentDuration.inMinutes % 60}m';
    } else {
      return '${_currentDuration.inMinutes}m ${_currentDuration.inSeconds % 60}s';
    }
  }

  Color _getUrgencyColor() {
    final hoursRemaining = _currentDuration.inHours;
    if (hoursRemaining <= 1) {
      return Colors.red;
    } else if (hoursRemaining <= 6) {
      return Colors.orange;
    } else if (hoursRemaining <= 24) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  String _getUrgencyText() {
    final hoursRemaining = _currentDuration.inHours;
    if (hoursRemaining <= 1) {
      return 'CRITICAL';
    } else if (hoursRemaining <= 6) {
      return 'URGENT';
    } else if (hoursRemaining <= 24) {
      return 'SOON';
    } else {
      return 'UPCOMING';
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.electionStart:
        return Colors.green;
      case EventType.electionEnd:
        return Colors.red;
      case EventType.registrationDeadline:
        return Colors.orange;
      case EventType.resultAnnouncement:
        return Colors.blue;
      case EventType.systemMaintenance:
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.electionStart:
        return Icons.how_to_vote;
      case EventType.electionEnd:
        return Icons.stop;
      case EventType.registrationDeadline:
        return Icons.schedule;
      case EventType.resultAnnouncement:
        return Icons.poll;
      case EventType.systemMaintenance:
        return Icons.build;
      default:
        return Icons.event;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.electionStart:
        return 'Election';
      case EventType.electionEnd:
        return 'Closing';
      case EventType.registrationDeadline:
        return 'Deadline';
      case EventType.resultAnnouncement:
        return 'Results';
      case EventType.systemMaintenance:
        return 'Maintenance';
      default:
        return 'Event';
    }
  }
}

/// Available countdown display formats
enum CountdownFormat {
  /// Automatically choose best format based on time remaining
  auto,
  
  /// Show days and hours
  daysHours,
  
  /// Show hours and minutes
  hoursMinutes,
  
  /// Show minutes and seconds
  minutesSeconds,
  
  /// Show all components (days, hours, minutes, seconds)
  full,
}

/// Represents a time component for display
class TimeComponent {
  const TimeComponent(this.value, this.label);
  
  final int value;
  final String label;
}

/// A compact countdown widget for lists and cards
class CompactCountdownTimer extends StatelessWidget {
  const CompactCountdownTimer({
    super.key,
    required this.event,
    required this.timeRemaining,
    this.onCompleted,
  });

  final TimetableEvent event;
  final Duration timeRemaining;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return CountdownTimer(
      event: event,
      timeRemaining: timeRemaining,
      onCompleted: onCompleted,
      compact: true,
      showLabels: false,
    );
  }
}

/// A grid of countdown timers for multiple events
class CountdownGrid extends StatelessWidget {
  const CountdownGrid({
    super.key,
    required this.events,
    required this.timeRemaining,
    this.crossAxisCount = 2,
    this.onEventCompleted,
  });

  final List<TimetableEvent> events;
  final Map<String, Duration> timeRemaining;
  final int crossAxisCount;
  final ValueChanged<TimetableEvent>? onEventCompleted;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final duration = timeRemaining[event.id] ?? Duration.zero;

        return CountdownTimer(
          event: event,
          timeRemaining: duration,
          onCompleted: () => onEventCompleted?.call(event),
          compact: true,
        );
      },
    );
  }
}