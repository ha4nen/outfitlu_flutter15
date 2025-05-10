import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';
import 'package:flutter_application_1/Pages/all%20items/CategoryDetailsPage.dart';
import 'package:flutter_application_1/Pages/Outfits/outfit.dart';
import 'package:flutter_application_1/Pages/all items/ItemDetails.dart';

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
    );
  }
}
class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
    );
  }
}

class AllItemsPage extends StatefulWidget {
  const AllItemsPage({super.key});

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  Map<String, List<WardrobeItem>> groupedItems = {};
  bool isLoading = true;
  String error = '';

  
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
    final url = Uri.parse('http://10.0.2.2:8000/api/wardrobe/');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Token $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final items = data.map((json) => WardrobeItem.fromJson(json)).toList();

        final Map<String, List<WardrobeItem>> tempGrouped = {};
        for (var item in items) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Items'),
      ),
      body: isLoading
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
                    final previewItems = items.take(4).toList();

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
        ),
      ),
    );
  },
  child: Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      category,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.secondary,
      ),
    ),
  ),
),

                        SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
itemCount: items.length > 4 ? 5 : previewItems.length,
itemBuilder: (context, index) {
  if (index < 4 && index < items.length) {
    final item = items[index];
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
),

        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            width: 100,
            color: Theme.of(context).colorScheme.surface,
            child: item.photoPath != null
                ? Image.network(
                    item.photoPath!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 130,
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                  )
                : const Center(child: Icon(Icons.image_not_supported)),
          ),
        ),
      ),
    );
  } else {
    // Arrow tile
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailsPage(
            categoryId: items.first.categoryId!,
            categoryName: category,
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
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Center(
            child: Icon(Icons.arrow_forward, size: 30, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}


                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
    ),
                ),
    );
  }
}
