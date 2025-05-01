// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../mesc/settings_page.dart';
import 'package:flutter_application_1/Pages/all%20items/all_items_page.dart';
import 'package:flutter_application_1/Pages/Outfits/all_outfits.dart';
import 'package:flutter_application_1/Pages/all items/ItemDetails.dart'; // Ensure this is the correct path
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/Pages/mesc/edit_profile_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Future<String?> getToken() async {
  return await storage.read(key: 'auth_token');
}

class ProfilePage extends StatefulWidget {
  final VoidCallback onThemeChange;
  final List<File> items; // Shared list of items

  const ProfilePage({super.key, required this.onThemeChange, required this.items});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  bool _isEditing = false; // Tracks whether the user is in edit mode
  final Set<int> _selectedItems = {}; // Tracks selected items for deletion
  String username = '';
  String bio = '';
  String location = '';
  String gender = '';
  String modestyPreference = '';
  String? profileImageUrl; // For loading from the server


  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    fetchProfileData();
  }

Future<void> fetchProfileData() async {
  final token = await getToken();
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8000/api/profile/'),
    headers: {'Authorization': 'Token $token'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
  username = data['user']?['username'] ?? '';
  bio = data['bio'] ?? '';
  location = data['location'] ?? '';
  gender = data['gender'] ?? '';
  modestyPreference = data['modesty_preference'] ?? '';

  if (data['profile_picture'] != null && data['profile_picture'] != '') {
    _profileImage = File('');
    profileImageUrl = data['profile_picture']; // should be full URL from the server
  }
});

  } else {
    print('Failed to load profile data');
  }
}


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _saveProfileImage(pickedFile.path);
    }
  }

  Future<void> _saveProfileImage(String path) async {
    // Save profile image path locally (e.g., using SharedPreferences)
  }

  Future<void> _loadProfileImage() async {
    // Load profile image path from local storage
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedItems.clear(); // Clear selections when toggling modes
    });
  }

  void _deleteSelectedItems() {
    setState(() {
      widget.items.removeWhere((file) => _selectedItems.contains(widget.items.indexOf(file)));
      _selectedItems.clear();
      _isEditing = false; // Exit edit mode after deletion
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white // White in light theme
                  : Theme.of(context).iconTheme.color, // Default in dark theme
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      SettingsPage(onThemeChange: widget.onThemeChange),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : (profileImageUrl != null
                            ? NetworkImage(profileImageUrl!) as ImageProvider
                            : null),
                    child: (_profileImage == null && profileImageUrl == null)
                        ? Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).iconTheme.color)
                        : null,
                  ),
 ), // ✅ Properly closed GestureDetector
              SizedBox(height: 16.0),

              // Username
              // Username
              Text(
                '@$username',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),

              // Bio - Move this up
                Builder(
                  builder: (context) {
                    if (bio.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          bio,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Return an empty widget if bio is empty
                  },
                ),


              // Followers and Following Count
              Text(
                '0 Following  |  0 Followers',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color, // Dynamic text color
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                );
                if (updated == true) {
                  await fetchProfileData(); // Refresh after editing
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text('Edit Profile', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),

              // Divider
              Divider(color: Theme.of(context).dividerColor), // Dynamic divider color

              // Items Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllItemsPage(
                            categorizedTops: {},
                            categorizedBottoms: {},
                            categorizedAccessories: {},
                            categorizedShoes: {},
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary, // Dynamic background color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary, // Dynamic text color
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.delete : Icons.edit,
                      color: Theme.of(context).iconTheme.color, // Dynamic icon color
                    ),
                    onPressed: _isEditing ? _deleteSelectedItems : _toggleEditMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items Section
              widget.items.isEmpty
                  ? Container(
                      height: 150,
                      color: Theme.of(context).colorScheme.surface, // Dynamic placeholder color
                      child: Center(
                        child: Text(
                          'No items to display',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Dynamic text color
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedItems.contains(index);
                          return GestureDetector(
                            onTap: _isEditing
                                ? () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedItems.remove(index);
                                      } else {
                                        _selectedItems.add(index);
                                      }
                                    });
                                  }
                                : () {
                                    // Navigate to the ItemDetailsPage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetails(
                                          item: widget.items[index],
                                          itemName: 'Sample Item Name',
                                          color: 'Sample Color',
                                          size: 'Sample Size',
                                          season: 'Sample Season',
                                          tags: ['Sample Tag 1', 'Sample Tag 2'],
                                        ),
                                      ),
                                    );
                                  },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.file(
                                    widget.items[index],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5) // Dynamic overlay color
                                        : null,
                                    colorBlendMode: isSelected ? BlendMode.darken : null,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.onPrimary, // Dynamic icon color
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 16), // Add spacing between sections

              // Outfits Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllOutfitsPage(
                            outfits: widget.items,
                            summerOutfits: [],
                            winterOutfits: [],
                            fallOutfits: [],
                            springOutfits: [],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary, // Dynamic background color
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Outfits',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary, // Dynamic text color
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.delete : Icons.edit,
                      color: Theme.of(context).iconTheme.color, // Dynamic icon color
                    ),
                    onPressed: _isEditing ? _deleteSelectedItems : _toggleEditMode,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Outfits Section
              widget.items.isEmpty
                  ? Container(
                      height: 150,
                      color: Theme.of(context).colorScheme.surface, // Dynamic placeholder color
                      child: Center(
                        child: Text(
                          'No outfits to display',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color), // Dynamic text color
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.items.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedItems.contains(index);
                          return GestureDetector(
                            onTap: _isEditing
                                ? () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedItems.remove(index);
                                      } else {
                                        _selectedItems.add(index);
                                      }
                                    });
                                  }
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetails(
                                          item: widget.items[index],
                                          itemName: 'Sample Item Name',
                                          color: 'Sample Color',
                                          size: 'Sample Size',
                                          season: 'Sample Season',
                                          tags: ['Sample Tag 1', 'Sample Tag 2'],
                                        ),
                                      ),
                                    );
                                  },
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.file(
                                    widget.items[index],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary.withOpacity(0.5) // Dynamic overlay color
                                        : null,
                                    colorBlendMode: isSelected ? BlendMode.darken : null,
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.onPrimary, // Dynamic icon color
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}