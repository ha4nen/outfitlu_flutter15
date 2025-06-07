import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_application_1/Pages/Outfits/outfit.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart';

class ChooseOutfitPage extends StatefulWidget {
  const ChooseOutfitPage({super.key});

  @override
  State<ChooseOutfitPage> createState() => _ChooseOutfitPageState();
}

class _ChooseOutfitPageState extends State<ChooseOutfitPage> {
  Map<String, List<Outfit>> outfitsBySeason = {};
  bool isLoading = true;
  String selectedTag = '';
  bool showHijabOnly = false;
  String sortBy = 'Newest';

  final List<String> tagOptions = [
    'All',
    'Casual',
    'Hijab',
    'Work',
    'Formal',
    'Comfy',
    'Chic',
    'Sport',
    'Classy',
  ];

  @override
  void initState() {
    super.initState();
    fetchOutfits();
  }

  Future<void> fetchOutfits() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/outfits/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final List<Outfit> allOutfits =
          data.map((e) => Outfit.fromJson(e)).toList();

      final Map<String, List<Outfit>> grouped = {};
      for (final outfit in allOutfits) {
        final season = outfit.season ?? 'Unknown';
        grouped.putIfAbsent(season, () => []).add(outfit);
      }

      setState(() {
        outfitsBySeason = grouped;
        isLoading = false;
      });
    } else {
      print("❌ Failed to load outfits: ${response.body}");
    }
  }

  List<Outfit> filterOutfits(List<Outfit> outfits) {
    List<Outfit> filtered =
        outfits.where((outfit) {
          final matchesTag =
              selectedTag.isEmpty ||
              (outfit.tags != null &&
                  outfit.tags!.toLowerCase().contains(
                    selectedTag.toLowerCase(),
                  ));
          final matchesHijab = !showHijabOnly || outfit.isHijabFriendly;
          return matchesTag && matchesHijab;
        }).toList();

    filtered.sort(
      (a, b) =>
          sortBy == 'Newest' ? b.id.compareTo(a.id) : a.id.compareTo(b.id),
    );
    return filtered;
  }

  int _tagCount(String tag, List<Outfit> outfits) {
    if (tag == 'All') return outfits.length;
    if (tag == 'Hijab') {
      return outfits.where((o) => o.isHijabFriendly).length;
    }
    return outfits
        .where(
          (o) =>
              o.tags != null &&
              o.tags!.toLowerCase().contains(tag.toLowerCase()),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Outfit"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFFF9800), height: 1),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tag in tagOptions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  tag == 'Hijab'
                                      ? 'Hijab Friendly (${_tagCount(tag, outfitsBySeason.values.expand((e) => e).toList())})'
                                      : '$tag (${_tagCount(tag, outfitsBySeason.values.expand((e) => e).toList())})',
                                  style: TextStyle(
                                    color:
                                        selectedTag == (tag == 'All' ? '' : tag)
                                            ? Colors.white
                                            : const Color(0xFF2F1B0C),
                                  ),
                                ),
                                selected:
                                    tag == 'Hijab'
                                        ? showHijabOnly
                                        : selectedTag ==
                                            (tag == 'All' ? '' : tag),
                                selectedColor: const Color(0xFFFF9800),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(
                                    color: Color(0xFFFFE0B2),
                                  ),
                                ),
                                onSelected: (_) {
                                  setState(() {
                                    if (tag == 'Hijab') {
                                      showHijabOnly = !showHijabOnly;
                                    } else {
                                      final newTag = tag == 'All' ? '' : tag;
                                      selectedTag =
                                          selectedTag == newTag ? '' : newTag;
                                    }
                                  });
                                },
                              ),
                            ),
                          ChoiceChip(
                            label: const Text('Newest'),
                            selected: sortBy == 'Newest',
                            selectedColor: const Color(0xFFFF9800),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFFFFE0B2)),
                            ),
                            onSelected: (_) {
                              setState(() => sortBy = 'Newest');
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Oldest'),
                            selected: sortBy == 'Oldest',
                            selectedColor: const Color(0xFFFF9800),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFFFFE0B2)),
                            ),
                            onSelected: (_) {
                              setState(() => sortBy = 'Oldest');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children:
                          outfitsBySeason.entries.map((entry) {
                            final season = entry.key;
                            final outfits = filterOutfits(entry.value);

                            if (outfits.isEmpty) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      season,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12.0,
                                          mainAxisSpacing: 12.0,
                                          childAspectRatio: 0.75,
                                        ),
                                    itemCount: outfits.length,
                                    itemBuilder: (context, index) {
                                      final outfit = outfits[index];
                                      return GestureDetector(
                                        onTap:
                                            () =>
                                                Navigator.pop(context, outfit),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade300,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              outfit.photoPath ?? '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              errorBuilder:
                                                  (_, __, ___) => const Center(
                                                    child: Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
    );
  }
}
