import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/The+Button/ItemDetailsFormPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ConfirmPhotoPage extends StatelessWidget {
  final File imageFile;

  const ConfirmPhotoPage({super.key, required this.imageFile});

  // Function to fetch categories and build categoryList + subcategories map
  Future<Map<String, dynamic>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      throw Exception('Token not found');
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/categories/'),
      headers: {'Authorization': 'Token $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> categoryData = json.decode(response.body);

      final List<Map<String, dynamic>> categoryList = [];
      final Map<String, List<Map<String, dynamic>>> formattedCategories = {};

      for (var category in categoryData) {
        final String categoryName = category['name'];
        final int categoryId = category['id'];
        final List<dynamic> subcategories = category['subcategories'];

        // Add to category list for dropdown
        categoryList.add({'id': categoryId, 'name': categoryName});

        // Map subcategories
        formattedCategories[categoryName] =
            subcategories.map<Map<String, dynamic>>((sub) {
              return {
                'id': sub['id'],
                'name': sub['name'],
                'category': {'id': categoryId, 'name': categoryName},
              };
            }).toList();
      }

      return {'categoryList': categoryList, 'categories': formattedCategories};
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Your Item"),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: theme.colorScheme.surfaceVariant,
              child: Image.file(imageFile),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text("Use Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () async {
                  try {
                    final data = await fetchCategories();
                    final categories = data['categories'];
                    final categoryList = data['categoryList'];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ItemDetailsFormPage(
                              imageFile: imageFile,
                              categoryList: categoryList,
                              categories: categories,
                            ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Error: ${e.toString()}",
                          style: TextStyle(color: theme.colorScheme.onError),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retake"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
