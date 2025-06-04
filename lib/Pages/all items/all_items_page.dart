// ignore_for_file: deprecated_member_use, file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/all%20items/CategoryDetailsPage.dart';
import 'package:flutter_application_1/Pages/all%20items/ItemDetails.dart';

class WardrobeItem {
  final int id;
  final String? color;
  final String? size;
  final String? material;
  final String? season;
  final String? tags;
  final String? photoPath;
  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;
  final int? userId;

  WardrobeItem({
    required this.id,
    this.color,
    this.size,
    this.material,
    this.season,
    this.tags,
    this.photoPath,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.userId,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    return WardrobeItem(
      id: json['id'] ?? 0,
      color: json['color'],
      size: json['size'],
      material: json['material'],
      season: json['season'],
      tags: json['tags'],
      photoPath: json['photo_path'] != null ? 'http://10.0.2.2:8000${json['photo_path']}' : null,
      categoryId: json['category']?['id'],
      categoryName: json['category']?['name'],
      subcategoryId: json['subcategory']?['id'],
      subcategoryName: json['subcategory']?['name'],
      userId: json['user'],
    );
  }
}

class AllItemsPage extends StatefulWidget {
  final int? userId;
  const AllItemsPage({super.key, this.userId});

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  Map<String, List<WardrobeItem>> groupedItems = {};
  bool isLoading = true;
  String error = '';
  String selectedTag = '';
String sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    fetchGroupedItems();
  }

  Future<void> fetchGroupedItems() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        error = 'Authentication token not found. Please log in again.';
      });
      return;
    }

    final url = widget.userId != null
        ? Uri.parse('http://10.0.2.2:8000/api/wardrobe/?user_id=${widget.userId}')
        : Uri.parse('http://10.0.2.2:8000/api/wardrobe/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filteredItems = data.map((json) => WardrobeItem.fromJson(json)).where((item) {
  return selectedTag.isEmpty || (item.tags?.toLowerCase().contains(selectedTag.toLowerCase()) ?? false);
}).toList()
..sort((a, b) =>
    sortBy == 'Newest' ? b.id.compareTo(a.id) : a.id.compareTo(b.id));

        final Map<String, List<WardrobeItem>> tempGrouped = {};
        for (var item in filteredItems) {
          if (item.categoryName != null) {
            tempGrouped.putIfAbsent(item.categoryName!, () => []);
            tempGrouped[item.categoryName!]!.add(item);
          }
        }

        setState(() {
          groupedItems = tempGrouped;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to fetch items (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'An error occurred: $e';
      });
    }
  }
String _capitalize(String? value) {
  if (value == null || value.isEmpty) return '';
  return value[0].toUpperCase() + value.substring(1);
}
final tags = ['All', 'Casual', 'Work', 'Formal', 'Comfy', 'Chic', 'Sport', 'Classy'];
final sortOptions = ['Newest', 'Oldest'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Items"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:Row(
  children: [
    for (final tag in tags)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            () {
              final tagKey = tag == 'All' ? '' : tag;
              final count = groupedItems.values
                  .expand((e) => e)
                  .where((item) => tagKey.isEmpty || (item.tags?.toLowerCase().contains(tagKey.toLowerCase()) ?? false))
                  .length;
              return '$tag ($count)';
            }(),
            style: TextStyle(
              color: selectedTag == (tag == 'All' ? '' : tag)
                  ? Colors.white
                  : const Color(0xFF2F1B0C),
            ),
          ),
          selected: selectedTag == (tag == 'All' ? '' : tag),
          selectedColor: const Color(0xFFFF9800),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFFE0B2)),
          ),
          onSelected: (_) {
            final newTag = tag == 'All' ? '' : tag;
            setState(() {
              selectedTag = selectedTag == newTag ? '' : newTag;
            });
            fetchGroupedItems();
          },
        ),
      ),
    for (final sort in sortOptions)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            sort,
            style: TextStyle(
              color: sortBy == sort
                  ? Colors.white
                  : const Color(0xFF2F1B0C),
            ),
          ),
          selected: sortBy == sort,
          selectedColor: const Color(0xFFFF9800),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFFE0B2)),
          ),
          onSelected: (_) {
            setState(() => sortBy = sort);
            fetchGroupedItems();
          },
        ),
      ),
  ],
),


            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                    ? Center(child: Text(error))
                    : groupedItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No items in your wardrobe yet.',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchGroupedItems,
                            child: ListView(
                              padding: const EdgeInsets.all(16.0),
                              children: groupedItems.entries.map((entry) {
                                final category = entry.key;
                                final items = entry.value;
                                final previewItems = items.length > 4 ? items.take(4).toList() : items;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CategoryDetailsPage(
                                              categoryId: items.first.categoryId!,
                                              categoryName: category,
                                              userId: widget.userId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              category,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2F1B0C),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              items.length.toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 140,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: previewItems.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index < previewItems.length) {
                                            final item = previewItems[index];
                                            return GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ItemDetails(
                                                    itemId: item.id,
                                                    itemName: item.material ?? 'Unnamed',
                                                    color: item.color ?? 'N/A',
                                                    size: item.size ?? 'N/A',
                                                    material: item.material ?? 'N/A',
                                                    season: item.season ?? 'N/A',
                                                    tags: item.tags?.split(',') ?? [],
                                                    imageUrl: item.photoPath,
                                                    category: item.categoryName ?? 'N/A',
                                                    subcategory: item.subcategoryName ?? 'General',
                                                    userId: item.userId,
                                                  ),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                child: Container(
                                                  width: 100,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.orange.shade100),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Expanded(
                                                        child: item.photoPath != null
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(12),
                                                                child: Image.network(
                                                                  item.photoPath!,
                                                                  fit: BoxFit.contain,
                                                                  width: 100,
                                                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                                                ),
                                                              )
                                                            : const Center(child: Icon(Icons.image_not_supported)),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
  '${_capitalize(item.color)} ${_capitalize(item.subcategoryName)}'.trim(),
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  textAlign: TextAlign.center,
  style: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF4B3C2F), // A stylish dark brown for your theme
  ),
)

                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return GestureDetector(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CategoryDetailsPage(
                                                    categoryId: items.first.categoryId!,
                                                    categoryName: category,
                                                    userId: widget.userId,
                                                  ),
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                child: Container(
                                                  width: 100,
                                                  height: 130,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.arrow_forward,
                                                      size: 30,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
