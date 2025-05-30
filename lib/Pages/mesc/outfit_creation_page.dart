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

  final List<String> seasonOptions = [
    'Winter',
    'Spring',
    'Summer',
    'Autumn',
    'All-Season',
  ];
  final List<String> tagSuggestions = [
    'Casual',
    'Work',
    'Sport',
    'Comfy',
    'Classic',
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
    request.fields['tags'] = _tagsController.text.trim();
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
              content: Text(
                'Outfit with ${selectedItems.length} item(s) saved.',
              ),
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
        title: const Text(
          'Create Outfit',
          style: TextStyle(
            color: ui.Color.fromARGB(255, 255, 255, 255),
          ), // Changed to black
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Description"),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      style: const TextStyle(
                        color: Colors.black,
                      ), // Changed to black
                      decoration: InputDecoration(
                        labelText: 'Enter outfit description',
                        labelStyle: const TextStyle(
                          color: Colors.black,
                        ), // Changed to black
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLabel("Season"),
                    DropdownButtonFormField<String>(
                      value: selectedSeason,
                      items:
                          seasonOptions.map((season) {
                            return DropdownMenuItem<String>(
                              value: season,
                              child: Text(
                                season,
                                style: const TextStyle(
                                  color: Colors.black,
                                ), // Changed to black
                              ),
                            );
                          }).toList(),
                      onChanged:
                          (value) => setState(() => selectedSeason = value!),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLabel("Tags"),
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Type or tap a suggestion',
                        labelStyle: const TextStyle(
                          color: Colors.black,
                        ), // Changed to black
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children:
                          tagSuggestions
                              .map(
                                (s) => ActionChip(
                                  label: Text(
                                    s,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ), // Changed to black
                                  ),
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  onPressed: () {
                                    final currentText =
                                        _tagsController.text.trim();
                                    final tags =
                                        currentText.isEmpty
                                            ? <String>{}
                                            : currentText
                                                .split(',')
                                                .map((e) => e.trim())
                                                .where((e) => e.isNotEmpty)
                                                .toSet();
                                    tags.add(s);
                                    setState(
                                      () =>
                                          _tagsController.text = tags.join(
                                            ', ',
                                          ),
                                    );
                                  },
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Checkbox(
                            value: isHijabFriendly,
                            onChanged:
                                (val) => setState(() => isHijabFriendly = val!),
                            activeColor: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Is Hijab Friendly',
                          style: TextStyle(
                            color: Colors.black,
                          ), // Changed to black
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...wardrobeByCategory.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Changed to black
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              itemBuilder: (context, index) {
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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? colorScheme.primary
                                                : colorScheme.outline,
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
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
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveOutfit,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Save Outfit',
                          style: TextStyle(
                            color: ui.Color.fromARGB(255, 193, 193, 193),
                          ), // Changed to black
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black, // Changed to black
      ),
    ),
  );
}
