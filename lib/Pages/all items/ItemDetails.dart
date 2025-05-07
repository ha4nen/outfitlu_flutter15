// ignore_for_file: deprecated_member_use, file_names

import 'dart:io';

import 'package:flutter/material.dart';

class ItemDetails extends StatelessWidget {
  final String itemName;
  final String color;
  final String size;
  final String season;
  final List<String> tags;

  const ItemDetails({
    super.key,
    required this.itemName,
    required this.color,
    required this.size,
    required this.season,
    required this.tags, required File item, String? imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image Container
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // Dynamic placeholder background color
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1), // Dynamic shadow color
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Item Name
            Text(
              itemName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamic text color
              ),
            ),
            const SizedBox(height: 16),

            // Item Details
            Text(
              'Details:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamic text color
              ),
            ),
            const SizedBox(height: 8),
            Text('Colour: $color', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
            Text('Size: $size', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
            Text('Season: $season', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color)),
            const SizedBox(height: 16),

            // Tags
            Text(
              'Tags:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamic text color
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2), // Dynamic chip color
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}