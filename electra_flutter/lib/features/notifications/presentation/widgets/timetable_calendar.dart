import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/neomorphic_container.dart';
import '../../domain/entities/timetable_event.dart';
import '../providers/notification_state.dart';

/// A modern calendar widget for displaying timetable events
/// 
/// Features:
/// - Month, week, and agenda views
/// - Event indicators with color coding
/// - Interactive date selection
/// - Neomorphic design with smooth animations
/// - KWASU theme integration
/// - Offline-first event display
class TimetableCalendar extends StatefulWidget {
  const TimetableCalendar({
    super.key,
    required this.selectedDate,
    required this.events,
    required this.calendarView,
    required this.onDateSelected,
    this.onEventTapped,
    this.firstDayOfWeek = DateTime.monday,
  });

  /// Currently selected date
  final DateTime selectedDate;
  
  /// List of events to display
  final List<TimetableEvent> events;
  
  /// Current calendar view mode
  final CalendarView calendarView;
  
  /// Callback when a date is selected
  final ValueChanged<DateTime> onDateSelected;
  
  /// Callback when an event is tapped
  final ValueChanged<TimetableEvent>? onEventTapped;
  
  /// First day of the week (default: Monday)
  final int firstDayOfWeek;

  @override
  State<TimetableCalendar> createState() => _TimetableCalendarState();
}

class _TimetableCalendarState extends State<TimetableCalendar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  late DateTime _displayedMonth;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    _pageController = PageController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.calendarView) {
      case CalendarView.month:
        return _buildMonthView();
      case CalendarView.week:
        return _buildWeekView();
      case CalendarView.agenda:
        return _buildAgendaView();
      default:
        return _buildMonthView();
    }
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        _buildWeekdayHeaders(),
        const SizedBox(height: 8),
        _buildMonthGrid(),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final theme = Theme.of(context);
    final weekdays = _getWeekdayLabels();

    return Row(
      children: weekdays.map((weekday) {
        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.disabledColor,
                fontFamily: 'KWASU',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid() {
    final daysInMonth = _getDaysInMonth();
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysInMonth.length,
      itemBuilder: (context, index) {
        final date = daysInMonth[index];
        return _buildDayCell(date);
      },
    );
  }

  Widget _buildDayCell(DateTime date) {
    final theme = Theme.of(context);
    final isSelected = _isSameDay(date, widget.selectedDate);
    final isToday = _isSameDay(date, DateTime.now());
    final isCurrentMonth = date.month == _displayedMonth.month;
    final eventsOnDate = _getEventsForDate(date);

    return GestureDetector(
      onTap: () => _handleDateSelection(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: NeomorphicContainer(
          padding: const EdgeInsets.all(4),
          borderRadius: 8,
          elevation: isSelected ? 6 : 2,
          isPressed: isSelected,
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Day number
              Text(
                date.day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isCurrentMonth
                      ? (isSelected
                          ? theme.colorScheme.primary
                          : (isToday
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color))
                      : theme.disabledColor,
                  fontFamily: 'KWASU',
                ),
              ),
              
              // Event indicators
              if (eventsOnDate.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...eventsOnDate.take(3).map((event) {
                        return Container(
                          margin: const EdgeInsets.only(right: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getEventColor(event),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                      if (eventsOnDate.length > 3)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: theme.disabledColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    final theme = Theme.of(context);
    final weekDates = _getWeekDates(widget.selectedDate);

    return Column(
      children: [
        // Week header
        Container(
          height: 60,
          child: Row(
            children: weekDates.map((date) {
              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleDateSelection(date),
                  child: NeomorphicContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: isSelected ? 4 : 2,
                    isPressed: isSelected,
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : null,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.disabledColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected || isToday
                                ? theme.colorScheme.primary
                                : theme.textTheme.titleMedium?.color,
                            fontFamily: 'KWASU',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Week events
        Expanded(
          child: _buildWeekEvents(weekDates),
        ),
      ],
    );
  }

  Widget _buildWeekEvents(List<DateTime> weekDates) {
    final theme = Theme.of(context);
    final weekEvents = <DateTime, List<TimetableEvent>>{};
    
    for (final date in weekDates) {
      weekEvents[date] = _getEventsForDate(date);
    }

    return ListView.builder(
      itemCount: 24, // 24 hours
      itemBuilder: (context, hour) {
        return Container(
          height: 60,
          child: Row(
            children: [
              // Time label
              SizedBox(
                width: 60,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Events for each day
              Expanded(
                child: Row(
                  children: weekDates.map((date) {
                    final eventsAtHour = weekEvents[date]
                        ?.where((event) => event.startDateTime.hour == hour)
                        .toList() ?? [];

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          children: eventsAtHour.map((event) {
                            return GestureDetector(
                              onTap: () => widget.onEventTapped?.call(event),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(4),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: _getEventColor(event),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  event.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgendaView() {
    final theme = Theme.of(context);
    final groupedEvents = _groupEventsByDate();
    final sortedDates = groupedEvents.keys.toList()
      ..sort();

    if (sortedDates.isEmpty) {
      return NeomorphicContainer(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No events scheduled',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.disabledColor,
                  fontFamily: 'KWASU',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final events = groupedEvents[date]!;
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, widget.selectedDate);

        return NeomorphicContainer(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              GestureDetector(
                onTap: () => _handleDateSelection(date),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected || isToday
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('MMM dd, yyyy').format(date),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected || isToday
                              ? Colors.white
                              : theme.textTheme.titleMedium?.color,
                          fontFamily: 'KWASU',
                        ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${events.length} event${events.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Events for this date
              ...events.map((event) => _buildAgendaEventItem(event, theme)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgendaEventItem(TimetableEvent event, ThemeData theme) {
    return GestureDetector(
      onTap: () => widget.onEventTapped?.call(event),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getEventColor(event).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.left(
            width: 4,
            color: _getEventColor(event),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'KWASU',
                    ),
                  ),
                  if (event.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(event.startDateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getEventColor(event),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEventTypeLabel(event.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDateSelection(DateTime date) {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onDateSelected(date);
  }

  List<String> _getWeekdayLabels() {
    final List<String> weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    // Adjust for first day of week
    if (widget.firstDayOfWeek == DateTime.sunday) {
      weekdays.insert(0, weekdays.removeLast());
    }
    
    return weekdays;
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    
    // Find the first Monday (or configured first day) of the calendar grid
    int startOffset = (firstDay.weekday - widget.firstDayOfWeek) % 7;
    final startDate = firstDay.subtract(Duration(days: startOffset));
    
    // Generate 42 days (6 weeks) for consistent grid
    final List<DateTime> days = [];
    for (int i = 0; i < 42; i++) {
      days.add(startDate.add(Duration(days: i)));
    }
    
    return days;
  }

  List<DateTime> _getWeekDates(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - widget.firstDayOfWeek));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<TimetableEvent> _getEventsForDate(DateTime date) {
    return widget.events.where((event) {
      return _isSameDay(event.startDateTime, date);
    }).toList();
  }

  Map<DateTime, List<TimetableEvent>> _groupEventsByDate() {
    final Map<DateTime, List<TimetableEvent>> grouped = {};
    
    for (final event in widget.events) {
      final date = DateTime(
        event.startDateTime.year,
        event.startDateTime.month,
        event.startDateTime.day,
      );
      
      grouped.putIfAbsent(date, () => []).add(event);
    }
    
    return grouped;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _getEventColor(TimetableEvent event) {
    switch (event.type) {
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

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.electionStart:
        return 'Start';
      case EventType.electionEnd:
        return 'End';
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