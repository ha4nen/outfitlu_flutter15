// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_application_1/Pages/mesc/outfit_creation_page.dart';

class MagicPage extends StatefulWidget {
  final VoidCallback onThemeChange;
  final DateTime? selectedDate;

  const MagicPage({
    super.key,
    required this.onThemeChange,
    this.selectedDate,
    required bool fromCalendar,
  });

  @override
  State<MagicPage> createState() => _MagicPageState();
}

class _MagicPageState extends State<MagicPage> {
  int? selectedItemIndex;
  double _trulyAiScale = 1.0;
  double _makeYourOwnScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI/Create Outfit'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Click the button for a Truly AI Generated OUTFIT, Choose an Item to generate around that ITEM.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AnimationLimiter(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: GestureDetector(
                            onTap: () {
                              if (!mounted) return;
                              setState(() {
                                selectedItemIndex =
                                    selectedItemIndex == index ? null : index;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    selectedItemIndex == index
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.secondary
                                        : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      selectedItemIndex == index
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Theme.of(context).dividerColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Item ${index + 1}',
                                  style: TextStyle(
                                    color:
                                        selectedItemIndex == index
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onSecondary
                                            : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => setState(() => _trulyAiScale = 0.95),
              onTapUp: (_) => setState(() => _trulyAiScale = 1.0),
              child: AnimatedScale(
                scale: _trulyAiScale,
                duration: const Duration(milliseconds: 100),
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedItemIndex != null) {
                      print('Help with AI for Item ${selectedItemIndex! + 1}');
                    } else {
                      print('Truly AI button clicked');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    selectedItemIndex != null ? 'Help with AI' : 'Truly AI',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTapDown: (_) => setState(() => _makeYourOwnScale = 0.95),
              onTapUp: (_) => setState(() => _makeYourOwnScale = 1.0),
              child: AnimatedScale(
                scale: _makeYourOwnScale,
                duration: const Duration(milliseconds: 100),
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (_) => OutfitCreationPage(
                              selectedDate: widget.selectedDate,
                            ),
                      ),
                    );
                    if (result == true) {
                      Navigator.pop(context, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                  child: const Text('Make ur own'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
