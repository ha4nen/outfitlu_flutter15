// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/Outfits/OutfitpageDyn.dart';
import 'dart:io';

import 'Catagories/Summer.dart';
import 'Catagories/Winter.dart';
import 'Catagories/Fall.dart';
import 'Catagories/Spring.dart';

class AllOutfitsPage extends StatefulWidget {
  final List<File> summerOutfits;
  final List<File> winterOutfits;
  final List<File> fallOutfits;
  final List<File> springOutfits;

  const AllOutfitsPage({
    super.key,
    required this.summerOutfits,
    required this.winterOutfits,
    required this.fallOutfits,
    required this.springOutfits,
    required List<File> outfits,
  });

  @override
  State<AllOutfitsPage> createState() => _AllOutfitsPageState();
}

class _AllOutfitsPageState extends State<AllOutfitsPage> {
  final Set<int> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('All Outfits'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategorySection('Summer', widget.summerOutfits),
              const SizedBox(height: 16),
              _buildCategorySection('Winter', widget.winterOutfits),
              const SizedBox(height: 16),
              _buildCategorySection('Fall', widget.fallOutfits),
              const SizedBox(height: 16),
              _buildCategorySection('Spring', widget.springOutfits),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(String categoryName, List<File> items) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OutfitCategoryPage(
                  categoryName: categoryName, // Pass the category name dynamically
                  outfits: items,
                ),
              ),
            );
          },
          child: Text(
            categoryName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
          ),
        ),
        const SizedBox(height: 8),
        items.isEmpty
            ? Container(
                height: 150,
                color: theme.scaffoldBackgroundColor,
                child: const Center(
                  child: Text('No outfits to display'),
                ),
              )
            : SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedItems.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedItems.remove(index);
                          } else {
                            _selectedItems.add(index);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(
                              items[index],
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              color: isSelected ? theme.primaryColor.withOpacity(0.5) : null,
                              colorBlendMode: isSelected ? BlendMode.darken : null,
                            ),
                          ),
                          if (isSelected)
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}