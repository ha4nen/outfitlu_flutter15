import 'dart:io';
import 'package:flutter/material.dart';
import 'itemDetails.dart'; // Import the ItemDetails page

class SubDetails extends StatelessWidget {
  final String subcategoryName;

  const SubDetails({super.key, required this.subcategoryName, required String subCategory});

  @override
  Widget build(BuildContext context) {
    // Example single item data
    final String itemName = 'Example Item';
    final String color = 'Red';
    final String size = 'M';
    final String season = 'Summer';
    final List<String> tags = ['Casual', 'Cotton', 'Comfortable'];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Text(
              subcategoryName, // Display the subcategory name dynamically
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Dynamic app bar color
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // Dynamic text color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: GestureDetector(
            onTap: () {
              // Navigate to ItemDetails page with example item data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetails(
                    itemName: itemName, // Pass the required itemName
                    color: color,       // Pass the required color
                    size: size,         // Pass the required size
                    season: season,     // Pass the required season
                    tags: tags,
                    item: File('path/to/your/file'), // Pass a valid File object
                  ),
                ),
              );
            },
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Dynamic background color
                borderRadius: BorderRadius.circular(12), // Soft rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1), // Dynamic shadow color
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  itemName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyLarge?.color, // Dynamic text color
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}