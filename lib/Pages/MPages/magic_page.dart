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
  String selectedSeason = 'None';
  String selectedModesty = 'None';
  String selectedOccasion = 'None';
  String selectedGender = 'None';

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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          onChanged: (val) => onChanged(val!),
          items: options
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            labelText: value.isEmpty ? hint : "",
            labelStyle: const TextStyle(color: Colors.black87),
            filled: true,
            fillColor: Colors.grey.shade100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.orange.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.orange.shade200),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
            ),
          ),
          dropdownColor: Colors.white,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dropdownTextColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ORANGE TOP SECTION ---
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28), // slightly more rounded
                ),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 32, // You can reduce this to 16 if you want even less top space
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Set the weather and preferences below to let Outfitly AI craft your perfect look.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                    ),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.2),
                        trackShape: const RoundedRectSliderTrackShape(),
                        thumbShape: _SmallOutlineThumbShape(),
                        overlayColor: const Color(0x33FFFFFF),
                        thumbColor: Colors.transparent,
                        disabledThumbColor: Colors.transparent,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTickMarkColor: Colors.transparent,
                        inactiveTickMarkColor: Colors.transparent,
                        valueIndicatorColor: Colors.white,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.black, // <-- Degree text is now black
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Slider(
                        value: selectedTemp,
                        min: 5,
                        max: 35,
                        divisions: 30,
                        label: '${selectedTemp.round()}°C',
                        onChanged: (val) => setState(() => selectedTemp = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ExpandableStyleSelector(
                            label: "Season",
                            selectedOption: selectedSeason,
                            options: ['Winter', 'Spring', 'Summer', 'Autumn'],
                            onChanged: (val) => setState(() => selectedSeason = val),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ExpandableStyleSelector(
                            label: "Modesty",
                            selectedOption: selectedModesty,
                            options: ['None', 'Hijab-Friendly'],
                            onChanged: (val) => setState(() => selectedModesty = val),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ExpandableStyleSelector(
                            label: "Occasion",
                            selectedOption: selectedOccasion,
                            options: [
                              'Casual',
                              'Work',
                              'Formal',
                              'Comfy',
                              'Chic',
                              'Sport',
                              'Classy',
                            ],
                            onChanged: (val) => setState(() => selectedOccasion = val),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ExpandableStyleSelector(
                            label: "Gender",
                            selectedOption: selectedGender,
                            options: ['Female', 'Male'],
                            onChanged: (val) => setState(() => selectedGender = val),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: ElevatedButton(
                      onPressed: _loading ? null : generateOutfit,
                      child: const Text('Generate Outfit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF9800),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // --- END ORANGE TOP SECTION ---

            const Divider(height: 36, color: Color(0xFFFF9800)), // <-- Degree color changed to orange

            // BOTTOM OF PAGE
            Center(
              child: const Text(
                'Prefer a personal touch? You can also design your own outfit manually below.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
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
                      builder: (_) => OutfitCreationPage(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallOutlineThumbShape extends SliderComponentShape {
  static const double _thumbRadius = 6.0;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Paint fillPaint = Paint()
      ..color = sliderTheme.activeTrackColor!
      ..style = PaintingStyle.fill;

    final Paint outlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    context.canvas.drawCircle(center, _thumbRadius, fillPaint);
    context.canvas.drawCircle(center, _thumbRadius + 2, outlinePaint);
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(16, 16);
  }
}

// Add this widget above _MagicPageState (or in a separate file if you prefer):

class ExpandableStyleSelector extends StatelessWidget {
  final String label;
  final String selectedOption;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const ExpandableStyleSelector({
    super.key,
    required this.label,
    required this.selectedOption,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Always show "None" as the default if nothing is selected
    final displayOption = (selectedOption.isEmpty || selectedOption == "None")
        ? "None"
        : selectedOption;
    return _ExpandableMenu(
      label: label,
      selectedOption: displayOption,
      options: options.contains("None") ? options : ["None", ...options],
      onChanged: onChanged,
    );
  }
}

class _ExpandableMenu extends StatefulWidget {
  final String label;
  final String selectedOption;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _ExpandableMenu({
    required this.label,
    required this.selectedOption,
    required this.options,
    required this.onChanged,
  });

  @override
  State<_ExpandableMenu> createState() => _ExpandableMenuState();
}

class _ExpandableMenuState extends State<_ExpandableMenu> with TickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
    setState(() => isExpanded = true);
    _controller.forward(from: 0);
  }

  void _hideOverlay() {
    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) setState(() => isExpanded = false);
    });
  }

  OverlayEntry _buildOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hideOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 8),
                child: Material(
                  color: Colors.transparent,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      alignment: Alignment.topCenter,
                      scale: _scale,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 344, // 4*80 + 3*8
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.start, // <-- force left alignment
                              crossAxisAlignment: WrapCrossAlignment.start,
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.options
                                  .where((opt) => opt != widget.selectedOption)
                                  .map((opt) => SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _userHasSelected = true;
                                            });
                                            widget.onChanged(opt);
                                            _hideOverlay();
                                          },
                                          child: _buildOptionBox(opt),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white, // <-- Make label text white
                ),
              ),
            ),
          ),
          // White cutout behind the selector (like a "hole" in the orange background)
          Container(
            decoration: BoxDecoration(
              // REMOVE: color: Colors.white, // pure white for the cutout
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.all(4),
            child: GestureDetector(
              onTap: () {
                if (!isExpanded) {
                  _showOverlay();
                } else {
                  _hideOverlay();
                }
              },
              child: _buildOptionBox(widget.selectedOption, isMain: true, showArrow: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionBox(String label, {bool isMain = false, bool showArrow = false}) {
    final Color orange = const Color(0xFFFF9800);
    final Color white = Colors.white; // Use white instead of grey

    bool userHasSelected = _userHasSelected ?? false;
    final bool isSelected = widget.selectedOption == label;
    final bool isNone = label == "None";

    if (isMain) {
      // Determine initial value based on selection
      final double initialValue = isNone ? 0.0 : 1.0;
      final double targetValue = (userHasSelected && isSelected)
          ? (isNone ? 0.0 : 1.0)
          : (isNone ? 0.0 : 1.0);

      return AspectRatio(
        aspectRatio: 1,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: initialValue,
            end: targetValue,
          ),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          builder: (context, value, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                return Stack(
                  children: [
                    // White background always
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white, width: 2), // <-- Thin white border
                      ),
                    ),
                    // Orange fill animates in/out
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: height * value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 2), // <-- Thin white border
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: value > 0.5 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      );
    }

    // Dropdown option: "None" is white, others are orange
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isNone ? white : orange,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15, // slightly smaller font
              color: isNone ? Colors.black87 : Colors.white,
            ),
            maxLines: 2, // allow wrapping for long words
          ),
        ),
      ),
    );
  }

  // Add this field to your _ExpandableMenuState class:
  bool? _userHasSelected;
}