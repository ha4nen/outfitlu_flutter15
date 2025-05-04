// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'dart:io';

class OutfitCategoryPage extends StatelessWidget {
  final String categoryName;
  final List<File> outfits;

  const OutfitCategoryPage({
    super.key,
    required this.categoryName,
    required this.outfits,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Outfits'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
      ),
      body: outfits.isEmpty
          ? Center(
              child: Text(
                'No outfits available for $categoryName',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: outfits.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Handle outfit selection or preview
                  },
                  child: Stack(
                    children: [
                      Image.file(
                        outfits[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          color: Colors.black54,
                          child: Text(
                            'Outfit ${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}