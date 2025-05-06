// Updated ItemDetailsFormPage with centered image and clean multi-tag formatting

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ItemDetailsFormPage extends StatefulWidget {
  final File imageFile;
  final List<Map<String, dynamic>> categoryList;
  final Map<String, List<Map<String, dynamic>>> categories;

  const ItemDetailsFormPage({
    super.key,
    required this.imageFile,
    required this.categoryList,
    required this.categories,
  });

  @override
  State<ItemDetailsFormPage> createState() => _ItemDetailsFormPageState();
}

class _ItemDetailsFormPageState extends State<ItemDetailsFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> itemData = {
    'category': null,
    'subcategory': null,
    'color': '',
    'size': '',
    'material': '',
    'season': 'All-Season',
    'tags': '',
  };

  String? token;
  List<Map<String, dynamic>> subCategories = [];

  final List<String> colorSuggestions = ['Red', 'Blue', 'Black', 'White', 'Green'];
  final List<String> sizeSuggestions = ['S', 'M', 'L', 'XL'];
  final List<String> materialSuggestions = ['Cotton', 'Polyester', 'Wool', 'Silk'];
  final List<String> tagSuggestions = ['Casual', 'Work', 'Formal', 'Comfy', 'Chic'];

  final Map<String, TextEditingController> _controllers = {
    'color': TextEditingController(),
    'size': TextEditingController(),
    'material': TextEditingController(),
    'tags': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
    });
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields.');
      return;
    }

    if (token == null) {
      _showSnackBar('User is not logged in.');
      return;
    }

    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/wardrobe/upload/');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Token $token';

      if (!await widget.imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      request.fields.addAll({
        'category_id': itemData['category']?['id']?.toString() ?? '',
        'subcategory_id': itemData['subcategory']?['id']?.toString() ?? '',
        'color': _controllers['color']!.text,
        'size': _controllers['size']!.text,
        'material': _controllers['material']!.text,
        'season': itemData['season'],
        'tags': _controllers['tags']!.text,
      });

      request.files.add(await http.MultipartFile.fromPath('photo_path', widget.imageFile.path));

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 201) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Error saving item:\n$responseBody');
      }
    } catch (e) {
      _showSnackBar('Unexpected error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Item saved successfully!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            },
            child: const Text("Go to Home"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Item Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.file(widget.imageFile, height: 200)),
              const SizedBox(height: 20),
              _buildLabel("Category"),
              _buildDropdown("Select category", _buildCategoryDropdown()),
              const SizedBox(height: 10),
              _buildLabel("Subcategory"),
              _buildDropdown("Select subcategory", _buildSubCategoryDropdown()),
              const SizedBox(height: 10),
              _buildLabel("Color"),
              _buildWithSuggestions("color", colorSuggestions),
              _buildLabel("Size"),
              _buildWithSuggestions("size", sizeSuggestions),
              _buildLabel("Material"),
              _buildWithSuggestions("material", materialSuggestions),
              _buildLabel("Season"),
              _buildDropdown("Select season", _buildSeasonDropdown()),
              _buildLabel("Tags"),
              _buildWithSuggestions("tags", tagSuggestions, isMulti: true),
              const SizedBox(height: 25),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Item"),
                  onPressed: _saveItem,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _buildDropdown(String hint, Widget child) => Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.white,
        ),
        child: child,
      );

  Widget _buildCategoryDropdown() => DropdownButtonFormField<Map<String, dynamic>>(
        decoration: _inputDecoration("Select category"),
        items: widget.categoryList.map((category) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: category,
            child: Text(category['name'], style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            final relatedSubCategories = widget.categories[value['name']] ?? [];
            setState(() {
              itemData['category'] = value;
              subCategories = relatedSubCategories;
              itemData['subcategory'] = null;
            });
          }
        },
        value: itemData['category'],
        validator: (value) => value == null ? 'Select a category' : null,
      );

  Widget _buildSubCategoryDropdown() => DropdownButtonFormField<Map<String, dynamic>>(
        decoration: _inputDecoration("Select subcategory"),
        items: subCategories.map((subcategory) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: subcategory,
            child: Text(subcategory['name'], style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (value) => setState(() => itemData['subcategory'] = value),
        value: itemData['subcategory'],
        validator: (value) => value == null ? 'Select a subcategory' : null,
      );

  Widget _buildSeasonDropdown() => DropdownButtonFormField<String>(
        decoration: _inputDecoration("Select season"),
        items: ['Winter', 'Spring', 'Summer', 'Autumn', 'All-Season'].map((season) {
          return DropdownMenuItem<String>(
            value: season,
            child: Text(season, style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (value) => setState(() => itemData['season'] = value!),
        value: itemData['season'],
      );

  Widget _buildWithSuggestions(String key, List<String> suggestions, {bool isMulti = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _controllers[key],
            decoration: _inputDecoration("Type or tap a suggestion"),
            onChanged: (value) => itemData[key] = value,
            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
          ),
          Wrap(
            spacing: 8,
            children: suggestions.map((s) => ActionChip(
              label: Text(s, style: const TextStyle(color: Colors.black)),
              backgroundColor: Colors.grey.shade200,
              onPressed: () {
                setState(() {
                  if (isMulti) {
                    final currentText = _controllers[key]!.text.trim();
                    final tags = currentText.isEmpty ? <String>{} : currentText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
                    tags.add(s);
                    _controllers[key]!.text = tags.join(', ');
                    itemData[key] = _controllers[key]!.text;
                  } else {
                    _controllers[key]!.text = s;
                    itemData[key] = s;
                  }
                });
              },
            )).toList(),
          )
        ],
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade100,
      );
}
