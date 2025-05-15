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
import 'package:flutter_application_1/Pages/Outfits/outfit_service.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitDetailsPage.dart'; // Ensure this is the correct path

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
  final int? userId; // <-- Added userId field

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
    this.userId, // <-- Added userId to constructor
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    String? catName = json['category']?['name'];
    String? subcatName = json['subcategory']?['name'];
    int? catId = json['category']?['id'];
    int? subcatId = json['subcategory']?['id'];
    int? userId =
        json['user'] is int
            ? json['user']
            : (json['user']?['id']); // Try both int or nested object

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
      userId: userId, // <-- Assign userId
    );
  }
}

final storage = FlutterSecureStorage(); // Keep if used elsewhere

// Function to get token (keep if used elsewhere)
Future<String?> getToken() async {
  return await storage.read(key: 'auth_token');
}

class ProfilePage extends StatefulWidget {
  final VoidCallback onThemeChange;
  final List<File>? items;
  final int? userId; // 👈 added userId

  // Update constructor: remove 'items' parameter
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
  bool _loadingOutfits = true;
  String _errorOutfits = '';

  // State for wardrobe items
  List<WardrobeItem> _wardrobeItems = [];
  bool _isLoadingItems = true;
  String _errorItems = '';

  @override
  void initState() {
    super.initState();
    fetchProfileData();
    _fetchWardrobeItems();
    _fetchOutfits();
  }

  Future<void> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
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
          profileImageUrl =
              data['profile_picture'] != null &&
                      data['profile_picture'].isNotEmpty
                  ? 'http://10.0.2.2:8000${data['profile_picture']}'
                  : null;
        });
      } else {
        print('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching profile data: $e');
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

  // REMOVED: _loadProfileImage (unless it was actually implemented)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions:
            widget.userId == null
                ? [
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.white
                              : Theme.of(context).iconTheme.color,
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
                ]
                : [],
      ),
      body: RefreshIndicator(
        // Optional: Add pull-to-refresh
        onRefresh: () async {
          await fetchProfileData();
          await _fetchWardrobeItems();
        },
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Ensure scroll works with RefreshIndicator
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- Profile Section (Remains largely the same) ---
                GestureDetector(
                  // onTap: _pickProfileImage, // Add if you implement image picking
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? NetworkImage(profileImageUrl!)
                            : null,
                    child:
                        profileImageUrl == null || profileImageUrl!.isEmpty
                            ? Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).iconTheme.color,
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  '@$username',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (bio.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      bio,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Text(
                  '0 Following  |  0 Followers', // TODO: Implement Follower counts
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.userId == null)
                  ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(),
                        ),
                      );
                      if (updated == true) {
                        await fetchProfileData(); // Refresh profile after editing
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),

                Divider(color: Theme.of(context).dividerColor),

                // --- Items Section Header (Navigate to modified AllItemsPage) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Navigate to the modified AllItemsPage (no args needed)
                            builder:
                                (context) =>
                                    AllItemsPage(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    // Add other actions if needed (e.g., Add Item button)
                  ],
                ),
                const SizedBox(height: 8),

                // --- Items Section Body (Uses fetched data) ---
                _buildItemsSection(), // Use helper method

                const SizedBox(height: 16),

                // --- Outfits Section Header (Remains the same for now) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Update AllOutfitsPage similarly if needed
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AllOutfitsPage(userId: widget.userId),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Outfits',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- Outfits Section Body (Still uses placeholder/old logic) ---
                // TODO: Update this section similarly to the Items section later
                _loadingOutfits
                    ? const Center(child: CircularProgressIndicator())
                    : _errorOutfits.isNotEmpty
                    ? Text(
                      _errorOutfits,
                      style: const TextStyle(color: Colors.red),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentOutfits.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _recentOutfits.length) {
                                // The arrow tile
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
                                              (_) => const AllOutfitsPage(),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 100,
                                        height: 120,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.9),
                                        child: const Center(
                                          child: Icon(
                                            Icons.arrow_forward,
                                            size: 32,
                                            color: Colors.black54,
                                          ),
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
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 100,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      child:
                                          outfit.photoPath != null
                                              ? Image.network(
                                                outfit.photoPath!,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 120,
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
                                                    (_, __, ___) =>
                                                        const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                          ),
                                                        ),
                                              )
                                              : const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
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

                // Original Outfits ListView (commented out, needs update)
                /*
                widget.items.isEmpty // This logic is now incorrect
                    ? Container(...) 
                    : SizedBox(...ListView.builder using widget.items...)
                */
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build the items section
  Widget _buildItemsSection() {
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
          'Error loading items: \$_errorItems',
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
                    MaterialPageRoute(builder: (_) => const AllItemsPage()),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 100,
                    height: 150,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.9),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward,
                        size: 32,
                        color: Colors.black54,
                      ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 110,
                  color: Theme.of(context).colorScheme.surface,
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
                                (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                          )
                          : const Center(
                            child: Icon(Icons.image_not_supported),
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
