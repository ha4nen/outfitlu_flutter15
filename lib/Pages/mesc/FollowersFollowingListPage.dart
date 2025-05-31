import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/Pages/MPages/profile_page.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : users.isEmpty
              ? const Center(child: Text('No users found'))
              : ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, index) {
                  final user = users[index]['user'];
                  final username = user['username'] ?? 'User';
                  final userId = user['id'];
                  final profilePic = user['profile_picture'];
                  final isFollowing = users[index]['is_following'] == true;
                  final isCurrentUser = userId == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          (profilePic != null &&
                                  profilePic.toString().isNotEmpty)
                              ? NetworkImage(profilePic)
                              : null,
                      backgroundColor: Colors.grey.shade300,
                      child:
                          profilePic == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(
                      username,
                      style: const TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProfilePage(
                                onThemeChange: () {},
                                userId: isCurrentUser ? null : userId,
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
                                        : Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(
                                isFollowing ? 'Unfollow' : 'Follow',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                  );
                },
              ),
    );
  }
}
