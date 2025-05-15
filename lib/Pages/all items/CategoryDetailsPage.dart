import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'category.dart';
import 'wardrobe_service.dart';
import 'all_items_page.dart' as all_items;
import 'ItemDetails.dart' as details;

class SubCategoryGroup {
  final int id;
  final String name;
  final List<all_items.WardrobeItem> items;
  final int? userId;

  SubCategoryGroup({required this.id, required this.name,  this.userId,}) : items = [];
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
      final response = await http.get(url, headers: {
        'Authorization': 'Token $token',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final items = data
            .map((json) => all_items.WardrobeItem.fromJson(json))
            .where((item) => item.categoryId == widget.categoryId)
            .toList();

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

  Widget _buildSubCategorySection(SubCategoryGroup group) {
    final previewItems = group.items.take(4).toList();
    final hasMore = group.items.length > 4;

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
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      group.name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
),



        SizedBox(
          height: 130,
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
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.photoPath != null
                          ? Image.network(
                              item.photoPath!,
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 100,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
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
                        userId: widget.userId, // 👈 pass it down
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      width: 100,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward, size: 30, color: Colors.black54),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : subcategoryGroups.isEmpty
                  ? const Center(child: Text('No subcategories or items found'))
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: subcategoryGroups.values
                          .map((group) => _buildSubCategorySection(group))
                          .toList(),
                    ),
    );
  }
}
