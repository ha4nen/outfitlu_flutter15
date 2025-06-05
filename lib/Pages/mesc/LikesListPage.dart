import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/Pages/Mpages/Profile_Page.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked by'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Text(
                    _error,
                    style: TextStyle(color: colorScheme.error),
                  ),
                )
              : ListView.separated(
                  itemCount: likedUsers.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final user = likedUsers[index];
                    final username = user['username'] ?? 'User';
                    final profilePic = user['profile_picture'];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage: (profilePic != null && profilePic.toString().isNotEmpty)
                            ? NetworkImage(profilePic)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: profilePic == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        username,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Tap to view profile',
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              onThemeChange: () {},
                              userId: user['id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      backgroundColor: colorScheme.background,
    );
  }
}
