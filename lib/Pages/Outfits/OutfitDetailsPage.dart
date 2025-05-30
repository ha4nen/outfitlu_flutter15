// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'outfit.dart';
import 'outfit_service.dart';

class OutfitDetailsPage extends StatefulWidget {
  final int? outfitId;
  final Outfit outfit;
  final int? userId;

  const OutfitDetailsPage({
    super.key,
    required this.outfit,
    this.outfitId,
    this.userId,
  });

  @override
  State<OutfitDetailsPage> createState() => _OutfitDetailsPageState();
}

class _OutfitDetailsPageState extends State<OutfitDetailsPage> {
  Outfit? _fetchedOutfit;
  bool _loading = true;
  bool _alreadyPosted = false;
  int? _loggedInUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedInUserId = prefs.getInt('user_id');

    if (widget.outfitId != null) {
      await _fetchOutfitById(widget.outfitId!);
    } else {
      _fetchedOutfit = widget.outfit;
    }

    if (_fetchedOutfit != null) {
      _alreadyPosted =
          prefs.getBool('outfit_posted_${_fetchedOutfit!.id}') ?? false;
      if (!_alreadyPosted) {
        await _checkIfAlreadyPosted(_fetchedOutfit!.id);
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchOutfitById(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/outfits/$id/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _fetchedOutfit = Outfit.fromJson(data);
    }
  }

  Future<void> _checkIfAlreadyPosted(int outfitId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/feed/posts/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final posts = jsonDecode(response.body);
      final posted = posts.any((post) => post['outfit'] == outfitId);
      if (posted) {
        setState(() => _alreadyPosted = true);
        prefs.setBool('outfit_posted_$outfitId', true); // Cache posted state
      }
    }
  }

  Future<void> _postOutfit(int outfitId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final captionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Post Outfit"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add a caption (optional):"),
                TextField(controller: captionController),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Post"),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final uri = Uri.parse('http://10.0.2.2:8000/api/feed/posts/create/');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Token $token';
    request.fields['outfit_id'] = outfitId.toString();
    request.fields['caption'] = captionController.text;

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 201) {
      setState(() => _alreadyPosted = true);
      prefs.setBool('outfit_posted_$outfitId', true); // Save posted flag
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Outfit posted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to post outfit: $responseBody')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
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
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('outfit_posted_${_fetchedOutfit!.id}'); // Clean up
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _fetchedOutfit == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final outfit = _fetchedOutfit!;
    final isOwner = _loggedInUserId == outfit.userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Outfit Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (outfit.photoPath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        outfit.photoPath!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        loadingBuilder:
                            (context, child, progress) =>
                                progress == null
                                    ? child
                                    : const SizedBox(
                                      height: 250,
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        outfit.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
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
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Outfit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (!_alreadyPosted)
                    ElevatedButton.icon(
                      onPressed: () => _postOutfit(outfit.id),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Post Outfit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                ],
              ),
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
              text: '$label ',
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
