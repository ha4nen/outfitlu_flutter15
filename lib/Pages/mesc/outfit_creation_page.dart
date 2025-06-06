// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use, unnecessary_to_list_in_spreads, unused_import, unnecessary_import

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

File? _combinedImageForPost;

class OutfitCreationPage extends StatefulWidget {
  final DateTime? selectedDate;

  const OutfitCreationPage({super.key, this.selectedDate});
  @override
  State<OutfitCreationPage> createState() => _OutfitCreationPageState();
}

class _OutfitCreationPageState extends State<OutfitCreationPage> {
  final Map<String, List<Map<String, dynamic>>> wardrobeByCategory = {};
  final List<Map<String, dynamic>> selectedItems = [];
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String selectedSeason = 'All-Season';
  bool isHijabFriendly = false;
  bool isLoading = true;
  String? selectedTag;
  final List<String> selectedOccasions = [];

  final List<String> seasonOptions = [
    'Winter',
    'Spring',
    'Summer',
    'Autumn',
    'All-Season',
  ];
  final List<String> occasionOptions = [
    'Casual',
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
    _fetchWardrobeItems();
  }

  Future<void> _fetchWardrobeItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print('🔒 No auth token found. User is not logged in.');
      if (!mounted) return;
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/wardrobe/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List items = jsonDecode(response.body);
        final Map<String, List<Map<String, dynamic>>> grouped = {};

        for (var item in items) {
          final category = item['category']['name'];
          grouped.putIfAbsent(category, () => []).add(item);
        }

        setState(() {
          wardrobeByCategory.clear();
          wardrobeByCategory.addAll(grouped);
          isLoading = false;
        });
      } else {
        print('❌ Failed to load wardrobe: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('⚠️ Error fetching wardrobe: $e');
      setState(() => isLoading = false);
    }
  }

  void _toggleSelection(Map<String, dynamic> item) {
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
    });
  }

  Future<File?> _combineImages() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 300.0;
      const padding = 10.0;

      final int count = selectedItems.length;
      final cols = 2;
      final rows = (count / cols).ceil();
      final imageSize = (size - padding * (cols + 1)) / cols;

      for (int i = 0; i < count; i++) {
        final item = selectedItems[i];
        final imageUrl =
            item['photo_path'].toString().startsWith("http")
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
      final file = File('${dir.path}/combined_outfit.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      return file;
    } catch (e) {
      print('⚠️ Error combining images: $e');
      return null;
    }
  }

  Future<void> _saveOutfit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (selectedItems.isEmpty || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select items and ensure login.')),
      );
      return;
    }

    final combinedImage = await _combineImages();
    if (combinedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to combine images.')),
      );
      return;
    }
    _combinedImageForPost = combinedImage; // ← Save for reuse

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8000/api/outfits/create/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.fields['type'] = 'User-created';
    request.fields['description'] = _descriptionController.text.trim();
    request.fields['season'] = selectedSeason;
    // Combine tags from the text field and selected occasions
    final tagsList = [
      ...selectedOccasions,
      ..._tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty),
    ];
    request.fields['tags'] = tagsList.join(
      ',',
    ); // or use space if your backend expects space-separated
    request.fields['is_hijab_friendly'] = isHijabFriendly.toString();

    for (var i = 0; i < selectedItems.length; i++) {
      request.fields['selected_items_ids[$i]'] =
          selectedItems[i]['id'].toString();
    }

    request.files.add(
      await http.MultipartFile.fromPath('photo_path', combinedImage.path),
    );

    final response = await request.send();
    if (response.statusCode == 201) {
      final responseBody = await response.stream.bytesToString();
      final outfitData = jsonDecode(responseBody);
      final outfitId = outfitData['id'];

      if (widget.selectedDate != null) {
        await http.post(
          Uri.parse('http://10.0.2.2:8000/api/planner/plan/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'outfit_id': outfitId,
            'date': widget.selectedDate!.toIso8601String().split('T').first,
          }),
        );
      }

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Outfit Saved!'),
              content: Text('Outfit with ${selectedItems.length} items saved.'),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // close first dialog
                    final shouldPost = await _askToPostOutfit();
                    if (shouldPost == true) {
                      await _promptCaptionAndPost(outfitId);
                    } else {
                      Navigator.pop(
                        context,
                        outfitId,
                      ); // ✅ return the outfit ID so planner can use it
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } else {
      final respStr = await response.stream.bytesToString();
      print('Error Response Body:\n$respStr');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $respStr')));
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
                hintText: "Enter caption for your post",
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
      final combinedImage = _combinedImageForPost;

      if (token == null || combinedImage == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Missing auth or image.")));
        return;
      }

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
          const SnackBar(content: Text("Post created successfully!")),
        );
      } else {
        final respStr = await response.stream.bytesToString();
        print("❌ Failed to post outfit: $respStr");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post outfit: $respStr")),
        );
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Outfit"),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFFFF9800),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Description", theme, colorScheme),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter outfit description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF9800),
                          ),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF9800)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF9800)),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildLabel("Season", theme, colorScheme),
                    DropdownButtonFormField<String>(
                      value: selectedSeason,
                      items:
                          seasonOptions
                              .map(
                                (season) => DropdownMenuItem<String>(
                                  value: season,
                                  child: Text(
                                    season,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => selectedSeason = value!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF9800)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF9800)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF9800)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    _buildLabel("Occasion", theme, colorScheme),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children:
                          occasionOptions.map((occasion) {
                            final isSelected = selectedOccasions.contains(
                              occasion,
                            );
                            return FilterChip(
                              label: Text(occasion),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedOccasions.add(occasion);
                                  } else {
                                    selectedOccasions.remove(occasion);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFFFF9800),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color(0xFFFF9800),
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              labelStyle: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : colorScheme.onSurface,
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: isHijabFriendly,
                          onChanged:
                              (val) => setState(() => isHijabFriendly = val!),
                          activeColor: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Is Hijab Friendly',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ...wardrobeByCategory.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, index) {
                                final item = items[index];
                                final isSelected = selectedItems.contains(item);
                                final imageUrl =
                                    item['photo_path'].toString().startsWith(
                                          "http",
                                        )
                                        ? item['photo_path']
                                        : 'http://10.0.2.2:8000${item['photo_path']}';

                                return GestureDetector(
                                  onTap: () => _toggleSelection(item),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFFFF9800)
                                                : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveOutfit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9800),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Save Outfit'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildLabel(String label, ThemeData theme, ColorScheme colorScheme) =>
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      );
}
