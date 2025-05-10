import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ItemDetails extends StatelessWidget {
  final String itemName;
  final String color;
  final String size;
  final String season;
  final List<String> tags;
  final String? imageUrl;
  final File item;
  final int itemId; // 👈 needed for deletion

  const ItemDetails({
    super.key,
    required this.itemName,
    required this.color,
    required this.size,
    required this.season,
    required this.tags,
    required this.imageUrl,
    required this.item,
    required this.itemId,
  });

  Future<void> deleteItem(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
Uri.parse('http://10.0.2.2:8000/api/wardrobe/$itemId/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      Navigator.pop(context); // pop detail page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } else {
      throw Exception('Failed to delete item');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 200,
                  height: 200,
                  color: Theme.of(context).colorScheme.surface,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                          loadingBuilder: (context, child, progress) =>
                              progress == null ? child : const Center(child: CircularProgressIndicator()),
                        )
                      : const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(itemName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Color: $color'),
            Text('Size: $size'),
            Text('Season: $season'),
            const SizedBox(height: 16),
            Text('Tags:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Item'),
                      content: const Text('Are you sure you want to delete this item?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context); // close dialog
                            await deleteItem(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
