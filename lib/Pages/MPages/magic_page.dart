import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/mesc/outfitAIHelper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MagicPage extends StatefulWidget {
  final VoidCallback onThemeChange;
  final DateTime? selectedDate;
  final bool fromCalendar;

  const MagicPage({
    super.key,
    required this.onThemeChange,
    this.selectedDate,
    required this.fromCalendar,
  });

  @override
  State<MagicPage> createState() => _MagicPageState();
}

class _MagicPageState extends State<MagicPage> {
  final OutfitAIHelper aiHelper = OutfitAIHelper();
  bool _loading = false;
  List<Map<String, dynamic>> recommendedItems = [];

  double selectedTemp = 22.0;
  String selectedSeason = 'Spring';
  String selectedModesty = 'None';
  String selectedOccasion = 'Casual';

  @override
  void initState() {
    super.initState();
    aiHelper.loadModel();
  }

  Map<String, List<Map<String, dynamic>>> groupBySubcategory(List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in items) {
      final sub = item['subcategory'] is Map ? item['subcategory']['name'] : item['subcategory'];
      if (sub != null) {
        grouped.putIfAbsent(sub, () => []).add(item);
      }
    }
    return grouped;
  }

  Map<String, dynamic>? pickRandomFromGrouped(Map<String, List<Map<String, dynamic>>> grouped) {
    if (grouped.isEmpty) return null;
    final subKeys = grouped.keys.toList()..shuffle();
    for (final key in subKeys) {
      final items = grouped[key];
      if (items != null && items.isNotEmpty) {
        return (items..shuffle()).first;
      }
    }
    return null;
  }

  Future<void> generateOutfit() async {
    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final res = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/wardrobe/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) {
final List<Map<String, dynamic>> wardrobe =
    (json.decode(res.body) as List).cast<Map<String, dynamic>>();

      final topsGrouped = groupBySubcategory(wardrobe.where((i) => i['category']['name'] == 'Tops').toList());
      final bottomsGrouped = groupBySubcategory(wardrobe.where((i) => i['category']['name'] == 'Bottoms').toList());
      final shoesGrouped = groupBySubcategory(wardrobe.where((i) => i['category']['name'] == 'Shoes').toList());
      final accessoriesGrouped = groupBySubcategory(wardrobe.where((i) => i['category']['name'] == 'Accessories').toList());

      final accessory = pickRandomFromGrouped(accessoriesGrouped);

      for (int i = 0; i < 10; i++) {
        final top = pickRandomFromGrouped(topsGrouped);
        final bottom = pickRandomFromGrouped(bottomsGrouped);
        final shoes = pickRandomFromGrouped(shoesGrouped);

        if (top == null || bottom == null || shoes == null) continue;

        final input = await encodeInput(
          temp: selectedTemp,
          season: selectedSeason,
          modesty: selectedModesty,
          occasion: selectedOccasion,
          top: top,
          bottom: bottom,
          shoes: shoes,
        );

        final compatible = await aiHelper.predict(input);

        if (compatible || Random().nextDouble() < 0.3) {
          setState(() {
            recommendedItems = [top, bottom, shoes, if (accessory != null) accessory];
            _loading = false;
          });
          return;
        }
      }

      setState(() {
        _loading = false;
        recommendedItems = [];
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> encodeInput({
    required double temp,
    required String season,
    required String modesty,
    required String occasion,
    required Map<String, dynamic> top,
    required Map<String, dynamic> bottom,
    required Map<String, dynamic> shoes,
  }) async {
    String getValue(dynamic field) => field is Map && field.containsKey('name') ? field['name'] : field.toString();
    String extractSubcategory(String full) => full.contains(' - ') ? full.split(' - ')[1] : full;

    List<String> subcats = [
      'T-shirts', 'Shirts', 'Long-sleeves', 'Sweatshirts & Hoodies', 'Sweaters & Cardigans', 'Jackets', 'Tank Tops',
      'Jeans', 'Shorts', 'Skirts', 'Formal-Trousers', 'Joggers / Sweatpants', 'Leggings', 'Cargo pants',
      'Sneakers', 'Formal Shoes', 'Sandals', 'Heels', 'Slippers',
      'Jewelry', 'Scarfs', 'Bags', 'Sunglasses', 'Watches', 'Belts', 'Hats / Caps / Beanies'
    ];
    List<String> colors = ['Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Beige', 'Gray', 'Brown', 'Orange'];
    List<String> materials = ['Cotton', 'Wool', 'Linen', 'Polyester', 'Silk', 'Denim', 'Canvas', 'Suede', 'Leather'];
    List<String> seasons = ['Winter', 'Spring', 'Summer', 'Autumn'];
    List<String> modestyOpts = ['None', 'Hijab-Friendly'];
    List<String> occasions = ['Casual', 'Work', 'Formal', 'Comfy', 'Chic', 'Sport', 'Classy'];

    List<double> encodeItem(Map<String, dynamic> item) {
      final sub = extractSubcategory(getValue(item['subcategory']));
      return [
        subcats.indexOf(sub).toDouble(),
        colors.indexOf(getValue(item['color'])).toDouble(),
        materials.indexOf(getValue(item['material'])).toDouble(),
        seasons.indexOf(getValue(item['season'])).toDouble(),
        0.0,
        0.0
      ];
    }

    return {
      'temp': temp,
      'season': seasons.indexOf(season).toDouble(),
      'modesty': modestyOpts.indexOf(modesty).toDouble(),
      'occasion': occasions.indexOf(occasion).toDouble(),
      'top': encodeItem(top),
      'bottom': encodeItem(bottom),
      'shoes': encodeItem(shoes),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Magic Outfit AI')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('Temp (°C)'),
                    Slider(
                      value: selectedTemp,
                      min: 5,
                      max: 35,
                      divisions: 30,
                      label: selectedTemp.round().toString(),
                      onChanged: (val) => setState(() => selectedTemp = val),
                    ),
                  ],
                ),
              ),
            ]),
            DropdownButton<String>(
              value: selectedSeason,
              items: ['Winter', 'Spring', 'Summer', 'Autumn']
                  .map((s) => DropdownMenuItem(value: s, child: Text('Season: $s')))
                  .toList(),
              onChanged: (val) => setState(() => selectedSeason = val!),
            ),
            DropdownButton<String>(
              value: selectedModesty,
              items: ['None', 'Hijab-Friendly']
                  .map((s) => DropdownMenuItem(value: s, child: Text('Modesty: $s')))
                  .toList(),
              onChanged: (val) => setState(() => selectedModesty = val!),
            ),
            DropdownButton<String>(
              value: selectedOccasion,
              items: ['Casual', 'Work', 'Formal', 'Comfy', 'Chic', 'Sport', 'Classy']
                  .map((s) => DropdownMenuItem(value: s, child: Text('Occasion: $s')))
                  .toList(),
              onChanged: (val) => setState(() => selectedOccasion = val!),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : generateOutfit,
              child: const Text('✨ Generate Outfit'),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : recommendedItems.isEmpty
                    ? const Text('No compatible outfit found.')
                    : Expanded(
                        child: GridView.builder(
                          itemCount: recommendedItems.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemBuilder: (context, index) {
                            final item = recommendedItems[index];
                            return Card(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      'http://10.0.2.2:8000${item['photo_path']}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                  Text(
                                    item['subcategory']['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      )
          ],
        ),
      ),
    );
  }
}
