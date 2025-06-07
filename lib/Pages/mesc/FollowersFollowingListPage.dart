import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/Pages/Mpages/Profile_Page.dart';

class FollowersFollowingListPage extends StatefulWidget {
  final int userId;
  final bool showFollowers;

  const FollowersFollowingListPage({
    super.key,
    required this.userId,
    required this.showFollowers,
  });

  @override
  State<FollowersFollowingListPage> createState() =>
      _FollowersFollowingListPageState();
}

class _FollowersFollowingListPageState
    extends State<FollowersFollowingListPage> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? token;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    currentUserId = prefs.getInt('user_id');

    if (token == null || currentUserId == null) return;

    final type = widget.showFollowers ? 'followers' : 'following';
    final url = Uri.parse(
      'http://10.0.2.2:8000/api/feed/$type/${widget.userId}/',
    );

    final response = await http.get(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        users = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow(int userId, int index) async {
    if (token == null) return;

    final url = Uri.parse('http://10.0.2.2:8000/api/feed/follow/$userId/');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        users[index]['is_following'] = !(users[index]['is_following'] ?? false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showFollowers ? 'Followers' : 'Following';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFFF9800)),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.separated(
                itemCount: users.length,
                separatorBuilder:
                    (_, __) => Divider(color: Colors.grey.shade200),
                itemBuilder: (_, index) {
                  final user = users[index]['user'];
                  final username = user['username'] ?? 'User';
                  final userId = user['id'];
                  final profilePic = user['profile_picture'];
                  final isFollowing = users[index]['is_following'] == true;
                  final isCurrentUser = userId == currentUserId;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundImage:
                          (profilePic != null &&
                                  profilePic.toString().isNotEmpty)
                              ? NetworkImage(profilePic)
                              : null,
                      backgroundColor: Colors.grey.shade300,
                      child:
                          profilePic == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                    ),
                    title: Text(
                      username,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Tap to view profile',
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfilePage(
                                onThemeChange: () {},
                                userId: userId,
                              ),
                        ),
                      );
                    },
                    trailing:
                        isCurrentUser
                            ? null
                            : ElevatedButton(
                              onPressed: () => _toggleFollow(userId, index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isFollowing
                                        ? Colors.grey
                                        : theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isFollowing ? 'Unfollow' : 'Follow',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                  );
                },
              ),
      backgroundColor: colorScheme.background,
    );
  }
}
