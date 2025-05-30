import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/Pages/Mpages/Profile_Page.dart'; // Update the path as needed

class LikesListPage extends StatefulWidget {
  final int postId;
  const LikesListPage({super.key, required this.postId});

  @override
  State<LikesListPage> createState() => _LikesListPageState();
}

class _LikesListPageState extends State<LikesListPage> {
  List<Map<String, dynamic>> likedUsers = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchLikedUsers();
  }

  Future<void> _fetchLikedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    final url = Uri.parse(
      'http://10.0.2.2:8000/api/feed/posts/${widget.postId}/likes/',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          likedUsers = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load likes';
          _loading = false;
          print('Response: ${response.statusCode}');
          print('Body: ${response.body}');
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liked by')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(child: Text(_error))
              : ListView.builder(
                itemCount: likedUsers.length,
                itemBuilder: (context, index) {
                  final user = likedUsers[index];
                  return ListTile(
                    leading:
                        user['profile_picture'] != null
                            ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                user['profile_picture'],
                              ),
                            )
                            : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['username'] ?? 'User'),
                    subtitle: const Text('Tap to view profile'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfilePage(
                                onThemeChange:
                                    () {}, // Provide an empty callback
                                userId: user['id'], // Pass the user ID
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
