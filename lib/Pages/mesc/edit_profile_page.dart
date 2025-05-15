import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  File? _image;
  String? bio;
  String? location;
  String? gender;
  String? modesty;
  late String _authToken;
  late int _userId;

  final _genders = ['male', 'female'];
  final _modestyOptions = ['None', 'Hijab-Friendly'];

  @override
  void initState() {
    super.initState();
    _loadTokenAndUserId();
  }

  Future<void> _loadTokenAndUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token') ?? '';
    _userId = prefs.getInt('user_id') ?? 0;

    if (_authToken.isNotEmpty) {
      await _fetchProfile();
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchProfile() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/profile/'),
      headers: {'Authorization': 'Token $_authToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        bio = data['bio'] as String? ?? '';
        location = data['location'] as String? ?? '';
        gender = _genders.contains(data['gender']) ? data['gender'] : null;
        modesty =
            _modestyOptions.contains(data['modesty_preference'])
                ? data['modesty_preference']
                : null;
        // TODO: load existing profile picture URL if you want to show it
      });
    } else {
      // handle error...
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final mimeType = lookupMimeType(pickedFile.path);
      if (mimeType == null ||
          !(mimeType.startsWith('image/jpeg') ||
              mimeType.startsWith('image/png'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only JPEG and PNG formats are supported.'),
          ),
        );
        return;
      }

      // Resize the image
      final imageBytes = await pickedFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage != null) {
        final resizedImage = img.copyResize(
          decodedImage,
          width: 500,
        ); // Resize to 500px width
        final resizedImageFile = File(pickedFile.path)
          ..writeAsBytesSync(img.encodeJpg(resizedImage));
        setState(() => _image = resizedImageFile);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse('http://10.0.2.2:8000/api/profile/update/');
    final request =
        http.MultipartRequest('PUT', uri)
          ..headers['Authorization'] = 'Token $_authToken'
          ..fields['bio'] = bio!
          ..fields['location'] = location!
          ..fields['gender'] = gender!
          ..fields['modesty_preference'] = modesty!;

    if (_image != null) {
      final mimeType = lookupMimeType(_image!.path)?.split('/');
      if (mimeType != null && mimeType.length == 2) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'profile_picture',
              _image!.path,
              contentType: MediaType(mimeType[0], mimeType[1]),
            ),
          );
        } catch (e) {
          print('Error adding file to request: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add image to request.')),
          );
          return;
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid image format.')));
        return;
      }
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    final backgroundColor = theme.colorScheme.background;
    final onBackgroundColor = theme.colorScheme.onBackground;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          backgroundColor: primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: backgroundColor,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child:
                      _image == null
                          ? Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: onPrimaryColor,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                initialValue: bio,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: TextStyle(color: onBackgroundColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
                style: TextStyle(color: onBackgroundColor),
                onChanged: (v) => bio = v,
                validator:
                    (v) => v == null || v.isEmpty ? 'Please enter a bio' : null,
              ),
              const SizedBox(height: 12),

              // Location
              TextFormField(
                initialValue: location,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: onBackgroundColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
                style: TextStyle(color: onBackgroundColor),
                onChanged: (v) => location = v,
                validator:
                    (v) =>
                        v == null || v.isEmpty
                            ? 'Please enter a location'
                            : null,
              ),
              const SizedBox(height: 12),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: gender,
                hint: Text(
                  'Select Gender',
                  style: TextStyle(color: onBackgroundColor),
                ),
                items:
                    _genders
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g.capitalize(),
                              style: TextStyle(color: onBackgroundColor),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => gender = v),
                validator: (v) => v == null ? 'Please select gender' : null,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Modesty Preference Dropdown
              DropdownButtonFormField<String>(
                value: modesty,
                hint: Text(
                  'Select Modesty Preference',
                  style: TextStyle(color: onBackgroundColor),
                ),
                items:
                    _modestyOptions
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: TextStyle(color: onBackgroundColor),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => modesty = v),
                validator:
                    (v) =>
                        v == null ? 'Please select modesty preference' : null,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: onPrimaryColor,
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor),
                        foregroundColor: primaryColor,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple extension to capitalize the first letter
extension on String {
  String capitalize() =>
      substring(0, 1).toUpperCase() + substring(1).toLowerCase();
}
