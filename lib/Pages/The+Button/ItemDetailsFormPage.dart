// Updated ItemDetailsFormPage with centered image and clean multi-tag formatting

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final List<String> colorSuggestions = [
    'Red',
    'Blue',
    'Black',
    'White',
    'Green',
    'Yellow',
    'Beige',
    'Gray',
    'Brown',
    'Orange',
  ];
  final List<String> sizeSuggestions = ['S', 'M', 'L', 'XL'];
  final List<String> materialSuggestions = [
    'Cotton',
    'Polyester',
    'Wool',
    'Silk',
    'Linen',
    'Denim',
    'Canvas',
    'Suede',
    'Leather',
  ];
  final List<String> tagSuggestions = [
    'Casual',
    'Work',
    'Formal',
    'Comfy',
    'Chic',
    'Sport',
    'Classy',
  ];

  // Remove controllers for fields that no longer need typing
  // Add controller for size field
  final Map<String, TextEditingController> _controllers = {
    'size': TextEditingController(),
  };

  // Add state to track selected chips for each field
  Map<String, dynamic> selectedChoices = {
    'color': null,
    'size': null,
    'material': null,
    'tags': <String>{},
  };

  // Add this map to associate color names with Flutter Colors
  final Map<String, Color> colorNameMap = {
    'Red': Colors.red,
    'Blue': Colors.blue,
    'Black': Colors.black,
    'White': Colors.white,
    'Green': Colors.green,
    'Yellow': Colors.yellow,
    'Beige': Color(0xFFF5F5DC),
    'Gray': Colors.grey,
    'Brown': Colors.brown,
    'Orange': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadToken();
    // Initialize selectedChoices with default values if needed
    selectedChoices['tags'] = <String>{};
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
        'color': itemData['color'],
        'size': _controllers['size']!.text,
        'material': itemData['material'],
        'season': itemData['season'],
        'tags': itemData['tags'],
      });

      request.files.add(
        await http.MultipartFile.fromPath('photo_path', widget.imageFile.path),
      );

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
      builder:
          (ctx) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Item saved successfully!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/main', (route) => false);
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
      appBar: AppBar(
        title: const Text("Item Details"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFFF9800), // thin line
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Image.file(widget.imageFile, height: 200)),
              const SizedBox(height: 20),
              _buildLabel("Category", required: true),
              _buildDropdown("Select category", _buildCategoryDropdown()),
              const SizedBox(height: 10),
              _buildLabel("Subcategory", required: true),
              _buildDropdown("Select subcategory", _buildSubCategoryDropdown()),
              const SizedBox(height: 10),
              _buildLabel("Color", required: true),
              _buildWithSuggestions("color", colorSuggestions),
              _buildLabel("Material", required: true),
              _buildWithSuggestions("material", materialSuggestions),
              _buildLabel("Season", required: true),
              _buildDropdown("Select season", _buildSeasonDropdown()),
              // Optional fields start here
              _buildLabel("Size", required: true),
              TextFormField(
                controller: _controllers['size'],
                decoration: _dropdownDecoration(
                  _controllers['size']!.text.isEmpty ? "Enter size" : "",
                ),
                onChanged: (val) => setState(() => itemData['size'] = val),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter a size' : null,
              ),
              _buildWithSuggestions("size", sizeSuggestions),
              _buildLabel("Tags"), // No (Optional) shown
              _buildWithSuggestions("tags", tagSuggestions, isMulti: true),
              const SizedBox(height: 25),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Item"),
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update _buildLabel to show (Optional) for non-required fields
  Widget _buildLabel(String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18, // Make headline bigger
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
          )
        // Remove (Optional) for non-required fields, including tags
      ],
    ),
  );

  Widget _buildDropdown(String hint, Widget child) => Theme(
    data: Theme.of(context).copyWith(canvasColor: Colors.white),
    child: child,
  );

  // Use this decoration for all dropdowns
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.orange.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.orange.shade200),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Color(0xFFFF9800), width: 2),
      ),
    );
  }

  Widget _buildCategoryDropdown() =>
      DropdownButtonFormField<Map<String, dynamic>>(
        decoration: _dropdownDecoration(
          itemData['category'] == null ? "Select category" : "",
        ),
        items: widget.categoryList.map((category) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: category,
            child: Text(
              category['name'],
              style: const TextStyle(color: Colors.black),
            ),
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

  Widget _buildSubCategoryDropdown() =>
      DropdownButtonFormField<Map<String, dynamic>>(
        decoration: _dropdownDecoration(
          itemData['subcategory'] == null ? "Select subcategory" : "",
        ),
        items: subCategories.map((subcategory) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: subcategory,
            child: Text(
              subcategory['name'],
              style: const TextStyle(color: Colors.black),
            ),
          );
        }).toList(),
        onChanged: (value) => setState(() => itemData['subcategory'] = value),
        value: itemData['subcategory'],
        validator: (value) => value == null ? 'Select a subcategory' : null,
      );

  Widget _buildSeasonDropdown() => DropdownButtonFormField<String>(
    decoration: _dropdownDecoration(
      ['Winter', 'Spring', 'Summer', 'Autumn'].contains(itemData['season'])
        ? ""
        : "Select season"
    ),
    items: ['Winter', 'Spring', 'Summer', 'Autumn'].map((season) {
      return DropdownMenuItem<String>(
        value: season,
        child: Text(season, style: const TextStyle(color: Colors.black)),
      );
    }).toList(),
    onChanged: (value) => setState(() => itemData['season'] = value!),
    value: ['Winter', 'Spring', 'Summer', 'Autumn'].contains(itemData['season'])
        ? itemData['season']
        : null,
    validator: (value) => value == null ? 'Select a season' : null,
  );

  Widget _buildWithSuggestions(
    String key,
    List<String> suggestions, {
    bool isMulti = false,
  }) {
    const Color orange = Color(0xFFFF9800);
    const Color orangeLight = Color(0xFFFFE0B2);
    const Color darkBrown = Color(0xFF2F1B0C);

    // For color and material, make selection mandatory
    if (key == "color" || key == "material") {
      return FormField<String>(
        validator: (_) =>
            selectedChoices[key] == null ? 'Select a $key' : null,
        builder: (state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: suggestions.map((s) {
                final isSelected = selectedChoices[key] == s;
                return ChoiceChip(
                  label: Text(
                    s,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : darkBrown,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: orange,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? orange : orangeLight,
                    ),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      selectedChoices[key] = selected ? s : null;
                      itemData[key] = selected ? s : '';
                    });
                    state.validate();
                  },
                );
              }).toList(),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    // For size, fill the field if a suggestion is selected
    if (key == "size") {
      return Wrap(
        spacing: 8,
        children: suggestions.map((s) {
          final isSelected = _controllers['size']!.text == s;
          return ChoiceChip(
            label: Text(
              s,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : darkBrown,
              ),
            ),
            selected: isSelected,
            selectedColor: orange,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? orange : orangeLight,
              ),
            ),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _controllers['size']!.text = s;
                  itemData['size'] = s;
                } else {
                  _controllers['size']!.clear();
                  itemData['size'] = '';
                }
              });
            },
          );
        }).toList(),
      );
    }

    // For tags and other fields
    return Wrap(
      spacing: 8,
      children: suggestions.map((s) {
        final isSelected = isMulti
            ? (selectedChoices[key] as Set<String>).contains(s)
            : selectedChoices[key] == s;

        return ChoiceChip(
          label: Text(
            s,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : darkBrown,
            ),
          ),
          selected: isSelected,
          selectedColor: orange,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? orange : orangeLight,
            ),
          ),
          onSelected: (selected) {
            setState(() {
              if (isMulti) {
                final tags = Set<String>.from(selectedChoices[key] as Set<String>);
                if (selected) {
                  tags.add(s);
                } else {
                  tags.remove(s);
                }
                selectedChoices[key] = tags;
                itemData[key] = tags.join(', ');
              } else {
                selectedChoices[key] = selected ? s : null;
                itemData[key] = selected ? s : '';
              }
            });
          },
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.black87),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey.shade100,
  );
}
