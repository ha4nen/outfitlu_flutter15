import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/all%20items/SubDetails.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String, dynamic>> subcategories = [];

  @override
  void initState() {
    super.initState();
    _fetchSubCategories();
  }

  Future<void> _fetchSubCategories() async {
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

    final url = Uri.parse('http://10.0.2.2:8000/api/categories/${widget.categoryId}/subcategories/');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          subcategories = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to load subcategories: ${response.statusCode}';
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
              : ListView.builder(
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final sub = subcategories[index];
                    return ListTile(
                      title: Text(sub['name'] ?? 'Unknown'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubDetails(
                              subcategoryId: sub['id'],
                              subcategoryName: sub['name'] ?? 'Unknown',
                              subCategory: '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
