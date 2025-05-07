import 'dart:convert';
import 'dart:io'; // Keep if ItemDetails still needs it
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'itemDetails.dart'; // Import the ItemDetails page

// Re-use the WardrobeItem model (ensure consistent)
class WardrobeItem {
  final int id; // Keep ID non-nullable
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

  // *** UPDATED fromJson factory ***
  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    final itemId = json['id'];
    if (itemId == null || itemId is! int) {
      throw FormatException('Invalid or missing item ID found in JSON: ${json['id']}');
    }

    String? catName = json['category']?['name'];
    String? subcatName = json['subcategory']?['name'];
    int? catId = json['category']?['id'];
    int? subcatId = json['subcategory']?['id'];

    return WardrobeItem(
      id: itemId,
      color: json['color'],
      size: json['size'],
      material: json['material'],
      season: json['season'],
      tags: json['tags'],
      photoPath: json['photo_path'] != null ? 'http://10.0.2.2:8000${json['photo_path']}' : null,
      categoryId: catId,
      categoryName: catName,
      subcategoryId: subcatId,
      subcategoryName: subcatName,
    );
  }
}

class SubDetails extends StatefulWidget {
  final String subcategoryName;
  final int subcategoryId; 

  const SubDetails({super.key, required this.subcategoryName, required this.subcategoryId, required String subCategory});

  @override
  State<SubDetails> createState() => _SubDetailsState();
}

class _SubDetailsState extends State<SubDetails> {
  List<WardrobeItem> _items = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchItemsBySubcategory();
  }

  Future<void> _fetchItemsBySubcategory() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Authentication token not found. Please log in.';
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/wardrobe/subcategory/${widget.subcategoryId}/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // *** UPDATED item parsing with try-catch and filtering ***
        final List<WardrobeItem> fetchedItems = data.map((itemJson) {
          try {
            return WardrobeItem.fromJson(itemJson);
          } catch (e) {
            print('Failed to parse item on SubDetails: $itemJson, Error: $e');
            return null; // Return null for items that fail parsing
          }
        })
        .where((item) => item != null) // Filter out the nulls
        .cast<WardrobeItem>()
        .toList();

        setState(() {
          _items = fetchedItems;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load items (Status code: ${response.statusCode})';
        });
        print('Error response body: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An error occurred: $e';
      });
      print('Network or parsing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.subcategoryName,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No items found in this subcategory.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.8, 
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return GestureDetector(
          onTap: () {
            // Navigate to ItemDetails - REMINDER: User must update ItemDetails
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetails(
                  itemName: item.material ?? 'Item ${item.id}',
                  color: item.color ?? 'N/A',
                  size: item.size ?? 'N/A',
                  season: item.season ?? 'N/A',
                  tags: item.tags?.split(',') ?? [],
                  imageUrl: item.photoPath, item: File(''), // Provide a dummy File object
                  // item: File(''), // REMOVE dummy File object if ItemDetails is updated
                ),
              ),
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: item.photoPath != null
                      ? Image.network(
                          item.photoPath!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                        ), 
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    item.material ?? item.color ?? 'Item ${item.id}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

