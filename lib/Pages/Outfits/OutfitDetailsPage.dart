import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      _alreadyPosted = prefs.getBool('outfit_posted_${_fetchedOutfit!.id}') ?? false;
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
      final posted = (posts as List).any((post) => post['outfit'] == outfitId);
      if (posted) {
        setState(() => _alreadyPosted = true);
        prefs.setBool('outfit_posted_$outfitId', true);
      }
    }
  }

  Future<void> _postOutfit(int outfitId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final captionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(
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
      prefs.setBool('outfit_posted_$outfitId', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit posted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post outfit: $responseBody')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Delete Outfit', style: TextStyle(color: Color(0xFFD9583B))),
      content: const Text('Are you sure you want to delete this outfit?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFFFF9800))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );

  if (confirmed == true && _fetchedOutfit != null) {
    await deleteOutfit(_fetchedOutfit!.id);

    final prefs = await SharedPreferences.getInstance();
    prefs.remove('outfit_posted_${_fetchedOutfit!.id}');

    if (mounted) {
      Navigator.pop(context, 'refresh'); // return to previous page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit deleted successfully')),
      );
    }
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Outfit Details"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
      ),
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (outfit.photoPath != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.orange.shade200, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          outfit.photoPath!,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _infoBox("Type", outfit.type ?? 'Unknown'),
                      _infoBox("Season", outfit.season ?? 'Unknown'),
                      _infoBox("Tags", outfit.tags ?? 'None'),
                      _infoBox("Hijab Friendly", outfit.isHijabFriendly ? 'Yes' : 'No'),
                    ],
                  ),
                  if (outfit.description != null && outfit.description!.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              outfit.description!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
      const SizedBox(height: 24),

                  if (isOwner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _confirmDelete(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          child: const Text('Delete Outfit'),
                        ),
                        if (!_alreadyPosted)
                          ElevatedButton(
                            onPressed: () => _postOutfit(outfit.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              textStyle: const TextStyle(fontSize: 14),
                            ),
                            child: const Text('Post Outfit'),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          )
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
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
