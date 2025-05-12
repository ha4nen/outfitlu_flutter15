import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_items_page.dart' as all_items;
import 'ItemDetails.dart';

class SubCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const SubCategoryPage({super.key, required this.categoryId, required this.categoryName});

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  bool isLoading = true;
  String error = '';
  List<all_items.WardrobeItem> items = [];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      isLoading = true;
      error = '';
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

    final url = Uri.parse('http://10.0.2.2:8000/api/wardrobe/');

    try {
      final response = await http.get(url, headers: {'Authorization': 'Token $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered = data
            .map((json) => all_items.WardrobeItem.fromJson(json))
            .where((item) => item.categoryId == widget.categoryId)
            .toList();

        setState(() {
          items = filtered;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.categoryName} Subcategories')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.photoPath != null
                            ? Image.network(
                                item.photoPath!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
