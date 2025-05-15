import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Pages/The+Button/ConfirmPhotoPage.dart';
import 'package:image_picker/image_picker.dart';
import '../mesc/loading_page.dart';

class AddItemOptionsPage extends StatelessWidget {
  const AddItemOptionsPage({super.key});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LoadingPage(
                imageFile: File(pickedFile.path),
                nextPageBuilder:
                    () => ConfirmPhotoPage(
                      imageFile: File(pickedFile.path),
                    ), // Navigate to ConfirmYourPhotoPage
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.brightness == Brightness.dark
            ? Colors
                .white // White text in dark theme
            : Colors.black; // Black text in light theme

    return AlertDialog(
      backgroundColor: theme.colorScheme.surface, // Dynamic surface color
      title: Text(
        "Add Item",
        style: TextStyle(color: textColor), // Dynamic text color
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.camera_alt,
              color: theme.colorScheme.primary,
            ), // Dynamic icon color
            title: Text(
              "Take a Photo",
              style: TextStyle(color: textColor), // Dynamic text color
            ),
            onTap: () => _pickImage(context, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(
              Icons.photo_library,
              color: theme.colorScheme.primary,
            ), // Dynamic icon color
            title: Text(
              "Choose from Library",
              style: TextStyle(color: textColor), // Dynamic text color
            ),
            onTap: () => _pickImage(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
