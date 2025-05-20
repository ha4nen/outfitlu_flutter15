import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'outfit.dart';
import 'outfit_service.dart';

class OutfitDetailsPage extends StatefulWidget {
  final int? outfitId;
  final Outfit outfit;
  final int? userId;

  const OutfitDetailsPage({super.key,required  this.outfit, this.outfitId, this.userId});

  @override
  State<OutfitDetailsPage> createState() => _OutfitDetailsPageState();
}

class _OutfitDetailsPageState extends State<OutfitDetailsPage> {
  Outfit? _fetchedOutfit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.outfit != null) {
      _fetchedOutfit = widget.outfit;
      _loading = false;
    } else {
      _fetchOutfitById();
    }
  }

  Future<void> _fetchOutfitById() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final id = widget.outfitId;

    if (token == null || id == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/outfits/$id/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _fetchedOutfit = Outfit.fromJson(data);
        _loading = false;
      });
    } else {
      print('❌ Failed to fetch outfit: ${response.body}');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Outfit'),
            content: const Text('Are you sure you want to delete this outfit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && _fetchedOutfit != null) {
      await deleteOutfit(_fetchedOutfit!.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_fetchedOutfit == null) {
      return const Scaffold(body: Center(child: Text("Outfit not found")));
    }

    final outfit = _fetchedOutfit!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (outfit.photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        outfit.photoPath!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder:
                            (_, __, ___) => const SizedBox(
                              height: 250,
                              child: Center(child: Icon(Icons.broken_image)),
                            ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if ((outfit.description ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        outfit.description!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  _buildDetailRow('Type:', outfit.type ?? 'Unknown'),
                  _buildDetailRow('Season:', outfit.season ?? 'Unknown'),
                  _buildDetailRow(
                    'Tags:',
                    outfit.tags?.isNotEmpty == true ? outfit.tags! : 'None',
                  ),
                  _buildDetailRow(
                    'Hijab Friendly:',
                    outfit.isHijabFriendly ? 'Yes' : 'No',
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<int?>(
            future: SharedPreferences.getInstance().then(
              (prefs) => prefs.getInt('user_id'),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final isOwner = snapshot.data == outfit.userId;

              if (!isOwner) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Outfit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label + ' ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
