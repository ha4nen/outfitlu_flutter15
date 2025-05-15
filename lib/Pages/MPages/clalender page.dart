import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/MPages/magic_page.dart';
import 'package:table_calendar/table_calendar.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _dayTapped = false;

  final Map<DateTime, List<String>> _events = {};

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _calendarFormat = CalendarFormat.week;
      _dayTapped = true;
    });
  }

  void _toggleCalendarFormat() {
    setState(() {
      _calendarFormat = CalendarFormat.month;
      _dayTapped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // Dynamic background color
      appBar: AppBar(
        title: const Text('Plan Your Look'),
        backgroundColor:
            Theme.of(
              context,
            ).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor:
            Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              availableCalendarFormats: const {
                CalendarFormat.month: '',
                CalendarFormat.week: '',
              },
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                leftChevronVisible: true,
                rightChevronVisible: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color, // Dynamic text color
                ),
                titleTextFormatter: (date, locale) {
                  return '${_monthName(date.month)} ${date.year}';
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.secondary, // Dynamic today color
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // Dynamic selected day color
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
              ),
            ),
          ),

          // Button to switch back to month view
          if (_calendarFormat == CalendarFormat.week)
            TextButton(
              onPressed: _toggleCalendarFormat,
              child: Text(
                'Show Full Month',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ), // Dynamic button text color
              ),
            ),

          // Expand section when a date is selected
          AnimatedCrossFade(
            crossFadeState:
                _dayTapped
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 400),
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                _buildEventCard(events),
                const SizedBox(height: 12),
                _buildOutfitImagePlaceholder(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(List<String> events) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              Theme.of(
                context,
              ).colorScheme.surface, // Dynamic card background color
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Plans for the Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.color, // Dynamic text color
              ),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Column(
                children: [
                  Text(
                    'No outfit planned.',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color, // Dynamic text color
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_awesome),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.primary, // Dynamic button color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MagicPage(
                                      onThemeChange: () {},
                                      fromCalendar: true,
                                    ),
                              ),
                            );
                          },
                          label: const Text('Create Your Outfit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(
                            Icons.checkroom,
                            color: Theme.of(context).colorScheme.onSurface,
                          ), // Dynamic icon color
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surface, // Dynamic button color
                            foregroundColor:
                                Theme.of(
                                  context,
                                ).colorScheme.onSurface, // Dynamic text color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Choose Your Outfit selected'),
                              ),
                            );
                          },
                          label: const Text('Choose Outfit'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Column(
                children:
                    events.map((event) {
                      return ListTile(
                        leading: Icon(
                          Icons.event,
                          color: Theme.of(context).colorScheme.primary,
                        ), // Dynamic icon color
                        title: Text(
                          event,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ), // Dynamic text color
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitImagePlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: AssetImage(
                'assets/outfit_placeholder.png',
              ), // Replace with actual asset
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Text(
              'Your planned outfit will appear here',
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.onSurface, // Dynamic text color
                fontWeight: FontWeight.bold,
                fontSize: 16,
                backgroundColor: Theme.of(context).colorScheme.surface
                    .withOpacity(0.7), // Dynamic background color
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
