import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/MPages/profile_page.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  List<Map<String, dynamic>> allPosts = [];
  List<Map<String, dynamic>> filteredPosts = [];
  List<Map<String, dynamic>> followingPosts = [];
  List<Map<String, dynamic>> discoverPosts = [];
  bool _isLoading = true;
  String _error = '';
  int? userId;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  ModalRoute.of(context)?.addScopedWillPopCallback(() async {
    await _fetchPosts(); // Refresh when navigating back
    return true;
  });
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

    final url = Uri.parse('http://10.0.2.2:8000/api/feed/combined/');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> followingRaw = data['following'];
        final List<dynamic> discoverRaw = data['discover'];

        List<Map<String, dynamic>> parsePosts(List<dynamic> raw) {
          return raw.map((post) {
            return {
              'id': post['id'],
              'username': post['user']['username'],
              'userId': post['user']['id'],
              'profilePictureUrl': post['user']?['profile_picture'],
              'imageUrl': post['image'],
              'caption': post['caption'] ?? '',
              'likeCount': post['like_count'] ?? 0,
              'isLiked': post['is_liked_by_current_user'] ?? false,
            };
          }).toList();
        }

        followingPosts = parsePosts(followingRaw);
        discoverPosts = parsePosts(discoverRaw);
        allPosts = [...followingPosts, ...discoverPosts];

        setState(() {
          _isLoading = false;
          _applyFilter();
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

  void _applyFilter() {
    setState(() {
      switch (selectedFilter) {
        case 'Mine':
          filteredPosts = allPosts.where((p) => p['userId'] == userId).toList();
          break;
        case 'Friends':
          filteredPosts = followingPosts.where((p) => p['userId'] != userId).toList();
          break;
        case 'Discover':
          filteredPosts = discoverPosts;
          break;
        default:
          filteredPosts = allPosts;
      }
    });
  }

  Future<void> _toggleLike(int postId, int index) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token == null) return;

  final currentIsLiked = filteredPosts[index]['isLiked'];
  final currentLikeCount = filteredPosts[index]['likeCount'];

  // ✅ Optimistically update the UI
  setState(() {
    filteredPosts[index]['isLiked'] = !currentIsLiked;
    filteredPosts[index]['likeCount'] = currentIsLiked ? currentLikeCount - 1 : currentLikeCount + 1;
  });

  final url = Uri.parse('http://10.0.2.2:8000/api/feed/posts/$postId/like/');
  final response = await http.post(
    url,
    headers: {'Authorization': 'Token $token'},
  ); 

  // ❌ If it fails, revert the change
  if (response.statusCode != 200 && response.statusCode != 201) {
    setState(() {
      filteredPosts[index]['isLiked'] = currentIsLiked;
      filteredPosts[index]['likeCount'] = currentLikeCount;
    });
  }
}


  Future<void> _goToUserProfile(int targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          onThemeChange: () {},
          userId: (targetUserId == currentUserId) ? null : targetUserId,
        ),
      ),
    );
  }

  Future<void> _deletePost(int postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx, true);
              final url = Uri.parse('http://10.0.2.2:8000/api/feed/posts/$postId/delete/');
              final response = await http.delete(url, headers: {'Authorization': 'Token $token'});

              if (response.statusCode == 204 || response.statusCode == 200) {
                await _fetchPosts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post')));
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
        title: const Text('Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                selectedFilter = value;
                _applyFilter();
              },
              itemBuilder: (context) => ['All', 'Mine', 'Friends', 'Discover']
                  .map((filter) => PopupMenuItem(value: filter, child: Text(filter)))
                  .toList(),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: TextStyle(color: colorScheme.error)))
              : filteredPosts.isEmpty
                  ? const Center(child: Text('No posts found.'))
                  : ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) => _buildPost(index, colorScheme, theme),
                    ),
    );
  }

  Widget _buildPost(int index, ColorScheme colorScheme, dynamic theme) {
    final post = filteredPosts[index];
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
                      backgroundImage: (post['profilePictureUrl'] != null &&
                              post['profilePictureUrl'].toString().isNotEmpty)
                          ? NetworkImage(post['profilePictureUrl'])
                          : null,
                      backgroundColor: colorScheme.primaryContainer,
                      child: post['profilePictureUrl'] == null
                          ? Icon(Icons.person, color: colorScheme.onPrimaryContainer)
                          : null,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () => _goToUserProfile(post['userId']),
                    child: Text(
                      post['username'] ?? 'Unknown User',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
              GestureDetector(
                onDoubleTap: () => _toggleLike(post['id'], index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1, child: Image.network( post['imageUrl'], fit: BoxFit.contain, alignment: Alignment.center, ), ),
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
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Icon(
                        post['isLiked'] ? Icons.favorite : Icons.favorite_border,
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
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
