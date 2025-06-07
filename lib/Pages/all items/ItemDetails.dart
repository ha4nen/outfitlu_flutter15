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
  final int? userId;

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
    this.userId,
  });

  Future<void> deleteItem(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Item'),
            content: const Text('Are you sure you want to delete this item?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFFFF9800)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/wardrobe/$itemId/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 204 || response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
    }
  }

  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Item"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<int?>(
                future: getCurrentUserId(),
                builder: (context, snapshot) {
                  final currentUserId = snapshot.data;
                  final isOwner = userId == null || currentUserId == userId;

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      if (imageUrl != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 200,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_not_supported),
                        ),
                      const SizedBox(height: 24),
                      Center(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            _infoBox("Category", category),
                            _infoBox("Subcategory", subcategory),
                            _infoBox("Color", color),
                            _infoBox("Size", size),
                            _infoBox("Material", material),
                            _infoBox("Season", season),
                            _infoBox("Tags", tags.join(", ")),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (snapshot.connectionState == ConnectionState.done &&
                          isOwner)
                        Center(
                          child: ElevatedButton(
                            onPressed: () => deleteItem(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            child: const Text('Delete Item'),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
