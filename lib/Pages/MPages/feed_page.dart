import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/MPages/profile_page.dart';
import 'package:flutter_application_1/Pages/mesc/LikesListPage.dart';

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
  List<Map<String, dynamic>> searchResults = [];
  bool _isLoading = true;
  String _error = '';
  int? userId;
  String selectedFilter = 'All';
  bool isAnimating = false;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      await _fetchPosts(); // Refresh when navigating back
      return true;
    });
  }

  List<String> recentSearches = [];

  Future<String> _getRecentSearchKey() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) {
      throw Exception("User ID not found when building recent search key.");
    }
    return 'recent_searches_user_$id';
  }

  void _addToRecentSearches(String username) {
    if (!recentSearches.contains(username)) {
      setState(() {
        recentSearches.insert(0, username);
        if (recentSearches.length > 5) {
          recentSearches = recentSearches.sublist(0, 5);
        }
      });
      _saveRecentSearches(); // Save after update
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getRecentSearchKey();
    recentSearches = prefs.getStringList(key) ?? [];
    setState(() {});
  }

  Future<void> _saveRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getRecentSearchKey();
    await prefs.setStringList(key, recentSearches);
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
        _applyFilter();
      });
      await _loadRecentSearches();
    }
  }

  Future<void> _searchUsers(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final url = Uri.parse('http://10.0.2.2:8000/api/users/search/?q=$query');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      final results =
          data.map<Map<String, dynamic>>((user) {
            final rawPic = user['profile_picture'];
            final fullProfilePicUrl =
                (rawPic != null && rawPic.toString().isNotEmpty) ? rawPic : '';

            print('User profile pic: $fullProfilePicUrl');

            return {
              'id': user['id'] ?? -1,
              'username': user['username'] ?? 'User',
              'profile_picture': fullProfilePicUrl,
            };
          }).toList();

      setState(() {
        searchResults = results;
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
          filteredPosts =
              followingPosts.where((p) => p['userId'] != userId).toList();
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
      filteredPosts[index]['likeCount'] =
          currentIsLiked ? currentLikeCount - 1 : currentLikeCount + 1;
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(onThemeChange: () {}, userId: targetUserId),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ['All', 'Mine', 'Friends', 'Discover'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            filters.map((filter) {
              final isSelected = selectedFilter == filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilter = filter;
                        _applyFilter();
                      });
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFFF9800) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? const Color(0xFFFF9800)
                                  : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
        title:
            !_showSearchBar
                ? const Text(
                  'O U T F I T L Y',
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
                : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search),
                      iconColor: Colors.orange,
                    ),
                    onChanged: _searchUsers,
                  ),
                ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: // Orange thin line
              Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,

        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                _searchController.clear();
                searchResults.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFFFF9800)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder:
                    (context) => Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: .0,
                      ), // Reduce vertical padding
                      child: SizedBox(
                        height: 70, // Set a fixed height for the filter bar
                        child: _buildFilterBar(),
                      ),
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? Center(
                child: Text(_error, style: TextStyle(color: colorScheme.error)),
              )
              : _showSearchBar
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFFF9800), // Orange border
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (recentSearches.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Recent Searches',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        ...recentSearches.map(
                          (username) => ListTile(
                            leading: Icon(
                              Icons.history,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            title: Text(
                              username,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              onPressed: () {
                                setState(() {
                                  recentSearches.remove(username);
                                });
                                _saveRecentSearches();
                              },
                            ),
                            onTap: () {
                              _searchController.text = username;
                              _searchUsers(username);
                            },
                          ),
                        ),
                        const Divider(),
                      ],
                      if (searchResults.isNotEmpty)
                        ...searchResults.map(
                          (user) => ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  (user['profile_picture'] != null &&
                                          user['profile_picture']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(user['profile_picture']!)
                                      : null,
                              backgroundColor: Colors.grey.shade200,
                              child:
                                  (user['profile_picture'] == null ||
                                          user['profile_picture']
                                              .toString()
                                              .isEmpty)
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            title: Text(
                              user['username'] ?? 'User',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Tap to view profile',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            onTap: () {
                              _addToRecentSearches(user['username']);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProfilePage(
                                        onThemeChange: () {},
                                        userId:
                                            (user['id'] != -1)
                                                ? user['id']
                                                : null,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (searchResults.isEmpty &&
                          _searchController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No users found.'),
                        ),
                    ],
                  ),
                ),
              )
              : filteredPosts.isEmpty
              ? const Center(child: Text('No posts found.'))
              : ListView.builder(
                itemCount: filteredPosts.length,
                itemBuilder:
                    (context, index) => _buildPost(index, colorScheme, theme),
              ),
    );
  }

  Widget _buildPost(int index, ColorScheme colorScheme, dynamic theme) {
    final post = filteredPosts[index];
    final isOwnPost = userId != null && post['userId'] == userId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFFF9800), // Orange border
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
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
                      radius: 24,
                      backgroundImage:
                          (post['profilePictureUrl'] != null &&
                                  post['profilePictureUrl']
                                      .toString()
                                      .isNotEmpty)
                              ? NetworkImage(post['profilePictureUrl'])
                              : null,
                      backgroundColor: Colors.grey.shade300,
                      child:
                          post['profilePictureUrl'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () => _goToUserProfile(post['userId']),
                    child: Text(
                      post['username'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F1B0C),
                      ),
                    ),
                  ),
                ),
                if (isOwnPost)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder:
                              (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      title: const Text(
                                        'Delete Post',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () async {
                                        Navigator.pop(
                                          ctx,
                                        ); // Close the bottom sheet
                                        await _deletePost(post['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            if (post['imageUrl'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: Colors.grey[100],
                    height: 245, // Smaller but visible
                    width: double.infinity,
                    child: Image.network(
                      post['imageUrl'],
                      fit: BoxFit.contain, // Show the whole image
                      alignment: Alignment.center,
                    ),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LikesListPage(postId: post['id']),
                        ),
                      );
                    },
                    child: Text(
                      '${post['likeCount']} likes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ),
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
