import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/MPages/magic_page.dart';
import 'package:flutter_application_1/Pages/mesc/ChooseOutfitPage.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart';
import 'package:flutter_application_1/Pages/Outfits/outfit.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<String, List<OutfitPlan>> _plannedOutfits = {};

  @override
  void initState() {
    super.initState();
    _fetchPlannedOutfits();
  }

  Future<void> _fetchPlannedOutfits() async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/planner/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final Map<String, List<OutfitPlan>> parsedPlans = {};

      for (final item in data) {
        try {
          final plan = OutfitPlan.fromJson(item);
          final key = plan.date.toIso8601String().split('T').first;
          parsedPlans.putIfAbsent(key, () => []).add(plan);
        } catch (e) {
          print('Error parsing plan: $e');
        }
      }

      setState(() => _plannedOutfits = parsedPlans);
    } else {
      print("Failed to fetch planned outfits: ${response.statusCode}");
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _calendarFormat = CalendarFormat.week;
    });
  }

  Future<void> _assignOutfitToDate(int outfitId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final selectedDate = _selectedDay;

    if (token == null || selectedDate == null) return;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/planner/plan/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'outfit_id': outfitId,
        'date': selectedDate.toIso8601String().split('T').first,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Outfit assigned to date!")),
      );
      _fetchPlannedOutfits();
    } else {
      print("❌ Failed to assign outfit: ${response.body}");
    }
  }

  Future<void> _deletePlannedOutfit(int planId) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/planner/$planId/delete/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Planned outfit deleted.")),
      );
      _fetchPlannedOutfits();
    } else {
      print("❌ Failed to delete planned outfit: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateKey = (_selectedDay ?? _focusedDay)
        .toIso8601String()
        .split('T')
        .first;
    final events = _plannedOutfits[selectedDateKey] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Your Look')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              final key = day.toIso8601String().split('T').first;
              return _plannedOutfits.containsKey(key) ? ['Planned'] : [];
            },
            onDaySelected: _onDaySelected,
            onPageChanged: (day) => setState(() => _focusedDay = day),
            availableCalendarFormats: const {
              CalendarFormat.month: '',
              CalendarFormat.week: '',
            },
            calendarStyle: const CalendarStyle(outsideDaysVisible: false),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              headerTitleBuilder: (context, date) {
                return GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _focusedDay,
                      firstDate: DateTime.utc(2020, 1, 1),
                      lastDate: DateTime.utc(2100, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        _focusedDay = picked;
                        _selectedDay = picked;
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      '${_monthName(date.month)} ${date.year}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_calendarFormat == CalendarFormat.week)
            TextButton(
              onPressed: () => setState(() => _calendarFormat = CalendarFormat.month),
              child: const Text('Show Full Month'),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: events.isNotEmpty ? _buildOutfitCard(events.first) : _buildEmptyState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(OutfitPlan plan) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "This is your planned outfit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                plan.outfitImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 160,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Column(
                children: [
                  Text(
                    plan.outfitDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutfitDetailsPage(
                          outfit: Outfit(
                            id: plan.outfitId,
                            description: plan.outfitDescription,
                            photoPath: plan.outfitImageUrl,
                            type: plan.outfitType,
                            season: plan.outfitSeason,
                            tags: plan.outfitTags,
                            isHijabFriendly: plan.isHijabFriendly,
                          ),
                        ),
                      ),
                    ),
                    child: Text(
                      'See the outfit details >',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Planned Outfit"),
                          content: const Text("Are you sure you want to delete this planned outfit?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _deletePlannedOutfit(plan.id);
                      }
                    },
                    child: const Text("Delete Planned Outfit"),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("No outfit planned for this day."),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MagicPage(
                      onThemeChange: () {},
                      fromCalendar: true,
                      selectedDate: _selectedDay,
                    ),
                  ),
                );
                if (result == true) _fetchPlannedOutfits();
              },
              child: const Text('Create Your Outfit'),
            ),
            ElevatedButton(
              onPressed: () async {
                final selectedOutfit = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChooseOutfitPage()),
                );
                if (selectedOutfit != null) {
                  await _assignOutfitToDate(selectedOutfit.id);
                }
              },
              child: const Text('Choose Existing Outfit'),
            ),
          ],
        ),
      );
}

class OutfitPlan {
  final int id;
  final int outfitId;
  final DateTime date;
  final String outfitImageUrl;
  final String outfitDescription;
  final String? outfitType;
  final String? outfitSeason;
  final String? outfitTags;
  final bool isHijabFriendly;

  OutfitPlan({
    required this.id,
    required this.outfitId,
    required this.date,
    required this.outfitImageUrl,
    required this.outfitDescription,
    this.outfitType,
    this.outfitSeason,
    this.outfitTags,
    required this.isHijabFriendly,
  });

  factory OutfitPlan.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    final rawPath = json['outfit']['photo_path'] ?? '';
    final cleanPath = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    final fullUrl = 'http://10.0.2.2:8000$cleanPath';

    return OutfitPlan(
      id: json['id'],
      outfitId: json['outfit']['id'],
      date: DateTime.utc(date.year, date.month, date.day),
      outfitImageUrl: fullUrl,
      outfitDescription: json['outfit']['description'] ?? '',
      outfitType: json['outfit']['type'],
      outfitSeason: json['outfit']['season'],
      outfitTags: json['outfit']['tags'],
      isHijabFriendly: json['outfit']['is_hijab_friendly'] ?? false,
    );
  }
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

String _monthName(int month) {
  const months = [
    '',
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month];
}