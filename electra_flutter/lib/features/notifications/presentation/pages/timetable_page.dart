import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/neomorphic_container.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/timetable_event.dart';
import '../providers/timetable_providers.dart';
import '../providers/notification_state.dart';
import '../widgets/timetable_calendar.dart';
import '../widgets/countdown_timer.dart';

/// Timetable page displaying calendar events and election schedules
/// 
/// Features:
/// - Calendar view with elections and deadlines
/// - Countdown timers for active elections
/// - Event filtering and search
/// - Offline-first with sync status
/// - Neomorphic KWASU-themed design
class TimetablePage extends ConsumerStatefulWidget {
  const TimetablePage({super.key});

  @override
  ConsumerState<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends ConsumerState<TimetablePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  CalendarView _currentView = CalendarView.month;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  EventType? _selectedEventType;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timetableProvider.notifier).loadEvents();
      ref.read(countdownProvider.notifier).startCountdowns();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timetableState = ref.watch(timetableProvider);
    final countdownState = ref.watch(countdownProvider);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () => _handleRefresh(),
          child: CustomScrollView(
            slivers: [
              // Search and filters
              SliverToBoxAdapter(
                child: _buildSearchAndFilters(theme),
              ),
              
              // Active countdowns
              if (countdownState.activeCountdowns.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildActiveCountdowns(theme, countdownState),
                ),
              
              // Calendar view
              SliverToBoxAdapter(
                child: _buildCalendarSection(theme, timetableState),
              ),
              
              // Events list
              SliverToBoxAdapter(
                child: _buildEventsSection(theme, timetableState),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      title: const Text(
        'Election Timetable',
        style: TextStyle(
          fontFamily: 'KWASU',
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.textTheme.titleLarge?.color,
      actions: [
        // View selector
        PopupMenuButton<CalendarView>(
          onSelected: (view) {
            setState(() {
              _currentView = view;
            });
            ref.read(timetableProvider.notifier).updateCalendarView(view);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: CalendarView.month,
              child: Row(
                children: [
                  Icon(Icons.calendar_month),
                  SizedBox(width: 8),
                  Text('Month View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CalendarView.week,
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week),
                  SizedBox(width: 8),
                  Text('Week View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: CalendarView.agenda,
              child: Row(
                children: [
                  Icon(Icons.list),
                  SizedBox(width: 8),
                  Text('Agenda View'),
                ],
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.view_module),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search bar
          NeomorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                ref.read(timetableProvider.notifier).searchEvents(value);
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                          ref.read(timetableProvider.notifier).clearSearch();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Event type filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', null, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Elections', EventType.electionStart, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Deadlines', EventType.registrationDeadline, theme),
                const SizedBox(width: 8),
                _buildFilterChip('Results', EventType.resultAnnouncement, theme),
                const SizedBox(width: 8),
                _buildFilterChip('System', EventType.systemMaintenance, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, EventType? type, ThemeData theme) {
    final isSelected = _selectedEventType == type;
    
    return NeomorphicContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      isPressed: isSelected,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedEventType = type;
          });
          ref.read(timetableProvider.notifier).filterByType(type);
        },
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCountdowns(ThemeData theme, CountdownState countdownState) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Elections',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'KWASU',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: countdownState.activeCountdowns.length,
              itemBuilder: (context, index) {
                final eventId = countdownState.activeCountdowns.keys.elementAt(index);
                final countdown = countdownState.activeCountdowns[eventId]!;
                final event = countdownState.countdownEvents[eventId];
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: CountdownTimer(
                    event: event!,
                    timeRemaining: countdown,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection(ThemeData theme, TimetableState timetableState) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: NeomorphicContainer(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: 'KWASU',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _navigateMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      onPressed: () => _navigateMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TimetableCalendar(
              selectedDate: _selectedDate,
              events: timetableState.events,
              calendarView: _currentView,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                ref.read(timetableProvider.notifier).selectDate(date);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsSection(ThemeData theme, TimetableState timetableState) {
    final eventsToShow = _searchQuery.isNotEmpty
        ? timetableState.filteredEvents
        : timetableState.events
            .where((event) =>
                _selectedEventType == null ||
                event.type == _selectedEventType)
            .toList();

    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'KWASU',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          if (timetableState.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (eventsToShow.isEmpty)
            NeomorphicContainer(
              padding: const EdgeInsets.all(24.0),
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
                      'No events found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters or search terms',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: eventsToShow.length,
              itemBuilder: (context, index) {
                final event = eventsToShow[index];
                return _buildEventCard(event, theme);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(TimetableEvent event, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeomorphicContainer(
        padding: const EdgeInsets.all(16.0),
        child: InkWell(
          onTap: () => _showEventDetails(event),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type, theme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getEventTypeLabel(event.type),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(event.startDateTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (event.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    event.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (event.status == EventStatus.active)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
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

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () => _showCreateEventDialog(),
      backgroundColor: theme.colorScheme.primary,
      child: const Icon(Icons.add),
    );
  }

  void _navigateMonth(int direction) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + direction,
        1,
      );
    });
    ref.read(timetableProvider.notifier).loadMonth(_selectedDate);
  }

  Future<void> _handleRefresh() async {
    await ref.read(timetableProvider.notifier).refreshEvents();
    await ref.read(syncProvider.notifier).syncEventsData();
  }

  void _showEventDetails(TimetableEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.disabledColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Event details
                  Text(
                    event.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'KWASU',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getEventTypeLabel(event.type),
                    style: TextStyle(
                      color: _getEventTypeColor(event.type, theme),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time and duration
                  _buildDetailRow(
                    'Start Time',
                    DateFormat('EEEE, MMMM dd, yyyy at HH:mm')
                        .format(event.startDateTime),
                    theme,
                  ),
                  if (event.endDateTime != null)
                    _buildDetailRow(
                      'End Time',
                      DateFormat('EEEE, MMMM dd, yyyy at HH:mm')
                          .format(event.endDateTime!),
                      theme,
                    ),
                  
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _subscribeToEventNotifications(event);
                          },
                          icon: const Icon(Icons.notifications),
                          label: const Text('Get Reminders'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _shareEvent(event);
                          },
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.disabledColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    // This would typically navigate to an event creation page
    // or show a dialog for creating new events
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event creation not available in this view'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _subscribeToEventNotifications(TimetableEvent event) {
    ref.read(eventNotificationProvider.notifier)
        .subscribeToEventNotifications(
          event.id,
          const Duration(hours: 1),
        );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Subscribed to notifications for ${event.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareEvent(TimetableEvent event) {
    // Implement event sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event sharing not implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getEventTypeColor(EventType type, ThemeData theme) {
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
        return theme.colorScheme.primary;
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.electionStart:
        return 'Election Start';
      case EventType.electionEnd:
        return 'Election End';
      case EventType.registrationDeadline:
        return 'Registration Deadline';
      case EventType.resultAnnouncement:
        return 'Results';
      case EventType.systemMaintenance:
        return 'Maintenance';
      default:
        return 'Event';
    }
  }
}