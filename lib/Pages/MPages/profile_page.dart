// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
// import 'dart:io'; // No longer needed for items list
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Keep if used elsewhere

import '../mesc/settings_page.dart';
import 'package:flutter_application_1/Pages/all%20items/all_items_page.dart';
import 'package:flutter_application_1/Pages/Outfits/all_outfits.dart';
import 'package:flutter_application_1/Pages/all items/ItemDetails.dart'; // Ensure this is the correct path
import 'package:flutter_application_1/Pages/mesc/edit_profile_page.dart';
import 'package:flutter_application_1/Pages/Outfits/outfit.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart'; // Ensure this is the correct path
import 'package:flutter_application_1/Pages/mesc/FollowersFollowingListPage.dart'; // <-- Add this import, adjust path if needed

// Re-use the WardrobeItem model (ensure it's consistent with other pages)
class WardrobeItem {
  final int id;
  final String? color;
  final String? size;
  final String? material;
  final String? season;
  final String? tags;
  final String? photoPath;
  final int? categoryId;
  final String? categoryName;
  final int? subcategoryId;
  final String? subcategoryName;
  final int? userId;

  WardrobeItem({
    required this.id,
    this.color,
    this.size,
    this.material,
    this.season,
    this.tags,
    this.photoPath,
    this.categoryId,
    this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    this.userId,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    String? catName = json['category']?['name'];
    String? subcatName = json['subcategory']?['name'];
    int? catId = json['category']?['id'];
    int? subcatId = json['subcategory']?['id'];
    int? userId = json['user'] is int ? json['user'] : (json['user']?['id']);

    return WardrobeItem(
      id: json['id'],
      color: json['color'],
      size: json['size'],
      material: json['material'],
      season: json['season'],
      tags: json['tags'],
      photoPath:
          json['photo_path'] != null
              ? 'http://10.0.2.2:8000${json['photo_path']}'
              : null,
      categoryId: catId,
      categoryName: catName,
      subcategoryId: subcatId,
      subcategoryName: subcatName,
      userId: userId,
    );
  }
}

// Function to get token (keep if used elsewhere)
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

class ProfilePage extends StatefulWidget {
  final VoidCallback onThemeChange;
  final List<File>? items;
  final int? userId;

  const ProfilePage({
    super.key,
    required this.onThemeChange,
    this.items,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Existing state for profile data
  String username = '';
  String bio = '';
  String location = '';
  String gender = '';
  String modestyPreference = '';
  String? profileImageUrl;

  List<Outfit> _recentOutfits = [];
  List<Outfit> _allOutfits = [];

  bool _loadingOutfits = true;
  String _errorOutfits = '';

  // State for wardrobe items
  List<WardrobeItem> _wardrobeItems = [];
  bool _isLoadingItems = true;
  String _errorItems = '';
  bool _hideItems = false;
  bool _hideOutfits = false;
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  bool isMyProfile = true;
  int totalLikes = 0;
  int? currentUserId;
  @override
  void initState() {
    super.initState();
    _loadHideSetting();
    fetchProfileData();
    _fetchWardrobeItems();
    _fetchOutfits();
  }

  Future<void> toggleFollow() async {
    print('widget.userId = ${widget.userId}');
    print('isMyProfile = $isMyProfile');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Token = $token');
    if (token == null || widget.userId == null) {
      print('Missing token or userId');
      return;
    }

    final url = Uri.parse(
      'http://10.0.2.2:8000/api/feed/follow/${widget.userId}/',
    );
    print('Sending POST to $url');

    final response = await http.post(
      url,
      headers: {'Authorization': 'Token $token'},
    );

    print('Response ${response.statusCode}');
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {
        isFollowing = !isFollowing;
        followersCount += isFollowing ? 1 : -1;
      });
    } else {
      print('Failed to toggle follow: ${response.body}');
    }
  }

  Future<void> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');

    final token = prefs.getString('auth_token');

    if (token == null) {
      print('No token found. User might not be logged in.');
      return;
    }

    final url =
        widget.userId == null
            ? Uri.parse('http://10.0.2.2:8000/api/profile/')
            : Uri.parse(
              'http://10.0.2.2:8000/api/users/${widget.userId}/profile/',
            );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['user']?['username'] ?? data['username'] ?? 'unknown';
          bio = data['bio'] ?? '';
          location = data['location'] ?? '';
          gender = data['gender'] ?? '';
          modestyPreference = data['modesty_preference'] ?? '';
          followersCount = data['followers_count'] ?? 0;
          followingCount = data['following_count'] ?? 0;
          isFollowing = data['is_following'] ?? false;
          totalLikes = data['total_likes'] ?? 0;
          isMyProfile =
              (widget.userId == null) || (widget.userId == currentUserId);
          final pic = data['profile_picture'];
          if (pic != null && pic.isNotEmpty) {
            profileImageUrl =
                pic.startsWith('http') ? pic : 'http://10.0.2.2:8000$pic';
          } else {
            profileImageUrl = null;
          }
        });
      } else {
        print('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _loadHideSetting() async {
    final prefs = await SharedPreferences.getInstance();

    final myUserId = prefs.getInt('user_id');
    final viewedUserId = widget.userId ?? myUserId;

    if (viewedUserId != null) {
      final isItemsHidden = prefs.getBool('hide_items_$viewedUserId') ?? false;
      final isOutfitsHidden =
          prefs.getBool('hide_outfits_$viewedUserId') ?? false;

      setState(() {
        _hideItems = viewedUserId == myUserId ? false : isItemsHidden;
        _hideOutfits = viewedUserId == myUserId ? false : isOutfitsHidden;
      });
    }
  }

  // Fetch all wardrobe items for the user
  Future<void> _fetchWardrobeItems() async {
    if (!mounted) return;
    setState(() {
      _isLoadingItems = true;
      _errorItems = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) {
      setState(() {
        _isLoadingItems = false;
        _errorItems = 'Authentication token not found.';
      });
      return;
    }

    final url =
        widget.userId == null
            ? Uri.parse('http://10.0.2.2:8000/api/wardrobe/')
            : Uri.parse(
              'http://10.0.2.2:8000/api/users/${widget.userId}/wardrobe/',
            );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _wardrobeItems =
              data.map((itemJson) => WardrobeItem.fromJson(itemJson)).toList();
          _isLoadingItems = false;
        });
      } else {
        setState(() {
          _isLoadingItems = false;
          _errorItems = 'Failed to load items (Code: ${response.statusCode})';
        });
        print('Error response body (items): ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
        _errorItems = 'An error occurred: $e';
      });
      print('Network or parsing error (items): $e');
    }
  }

  Future<void> _fetchOutfits() async {
    setState(() {
      _loadingOutfits = true;
      _errorOutfits = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _loadingOutfits = false;
          _errorOutfits = 'Authentication token not found.';
        });
        return;
      }

      final url =
          widget.userId == null
              ? Uri.parse('http://10.0.2.2:8000/api/outfits/')
              : Uri.parse(
                'http://10.0.2.2:8000/api/users/${widget.userId}/outfits/',
              );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final sorted =
            data.map((json) => Outfit.fromJson(json)).toList()
              ..sort((a, b) => b.id.compareTo(a.id));

        setState(() {
          _allOutfits = sorted;
          _recentOutfits = sorted.take(4).toList();
          _loadingOutfits = false;
        });
      } else {
        setState(() {
          _errorOutfits =
              'Failed to load outfits (Status code: ${response.statusCode})';
          _loadingOutfits = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorOutfits = 'Error fetching outfits: $e';
        _loadingOutfits = false;
      });
    }
  }

  Widget _buildStatBlock(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF2F1B0C),
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchProfileData();
          await _fetchWardrobeItems();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 32,
            ), // Add bottom padding for scroll
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF9800),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                    bottom: 20,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      if (widget.userId != null)
                        Positioned(
                          top: 4,
                          left: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      if (widget.userId == null)
                        Positioned(
                          top: 4,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => SettingsPage(
                                        onThemeChange: widget.onThemeChange,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      Column(
                        children: [
                          const SizedBox(
                            height: 40,
                          ), // was 16, now 32 for more space before profile picture
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                profileImageUrl != null
                                    ? NetworkImage(profileImageUrl!)
                                    : null,
                            child:
                                profileImageUrl == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Colors.grey,
                                    )
                                    : null,
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(
                              top: 16,
                              left: 16,
                              right: 16,
                            ), // <-- margin for white card
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F1B0C),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bio.isNotEmpty ? bio : ' ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      FollowersFollowingListPage(
                                                        userId:
                                                            widget.userId ??
                                                            currentUserId!,
                                                        showFollowers: false,
                                                      ),
                                            ),
                                          );
                                        },
                                        child: _buildStatBlock(
                                          '$followingCount',
                                          'Following',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      FollowersFollowingListPage(
                                                        userId:
                                                            widget.userId ??
                                                            currentUserId!,
                                                        showFollowers: true,
                                                      ),
                                            ),
                                          );
                                        },
                                        child: _buildStatBlock(
                                          '$followersCount',
                                          'Followers',
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatBlock(
                                        '$totalLikes',
                                        'Likes',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                isMyProfile
                                    ? ElevatedButton(
                                      onPressed: () async {
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => EditProfilePage(),
                                          ),
                                        );
                                        if (updated == true) {
                                          await fetchProfileData();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF9800,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: const Text(
                                        'Edit Profile',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                    : ElevatedButton(
                                      onPressed: toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF9800,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 10,
                                        ),
                                      ),
                                      child: Text(
                                        isFollowing ? 'Unfollow' : 'Follow',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                // --- Items Section ---
                Container(
                  margin: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 8,
                  ), // No space at the top
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap:
                              (_hideItems && widget.userId != null)
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AllItemsPage(
                                              userId: widget.userId,
                                            ),
                                      ),
                                    );
                                  },
                          child: Row(
                            children: [
                              const Text(
                                'Items ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F1B0C),
                                ),
                              ),
                              Text(
                                ' ${_wardrobeItems.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildItemsSection(),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // --- Outfits Section ---
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ), // Increased vertical padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: GestureDetector(
                          onTap:
                              (_hideOutfits && widget.userId != null)
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AllOutfitsPage(
                                              userId: widget.userId,
                                            ),
                                      ),
                                    );
                                  },
                          child: Row(
                            children: [
                              const Text(
                                'Outfits ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2F1B0C),
                                ),
                              ),
                              Text(
                                ' ${_allOutfits.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_loadingOutfits)
                        const Center(child: CircularProgressIndicator())
                      else if (_hideOutfits && widget.userId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Text(
                            'This user has hidden their outfits.',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (_errorOutfits.isNotEmpty)
                        Text(
                          _errorOutfits,
                          style: const TextStyle(color: Colors.red),
                        )
                      else
                        SizedBox(
                          height: 150, // Increased height for bigger images
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentOutfits.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _recentOutfits.length) {
                                // The "see all" arrow at the end
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AllOutfitsPage(
                                                userId: widget.userId,
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 110, // Match item card width
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.9),
                                        border: Border.all(
                                          color: Colors.orange.shade200,
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.arrow_forward,
                                          size: 32,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final outfit = _recentOutfits[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              OutfitDetailsPage(outfit: outfit),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    width: 110, // Match item card width
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child:
                                          outfit.photoPath != null
                                              ? Image.network(
                                                outfit.photoPath!,
                                                fit: BoxFit.cover,
                                                width: 110,
                                                height: 150,
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  progress,
                                                ) {
                                                  if (progress == null)
                                                    return child;
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                },
                                                errorBuilder:
                                                    (context, error, stackTrace) =>
                                                        const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                          ),
                                                        ),
                                              )
                                              : const Center(
                                                child: Icon(
                                                  Icons.photo_library_outlined,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                              ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 90), // Extra bottom padding for scroll
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the items section
  Widget _buildItemsSection() {
    // 👇 Check if the viewed user has hidden their items (and it's not your own profile)
    if (_hideItems && widget.userId != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          'This user has hidden their wardrobe.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_isLoadingItems) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_errorItems.isNotEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'Error loading items: $_errorItems', // <- fixed escaped string
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    final displayedItems = _wardrobeItems.take(4).toList();

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayedItems.length + 1,
        itemBuilder: (context, index) {
          if (index == displayedItems.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllItemsPage(userId: widget.userId),
                    ),
                  );
                },
                child: Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.9),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 32,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            );
          }

          final item = displayedItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ItemDetails(
                        itemId: item.id,
                        itemName: item.material ?? 'Unnamed',
                        color: item.color ?? 'N/A',
                        size: item.size ?? 'N/A',
                        material: item.material ?? 'N/A',
                        season: item.season ?? 'N/A',
                        tags: item.tags?.split(',') ?? [],
                        imageUrl: item.photoPath,
                        category: item.categoryName ?? 'N/A',
                        subcategory: item.subcategoryName ?? 'General',
                        userId: item.userId,
                      ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: 110,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Colors.orange.shade200, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      item.photoPath != null
                          ? Image.network(
                            item.photoPath!,
                            fit: BoxFit.cover,
                            width: 110,
                            height: 150,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.photo_library_outlined,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}