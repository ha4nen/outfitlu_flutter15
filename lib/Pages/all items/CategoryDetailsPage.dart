// ignore_for_file: deprecated_member_use, file_names

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_items_page.dart' as all_items;
import 'ItemDetails.dart' as details;

class SubCategoryGroup {
  final int id;
  final String name;
  final List<all_items.WardrobeItem> items;
  final int? userId;

  SubCategoryGroup({required this.id, required this.name, this.userId})
      : items = [];
}

class CategoryDetailsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final int? userId;

  const CategoryDetailsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.userId,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  Map<int, SubCategoryGroup> subcategoryGroups = {};
  bool isLoading = true;
  String error = '';
  String selectedTag = '';
String sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _fetchItemsByCategory();
  }

  Future<void> _fetchItemsByCategory() async {
    setState(() {
      isLoading = true;
      error = '';
      subcategoryGroups = {};
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        error = 'No auth token found.';
      });
      return;
    }

    final url = widget.userId != null
        ? Uri.parse('http://10.0.2.2:8000/api/users/${widget.userId}/wardrobe/')
        : Uri.parse('http://10.0.2.2:8000/api/wardrobe/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final items = data
    .map((json) => all_items.WardrobeItem.fromJson(json))
    .where((item) => item.categoryId == widget.categoryId)
    .where((item) => selectedTag.isEmpty || (item.tags?.toLowerCase().contains(selectedTag.toLowerCase()) ?? false))
    .toList()
    ..sort((a, b) => sortBy == 'Newest' ? b.id.compareTo(a.id) : a.id.compareTo(b.id));


        final Map<int, SubCategoryGroup> grouped = {};
        for (var item in items) {
          if (item.subcategoryId != null && item.subcategoryName != null) {
            grouped.putIfAbsent(
              item.subcategoryId!,
              () => SubCategoryGroup(
                id: item.subcategoryId!,
                name: item.subcategoryName!,
              ),
            );
            grouped[item.subcategoryId!]!.items.add(item);
          }
        }

        setState(() {
          subcategoryGroups = grouped;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to load items: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error: $e';
      });
    }
  }
final tagOptions = ['All', 'Casual', 'Work', 'Formal', 'Comfy', 'Chic', 'Sport', 'Classy'];
final sortOptions = ['Newest', 'Oldest'];

  Widget _buildSubCategorySection(SubCategoryGroup group) {
    final previewItems = group.items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubDetails(
                subcategoryId: group.id,
                subcategoryName: group.name,
                subCategory: '',
                userId: widget.userId,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F1B0C),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  group.items.length.toString(),
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
                      builder: (_) => details.ItemDetails(
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
                              color: Color(0xFF4B3C2F),
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
                      builder: (_) => SubDetails(
                        subcategoryId: group.id,
                        subcategoryName: group.name,
                        subCategory: '',
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
  }

  String _capitalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
  children: [
    for (final tag in tagOptions)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            () {
              final tagKey = tag == 'All' ? '' : tag;
              final count = subcategoryGroups.values
                  .expand((group) => group.items)
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
            _fetchItemsByCategory();
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
              color: sortBy == sort ? Colors.white : const Color(0xFF2F1B0C),
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
            _fetchItemsByCategory();
          },
        ),
      ),
  ],
),

                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchItemsByCategory,
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: subcategoryGroups.values
                              .map((group) => _buildSubCategorySection(group))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
