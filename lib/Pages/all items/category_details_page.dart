import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart'; // For navigating to item list of a single subcategory

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

  // Updated factory to handle potential invalid data from API
  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    // *** FIX START: Explicitly check if 'id' is a valid integer ***
    final itemId = json['id'];
    if (itemId == null || itemId is! int) {
      // Throw an error if ID is missing or not an integer. 
      // This will be caught in the list mapping logic.
      throw FormatException('Invalid or missing item ID found in JSON: ${json['id']}');
    }
    // *** FIX END ***

    // If ID is valid, proceed with parsing
    String? catName = json['category']?['name'];
    String? subcatName = json['subcategory']?['name'];
    int? catId = json['category']?['id'];
    int? subcatId = json['subcategory']?['id'];

    return WardrobeItem(
      id: itemId, // Use the validated itemId
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

// Structure to hold grouped subcategories and their items
class SubCategoryGroupForDetails {
  final int id;
  final String name;
  final List<WardrobeItem> items = [];

  SubCategoryGroupForDetails({required this.id, required this.name});
}

class CategoryDetailsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsPageState();
}

class _CategoryDetailsPageState extends State<CategoryDetailsPage> {
  Map<int, SubCategoryGroupForDetails> _groupedItemsBySubCategory = {}; // Map<subcategoryId, SubCategoryGroup>
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchItemsForCategoryAndGroup();
  }

  Future<void> _fetchItemsForCategoryAndGroup() async {
    setState(() {
      _isLoading = true;
      _error = '';
      _groupedItemsBySubCategory = {}; // Clear previous data
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

    final url = Uri.parse('http://10.0.2.2:8000/api/wardrobe/category/${widget.categoryId}/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // *** DEBUG LOGGING START ***
        print("--- Raw API Data for Category ${widget.categoryId} ---");
        print(response.body);
        print("--- Processing Items ---");
        // *** DEBUG LOGGING END ***

        final List<WardrobeItem> categoryItems = data.map((itemJson) {
          // *** DEBUG LOGGING START ***
          print("Processing item JSON: $itemJson"); 
          // *** DEBUG LOGGING END ***
          try {
            // *** DEBUG LOGGING START ***
            // Log potential nulls before parsing
            if (itemJson is Map<String, dynamic>) {
              print("  >> ID: ${itemJson['id']} (Type: ${itemJson['id']?.runtimeType})");
              print("  >> Category ID: ${itemJson['category']?['id']} (Type: ${itemJson['category']?['id']?.runtimeType})");
              print("  >> SubCategory ID: ${itemJson['subcategory']?['id']} (Type: ${itemJson['subcategory']?['id']?.runtimeType})");
            } else {
              print("  >> Item JSON is not a Map: $itemJson");
            }
            // *** DEBUG LOGGING END ***
            
            return WardrobeItem.fromJson(itemJson);
          } catch (e) {
            print('Failed to parse item: $itemJson, Error: $e');
            return null; // Return null for items that fail parsing
          }
        })
        .where((item) => item != null) // Filter out the nulls (failed items)
        .cast<WardrobeItem>() // Cast the list back to the correct type
        .toList();
        
        // *** DEBUG LOGGING START ***
        print("--- Successfully Parsed Items: ${categoryItems.length} ---");
        // *** DEBUG LOGGING END ***

        // Group the successfully parsed items by SubCategory
        final Map<int, SubCategoryGroupForDetails> grouped = {};
        for (var item in categoryItems) {
          // *** DEBUG LOGGING START ***
          print("Grouping item ID: ${item.id}, Subcategory ID: ${item.subcategoryId}, Subcategory Name: ${item.subcategoryName}");
          // *** DEBUG LOGGING END ***
          if (item.subcategoryId != null && item.subcategoryName != null) {
            // Ensure SubCategoryGroup exists
            grouped.putIfAbsent(
              item.subcategoryId!, 
              () => SubCategoryGroupForDetails(id: item.subcategoryId!, name: item.subcategoryName!)
            );
            // Add item to the SubCategoryGroup
            grouped[item.subcategoryId!]!.items.add(item);
          } else {
            // Optional: Handle items with category but no subcategory
             print("Item ID ${item.id} has null subcategory ID or name. Skipping grouping.");
          }
        }

        setState(() {
          _groupedItemsBySubCategory = grouped;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load items for this category (Status code: ${response.statusCode})';
        });
        print('Error response body: ${response.body}');
      } 
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An error occurred during fetch/processing: $e'; // More specific error
      });
      print('Network or parsing error: $e');
    }
  }

  Widget _buildSubCategorySection(SubCategoryGroupForDetails subCategoryGroup) {
    // ... (rest of widget remains the same) ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubDetails(
                  subcategoryName: subCategoryGroup.name,
                  subcategoryId: subCategoryGroup.id, subCategory: '',
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  subCategoryGroup.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color?.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        subCategoryGroup.items.isEmpty
            ? Container(
                height: 120,
                alignment: Alignment.center,
                child: Text(
                  'No items in this subcategory.',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              )
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subCategoryGroup.items.length,
                  itemBuilder: (context, index) {
                    final item = subCategoryGroup.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          print('Navigate to details for item ID: ${item.id}');
                        },
                        child: ClipRRect(
                           borderRadius: BorderRadius.circular(8.0),
                           child: item.photoPath != null
                            ? Image.network(
                                item.photoPath!,
                                width: 100,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) => 
                                  progress == null ? child : Center(child: CircularProgressIndicator()),
                                errorBuilder: (context, error, stack) => 
                                  Container(width: 100, height: 120, color: Colors.grey[200], child: Icon(Icons.error)),
                              )
                            : Container(
                                width: 100,
                                height: 120,
                                color: Colors.grey[300],
                                child: Icon(Icons.image_not_supported, color: Colors.white),
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (build method remains the same) ...
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).iconTheme.color),
            onPressed: _fetchItemsForCategoryAndGroup,
            tooltip: 'Refresh Items',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // ... (buildBody method remains the same) ...
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

    if (_groupedItemsBySubCategory.isEmpty) {
      return Center(
        child: Text('No items found in the ${widget.categoryName} category.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: _groupedItemsBySubCategory.values
          .map((subCategoryGroup) => _buildSubCategorySection(subCategoryGroup))
          .toList(),
    );
  }
}

