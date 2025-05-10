import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ItemDetails extends StatelessWidget {
  final String itemName;
  final String color;
  final String size;
  final String material;
  final String season;
  final List<String> tags;
  final String? imageUrl;
  final int itemId;
  final String category;
  final String subcategory;

  const ItemDetails({
    super.key,
    required this.itemName,
    required this.color,
    required this.size,
    required this.material,
    required this.season,
    required this.tags,
    required this.imageUrl,
    required this.itemId,
    required this.category,
    required this.subcategory,
  });
Future<void> deleteItem(BuildContext context, int itemId) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Item'),
      content: const Text('Are you sure you want to delete this item?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.delete(
    Uri.parse('http://10.0.2.2:8000/api/wardrobe/$itemId/'), // ✅ Corrected here
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode == 204 || response.statusCode == 200) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item deleted successfully')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete item')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_not_supported),
              ),
            const SizedBox(height: 24),

            Text(
              itemName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDetail('Category', category, theme),
            _buildDetail('Subcategory', subcategory, theme),
            _buildDetail('Color', color, theme),
            _buildDetail('Size', size, theme),
            _buildDetail('Material', material, theme),
            _buildDetail('Season', season, theme),
            const SizedBox(height: 16),

            Text(
              'Tags:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () => deleteItem(context, itemId),
              icon: const Icon(Icons.delete),
              label: const Text('Delete Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        '$label: $value',
        style: theme.textTheme.bodyLarge,
      ),
    );
  }
}
