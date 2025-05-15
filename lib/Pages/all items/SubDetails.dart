import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_items_page.dart' as all_items;
import 'ItemDetails.dart';

class SubDetails extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;
  final String subCategory;
  final int? userId;

  const SubDetails({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
    required this.subCategory,
    this.userId,
  });

  @override
  State<SubDetails> createState() => _SubDetailsState();
}

class _SubDetailsState extends State<SubDetails> {
  List<all_items.WardrobeItem> items = [];
  bool isLoading = true;
  String error = '';

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
        error = 'No token found';
      });
      return;
    }

    final url =
        widget.userId != null
            ? Uri.parse(
              'http://10.0.2.2:8000/api/users/${widget.userId}/wardrobe/',
            )
            : Uri.parse('http://10.0.2.2:8000/api/wardrobe/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered =
            data
                .map((json) => all_items.WardrobeItem.fromJson(json))
                .where((item) => item.subcategoryId == widget.subcategoryId)
                .toList();

        setState(() {
          items = filtered;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          error = 'Failed to load items';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = 'Error: $e';
      });
    }
  }

  Future<void> _deleteItem(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final url =
        widget.userId != null
            ? Uri.parse(
              'http://10.0.2.2:8000/api/users/${widget.userId}/wardrobe/',
            )
            : Uri.parse('http://10.0.2.2:8000/api/wardrobe/');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 204) {
      setState(() {
        items.removeWhere((item) => item.id == itemId);
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.subcategoryName)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
              ? Center(child: Text(error))
              : items.isEmpty
              ? const Center(child: Text('No items in this subcategory'))
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
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ItemDetails(
                                  itemId: item.id,
                                  itemName: item.material ?? 'Unnamed',
                                  color: item.color ?? 'N/A',
                                  size: item.size ?? 'N/A',
                                  material: item.material ?? 'N/A',
                                  season: item.season ?? 'N/A',
                                  tags: item.tags?.split(',') ?? [],
                                  imageUrl: item.photoPath,
                                  category: item.categoryName ?? 'N/A',
                                  subcategory:
                                      item.subcategoryName ?? 'General',
                                  userId: item.userId,
                                ),
                          ),
                        ),
                    onLongPress:
                        () => showDialog(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text('Delete Item'),
                                content: const Text(
                                  'Are you sure you want to delete this item?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _deleteItem(item.id);
                                    },
                                    child: const Text('Yes'),
                                  ),
                                ],
                              ),
                        ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          item.photoPath != null
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
