import 'package:flutter/material.dart';
import 'dart:io';
import '../../SubDetails.dart'; // Import SubDetails page

class BottomsPage extends StatefulWidget {
  final Map<String, List<File>> categorizedBottoms;

  const BottomsPage({
    super.key,
    required this.categorizedBottoms,
  });

  @override
  State<BottomsPage> createState() => _BottomsPageState();
}

class _BottomsPageState extends State<BottomsPage> {
  final Set<String> _sectionsMarkedForDelete = {};
  bool _isDeleteMode = false;

  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F1E1),
          title: const Text("Add New Section", style: TextStyle(color: Color(0xFF2C3E50))),
          content: TextField(
            decoration: const InputDecoration(hintText: "Section name"),
            onChanged: (value) {
              newCategory = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9B1B30)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
              onPressed: () {
                if (newCategory.isNotEmpty &&
                    !widget.categorizedBottoms.containsKey(newCategory)) {
                  setState(() {
                    widget.categorizedBottoms[newCategory] = [];
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF6F1E1),
        title: const Text('Confirm Deletion', style: TextStyle(color: Color(0xFF2C3E50))),
        content: Text('Are you sure you want to delete "$categoryName"?', style: TextStyle(color: Color(0xFF2C3E50))),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6F61)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              setState(() {
                widget.categorizedBottoms.remove(categoryName);
                _sectionsMarkedForDelete.remove(categoryName);
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Bottoms', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2C3E50),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                setState(() {
                  _isDeleteMode = !_isDeleteMode;
                });
              } else if (value == 'customize') {
                _showAddCategoryDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(_isDeleteMode ? 'Cancel Delete Mode' : 'Delete Sections'),
              ),
              const PopupMenuItem(
                value: 'customize',
                child: Text('Customize Your Bottoms'),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: widget.categorizedBottoms.entries.map((entry) {
              return _buildCategorySection(entry.key, entry.value);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String categoryName, List<File> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubDetails(subcategoryName: categoryName, subCategory: '',),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B1B30),
                ),
              ),
              if (_isDeleteMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6F61)),
                  onPressed: () => _showDeleteConfirmation(categoryName),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8A7B1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('No items to display')),
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: items.map((file) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(file),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
        const SizedBox(height: 24),
      ],
    );
  }
}
