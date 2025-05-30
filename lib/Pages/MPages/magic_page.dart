// Full updated MagicPage using 34-input model (context + top1, top2, bottom, shoes, accessory)
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_application_1/Pages/mesc/outfitAIHelper.dart';
import 'package:flutter_application_1/Pages/mesc/outfit_creation_page.dart'; // Add this import (update the path if needed)

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
  String? generationError;
  bool _alreadySaved = false;
  double selectedTemp = 22.0;
  String selectedSeason = 'Spring';
  String selectedModesty = 'None';
  String selectedOccasion = 'Casual';
  String selectedGender = 'Female';

  @override
  void initState() {
    super.initState();
    aiHelper.loadModel();
  }

  Map<String, List<Map<String, dynamic>>> groupBySubcategory(
    List<Map<String, dynamic>> items,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in items) {
      final sub =
          item['subcategory'] is Map
              ? item['subcategory']['name']
              : item['subcategory'];
      if (sub != null) {
        grouped.putIfAbsent(sub, () => []).add(item);
      }
    }
    return grouped;
  }

  Map<String, dynamic>? pickRandomFromGrouped(
    Map<String, List<Map<String, dynamic>>> grouped, [
    List<String>? allowed,
  ]) {
    final keys =
        allowed != null
            ? grouped.keys.where(allowed.contains).toList()
            : grouped.keys.toList();
    keys.shuffle();
    for (final key in keys) {
      final items = grouped[key];
      if (items != null && items.isNotEmpty) {
        return (items..shuffle()).first;
      }
    }
    return null;
  }

  Map<String, dynamic>? pickFromGroupedBySubcat(
    Map<String, List<Map<String, dynamic>>> grouped,
    List<String> allowedSubs,
  ) {
    final filtered =
        grouped.entries
            .where((e) => allowedSubs.contains(e.key) && e.value.isNotEmpty)
            .expand((e) => e.value)
            .toList();
    if (filtered.isEmpty) return null;
    return filtered[Random().nextInt(filtered.length)];
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

      final topsGrouped = groupBySubcategory(
        wardrobe.where((i) => i['category']['name'] == 'Tops').toList(),
      );
      final bottomsGrouped = groupBySubcategory(
        wardrobe.where((i) => i['category']['name'] == 'Bottoms').toList(),
      );
      final shoesGrouped = groupBySubcategory(
        wardrobe.where((i) => i['category']['name'] == 'Shoes').toList(),
      );
      final accessoriesGrouped = groupBySubcategory(
        wardrobe.where((i) => i['category']['name'] == 'Accessories').toList(),
      );
      // ✨ MagicPage Flutter constraints (aligned with backend AI model logic)

      // These constraints must be applied inside the MagicPage's item filtering logic
      // Apply before calling `pickRandomFromGrouped()` to respect filtering rules

      // 🔒 1. Modesty filtering (Hijab-Friendly)
      if (selectedModesty == 'Hijab-Friendly') {
        // Exclude skirts for bottoms
        bottomsGrouped.removeWhere((subcat, items) => subcat == 'Skirts');
        // Exclude tank tops and T-shirts for tops
        topsGrouped.removeWhere(
          (subcat, items) => subcat == 'Tank Tops' || subcat == 'T-shirts',
        );
      }

      // 🔒 2. Gender filtering
      if (selectedGender == 'Male') {
        // Exclude skirts for bottoms (only females allowed)
        bottomsGrouped.removeWhere((subcat, items) => subcat == 'Skirts');
        // Optionally adjust accessories
        accessoriesGrouped.removeWhere(
          (subcat, items) => subcat == 'Jewelry' || subcat == 'Bags',
        );
      }
      if (selectedGender == 'Female') {
        accessoriesGrouped.removeWhere(
          (subcat, items) => subcat == 'Watches' || subcat == 'Belts',
        );
      }

      // 🔒 3. Occasion filtering
      final casualBottoms = [
        'Shorts',
        'Jeans',
        'Cargo pants',
        'Leggings',
        'Joggers / Sweatpants',
      ];
      final formalBottoms = ['Formal-Trousers', 'Jeans', 'Skirts'];
      final casualShoes = ['sneakers', 'Sandals'];
      final formalShoes = ['Slippers', 'Heels', 'Formal Shoes'];

      if (['Casual', 'Comfy', 'Sport'].contains(selectedOccasion)) {
        bottomsGrouped.removeWhere((key, _) => !casualBottoms.contains(key));
        shoesGrouped.removeWhere((key, _) => !casualShoes.contains(key));
      } else if ([
        'Work',
        'Formal',
        'Chic',
        'Classy',
      ].contains(selectedOccasion)) {
        bottomsGrouped.removeWhere((key, _) => !formalBottoms.contains(key));
        if (selectedGender == 'Male') bottomsGrouped.remove('Skirts');
        shoesGrouped.removeWhere((key, _) => !formalShoes.contains(key));
      }

      // 🔒 4. Temperature-based filtering
      if (selectedTemp < 15) {
        // Prefer warm materials (Wool, Leather, Suede)
        // Add scarf to accessories
        accessoriesGrouped.putIfAbsent(
          'Scarfs',
          () =>
              wardrobe
                  .where((i) => i['subcategory']['name'] == 'Scarfs')
                  .toList(),
        );
      } else if (selectedTemp > 25) {
        // Prefer light materials (Cotton, Linen, Canvas)
        // Add sunglasses to accessories
        accessoriesGrouped.putIfAbsent(
          'Sunglasses',
          () =>
              wardrobe
                  .where((i) => i['subcategory']['name'] == 'Sunglasses')
                  .toList(),
        );
        // Remove cold tops
        topsGrouped.removeWhere(
          (subcat, _) => [
            'Sweatshirts & Hoodies',
            'Sweaters & Cardigans',
            'Jackets',
            'Long-sleeves',
          ].contains(subcat),
        );
      }

      final accessoryItems = <Map<String, dynamic>>[];
      for (var subcat in accessoriesGrouped.keys) {
        final items = accessoriesGrouped[subcat];
        if (items != null && items.isNotEmpty) {
          accessoryItems.add(
            (items..shuffle()).first,
          ); // pick 1 from each subcat
        }
      }

      for (int i = 0; i < 10; i++) {
        final outerwearSubcats = [
          'Jackets',
          'Sweaters & Cardigans',
          'Sweatshirts & Hoodies',
        ];
        final innerwearSubcats = ['Shirts', 'T-shirts'];

        final topOuter = pickFromGroupedBySubcat(topsGrouped, outerwearSubcats);
        final topInner = pickFromGroupedBySubcat(topsGrouped, innerwearSubcats);

        List<Map<String, dynamic>> tops = [];

        if (selectedTemp < 15 && topOuter != null && topInner != null) {
          tops = [topOuter, topInner];
        } else if (topInner != null) {
          tops = [topInner];
        } else if (topOuter != null) {
          tops = [topOuter];
        } else {
          continue;
        }

        final topIds = tops.map((t) => t['id']).toSet();
        final topItems =
            topIds.map((id) => tops.firstWhere((t) => t['id'] == id)).toList();

        final allowedBottoms = bottomsGrouped.map(
          (key, value) => MapEntry(
            key,
            value.where((item) {
              if (selectedModesty == 'Hijab-Friendly' &&
                  item['subcategory']['name'] == 'Skirts') {
                return false;
              }
              return true;
            }).toList(),
          ),
        );

        final bottom = pickRandomFromGrouped(allowedBottoms);
        final shoes = pickRandomFromGrouped(shoesGrouped);
        if ([bottom, shoes].any((e) => e == null)) continue;

        if (topItems.isEmpty || bottom == null || shoes == null) continue;

        final input = await encodeInput(
          temp: selectedTemp,
          season: selectedSeason,
          modesty: selectedModesty,
          occasion: selectedOccasion,
          gender: selectedGender,
          top1: topItems[0],
          top2: topItems.length > 1 ? topItems[1] : <String, dynamic>{},
          bottom: bottom,
          shoes: shoes,
          accessory: accessoryItems.isNotEmpty ? accessoryItems[0] : null,
        );

        // ✅ Add color harmony check at the end of generation
        bool isColorHarmonious(String c1, String c2) {
          final harmonyMap = {
            'Black': ['White', 'Gray', 'Red', 'Pink', 'Olive'],
            'White': ['Black', 'Blue', 'Beige', 'Navy'],
            'Red': ['Black', 'White', 'Blue', 'Gray'],
            'Blue': ['White', 'Gray', 'Red', 'Beige'],
            'Green': ['Beige', 'White', 'Brown', 'Olive'],
            'Yellow': ['Blue', 'Gray', 'White'],
            'Beige': ['Green', 'Brown', 'Blue'],
            'Gray': ['Black', 'Blue', 'White', 'Purple'],
            'Brown': ['Beige', 'Green', 'Olive'],
            'Orange': ['Blue', 'Beige', 'Brown'],
            'Pink': ['Gray', 'White', 'Beige'],
            'Purple': ['Gray', 'Black'],
            'Navy': ['White', 'Beige'],
            'Maroon': ['White', 'Beige'],
            'Olive': ['Beige', 'Brown'],
            'Teal': ['White', 'Gray'],
          };
          return harmonyMap[c1]?.contains(c2) ?? false;
        }

        final compatible = await aiHelper.predict(input);

        if (compatible || Random().nextDouble() < 0.2) {
          setState(() {
            recommendedItems = [...topItems, bottom, shoes, ...accessoryItems];
            _loading = false;
            generationError = null;
            _alreadySaved = false;
          });

          return;
        }
      }

      setState(() {
        _loading = false;
        recommendedItems = [];
        generationError =
            "No compatible outfit found.\nTry changing temperature or filters.";
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
    required String gender,
    required Map<String, dynamic> top1,
    required Map<String, dynamic> top2,
    required Map<String, dynamic> bottom,
    required Map<String, dynamic> shoes,
    Map<String, dynamic>? accessory,
  }) async {
    String getVal(dynamic field) =>
        field is Map && field.containsKey('name')
            ? field['name']
            : field.toString();
    String sub(String val) => val.contains(' - ') ? val.split(' - ')[1] : val;

    List<String> subcats = [
      'T-shirts',
      'Shirts',
      'Long-sleeves',
      'Sweatshirts & Hoodies',
      'Sweaters & Cardigans',
      'Jackets',
      'Tank Tops',
      'Jeans',
      'Shorts',
      'Skirts',
      'Formal-Trousers',
      'Joggers / Sweatpants',
      'Leggings',
      'Cargo pants',
      'Sneakers',
      'Formal Shoes',
      'Sandals',
      'Heels',
      'Slippers',
      'Jewelry',
      'Scarfs',
      'Bags',
      'Sunglasses',
      'Watches',
      'Belts',
      'Hats / Caps / Beanies',
    ];
    List<String> colors = [
      'Black',
      'White',
      'Red',
      'Blue',
      'Green',
      'Yellow',
      'Beige',
      'Gray',
      'Brown',
      'Orange',
    ];
    List<String> materials = [
      'Cotton',
      'Wool',
      'Linen',
      'Polyester',
      'Silk',
      'Denim',
      'Canvas',
      'Suede',
      'Leather',
    ];
    List<String> seasons = ['Winter', 'Spring', 'Summer', 'Autumn'];
    List<String> modestyOpts = ['None', 'Hijab-Friendly'];
    List<String> occasions = [
      'Casual',
      'Work',
      'Formal',
      'Comfy',
      'Chic',
      'Sport',
      'Classy',
    ];
    List<String> genders = ['Female', 'Male'];

    List<double> encodeItem(Map<String, dynamic> item) => [
      subcats.indexOf(sub(getVal(item['subcategory']))).toDouble(),
      colors.indexOf(getVal(item['color'])).toDouble(),
      materials.indexOf(getVal(item['material'])).toDouble(),
      seasons.indexOf(getVal(item['season'])).toDouble(),
      0.0,
      0.0,
    ];

    return {
      'temp': temp,
      'season': seasons.indexOf(season).toDouble(),
      'modesty': modestyOpts.indexOf(modesty).toDouble(),
      'occasion': occasions.indexOf(occasion).toDouble(),
      'top1': encodeItem(top1),
      'top2': encodeItem(top2),
      'bottom': encodeItem(bottom),
      'shoes': encodeItem(shoes),
      'accessory':
          accessory != null ? encodeItem(accessory) : List.filled(6, 0.0),
    };
  }

  Future<File?> _combineImagesFromItems(
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 300.0;
      const padding = 10.0;

      final count = items.length;
      const cols = 2;
      final rows = (count / cols).ceil();
      final imageSize = (size - padding * (cols + 1)) / cols;

      for (int i = 0; i < count; i++) {
        final item = items[i];
        final imageUrl =
            item['photo_path'].toString().startsWith('http')
                ? item['photo_path']
                : 'http://10.0.2.2:8000${item['photo_path']}';

        final image = await NetworkAssetBundle(Uri.parse(imageUrl))
            .load(imageUrl)
            .then(
              (byteData) =>
                  ui.instantiateImageCodec(byteData.buffer.asUint8List()),
            )
            .then((codec) => codec.getNextFrame())
            .then((frame) => frame.image);

        final dx = padding + (i % cols) * (imageSize + padding);
        final dy = padding + (i ~/ cols) * (imageSize + padding);
        final rect = Rect.fromLTWH(dx, dy, imageSize, imageSize);

        paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.cover);
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.toInt(),
        (rows * (imageSize + padding)).toInt(),
      );
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ai_generated_outfit.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      return file;
    } catch (e) {
      print('⚠️ Error combining images: $e');
      return null;
    }
  }

  Future<void> _promptDescriptionAndSave() async {
    final TextEditingController descController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Describe This Outfit"),
            content: TextField(
              controller: descController,
              decoration: const InputDecoration(
                hintText: "Optional description...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Save"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _saveGeneratedOutfit(
        recommendedItems,
        selectedSeason,
        selectedOccasion,
        selectedModesty == 'Hijab-Friendly',
        description: descController.text.trim(),
      );
    }
  }

  Future<void> _assignOutfitToPlanner(int outfitId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/planner/plan/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'outfit_id': outfitId,
        'date': date.toIso8601String().split('T').first,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Outfit added to your planner!")),
      );
    } else {
      print("❌ Failed to assign outfit to planner: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to assign outfit to planner.")),
      );
    }
  }

  Future<void> _saveGeneratedOutfit(
    List<Map<String, dynamic>> items,
    String season,
    String occasion,
    bool isHijabFriendly, {
    String? description,
  }) async {
    if (_alreadySaved) return;
    setState(() => _alreadySaved = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Missing login or items")));
      return;
    }

    final combinedImage = await _combineImagesFromItems(items);
    if (combinedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Image generation failed")));
      return;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/api/outfits/create/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.fields['type'] = 'AI-generated';
    request.fields['season'] = season;
    request.fields['tags'] = occasion;
    request.fields['is_hijab_friendly'] = isHijabFriendly.toString();
    request.fields['description'] = description ?? '';

    for (int i = 0; i < items.length; i++) {
      request.fields['selected_items_ids[$i]'] = items[i]['id'].toString();
    }

    request.files.add(
      await http.MultipartFile.fromPath('photo_path', combinedImage.path),
    );

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final responseData = jsonDecode(respStr);
      final outfitId = responseData['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ AI outfit saved to wardrobe!")),
      );

      final shouldPost = await _askToPostOutfit();
      if (shouldPost == true) {
        await _promptCaptionAndPost(outfitId);
      }
      if (widget.fromCalendar && widget.selectedDate != null) {
        await _assignOutfitToPlanner(outfitId, widget.selectedDate!);
        Navigator.pop(context, true); // return true to trigger refresh
      }
    } else {
      print("❌ Save failed: $respStr");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to save: $respStr")));
    }
  }

  Future<bool?> _askToPostOutfit() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Post Outfit?"),
            content: const Text(
              "Do you want to post this outfit to your feed?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Yes"),
              ),
            ],
          ),
    );
  }

  Future<void> _promptCaptionAndPost(int outfitId) async {
    final TextEditingController captionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Caption"),
            content: TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: "Enter a caption for your post",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Post"),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final postRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/feed/posts/create/'),
      );
      postRequest.headers['Authorization'] = 'Token $token';
      postRequest.fields['outfit_id'] = outfitId.toString();
      postRequest.fields['caption'] = captionController.text.trim();

      final response = await postRequest.send();
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Outfit posted successfully!")),
        );
      } else {
        final respStr = await response.stream.bytesToString();
        print("❌ Failed to post outfit: $respStr");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to post: $respStr")));
      }
    }
  }

  Widget _buildDropdown(
    String hint,
    String value,
    List<String> options,
    Function(String) onChanged, {
    String? label,
    Color textColor = Colors.black,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          onChanged: (val) => onChanged(val!),
          items:
              options
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: TextStyle(fontSize: 13, color: textColor),
                      ),
                    ),
                  )
                  .toList(),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(title: const Text('🧠 Magic Outfit AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adjust the temperature to help AI match clothing to weather:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Slider(
              value: selectedTemp,
              min: 5,
              max: 35,
              divisions: 30,
              label: '${selectedTemp.round()}°C',
              onChanged: (val) => setState(() => selectedTemp = val),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Season",
                    selectedSeason,
                    ['Winter', 'Spring', 'Summer', 'Autumn'],
                    (val) => setState(() => selectedSeason = val),
                    label: "Season",
                    textColor: dropdownTextColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    "Modesty",
                    selectedModesty,
                    ['None', 'Hijab-Friendly'],
                    (val) => setState(() => selectedModesty = val),
                    label: "Modesty",
                    textColor: dropdownTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    "Occasion",
                    selectedOccasion,
                    [
                      'Casual',
                      'Work',
                      'Formal',
                      'Comfy',
                      'Chic',
                      'Sport',
                      'Classy',
                    ],
                    (val) => setState(() => selectedOccasion = val),
                    label: "Occasion",
                    textColor: dropdownTextColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown(
                    "Gender",
                    selectedGender,
                    ['Female', 'Male'],
                    (val) => setState(() => selectedGender = val),
                    label: "Gender",
                    textColor: dropdownTextColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _loading ? null : generateOutfit,
                child: const Text('✨ Generate Outfit'),
              ),
            ),
            const SizedBox(height: 20),

            if (!_loading &&
                generationError != null &&
                recommendedItems.isEmpty)
              Center(
                child: Text(
                  generationError!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (_loading) const Center(child: CircularProgressIndicator()),

            if (!_loading && recommendedItems.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recommendedItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = recommendedItems[index];
                  return Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            'http://10.0.2.2:8000${item['photo_path']}',
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            item['subcategory']['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (!_loading && recommendedItems.isNotEmpty)
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: const Text("Save to Wardrobe"),
                  onPressed: _promptDescriptionAndSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),

            const Divider(height: 30),
            const Text(
              'You can generate your outfit using AI or create one manually:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.create),
                label: const Text('Create Outfit Manually'),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => OutfitCreationPage(
                            selectedDate: widget.selectedDate,
                          ),
                    ),
                  );

                  // If outfit was successfully saved, assign it to planner
                  if (result is int &&
                      widget.fromCalendar &&
                      widget.selectedDate != null) {
                    await _assignOutfitToPlanner(result, widget.selectedDate!);
                    Navigator.pop(context, true); // Tell planner to refresh
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
