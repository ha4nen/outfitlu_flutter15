import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart';
import 'package:flutter_application_1/Pages/Outfits/outfit.dart';

class ChooseOutfitPage extends StatefulWidget {
  const ChooseOutfitPage({super.key});

  @override
  State<ChooseOutfitPage> createState() => _ChooseOutfitPageState();
}

class _ChooseOutfitPageState extends State<ChooseOutfitPage> {
  Map<String, List<Outfit>> outfitsBySeason = {};
  bool isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Outfit')),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children:
                    outfitsBySeason.entries.map((entry) {
                      final season = entry.key;
                      final outfits = entry.value;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                season,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                              itemCount: outfits.length,
                              itemBuilder: (context, index) {
                                final outfit = outfits[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context, outfit);
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            outfit.photoPath ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (_, __, ___) => const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        outfit.description ?? 'No description',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
    );
  }
}
