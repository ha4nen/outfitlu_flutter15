// ignore_for_file: unused_element, unused_field

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';

class AllItemsPage extends StatefulWidget {
  final Map<String, List<File>> categorizedTops;
  final Map<String, List<File>> categorizedBottoms;
  final Map<String, List<File>> categorizedAccessories;
  final Map<String, List<File>> categorizedShoes;

  const AllItemsPage({
    super.key,
    required this.categorizedTops,
    required this.categorizedBottoms,
    required this.categorizedAccessories,
    required this.categorizedShoes,
  });

  @override
  State<AllItemsPage> createState() => _AllItemsPageState();
}

class _AllItemsPageState extends State<AllItemsPage> {
  final Set<String> _sectionsMarkedForDelete = {};
  final bool _isDeleteMode = false;

  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F1E1),
          title: const Text("Add New Section", style: TextStyle(color: Color(0xFF2C3E50))),
          content: TextField(
            decoration: const InputDecoration(hintText: "Section name"),
            onChanged: (value) {
              newCategory = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B1B30)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (newCategory.isNotEmpty &&
                    !widget.categorizedTops.containsKey(newCategory)) {
                  setState(() {
                    widget.categorizedTops[newCategory] = [];
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6F1E1),
        title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF2C3E50))),
        content: Text('Are you sure you want to delete "$categoryName"?', style: TextStyle(color: Color(0xFF2C3E50))),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F61)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                widget.categorizedTops.remove(categoryName);
                widget.categorizedBottoms.remove(categoryName);
                widget.categorizedAccessories.remove(categoryName);
                widget.categorizedShoes.remove(categoryName);
                _sectionsMarkedForDelete.remove(categoryName);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, Map<String, List<File>> categorizedItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubDetails(
                  subcategoryName: title, subCategory: '', // Pass the clicked category name dynamically
                ),
              ),
            );
          },
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary, // Dynamic text color
            ),
          ),
        ),
        const SizedBox(height: 8),
        categorizedItems.isEmpty
            ? Container(
                height: 150,
                color: Theme.of(context).colorScheme.surface, // Dynamic placeholder background color
                child: Center(
                  child: Text(
                    'No items to display',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Dynamic text color
                  ),
                ),
              )
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categorizedItems.values.expand((e) => e).length,
                  itemBuilder: (context, index) {
                    final file = categorizedItems.values.expand((e) => e).toList()[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        file,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dynamic background color
      appBar: AppBar(
        title: const Text('All Items'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color), // Dynamic icon color
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySection('Tops', widget.categorizedTops),
              _buildCategorySection('Bottoms', widget.categorizedBottoms),
              _buildCategorySection('Accessories', widget.categorizedAccessories),
              _buildCategorySection('Shoes', widget.categorizedShoes),
            ],
          ),
        ),
      ),
    );
  }
}