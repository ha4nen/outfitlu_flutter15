import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/MPages/profile_page.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key, required List<Map<String, String>> posts});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  List<Map<String, dynamic>> posts = [];
  bool _isLoading = true;
  String _error = '';
  int? userId;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    userId = prefs.getInt('user_id');

    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Authentication token not found.';
      });
      return;
    }

    final url = Uri.parse('http://10.0.2.2:8000/api/feed/posts/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final formatted =
            data.map((post) {
              return {
                'id': post['id'],
                'username': post['user']['username'],
                'userId': post['user']['id'],
                'profilePictureUrl':
                    post['user']['profile']?['profile_picture'], // ✅ GET FROM profile
                'imageUrl':
                    post['image'] != null
                        ? 'http://10.0.2.2:8000${post['image']}'
                        : null,
                'caption': post['caption'] ?? '',
                'likeCount': post['like_count'] ?? 0,
                'isLiked': post['is_liked_by_current_user'] ?? false,
              };
            }).toList();

        setState(() {
          posts = List<Map<String, dynamic>>.from(formatted);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load posts (Status code: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'An error occurred: $e';
      });
    }
  }

  Future<void> _toggleLike(int postId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final url = Uri.parse('http://10.0.2.2:8000/api/feed/posts/$postId/like/');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        posts[index]['isLiked'] = !posts[index]['isLiked'];
        posts[index]['likeCount'] += posts[index]['isLiked'] ? 1 : -1;
      });
    }
  }

  void _goToUserProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(onThemeChange: () {}, userId: userId),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx, true);
                  final url = Uri.parse(
                    'http://10.0.2.2:8000/api/feed/posts/$postId/delete/',
                  );
                  final response = await http.delete(
                    url,
                    headers: {'Authorization': 'Token $token'},
                  );

                  if (response.statusCode == 204 ||
                      response.statusCode == 200) {
                    await _fetchPosts();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post deleted')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete post')),
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                child: Text(_error, style: TextStyle(color: colorScheme.error)),
              )
              : posts.isEmpty
              ? Center(
                child: Text(
                  'No posts available.',
                  style: TextStyle(color: colorScheme.onBackground),
                ),
              )
              : ListView.builder(
                itemCount: posts.length,
                itemBuilder:
                    (context, index) => _buildPost(index, colorScheme, theme),
              ),
    );
  }

  Widget _buildPost(int index, ColorScheme colorScheme, dynamic theme) {
    final post = posts[index];
    final isOwnPost = userId != null && post['userId'] == userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ListTile(
                  leading: GestureDetector(
                    onTap: () => _goToUserProfile(post['userId']),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundImage:
                          (post['profilePictureUrl'] != null &&
                                  post['profilePictureUrl']
                                      .toString()
                                      .isNotEmpty)
                              ? NetworkImage(
                                'http://10.0.2.2:8000${post['profilePictureUrl']}',
                              )
                              : null,
                      backgroundColor: colorScheme.primaryContainer,
                      child:
                          post['profilePictureUrl'] == null
                              ? Icon(
                                Icons.person,
                                color: colorScheme.onPrimaryContainer,
                              )
                              : null,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () => _goToUserProfile(post['userId']),
                    child: Text(
                      post['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                if (isOwnPost)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePost(post['id']),
                    ),
                  ),
              ],
            ),
            if (post['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio:
                      1, // You can adjust this if most of your images are taller or wider
                  child: Image.network(
                    post['imageUrl'],
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(post['id'], index),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        post['isLiked']
                            ? Icons.favorite
                            : Icons.favorite_border,
                        key: ValueKey(post['isLiked']),
                        color: post['isLiked'] ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${post['likeCount']}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post['caption'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
