// 🟠 Final UI polish: fixed top-left back arrow, consistent header, scroll fix, dot color, shorter button text, better alignment

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MyPlannerUI extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;
  final Map<String, List<String>> plannedOutfits;
  final VoidCallback onChooseOutfit;
  final VoidCallback onCreateOutfit;
  final String? outfitImageUrl;
  final VoidCallback? onSeeDetails;
  final VoidCallback? onBackToMonth;

  const MyPlannerUI({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.plannedOutfits,
    required this.onChooseOutfit,
    required this.onCreateOutfit,
    this.outfitImageUrl,
    this.onSeeDetails,
    this.onBackToMonth,
  });

  @override
  Widget build(BuildContext context) {
    final selectedKey = (selectedDay ?? focusedDay).toIso8601String().split('T').first;
    final hasEvent = plannedOutfits.containsKey(selectedKey);
    final bool isWeekView = calendarFormat == CalendarFormat.week;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 40, bottom: 20),
              color: const Color(0xFFFF9800),
              alignment: Alignment.center,
              child: const Text(
                "My Planner",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isWeekView && onBackToMonth != null)
              Positioned(
                top: 40,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBackToMonth,
                ),
              ),
          ],
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF3E0), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: calendarFormat,
            eventLoader: (day) {
              final key = day.toIso8601String().split('T').first;
              return plannedOutfits.containsKey(key) ? ['Planned'] : [];
            },
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
              CalendarFormat.week: '',
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                border: Border.all(color: Color(0xFFFF9800), width: 2),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFFEF6C00), // 🔶 Darker orange for dot
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFFFF9800),
                fontWeight: FontWeight.bold,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFFFF9800)),
              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFFFF9800)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
            child: hasEvent
                ? Column(
                    children: [
                      const Icon(Icons.checkroom, size: 80, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("You have an outfit planned!", style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      if (outfitImageUrl != null)
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.orange.shade200, width: 1.5),
    borderRadius: BorderRadius.circular(12),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.network(
      outfitImageUrl!,
      width: double.infinity,
      height: 400,
      fit: BoxFit.contain,
    ),
  ),
),

                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: onSeeDetails,
                              child: const Text(
                                "See the outfit details >",
                                style: TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.orange.shade300, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(32),
                        child: const Icon(Icons.checkroom, size: 80, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text("You don’t have any outfit planned for this day!", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onChooseOutfit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9800),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("CHOOSE OUTFIT", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: onCreateOutfit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFEF6C00),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text("CREATE OUTFIT", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
          ),
        )
      ],
    );
  }
}
