// ignore_for_file: deprecated_member_use, file_names

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
String sortBy = 'Newest';

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
        final filtered = data
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

    final url = Uri.parse('http://10.0.2.2:8000/api/wardrobe/$itemId/');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 204) {
      setState(() {
        items.removeWhere((item) => item.id == itemId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  }

  String _capitalize(String? value) {
    if (value == null || value.isEmpty) return '';
    return value[0].toUpperCase() + value.substring(1);
  }

  String selectedTag = ''; // for filtering by tag
final tags = ['All', 'Casual', 'Work', 'Formal', 'Comfy', 'Chic', 'Sport', 'Classy'];
final sortOptions = ['Newest', 'Oldest'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subcategoryName),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
  children: [
    for (final tag in tags)
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(
            () {
              final tagKey = tag == 'All' ? '' : tag;
              final count = items
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
          },
        ),
      ),
  ],
),

            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : items.isEmpty
                  ? const Center(
                      child: Text(
                        'No items in this subcategory',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchItems,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: items.where((item) => selectedTag.isEmpty || (item.tags?.toLowerCase().contains(selectedTag.toLowerCase()) ?? false)).length,
                        itemBuilder: (context, index) {
final filteredItems = items
    .where((item) => selectedTag.isEmpty || (item.tags?.toLowerCase().contains(selectedTag.toLowerCase()) ?? false))
    .toList()
  ..sort((a, b) => sortBy == 'Newest' ? b.id.compareTo(a.id) : a.id.compareTo(b.id));
                          final item = filteredItems[index];
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
                                  userId: item.userId,
                                ),
                              ),
                            ),
                            onLongPress: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Item'),
                                content: const Text('Are you sure you want to delete this item?'),
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
                            child: Container(
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
                                              width: double.infinity,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          )
                                        : const Center(child: Icon(Icons.image_not_supported)),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text(
                                      '${_capitalize(item.color)} ${_capitalize(item.subcategoryName)}'.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF4B3C2F),
                                      ),
                                    ),
                                  ),
                                                                   const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
